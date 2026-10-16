#include "dopamine/simulation/simulation_core.hpp"

#include <algorithm>
#include <chrono>
#include <iostream>
#include <numeric>
#include <string_view>
#include <utility>
#include <vector>

using dopamine::sim::SimulationCore;
using Clock = std::chrono::steady_clock;

#if defined(_MSC_VER)
#define DOPAMINE_STRINGIFY_VALUE(value) #value
#define DOPAMINE_STRINGIFY(value) DOPAMINE_STRINGIFY_VALUE(value)
#define DOPAMINE_COMPILER_VERSION "MSVC " DOPAMINE_STRINGIFY(_MSC_FULL_VER)
#elif defined(__VERSION__)
#define DOPAMINE_COMPILER_VERSION __VERSION__
#else
#define DOPAMINE_COMPILER_VERSION "unknown"
#endif

namespace {

void report(std::string_view name, std::vector<double> frame_times_ms) {
	std::sort(frame_times_ms.begin(), frame_times_ms.end());
	const auto percentile = [&frame_times_ms](double fraction) {
		const auto index = static_cast<std::size_t>(fraction * static_cast<double>(frame_times_ms.size() - 1));
		return frame_times_ms[index];
	};
	const double mean = std::accumulate(frame_times_ms.begin(), frame_times_ms.end(), 0.0) /
			static_cast<double>(frame_times_ms.size());
	std::cout << name << " mean_ms=" << mean << " p50_ms=" << percentile(0.50)
			<< " p95_ms=" << percentile(0.95) << " p99_ms=" << percentile(0.99)
			<< " max_ms=" << frame_times_ms.back() << '\n';
}

} // namespace

int main() {
	constexpr int enemy_count = 500;
	constexpr int projectile_count = 2000;
	constexpr int measured_frames = 300;
	constexpr double delta_seconds = 1.0 / 60.0;
	std::cout << "workload=enemies:" << enemy_count << ",projectiles:" << projectile_count
			<< " frames=" << measured_frames << " dt_ms=" << delta_seconds * 1000.0
			<< " compiler=" << DOPAMINE_COMPILER_VERSION << " build="
#ifdef NDEBUG
			<< "release\n";
#else
			<< "debug\n";
#endif

	SimulationCore steady_simulation;
	for (int index = 0; index < enemy_count; ++index) {
		const float x = -800.0F + static_cast<float>(index % 25) * 64.0F;
		const float y = -640.0F + static_cast<float>(index / 25) * 64.0F;
		steady_simulation.spawn("benchmark_enemy", x, y, 10000.0F, 0.0F, 0.0F);
	}
	for (int index = 0; index < projectile_count; ++index) {
		const float x = 10000.0F + static_cast<float>(index % 100) * 64.0F;
		const float y = 10000.0F + static_cast<float>(index / 100) * 64.0F;
		steady_simulation.spawn_projectile("benchmark_projectile", x, y, 1.0F, 3.0F, 60.0,
				120.0F, 0.0F);
	}
	if (steady_simulation.entity_count() != enemy_count + projectile_count) {
		std::cerr << "steady workload setup did not reach the requested entity counts\n";
		return 1;
	}
	std::vector<double> steady_times;
	steady_times.reserve(measured_frames);
	for (int frame = 0; frame < measured_frames; ++frame) {
		const auto start = Clock::now();
		const auto events = steady_simulation.advance(delta_seconds);
		const auto finish = Clock::now();
		if (!events.empty() || steady_simulation.entity_count() != enemy_count + projectile_count) {
			std::cerr << "steady workload unexpectedly changed entity or event counts\n";
			return 1;
		}
		steady_times.push_back(std::chrono::duration<double, std::milli>(finish - start).count());
	}
	report("steady_no_hits", std::move(steady_times));

	SimulationCore impact_simulation;
	for (int index = 0; index < enemy_count; ++index) {
		impact_simulation.spawn("benchmark_enemy", 0.0F, 0.0F, 1000000000.0F, 0.0F, 0.0F);
	}
	std::vector<double> impact_times;
	impact_times.reserve(measured_frames);
	for (int frame = 0; frame < measured_frames; ++frame) {
		for (int index = 0; index < projectile_count; ++index) {
			impact_simulation.spawn_projectile("wildfire_sprayer", 0.0F, 0.0F, 1.0F, 3.0F, 60.0,
					0.0F, 0.0F, 2.0F, 0.5, 2.0, 60.0F, 0.5F);
		}
		if (impact_simulation.entity_count() != enemy_count + projectile_count) {
			std::cerr << "impact workload did not refill to the requested entity counts\n";
			return 1;
		}
		const auto start = Clock::now();
		const auto events = impact_simulation.advance(delta_seconds);
		const auto finish = Clock::now();
		if (events.size() != 2500 || impact_simulation.entity_count() != enemy_count) {
			std::cerr << "impact workload produced events=" << events.size()
					<< " entities=" << impact_simulation.entity_count() << '\n';
			return 1;
		}
		impact_times.push_back(std::chrono::duration<double, std::milli>(finish - start).count());
	}
	report("wildfire_impact_burst", std::move(impact_times));
	return 0;
}
