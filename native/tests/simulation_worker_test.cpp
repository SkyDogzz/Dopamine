#include "dopamine/simulation/simulation_worker.hpp"

#include <chrono>
#include <cmath>
#include <cstdlib>
#include <iostream>

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

	SimulationCommand resume;
	resume.type = CommandType::Resume;
	submit_and_wait(worker, resume);
	require(!worker.snapshot()->paused, "resume should unpause simulation");

	SimulationCommand pause;
	pause.type = CommandType::Pause;
	submit_and_wait(worker, pause);
	require(worker.snapshot()->paused, "pause should stop continuous simulation");

	SimulationCommand despawn;
	despawn.type = CommandType::Despawn;
	despawn.entity = after_step->entities[0].id;
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

	worker.stop();
	worker.stop();
	require(!worker.is_running(), "stop should be safe and leave no worker thread");
	require(worker.submit(spawn) == 0, "stopped worker should reject new commands");
	return 0;
}
