#pragma once

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace dopamine::sim {

struct EntityId {
	uint32_t index = 0;
	uint32_t generation = 0;

	friend bool operator==(const EntityId &, const EntityId &) = default;
};

struct Transform2D {
	float x = 0.0F;
	float y = 0.0F;
};

struct Velocity2D {
	float x = 0.0F;
	float y = 0.0F;
};

struct Health {
	float current = 1.0F;
	float maximum = 1.0F;
};

struct EnemyType {
	std::string id;
};

struct Entity {
	EntityId id;
	Transform2D transform;
	Velocity2D velocity;
	Health health;
	EnemyType type;
};

class SimulationCore {
public:
	EntityId spawn(std::string type, float x, float y, float hp, float velocity_x, float velocity_y);
	bool despawn(EntityId id);
	void reset();
	void advance(double delta_seconds);

	std::optional<Entity> entity(EntityId id) const;
	std::vector<Entity> snapshot() const;
	std::size_t entity_count() const { return entity_count_; }
	double simulation_time() const { return simulation_time_; }

private:
	struct Slot {
		uint32_t generation = 1;
		bool active = false;
	};

	static void invalidate(Slot &slot);
	std::vector<Slot> slots_;
	std::vector<Transform2D> transforms_;
	std::vector<Velocity2D> velocities_;
	std::vector<Health> health_;
	std::vector<EnemyType> enemy_types_;
	std::vector<uint32_t> free_indices_;
	std::size_t entity_count_ = 0;
	double simulation_time_ = 0.0;
};

} // namespace dopamine::sim
