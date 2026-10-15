#include "dopamine/simulation/simulation_worker.hpp"

#include <algorithm>
#include <cmath>
#include <utility>

namespace dopamine::sim {

SimulationWorker::SimulationWorker() {
	published_.store(std::make_shared<SimulationSnapshot>());
}

SimulationWorker::~SimulationWorker() {
	stop();
}

void SimulationWorker::start() {
	std::lock_guard lock(lifecycle_mutex_);
	if (thread_.joinable()) {
		return;
	}
	running_.store(true);
	thread_ = std::jthread([this](std::stop_token stop_token) { run(stop_token); });
}

void SimulationWorker::stop() {
	std::lock_guard lock(lifecycle_mutex_);
	if (!thread_.joinable()) {
		running_.store(false);
		return;
	}
	thread_.request_stop();
	queue_cv_.notify_all();
	thread_.join();
	{
		std::lock_guard queue_lock(queue_mutex_);
		queue_.clear();
	}
	running_.store(false);
	apply(SimulationCommand{.type = CommandType::Pause});
	publish(0.0);
}

uint64_t SimulationWorker::submit(SimulationCommand command) {
	if (!running_.load()) {
		return 0;
	}
	{
		std::lock_guard lock(queue_mutex_);
		if (!running_.load() || queue_.size() >= max_queued_commands_) {
			rejected_commands_.fetch_add(1);
			return 0;
		}
		const uint64_t sequence = next_sequence_++;
		command.sequence = sequence;
		queue_.push_back(std::move(command));
		queue_cv_.notify_one();
		return sequence;
	}
}

std::shared_ptr<const SimulationSnapshot> SimulationWorker::snapshot() const {
	return published_.load();
}

bool SimulationWorker::wait_until_applied(uint64_t sequence, std::chrono::milliseconds timeout) const {
	std::unique_lock lock(applied_mutex_);
	return applied_cv_.wait_for(lock, timeout, [this, sequence] {
		return snapshot()->last_sequence >= sequence || !running_.load();
	}) && snapshot()->last_sequence >= sequence;
}

void SimulationWorker::run(std::stop_token stop_token) {
	auto last_update = std::chrono::steady_clock::now();
	while (!stop_token.stop_requested()) {
		std::deque<SimulationCommand> commands;
		{
			std::unique_lock lock(queue_mutex_);
			auto has_command_or_stopping = [this, &stop_token] {
				return stop_token.stop_requested() || !queue_.empty();
			};
			if (paused_) {
				queue_cv_.wait(lock, has_command_or_stopping);
			} else {
				queue_cv_.wait_for(lock, std::chrono::milliseconds(16), has_command_or_stopping);
			}
			if (stop_token.stop_requested()) {
				break;
			}
			commands.swap(queue_);
		}

		for (const SimulationCommand &command : commands) {
			apply(command);
		}

		const auto now = std::chrono::steady_clock::now();
		const double elapsed = std::chrono::duration<double>(now - last_update).count();
		last_update = now;
		double frame_time_ms = elapsed * 1000.0;
		if (!paused_ && elapsed > 0.0) {
			if (has_event_capacity()) {
				if (has_steering_target_) {
					simulation_.steer_enemies_towards(steering_target_x_, steering_target_y_, steering_config_);
				}
				const double delta = deferred_elapsed_ + elapsed * speed_multiplier_;
				deferred_elapsed_ = 0.0;
				append_events(simulation_.advance(delta));
			} else {
				deferred_elapsed_ += elapsed * speed_multiplier_;
			}
		} else if (paused_) {
			frame_time_ms = 0.0;
		}
		publish(frame_time_ms);
	}
	running_.store(false);
	queue_cv_.notify_all();
	applied_cv_.notify_all();
}

void SimulationWorker::apply(const SimulationCommand &command) {
	switch (command.type) {
		case CommandType::Spawn: {
			if (command.count == 0 || command.count > 500 || simulation_.entity_count() + command.count > max_entities_) {
				log("spawn rejected: entity count outside limits");
				break;
			}
			try {
				for (uint32_t i = 0; i < command.count; ++i) {
					simulation_.spawn(command.entity_type, command.x, command.y, command.hp,
							command.velocity_x, command.velocity_y, command.threat_level, command.enemy_move_speed);
				}
				log("spawned " + std::to_string(command.count) + " " + command.entity_type);
			} catch (const std::exception &error) {
				log(std::string("spawn rejected: ") + error.what());
			}
			break;
		}
		case CommandType::Despawn:
			log(simulation_.despawn(command.entity) ? "entity despawned" : "despawn ignored: stale entity ID");
			break;
		case CommandType::KillAll: {
			const auto entities = simulation_.snapshot();
			for (const Entity &entity : entities) {
				simulation_.despawn(entity.id);
			}
			log("removed " + std::to_string(entities.size()) + " entities");
			break;
		}
		case CommandType::Pause:
			paused_ = true;
			log("simulation paused");
			break;
		case CommandType::Resume:
			paused_ = false;
			log("simulation resumed");
			break;
		case CommandType::Step:
			if (!paused_ || !std::isfinite(command.delta_seconds) || command.delta_seconds <= 0.0) {
				log("step rejected: pause first and use a positive finite duration");
				break;
			}
			try {
				if (!has_event_capacity()) {
					log("step rejected: acknowledge pending combat events first");
					break;
				}
				if (has_steering_target_) {
					simulation_.steer_enemies_towards(steering_target_x_, steering_target_y_, steering_config_);
				}
				append_events(simulation_.advance(command.delta_seconds * speed_multiplier_));
				log("stepped " + std::to_string(command.delta_seconds) + " seconds");
			} catch (const std::exception &error) {
				log(std::string("step rejected: ") + error.what());
			}
			break;
		case CommandType::SetSpeed:
			if (!std::isfinite(command.speed_multiplier) || command.speed_multiplier < 0.25 ||
					command.speed_multiplier > 4.0) {
				log("speed rejected: expected a value from 0.25 to 4.0");
				break;
			}
			speed_multiplier_ = command.speed_multiplier;
			log("speed set to " + std::to_string(speed_multiplier_));
			break;
		case CommandType::SetSteeringTarget:
			if (!std::isfinite(command.x) || !std::isfinite(command.y) ||
					!std::isfinite(command.steering.max_speed) || command.steering.max_speed < 0.0F ||
					!std::isfinite(command.steering.separation_radius) || command.steering.separation_radius < 0.0F ||
					!std::isfinite(command.steering.separation_weight) || command.steering.separation_weight < 0.0F ||
					command.steering.separation_weight > 1.0F ||
					!std::isfinite(command.steering.spatial_hash.cell_size) ||
					command.steering.spatial_hash.cell_size <= 0.0F) {
				log("steering target rejected: invalid target or configuration");
				break;
			}
			has_steering_target_ = true;
			steering_target_x_ = command.x;
			steering_target_y_ = command.y;
			steering_config_ = command.steering;
			log("steering target updated");
			break;
		case CommandType::SpawnProjectile:
			if (simulation_.entity_count() >= max_entities_) {
				log("projectile rejected: entity count outside limits");
				break;
			}
			try {
				simulation_.spawn_projectile(command.entity_type, command.x, command.y, command.projectile_damage,
						command.projectile_radius, command.projectile_lifetime, command.velocity_x, command.velocity_y);
				log("spawned projectile " + command.entity_type);
			} catch (const std::exception &error) {
				log(std::string("projectile rejected: ") + error.what());
			}
			break;
		case CommandType::SpawnXpOrb:
			if (simulation_.entity_count() >= max_entities_) {
				log("XP orb rejected: entity count outside limits");
				break;
			}
			try {
				simulation_.spawn_xp_orb(command.x, command.y, command.xp_value);
				log("spawned XP orb worth " + std::to_string(command.xp_value));
			} catch (const std::exception &error) {
				log(std::string("XP orb rejected: ") + error.what());
			}
			break;
		case CommandType::CollectXpOrb:
			if (pending_events_.size() >= max_pending_events_) {
				log("XP collection delayed: acknowledge pending events first");
				break;
			}
			{
				std::vector<CombatEvent> events;
				if (simulation_.collect_xp_orb(command.entity, events)) {
					append_events(std::move(events));
					log("XP orb collected");
				} else {
					log("XP collection ignored: stale or non-XP entity ID");
				}
			}
			break;
		case CommandType::AcknowledgeEvents:
			if (command.event_sequence <= last_event_sequence_) {
				const auto first_pending = std::find_if(pending_events_.begin(), pending_events_.end(),
						[&command](const CombatEvent &event) { return event.sequence > command.event_sequence; });
				pending_events_.erase(pending_events_.begin(), first_pending);
			} else {
				log("event acknowledgement ignored: sequence is ahead of the event stream");
			}
			break;
		case CommandType::Reset:
			simulation_.reset();
			paused_ = true;
			speed_multiplier_ = 1.0;
			has_steering_target_ = false;
			collision_count_ = 0;
			deferred_elapsed_ = 0.0;
			log("simulation reset");
			break;
	}
	if (command.sequence != 0) {
		pending_sequence_ = command.sequence;
	}
}

void SimulationWorker::publish(double frame_time_ms) {
	auto next = std::make_shared<SimulationSnapshot>();
	next->paused = paused_;
	next->speed_multiplier = speed_multiplier_;
	next->simulation_time = simulation_.simulation_time();
	next->frame_time_ms = frame_time_ms;
	next->last_sequence = pending_sequence_;
	next->rejected_commands = rejected_commands_.load();
	next->entities = simulation_.snapshot();
	next->events = pending_events_;
	next->collision_count = collision_count_;
	for (const Entity &entity : next->entities) {
		if (entity.is_projectile) {
			++next->projectile_count;
		}
		if (entity.is_xp_orb) {
			++next->xp_orb_count;
		}
	}
	next->logs = logs_;
	published_.store(std::move(next));
	applied_cv_.notify_all();
}

void SimulationWorker::append_events(std::vector<CombatEvent> events) {
	for (const CombatEvent &event : events) {
		last_event_sequence_ = event.sequence;
		if (event.type == CombatEventType::Damage) {
			++collision_count_;
		}
		pending_events_.push_back(event);
	}
}

bool SimulationWorker::has_event_capacity() const {
	return pending_events_.size() <= max_pending_events_ - max_events_per_advance_;
}

void SimulationWorker::log(std::string message) {
	if (logs_.size() == 100) {
		logs_.erase(logs_.begin());
	}
	logs_.push_back("t=" + std::to_string(simulation_.simulation_time()) + "s " + std::move(message));
}

} // namespace dopamine::sim
