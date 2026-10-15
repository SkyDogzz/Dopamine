extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	root.add_child(session)
	await process_frame
	if session.simulation == null:
		_fail("Survival session should create the shared simulation")
		return
	var state: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return snapshot["simulation_time"] > 0.08 and snapshot["entities"].size() == 1
	)
	if state.is_empty():
		_fail("Survival enemy did not start pursuing the player")
		return
	var velocity: Dictionary = state["entities"][0]["components"]["Velocity2D"]
	if float(velocity["x"]) >= 0.0:
		_fail("Enemy should steer toward the player from the right")
		return
	session.player.global_position = Vector2(400.0, 0.0)
	state = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		var last_sequence: int = int(snapshot["last_sequence"])
		var current_velocity: Dictionary = snapshot["entities"][0]["components"]["Velocity2D"]
		return last_sequence >= session.last_target_sequence and float(current_velocity["x"]) > 0.0
	)
	if state.is_empty():
		_fail("Enemy should follow the updated Godot player position")
		return
	print("Survival player-to-enemy steering smoke passed")
	quit()

func _wait_until(session: Node2D, predicate: Callable) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var state: Dictionary = session.simulation.snapshot()
		if predicate.call(state):
			return state
	return {}

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
