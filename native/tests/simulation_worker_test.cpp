#include "dopamine/simulation/simulation_worker.hpp"

#include <atomic>
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <thread>

using namespace std::chrono_literals;
using dopamine::sim::CommandType;
using dopamine::sim::Entity;
using dopamine::sim::SimulationCommand;
using dopamine::sim::SimulationWorker;
using dopamine::sim::SimulationWorkerState;

namespace {

void require(bool condition, const char *message) {
	if (!condition) {
		std::cerr << message << '\n';
		std::exit(1);
	}
}

uint64_t submit_and_wait(SimulationWorker &worker, const SimulationCommand &command) {
	const uint64_t sequence = worker.submit(command);
	require(sequence != 0, "worker should accept command");
	require(worker.wait_until_applied(sequence, 1s), "worker should apply command");
	return sequence;
}

} // namespace

int main() {
	SimulationWorker worker;
	worker.start();
	require(worker.snapshot()->paused, "worker should start paused");

	SimulationCommand spawn;
	spawn.type = CommandType::Spawn;
	spawn.entity_type = "chaser";
	spawn.count = 1;
	spawn.x = 1.0F;
	spawn.y = 2.0F;
	spawn.hp = 10.0F;
	spawn.velocity_x = 2.0F;
	const uint64_t spawn_sequence = submit_and_wait(worker, spawn);
	const auto after_spawn = worker.snapshot();
	require(after_spawn->last_sequence == spawn_sequence, "snapshot should acknowledge the applied command");
	require(after_spawn->entities.size() == 1, "spawn command should publish one entity");
	const auto first_snapshot = after_spawn;

	SimulationCommand area_damage;
	SimulationCommand area_target;
	area_target.type = CommandType::Spawn;
	area_target.entity_type = "chaser";
	area_target.x = 1000.0F;
	area_target.y = 1000.0F;
	area_target.hp = 10.0F;
	submit_and_wait(worker, area_target);
	area_damage.type = CommandType::DamageEnemiesInRadius;
	area_damage.x = 1000.0F;
	area_damage.y = 1000.0F;
	area_damage.projectile_radius = 32.0F;
	area_damage.projectile_damage = 3.0F;
	submit_and_wait(worker, area_damage);
	const auto after_area_damage = worker.snapshot();
	require(after_area_damage->events.size() == 1 &&
			after_area_damage->events.front().type == dopamine::sim::CombatEventType::Damage &&
			std::any_of(after_area_damage->entities.begin(), after_area_damage->entities.end(),
					[](const Entity &entity) { return entity.transform.x == 1000.0F && entity.health.current == 7.0F; }),
			"area damage command should publish standard damage events for nearby enemies");
	SimulationCommand clear_area_events;
	clear_area_events.type = CommandType::AcknowledgeEvents;
	clear_area_events.event_sequence = after_area_damage->events.back().sequence;
	submit_and_wait(worker, clear_area_events);
	SimulationCommand clear_area_target;
	clear_area_target.type = CommandType::Despawn;
	clear_area_target.entity = after_area_damage->entities.back().id;
	for (const Entity &entity : after_area_damage->entities) {
		if (entity.transform.x == 1000.0F) clear_area_target.entity = entity.id;
	}
	submit_and_wait(worker, clear_area_target);

	SimulationCommand set_speed;
	set_speed.type = CommandType::SetSpeed;
	set_speed.speed_multiplier = 2.0;
	submit_and_wait(worker, set_speed);

	SimulationCommand step;
	step.type = CommandType::Step;
	step.delta_seconds = 0.5;
	submit_and_wait(worker, step);
	const auto after_step = worker.snapshot();
	require(std::abs(after_step->simulation_time - 1.0) < 0.02, "step should apply explicit time and speed");
	require(std::abs(after_step->entities[0].transform.x - 3.0F) < 0.02F, "step should update entity position");
	require(first_snapshot->simulation_time == 0.0, "published snapshots should remain immutable");
	require(first_snapshot->entities[0].transform.x == 1.0F, "old snapshot should retain old entity state");

	SimulationCommand overrides;
	overrides.type = CommandType::ApplySandboxOverrides;
	overrides.steering.max_speed = 42.0F;
	overrides.steering.separation_radius = 24.0F;
	overrides.steering.separation_weight = 0.75F;
	overrides.steering.spatial_hash.cell_size = 48.0F;
	submit_and_wait(worker, overrides);
	require(worker.snapshot()->steering_config.max_speed == 42.0F &&
			worker.snapshot()->steering_config.separation_radius == 24.0F &&
			worker.snapshot()->steering_config.separation_weight == 0.75F &&
			worker.snapshot()->steering_config.spatial_hash.cell_size == 48.0F,
			"valid sandbox override transaction should commit all values atomically");
	overrides.steering.max_speed = 99.0F;
	overrides.steering.separation_weight = 2.0F;
	submit_and_wait(worker, overrides);
	require(worker.snapshot()->steering_config.max_speed == 42.0F &&
			worker.snapshot()->steering_config.separation_weight == 0.75F,
			"invalid sandbox override transaction should roll back every value");

	SimulationCommand resume;
	resume.type = CommandType::Resume;
	submit_and_wait(worker, resume);
	require(!worker.snapshot()->paused, "resume should unpause simulation");

	SimulationCommand pause;
	pause.type = CommandType::Pause;
	submit_and_wait(worker, pause);
	require(worker.snapshot()->paused, "pause should stop continuous simulation");

	SimulationCommand steering_target;
	steering_target.type = CommandType::SetSteeringTarget;
	steering_target.x = 20.0F;
	steering_target.y = 2.0F;
	steering_target.steering.max_speed = 10.0F;
	steering_target.steering.separation_radius = 18.0F;
	steering_target.steering.separation_weight = 0.5F;
	submit_and_wait(worker, steering_target);
	SimulationCommand enemy_speed;
	enemy_speed.type = CommandType::SetEnemySpeedMultiplier;
	enemy_speed.enemy_speed_multiplier = 1.15F;
	submit_and_wait(worker, enemy_speed);
	step.delta_seconds = 0.1;
	submit_and_wait(worker, step);
	const auto after_steering = worker.snapshot();
	require(after_steering->entities[0].velocity.x > 0.0F,
			"worker step should apply target steering through the shared core");
	require(std::abs(std::hypot(after_steering->entities[0].velocity.x,
				after_steering->entities[0].velocity.y) - 11.5F) < 0.01F,
			"worker should apply the event speed multiplier to the existing enemy");
	require(after_steering->entities[0].transform.x > after_step->entities[0].transform.x,
			"steered worker step should move toward its target");

	SimulationCommand despawn;
	despawn.type = CommandType::Despawn;
	despawn.entity = after_steering->entities[0].id;
	submit_and_wait(worker, despawn);
	require(worker.snapshot()->entities.empty(), "despawn command should remove the requested entity");

	spawn.count = 2;
	submit_and_wait(worker, spawn);
	require(worker.snapshot()->entities.size() == 2, "spawn command should honor entity count");
	SimulationCommand kill_all;
	kill_all.type = CommandType::KillAll;
	submit_and_wait(worker, kill_all);
	require(worker.snapshot()->entities.empty(), "kill all should remove every entity");

	spawn.count = 1;
	submit_and_wait(worker, spawn);
	require(worker.snapshot()->entities.size() == 1, "worker should accept spawn after kill all");

	SimulationCommand reset;
	reset.type = CommandType::Reset;
	submit_and_wait(worker, reset);
	const auto after_reset = worker.snapshot();
	require(after_reset->entities.empty(), "reset should clear entities");
	require(after_reset->simulation_time == 0.0, "reset should clear simulation time");
	require(after_reset->paused, "reset should leave simulation paused");
	require(after_reset->speed_multiplier == 1.0, "reset should restore normal speed");
	require(after_reset->steering_config.max_speed == 75.0F &&
			after_reset->steering_config.separation_radius == 18.0F &&
			after_reset->steering_config.separation_weight == 0.5F &&
			after_reset->steering_config.spatial_hash.cell_size == 64.0F,
			"reset should restore every live steering override to its default");

	spawn.x = 100.0F;
	spawn.y = 0.0F;
	spawn.velocity_x = 0.0F;
	spawn.count = 1;
	submit_and_wait(worker, spawn);
	SimulationCommand projectile;
	projectile.type = CommandType::SpawnProjectile;
	projectile.entity_type = "test_projectile";
	projectile.x = 0.0F;
	projectile.y = 0.0F;
	projectile.velocity_x = 1000.0F;
	projectile.projectile_damage = 12.0F;
	projectile.projectile_radius = 2.0F;
	projectile.projectile_lifetime = 1.0;
	submit_and_wait(worker, projectile);
	step.delta_seconds = 0.2;
	submit_and_wait(worker, step);
	const auto with_events = worker.snapshot();
	require(with_events->events.size() == 2, "worker snapshot should retain damage and death events");
	require(with_events->collision_count == 1, "worker should count projectile impacts");
	require(with_events->projectile_count == 0, "consumed projectile should be absent from the snapshot");
	SimulationCommand acknowledge;
	acknowledge.type = CommandType::AcknowledgeEvents;
	acknowledge.event_sequence = with_events->events.back().sequence;
	submit_and_wait(worker, acknowledge);
	require(worker.snapshot()->events.empty(), "acknowledged combat events should leave the pending queue");
	SimulationCommand gravity_target;
	gravity_target.type = CommandType::Spawn;
	gravity_target.entity_type = "gravity_probe";
	gravity_target.x = 0.0F;
	gravity_target.hp = 100.0F;
	submit_and_wait(worker, gravity_target);
	SimulationCommand gravity_steering;
	gravity_steering.type = CommandType::SetSteeringTarget;
	gravity_steering.x = -100.0F;
	gravity_steering.steering.max_speed = 30.0F;
	submit_and_wait(worker, gravity_steering);
	SimulationCommand void_orb;
	void_orb.type = CommandType::SpawnProjectile;
	void_orb.entity_type = "void_orb";
	void_orb.x = 100.0F;
	void_orb.projectile_damage = 5.0F;
	void_orb.projectile_radius = 3.0F;
	void_orb.projectile_lifetime = 3.0;
	void_orb.projectile_attraction_radius = 200.0F;
	void_orb.projectile_attraction_speed = 50.0F;
	void_orb.projectile_pierces_targets = true;
	submit_and_wait(worker, void_orb);
	step.delta_seconds = 0.25;
	submit_and_wait(worker, step);
	const auto gravity_snapshot = worker.snapshot();
	const auto gravity_entity = std::find_if(gravity_snapshot->entities.begin(), gravity_snapshot->entities.end(),
			[](const auto &entity) { return entity.type.id == "gravity_probe"; });
	const auto orb_entity = std::find_if(gravity_snapshot->entities.begin(), gravity_snapshot->entities.end(),
			[](const auto &entity) { return entity.type.id == "void_orb"; });
	require(gravity_entity != gravity_snapshot->entities.end() && gravity_entity->transform.x > 0.0F &&
			orb_entity != gravity_snapshot->entities.end() && orb_entity->projectile.pierces_targets &&
			orb_entity->projectile.attraction_radius == 200.0F,
			"worker should apply, snapshot and retain Void Orb attraction fields");
	SimulationCommand clear_gravity_test;
	clear_gravity_test.type = CommandType::Reset;
	submit_and_wait(worker, clear_gravity_test);
	SimulationCommand dot_targets;
	dot_targets.type = CommandType::Spawn;
	dot_targets.entity_type = "chaser";
	dot_targets.count = 10;
	dot_targets.hp = 100000.0F;
	submit_and_wait(worker, dot_targets);
	const auto dot_target_snapshot = worker.snapshot();
	for (const auto &entity : dot_target_snapshot->entities) {
		SimulationCommand apply_status;
		apply_status.type = CommandType::ApplyDamageOverTime;
		apply_status.entity = entity.id;
		apply_status.status_damage_per_tick = 1.0F;
		apply_status.status_interval_seconds = 0.001;
		apply_status.status_duration_seconds = 1.0;
		submit_and_wait(worker, apply_status);
	}
	step.delta_seconds = 1.0;
	const uint64_t rejected_dot_step = submit_and_wait(worker, step);
	const auto after_rejected_dot_step = worker.snapshot();
	require(after_rejected_dot_step->last_sequence == rejected_dot_step &&
			after_rejected_dot_step->simulation_time == 0.0,
			"worker should acknowledge but not execute a step that exceeds the event budget");
	for (const auto &entity : after_rejected_dot_step->entities) {
		require(entity.health.current == 100000.0F && entity.damage_over_time.has_value(),
				"rejected worker step should preserve health and active statuses");
	}
	require(after_rejected_dot_step->events.empty() && !after_rejected_dot_step->logs.empty() &&
			after_rejected_dot_step->logs.back().find("event budget exceeded") != std::string::npos,
			"worker should explain that an oversized explicit step was rejected");
	step.delta_seconds = 0.1;
	submit_and_wait(worker, step);
	const auto after_bounded_dot_step = worker.snapshot();
	require(std::abs(after_bounded_dot_step->simulation_time - 0.1) < 1e-9 &&
			after_bounded_dot_step->events.size() == 1000,
			"a smaller step should preserve every due damage-over-time event");
	acknowledge.event_sequence = after_bounded_dot_step->events.back().sequence;
	submit_and_wait(worker, acknowledge);
	submit_and_wait(worker, reset);

	SimulationCommand capacity_enemies;
	capacity_enemies.type = CommandType::Spawn;
	capacity_enemies.entity_type = "chaser";
	capacity_enemies.count = 500;
	capacity_enemies.hp = 20.0F;
	const uint64_t enemies_sequence = submit_and_wait(worker, capacity_enemies);
	uint64_t projectiles_sequence = 0;
	for (int index = 0; index < 1999; ++index) {
		SimulationCommand capacity_projectile;
		capacity_projectile.type = CommandType::SpawnProjectile;
		capacity_projectile.entity_type = "benchmark_projectile";
	capacity_projectile.x = 0.0F;
		capacity_projectile.y = 0.0F;
		capacity_projectile.projectile_lifetime = 60.0;
		projectiles_sequence = worker.submit(capacity_projectile);
		require(projectiles_sequence != 0, "worker command queue should accept the benchmark projectile workload");
	}
	require(projectiles_sequence > enemies_sequence && worker.wait_until_applied(projectiles_sequence, 5s),
			"worker should apply the initial benchmark entities");
	SimulationCommand over_capacity_spawn;
	over_capacity_spawn.type = CommandType::Spawn;
	over_capacity_spawn.entity_type = "chaser";
	over_capacity_spawn.count = 2;
	over_capacity_spawn.hp = 20.0F;
	submit_and_wait(worker, over_capacity_spawn);
	const auto after_rejected_spawn = worker.snapshot();
	require(after_rejected_spawn->entities.size() == 2499 &&
			after_rejected_spawn->logs.back().find("spawn rejected: entity count outside limits") != std::string::npos,
			"an over-capacity batch spawn should be rejected without partially adding entities");
	SimulationCommand final_projectile;
	final_projectile.type = CommandType::SpawnProjectile;
	final_projectile.entity_type = "benchmark_projectile";
	final_projectile.x = 0.0F;
	final_projectile.y = 0.0F;
	final_projectile.projectile_lifetime = 60.0;
	const uint64_t final_projectile_sequence = submit_and_wait(worker, final_projectile);
	const auto benchmark_snapshot = worker.snapshot();
	require(final_projectile_sequence > projectiles_sequence && benchmark_snapshot->entities.size() == 2500 &&
			benchmark_snapshot->projectile_count == 2000,
			"worker capacity should match the documented 500-enemy plus 2,000-projectile target after rejection");
	SimulationCommand over_capacity_projectile;
	over_capacity_projectile.type = CommandType::SpawnProjectile;
	over_capacity_projectile.entity_type = "benchmark_projectile";
	const uint64_t over_capacity_sequence = submit_and_wait(worker, over_capacity_projectile);
	require(over_capacity_sequence > final_projectile_sequence && worker.snapshot()->entities.size() == 2500,
			"worker should keep its hard entity cap after reaching the benchmark capacity");
	step.delta_seconds = 1.0 / 60.0;
	submit_and_wait(worker, step);
	const auto benchmark_combat = worker.snapshot();
	require(benchmark_combat->projectile_count == 0 && benchmark_combat->collision_count >= 2000 &&
			benchmark_combat->events.size() <= 4000,
			"worker should resolve the full projectile workload without exceeding its reserved event budget");
	SimulationCommand capture_speed;
	capture_speed.type = CommandType::SetSpeed;
	capture_speed.speed_multiplier = 2.0;
	submit_and_wait(worker, capture_speed);
	SimulationCommand capture_overrides;
	capture_overrides.type = CommandType::ApplySandboxOverrides;
	capture_overrides.steering.max_speed = 48.0F;
	capture_overrides.steering.separation_radius = 30.0F;
	capture_overrides.steering.separation_weight = 0.25F;
	capture_overrides.steering.spatial_hash.cell_size = 32.0F;
	submit_and_wait(worker, capture_overrides);
	SimulationCommand capture_target;
	capture_target.type = CommandType::SetSteeringTarget;
	capture_target.x = 12.0F;
	capture_target.y = -6.0F;
	capture_target.steering = capture_overrides.steering;
	submit_and_wait(worker, capture_target);
	const auto captured_worker_state = worker.capture_state(1s);
	require(captured_worker_state.has_value(), "worker should capture a coherent state at a command barrier");
	const SimulationWorkerState saved_worker_state = *captured_worker_state;
	require(saved_worker_state.format_version == 18 && saved_worker_state.paused && saved_worker_state.speed_multiplier == 2.0 &&
			saved_worker_state.has_steering_target && saved_worker_state.steering_target_x == 12.0F &&
			saved_worker_state.steering_target_y == -6.0F && saved_worker_state.steering_config.max_speed == 48.0F &&
			saved_worker_state.collision_count == benchmark_combat->collision_count &&
			saved_worker_state.pending_events.size() == benchmark_combat->events.size() &&
			!saved_worker_state.logs.empty() && saved_worker_state.pending_commands.empty() &&
			saved_worker_state.next_sequence == saved_worker_state.pending_sequence + 1,
			"worker state should include simulation controls, queues, events, logs and sequence counters");
	require(!worker.restore_state(saved_worker_state), "worker restore should require a stopped worker");

	worker.stop();
	SimulationWorkerState unsupported_worker_state = saved_worker_state;
	unsupported_worker_state.format_version = 16;
	require(!worker.restore_state(unsupported_worker_state), "worker should reject a snapshot from the previous format");
	SimulationWorkerState invalid_worker_state = saved_worker_state;
	invalid_worker_state.speed_multiplier = 8.0;
	SimulationWorkerState invalid_reaction_budget_state = saved_worker_state;
	invalid_reaction_budget_state.pending_events.front().reaction_budget = 65;
	const auto stopped_snapshot = worker.snapshot();
	require(!worker.restore_state(invalid_worker_state) && !worker.restore_state(invalid_reaction_budget_state) &&
			worker.snapshot()->simulation_time == stopped_snapshot->simulation_time &&
			worker.snapshot()->entities.size() == stopped_snapshot->entities.size(),
			"invalid worker state should be rejected without changing the stopped worker");
	SimulationWorkerState gapped_queue_state = saved_worker_state;
	SimulationCommand queued_spawn;
	queued_spawn.type = CommandType::Spawn;
	queued_spawn.sequence = gapped_queue_state.next_sequence + 1;
	queued_spawn.entity_type = "capture_probe";
	gapped_queue_state.pending_commands.push_back(queued_spawn);
	++gapped_queue_state.next_sequence;
	require(!worker.restore_state(gapped_queue_state), "worker restore should reject command sequence gaps");
	SimulationWorkerState queued_command_state = saved_worker_state;
	queued_command_state.pending_events.front().status_type = "burn";
	queued_command_state.pending_events.front().reaction_chain_id = 44;
	queued_command_state.pending_events.front().reaction_budget = 0;
	queued_spawn.sequence = queued_command_state.next_sequence;
	queued_command_state.pending_commands.push_back(queued_spawn);
	++queued_command_state.next_sequence;
	SimulationCommand queued_poison;
	queued_poison.type = CommandType::ApplyDamageOverTime;
	for (std::size_t index = 0; index < queued_command_state.core_state.active_slots.size(); ++index) {
		const Entity &entity = queued_command_state.core_state.entities[index];
		if (queued_command_state.core_state.active_slots[index] && !entity.is_projectile && !entity.is_xp_orb &&
				entity.health.current > 0.0F) {
			queued_poison.entity = entity.id;
			break;
		}
	}
	queued_poison.status_damage_per_tick = 2.0F;
	queued_poison.status_interval_seconds = 0.5;
	queued_poison.status_duration_seconds = 2.0;
	queued_poison.status_type = "poison";
	queued_poison.sequence = queued_command_state.next_sequence;
	queued_command_state.pending_commands.push_back(queued_poison);
	++queued_command_state.next_sequence;
	require(worker.restore_state(queued_command_state), "stopped worker should restore a validated full worker state");
	const auto restored_worker_snapshot = worker.snapshot();
	require(restored_worker_snapshot->paused && restored_worker_snapshot->speed_multiplier == 2.0 &&
			restored_worker_snapshot->collision_count == saved_worker_state.collision_count &&
			restored_worker_snapshot->events.size() == saved_worker_state.pending_events.size() &&
			restored_worker_snapshot->events.front().status_type == "burn" &&
			restored_worker_snapshot->events.front().reaction_chain_id == 44 &&
			restored_worker_snapshot->events.front().reaction_budget == 0 &&
			restored_worker_snapshot->last_sequence == saved_worker_state.pending_sequence &&
			restored_worker_snapshot->steering_config.max_speed == 48.0F,
			"restored worker snapshot should match the captured worker state");
	worker.start();
	SimulationCommand acknowledge_restored_events;
	acknowledge_restored_events.type = CommandType::AcknowledgeEvents;
	acknowledge_restored_events.event_sequence = queued_command_state.last_event_sequence;
	const uint64_t acknowledge_sequence = submit_and_wait(worker, acknowledge_restored_events);
	bool restored_pending_poison = false;
	for (const Entity &entity : worker.snapshot()->entities) {
		if (entity.id == queued_poison.entity && entity.damage_over_time &&
				entity.damage_over_time->status_type == "poison") {
			restored_pending_poison = true;
		}
	}
	require(acknowledge_sequence == queued_command_state.next_sequence &&
			worker.snapshot()->entities.size() == queued_command_state.core_state.entity_count + 1 &&
			restored_pending_poison,
			"restored worker should keep queued typed statuses and continue command numbering after restore");
	step.delta_seconds = 0.01;
	const uint64_t restored_step_sequence = submit_and_wait(worker, step);
	const auto after_restored_step = worker.snapshot();
	require(restored_step_sequence == acknowledge_sequence + 1 && after_restored_step->events.empty() &&
			std::abs(after_restored_step->simulation_time - queued_command_state.core_state.simulation_time - 0.02) < 0.001,
			"restored worker should continue from its saved simulation clock and speed");
	worker.stop();
	worker.stop();
	require(!worker.is_running(), "stop should be safe and leave no worker thread");
	require(worker.submit(spawn) == 0, "stopped worker should reject new commands");

	SimulationWorker loaded_worker;
	loaded_worker.start();
	std::atomic<bool> keep_submitting = true;
	std::jthread producer([&loaded_worker, &keep_submitting] {
		SimulationCommand load;
		load.type = CommandType::Spawn;
		load.entity_type = "stop_stress";
		load.hp = 1.0F;
		while (keep_submitting.load()) {
			loaded_worker.submit(load);
		}
	});
	std::this_thread::sleep_for(10ms);
	loaded_worker.stop();
	keep_submitting.store(false);
	producer.join();
	require(!loaded_worker.is_running(), "stop under concurrent command load should join the worker");
	require(loaded_worker.submit(spawn) == 0, "worker stopped under load should reject new commands");
	return 0;
}
