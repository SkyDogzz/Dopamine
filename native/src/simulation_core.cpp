#include "dopamine/simulation/simulation_core.hpp"

#include <cmath>
#include <limits>
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

} // namespace dopamine::sim
