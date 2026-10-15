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
	using dopamine::sim::health_decay_amount;
	require(dopamine::sim::gdd_validated_player_initial_hp == 100.0F,
			"validated initial player HP should remain 100");
	require(std::abs(health_decay_amount(0.0, 60.0) - 97.2) < 0.000001,
			"proposed health decay should match the GDD first-minute example");
	require(std::abs(health_decay_amount(0.0, 720.0) - 2116.8) < 0.000001,
			"proposed health decay should match the GDD twelve-minute example");
	require(std::abs(health_decay_amount(60.0, 60.0) - 111.6) < 0.000001,
			"health decay should use the active-time interval start");
	require(health_decay_amount(15.0, 0.0) == 0.0,
			"zero active duration should cause no health decay");
	require(health_decay_amount(10.0, 10.0, {.base_rate = 2.0, .increase_per_active_second = 0.0}) == 20.0,
			"health decay coefficients should remain configurable");
	bool rejected_decay_interval = false;
	try {
		health_decay_amount(-1.0, 1.0);
	} catch (const std::invalid_argument &) {
		rejected_decay_interval = true;
	}
	require(rejected_decay_interval, "negative active time must be rejected by the decay rule");
	using dopamine::sim::kill_heal_amount;
	require(std::abs(kill_heal_amount(1.0) - 5.0) < 0.000001,
			"proposed ordinary enemy threat should produce five HP of kill healing");
	require(std::abs(kill_heal_amount(0.1) - (2.0 + 3.0 * std::sqrt(0.5))) < 0.000001,
			"kill healing should clamp threat to its proposed lower bound");
	require(std::abs(kill_heal_amount(100.0) - 17.0) < 0.000001,
			"kill healing should clamp threat to its proposed upper bound");
	require(kill_heal_amount(1.0, {.base_amount = 1.0, .amount_per_sqrt_threat = 2.0,
			.minimum_threat = 1.0, .maximum_threat = 9.0}) == 3.0,
			"kill healing formula coefficients should remain configurable");

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

	SimulationCore spatial;
	const auto left = spatial.spawn("chaser", -0.01F, 0.0F, 1.0F, 0.0F, 0.0F);
	const auto near = spatial.spawn("tank", 3.0F, 4.0F, 1.0F, 0.0F, 0.0F);
	spatial.spawn("outside", 5.01F, 0.0F, 1.0F, 0.0F, 0.0F);
	const auto around_origin = spatial.query_radius(0.0F, 0.0F, 5.0F, {.cell_size = 4.0F});
	require(around_origin.size() == 2, "spatial query should include radius boundary and nearby negative cell");
	require(around_origin[0] == left && around_origin[1] == near, "spatial query should keep stable entity order");
	const auto negative_cell = spatial.query_radius(-0.01F, 0.0F, 0.01F, {.cell_size = 4.0F});
	require(negative_cell.size() == 1 && negative_cell.front() == left,
			"negative coordinates should map to floor-based spatial cells");
	spatial.despawn(left);
	const auto after_despawn = spatial.query_radius(0.0F, 0.0F, 5.0F, {.cell_size = 4.0F});
	require(after_despawn.size() == 1 && after_despawn.front() == near,
			"spatial query should not return despawned entities");
	require(spatial.query_radius(0.0F, 0.0F, 10000.0F, {.cell_size = 4.0F}).size() == 2,
			"wide spatial queries should scan occupied cells without iterating the empty grid");
	bool rejected_query = false;
	try {
		spatial.query_radius(0.0F, 0.0F, -1.0F);
	} catch (const std::invalid_argument &) {
		rejected_query = true;
	}
	require(rejected_query, "negative spatial query radius must be rejected");

	SimulationCore steering;
	const auto chaser = steering.spawn("chaser", -20.0F, 0.0F, 20.0F, 0.0F, 0.0F);
	const auto neighbor = steering.spawn("chaser", -15.0F, 0.0F, 20.0F, 0.0F, 0.0F);
	steering.steer_enemies_towards(0.0F, 0.0F,
			{.max_speed = 75.0F, .separation_radius = 18.0F, .separation_weight = 0.75F,
					.spatial_hash = {.cell_size = 8.0F}});
	const auto steered = steering.entity(chaser);
	const auto separated = steering.entity(neighbor);
	require(steered.has_value() && separated.has_value(), "steering must keep entities active");
	require(std::abs(std::hypot(steered->velocity.x, steered->velocity.y) - 75.0F) < 0.001F,
			"steering must respect the configured maximum speed");
	require(steered->velocity.x < -1.0F && separated->velocity.x > 1.0F,
			"nearby entities should steer apart while pursuing the target");
	steering.advance(0.1);
	require(steering.entity(chaser)->transform.x < -20.0F, "steered entity should move after integration");
	bool rejected_steering = false;
	try {
		steering.steer_enemies_towards(0.0F, 0.0F, {.max_speed = -1.0F});
	} catch (const std::invalid_argument &) {
		rejected_steering = true;
	}
	require(rejected_steering, "invalid steering configuration must be rejected");
	SimulationCore coincident;
	const auto coincident_first = coincident.spawn("chaser", 0.0F, 0.0F, 1.0F, 0.0F, 0.0F);
	const auto coincident_second = coincident.spawn("chaser", 0.0F, 0.0F, 1.0F, 0.0F, 0.0F);
	coincident.steer_enemies_towards(10.0F, 0.0F,
			{.max_speed = 10.0F, .separation_radius = 5.0F, .separation_weight = 0.75F});
	require(coincident.entity(coincident_first)->velocity.x < 0.0F &&
			coincident.entity(coincident_second)->velocity.x > 0.0F,
			"coincident entities should separate deterministically without random state");

	SimulationCore combat;
	const auto target = combat.spawn("chaser", 50.0F, -100.0F, 10.0F, 0.0F, 1000.0F, 4.0F);
	const auto projectile = combat.spawn_projectile("test_projectile", 0.0F, 0.0F, 12.0F, 2.0F, 1.0, 500.0F, 0.0F);
	const auto combat_events = combat.advance(0.2);
	require(combat_events.size() == 2, "swept projectile hit should emit damage and death events");
	require(combat_events[0].type == dopamine::sim::CombatEventType::Damage &&
			combat_events[0].target == target && combat_events[0].source == projectile,
			"damage event should identify projectile and target");
	require(combat_events[1].type == dopamine::sim::CombatEventType::Death &&
			combat_events[1].sequence > combat_events[0].sequence &&
			combat_events[1].threat_level == 4.0F,
			"death event should preserve the target threat for reward calculation");
	require(kill_heal_amount(combat_events[1].threat_level) == 8.0,
			"death threat should feed the proposed kill heal rule");
	require(!combat.entity(target).has_value() && !combat.entity(projectile).has_value(),
			"lethal hit should remove the enemy and consumed projectile");
	require(std::abs(combat.simulation_time() - 0.2) < 0.001,
			"combat step should retain its explicit duration");

	SimulationCore expiring_projectile;
	const auto expires = expiring_projectile.spawn_projectile("test_projectile", 0.0F, 0.0F,
			1.0F, 1.0F, 0.1, 10.0F, 0.0F);
	require(expiring_projectile.advance(0.2).empty(), "expired projectile without a target should emit no combat event");
	require(!expiring_projectile.entity(expires).has_value(), "projectile should despawn when its lifetime expires");

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
