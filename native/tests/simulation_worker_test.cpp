#include "dopamine/simulation/simulation_worker.hpp"

#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <thread>

using namespace std::chrono_literals;
using dopamine::sim::CommandType;
using dopamine::sim::SimulationCommand;
using dopamine::sim::SimulationWorker;

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
	step.delta_seconds = 0.1;
	submit_and_wait(worker, step);
	const auto after_steering = worker.snapshot();
	require(after_steering->entities[0].velocity.x > 0.0F,
			"worker step should apply target steering through the shared core");
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
	SimulationCommand dot_targets;
	dot_targets.type = CommandType::Spawn;
	dot_targets.entity_type = "chaser";
	dot_targets.count = 10;
	dot_targets.hp = 100000.0F;
	submit_and_wait(worker, dot_targets);
	for (const auto &entity : worker.snapshot()->entities) {
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
			after_rejected_dot_step->simulation_time == 0.2,
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
	require(std::abs(after_bounded_dot_step->simulation_time - 0.3) < 1e-9 &&
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
	for (int index = 0; index < 2000; ++index) {
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
			"worker should apply 500 enemies and 2,000 projectiles");
	const auto benchmark_snapshot = worker.snapshot();
	require(benchmark_snapshot->entities.size() == 2500 && benchmark_snapshot->projectile_count == 2000,
			"worker capacity should match the documented 500-enemy plus 2,000-projectile target");
	SimulationCommand over_capacity_projectile;
	over_capacity_projectile.type = CommandType::SpawnProjectile;
	over_capacity_projectile.entity_type = "benchmark_projectile";
	const uint64_t over_capacity_sequence = submit_and_wait(worker, over_capacity_projectile);
	require(over_capacity_sequence > projectiles_sequence && worker.snapshot()->entities.size() == 2500,
			"worker should keep its hard entity cap after reaching the benchmark capacity");
	step.delta_seconds = 1.0 / 60.0;
	submit_and_wait(worker, step);
	const auto benchmark_combat = worker.snapshot();
	require(benchmark_combat->projectile_count == 0 && benchmark_combat->collision_count >= 2000 &&
			benchmark_combat->events.size() <= 4000,
			"worker should resolve the full projectile workload without exceeding its reserved event budget");

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
