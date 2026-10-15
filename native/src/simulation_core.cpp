#include "dopamine/simulation/simulation_core.hpp"

#include <cmath>
#include <limits>
#include <algorithm>
#include <stdexcept>
#include <utility>

namespace dopamine::sim {

EntityId SimulationCore::spawn(std::string type, float x, float y, float hp, float velocity_x, float velocity_y) {
	if (type.empty() || !std::isfinite(x) || !std::isfinite(y) || !std::isfinite(hp) || hp <= 0.0F ||
			!std::isfinite(velocity_x) || !std::isfinite(velocity_y)) {
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
	enemy_types_[index] = {std::move(type)};
	++entity_count_;
	return id;
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

void SimulationCore::advance(double delta_seconds) {
	if (!std::isfinite(delta_seconds) || delta_seconds < 0.0) {
		throw std::invalid_argument("simulation delta must be finite and non-negative");
	}
	for (std::size_t index = 0; index < slots_.size(); ++index) {
		if (slots_[index].active) {
			transforms_[index].x += velocities_[index].x * static_cast<float>(delta_seconds);
			transforms_[index].y += velocities_[index].y * static_cast<float>(delta_seconds);
		}
	}
	simulation_time_ += delta_seconds;
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
		if (!slots_[index].active) {
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
			next_velocities[index] = {
				static_cast<float>(steering_x / steering_length * config.max_speed),
				static_cast<float>(steering_y / steering_length * config.max_speed),
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
		if (!slots_[slot_index].active) {
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
	std::sort(result.begin(), result.end());
	return result;
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
	return Entity{id, transforms_[index], velocities_[index], health_[index], enemy_types_[index]};
}

std::vector<Entity> SimulationCore::snapshot() const {
	std::vector<Entity> result;
	result.reserve(entity_count_);
	for (uint32_t index = 0; index < slots_.size(); ++index) {
		if (slots_[index].active) {
			const EntityId id{index, slots_[index].generation};
			result.push_back({id, transforms_[index], velocities_[index], health_[index], enemy_types_[index]});
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
