extends Control

func _ready() -> void:
	var simulation = ClassDB.instantiate("CombatSimulation")
	assert(simulation != null, "CombatSimulation GDExtension class is unavailable")
	assert(simulation.step(0.0) == 0, "Simulation bridge should reject an empty step")
	assert(simulation.set_speed(10.0) == 0, "Simulation bridge should reject an unsafe speed")
	assert(simulation.spawn("", 1, Vector2.ZERO, 10.0, Vector2.ZERO) == 0, "Simulation bridge should reject an empty type")
	var sequence: int = simulation.spawn("chaser", 1, Vector2(1.0, 2.0), 10.0, Vector2(2.0, 0.0))
	assert(sequence > 0, "Simulation worker rejected spawn")
	await get_tree().create_timer(0.05).timeout
	var state: Dictionary = simulation.snapshot()
	assert(state["last_sequence"] >= sequence, "Worker did not acknowledge spawn")
	assert(state["entities"].size() == 1, "Worker snapshot should contain spawned entity")
	print("Dopamine C++ simulation bridge loaded and responsive")
