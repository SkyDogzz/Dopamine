#include "dopamine/simulation/simulation_core.hpp"

#include <algorithm>
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
	using dopamine::sim::enemy_profile;
	const auto chaser_profile = enemy_profile("chaser");
	const auto sprinter_profile = enemy_profile("sprinter");
	const auto tank_profile = enemy_profile("tank");
	const auto shooter_profile = enemy_profile("shooter");
	const auto buffer_profile = enemy_profile("buffer");
	const auto elite_profile = enemy_profile("elite");
	const auto exploder_profile = enemy_profile("exploder");
	const auto shielder_profile = enemy_profile("shielder");
	const auto summoner_profile = enemy_profile("summoner");
	const auto summoned_profile = enemy_profile("summoned");
	require(chaser_profile && chaser_profile->health == 20.0F && chaser_profile->speed == 75.0F,
			"proposed chaser profile should match GDD starting values");
	require(sprinter_profile && sprinter_profile->health == 12.0F && sprinter_profile->speed == 125.0F,
			"proposed sprinter profile should match GDD starting values");
	require(tank_profile && tank_profile->health == 80.0F && tank_profile->speed == 45.0F,
			"proposed tank profile should match GDD starting values");
	require(shooter_profile && shooter_profile->health == 25.0F && shooter_profile->speed == 65.0F,
			"proposed shooter profile should match GDD starting values");
	require(buffer_profile && buffer_profile->support_radius == 150.0F &&
			buffer_profile->support_speed_multiplier == 1.2F,
			"proposed support profile should expose a bounded speed aura");
	require(elite_profile && elite_profile->health == 50.0F && elite_profile->speed == 100.0F &&
			elite_profile->threat_level == 3.0F,
			"proposed Hasted elite profile should have a distinct combat profile");
	SimulationCore armored_elite;
	const auto armored_id = armored_elite.spawn("elite", 0.0F, 0.0F, 50.0F, 0.0F, 0.0F,
			3.0F, 75.0F, "Armored", 0.65F);
	std::vector<dopamine::sim::CombatEvent> armored_events;
	armored_elite.apply_direct_damage({}, armored_id, 10.0F, armored_events);
	require(armored_elite.entity(armored_id)->health.current == 43.5F &&
			armored_elite.entity(armored_id)->type.affix == "Armored" &&
			armored_elite.entity(armored_id)->type.damage_taken_multiplier == 0.65F,
			"proposed Armored elite affix should reduce incoming damage and persist in snapshots");
	SimulationCore regenerating_elite;
	const auto regenerating_id = regenerating_elite.spawn("elite", 0.0F, 0.0F, 50.0F, 0.0F, 0.0F,
			3.0F, 75.0F, "Regenerating", 1.0F, 0.5F);
	std::vector<dopamine::sim::CombatEvent> regeneration_events;
	regenerating_elite.apply_direct_damage({}, regenerating_id, 10.0F, regeneration_events);
	regenerating_elite.advance(4.0);
	require(regenerating_elite.entity(regenerating_id)->health.current == 42.0F &&
			regenerating_elite.entity(regenerating_id)->type.health_regen_per_second == 0.5F,
			"proposed Regenerating elite affix should restore health over simulation time");
	regenerating_elite.advance(100.0);
	require(regenerating_elite.entity(regenerating_id)->health.current == 50.0F,
			"proposed Regenerating elite affix should not exceed maximum health");
	require(exploder_profile && exploder_profile->health == 30.0F && exploder_profile->speed == 60.0F &&
			exploder_profile->threat_level == 2.0F,
			"proposed Exploder profile should be available to Survival");
	require(shielder_profile && shielder_profile->shield_radius == 150.0F &&
			shielder_profile->shield_damage_multiplier == 0.65F,
			"proposed Shielder profile should expose bounded ally protection");
	require(summoner_profile && summoner_profile->health == 42.0F && summoned_profile &&
			summoned_profile->threat_level == 0.5F,
			"proposed Summoner and summoned enemy profiles should be available to Survival");
	require(!enemy_profile("unknown"), "unknown enemy profiles should be rejected");
	SimulationCore profile_steering;
	const auto profile_entity = profile_steering.spawn("tank", -100.0F, 0.0F, 80.0F,
			0.0F, 0.0F, 1.0F, tank_profile->speed);
	profile_steering.steer_enemies_towards(0.0F, 0.0F, {.max_speed = 10.0F});
	require(std::abs(profile_steering.entity(profile_entity)->velocity.x - tank_profile->speed) < 0.001F,
			"enemy steering should preserve the profile-specific proposed movement speed");
	SimulationCore supported_group;
	const auto supported_ally = supported_group.spawn("chaser", 80.0F, 0.0F, 20.0F, 0.0F, 0.0F, 1.0F, 75.0F);
	const auto distant_ally = supported_group.spawn("chaser", 180.0F, 0.0F, 20.0F, 0.0F, 0.0F, 1.0F, 75.0F);
	const auto support_entity = supported_group.spawn("buffer", 0.0F, 0.0F, 35.0F, 0.0F, 0.0F, 2.0F, 55.0F);
	supported_group.steer_enemies_towards(500.0F, 0.0F, {.max_speed = 75.0F, .separation_radius = 0.0F});
	const auto supported_velocity = supported_group.entity(supported_ally)->velocity;
	const auto distant_velocity = supported_group.entity(distant_ally)->velocity;
	require(supported_velocity.x > 75.0F && supported_group.entity(supported_ally)->type.supported &&
			std::abs(distant_velocity.x - 75.0F) < 0.001F &&
			!supported_group.entity(distant_ally)->type.supported,
			"support aura should speed nearby allies without affecting enemies outside its radius");
	SimulationCore restored_support;
	restored_support.restore_state(supported_group.capture_state());
	require(restored_support.entity(supported_ally)->type.supported &&
			restored_support.entity(support_entity)->type.support_radius == 150.0F,
			"support aura and ally state should survive simulation capture and restore");
	auto invalid_support_state = supported_group.capture_state();
	invalid_support_state.entities[support_entity.index].type.support_radius = -1.0F;
	bool rejected_invalid_support_state = false;
	try {
		SimulationCore invalid_support;
		invalid_support.restore_state(invalid_support_state);
	} catch (const std::invalid_argument &) {
		rejected_invalid_support_state = true;
	}
	require(rejected_invalid_support_state, "restoring a negative support radius should be rejected");
	std::vector<dopamine::sim::CombatEvent> support_death_events;
	supported_group.apply_direct_damage(supported_ally, support_entity, 35.0F, support_death_events);
	supported_group.steer_enemies_towards(500.0F, 0.0F, {.max_speed = 75.0F, .separation_radius = 0.0F});
	require(!supported_group.entity(supported_ally)->type.supported &&
			std::abs(supported_group.entity(supported_ally)->velocity.x - 75.0F) < 0.001F,
			"destroying a support enemy should immediately remove its aura effect");
	SimulationCore shielded_group;
	const auto protected_ally = shielded_group.spawn("chaser", 80.0F, 0.0F, 20.0F, 0.0F, 0.0F, 1.0F, 75.0F);
	const auto unprotected_ally = shielded_group.spawn("chaser", 180.0F, 0.0F, 20.0F, 0.0F, 0.0F, 1.0F, 75.0F);
	const auto shielder = shielded_group.spawn("shielder", 0.0F, 0.0F, 40.0F, 0.0F, 0.0F, 2.0F, 45.0F);
	shielded_group.steer_enemies_towards(80.0F, 0.0F, {.max_speed = 75.0F, .separation_radius = 0.0F});
	std::vector<dopamine::sim::CombatEvent> shield_events;
	shielded_group.apply_direct_damage(protected_ally, protected_ally, 10.0F, shield_events);
	require(shield_events.size() == 1 && std::abs(shield_events[0].amount - 6.5F) < 0.001F &&
			shielded_group.entity(protected_ally)->type.shielded &&
			!shielded_group.entity(unprotected_ally)->type.shielded,
			"Shielder should reduce damage only for allies inside its aura");
	SimulationCore restored_shielded_group;
	restored_shielded_group.restore_state(shielded_group.capture_state());
	require(restored_shielded_group.entity(protected_ally)->type.shielded &&
			restored_shielded_group.entity(protected_ally)->type.shield_source == shielder,
			"Shielder protection source should survive simulation capture and restore");
	std::vector<dopamine::sim::CombatEvent> distant_events;
	shielded_group.apply_direct_damage(unprotected_ally, unprotected_ally, 10.0F, distant_events);
	require(distant_events.size() == 1 && std::abs(distant_events[0].amount - 10.0F) < 0.001F,
			"allies outside the Shielder aura should receive unmodified damage");
	std::vector<dopamine::sim::CombatEvent> shielder_death_events;
	shielded_group.apply_direct_damage(protected_ally, shielder, 40.0F, shielder_death_events);
	std::vector<dopamine::sim::CombatEvent> unshielded_events;
	shielded_group.apply_direct_damage(protected_ally, protected_ally, 10.0F, unshielded_events);
	require(!shielded_group.entity(protected_ally)->type.shielded && unshielded_events.size() == 1 &&
			std::abs(unshielded_events[0].amount - 10.0F) < 0.001F,
			"destroying the Shielder should immediately restore full incoming damage");
	SimulationCore xp_simulation;
	const auto xp_orb = xp_simulation.spawn_xp_orb(12.0F, -4.0F, 7.0F);
	const auto spawned_orb = xp_simulation.entity(xp_orb);
	require(spawned_orb.has_value() && spawned_orb->is_xp_orb && spawned_orb->xp_value == 7.0F,
			"XP orb should exist as a typed shared-core entity");
	std::vector<dopamine::sim::CombatEvent> xp_events;
	require(xp_simulation.collect_xp_orb(xp_orb, xp_events), "active XP orb should be collectable");
	require(xp_events.size() == 1 && xp_events[0].type == dopamine::sim::CombatEventType::XpCollected &&
			xp_events[0].amount == 7.0F && xp_events[0].target == xp_orb,
			"XP collection should emit its value once through a sequenced gameplay event");
	require(!xp_simulation.entity(xp_orb).has_value() && !xp_simulation.collect_xp_orb(xp_orb, xp_events),
			"collected XP orb should be removed and reject duplicate collection");
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

	SimulationCore enemy_shot;
	const auto untouched_enemy = enemy_shot.spawn("chaser", 10.0F, 0.0F, 100.0F, 0.0F, 0.0F);
	const auto enemy_projectile = enemy_shot.spawn_projectile("enemy_projectile", 0.0F, 0.0F,
			8.0F, 6.0F, 4.0, 100.0F, 0.0F);
	enemy_shot.advance(0.1);
	const auto enemy_after_shot = enemy_shot.entity(untouched_enemy);
	const auto shot_after_advance = enemy_shot.entity(enemy_projectile);
	require(enemy_after_shot && enemy_after_shot->health.current == 100.0F && shot_after_advance &&
			shot_after_advance->transform.x > 0.0F,
			"enemy projectiles should move without damaging ECS enemy targets");

	SimulationCore void_orb;
	const auto pulled_target = void_orb.spawn("chaser", -20.0F, 0.0F, 100.0F, 0.0F, 0.0F);
	const auto gravity_orb = void_orb.spawn_projectile("void_orb", 80.0F, 0.0F, 2.0F, 3.0F, 3.0,
			0.0F, 0.0F, 2.0F, 0.5, 2.0, 0.0F, 0.0F, 0, 150.0F, 40.0F, true);
	void_orb.steer_enemies_towards(-100.0F, 0.0F, {.max_speed = 30.0F});
	void_orb.advance(0.25);
	const auto pulled_state = void_orb.entity(pulled_target);
	const auto orb_state = void_orb.entity(gravity_orb);
	require(pulled_state && pulled_state->transform.x > -20.0F &&
			pulled_state->velocity.x > 0.0F,
			"Void Orb attraction should pull nearby enemies toward its field centre");
	require(orb_state && orb_state->is_projectile && orb_state->projectile.attraction_radius == 150.0F &&
			orb_state->projectile.attraction_speed == 40.0F && orb_state->projectile.pierces_targets,
			"Void Orb field parameters should remain on the shared projectile state");
	SimulationCore charging_boss;
	const auto boss_charge = charging_boss.spawn("mid_boss", 0.0F, 0.0F, 1000.0F, 0.0F, 0.0F, 1.0F, 75.0F);
	require(charging_boss.dash_entity(boss_charge, 0.0F, 200.0F, 0.2),
			"a valid boss entity should accept a timed movement override");
	charging_boss.steer_enemies_towards(500.0F, 0.0F, {.max_speed = 75.0F, .separation_radius = 0.0F});
	charging_boss.advance(0.1);
	auto charging_state = charging_boss.entity(boss_charge);
	require(charging_state && std::abs(charging_state->transform.y - 20.0F) < 1e-5F &&
			charging_state->velocity.y == 200.0F && charging_state->movement_override.has_value(),
			"timed movement should override target steering and move the entity at dash velocity");
	SimulationCore restored_charge;
	restored_charge.restore_state(charging_boss.capture_state());
	restored_charge.advance(0.1);
	charging_state = restored_charge.entity(boss_charge);
	require(charging_state && std::abs(charging_state->transform.y - 40.0F) < 1e-5F &&
			!charging_state->movement_override.has_value() && charging_state->velocity.y == 0.0F,
			"movement override duration should survive snapshots and stop on expiry");
	SimulationCore restored_void_orb;
	restored_void_orb.restore_state(void_orb.capture_state());
	const auto restored_orb_state = restored_void_orb.entity(gravity_orb);
	require(restored_orb_state && restored_orb_state->projectile.pierces_targets &&
			restored_orb_state->projectile.attraction_radius == 150.0F,
			"Void Orb attraction and piercing should survive a simulation snapshot restore");
	SimulationCore piercing_orb;
	const auto first_orb_target = piercing_orb.spawn("chaser", 0.0F, 0.0F, 100.0F, 0.0F, 0.0F);
	const auto second_orb_target = piercing_orb.spawn("chaser", 35.0F, 0.0F, 100.0F, 0.0F, 0.0F);
	const auto piercing_orb_id = piercing_orb.spawn_projectile("void_orb", -100.0F, 0.0F, 5.0F, 3.0F, 2.0,
			1000.0F, 0.0F, 2.0F, 0.5, 2.0, 0.0F, 0.0F, 0, 0.0F, 0.0F, true);
	const auto piercing_events = piercing_orb.advance(0.2);
	const auto piercing_orb_state = piercing_orb.entity(piercing_orb_id);
	require(piercing_events.size() == 2 && piercing_events[0].target == first_orb_target &&
			piercing_events[1].target == second_orb_target && piercing_orb_state.has_value(),
			"a piercing Void Orb should damage each target once and remain active after impacts");

	SimulationCore crimson_daggers;
	const auto crimson_dagger_id = crimson_daggers.spawn_projectile("crimson_dagger", 14.0F, 0.0F,
			5.0F, 2.5F, 0.8, 0.0F, 0.0F);
	crimson_daggers.steer_enemies_towards(0.0F, 0.0F);
	crimson_daggers.advance(0.1);
	const auto orbiting_crimson_dagger = crimson_daggers.entity(crimson_dagger_id);
	require(orbiting_crimson_dagger && orbiting_crimson_dagger->is_projectile &&
			std::abs(std::hypot(orbiting_crimson_dagger->transform.x, orbiting_crimson_dagger->transform.y) - 30.0F) < 0.01F &&
			std::abs(orbiting_crimson_dagger->transform.y) > 1.0F,
			"Crimson Daggers should orbit the player instead of travelling in a straight line");

	SimulationCore bloodstorm;
	const auto bloodstorm_first_target = bloodstorm.spawn("test_target", 30.0F, 0.0F, 100.0F, 0.0F, 0.0F);
	const auto bloodstorm_second_target = bloodstorm.spawn("test_target", 0.0F, 30.0F, 100.0F, 0.0F, 0.0F);
	const auto bloodstorm_id = bloodstorm.spawn_projectile("bloodstorm_dagger", 14.0F, 0.0F,
			5.0F, 2.5F, 2.4, 0.0F, 0.0F, 1.0F, 0.5, 2.0,
			0.0F, 0.0F, 0, 0.0F, 0.0F, true);
	bloodstorm.steer_enemies_towards(0.0F, 0.0F);
	for (int step = 0; step < 16; ++step) {
		bloodstorm.advance(0.1);
	}
	const auto orbiting_dagger = bloodstorm.entity(bloodstorm_id);
	require(orbiting_dagger && orbiting_dagger->is_projectile &&
			std::abs(std::hypot(orbiting_dagger->transform.x, orbiting_dagger->transform.y) - 30.0F) < 0.01F &&
			std::abs(orbiting_dagger->transform.y) > 1.0F &&
			orbiting_dagger->projectile.hit_targets.size() == 2 &&
			std::find(orbiting_dagger->projectile.hit_targets.begin(), orbiting_dagger->projectile.hit_targets.end(),
					bloodstorm_first_target) != orbiting_dagger->projectile.hit_targets.end() &&
			std::find(orbiting_dagger->projectile.hit_targets.begin(), orbiting_dagger->projectile.hit_targets.end(),
					bloodstorm_second_target) != orbiting_dagger->projectile.hit_targets.end(),
			"Bloodstorm should orbit the player and hit each of two distinct targets once");
	const auto bloodstorm_snapshot = bloodstorm.capture_state();
	SimulationCore restored_bloodstorm;
	restored_bloodstorm.restore_state(bloodstorm_snapshot);
	restored_bloodstorm.steer_enemies_towards(0.0F, 0.0F);
	restored_bloodstorm.advance(0.1);
	const auto restored_dagger = restored_bloodstorm.entity(bloodstorm_id);
	require(restored_dagger && restored_dagger->is_projectile &&
			std::abs(std::hypot(restored_dagger->transform.x, restored_dagger->transform.y) - 30.0F) < 0.01F,
			"Bloodstorm orbit state should survive a native simulation snapshot restore");

	SimulationCore frost_nova;
	const auto chilled_target = frost_nova.spawn("chaser", 50.0F, 0.0F, 100.0F, 0.0F, 0.0F, 1.0F, 75.0F);
	const auto outside_target = frost_nova.spawn("chaser", 90.0F, 0.0F, 100.0F, 0.0F, 0.0F, 1.0F, 75.0F);
	const auto frost_pulse = frost_nova.spawn_projectile("frost_nova", 0.0F, 0.0F, 8.0F, 60.0F, 0.1,
			0.0F, 0.0F, 2.0F, 0.5, 2.0, 0.0F, 0.0F, 0, 0.0F, 0.0F, true, 2.0, 0.5);
	const auto frost_events = frost_nova.advance(0.01);
	const auto chilled_state = frost_nova.entity(chilled_target);
	require(frost_events.size() == 1 && frost_events[0].target == chilled_target &&
			frost_nova.entity(outside_target)->health.current == 100.0F,
			"Frost Nova should damage every target inside its radius and leave targets outside untouched");
	require(chilled_state && chilled_state->chill_effect &&
			chilled_state->chill_effect->speed_multiplier == 0.5F,
			"Frost Nova should apply a timed Chill effect to hit enemies");
	const auto frost_pierce_state = frost_nova.entity(frost_pulse);
	require(frost_pierce_state && frost_pierce_state->projectile.chill_duration_seconds == 2.0 &&
			frost_pierce_state->projectile.chill_speed_multiplier == 0.5F,
			"Frost projectile Chill parameters should remain in native projectile state");
	SimulationCore vulnerable_frost;
	const auto vulnerable_target = vulnerable_frost.spawn("chaser", 0.0F, 0.0F, 100.0F, 0.0F, 0.0F);
	vulnerable_frost.apply_chill(vulnerable_target, 1.0, 0.5F, 1.25F);
	std::vector<dopamine::sim::CombatEvent> vulnerability_events;
	vulnerable_frost.apply_direct_damage(dopamine::sim::EntityId{}, vulnerable_target, 8.0F, vulnerability_events);
	require(vulnerability_events.size() == 1 && vulnerability_events.front().amount == 10.0F &&
			vulnerability_events.front().target_was_chilled,
			"Frozen Crown vulnerability should increase damage to chilled targets and tag the combat event");
	frost_nova.steer_enemies_towards(-100.0F, 0.0F, {.max_speed = 20.0F, .separation_radius = 0.0F});
	require(std::abs(frost_nova.entity(chilled_target)->velocity.x + 37.5F) < 0.001F &&
			std::abs(frost_nova.entity(outside_target)->velocity.x + 75.0F) < 0.001F,
			"Chill should reduce only affected enemies' movement speed");
	SimulationCore restored_frost;
	restored_frost.restore_state(frost_nova.capture_state());
	require(restored_frost.entity(chilled_target)->chill_effect.has_value(),
			"Chill should survive a native simulation snapshot restore");
	restored_frost.advance(2.1);
	restored_frost.steer_enemies_towards(-100.0F, 0.0F, {.max_speed = 20.0F, .separation_radius = 0.0F});
	require(!restored_frost.entity(chilled_target)->chill_effect.has_value() &&
			std::abs(restored_frost.entity(chilled_target)->velocity.x + 75.0F) < 0.001F,
			"Chill should expire in simulation time and restore the enemy's proposed base speed");

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

	SimulationCore damage_over_time;
	const auto dot_target = damage_over_time.spawn("chaser", 0.0F, 0.0F, 20.0F, 0.0F, 0.0F);
	require(damage_over_time.apply_damage_over_time(dot_target, 3.0F, 1.0, 2.5),
			"valid damage-over-time should apply to a live target");
	auto dot_events = damage_over_time.advance(0.5);
	require(dot_events.empty(), "damage-over-time should wait for its first interval");
	dot_events = damage_over_time.advance(2.0);
	require(dot_events.size() == 2 && dot_events[0].type == dopamine::sim::CombatEventType::Damage &&
			dot_events[0].amount == 3.0F && dot_events[0].is_damage_over_time &&
			dot_events[0].status_type == "generic" && dot_events[1].amount == 3.0F &&
			dot_events[1].is_damage_over_time && dot_events[1].status_type == "generic",
			"large steps should preserve each due damage-over-time tick");
	require(damage_over_time.entity(dot_target)->health.current == 14.0F,
			"damage-over-time should apply cumulative tick damage");
	SimulationCore expiring_status;
	const auto expiring_target = expiring_status.spawn("chaser", 0.0F, 0.0F, 10.0F, 0.0F, 0.0F);
	expiring_status.apply_damage_over_time(expiring_target, 1.0F, 0.5, 1.0);
	const auto expiry_events = expiring_status.advance(2.0);
	require(expiry_events.size() == 2 && expiring_status.entity(expiring_target)->health.current == 8.0F,
			"a large step must not emit damage-over-time ticks after the effect expires");
	SimulationCore lethal_status;
	const auto lethal_target = lethal_status.spawn("chaser", 0.0F, 0.0F, 2.0F, 0.0F, 0.0F);
	lethal_status.apply_damage_over_time(lethal_target, 3.0F, 0.5, 1.0, "bleed");
	const auto lethal_status_events = lethal_status.advance(0.5);
	require(lethal_status_events.size() == 2 && lethal_status_events[0].is_damage_over_time &&
			lethal_status_events[0].status_type == "bleed" &&
			lethal_status_events[1].type == dopamine::sim::CombatEventType::Death &&
			lethal_status_events[1].status_type == "bleed",
			"lethal status ticks should preserve identity on damage and death events");
	SimulationCore excessive_status;
	std::vector<dopamine::sim::EntityId> excessive_targets;
	for (int index = 0; index < 10; ++index) {
		const auto target = excessive_status.spawn("chaser", static_cast<float>(index * 100), 0.0F,
				100000.0F, 0.0F, 0.0F);
		excessive_targets.push_back(target);
		excessive_status.apply_damage_over_time(target, 1.0F, 0.001, 1.0);
	}
	bool rejected_excessive_step = false;
	try {
		excessive_status.advance(1.0);
	} catch (const std::length_error &) {
		rejected_excessive_step = true;
	}
	require(rejected_excessive_step && excessive_status.simulation_time() == 0.0,
			"an event-heavy step must be rejected before advancing simulation time");
	for (const auto target : excessive_targets) {
		const auto state = excessive_status.entity(target);
		require(state && state->health.current == 100000.0F && state->damage_over_time.has_value(),
				"an event-heavy rejected step must not partially mutate entities or statuses");
	}
	const auto dot_replacement = damage_over_time.spawn("tank", 0.0F, 0.0F, 10.0F, 0.0F, 0.0F);
	require(damage_over_time.apply_damage_over_time(dot_replacement, 2.0F, 0.5, 0.5),
			"damage-over-time should apply to a second entity");
	require(damage_over_time.apply_damage_over_time(dot_replacement, 4.0F, 1.0, 1.0),
			"reapplying damage-over-time should replace the active effect");
	dot_events = damage_over_time.advance(1.0);
	require(dot_events.size() == 1 && dot_events[0].amount == 4.0F,
			"reapplication should replace rather than stack or retain old timing");
	require(!damage_over_time.apply_damage_over_time({9999, 1}, 1.0F, 1.0, 1.0),
			"damage-over-time should reject stale targets");
	bool rejected_dot = false;
	try {
		damage_over_time.apply_damage_over_time(dot_replacement, 0.0F, 1.0, 1.0);
	} catch (const std::invalid_argument &) {
		rejected_dot = true;
	}
	require(rejected_dot, "damage-over-time should reject non-positive values");
	SimulationCore inferno_burn;
	const auto burn_target = inferno_burn.spawn("chaser", 60.0F, 0.0F, 20.0F, 0.0F, 0.0F);
	inferno_burn.spawn_projectile("inferno_sprayer", 0.0F, 0.0F, 1.0F, 3.0F, 2.0,
			100.0F, 0.0F, 2.5F, 0.25, 1.0);
	const auto burn_impact = inferno_burn.advance(0.6);
	require(!burn_impact.empty() && inferno_burn.entity(burn_target)->health.current == 19.0F &&
			inferno_burn.entity(burn_target)->damage_over_time.has_value(),
			"Inferno Sprayer projectile hit should apply its configured burn to a surviving target");
	const auto burn_ticks = inferno_burn.advance(0.25);
	require(burn_ticks.size() == 1 && burn_ticks[0].is_damage_over_time &&
			burn_ticks[0].status_type == "burn" && burn_ticks[0].amount == 2.5F,
			"Inferno burn should emit a tagged tick using its configured damage");
	SimulationCore toxic_cloud;
	const auto poison_primary = toxic_cloud.spawn("chaser", 60.0F, 0.0F, 20.0F, 0.0F, 0.0F);
	const auto poison_splash = toxic_cloud.spawn("chaser", 60.0F, 25.0F, 20.0F, 0.0F, 0.0F);
	toxic_cloud.spawn_projectile("toxic_cloud", 0.0F, 0.0F, 1.0F, 3.0F, 2.0,
			100.0F, 0.0F, 2.0F, 0.5, 1.0, 40.0F, 0.5F);
	toxic_cloud.advance(0.6);
	const auto poison_direct = toxic_cloud.entity(poison_primary);
	const auto poison_affected = toxic_cloud.entity(poison_splash);
	require(poison_direct && poison_direct->damage_over_time && poison_direct->damage_over_time->status_type == "poison" &&
			poison_affected && poison_affected->damage_over_time && poison_affected->damage_over_time->status_type == "poison" &&
			poison_direct->health.current == 19.0F && poison_affected->health.current == 19.5F,
			"Toxic Cloud should apply poison and its bounded area splash to nearby enemies");
	const auto poison_ticks = toxic_cloud.advance(0.5);
	require(poison_ticks.size() == 2 && poison_ticks[0].is_damage_over_time && poison_ticks[1].is_damage_over_time &&
			poison_ticks[0].status_type == "poison" && poison_ticks[1].status_type == "poison",
			"Toxic Cloud poison should use the shared event path with its status identity");
	const auto poison_late = toxic_cloud.spawn("chaser", 90.0F, 0.0F, 20.0F, 0.0F, 0.0F);
	const auto persistent_cloud_state = toxic_cloud.capture_state();
	SimulationCore restored_cloud;
	restored_cloud.restore_state(persistent_cloud_state);
	restored_cloud.advance(0.5);
	const auto late_poisoned = restored_cloud.entity(poison_late);
	const auto cloud_projectiles = restored_cloud.snapshot();
	require(late_poisoned && late_poisoned->damage_over_time &&
			std::any_of(cloud_projectiles.begin(), cloud_projectiles.end(), [](const dopamine::sim::Entity &entity) {
				return entity.is_projectile && entity.type.id == "toxic_cloud";
			}),
			"Toxic Cloud should persist after impact, poison later arrivals, and survive snapshot restoration");
	for (double step_seconds : {1.0 / 120.0, 1.0 / 60.0, 1.0 / 30.0, 0.1}) {
		SimulationCore timed_status;
		const auto timed_target = timed_status.spawn("chaser", 0.0F, 0.0F, 100.0F, 0.0F, 0.0F);
		const auto moving_entity = timed_status.spawn("chaser", 0.0F, 20.0F, 100.0F, 100.0F, 0.0F);
		timed_status.apply_damage_over_time(timed_target, 2.0F, 0.25, 1.0);
		int ticks = 0;
		float previous_x = 0.0F;
		float previous_y = 20.0F;
		for (double elapsed = 0.0; elapsed < 1.0 - 1e-12; elapsed += step_seconds) {
			const double step = std::min(step_seconds, 1.0 - elapsed);
			for (const auto &event : timed_status.advance(step)) {
				if (event.is_damage_over_time) {
					++ticks;
					require(std::isfinite(event.remaining_health), "status ticks should retain finite health across supported frame deltas");
				}
			}
			const auto moving_entity_state = timed_status.entity(moving_entity);
			require(moving_entity_state && std::isfinite(moving_entity_state->transform.x) &&
					std::isfinite(moving_entity_state->transform.y) &&
					std::isfinite(moving_entity_state->velocity.x) &&
					std::isfinite(moving_entity_state->velocity.y) &&
					std::isfinite(moving_entity_state->health.current),
					"positions, velocities and health should remain finite for supported frame deltas");
			const float actual_distance = std::hypot(moving_entity_state->transform.x - previous_x,
				moving_entity_state->transform.y - previous_y);
			const float expected_distance = std::hypot(moving_entity_state->velocity.x,
				moving_entity_state->velocity.y) * static_cast<float>(step);
			require(std::abs(actual_distance - expected_distance) < 0.001F,
					"each supported frame delta should integrate movement without an uncontrolled jump");
			previous_x = moving_entity_state->transform.x;
			previous_y = moving_entity_state->transform.y;
		}
		require(ticks == 4 && timed_status.entity(timed_target)->health.current == 92.0F,
				"DoT tick count and damage should be independent of supported simulation step sizes");
		const auto moved_entity = timed_status.entity(moving_entity);
		require(moved_entity && std::isfinite(moved_entity->transform.x) &&
				std::abs(moved_entity->transform.x - 100.0F) < 0.001F,
				"movement should remain finite and integrate the same distance across supported step sizes");
	}
	SimulationCore wildfire;
	const auto wildfire_primary = wildfire.spawn("chaser", 60.0F, 0.0F, 100.0F, 0.0F, 0.0F);
	const auto wildfire_near = wildfire.spawn("chaser", 60.0F, 25.0F, 100.0F, 0.0F, 0.0F);
	const auto wildfire_far = wildfire.spawn("chaser", 60.0F, 50.0F, 100.0F, 0.0F, 0.0F);
	wildfire.spawn_projectile("wildfire_sprayer", 0.0F, 0.0F, 10.0F, 3.0F, 2.0,
			100.0F, 0.0F, 2.0F, 0.5, 2.0, 40.0F, 0.5F);
	wildfire.advance(0.6);
	const auto wildfire_direct = wildfire.entity(wildfire_primary);
	const auto wildfire_splash = wildfire.entity(wildfire_near);
	const auto wildfire_unaffected = wildfire.entity(wildfire_far);
	require(wildfire_direct && wildfire_direct->health.current == 90.0F &&
			wildfire_splash && wildfire_splash->health.current == 95.0F && wildfire_splash->damage_over_time &&
			wildfire_splash->damage_over_time->status_type == "burn" &&
			wildfire_unaffected && wildfire_unaffected->health.current == 100.0F,
			"Wildfire should damage and ignite nearby enemies within its explosion radius only");
	SimulationCore bounded_explosions;
	for (int index = 0; index < 502; ++index) {
		bounded_explosions.spawn("chaser", 60.0F, 0.0F, 100.0F, 0.0F, 0.0F);
	}
	for (int index = 0; index < 2; ++index) {
		bounded_explosions.spawn_projectile("wildfire_sprayer", 0.0F, 0.0F, 1.0F, 3.0F, 2.0,
				100.0F, 0.0F, 1.0F, 0.5, 2.0, 1000.0F, 0.1F);
	}
	const auto bounded_explosion_events = bounded_explosions.advance(0.6);
	const auto bounded_targets = bounded_explosions.snapshot();
	const int splash_damaged_targets = static_cast<int>(std::count_if(bounded_targets.begin(), bounded_targets.end(),
			[](const auto &entity) { return entity.health.current < entity.health.maximum - 0.01F; }));
	require(bounded_explosion_events.size() == 502 && splash_damaged_targets == 501,
			"Wildfire splash should process no more than its proposed per-step target budget");
	SimulationCore combat;
	const auto target = combat.spawn("chaser", 50.0F, -100.0F, 10.0F, 0.0F, 1000.0F, 4.0F);
	const auto projectile = combat.spawn_projectile("test_projectile", 0.0F, 0.0F, 12.0F, 2.0F, 1.0, 500.0F, 0.0F);
	const auto combat_events = combat.advance(0.2);
	require(combat_events.size() == 2, "swept projectile hit should emit damage and death events");
	require(combat_events[0].type == dopamine::sim::CombatEventType::Damage &&
			combat_events[0].target == target && combat_events[0].source == projectile &&
			combat_events[0].source_type == "test_projectile",
			"damage event should identify projectile type, source and target");
	require(combat_events[1].type == dopamine::sim::CombatEventType::Death &&
			combat_events[1].sequence > combat_events[0].sequence &&
			combat_events[1].threat_level == 4.0F && combat_events[1].target_type == "chaser",
			"death event should preserve target type and threat for mode rules");
	require(kill_heal_amount(combat_events[1].threat_level) == 8.0,
			"death threat should feed the proposed kill heal rule");
	require(!combat.entity(target).has_value() && !combat.entity(projectile).has_value(),
			"lethal hit should remove the enemy and consumed projectile");
	require(std::abs(combat.simulation_time() - 0.2) < 0.001,
			"combat step should retain its explicit duration");

	SimulationCore sawblades;
	const auto first_blade_target = sawblades.spawn("chaser", 30.0F, 0.0F, 100.0F, 0.0F, 0.0F);
	const auto second_blade_target = sawblades.spawn("chaser", 0.0F, 80.0F, 100.0F, 0.0F, 0.0F);
	sawblades.spawn_projectile("sawblades", 0.0F, 0.0F, 10.0F, 3.0F, 2.0,
			100.0F, 0.0F, 2.0F, 0.5, 2.0, 0.0F, 0.0F, 1);
	const auto first_ricochet = sawblades.advance(0.5);
	SimulationCore restored_sawblades;
	restored_sawblades.restore_state(sawblades.capture_state());
	const auto second_ricochet = restored_sawblades.advance(1.0);
	require(!first_ricochet.empty() && first_ricochet[0].target == first_blade_target &&
			!second_ricochet.empty() && second_ricochet[0].target == second_blade_target,
			"Sawblades should ricochet toward a new living target after each impact");

	SimulationCore expiring_projectile;
	const auto expires = expiring_projectile.spawn_projectile("test_projectile", 0.0F, 0.0F,
			1.0F, 1.0F, 0.1, 10.0F, 0.0F);
	require(expiring_projectile.advance(0.2).empty(), "expired projectile without a target should emit no combat event");
	require(!expiring_projectile.entity(expires).has_value(), "projectile should despawn when its lifetime expires");

	SimulationCore resumable;
	const auto recycled = resumable.spawn("chaser", -5.0F, 0.0F, 10.0F, 0.0F, 0.0F);
	require(resumable.despawn(recycled), "snapshot fixture should create a recycled generation");
	const auto resumable_enemy = resumable.spawn("tank", 0.0F, 0.0F, 30.0F, 4.0F, 0.0F, 2.0F, 45.0F);
	require(resumable.apply_damage_over_time(resumable_enemy, 2.0F, 0.5, 2.0),
			"snapshot fixture should have a live status effect");
	const auto resumable_projectile = resumable.spawn_projectile("inferno_sprayer", 50.0F, 10.0F,
			5.0F, 3.0F, 4.0, 20.0F, 0.0F, 1.5F, 0.25, 1.5, 12.0F, 0.5F);
	const auto resumable_orb = resumable.spawn_xp_orb(-20.0F, 4.0F, 9.0F);
	const auto free_slot = resumable.spawn("chaser", 100.0F, 0.0F, 10.0F, 0.0F, 0.0F);
	require(resumable.despawn(free_slot), "snapshot fixture should retain a reusable free slot");
	resumable.advance(0.2);
	const auto core_state = resumable.capture_state();
	SimulationCore restored;
	restored.restore_state(core_state);
	require(restored.entity_count() == resumable.entity_count() &&
			std::abs(restored.simulation_time() - resumable.simulation_time()) < 1e-12 &&
		restored.entity(resumable_enemy)->id == resumable_enemy,
			"core restore should preserve active IDs, entity count and simulation clock");
	const auto restored_projectile = restored.entity(resumable_projectile);
	require(restored_projectile && restored_projectile->is_projectile &&
			restored_projectile->projectile.applies_damage_over_time &&
			restored_projectile->projectile.explosion_radius == 12.0F &&
			std::abs(restored_projectile->projectile.remaining_seconds - 3.8) < 1e-9,
			"core restore should preserve projectile state and remaining lifetime");
	const auto restored_dot_target = restored.entity(resumable_enemy);
	require(restored_dot_target && restored_dot_target->damage_over_time &&
			std::abs(restored_dot_target->damage_over_time->time_to_tick - 0.3) < 1e-9 &&
			restored_dot_target->damage_over_time->status_type == "generic" &&
			restored_projectile->projectile.status_type == "burn",
			"core restore should preserve damage-over-time clocks and status identity");
	const auto restored_orb = restored.entity(resumable_orb);
	require(restored_orb && restored_orb->is_xp_orb && restored_orb->xp_value == 9.0F,
			"core restore should preserve XP orb components");
	const auto original_events = resumable.advance(0.3);
	const auto restored_events = restored.advance(0.3);
	require(original_events.size() == restored_events.size() && original_events.size() == 1 &&
			original_events[0].sequence == restored_events[0].sequence &&
			original_events[0].target == restored_events[0].target &&
			original_events[0].amount == restored_events[0].amount,
			"restored and original cores should continue with the same event sequence and result");
	const auto original_recycled = resumable.spawn("sprinter", 0.0F, 0.0F, 5.0F, 0.0F, 0.0F);
	const auto restored_recycled = restored.spawn("sprinter", 0.0F, 0.0F, 5.0F, 0.0F, 0.0F);
	require(original_recycled == restored_recycled && original_recycled.index == free_slot.index &&
			original_recycled.generation == free_slot.generation + 1,
			"core restore should preserve free indices and entity generations");
	auto invalid_core_state = core_state;
	invalid_core_state.active_slots.pop_back();
	const auto unchanged_time = restored.simulation_time();
	bool rejected_invalid_core_state = false;
	try {
		restored.restore_state(invalid_core_state);
	} catch (const std::invalid_argument &) {
		rejected_invalid_core_state = true;
	}
	require(rejected_invalid_core_state && restored.simulation_time() == unchanged_time &&
			restored.entity_count() == resumable.entity_count(),
			"invalid core snapshots should be rejected without changing the live core");
	auto invalid_status_core_state = core_state;
	invalid_status_core_state.entities[resumable_enemy.index].damage_over_time->status_type = "shock";
	bool rejected_unknown_status_type = false;
	try {
		restored.restore_state(invalid_status_core_state);
	} catch (const std::invalid_argument &) {
		rejected_unknown_status_type = true;
	}
	require(rejected_unknown_status_type && restored.simulation_time() == unchanged_time,
			"core restore should reject unknown damage-over-time identities without mutating live state");

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
