#pragma once

#include "dopamine/simulation/simulation_core.hpp"

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

namespace dopamine::sim {

enum class CommandType {
	Spawn,
	Despawn,
	KillAll,
	Pause,
	Resume,
	Step,
	SetSpeed,
	SetSteeringTarget,
	SpawnProjectile,
	SpawnXpOrb,
	CollectXpOrb,
	AcknowledgeEvents,
	Reset,
};

struct SimulationCommand {
	CommandType type = CommandType::Pause;
	uint64_t sequence = 0;
	std::string entity_type;
	uint32_t count = 1;
	EntityId entity;
	float x = 0.0F;
	float y = 0.0F;
	float hp = 1.0F;
	float threat_level = 1.0F;
	float enemy_move_speed = 0.0F;
	float velocity_x = 0.0F;
	float velocity_y = 0.0F;
	double delta_seconds = 0.0;
	double speed_multiplier = 1.0;
	float projectile_damage = 1.0F;
	float projectile_radius = 3.0F;
	double projectile_lifetime = 5.0;
	float xp_value = 1.0F;
	uint64_t event_sequence = 0;
	SteeringConfig steering;
};

struct SimulationSnapshot {
	bool paused = true;
	double speed_multiplier = 1.0;
	double simulation_time = 0.0;
	double frame_time_ms = 0.0;
	uint64_t last_sequence = 0;
	uint64_t rejected_commands = 0;
	uint64_t collision_count = 0;
	uint64_t projectile_count = 0;
	uint64_t xp_orb_count = 0;
	std::vector<Entity> entities;
	std::vector<CombatEvent> events;
	std::vector<std::string> logs;
};

class SimulationWorker {
public:
	SimulationWorker();
	~SimulationWorker();
	SimulationWorker(const SimulationWorker &) = delete;
	SimulationWorker &operator=(const SimulationWorker &) = delete;

	void start();
	void stop();
	bool is_running() const { return running_.load(); }
	uint64_t submit(SimulationCommand command);
	std::shared_ptr<const SimulationSnapshot> snapshot() const;
	bool wait_until_applied(uint64_t sequence, std::chrono::milliseconds timeout) const;

private:
	void run(std::stop_token stop_token);
	void apply(const SimulationCommand &command);
	void publish(double frame_time_ms);
	void log(std::string message);
	void append_events(std::vector<CombatEvent> events);
	bool has_event_capacity() const;

	static constexpr std::size_t max_queued_commands_ = 2048;
	static constexpr std::size_t max_entities_ = 2000;
	static constexpr std::size_t max_pending_events_ = 8192;
	static constexpr std::size_t max_events_per_advance_ = 4000;

	mutable std::mutex lifecycle_mutex_;
	std::jthread thread_;
	std::atomic<bool> running_ = false;

	mutable std::mutex queue_mutex_;
	std::condition_variable queue_cv_;
	std::deque<SimulationCommand> queue_;
	uint64_t next_sequence_ = 1;

	mutable std::mutex applied_mutex_;
	mutable std::condition_variable applied_cv_;
	std::atomic<std::shared_ptr<const SimulationSnapshot>> published_;
	std::atomic<uint64_t> rejected_commands_ = 0;
	uint64_t pending_sequence_ = 0;

	SimulationCore simulation_;
	bool paused_ = true;
	double speed_multiplier_ = 1.0;
	bool has_steering_target_ = false;
	float steering_target_x_ = 0.0F;
	float steering_target_y_ = 0.0F;
	SteeringConfig steering_config_;
	std::vector<CombatEvent> pending_events_;
	uint64_t last_event_sequence_ = 0;
	uint64_t collision_count_ = 0;
	double deferred_elapsed_ = 0.0;
	std::vector<std::string> logs_;
};

} // namespace dopamine::sim
