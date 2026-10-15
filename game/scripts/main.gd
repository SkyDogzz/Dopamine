extends Control

func _ready() -> void:
	var probe = ClassDB.instantiate("SimulationProbe")
	assert(probe != null, "SimulationProbe GDExtension class is unavailable")
	var api_version: String = probe.call("api_version")
	assert(api_version == "4.7", "Unexpected Godot API version: %s" % api_version)
	print("Dopamine GDExtension loaded (Godot API %s)" % api_version)
