#pragma once

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <unordered_map>
#include <utility>
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

struct SpatialHashConfig {
	float cell_size = 64.0F;
};

struct SteeringConfig {
	float max_speed = 75.0F;
	float separation_radius = 18.0F;
	float separation_weight = 0.5F;
	SpatialHashConfig spatial_hash;
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
	void steer_enemies_towards(float target_x, float target_y, SteeringConfig config = {});
	std::vector<EntityId> query_radius(float x, float y, float radius,
			SpatialHashConfig config = {}) const;

	std::optional<Entity> entity(EntityId id) const;
	std::vector<Entity> snapshot() const;
	std::size_t entity_count() const { return entity_count_; }
	double simulation_time() const { return simulation_time_; }

private:
	using SpatialCell = std::pair<int64_t, int64_t>;
	struct SpatialCellHash {
		size_t operator()(const SpatialCell &cell) const noexcept;
	};
	using SpatialIndex = std::unordered_map<SpatialCell, std::vector<uint32_t>, SpatialCellHash>;

	struct Slot {
		uint32_t generation = 1;
		bool active = false;
	};

	static void invalidate(Slot &slot);
	static int64_t cell_coordinate(float value, float cell_size);
	SpatialIndex build_spatial_index(SpatialHashConfig config) const;
	std::vector<uint32_t> query_spatial_index(const SpatialIndex &index, float x, float y,
			float radius, SpatialHashConfig config) const;
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
