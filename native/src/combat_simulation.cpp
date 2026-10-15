#include "combat_simulation.hpp"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>

#include <cmath>
#include <limits>
#include <string>

using namespace godot;
using dopamine::sim::CommandType;
using dopamine::sim::SimulationCommand;

void CombatSimulation::_bind_methods() {
	ClassDB::bind_method(D_METHOD("spawn", "entity_type", "count", "position", "hp", "velocity"),
			&CombatSimulation::spawn);
	ClassDB::bind_method(D_METHOD("despawn", "index", "generation"), &CombatSimulation::despawn);
	ClassDB::bind_method(D_METHOD("kill_all"), &CombatSimulation::kill_all);
	ClassDB::bind_method(D_METHOD("pause"), &CombatSimulation::pause);
	ClassDB::bind_method(D_METHOD("resume"), &CombatSimulation::resume);
	ClassDB::bind_method(D_METHOD("step", "delta_seconds"), &CombatSimulation::step);
	ClassDB::bind_method(D_METHOD("set_speed", "multiplier"), &CombatSimulation::set_speed);
	ClassDB::bind_method(D_METHOD("set_steering_target", "position", "max_speed", "separation_radius", "separation_weight"),
			&CombatSimulation::set_steering_target);
	ClassDB::bind_method(D_METHOD("reset"), &CombatSimulation::reset);
	ClassDB::bind_method(D_METHOD("snapshot"), &CombatSimulation::snapshot);
}

CombatSimulation::CombatSimulation() {
	worker_.start();
}

int64_t CombatSimulation::spawn(String entity_type, int64_t count, Vector2 position, float hp, Vector2 velocity) {
	if (entity_type.is_empty() || count <= 0 || count > 500 || !std::isfinite(position.x) ||
			!std::isfinite(position.y) || !std::isfinite(hp) || hp <= 0.0F || !std::isfinite(velocity.x) ||
			!std::isfinite(velocity.y)) {
		return 0;
	}
	SimulationCommand command;
	command.type = CommandType::Spawn;
	command.entity_type = entity_type.utf8().get_data();
	command.count = static_cast<uint32_t>(count);
	command.x = static_cast<float>(position.x);
	command.y = static_cast<float>(position.y);
	command.hp = hp;
	command.velocity_x = static_cast<float>(velocity.x);
	command.velocity_y = static_cast<float>(velocity.y);
	return submit(std::move(command));
}

int64_t CombatSimulation::despawn(int64_t index, int64_t generation) {
	constexpr int64_t max_id = std::numeric_limits<uint32_t>::max();
	if (index < 0 || index > max_id || generation <= 0 || generation > max_id) {
		return 0;
	}
	SimulationCommand command;
	command.type = CommandType::Despawn;
	command.entity = {static_cast<uint32_t>(index), static_cast<uint32_t>(generation)};
	return submit(std::move(command));
}

int64_t CombatSimulation::kill_all() {
	SimulationCommand command;
	command.type = CommandType::KillAll;
	return submit(std::move(command));
}

int64_t CombatSimulation::pause() {
	SimulationCommand command;
	command.type = CommandType::Pause;
	return submit(std::move(command));
}

int64_t CombatSimulation::resume() {
	SimulationCommand command;
	command.type = CommandType::Resume;
	return submit(std::move(command));
}

int64_t CombatSimulation::step(double delta_seconds) {
	if (!std::isfinite(delta_seconds) || delta_seconds <= 0.0) {
		return 0;
	}
	SimulationCommand command;
	command.type = CommandType::Step;
	command.delta_seconds = delta_seconds;
	return submit(std::move(command));
}

int64_t CombatSimulation::set_speed(double multiplier) {
	if (!std::isfinite(multiplier) || multiplier < 0.25 || multiplier > 4.0) {
		return 0;
	}
	SimulationCommand command;
	command.type = CommandType::SetSpeed;
	command.speed_multiplier = multiplier;
	return submit(std::move(command));
}

int64_t CombatSimulation::set_steering_target(Vector2 position, float max_speed, float separation_radius,
		float separation_weight) {
	if (!std::isfinite(position.x) || !std::isfinite(position.y) || !std::isfinite(max_speed) || max_speed < 0.0F ||
			!std::isfinite(separation_radius) || separation_radius < 0.0F || !std::isfinite(separation_weight) ||
			separation_weight < 0.0F || separation_weight > 1.0F) {
		return 0;
	}
	SimulationCommand command;
	command.type = CommandType::SetSteeringTarget;
	command.x = static_cast<float>(position.x);
	command.y = static_cast<float>(position.y);
	command.steering.max_speed = max_speed;
	command.steering.separation_radius = separation_radius;
	command.steering.separation_weight = separation_weight;
	return submit(std::move(command));
}

int64_t CombatSimulation::reset() {
	SimulationCommand command;
	command.type = CommandType::Reset;
	return submit(std::move(command));
}

Dictionary CombatSimulation::snapshot() const {
	const auto state = worker_.snapshot();
	Dictionary result;
	result["paused"] = state->paused;
	result["speed_multiplier"] = state->speed_multiplier;
	result["simulation_time"] = state->simulation_time;
	result["last_sequence"] = static_cast<int64_t>(state->last_sequence);
	result["rejected_commands"] = static_cast<int64_t>(state->rejected_commands);

	Dictionary metrics;
	metrics["frame_time_ms"] = state->frame_time_ms;
	metrics["entity_count"] = static_cast<int64_t>(state->entities.size());
	metrics["projectile_count"] = static_cast<int64_t>(state->projectile_count);
	metrics["collision_count"] = static_cast<int64_t>(state->collision_count);
	result["metrics"] = metrics;

	Array entities;
	for (const dopamine::sim::Entity &entity : state->entities) {
		Dictionary id;
		id["index"] = static_cast<int64_t>(entity.id.index);
		id["generation"] = static_cast<int64_t>(entity.id.generation);

		Dictionary transform;
		transform["x"] = entity.transform.x;
		transform["y"] = entity.transform.y;
		Dictionary velocity;
		velocity["x"] = entity.velocity.x;
		velocity["y"] = entity.velocity.y;
		Dictionary health;
		health["current"] = entity.health.current;
		health["maximum"] = entity.health.maximum;

		Dictionary components;
		components["Transform2D"] = transform;
		components["Velocity2D"] = velocity;
		components["Health"] = health;
		components["EnemyType"] = String(entity.type.id.c_str());

		Dictionary entry;
		entry["id"] = id;
		entry["components"] = components;
		entities.push_back(entry);
	}
	result["entities"] = entities;

	PackedStringArray logs;
	for (const std::string &message : state->logs) {
		logs.push_back(String(message.c_str()));
	}
	result["logs"] = logs;
	return result;
}

int64_t CombatSimulation::submit(SimulationCommand command) {
	const uint64_t sequence = worker_.submit(std::move(command));
	return sequence <= static_cast<uint64_t>(std::numeric_limits<int64_t>::max()) ? static_cast<int64_t>(sequence) : 0;
}
