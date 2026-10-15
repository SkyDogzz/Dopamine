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

	int64_t spawn(String entity_type, int64_t count, Vector2 position, float hp, Vector2 velocity);
	int64_t despawn(int64_t index, int64_t generation);
	int64_t kill_all();
	int64_t pause();
	int64_t resume();
	int64_t step(double delta_seconds);
	int64_t set_speed(double multiplier);
	int64_t set_steering_target(Vector2 position, float max_speed, float separation_radius, float separation_weight);
	int64_t reset();
	Dictionary snapshot() const;

private:
	int64_t submit(dopamine::sim::SimulationCommand command);
	dopamine::sim::SimulationWorker worker_;
};

} // namespace godot
