#include "combat_simulation.hpp"

#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_dopamine(ModuleInitializationLevel level) {
	if (level == MODULE_INITIALIZATION_LEVEL_SCENE) {
		GDREGISTER_CLASS(CombatSimulationSnapshot);
		GDREGISTER_CLASS(CombatSimulation);
	}
}

void uninitialize_dopamine(ModuleInitializationLevel) {}

extern "C" {
GDExtensionBool GDE_EXPORT dopamine_library_init(
		GDExtensionInterfaceGetProcAddress get_proc_address,
		GDExtensionClassLibraryPtr library,
		GDExtensionInitialization *initialization) {
	GDExtensionBinding::InitObject init_object(get_proc_address, library, initialization);
	init_object.register_initializer(initialize_dopamine);
	init_object.register_terminator(uninitialize_dopamine);
	init_object.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
	return init_object.init();
}
}
