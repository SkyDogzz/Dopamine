#pragma once

#include "dopamine/simulation/simulation_worker.hpp"

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class CombatSimulation : public RefCounted {
	GDCLASS(CombatSimulation, RefCounted)

protected:
	static void _bind_methods();

public:
	CombatSimulation();

	int64_t spawn(String entity_type, int64_t count, Vector2 position, float hp, Vector2 velocity,
			float threat_level = 1.0F);
	int64_t spawn_enemy(String enemy_type, int64_t count, Vector2 position, Vector2 velocity,
			float hp_multiplier = 1.0F, String affix = String());
	int64_t spawn_projectile(String projectile_type, Vector2 position, Vector2 velocity, float damage,
			float radius, double lifetime_seconds, float burn_damage_per_tick = 2.0F,
			double burn_interval_seconds = 0.5, double burn_duration_seconds = 2.0,
			float explosion_radius = 0.0F, float explosion_damage_multiplier = 0.0F,
			int64_t ricochets = 0, float attraction_radius = 0.0F, float attraction_speed = 0.0F,
			bool pierces_targets = false, double chill_duration_seconds = 0.0,
			float chill_speed_multiplier = 1.0F, float chill_damage_multiplier = 1.0F);
	int64_t spawn_status_projectile(String projectile_type, Vector2 position, Vector2 velocity, float damage,
			float radius, double lifetime_seconds, float status_damage_per_tick = 2.0F,
			double status_interval_seconds = 0.5, double status_duration_seconds = 2.0,
			float explosion_radius = 0.0F, float explosion_damage_multiplier = 0.0F,
			int64_t ricochets = 0, float attraction_radius = 0.0F, float attraction_speed = 0.0F,
			bool pierces_targets = false, double chill_duration_seconds = 0.0,
			float chill_speed_multiplier = 1.0F, float chill_damage_multiplier = 1.0F);
	int64_t spawn_xp_orb(Vector2 position, float xp_value);
	int64_t collect_xp_orb(int64_t index, int64_t generation);
	int64_t apply_damage_over_time(int64_t index, int64_t generation, float damage_per_tick,
			double interval_seconds, double duration_seconds);
	int64_t despawn(int64_t index, int64_t generation);
	int64_t kill_all();
	int64_t pause();
	int64_t resume();
	int64_t step(double delta_seconds);
	int64_t set_speed(double multiplier);
	int64_t apply_sandbox_overrides(Dictionary overrides);
	int64_t set_steering_target(Vector2 position, float max_speed, float separation_radius, float separation_weight);
	int64_t dash_entity(int64_t index, int64_t generation, Vector2 velocity, double duration_seconds);
	int64_t acknowledge_events(int64_t event_sequence);
	double health_decay_amount(double active_time_seconds, double delta_seconds) const;
	double kill_heal_amount(double threat_level) const;
	double initial_player_hp() const;
	int64_t reset();
	Dictionary snapshot() const;

private:
	int64_t submit(dopamine::sim::SimulationCommand command);
	dopamine::sim::SimulationWorker worker_;
};

} // namespace godot
