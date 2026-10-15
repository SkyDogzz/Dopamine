#include "simulation_probe.hpp"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void SimulationProbe::_bind_methods() {
	ClassDB::bind_method(D_METHOD("api_version"), &SimulationProbe::api_version);
}

String SimulationProbe::api_version() const {
	return "4.7";
}
