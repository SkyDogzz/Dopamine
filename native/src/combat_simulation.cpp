#include "combat_simulation.hpp"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>

#include <algorithm>
#include <cmath>
#include <limits>
#include <string>
#include <vector>

using namespace godot;
using dopamine::sim::CommandType;
using dopamine::sim::SimulationCommand;

namespace {

std::vector<std::string> split_affixes(const std::string &value) {
	std::vector<std::string> result;
	if (value.empty() || value.front() == '+' || value.back() == '+') return result;
	std::size_t start = 0;
	while (start < value.size()) {
		const std::size_t separator = value.find('+', start);
		result.push_back(value.substr(start, separator == std::string::npos ? separator : separator - start));
		if (separator == std::string::npos) break;
		start = separator + 1;
	}
	return result;
}

bool has_affix(const std::vector<std::string> &affixes, const std::string &affix) {
	return std::find(affixes.begin(), affixes.end(), affix) != affixes.end();
}

} // namespace

void CombatSimulationSnapshot::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_format_version"), &CombatSimulationSnapshot::get_format_version);
	ClassDB::bind_method(D_METHOD("is_valid"), &CombatSimulationSnapshot::is_valid);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "format_version"), "", "get_format_version");
}

uint32_t CombatSimulationSnapshot::get_format_version() const {
	return format_version_;
}

bool CombatSimulationSnapshot::is_valid() const {
	return state_.has_value() && format_version_ == 18;
}

void CombatSimulation::_bind_methods() {
	ClassDB::bind_method(D_METHOD("spawn", "entity_type", "count", "position", "hp", "velocity", "threat_level"),
			&CombatSimulation::spawn, DEFVAL(1.0));
	ClassDB::bind_method(D_METHOD("spawn_enemy", "enemy_type", "count", "position", "velocity", "hp_multiplier", "affix", "movement_speed_multiplier"),
			&CombatSimulation::spawn_enemy, DEFVAL(1.0), DEFVAL(String()), DEFVAL(1.0));
	ClassDB::bind_method(D_METHOD("spawn_projectile", "projectile_type", "position", "velocity", "damage", "radius", "lifetime_seconds", "burn_damage_per_tick", "burn_interval_seconds", "burn_duration_seconds", "explosion_radius", "explosion_damage_multiplier", "ricochets", "attraction_radius", "attraction_speed", "pierces_targets", "chill_duration_seconds", "chill_speed_multiplier", "chill_damage_multiplier", "orbit_angular_speed", "reaction_chain_id", "reaction_budget", "critical_hit", "homing_turn_rate", "homing_radius"),
			&CombatSimulation::spawn_projectile, DEFVAL(2.0), DEFVAL(0.5), DEFVAL(2.0), DEFVAL(0.0), DEFVAL(0.0), DEFVAL(0), DEFVAL(0.0), DEFVAL(0.0), DEFVAL(false), DEFVAL(0.0), DEFVAL(1.0), DEFVAL(1.0), DEFVAL(0.0), DEFVAL(0), DEFVAL(1), DEFVAL(false), DEFVAL(0.0), DEFVAL(0.0));
	ClassDB::bind_method(D_METHOD("spawn_status_projectile", "projectile_type", "position", "velocity", "damage", "radius", "lifetime_seconds", "status_damage_per_tick", "status_interval_seconds", "status_duration_seconds", "explosion_radius", "explosion_damage_multiplier", "ricochets", "attraction_radius", "attraction_speed", "pierces_targets", "chill_duration_seconds", "chill_speed_multiplier", "chill_damage_multiplier", "orbit_angular_speed", "reaction_chain_id", "reaction_budget", "critical_hit", "homing_turn_rate", "homing_radius"),
			&CombatSimulation::spawn_status_projectile, DEFVAL(2.0), DEFVAL(0.5), DEFVAL(2.0), DEFVAL(0.0), DEFVAL(0.0), DEFVAL(0), DEFVAL(0.0), DEFVAL(0.0), DEFVAL(false), DEFVAL(0.0), DEFVAL(1.0), DEFVAL(1.0), DEFVAL(0.0), DEFVAL(0), DEFVAL(1), DEFVAL(false), DEFVAL(0.0), DEFVAL(0.0));
	ClassDB::bind_method(D_METHOD("spawn_xp_orb", "position", "xp_value"), &CombatSimulation::spawn_xp_orb);
	ClassDB::bind_method(D_METHOD("attract_xp_orbs", "target", "radius", "acceleration", "max_speed", "delta_seconds"),
			&CombatSimulation::attract_xp_orbs);
	ClassDB::bind_method(D_METHOD("stop_xp_orb_attraction"), &CombatSimulation::stop_xp_orb_attraction);
	ClassDB::bind_method(D_METHOD("collect_xp_orb", "index", "generation"), &CombatSimulation::collect_xp_orb);
	ClassDB::bind_method(D_METHOD("apply_damage_over_time", "index", "generation", "damage_per_tick", "interval_seconds", "duration_seconds", "status_type"),
			&CombatSimulation::apply_damage_over_time, DEFVAL(String("generic")));
	ClassDB::bind_method(D_METHOD("tick_damage_over_time", "index", "generation", "status_type"),
			&CombatSimulation::tick_damage_over_time);
	ClassDB::bind_method(D_METHOD("despawn", "index", "generation"), &CombatSimulation::despawn);
	ClassDB::bind_method(D_METHOD("kill_all"), &CombatSimulation::kill_all);
	ClassDB::bind_method(D_METHOD("pause"), &CombatSimulation::pause);
	ClassDB::bind_method(D_METHOD("resume"), &CombatSimulation::resume);
	ClassDB::bind_method(D_METHOD("step", "delta_seconds"), &CombatSimulation::step);
	ClassDB::bind_method(D_METHOD("set_speed", "multiplier"), &CombatSimulation::set_speed);
	ClassDB::bind_method(D_METHOD("apply_sandbox_overrides", "overrides"), &CombatSimulation::apply_sandbox_overrides);
	ClassDB::bind_method(D_METHOD("set_steering_target", "position", "max_speed", "separation_radius", "separation_weight"),
			&CombatSimulation::set_steering_target);
	ClassDB::bind_method(D_METHOD("set_enemy_speed_multiplier", "multiplier"),
			&CombatSimulation::set_enemy_speed_multiplier);
	ClassDB::bind_method(D_METHOD("damage_enemies_in_radius", "center", "radius", "damage"),
			&CombatSimulation::damage_enemies_in_radius);
	ClassDB::bind_method(D_METHOD("apply_finisher_damage", "target_index", "target_generation", "damage"),
			&CombatSimulation::apply_finisher_damage);
	ClassDB::bind_method(D_METHOD("dash_entity", "index", "generation", "velocity", "duration_seconds"),
			&CombatSimulation::dash_entity);
	ClassDB::bind_method(D_METHOD("acknowledge_events", "event_sequence"), &CombatSimulation::acknowledge_events);
	ClassDB::bind_method(D_METHOD("health_decay_amount", "active_time_seconds", "delta_seconds"),
			&CombatSimulation::health_decay_amount);
	ClassDB::bind_method(D_METHOD("kill_heal_amount", "threat_level"), &CombatSimulation::kill_heal_amount);
	ClassDB::bind_method(D_METHOD("initial_player_hp"), &CombatSimulation::initial_player_hp);
	ClassDB::bind_method(D_METHOD("reset"), &CombatSimulation::reset);
	ClassDB::bind_method(D_METHOD("snapshot"), &CombatSimulation::snapshot);
	ClassDB::bind_method(D_METHOD("capture_state"), &CombatSimulation::capture_state);
	ClassDB::bind_method(D_METHOD("restore_state", "state"), &CombatSimulation::restore_state);
}

CombatSimulation::CombatSimulation() {
	worker_.start();
}

int64_t CombatSimulation::spawn(String entity_type, int64_t count, Vector2 position, float hp, Vector2 velocity,
		float threat_level) {
	if (entity_type.is_empty() || count <= 0 || count > 500 || !std::isfinite(position.x) ||
			!std::isfinite(position.y) || !std::isfinite(hp) || hp <= 0.0F || !std::isfinite(velocity.x) ||
			!std::isfinite(velocity.y) || !std::isfinite(threat_level) || threat_level <= 0.0F) {
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
	command.threat_level = threat_level;
	return submit(std::move(command));
}

int64_t CombatSimulation::spawn_enemy(String enemy_type, int64_t count, Vector2 position, Vector2 velocity,
		float hp_multiplier, String affix, float movement_speed_multiplier) {
	const std::string type = enemy_type.utf8().get_data();
	const auto profile = dopamine::sim::enemy_profile(type);
	if (!profile.has_value()) {
		return 0;
	}
	if (count <= 0 || count > 500 || !std::isfinite(position.x) || !std::isfinite(position.y) ||
			!std::isfinite(velocity.x) || !std::isfinite(velocity.y) || !std::isfinite(hp_multiplier) ||
			hp_multiplier <= 0.0F || !std::isfinite(profile->health * hp_multiplier) ||
			!std::isfinite(movement_speed_multiplier) || movement_speed_multiplier < 0.1F ||
			movement_speed_multiplier > 10.0F || !std::isfinite(profile->speed * movement_speed_multiplier)) {
		return 0;
	}
	SimulationCommand command;
	command.type = CommandType::Spawn;
	command.entity_type = std::string(profile->id);
	command.enemy_affix = affix.utf8().get_data();
	std::vector<std::string> affixes;
	command.count = static_cast<uint32_t>(count);
	command.x = static_cast<float>(position.x);
	command.y = static_cast<float>(position.y);
	command.hp = profile->health * hp_multiplier;
	command.threat_level = profile->threat_level;
	command.enemy_move_speed = profile->speed;
	if (type == "elite") {
		if (command.enemy_affix.empty()) command.enemy_affix = "Hasted";
		affixes = split_affixes(command.enemy_affix);
		const std::vector<std::string> supported_affixes = {
				"Hasted", "Armored", "Regenerating", "Volatile", "Shielded", "Split-on-Death"};
		if (affixes.empty() || affixes.size() > 2 || std::any_of(affixes.begin(), affixes.end(),
				[&](const std::string &entry) {
					return !has_affix(supported_affixes, entry) ||
							std::count(affixes.begin(), affixes.end(), entry) != 1;
				})) {
			return 0;
		}
		command.enemy_move_speed = has_affix(affixes, "Hasted") ? 100.0F : 75.0F;
		if (has_affix(affixes, "Armored")) command.enemy_damage_taken_multiplier *= 0.65F;
		if (has_affix(affixes, "Shielded")) command.enemy_damage_taken_multiplier *= 0.5F;
		if (has_affix(affixes, "Regenerating")) command.enemy_health_regen_per_second = command.hp * 0.01F;
		if (has_affix(affixes, "Volatile")) {
			command.enemy_death_explosion_radius = 82.0F;
			command.enemy_death_explosion_damage = 18.0F;
		}
	} else if (!command.enemy_affix.empty()) {
		return 0;
	}
	command.enemy_move_speed *= movement_speed_multiplier;
	const Vector2 initial_velocity = velocity.length() > 0.0
			? velocity.normalized() * command.enemy_move_speed : Vector2(command.enemy_move_speed, 0.0);
	command.velocity_x = static_cast<float>(initial_velocity.x);
	command.velocity_y = static_cast<float>(initial_velocity.y);
	return submit(std::move(command));
}

int64_t CombatSimulation::spawn_projectile(String projectile_type, Vector2 position, Vector2 velocity,
		float damage, float radius, double lifetime_seconds, float burn_damage_per_tick,
		double burn_interval_seconds, double burn_duration_seconds, float explosion_radius,
		float explosion_damage_multiplier, int64_t ricochets, float attraction_radius,
		float attraction_speed, bool pierces_targets, double chill_duration_seconds,
		float chill_speed_multiplier, float chill_damage_multiplier, float orbit_angular_speed,
		int64_t reaction_chain_id, int64_t reaction_budget, bool critical_hit,
		float homing_turn_rate, float homing_radius) {
	if (ricochets < 0 || ricochets > 64 || reaction_chain_id < 0 || reaction_budget < 0 || reaction_budget > 64) {
		return 0;
	}
	return spawn_status_projectile(projectile_type, position, velocity, damage, radius, lifetime_seconds,
			burn_damage_per_tick, burn_interval_seconds, burn_duration_seconds,
			explosion_radius, explosion_damage_multiplier, ricochets, attraction_radius,
			attraction_speed, pierces_targets, chill_duration_seconds, chill_speed_multiplier,
			chill_damage_multiplier, orbit_angular_speed, reaction_chain_id, reaction_budget, critical_hit,
			homing_turn_rate, homing_radius);
}

int64_t CombatSimulation::spawn_status_projectile(String projectile_type, Vector2 position, Vector2 velocity,
		float damage, float radius, double lifetime_seconds, float status_damage_per_tick,
		double status_interval_seconds, double status_duration_seconds, float explosion_radius,
		float explosion_damage_multiplier, int64_t ricochets, float attraction_radius,
		float attraction_speed, bool pierces_targets, double chill_duration_seconds,
		float chill_speed_multiplier, float chill_damage_multiplier, float orbit_angular_speed,
		int64_t reaction_chain_id, int64_t reaction_budget, bool critical_hit,
		float homing_turn_rate, float homing_radius) {
	const std::string type = projectile_type.utf8().get_data();
	const bool applies_damage_over_time = type == "inferno_sprayer" || type == "bloodstorm_dagger" ||
			type == "wildfire_sprayer" || type == "toxic_cloud" || type == "pandemic_cloud";
	if (projectile_type.is_empty() || !std::isfinite(position.x) || !std::isfinite(position.y) ||
			!std::isfinite(velocity.x) || !std::isfinite(velocity.y) || !std::isfinite(damage) || damage <= 0.0F ||
			!std::isfinite(radius) || radius < 0.0F || !std::isfinite(lifetime_seconds) || lifetime_seconds <= 0.0 ||
			!std::isfinite(explosion_radius) || explosion_radius < 0.0F ||
			!std::isfinite(explosion_damage_multiplier) || explosion_damage_multiplier < 0.0F ||
			!std::isfinite(attraction_radius) || attraction_radius < 0.0F ||
			!std::isfinite(attraction_speed) || attraction_speed < 0.0F ||
			((attraction_radius > 0.0F) != (attraction_speed > 0.0F)) ||
			!std::isfinite(chill_duration_seconds) || chill_duration_seconds < 0.0 ||
			!std::isfinite(chill_speed_multiplier) || chill_speed_multiplier < 0.0F ||
			chill_speed_multiplier > 1.0F ||
			((chill_duration_seconds > 0.0) != (chill_speed_multiplier < 1.0F)) ||
			!std::isfinite(chill_damage_multiplier) || chill_damage_multiplier < 1.0F ||
			!std::isfinite(orbit_angular_speed) || orbit_angular_speed < 0.0F ||
			!std::isfinite(homing_turn_rate) || homing_turn_rate < 0.0F ||
			!std::isfinite(homing_radius) || homing_radius < 0.0F ||
			((homing_turn_rate > 0.0F) != (homing_radius > 0.0F)) ||
			ricochets < 0 || ricochets > 64 || reaction_chain_id < 0 || reaction_budget < 0 || reaction_budget > 64 ||
			!std::isfinite(damage * explosion_damage_multiplier)) {
		return 0;
	}
	if (applies_damage_over_time && (!std::isfinite(status_damage_per_tick) || status_damage_per_tick <= 0.0F ||
			!std::isfinite(status_interval_seconds) || status_interval_seconds <= 0.0 ||
			!std::isfinite(status_duration_seconds) || status_duration_seconds <= 0.0)) {
		return 0;
	}
	SimulationCommand command;
	command.type = CommandType::SpawnProjectile;
	command.entity_type = projectile_type.utf8().get_data();
	command.x = static_cast<float>(position.x);
	command.y = static_cast<float>(position.y);
	command.velocity_x = static_cast<float>(velocity.x);
	command.velocity_y = static_cast<float>(velocity.y);
	command.projectile_damage = damage;
	command.projectile_radius = radius;
	command.projectile_lifetime = lifetime_seconds;
	command.projectile_status_damage = status_damage_per_tick;
	command.projectile_status_interval = status_interval_seconds;
	command.projectile_status_duration = status_duration_seconds;
	command.projectile_explosion_radius = explosion_radius;
	command.projectile_explosion_damage_multiplier = explosion_damage_multiplier;
	command.projectile_ricochets = static_cast<uint32_t>(ricochets);
	command.projectile_attraction_radius = attraction_radius;
	command.projectile_attraction_speed = attraction_speed;
	command.projectile_pierces_targets = pierces_targets;
	command.projectile_chill_duration = chill_duration_seconds;
	command.projectile_chill_speed_multiplier = chill_speed_multiplier;
	command.projectile_chill_damage_multiplier = chill_damage_multiplier;
	command.projectile_orbit_angular_speed = orbit_angular_speed;
	command.projectile_homing_turn_rate = homing_turn_rate;
	command.projectile_homing_radius = homing_radius;
	command.projectile_reaction_chain_id = static_cast<uint64_t>(reaction_chain_id);
	command.projectile_reaction_budget = static_cast<uint32_t>(reaction_budget);
	command.projectile_critical_hit = critical_hit;
	return submit(std::move(command));
}

int64_t CombatSimulation::spawn_xp_orb(Vector2 position, float xp_value) {
	if (!std::isfinite(position.x) || !std::isfinite(position.y) || !std::isfinite(xp_value) || xp_value <= 0.0F) {
		return 0;
	}
	SimulationCommand command;
	command.type = CommandType::SpawnXpOrb;
	command.x = static_cast<float>(position.x);
	command.y = static_cast<float>(position.y);
	command.xp_value = xp_value;
	return submit(std::move(command));
}

int64_t CombatSimulation::attract_xp_orbs(Vector2 target, float radius, float acceleration, float max_speed,
		double delta_seconds) {
	if (!std::isfinite(target.x) || !std::isfinite(target.y) || !std::isfinite(radius) || radius <= 0.0F ||
			!std::isfinite(acceleration) || acceleration < 0.0F || !std::isfinite(max_speed) || max_speed <= 0.0F ||
			!std::isfinite(delta_seconds) || delta_seconds < 0.0) {
		return 0;
	}
	SimulationCommand command;
	command.type = CommandType::AttractXpOrbs;
	command.x = static_cast<float>(target.x);
	command.y = static_cast<float>(target.y);
	command.projectile_attraction_radius = radius;
	command.projectile_attraction_speed = acceleration;
	command.movement_duration_seconds = max_speed;
	command.attraction_delta_seconds = delta_seconds;
	return submit(std::move(command));
}

int64_t CombatSimulation::stop_xp_orb_attraction() {
	SimulationCommand command;
	command.type = CommandType::StopXpOrbAttraction;
	return submit(std::move(command));
}

int64_t CombatSimulation::collect_xp_orb(int64_t index, int64_t generation) {
	constexpr int64_t max_id = std::numeric_limits<uint32_t>::max();
	if (index < 0 || index > max_id || generation <= 0 || generation > max_id) {
		return 0;
	}
	SimulationCommand command;
	command.type = CommandType::CollectXpOrb;
	command.entity = {static_cast<uint32_t>(index), static_cast<uint32_t>(generation)};
	return submit(std::move(command));
}

int64_t CombatSimulation::apply_damage_over_time(int64_t index, int64_t generation, float damage_per_tick,
		double interval_seconds, double duration_seconds, String status_type) {
	constexpr int64_t max_id = std::numeric_limits<uint32_t>::max();
	const std::string status_type_value = status_type.utf8().get_data();
	if (index < 0 || index > max_id || generation <= 0 || generation > max_id ||
			!std::isfinite(damage_per_tick) || damage_per_tick <= 0.0F || !std::isfinite(interval_seconds) ||
			interval_seconds <= 0.0 || !std::isfinite(duration_seconds) || duration_seconds <= 0.0 ||
			(status_type_value != "generic" && status_type_value != "burn" &&
			 status_type_value != "poison" && status_type_value != "bleed")) {
		return 0;
	}
	SimulationCommand command;
	command.type = CommandType::ApplyDamageOverTime;
	command.entity = {static_cast<uint32_t>(index), static_cast<uint32_t>(generation)};
	command.status_damage_per_tick = damage_per_tick;
	command.status_interval_seconds = interval_seconds;
	command.status_duration_seconds = duration_seconds;
	command.status_type = status_type_value;
	return submit(std::move(command));
}

int64_t CombatSimulation::tick_damage_over_time(int64_t index, int64_t generation, String status_type) {
	if (index < 0 || generation <= 0 || (status_type != "burn" && status_type != "poison" && status_type != "bleed")) {
		return 0;
	}
	SimulationCommand command;
	command.type = CommandType::TickDamageOverTime;
	command.entity = {static_cast<uint32_t>(index), static_cast<uint32_t>(generation)};
	command.status_type = status_type.utf8().get_data();
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

int64_t CombatSimulation::apply_sandbox_overrides(Dictionary overrides) {
	if (overrides.size() != 4 || !overrides.has("max_speed") || !overrides.has("separation_radius") ||
			!overrides.has("separation_weight") || !overrides.has("cell_size")) {
		return 0;
	}
	const Variant max_speed = overrides["max_speed"];
	const Variant separation_radius = overrides["separation_radius"];
	const Variant separation_weight = overrides["separation_weight"];
	const Variant cell_size = overrides["cell_size"];
	const auto is_number = [](const Variant &value) {
		return value.get_type() == Variant::INT || value.get_type() == Variant::FLOAT;
	};
	if (!is_number(max_speed) || !is_number(separation_radius) || !is_number(separation_weight) || !is_number(cell_size)) {
		return 0;
	}
	SimulationCommand command;
	command.type = CommandType::ApplySandboxOverrides;
	command.steering.max_speed = static_cast<float>(static_cast<double>(max_speed));
	command.steering.separation_radius = static_cast<float>(static_cast<double>(separation_radius));
	command.steering.separation_weight = static_cast<float>(static_cast<double>(separation_weight));
	command.steering.spatial_hash.cell_size = static_cast<float>(static_cast<double>(cell_size));
	if (!std::isfinite(command.steering.max_speed) || command.steering.max_speed < 0.0F ||
			!std::isfinite(command.steering.separation_radius) || command.steering.separation_radius < 0.0F ||
			!std::isfinite(command.steering.separation_weight) || command.steering.separation_weight < 0.0F ||
			command.steering.separation_weight > 1.0F || !std::isfinite(command.steering.spatial_hash.cell_size) ||
			command.steering.spatial_hash.cell_size <= 0.0F) {
		return 0;
	}
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

int64_t CombatSimulation::set_enemy_speed_multiplier(float multiplier) {
	if (!std::isfinite(multiplier) || multiplier < 0.1F || multiplier > 10.0F) {
		return 0;
	}
	dopamine::sim::SimulationCommand command;
	command.type = dopamine::sim::CommandType::SetEnemySpeedMultiplier;
	command.enemy_speed_multiplier = multiplier;
	return submit(std::move(command));
}

int64_t CombatSimulation::damage_enemies_in_radius(Vector2 center, float radius, float damage) {
	if (!std::isfinite(center.x) || !std::isfinite(center.y) || !std::isfinite(radius) || radius < 0.0F ||
			!std::isfinite(damage) || damage <= 0.0F) {
		return 0;
	}
	dopamine::sim::SimulationCommand command;
	command.type = dopamine::sim::CommandType::DamageEnemiesInRadius;
	command.x = static_cast<float>(center.x);
	command.y = static_cast<float>(center.y);
	command.projectile_radius = radius;
	command.projectile_damage = damage;
	return submit(std::move(command));
}

int64_t CombatSimulation::apply_finisher_damage(int64_t target_index, int64_t target_generation, float damage) {
	constexpr int64_t max_id = std::numeric_limits<uint32_t>::max();
	if (target_index < 0 || target_index > max_id || target_generation <= 0 || target_generation > max_id ||
			!std::isfinite(damage) || damage <= 0.0F) {
		return 0;
	}
	SimulationCommand command;
	command.type = CommandType::ApplyFinisherDamage;
	command.entity = {static_cast<uint32_t>(target_index), static_cast<uint32_t>(target_generation)};
	command.projectile_damage = damage;
	return submit(std::move(command));
}

int64_t CombatSimulation::dash_entity(int64_t index, int64_t generation, Vector2 velocity, double duration_seconds) {
	constexpr int64_t max_id = std::numeric_limits<uint32_t>::max();
	if (index < 0 || index > max_id || generation <= 0 || generation > max_id ||
			!std::isfinite(velocity.x) || !std::isfinite(velocity.y) ||
			!std::isfinite(duration_seconds) || duration_seconds <= 0.0) {
		return 0;
	}
	SimulationCommand command;
	command.type = CommandType::DashEntity;
	command.entity = {static_cast<uint32_t>(index), static_cast<uint32_t>(generation)};
	command.velocity_x = static_cast<float>(velocity.x);
	command.velocity_y = static_cast<float>(velocity.y);
	command.movement_duration_seconds = duration_seconds;
	return submit(std::move(command));
}

int64_t CombatSimulation::acknowledge_events(int64_t event_sequence) {
	if (event_sequence < 0) {
		return 0;
	}
	SimulationCommand command;
	command.type = CommandType::AcknowledgeEvents;
	command.event_sequence = static_cast<uint64_t>(event_sequence);
	return submit(std::move(command));
}

double CombatSimulation::health_decay_amount(double active_time_seconds, double delta_seconds) const {
	return dopamine::sim::health_decay_amount(active_time_seconds, delta_seconds);
}

double CombatSimulation::kill_heal_amount(double threat_level) const {
	return dopamine::sim::kill_heal_amount(threat_level);
}

double CombatSimulation::initial_player_hp() const {
	return dopamine::sim::gdd_validated_player_initial_hp;
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
	Dictionary overrides;
	overrides["max_speed"] = state->steering_config.max_speed;
	overrides["separation_radius"] = state->steering_config.separation_radius;
	overrides["separation_weight"] = state->steering_config.separation_weight;
	overrides["cell_size"] = state->steering_config.spatial_hash.cell_size;
	result["sandbox_overrides"] = overrides;
	result["simulation_time"] = state->simulation_time;
	result["last_sequence"] = static_cast<int64_t>(state->last_sequence);
	result["rejected_commands"] = static_cast<int64_t>(state->rejected_commands);

	Dictionary metrics;
	metrics["frame_time_ms"] = state->frame_time_ms;
	metrics["entity_count"] = static_cast<int64_t>(state->entities.size());
	metrics["projectile_count"] = static_cast<int64_t>(state->projectile_count);
	metrics["xp_orb_count"] = static_cast<int64_t>(state->xp_orb_count);
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
		components["CollisionRadius"] = entity.type.collision_radius;
		components["ThreatLevel"] = entity.type.threat_level;
		components["MoveSpeed"] = entity.type.move_speed;
		if (!entity.type.affix.empty()) {
			components["Affix"] = String(entity.type.affix.c_str());
			Array affixes;
			for (const std::string &affix : split_affixes(entity.type.affix)) {
				affixes.append(String(affix.c_str()));
			}
			components["Affixes"] = affixes;
		}
		components["DamageTakenMultiplier"] = entity.type.damage_taken_multiplier;
		components["HealthRegenPerSecond"] = entity.type.health_regen_per_second;
		components["DeathExplosionRadius"] = entity.type.death_explosion_radius;
		components["DeathExplosionDamage"] = entity.type.death_explosion_damage;
		components["Supported"] = entity.type.supported;
		components["Shielded"] = entity.type.shielded ||
				entity.type.affix.find("Shielded") != std::string::npos;
		if (entity.type.support_radius > 0.0F) {
			components["SupportRadius"] = entity.type.support_radius;
			components["SupportSpeedMultiplier"] = entity.type.support_speed_multiplier;
		}
		if (entity.type.shield_radius > 0.0F) {
			components["ShieldRadius"] = entity.type.shield_radius;
			components["ShieldDamageMultiplier"] = entity.type.shield_damage_multiplier;
		}
		components["IsProjectile"] = entity.is_projectile;
		components["IsXpOrb"] = entity.is_xp_orb;
		components["XpValue"] = entity.xp_value;
		if (!entity.damage_over_time_effects.empty()) {
			Dictionary status;
			const auto &primary_status = entity.damage_over_time_effects.front();
			status["damage_per_tick"] = primary_status.damage_per_tick;
			status["interval_seconds"] = primary_status.interval_seconds;
			status["remaining_seconds"] = primary_status.remaining_seconds;
			status["time_to_tick"] = primary_status.time_to_tick;
			status["status_type"] = primary_status.status_type.c_str();
			components["DamageOverTime"] = status;
			Array statuses;
			for (const auto &effect : entity.damage_over_time_effects) {
				Dictionary entry;
				entry["damage_per_tick"] = effect.damage_per_tick;
				entry["interval_seconds"] = effect.interval_seconds;
				entry["remaining_seconds"] = effect.remaining_seconds;
				entry["time_to_tick"] = effect.time_to_tick;
				entry["status_type"] = effect.status_type.c_str();
				statuses.push_back(entry);
			}
			components["DamageOverTimeEffects"] = statuses;
		}
		if (entity.chill_effect.has_value()) {
			Dictionary chill;
			chill["remaining_seconds"] = entity.chill_effect->remaining_seconds;
			chill["speed_multiplier"] = entity.chill_effect->speed_multiplier;
			chill["damage_taken_multiplier"] = entity.chill_effect->damage_taken_multiplier;
			components["Chill"] = chill;
		}
		if (entity.movement_override.has_value()) {
			Dictionary movement;
			Dictionary movement_velocity;
			movement_velocity["x"] = entity.movement_override->velocity.x;
			movement_velocity["y"] = entity.movement_override->velocity.y;
			movement["velocity"] = movement_velocity;
			movement["remaining_seconds"] = entity.movement_override->remaining_seconds;
			components["MovementOverride"] = movement;
		}
		if (entity.is_projectile) {
			Dictionary projectile;
			projectile["damage"] = entity.projectile.damage;
			projectile["radius"] = entity.projectile.radius;
			projectile["remaining_seconds"] = entity.projectile.remaining_seconds;
			projectile["persistent_area"] = entity.projectile.persistent_area;
			projectile["area_radius"] = entity.projectile.explosion_radius;
			projectile["attraction_radius"] = entity.projectile.attraction_radius;
			projectile["attraction_speed"] = entity.projectile.attraction_speed;
			projectile["homing_turn_rate"] = entity.projectile.homing_turn_rate;
			projectile["homing_radius"] = entity.projectile.homing_radius;
			projectile["pierces_targets"] = entity.projectile.pierces_targets;
			projectile["chill_duration_seconds"] = entity.projectile.chill_duration_seconds;
			projectile["chill_speed_multiplier"] = entity.projectile.chill_speed_multiplier;
			projectile["chill_damage_multiplier"] = entity.projectile.chill_damage_multiplier;
			projectile["orbit_angular_speed"] = entity.projectile.orbit_angular_speed;
			projectile["reaction_chain_id"] = static_cast<int64_t>(entity.projectile.reaction_chain_id);
			projectile["reaction_budget"] = entity.projectile.reaction_budget;
			projectile["critical_hit"] = entity.projectile.critical_hit;
			components["Projectile"] = projectile;
		}

		Dictionary entry;
		entry["id"] = id;
		entry["components"] = components;
		entities.push_back(entry);
	}
	result["entities"] = entities;
	Array events;
	for (const dopamine::sim::CombatEvent &event : state->events) {
		Dictionary source;
		source["index"] = static_cast<int64_t>(event.source.index);
		source["generation"] = static_cast<int64_t>(event.source.generation);
		Dictionary target;
		target["index"] = static_cast<int64_t>(event.target.index);
		target["generation"] = static_cast<int64_t>(event.target.generation);
		Dictionary entry;
		entry["sequence"] = static_cast<int64_t>(event.sequence);
		entry["reaction_chain_id"] = static_cast<int64_t>(event.reaction_chain_id);
		entry["reaction_budget"] = event.reaction_budget;
		entry["critical_hit"] = event.critical_hit;
		switch (event.type) {
			case dopamine::sim::CombatEventType::Damage: entry["type"] = "damage"; break;
			case dopamine::sim::CombatEventType::Death: entry["type"] = "death"; break;
			case dopamine::sim::CombatEventType::XpCollected: entry["type"] = "xp_collected"; break;
		}
		entry["source"] = source;
		entry["target"] = target;
		entry["amount"] = event.amount;
		entry["is_damage_over_time"] = event.is_damage_over_time;
		entry["status_type"] = event.status_type.c_str();
		entry["target_was_chilled"] = event.target_was_chilled;
		entry["target_had_burn"] = event.target_had_burn;
		entry["target_had_poison"] = event.target_had_poison;
		entry["target_had_bleed"] = event.target_had_bleed;
		entry["remaining_health"] = event.remaining_health;
		entry["threat_level"] = event.threat_level;
		entry["target_type"] = event.target_type.c_str();
		entry["target_affix"] = event.target_affix.c_str();
		entry["source_type"] = event.source_type.c_str();
		Dictionary position;
		position["x"] = event.position_x;
		position["y"] = event.position_y;
		entry["position"] = position;
		events.push_back(entry);
	}
	result["events"] = events;

	PackedStringArray logs;
	for (const std::string &message : state->logs) {
		logs.push_back(String(message.c_str()));
	}
	result["logs"] = logs;
	return result;
}

Dictionary CombatSimulation::capture_state() {
	const std::optional<dopamine::sim::SimulationWorkerState> captured = worker_.capture_state();
	if (!captured.has_value()) {
		return {};
	}
	Ref<CombatSimulationSnapshot> native_state;
	native_state.instantiate();
	native_state->state_ = *captured;
	Dictionary result;
	result["format_version"] = static_cast<int64_t>(native_state->format_version_);
	result["native_state"] = native_state;
	return result;
}

bool CombatSimulation::restore_state(const Dictionary &state) {
	if (state.size() != 2 || !state.has("format_version") || !state.has("native_state") ||
			state["format_version"].get_type() != Variant::INT ||
			static_cast<uint32_t>(static_cast<int64_t>(state["format_version"])) != 18) {
		return false;
	}
	Ref<CombatSimulationSnapshot> native_state = state["native_state"];
	if (native_state.is_null() || !native_state->is_valid()) {
		return false;
	}
	worker_.stop();
	if (!worker_.restore_state(*native_state->state_)) {
		worker_.start();
		return false;
	}
	worker_.start();
	return true;
}

int64_t CombatSimulation::submit(SimulationCommand command) {
	const uint64_t sequence = worker_.submit(std::move(command));
	return sequence <= static_cast<uint64_t>(std::numeric_limits<int64_t>::max()) ? static_cast<int64_t>(sequence) : 0;
}
