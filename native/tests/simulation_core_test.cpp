#include "dopamine/simulation/simulation_core.hpp"

#include <cmath>
#include <cstdlib>
#include <iostream>
#include <stdexcept>

using dopamine::sim::SimulationCore;

namespace {

void require(bool condition, const char *message) {
	if (!condition) {
		std::cerr << message << '\n';
		std::exit(1);
	}
}

} // namespace

int main() {
	SimulationCore simulation;
	const auto first = simulation.spawn("chaser", 1.0F, 2.0F, 10.0F, 5.0F, 0.0F);
	require(simulation.entity_count() == 1, "spawn should add one entity");
	require(simulation.entity(first).has_value(), "spawned handle should resolve");

	simulation.advance(0.5);
	const auto moved = simulation.entity(first);
	require(moved.has_value(), "entity should survive a step");
	require(std::abs(moved->transform.x - 3.5F) < 0.001F, "step should integrate velocity");
	require(std::abs(simulation.simulation_time() - 0.5) < 0.001, "step should advance time");

	require(simulation.despawn(first), "despawn should accept a live handle");
	require(!simulation.entity(first).has_value(), "despawned handle should be stale");
	const auto second = simulation.spawn("tank", 0.0F, 0.0F, 20.0F, 1.0F, 0.0F);
	require(second.index == first.index, "despawned index should be reused");
	require(second.generation != first.generation, "reused index should get a new generation");
	require(!simulation.despawn(first), "stale handle must not despawn a new entity");
	bool rejected_negative_delta = false;
	try {
		simulation.advance(-1.0);
	} catch (const std::invalid_argument &) {
		rejected_negative_delta = true;
	}
	require(rejected_negative_delta, "negative delta must be rejected");

	simulation.reset();
	require(simulation.entity_count() == 0, "reset should remove every entity");
	require(!simulation.entity(second).has_value(), "reset should invalidate old handles");
	require(simulation.simulation_time() == 0.0, "reset should clear simulation time");
	return 0;
}
