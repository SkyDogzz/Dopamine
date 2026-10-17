#include "dopamine/simulation/simulation_worker.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <utility>

namespace dopamine::sim {

namespace {

bool valid_steering_config(const SteeringConfig &config) {
	return std::isfinite(config.max_speed) && config.max_speed >= 0.0F &&
			std::isfinite(config.separation_radius) && config.separation_radius >= 0.0F &&
			std::isfinite(config.separation_weight) && config.separation_weight >= 0.0F &&
			config.separation_weight <= 1.0F && std::isfinite(config.spatial_hash.cell_size) &&
			config.spatial_hash.cell_size > 0.0F;
}

} // namespace

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
		for (const SimulationCommand &command : queue_) {
			if (command.capture_promise) {
				try {
					command.capture_promise->set_exception(std::make_exception_ptr(
							std::runtime_error("worker stopped before state capture")));
				} catch (const std::future_error &) {
				}
			}
		}
		queue_.clear();
	}
	capture_pending_.store(false);
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

std::optional<SimulationWorkerState> SimulationWorker::capture_state(std::chrono::milliseconds timeout) {
	if (!running_.load()) {
		return std::nullopt;
	}
	bool expected = false;
	if (!capture_pending_.compare_exchange_strong(expected, true)) {
		return std::nullopt;
	}
	auto promise = std::make_shared<std::promise<SimulationWorkerState>>();
	auto result = promise->get_future();
	SimulationCommand command;
	command.type = CommandType::CaptureState;
	command.capture_promise = std::move(promise);
	if (submit(std::move(command)) == 0) {
		capture_pending_.store(false);
		return std::nullopt;
	}
	if (result.wait_for(timeout) != std::future_status::ready) {
		return std::nullopt;
	}
	try {
		return result.get();
	} catch (const std::exception &) {
		return std::nullopt;
	}
}

bool SimulationWorker::restore_state(const SimulationWorkerState &state) {
	if (state.format_version != 17 || state.next_sequence == 0 ||
			state.next_sequence <= state.pending_sequence ||
			state.pending_commands.size() > max_queued_commands_ ||
			state.pending_events.size() > max_pending_events_ || state.logs.size() > 100 ||
			!std::isfinite(state.speed_multiplier) || state.speed_multiplier < 0.25 || state.speed_multiplier > 4.0 ||
			!std::isfinite(state.deferred_elapsed) || state.deferred_elapsed < 0.0 ||
			!valid_steering_config(state.steering_config) ||
			(state.has_steering_target && (!std::isfinite(state.steering_target_x) ||
					!std::isfinite(state.steering_target_y))) ||
			state.core_state.next_event_sequence <= state.last_event_sequence) {
		return false;
	}
	uint64_t previous_event_sequence = 0;
	for (const CombatEvent &event : state.pending_events) {
		if (event.sequence == 0 || event.sequence <= previous_event_sequence || event.reaction_budget > 64 ||
				event.sequence > state.last_event_sequence) {
			return false;
		}
		previous_event_sequence = event.sequence;
	}
	uint64_t previous_command_sequence = state.pending_sequence;
	for (const SimulationCommand &command : state.pending_commands) {
		if (previous_command_sequence == std::numeric_limits<uint64_t>::max() ||
				command.sequence != previous_command_sequence + 1 || command.capture_promise ||
				static_cast<uint8_t>(command.type) >= static_cast<uint8_t>(CommandType::CaptureState)) {
			return false;
		}
		previous_command_sequence = command.sequence;
	}
	if (previous_command_sequence == std::numeric_limits<uint64_t>::max() ||
			state.next_sequence != previous_command_sequence + 1) {
		return false;
	}
	SimulationCore restored_core;
	try {
		restored_core.restore_state(state.core_state);
	} catch (const std::exception &) {
		return false;
	}

	std::lock_guard lifecycle_lock(lifecycle_mutex_);
	if (thread_.joinable() || running_.load() || capture_pending_.load()) {
		return false;
	}
	{
		std::lock_guard queue_lock(queue_mutex_);
		queue_ = state.pending_commands;
		next_sequence_ = state.next_sequence;
	}
	simulation_ = std::move(restored_core);
	paused_ = state.paused;
	speed_multiplier_ = state.speed_multiplier;
	has_steering_target_ = state.has_steering_target;
	steering_target_x_ = state.steering_target_x;
	steering_target_y_ = state.steering_target_y;
	steering_config_ = state.steering_config;
	pending_sequence_ = state.pending_sequence;
	rejected_commands_.store(state.rejected_commands);
	pending_events_ = state.pending_events;
	last_event_sequence_ = state.last_event_sequence;
	collision_count_ = state.collision_count;
	deferred_elapsed_ = state.deferred_elapsed;
	logs_ = state.logs;
	publish(0.0);
	return true;
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
		bool paused_before_commands = false;
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
			paused_before_commands = paused_;
			commands.swap(queue_);
		}

		while (!commands.empty()) {
			SimulationCommand command = std::move(commands.front());
			commands.pop_front();
			apply(command, &commands);
		}

		const auto now = std::chrono::steady_clock::now();
		if (paused_before_commands && !paused_) {
			last_update = now;
		}
		const double elapsed = std::chrono::duration<double>(now - last_update).count();
		last_update = now;
		double frame_time_ms = elapsed * 1000.0;
		if (!paused_ && elapsed > 0.0) {
			if (has_event_capacity()) {
				if (has_steering_target_) {
					simulation_.steer_enemies_towards(steering_target_x_, steering_target_y_, steering_config_);
				}
				const double delta = deferred_elapsed_ + elapsed * speed_multiplier_;
				double step = delta;
				if (simulation_.estimate_event_count_upper_bound(step) > max_events_per_advance_) {
					double lower = 0.0;
					double upper = step;
					for (int iteration = 0; iteration < 48; ++iteration) {
						const double candidate = lower + (upper - lower) * 0.5;
						if (candidate == lower || candidate == upper) {
							break;
						}
						if (simulation_.estimate_event_count_upper_bound(candidate) <= max_events_per_advance_) {
							lower = candidate;
						} else {
							upper = candidate;
						}
					}
					step = lower;
				}
				if (step > 0.0) {
					deferred_elapsed_ = delta - step;
					append_events(simulation_.advance(step));
				} else {
					deferred_elapsed_ = delta;
				}
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

void SimulationWorker::apply(const SimulationCommand &command,
		const std::deque<SimulationCommand> *batch_pending) {
	switch (command.type) {
		case CommandType::Spawn: {
			if (command.count == 0 || command.count > 500 || simulation_.entity_count() + command.count > max_entities_) {
				log("spawn rejected: entity count outside limits");
				break;
			}
			try {
				for (uint32_t i = 0; i < command.count; ++i) {
					simulation_.spawn(command.entity_type, command.x, command.y, command.hp,
							command.velocity_x, command.velocity_y, command.threat_level, command.enemy_move_speed,
							command.enemy_affix, command.enemy_damage_taken_multiplier,
							command.enemy_health_regen_per_second, command.enemy_death_explosion_radius,
							command.enemy_death_explosion_damage);
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
				const double scaled_delta = command.delta_seconds * speed_multiplier_;
				if (simulation_.estimate_event_count_upper_bound(scaled_delta) > max_events_per_advance_) {
					log("step rejected: combat event budget exceeded; use a smaller duration");
					break;
				}
				if (has_steering_target_) {
					simulation_.steer_enemies_towards(steering_target_x_, steering_target_y_, steering_config_);
				}
				append_events(simulation_.advance(scaled_delta));
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
		case CommandType::ApplySandboxOverrides:
			if (!std::isfinite(command.steering.max_speed) || command.steering.max_speed < 0.0F ||
					!std::isfinite(command.steering.separation_radius) || command.steering.separation_radius < 0.0F ||
					!std::isfinite(command.steering.separation_weight) || command.steering.separation_weight < 0.0F ||
					command.steering.separation_weight > 1.0F ||
					!std::isfinite(command.steering.spatial_hash.cell_size) ||
					command.steering.spatial_hash.cell_size <= 0.0F) {
				log("sandbox overrides rejected: invalid configuration; previous values kept");
				break;
			}
			steering_config_ = command.steering;
			has_steering_target_ = true;
			steering_target_x_ = 0.0F;
			steering_target_y_ = 0.0F;
			log("sandbox overrides committed atomically");
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
		case CommandType::DashEntity:
			try {
				if (simulation_.dash_entity(command.entity, command.velocity_x, command.velocity_y,
						command.movement_duration_seconds)) {
					log("entity movement override started");
				} else {
					log("entity movement override ignored: stale or unsupported entity ID");
				}
			} catch (const std::exception &error) {
				log(std::string("entity movement override rejected: ") + error.what());
			}
			break;
		case CommandType::AttractXpOrbs:
			simulation_.attract_xp_orbs(command.x, command.y, command.projectile_attraction_radius,
					command.projectile_attraction_speed, static_cast<float>(command.movement_duration_seconds),
					command.attraction_delta_seconds);
			break;
		case CommandType::StopXpOrbAttraction:
			simulation_.stop_xp_orb_attraction();
			break;
		case CommandType::SpawnProjectile:
			if (simulation_.entity_count() >= max_entities_) {
				log("projectile rejected: entity count outside limits");
				break;
			}
			try {
				simulation_.spawn_projectile(command.entity_type, command.x, command.y, command.projectile_damage,
						command.projectile_radius, command.projectile_lifetime, command.velocity_x, command.velocity_y,
						command.projectile_status_damage, command.projectile_status_interval,
						command.projectile_status_duration, command.projectile_explosion_radius,
						command.projectile_explosion_damage_multiplier, command.projectile_ricochets,
						command.projectile_attraction_radius, command.projectile_attraction_speed,
						command.projectile_pierces_targets, command.projectile_chill_duration,
						command.projectile_chill_speed_multiplier, command.projectile_chill_damage_multiplier,
						command.projectile_orbit_angular_speed, command.projectile_reaction_chain_id,
						command.projectile_reaction_budget, command.projectile_critical_hit,
						command.projectile_homing_turn_rate, command.projectile_homing_radius);
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
		case CommandType::ApplyDamageOverTime:
			try {
				if (simulation_.apply_damage_over_time(command.entity, command.status_damage_per_tick,
						command.status_interval_seconds, command.status_duration_seconds, command.status_type)) {
					log("damage-over-time applied to entity " + std::to_string(command.entity.index));
				} else {
					log("damage-over-time ignored: stale or unsupported entity ID");
				}
			} catch (const std::exception &error) {
				log(std::string("damage-over-time rejected: ") + error.what());
			}
			break;
		case CommandType::TickDamageOverTime:
			if (pending_events_.size() < max_pending_events_) {
				std::vector<CombatEvent> events;
				if (simulation_.tick_damage_over_time(command.entity, command.status_type, events)) {
					append_events(std::move(events));
				}
			} else {
				log("status tick delayed: acknowledge pending events first");
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
			steering_config_ = SteeringConfig{};
			collision_count_ = 0;
			deferred_elapsed_ = 0.0;
			log("simulation reset");
			break;
		case CommandType::CaptureState:
			if (!command.capture_promise) {
				log("state capture ignored: missing response channel");
				break;
			}
			{
				SimulationWorkerState state;
				state.core_state = simulation_.capture_state();
				state.paused = paused_;
				state.speed_multiplier = speed_multiplier_;
				state.has_steering_target = has_steering_target_;
				state.steering_target_x = steering_target_x_;
				state.steering_target_y = steering_target_y_;
				state.steering_config = steering_config_;
				state.pending_sequence = command.sequence;
				state.rejected_commands = rejected_commands_.load();
				state.pending_events = pending_events_;
				state.last_event_sequence = last_event_sequence_;
				state.collision_count = collision_count_;
				state.deferred_elapsed = deferred_elapsed_;
				state.logs = logs_;
				{
					std::lock_guard queue_lock(queue_mutex_);
					if (batch_pending != nullptr) {
						state.pending_commands = *batch_pending;
					}
					state.pending_commands.insert(state.pending_commands.end(), queue_.begin(), queue_.end());
					for (SimulationCommand &pending : state.pending_commands) {
						pending.capture_promise.reset();
					}
					state.next_sequence = next_sequence_;
				}
				capture_pending_.store(false);
				try {
					command.capture_promise->set_value(std::move(state));
				} catch (const std::future_error &) {
				}
			}
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
	next->steering_config = steering_config_;
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
