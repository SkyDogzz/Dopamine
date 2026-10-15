#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class SimulationProbe : public RefCounted {
	GDCLASS(SimulationProbe, RefCounted)

protected:
	static void _bind_methods();

public:
	String api_version() const;
};

} // namespace godot
