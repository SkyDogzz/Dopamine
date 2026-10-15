extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var simulation = ClassDB.instantiate("CombatSimulation")
	assert(simulation != null, "CombatSimulation GDExtension class is unavailable")
	assert(simulation.spawn("", 1, Vector2.ZERO, 10.0, Vector2.ZERO) == 0)
	assert(simulation.set_speed(10.0) == 0)

	var spawn_sequence: int = simulation.spawn("chaser", 1, Vector2(1.0, 2.0), 10.0, Vector2(2.0, 0.0))
	var state: Dictionary = await _wait_for_sequence(simulation, spawn_sequence)
	assert(state["entities"].size() == 1)
	var entity_id: Dictionary = state["entities"][0]["id"]
	var initial_position: Dictionary = state["entities"][0]["components"]["Transform2D"]

	var speed_sequence: int = simulation.set_speed(2.0)
	await _wait_for_sequence(simulation, speed_sequence)
	var step_sequence: int = simulation.step(0.25)
	state = await _wait_for_sequence(simulation, step_sequence)
	assert(is_equal_approx(state["simulation_time"], 0.5))
	assert(is_equal_approx(state["entities"][0]["components"]["Transform2D"]["x"], 2.0))
	assert(is_equal_approx(initial_position["x"], 1.0), "Older GDScript snapshots should keep their values")

	var pause_sequence: int = simulation.pause()
	state = await _wait_for_sequence(simulation, pause_sequence)
	assert(state["paused"])
	assert(simulation.step(0.0) == 0)

	var despawn_sequence: int = simulation.despawn(entity_id["index"], entity_id["generation"])
	state = await _wait_for_sequence(simulation, despawn_sequence)
	assert(state["entities"].is_empty())

	var respawn_sequence: int = simulation.spawn("tank", 2, Vector2.ZERO, 20.0, Vector2.ZERO)
	state = await _wait_for_sequence(simulation, respawn_sequence)
	assert(state["entities"].size() == 2)
	var kill_sequence: int = simulation.kill_all()
	state = await _wait_for_sequence(simulation, kill_sequence)
	assert(state["entities"].is_empty())

	var reset_spawn_sequence: int = simulation.spawn("chaser", 1, Vector2.ZERO, 10.0, Vector2.ZERO)
	await _wait_for_sequence(simulation, reset_spawn_sequence)
	var reset_sequence: int = simulation.reset()
	state = await _wait_for_sequence(simulation, reset_sequence)
	assert(state["entities"].is_empty())
	assert(state["simulation_time"] == 0.0)
	assert(state["speed_multiplier"] == 1.0)
	assert(state["paused"])
	print("Sandbox simulation bridge checks passed")
	quit()

func _wait_for_sequence(simulation: Object, sequence: int) -> Dictionary:
	assert(sequence > 0, "Simulation worker rejected command")
	var deadline := Time.get_ticks_msec() + 1000
	var state: Dictionary = simulation.snapshot()
	while state["last_sequence"] < sequence and Time.get_ticks_msec() < deadline:
		await process_frame
		state = simulation.snapshot()
	assert(state["last_sequence"] >= sequence, "Simulation worker timed out")
	return state
