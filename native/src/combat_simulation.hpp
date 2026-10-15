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
	int64_t spawn_projectile(String projectile_type, Vector2 position, Vector2 velocity, float damage,
			float radius, double lifetime_seconds);
	int64_t despawn(int64_t index, int64_t generation);
	int64_t kill_all();
	int64_t pause();
	int64_t resume();
	int64_t step(double delta_seconds);
	int64_t set_speed(double multiplier);
	int64_t set_steering_target(Vector2 position, float max_speed, float separation_radius, float separation_weight);
	int64_t acknowledge_events(int64_t event_sequence);
	double health_decay_amount(double active_time_seconds, double delta_seconds) const;
	double kill_heal_amount(double threat_level) const;
	int64_t reset();
	Dictionary snapshot() const;

private:
	int64_t submit(dopamine::sim::SimulationCommand command);
	dopamine::sim::SimulationWorker worker_;
};

} // namespace godot
