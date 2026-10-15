#include "dopamine/simulation/simulation_core.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <stdexcept>
#include <utility>

namespace dopamine::sim {

namespace {

constexpr float enemy_collision_radius = 12.0F; // Provisional until hitboxes are specified.

} // namespace

std::optional<EnemyProfile> enemy_profile(std::string_view id) {
	// Starting values from the GDD are proposed and remain tunable.
	if (id == "chaser") return EnemyProfile{"chaser", 20.0F, 75.0F, 1.0F};
	if (id == "sprinter") return EnemyProfile{"sprinter", 12.0F, 125.0F, 1.0F};
	if (id == "tank") return EnemyProfile{"tank", 80.0F, 45.0F, 1.0F};
	if (id == "shooter") return EnemyProfile{"shooter", 25.0F, 65.0F, 1.0F};
	if (id == "exploder") return EnemyProfile{"exploder", 30.0F, 60.0F, 2.0F};
	if (id == "shielder") return EnemyProfile{"shielder", 40.0F, 45.0F, 2.0F, 0.0F, 1.0F, 150.0F, 0.65F};
	if (id == "summoner") return EnemyProfile{"summoner", 42.0F, 42.0F, 2.5F};
	if (id == "summoned") return EnemyProfile{"summoned", 12.0F, 90.0F, 0.5F};
	// Buffer stats and aura are proposed tuning, kept isolated from accepted GDD behavior.
	if (id == "buffer") return EnemyProfile{"buffer", 35.0F, 55.0F, 2.0F, 150.0F, 1.2F};
	// The Hasted elite profile is a proposed first affix prototype.
	if (id == "elite") return EnemyProfile{"elite", 50.0F, 100.0F, 3.0F};
	return std::nullopt;
}

double health_decay_amount(double active_time_seconds, double delta_seconds, HealthDecayConfig config) {
	if (!std::isfinite(active_time_seconds) || active_time_seconds < 0.0 ||
			!std::isfinite(delta_seconds) || delta_seconds < 0.0 ||
			!std::isfinite(config.base_rate) || config.base_rate < 0.0 ||
			!std::isfinite(config.increase_per_active_second) || config.increase_per_active_second < 0.0) {
		throw std::invalid_argument("invalid health decay interval or configuration");
	}
	const double amount = delta_seconds *
			(config.base_rate + config.increase_per_active_second *
					(active_time_seconds + delta_seconds * 0.5));
	if (!std::isfinite(amount)) {
		throw std::overflow_error("health decay amount overflowed");
	}
	return amount;
}

double kill_heal_amount(double threat_level, KillHealConfig config) {
	if (!std::isfinite(threat_level) || threat_level <= 0.0 ||
			!std::isfinite(config.base_amount) || config.base_amount < 0.0 ||
			!std::isfinite(config.amount_per_sqrt_threat) || config.amount_per_sqrt_threat < 0.0 ||
			!std::isfinite(config.minimum_threat) || config.minimum_threat <= 0.0 ||
			!std::isfinite(config.maximum_threat) || config.maximum_threat < config.minimum_threat) {
		throw std::invalid_argument("invalid kill heal threat or configuration");
	}
	const double bounded_threat = std::clamp(threat_level, config.minimum_threat, config.maximum_threat);
	const double amount = config.base_amount + config.amount_per_sqrt_threat * std::sqrt(bounded_threat);
	if (!std::isfinite(amount)) {
		throw std::overflow_error("kill heal amount overflowed");
	}
	return amount;
}

EntityId SimulationCore::spawn(std::string type, float x, float y, float hp, float velocity_x,
		float velocity_y, float threat_level, float move_speed) {
	if (type.empty() || !std::isfinite(x) || !std::isfinite(y) || !std::isfinite(hp) || hp <= 0.0F ||
			!std::isfinite(velocity_x) || !std::isfinite(velocity_y) || !std::isfinite(threat_level) ||
			threat_level <= 0.0F || !std::isfinite(move_speed) || move_speed < 0.0F) {
		throw std::invalid_argument("invalid simulation entity");
	}

	uint32_t index;
	if (free_indices_.empty()) {
		if (slots_.size() >= std::numeric_limits<uint32_t>::max()) {
			throw std::length_error("entity index capacity reached");
		}
		index = static_cast<uint32_t>(slots_.size());
		slots_.emplace_back();
		transforms_.emplace_back();
		velocities_.emplace_back();
		health_.emplace_back();
		enemy_types_.emplace_back();
		projectile_flags_.push_back(false);
		projectiles_.emplace_back();
		xp_orb_flags_.push_back(false);
		xp_values_.push_back(0.0F);
		damage_over_time_.emplace_back();
		chill_effects_.emplace_back();
	} else {
		index = free_indices_.back();
		free_indices_.pop_back();
	}

	Slot &slot = slots_[index];
	const EntityId id{index, slot.generation};
	slot.active = true;
	transforms_[index] = {x, y};
	velocities_[index] = {velocity_x, velocity_y};
	health_[index] = {hp, hp};
	const auto profile = enemy_profile(type);
	enemy_types_[index] = {std::move(type), threat_level, move_speed,
			profile ? profile->support_radius : 0.0F,
			profile ? profile->support_speed_multiplier : 1.0F,
			false,
			profile ? profile->shield_radius : 0.0F,
			profile ? profile->shield_damage_multiplier : 1.0F,
			false,
			{}};
	projectile_flags_[index] = false;
	projectiles_[index] = {};
	xp_orb_flags_[index] = false;
	xp_values_[index] = 0.0F;
	damage_over_time_[index].reset();
	chill_effects_[index].reset();
	++entity_count_;
	return id;
}

EntityId SimulationCore::spawn_projectile(std::string type, float x, float y, float damage, float radius,
		double lifetime_seconds, float velocity_x, float velocity_y, float status_damage_per_tick,
		double status_interval_seconds, double status_duration_seconds, float explosion_radius,
		float explosion_damage_multiplier, uint32_t ricochets, float attraction_radius,
		float attraction_speed, bool pierces_targets, double chill_duration_seconds,
		float chill_speed_multiplier, float chill_damage_multiplier) {
	if (!std::isfinite(damage) || damage <= 0.0F || !std::isfinite(radius) || radius < 0.0F ||
			!std::isfinite(lifetime_seconds) || lifetime_seconds <= 0.0 || type.empty() ||
			ricochets > 64 ||
			!std::isfinite(explosion_radius) || explosion_radius < 0.0F ||
			!std::isfinite(attraction_radius) || attraction_radius < 0.0F ||
			!std::isfinite(attraction_speed) || attraction_speed < 0.0F ||
			((attraction_radius > 0.0F) != (attraction_speed > 0.0F)) ||
			!std::isfinite(chill_duration_seconds) || chill_duration_seconds < 0.0 ||
			!std::isfinite(chill_speed_multiplier) || chill_speed_multiplier < 0.0F ||
			chill_speed_multiplier > 1.0F ||
			((chill_duration_seconds > 0.0) != (chill_speed_multiplier < 1.0F)) ||
			!std::isfinite(chill_damage_multiplier) || chill_damage_multiplier < 1.0F ||
			!std::isfinite(explosion_damage_multiplier) || explosion_damage_multiplier < 0.0F ||
			!std::isfinite(damage * explosion_damage_multiplier)) {
		throw std::invalid_argument("invalid projectile");
	}
	const bool applies_damage_over_time = type == "inferno_sprayer" || type == "bloodstorm_dagger" ||
			type == "wildfire_sprayer" || type == "toxic_cloud" || type == "pandemic_cloud";
	if (applies_damage_over_time && (!std::isfinite(status_damage_per_tick) || status_damage_per_tick <= 0.0F ||
			!std::isfinite(status_interval_seconds) || status_interval_seconds <= 0.0 ||
			!std::isfinite(status_duration_seconds) || status_duration_seconds <= 0.0)) {
		throw std::invalid_argument("projectile status values must be positive and finite");
	}
	const EntityId id = spawn(type, x, y, 1.0F, velocity_x, velocity_y);
	projectile_flags_[id.index] = true;
	ProjectileData projectile;
	projectile.damage = damage;
	projectile.radius = radius;
	projectile.remaining_seconds = lifetime_seconds;
	projectile.applies_damage_over_time = applies_damage_over_time;
	projectile.status_damage_per_tick = status_damage_per_tick;
	projectile.status_interval_seconds = status_interval_seconds;
	projectile.status_duration_seconds = status_duration_seconds;
	projectile.explosion_radius = explosion_radius;
	projectile.explosion_damage_multiplier = explosion_damage_multiplier;
	projectile.ricochets_remaining = ricochets;
	projectile.attraction_radius = attraction_radius;
	projectile.attraction_speed = attraction_speed;
	projectile.pierces_targets = pierces_targets;
	projectile.chill_duration_seconds = chill_duration_seconds;
	projectile.chill_speed_multiplier = chill_speed_multiplier;
	projectile.chill_damage_multiplier = chill_damage_multiplier;
	if (type == "infinite_circuit_branch") {
		float nearest_distance_squared = enemy_collision_radius * enemy_collision_radius;
		for (uint32_t index = 0; index < slots_.size(); ++index) {
			if (!slots_[index].active || projectile_flags_[index] || xp_orb_flags_[index] || health_[index].current <= 0.0F) {
				continue;
			}
			const float dx = transforms_[index].x - x;
			const float dy = transforms_[index].y - y;
			const float distance_squared = dx * dx + dy * dy;
			if (distance_squared < nearest_distance_squared) {
				nearest_distance_squared = distance_squared;
				projectile.ignores_source_entity = true;
				projectile.source_entity = {index, slots_[index].generation};
			}
		}
	}
	projectiles_[id.index] = projectile;
	return id;
}

EntityId SimulationCore::spawn_xp_orb(float x, float y, float xp_value) {
	if (!std::isfinite(xp_value) || xp_value <= 0.0F) {
		throw std::invalid_argument("XP orb value must be positive and finite");
	}
	const EntityId id = spawn("xp_orb", x, y, 1.0F, 0.0F, 0.0F);
	xp_orb_flags_[id.index] = true;
	xp_values_[id.index] = xp_value;
	return id;
}

bool SimulationCore::apply_damage_over_time(EntityId target, float damage_per_tick, double interval_seconds,
		double duration_seconds) {
	if (!std::isfinite(damage_per_tick) || damage_per_tick <= 0.0F || !std::isfinite(interval_seconds) ||
			interval_seconds <= 0.0 || !std::isfinite(duration_seconds) || duration_seconds <= 0.0) {
		throw std::invalid_argument("damage-over-time values must be positive and finite");
	}
	if (target.index >= slots_.size() || !slots_[target.index].active ||
			slots_[target.index].generation != target.generation || projectile_flags_[target.index] ||
			xp_orb_flags_[target.index]) {
		return false;
	}
	damage_over_time_[target.index] = DamageOverTime{damage_per_tick, interval_seconds, duration_seconds, interval_seconds};
	return true;
}

bool SimulationCore::apply_chill(EntityId target, double duration_seconds, float speed_multiplier,
		float damage_taken_multiplier) {
	if (!std::isfinite(duration_seconds) || duration_seconds <= 0.0 || !std::isfinite(speed_multiplier) ||
			speed_multiplier < 0.0F || speed_multiplier >= 1.0F ||
			!std::isfinite(damage_taken_multiplier) || damage_taken_multiplier < 1.0F) {
		throw std::invalid_argument("invalid chill duration or multipliers");
	}
	if (target.index >= slots_.size() || !slots_[target.index].active ||
			slots_[target.index].generation != target.generation || projectile_flags_[target.index] ||
			xp_orb_flags_[target.index]) {
		return false;
	}
	if (chill_effects_[target.index].has_value()) {
		ChillEffect &current = *chill_effects_[target.index];
		current.remaining_seconds = std::max(current.remaining_seconds, duration_seconds);
		current.speed_multiplier = std::min(current.speed_multiplier, speed_multiplier);
		current.damage_taken_multiplier = std::max(current.damage_taken_multiplier, damage_taken_multiplier);
	} else {
		chill_effects_[target.index] = ChillEffect{duration_seconds, speed_multiplier, damage_taken_multiplier};
	}
	return true;
}

void SimulationCore::apply_direct_damage(EntityId source, EntityId target, float amount,
		std::vector<CombatEvent> &events) {
	if (!std::isfinite(amount) || amount <= 0.0F) {
		throw std::invalid_argument("invalid direct damage");
	}
	std::vector<EntityId> to_despawn;
	apply_damage(source, target, amount, events, to_despawn);
	for (const EntityId id : to_despawn) {
		despawn(id);
	}
}

bool SimulationCore::collect_xp_orb(EntityId id, std::vector<CombatEvent> &events) {
	if (id.index >= slots_.size() || !slots_[id.index].active ||
			slots_[id.index].generation != id.generation || !xp_orb_flags_[id.index]) {
		return false;
	}
	CombatEvent event;
	event.sequence = next_event_sequence_++;
	event.type = CombatEventType::XpCollected;
	event.target = id;
	event.amount = xp_values_[id.index];
	event.position_x = transforms_[id.index].x;
	event.position_y = transforms_[id.index].y;
	if (!despawn(id)) {
		return false;
	}
	events.push_back(event);
	return true;
}

bool SimulationCore::despawn(EntityId id) {
	if (id.index >= slots_.size()) {
		return false;
	}

	Slot &slot = slots_[id.index];
	if (!slot.active || slot.generation != id.generation) {
		return false;
	}

	slot.active = false;
	invalidate(slot);
	free_indices_.push_back(id.index);
	--entity_count_;
	return true;
}

void SimulationCore::reset() {
	for (uint32_t index = 0; index < slots_.size(); ++index) {
		Slot &slot = slots_[index];
		if (slot.active) {
			slot.active = false;
			invalidate(slot);
			free_indices_.push_back(index);
		}
	}
	entity_count_ = 0;
	simulation_time_ = 0.0;
	for (auto &effect : damage_over_time_) effect.reset();
	for (auto &effect : chill_effects_) effect.reset();
}

SimulationCoreState SimulationCore::capture_state() const {
	SimulationCoreState state;
	state.entities.reserve(slots_.size());
	state.active_slots.reserve(slots_.size());
	for (uint32_t index = 0; index < slots_.size(); ++index) {
		Entity entity;
		entity.id = {index, slots_[index].generation};
		entity.transform = transforms_[index];
		entity.velocity = velocities_[index];
		entity.health = health_[index];
		entity.type = enemy_types_[index];
		entity.is_projectile = projectile_flags_[index];
		entity.projectile = projectiles_[index];
		entity.is_xp_orb = xp_orb_flags_[index];
		entity.xp_value = xp_values_[index];
		entity.damage_over_time = damage_over_time_[index];
		entity.chill_effect = chill_effects_[index];
		state.entities.push_back(std::move(entity));
		state.active_slots.push_back(slots_[index].active);
	}
	state.free_indices = free_indices_;
	state.entity_count = entity_count_;
	state.simulation_time = simulation_time_;
	state.next_event_sequence = next_event_sequence_;
	return state;
}

void SimulationCore::restore_state(const SimulationCoreState &state) {
	const std::size_t slot_count = state.entities.size();
	if (slot_count > std::numeric_limits<uint32_t>::max() || state.active_slots.size() != slot_count ||
			state.entity_count > slot_count || !std::isfinite(state.simulation_time) || state.simulation_time < 0.0 ||
			state.next_event_sequence == 0) {
		throw std::invalid_argument("invalid simulation core state header");
	}

	std::vector<bool> free_slots(slot_count, false);
	for (uint32_t index : state.free_indices) {
		if (index >= slot_count || free_slots[index] || state.active_slots[index]) {
			throw std::invalid_argument("invalid simulation core free-index list");
		}
		free_slots[index] = true;
	}

	std::size_t active_count = 0;
	for (std::size_t index = 0; index < slot_count; ++index) {
		const Entity &entity = state.entities[index];
		if (entity.id.index != index || entity.id.generation == 0) {
			throw std::invalid_argument("invalid simulation core entity identity");
		}
		if (!state.active_slots[index]) {
			if (!free_slots[index]) {
				throw std::invalid_argument("inactive simulation core slot is not reusable");
			}
			continue;
		}
		++active_count;
		const bool valid_transform = std::isfinite(entity.transform.x) && std::isfinite(entity.transform.y) &&
				std::isfinite(entity.velocity.x) && std::isfinite(entity.velocity.y);
		const bool valid_health = std::isfinite(entity.health.current) && std::isfinite(entity.health.maximum) &&
				entity.health.maximum > 0.0F && entity.health.current > 0.0F &&
				entity.health.current <= entity.health.maximum;
		const bool valid_type = !entity.type.id.empty() && std::isfinite(entity.type.threat_level) &&
				entity.type.threat_level > 0.0F && std::isfinite(entity.type.move_speed) && entity.type.move_speed >= 0.0F;
		const bool valid_support = std::isfinite(entity.type.support_radius) && entity.type.support_radius >= 0.0F &&
				std::isfinite(entity.type.support_speed_multiplier) && entity.type.support_speed_multiplier >= 1.0F &&
				(!entity.type.supported || entity.type.support_radius == 0.0F);
		const bool valid_shield = std::isfinite(entity.type.shield_radius) && entity.type.shield_radius >= 0.0F &&
				std::isfinite(entity.type.shield_damage_multiplier) && entity.type.shield_damage_multiplier > 0.0F &&
				entity.type.shield_damage_multiplier <= 1.0F &&
				(entity.type.shielded
					? entity.type.shield_radius == 0.0F && entity.type.shield_source.generation != 0 &&
						entity.type.shield_source.index < slot_count
					: entity.type.shield_source.generation == 0);
		if (!valid_transform || !valid_health || !valid_type || !valid_support || !valid_shield ||
				(entity.is_projectile && entity.is_xp_orb)) {
			throw std::invalid_argument("invalid active simulation core entity");
		}
		if (entity.is_projectile) {
			const ProjectileData &projectile = entity.projectile;
			bool valid_hit_targets = projectile.ricochets_remaining <= 64 && projectile.hit_targets.size() < slot_count;
			for (std::size_t hit_index = 0; valid_hit_targets && hit_index < projectile.hit_targets.size(); ++hit_index) {
				const EntityId hit_target = projectile.hit_targets[hit_index];
				valid_hit_targets = hit_target.index < slot_count && hit_target.generation != 0 &&
						std::find(projectile.hit_targets.begin(), projectile.hit_targets.begin() + hit_index, hit_target) ==
						projectile.hit_targets.begin() + hit_index;
			}
			if (!std::isfinite(projectile.damage) || projectile.damage <= 0.0F ||
					!std::isfinite(projectile.radius) || projectile.radius < 0.0F ||
					!std::isfinite(projectile.remaining_seconds) || projectile.remaining_seconds <= 0.0 ||
					!std::isfinite(projectile.explosion_radius) || projectile.explosion_radius < 0.0F ||
					!std::isfinite(projectile.explosion_damage_multiplier) ||
					projectile.explosion_damage_multiplier < 0.0F ||
					!std::isfinite(projectile.attraction_radius) || projectile.attraction_radius < 0.0F ||
					!std::isfinite(projectile.attraction_speed) || projectile.attraction_speed < 0.0F ||
					((projectile.attraction_radius > 0.0F) != (projectile.attraction_speed > 0.0F)) ||
					!std::isfinite(projectile.chill_duration_seconds) || projectile.chill_duration_seconds < 0.0 ||
					!std::isfinite(projectile.chill_speed_multiplier) || projectile.chill_speed_multiplier < 0.0F ||
					projectile.chill_speed_multiplier > 1.0F ||
					((projectile.chill_duration_seconds > 0.0) != (projectile.chill_speed_multiplier < 1.0F)) ||
					!std::isfinite(projectile.chill_damage_multiplier) || projectile.chill_damage_multiplier < 1.0F ||
					!valid_hit_targets ||
					(projectile.applies_damage_over_time && (!std::isfinite(projectile.status_damage_per_tick) ||
							!std::isfinite(projectile.status_interval_seconds) ||
							!std::isfinite(projectile.status_duration_seconds) || projectile.status_damage_per_tick <= 0.0F ||
							projectile.status_interval_seconds <= 0.0 || projectile.status_duration_seconds <= 0.0)) ||
					(entity.damage_over_time.has_value() || entity.chill_effect.has_value())) {
				throw std::invalid_argument("invalid simulation core projectile state");
			}
		} else if (entity.is_xp_orb) {
			if (!std::isfinite(entity.xp_value) || entity.xp_value <= 0.0F || entity.damage_over_time.has_value() ||
					entity.chill_effect.has_value()) {
				throw std::invalid_argument("invalid simulation core XP orb state");
			}
		} else if (entity.damage_over_time.has_value()) {
			const DamageOverTime &status = *entity.damage_over_time;
			if (!std::isfinite(status.damage_per_tick) || status.damage_per_tick <= 0.0F ||
					!std::isfinite(status.interval_seconds) || status.interval_seconds <= 0.0 ||
					!std::isfinite(status.remaining_seconds) || status.remaining_seconds <= 0.0 ||
					!std::isfinite(status.time_to_tick) || status.time_to_tick < 0.0 ||
					status.time_to_tick > status.interval_seconds) {
				throw std::invalid_argument("invalid simulation core damage-over-time state");
			}
		}
		if (entity.chill_effect.has_value()) {
			const ChillEffect &chill = *entity.chill_effect;
			if (!std::isfinite(chill.remaining_seconds) || chill.remaining_seconds <= 0.0 ||
					!std::isfinite(chill.speed_multiplier) || chill.speed_multiplier < 0.0F ||
					chill.speed_multiplier >= 1.0F ||
					!std::isfinite(chill.damage_taken_multiplier) || chill.damage_taken_multiplier < 1.0F ||
					entity.is_projectile || entity.is_xp_orb) {
				throw std::invalid_argument("invalid simulation core chill state");
			}
		}
	}
	if (active_count != state.entity_count || state.free_indices.size() + active_count != slot_count) {
		throw std::invalid_argument("inconsistent simulation core entity counts");
	}

	SimulationCore restored;
	restored.slots_.reserve(slot_count);
	restored.transforms_.reserve(slot_count);
	restored.velocities_.reserve(slot_count);
	restored.health_.reserve(slot_count);
	restored.enemy_types_.reserve(slot_count);
	restored.projectile_flags_.reserve(slot_count);
	restored.projectiles_.reserve(slot_count);
	restored.xp_orb_flags_.reserve(slot_count);
	restored.xp_values_.reserve(slot_count);
	restored.damage_over_time_.reserve(slot_count);
	restored.chill_effects_.reserve(slot_count);
	for (std::size_t index = 0; index < slot_count; ++index) {
		const Entity &entity = state.entities[index];
		restored.slots_.push_back({entity.id.generation, state.active_slots[index]});
		restored.transforms_.push_back(entity.transform);
		restored.velocities_.push_back(entity.velocity);
		restored.health_.push_back(entity.health);
		restored.enemy_types_.push_back(entity.type);
		restored.projectile_flags_.push_back(entity.is_projectile);
		restored.projectiles_.push_back(entity.projectile);
		restored.xp_orb_flags_.push_back(entity.is_xp_orb);
		restored.xp_values_.push_back(entity.xp_value);
		restored.damage_over_time_.push_back(entity.damage_over_time);
		restored.chill_effects_.push_back(entity.chill_effect);
	}
	restored.free_indices_ = state.free_indices;
	restored.entity_count_ = state.entity_count;
	restored.simulation_time_ = state.simulation_time;
	restored.next_event_sequence_ = state.next_event_sequence;
	*this = std::move(restored);
}

std::size_t SimulationCore::estimate_event_count_upper_bound(double delta_seconds) const {
	if (!std::isfinite(delta_seconds) || delta_seconds < 0.0) {
		throw std::invalid_argument("simulation delta must be finite and non-negative");
	}
	if (delta_seconds == 0.0) {
		return 0;
	}
	std::size_t estimate = 0;
	const auto add_saturated = [&estimate](long double amount) {
		const long double remaining = static_cast<long double>(std::numeric_limits<std::size_t>::max() - estimate);
		estimate += static_cast<std::size_t>(std::min(amount, remaining));
	};
	std::size_t projectile_count = 0;
	std::size_t piercing_projectile_count = 0;
	std::size_t target_count = 0;
	bool has_explosive_projectile = false;
	for (std::size_t index = 0; index < slots_.size(); ++index) {
		if (!slots_[index].active) {
			continue;
		}
		if (projectile_flags_[index]) {
			++projectile_count;
			piercing_projectile_count += projectiles_[index].pierces_targets ? 1U : 0U;
			has_explosive_projectile = has_explosive_projectile ||
					(projectiles_[index].explosion_radius > 0.0F &&
					 projectiles_[index].explosion_damage_multiplier > 0.0F);
			continue;
		}
		if (!xp_orb_flags_[index] && health_[index].current > 0.0F) {
			++target_count;
		}
		if (!damage_over_time_[index].has_value() || health_[index].current <= 0.0F) {
			continue;
		}
		const DamageOverTime &status = *damage_over_time_[index];
		const double active_seconds = std::min(delta_seconds, status.remaining_seconds);
		const double first_tick = std::max(0.0, status.time_to_tick);
		if (active_seconds + 1e-12 < first_tick) {
			continue;
		}
		const long double ticks = std::floor((static_cast<long double>(active_seconds) - first_tick + 1e-12L) /
				status.interval_seconds) + 1.0L;
		// Each tick emits damage, and at most one of those ticks can also emit death.
		add_saturated(ticks + 1.0L);
	}
	add_saturated(static_cast<long double>(projectile_count) * 2.0L);
	add_saturated(static_cast<long double>(piercing_projectile_count) * target_count * 2.0L);
	if (has_explosive_projectile) {
		// The whole advance shares a 500-target splash cap; each hit can emit damage and death.
		add_saturated(1000.0L);
	}
	return estimate;
}

std::vector<CombatEvent> SimulationCore::advance(double delta_seconds) {
	constexpr std::size_t max_explosion_targets_per_advance = 500; // Proposed safety budget for secondary blast hits.
	constexpr std::size_t max_events_per_advance = 8192;
	if (!std::isfinite(delta_seconds) || delta_seconds < 0.0) {
		throw std::invalid_argument("simulation delta must be finite and non-negative");
	}
	if (estimate_event_count_upper_bound(delta_seconds) > max_events_per_advance) {
		throw std::length_error("simulation step exceeds the combat event budget");
	}
	bool has_active_projectile = false;
	for (std::size_t index = 0; index < slots_.size(); ++index) {
		has_active_projectile = has_active_projectile || (slots_[index].active && projectile_flags_[index]);
	}
	if (has_active_projectile) {
		const SpatialIndex spatial_index = build_spatial_index({});
		std::vector<float> attraction_strength(slots_.size(), 0.0F);
		std::vector<Velocity2D> attracted_velocities = velocities_;
		for (uint32_t field_index = 0; field_index < slots_.size(); ++field_index) {
			if (!slots_[field_index].active || !projectile_flags_[field_index] ||
					projectiles_[field_index].attraction_radius <= 0.0F) {
				continue;
			}
			const Transform2D &center = transforms_[field_index];
			const ProjectileData &field = projectiles_[field_index];
			const auto candidates = query_spatial_index(spatial_index, center.x, center.y, field.attraction_radius, {});
			for (uint32_t target_index : candidates) {
				const float dx = center.x - transforms_[target_index].x;
				const float dy = center.y - transforms_[target_index].y;
				const float distance = std::hypot(dx, dy);
				if (distance <= 0.0F || distance >= field.attraction_radius) {
					continue;
				}
				const float strength = field.attraction_speed * (1.0F - distance / field.attraction_radius);
				if (strength > attraction_strength[target_index]) {
					attraction_strength[target_index] = strength;
					attracted_velocities[target_index] = {dx / distance * strength, dy / distance * strength};
				}
			}
		}
		for (uint32_t index = 0; index < slots_.size(); ++index) {
			if (attraction_strength[index] > 0.0F) {
				velocities_[index] = attracted_velocities[index];
			}
		}
	}
	const std::vector<Transform2D> start_positions = has_active_projectile
			? transforms_
			: std::vector<Transform2D>{};
	for (std::size_t index = 0; index < slots_.size(); ++index) {
		if (slots_[index].active && !projectile_flags_[index] && !xp_orb_flags_[index]) {
			transforms_[index].x += velocities_[index].x * static_cast<float>(delta_seconds);
			transforms_[index].y += velocities_[index].y * static_cast<float>(delta_seconds);
		}
	}

	std::vector<CombatEvent> events;
	std::vector<EntityId> to_despawn;
	std::size_t explosion_targets_processed = 0;
	for (uint32_t index = 0; index < slots_.size(); ++index) {
		if (!slots_[index].active || !damage_over_time_[index].has_value()) {
			continue;
		}
		DamageOverTime &status = *damage_over_time_[index];
		const double active_seconds = std::min(delta_seconds, status.remaining_seconds);
		status.remaining_seconds -= active_seconds;
		status.time_to_tick -= active_seconds;
		const EntityId target{index, slots_[index].generation};
		while (status.time_to_tick <= 1e-12 && status.remaining_seconds >= -1e-12) {
			const std::size_t event_start = events.size();
			apply_damage(target, target, status.damage_per_tick, events, to_despawn);
			if (event_start < events.size()) {
				events[event_start].is_damage_over_time = true;
			}
			status.time_to_tick += status.interval_seconds;
			if (health_[index].current <= 0.0F) {
				break;
			}
		}
		if (status.remaining_seconds <= 1e-12 || health_[index].current <= 0.0F) {
			damage_over_time_[index].reset();
		}
	}
	if (has_active_projectile) {
		float max_target_displacement = 0.0F;
		for (uint32_t index = 0; index < slots_.size(); ++index) {
			if (slots_[index].active && !projectile_flags_[index] && !xp_orb_flags_[index]) {
				max_target_displacement = std::max(max_target_displacement,
						static_cast<float>(std::hypot(transforms_[index].x - start_positions[index].x,
								transforms_[index].y - start_positions[index].y)));
			}
		}
		constexpr float enemy_collision_radius = 12.0F; // Provisional until hitboxes are specified.
		const SpatialIndex spatial_index = build_spatial_index({});
		for (uint32_t projectile_index = 0; projectile_index < slots_.size(); ++projectile_index) {
			if (!slots_[projectile_index].active || !projectile_flags_[projectile_index]) {
				continue;
			}
			ProjectileData &projectile = projectiles_[projectile_index];
			const Transform2D projectile_start = start_positions[projectile_index];
			const double travel_seconds = std::min(delta_seconds, projectile.remaining_seconds);
			const Transform2D projectile_end = transforms_[projectile_index] = {
				projectile_start.x + velocities_[projectile_index].x * static_cast<float>(travel_seconds),
				projectile_start.y + velocities_[projectile_index].y * static_cast<float>(travel_seconds),
			};
			const float segment_x = projectile_end.x - projectile_start.x;
			const float segment_y = projectile_end.y - projectile_start.y;
			const float half_segment_length = std::hypot(segment_x, segment_y) * 0.5F;
			const float broadphase_radius = half_segment_length + max_target_displacement + projectile.radius + enemy_collision_radius;
			const float midpoint_x = (projectile_start.x + projectile_end.x) * 0.5F;
			const float midpoint_y = (projectile_start.y + projectile_end.y) * 0.5F;
			const auto candidates = query_spatial_index(spatial_index, midpoint_x, midpoint_y,
					broadphase_radius, {});
			bool hit = false;
			// Survival's player is a Godot CharacterBody2D outside the ECS. Enemy shots
			// travel through the same projectile/lifetime path, while Godot resolves
			// their player collision; they must not damage other ECS enemies.
			if (enemy_types_[projectile_index].id != "enemy_projectile") {
			for (uint32_t target_index : candidates) {
				const EntityId potential_target{target_index, slots_[target_index].generation};
				if (target_index == projectile_index || projectile_flags_[target_index] || xp_orb_flags_[target_index] ||
						health_[target_index].current <= 0.0F ||
						std::find(projectile.hit_targets.begin(), projectile.hit_targets.end(), potential_target) != projectile.hit_targets.end() ||
						(projectile.ignores_source_entity && potential_target == projectile.source_entity)) {
					continue;
				}
				const double relative_start_x = static_cast<double>(projectile_start.x) - start_positions[target_index].x;
				const double relative_start_y = static_cast<double>(projectile_start.y) - start_positions[target_index].y;
				const double relative_end_x = static_cast<double>(projectile_end.x) - transforms_[target_index].x;
				const double relative_end_y = static_cast<double>(projectile_end.y) - transforms_[target_index].y;
				const double relative_delta_x = relative_end_x - relative_start_x;
				const double relative_delta_y = relative_end_y - relative_start_y;
				const double segment_length_squared = relative_delta_x * relative_delta_x + relative_delta_y * relative_delta_y;
				const double closest_t = segment_length_squared > 0.0
						? std::clamp(-(relative_start_x * relative_delta_x + relative_start_y * relative_delta_y) /
								segment_length_squared, 0.0, 1.0)
						: 0.0;
				const double closest_x = relative_start_x + relative_delta_x * closest_t;
				const double closest_y = relative_start_y + relative_delta_y * closest_t;
				const double combined_radius = projectile.radius + enemy_collision_radius;
				if (closest_x * closest_x + closest_y * closest_y > combined_radius * combined_radius) {
					continue;
				}

				const EntityId projectile_id{projectile_index, slots_[projectile_index].generation};
				const EntityId target_id{target_index, slots_[target_index].generation};
				apply_damage(projectile_id, target_id, projectile.damage, events, to_despawn);
				bool ricocheted = false;
				if (projectile.chill_duration_seconds > 0.0 && health_[target_index].current > 0.0F) {
					apply_chill(target_id, projectile.chill_duration_seconds, projectile.chill_speed_multiplier,
							projectile.chill_damage_multiplier);
				}
				if (projectile.applies_damage_over_time && health_[target_index].current > 0.0F) {
					apply_damage_over_time(target_id, projectile.status_damage_per_tick,
							projectile.status_interval_seconds, projectile.status_duration_seconds);
				}
				if (projectile.explosion_radius > 0.0F && projectile.explosion_damage_multiplier > 0.0F) {
					const auto splash_targets = query_spatial_index(spatial_index, transforms_[target_index].x,
							transforms_[target_index].y, projectile.explosion_radius, {});
					for (uint32_t splash_index : splash_targets) {
						if (explosion_targets_processed >= max_explosion_targets_per_advance) {
							break;
						}
						if (splash_index == target_index || projectile_flags_[splash_index] || xp_orb_flags_[splash_index] ||
								health_[splash_index].current <= 0.0F) {
							continue;
						}
						++explosion_targets_processed;
						const EntityId splash_id{splash_index, slots_[splash_index].generation};
						apply_damage(projectile_id, splash_id, projectile.damage * projectile.explosion_damage_multiplier,
								events, to_despawn);
						if (projectile.chill_duration_seconds > 0.0 && health_[splash_index].current > 0.0F) {
							apply_chill(splash_id, projectile.chill_duration_seconds,
									projectile.chill_speed_multiplier, projectile.chill_damage_multiplier);
						}
						if (projectile.applies_damage_over_time && health_[splash_index].current > 0.0F) {
							apply_damage_over_time(splash_id, projectile.status_damage_per_tick,
									projectile.status_interval_seconds, projectile.status_duration_seconds);
						}
					}
				}
				if (projectile.pierces_targets) {
					projectile.hit_targets.push_back(target_id);
					continue;
				}
				if (projectile.ricochets_remaining > 0) {
					projectile.hit_targets.push_back(target_id);
					--projectile.ricochets_remaining;
					const float speed = std::hypot(velocities_[projectile_index].x, velocities_[projectile_index].y);
					float nearest_distance_squared = std::numeric_limits<float>::infinity();
					uint32_t nearest_target = static_cast<uint32_t>(slots_.size());
					// ponytail: one slot scan per hit; replace with a spatial query if dense-world profiling warrants it.
					for (uint32_t candidate_index = 0; candidate_index < slots_.size(); ++candidate_index) {
						if (!slots_[candidate_index].active || projectile_flags_[candidate_index] || xp_orb_flags_[candidate_index] ||
								health_[candidate_index].current <= 0.0F) {
							continue;
						}
						const EntityId candidate_id{candidate_index, slots_[candidate_index].generation};
						if (std::find(projectile.hit_targets.begin(), projectile.hit_targets.end(), candidate_id) != projectile.hit_targets.end()) {
							continue;
						}
						const float dx = transforms_[candidate_index].x - transforms_[target_index].x;
						const float dy = transforms_[candidate_index].y - transforms_[target_index].y;
						const float distance_squared = dx * dx + dy * dy;
						if (distance_squared < nearest_distance_squared) {
							nearest_distance_squared = distance_squared;
							nearest_target = candidate_index;
						}
					}
					if (nearest_target < slots_.size() && speed > 0.0F) {
						const float dx = transforms_[nearest_target].x - transforms_[target_index].x;
						const float dy = transforms_[nearest_target].y - transforms_[target_index].y;
						const float distance = std::hypot(dx, dy);
						if (distance > 0.0F) {
							transforms_[projectile_index] = transforms_[target_index];
							velocities_[projectile_index] = {dx / distance * speed, dy / distance * speed};
							ricocheted = true;
						}
					}
				}
				hit = !ricocheted;
				break;
			}
			}
			projectile.remaining_seconds -= delta_seconds;
			if (hit || projectile.remaining_seconds <= 0.0) {
				to_despawn.push_back({projectile_index, slots_[projectile_index].generation});
			}
		}
	}
	for (EntityId id : to_despawn) {
		despawn(id);
	}
	for (std::size_t index = 0; index < slots_.size(); ++index) {
		if (!slots_[index].active || !chill_effects_[index].has_value()) {
			continue;
		}
		chill_effects_[index]->remaining_seconds -= delta_seconds;
		if (chill_effects_[index]->remaining_seconds <= 1e-12 || health_[index].current <= 0.0F) {
			chill_effects_[index].reset();
		}
	}
	simulation_time_ += delta_seconds;
	return events;
}

void SimulationCore::steer_enemies_towards(float target_x, float target_y, SteeringConfig config) {
	if (!std::isfinite(target_x) || !std::isfinite(target_y) || !std::isfinite(config.max_speed) ||
			config.max_speed < 0.0F || !std::isfinite(config.separation_radius) ||
			config.separation_radius < 0.0F || !std::isfinite(config.separation_weight) ||
			config.separation_weight < 0.0F || config.separation_weight > 1.0F ||
			!std::isfinite(config.spatial_hash.cell_size) || config.spatial_hash.cell_size <= 0.0F) {
		throw std::invalid_argument("invalid steering configuration");
	}

	std::vector<Velocity2D> next_velocities = velocities_;
	float maximum_support_radius = 0.0F;
	float maximum_shield_radius = 0.0F;
	for (uint32_t index = 0; index < slots_.size(); ++index) {
		if (slots_[index].active && !projectile_flags_[index] && !xp_orb_flags_[index]) {
			maximum_support_radius = std::max(maximum_support_radius, enemy_types_[index].support_radius);
			maximum_shield_radius = std::max(maximum_shield_radius, enemy_types_[index].shield_radius);
		}
	}
	const bool needs_spatial_index = (config.separation_radius > 0.0F && config.separation_weight > 0.0F) ||
			maximum_support_radius > 0.0F || maximum_shield_radius > 0.0F;
	const SpatialIndex spatial_index = needs_spatial_index ? build_spatial_index(config.spatial_hash) : SpatialIndex{};
	for (uint32_t index = 0; index < slots_.size(); ++index) {
		if (!slots_[index].active || projectile_flags_[index] || xp_orb_flags_[index]) {
			continue;
		}
		enemy_types_[index].supported = false;
		enemy_types_[index].shielded = false;
		enemy_types_[index].shield_source = {};
		const Transform2D &position = transforms_[index];
		const double target_dx = static_cast<double>(target_x) - position.x;
		const double target_dy = static_cast<double>(target_y) - position.y;
		const double target_length = std::hypot(target_dx, target_dy);
		double steering_x = target_length > 0.0 ? target_dx / target_length : 0.0;
		double steering_y = target_length > 0.0 ? target_dy / target_length : 0.0;

		if (config.separation_radius > 0.0F && config.separation_weight > 0.0F) {
			const auto neighbors = query_spatial_index(spatial_index, position.x, position.y,
					config.separation_radius, config.spatial_hash);
			double separation_x = 0.0;
			double separation_y = 0.0;
			for (uint32_t neighbor_index : neighbors) {
				if (neighbor_index == index) {
					continue;
				}
				const double dx = static_cast<double>(position.x) - transforms_[neighbor_index].x;
				const double dy = static_cast<double>(position.y) - transforms_[neighbor_index].y;
				const double distance = std::hypot(dx, dy);
				if (distance > 0.0) {
					const double strength = (config.separation_radius - distance) / config.separation_radius;
					separation_x += dx / distance * strength;
					separation_y += dy / distance * strength;
				} else {
					separation_x += neighbor_index < index ? 1.0 : -1.0;
				}
			}
			const double separation_length = std::hypot(separation_x, separation_y);
			if (separation_length > 0.0) {
				steering_x = steering_x * (1.0 - config.separation_weight) +
						separation_x / separation_length * config.separation_weight;
				steering_y = steering_y * (1.0 - config.separation_weight) +
						separation_y / separation_length * config.separation_weight;
			}
		}

		const double steering_length = std::hypot(steering_x, steering_y);
		if (steering_length > 0.0) {
			float max_speed = enemy_types_[index].move_speed > 0.0F
					? enemy_types_[index].move_speed
					: config.max_speed;
			if (enemy_types_[index].support_radius <= 0.0F && maximum_support_radius > 0.0F) {
				const auto support_neighbors = query_spatial_index(spatial_index, position.x, position.y,
						maximum_support_radius, config.spatial_hash);
				for (uint32_t support_index : support_neighbors) {
					const EnemyType &support = enemy_types_[support_index];
					if (support.support_radius <= 0.0F || health_[support_index].current <= 0.0F) {
						continue;
					}
					const double dx = static_cast<double>(position.x) - transforms_[support_index].x;
					const double dy = static_cast<double>(position.y) - transforms_[support_index].y;
					if (dx * dx + dy * dy > static_cast<double>(support.support_radius) * support.support_radius) {
						continue;
					}
					enemy_types_[index].supported = true;
					max_speed = std::max(max_speed, enemy_types_[index].move_speed > 0.0F
							? enemy_types_[index].move_speed * support.support_speed_multiplier
							: config.max_speed * support.support_speed_multiplier);
				}
			}
			if (chill_effects_[index].has_value()) {
				max_speed *= chill_effects_[index]->speed_multiplier;
			}
			next_velocities[index] = {
				static_cast<float>(steering_x / steering_length * max_speed),
				static_cast<float>(steering_y / steering_length * max_speed),
			};
		} else {
			next_velocities[index] = {};
		}
		if (enemy_types_[index].shield_radius <= 0.0F && maximum_shield_radius > 0.0F) {
			const auto shield_neighbors = query_spatial_index(spatial_index, position.x, position.y,
					maximum_shield_radius, config.spatial_hash);
			for (uint32_t shield_index : shield_neighbors) {
				const EnemyType &shield = enemy_types_[shield_index];
				if (shield.shield_radius <= 0.0F || health_[shield_index].current <= 0.0F) {
					continue;
				}
				const double dx = static_cast<double>(position.x) - transforms_[shield_index].x;
				const double dy = static_cast<double>(position.y) - transforms_[shield_index].y;
				if (dx * dx + dy * dy > static_cast<double>(shield.shield_radius) * shield.shield_radius) {
					continue;
				}
				enemy_types_[index].shielded = true;
				enemy_types_[index].shield_source = {shield_index, slots_[shield_index].generation};
				break;
			}
		}
	}
	velocities_.swap(next_velocities);
}

std::vector<EntityId> SimulationCore::query_radius(float x, float y, float radius, SpatialHashConfig config) const {
	if (!std::isfinite(x) || !std::isfinite(y) || !std::isfinite(radius) || radius < 0.0F ||
			!std::isfinite(config.cell_size) || config.cell_size <= 0.0F) {
		throw std::invalid_argument("invalid spatial query");
	}
	if (entity_count_ == 0) {
		return {};
	}

	const SpatialIndex index = build_spatial_index(config);
	const std::vector<uint32_t> candidates = query_spatial_index(index, x, y, radius, config);
	std::vector<EntityId> result;
	result.reserve(candidates.size());
	for (uint32_t entity_index : candidates) {
		result.push_back({entity_index, slots_[entity_index].generation});
	}
	return result;
}

size_t SimulationCore::SpatialCellHash::operator()(const SpatialCell &cell) const noexcept {
	const size_t first = std::hash<int64_t>{}(cell.first);
	const size_t second = std::hash<int64_t>{}(cell.second);
	return first ^ (second + 0x9e3779b9U + (first << 6U) + (first >> 2U));
}

SimulationCore::SpatialIndex SimulationCore::build_spatial_index(SpatialHashConfig config) const {
	SpatialIndex index;
	index.reserve(entity_count_);
	for (uint32_t slot_index = 0; slot_index < slots_.size(); ++slot_index) {
		if (!slots_[slot_index].active || projectile_flags_[slot_index] || xp_orb_flags_[slot_index]) {
			continue;
		}
		const Transform2D &position = transforms_[slot_index];
		index[{cell_coordinate(position.x, config.cell_size), cell_coordinate(position.y, config.cell_size)}]
				.push_back(slot_index);
	}
	return index;
}

std::vector<uint32_t> SimulationCore::query_spatial_index(const SpatialIndex &index, float x, float y,
		float radius, SpatialHashConfig config) const {
	const int64_t min_x = cell_coordinate(x - radius, config.cell_size);
	const int64_t max_x = cell_coordinate(x + radius, config.cell_size);
	const int64_t min_y = cell_coordinate(y - radius, config.cell_size);
	const int64_t max_y = cell_coordinate(y + radius, config.cell_size);
	const double radius_squared = static_cast<double>(radius) * radius;
	std::vector<uint32_t> result;
	const long double queried_cells =
			(static_cast<long double>(max_x) - min_x + 1.0L) *
			(static_cast<long double>(max_y) - min_y + 1.0L);
	if (queried_cells > static_cast<long double>(index.size()) * 4.0L) {
		for (const auto &[cell, entities] : index) {
			(void)cell;
			for (uint32_t slot_index : entities) {
				const double dx = static_cast<double>(transforms_[slot_index].x) - x;
				const double dy = static_cast<double>(transforms_[slot_index].y) - y;
				if (dx * dx + dy * dy <= radius_squared) {
					result.push_back(slot_index);
				}
			}
		}
	} else {
		for (int64_t cell_x = min_x; cell_x <= max_x; ++cell_x) {
			for (int64_t cell_y = min_y; cell_y <= max_y; ++cell_y) {
				const auto found = index.find({cell_x, cell_y});
				if (found == index.end()) {
					continue;
				}
				for (uint32_t slot_index : found->second) {
					const double dx = static_cast<double>(transforms_[slot_index].x) - x;
					const double dy = static_cast<double>(transforms_[slot_index].y) - y;
					if (dx * dx + dy * dy <= radius_squared) {
						result.push_back(slot_index);
					}
				}
			}
		}
	}
	std::sort(result.begin(), result.end());
	return result;
}

void SimulationCore::apply_damage(EntityId source, EntityId target, float amount,
		std::vector<CombatEvent> &events, std::vector<EntityId> &deferred_despawns) {
	if (target.index >= slots_.size() || !slots_[target.index].active ||
			slots_[target.index].generation != target.generation || !std::isfinite(amount) || amount <= 0.0F) {
		return;
	}
	Health &target_health = health_[target.index];
	const bool target_was_chilled = chill_effects_[target.index].has_value();
	EnemyType &target_type = enemy_types_[target.index];
	if (target_type.shielded) {
		const EntityId source_id = target_type.shield_source;
		const bool source_active = source_id.index < slots_.size() && slots_[source_id.index].active &&
				slots_[source_id.index].generation == source_id.generation &&
				health_[source_id.index].current > 0.0F && enemy_types_[source_id.index].shield_radius > 0.0F;
		if (source_active) {
			const double dx = static_cast<double>(transforms_[target.index].x) - transforms_[source_id.index].x;
			const double dy = static_cast<double>(transforms_[target.index].y) - transforms_[source_id.index].y;
			const float radius = enemy_types_[source_id.index].shield_radius;
			if (dx * dx + dy * dy <= static_cast<double>(radius) * radius) {
				amount *= enemy_types_[source_id.index].shield_damage_multiplier;
			} else {
				target_type.shielded = false;
				target_type.shield_source = {};
			}
		} else {
			target_type.shielded = false;
			target_type.shield_source = {};
		}
	}
	if (target_was_chilled) {
		amount *= chill_effects_[target.index]->damage_taken_multiplier;
	}
	target_health.current = std::max(0.0F, target_health.current - amount);
	const std::string source_type = source.index < slots_.size() && slots_[source.index].active &&
			slots_[source.index].generation == source.generation ? enemy_types_[source.index].id : std::string{};
	events.push_back({next_event_sequence_++, CombatEventType::Damage, source, target,
			amount, target_health.current, enemy_types_[target.index].threat_level,
			transforms_[target.index].x, transforms_[target.index].y, enemy_types_[target.index].id});
	events.back().source_type = source_type;
	events.back().target_was_chilled = target_was_chilled;
	if (target_health.current <= 0.0F) {
		events.push_back({next_event_sequence_++, CombatEventType::Death, source, target,
				0.0F, 0.0F, enemy_types_[target.index].threat_level,
				transforms_[target.index].x, transforms_[target.index].y, enemy_types_[target.index].id});
		events.back().source_type = source_type;
		events.back().target_was_chilled = target_was_chilled;
		deferred_despawns.push_back(target);
	}
}

std::optional<Entity> SimulationCore::entity(EntityId id) const {
	if (id.index >= slots_.size()) {
		return std::nullopt;
	}
	const Slot &slot = slots_[id.index];
	if (!slot.active || slot.generation != id.generation) {
		return std::nullopt;
	}
	const size_t index = static_cast<size_t>(id.index);
	return Entity{id, transforms_[index], velocities_[index], health_[index], enemy_types_[index],
			projectile_flags_[index], projectiles_[index], xp_orb_flags_[index], xp_values_[index],
			damage_over_time_[index], chill_effects_[index]};
}

std::vector<Entity> SimulationCore::snapshot() const {
	std::vector<Entity> result;
	result.reserve(entity_count_);
	for (uint32_t index = 0; index < slots_.size(); ++index) {
		if (slots_[index].active) {
			const EntityId id{index, slots_[index].generation};
			result.push_back({id, transforms_[index], velocities_[index], health_[index], enemy_types_[index],
					projectile_flags_[index], projectiles_[index], xp_orb_flags_[index], xp_values_[index],
					damage_over_time_[index], chill_effects_[index]});
		}
	}
	return result;
}

void SimulationCore::invalidate(Slot &slot) {
	++slot.generation;
	if (slot.generation == 0) {
		++slot.generation;
	}
}

int64_t SimulationCore::cell_coordinate(float value, float cell_size) {
	const double coordinate = std::floor(static_cast<double>(value) / cell_size);
	if (coordinate < static_cast<double>(std::numeric_limits<int64_t>::min()) ||
			coordinate > static_cast<double>(std::numeric_limits<int64_t>::max())) {
		throw std::invalid_argument("spatial coordinate outside supported range");
	}
	return static_cast<int64_t>(coordinate);
}

} // namespace dopamine::sim
