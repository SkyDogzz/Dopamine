#include "dopamine/simulation/simulation_core.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <stdexcept>
#include <utility>

namespace dopamine::sim {

std::optional<EnemyProfile> enemy_profile(std::string_view id) {
	// Starting values from the GDD are proposed and remain tunable.
	if (id == "chaser") return EnemyProfile{"chaser", 20.0F, 75.0F, 1.0F};
	if (id == "sprinter") return EnemyProfile{"sprinter", 12.0F, 125.0F, 1.0F};
	if (id == "tank") return EnemyProfile{"tank", 80.0F, 45.0F, 1.0F};
	if (id == "shooter") return EnemyProfile{"shooter", 25.0F, 65.0F, 1.0F};
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
	enemy_types_[index] = {std::move(type), threat_level, move_speed};
	projectile_flags_[index] = false;
	projectiles_[index] = {};
	xp_orb_flags_[index] = false;
	xp_values_[index] = 0.0F;
	damage_over_time_[index].reset();
	++entity_count_;
	return id;
}

EntityId SimulationCore::spawn_projectile(std::string type, float x, float y, float damage, float radius,
		double lifetime_seconds, float velocity_x, float velocity_y, float status_damage_per_tick,
		double status_interval_seconds, double status_duration_seconds) {
	if (!std::isfinite(damage) || damage <= 0.0F || !std::isfinite(radius) || radius < 0.0F ||
			!std::isfinite(lifetime_seconds) || lifetime_seconds <= 0.0 || type.empty()) {
		throw std::invalid_argument("invalid projectile");
	}
	const bool applies_damage_over_time = type == "inferno_sprayer" || type == "bloodstorm_dagger";
	if (applies_damage_over_time && (!std::isfinite(status_damage_per_tick) || status_damage_per_tick <= 0.0F ||
			!std::isfinite(status_interval_seconds) || status_interval_seconds <= 0.0 ||
			!std::isfinite(status_duration_seconds) || status_duration_seconds <= 0.0)) {
		throw std::invalid_argument("projectile status values must be positive and finite");
	}
	const EntityId id = spawn(type, x, y, 1.0F, velocity_x, velocity_y);
	projectile_flags_[id.index] = true;
	projectiles_[id.index] = {damage, radius, lifetime_seconds, applies_damage_over_time,
			status_damage_per_tick, status_interval_seconds, status_duration_seconds};
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
}

std::vector<CombatEvent> SimulationCore::advance(double delta_seconds) {
	if (!std::isfinite(delta_seconds) || delta_seconds < 0.0) {
		throw std::invalid_argument("simulation delta must be finite and non-negative");
	}
	bool has_active_projectile = false;
	for (std::size_t index = 0; index < slots_.size(); ++index) {
		has_active_projectile = has_active_projectile || (slots_[index].active && projectile_flags_[index]);
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
	for (uint32_t index = 0; index < slots_.size(); ++index) {
		if (!slots_[index].active || !damage_over_time_[index].has_value()) {
			continue;
		}
		DamageOverTime &status = *damage_over_time_[index];
		const double active_seconds = std::min(delta_seconds, status.remaining_seconds);
		status.remaining_seconds -= active_seconds;
		status.time_to_tick -= delta_seconds;
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
			for (uint32_t target_index : candidates) {
				if (target_index == projectile_index || projectile_flags_[target_index] || xp_orb_flags_[target_index] ||
						health_[target_index].current <= 0.0F) {
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
				if (projectile.applies_damage_over_time && health_[target_index].current > 0.0F) {
					apply_damage_over_time(target_id, projectile.status_damage_per_tick,
							projectile.status_interval_seconds, projectile.status_duration_seconds);
				}
				hit = true;
				break;
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
	const SpatialIndex spatial_index = config.separation_radius > 0.0F && config.separation_weight > 0.0F
			? build_spatial_index(config.spatial_hash)
			: SpatialIndex{};
	for (uint32_t index = 0; index < slots_.size(); ++index) {
		if (!slots_[index].active || projectile_flags_[index] || xp_orb_flags_[index]) {
			continue;
		}
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
			const float max_speed = enemy_types_[index].move_speed > 0.0F
					? enemy_types_[index].move_speed
					: config.max_speed;
			next_velocities[index] = {
				static_cast<float>(steering_x / steering_length * max_speed),
				static_cast<float>(steering_y / steering_length * max_speed),
			};
		} else {
			next_velocities[index] = {};
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
	target_health.current = std::max(0.0F, target_health.current - amount);
	events.push_back({next_event_sequence_++, CombatEventType::Damage, source, target,
			amount, target_health.current, enemy_types_[target.index].threat_level,
			transforms_[target.index].x, transforms_[target.index].y, enemy_types_[target.index].id});
	if (target_health.current <= 0.0F) {
		events.push_back({next_event_sequence_++, CombatEventType::Death, source, target,
				0.0F, 0.0F, enemy_types_[target.index].threat_level,
				transforms_[target.index].x, transforms_[target.index].y, enemy_types_[target.index].id});
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
			damage_over_time_[index]};
}

std::vector<Entity> SimulationCore::snapshot() const {
	std::vector<Entity> result;
	result.reserve(entity_count_);
	for (uint32_t index = 0; index < slots_.size(); ++index) {
		if (slots_[index].active) {
			const EntityId id{index, slots_[index].generation};
			result.push_back({id, transforms_[index], velocities_[index], health_[index], enemy_types_[index],
					projectile_flags_[index], projectiles_[index], xp_orb_flags_[index], xp_values_[index],
					damage_over_time_[index]});
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
