#pragma once

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <unordered_map>
#include <utility>
#include <vector>

namespace dopamine::sim {

inline constexpr float gdd_validated_player_initial_hp = 100.0F;

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

struct HealthDecayConfig {
	double base_rate = 1.5;
	double increase_per_active_second = 0.004;
};

double health_decay_amount(double active_time_seconds, double delta_seconds,
		HealthDecayConfig config = {});

struct KillHealConfig {
	double base_amount = 2.0;
	double amount_per_sqrt_threat = 3.0;
	double minimum_threat = 0.5;
	double maximum_threat = 25.0;
};

double kill_heal_amount(double threat_level, KillHealConfig config = {});

struct EnemyType {
	std::string id;
	float threat_level = 1.0F;
	float move_speed = 0.0F;
};

struct EnemyProfile {
	std::string_view id;
	float health = 1.0F;
	float speed = 0.0F;
	float threat_level = 1.0F;
};

std::optional<EnemyProfile> enemy_profile(std::string_view id);

struct ProjectileData {
	float damage = 1.0F;
	float radius = 3.0F;
	double remaining_seconds = 5.0;
	bool applies_damage_over_time = false;
	float status_damage_per_tick = 0.0F;
	double status_interval_seconds = 0.0;
	double status_duration_seconds = 0.0;
	float explosion_radius = 0.0F;
	float explosion_damage_multiplier = 0.0F;
	uint32_t ricochets_remaining = 0;
	std::vector<EntityId> hit_targets;
	float attraction_radius = 0.0F;
	float attraction_speed = 0.0F;
	bool pierces_targets = false;
	double chill_duration_seconds = 0.0;
	float chill_speed_multiplier = 1.0F;
	float chill_damage_multiplier = 1.0F;
	bool ignores_source_entity = false;
	EntityId source_entity;
};

struct DamageOverTime {
	float damage_per_tick = 0.0F;
	double interval_seconds = 0.0;
	double remaining_seconds = 0.0;
	double time_to_tick = 0.0;
};

struct ChillEffect {
	double remaining_seconds = 0.0;
	float speed_multiplier = 1.0F;
	float damage_taken_multiplier = 1.0F;
};

enum class CombatEventType {
	Damage,
	Death,
	XpCollected,
};

struct CombatEvent {
	uint64_t sequence = 0;
	CombatEventType type = CombatEventType::Damage;
	EntityId source;
	EntityId target;
	float amount = 0.0F;
	float remaining_health = 0.0F;
	float threat_level = 1.0F;
	float position_x = 0.0F;
	float position_y = 0.0F;
	std::string target_type;
	std::string source_type;
	bool is_damage_over_time = false;
	bool target_was_chilled = false;
};

struct Entity {
	EntityId id;
	Transform2D transform;
	Velocity2D velocity;
	Health health;
	EnemyType type;
	bool is_projectile = false;
	ProjectileData projectile;
	bool is_xp_orb = false;
	float xp_value = 0.0F;
	std::optional<DamageOverTime> damage_over_time;
	std::optional<ChillEffect> chill_effect;
};

struct SimulationCoreState {
	// Slot-aligned data keeps inactive generations and free-index reuse intact.
	std::vector<Entity> entities;
	std::vector<bool> active_slots;
	std::vector<uint32_t> free_indices;
	std::size_t entity_count = 0;
	double simulation_time = 0.0;
	uint64_t next_event_sequence = 1;
};

class SimulationCore {
public:
	EntityId spawn(std::string type, float x, float y, float hp, float velocity_x, float velocity_y,
			float threat_level = 1.0F, float move_speed = 0.0F);
	EntityId spawn_projectile(std::string type, float x, float y, float damage, float radius,
			double lifetime_seconds, float velocity_x, float velocity_y, float status_damage_per_tick = 2.0F,
			double status_interval_seconds = 0.5, double status_duration_seconds = 2.0,
			float explosion_radius = 0.0F, float explosion_damage_multiplier = 0.0F,
			uint32_t ricochets = 0, float attraction_radius = 0.0F, float attraction_speed = 0.0F,
			bool pierces_targets = false, double chill_duration_seconds = 0.0,
			float chill_speed_multiplier = 1.0F, float chill_damage_multiplier = 1.0F);
	EntityId spawn_xp_orb(float x, float y, float xp_value);
	bool apply_damage_over_time(EntityId target, float damage_per_tick, double interval_seconds,
			double duration_seconds);
	bool apply_chill(EntityId target, double duration_seconds, float speed_multiplier,
		float damage_taken_multiplier = 1.0F);
	void apply_direct_damage(EntityId source, EntityId target, float amount, std::vector<CombatEvent> &events);
	bool collect_xp_orb(EntityId id, std::vector<CombatEvent> &events);
	bool despawn(EntityId id);
	void reset();
	SimulationCoreState capture_state() const;
	void restore_state(const SimulationCoreState &state);
	std::size_t estimate_event_count_upper_bound(double delta_seconds) const;
	std::vector<CombatEvent> advance(double delta_seconds);
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
	void apply_damage(EntityId source, EntityId target, float amount,
			std::vector<CombatEvent> &events, std::vector<EntityId> &deferred_despawns);
	std::vector<Slot> slots_;
	std::vector<Transform2D> transforms_;
	std::vector<Velocity2D> velocities_;
	std::vector<Health> health_;
	std::vector<EnemyType> enemy_types_;
	std::vector<bool> projectile_flags_;
	std::vector<ProjectileData> projectiles_;
	std::vector<bool> xp_orb_flags_;
	std::vector<float> xp_values_;
	std::vector<std::optional<DamageOverTime>> damage_over_time_;
	std::vector<std::optional<ChillEffect>> chill_effects_;
	std::vector<uint32_t> free_indices_;
	std::size_t entity_count_ = 0;
	double simulation_time_ = 0.0;
	uint64_t next_event_sequence_ = 1;
};

} // namespace dopamine::sim
