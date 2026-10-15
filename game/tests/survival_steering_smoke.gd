extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.weapon_enabled = false
	session.spawn_initial_enemy = true
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
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
	session.set_physics_process(false)
	var slow_target_sequence: int = session.simulation.set_steering_target(Vector2.ZERO, 10.0, 0.0, 0.0)
	state = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return int(snapshot["last_sequence"]) >= slow_target_sequence
	)
	if state.is_empty():
		_fail("Survival should accept a slower generic steering target for the profile speed check")
		return
	session._spawn_wave_enemy()
	state = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return snapshot["entities"].size() == 2
	)
	if state.is_empty():
		_fail("Survival should spawn a wave enemy through the shared enemy-profile API")
		return
	var wave_enemy: Dictionary = state["entities"][1]["components"]
	var wave_velocity: Dictionary = wave_enemy["Velocity2D"]
	if not is_equal_approx(float(wave_enemy["MoveSpeed"]), 75.0) or \
			not is_equal_approx(Vector2(float(wave_velocity["x"]), float(wave_velocity["y"])).length(), 75.0):
		_fail("Wave-spawned Chasers should preserve their profile speed instead of generic steering speed")
		return
	session.set_physics_process(true)
	session.player.global_position = Vector2(400.0, 0.0)
	state = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		var last_sequence: int = int(snapshot["last_sequence"])
		var current_velocity: Dictionary = snapshot["entities"][0]["components"]["Velocity2D"]
		return last_sequence >= session.last_target_sequence and float(current_velocity["x"]) > 0.0
	)
	if state.is_empty():
		_fail("Enemy should follow the updated Godot player position")
		return
	session.simulation.set_speed(4.0)
	state = await _wait_until(session, func(_snapshot: Dictionary) -> bool:
		return session.get("player_hp") != null and float(session.get("player_hp")) < 100.0
	)
	if state.is_empty():
		_fail("Active simulation time should apply HP decay to the Survival player")
		return
	session.simulation.pause()
	state = await _wait_until(session, func(snapshot: Dictionary) -> bool: return snapshot["paused"])
	if state.is_empty():
		_fail("Survival should pause before a deterministic kill-heal check")
		return
	var hp_when_paused: float = float(session.get("player_hp"))
	await process_frame
	await process_frame
	if not is_equal_approx(float(session.get("player_hp")), hp_when_paused):
		_fail("HP decay should stop while the Survival simulation is paused")
		return
	session.set("player_hp", 80.0)
	var enemy_position: Dictionary = state["entities"][0]["components"]["Transform2D"]
	var projectile_sequence: int = session.simulation.spawn_projectile("test_bolt",
		Vector2(float(enemy_position["x"]), float(enemy_position["y"])), Vector2.ZERO, 1000.0, 12.0, 1.0)
	if projectile_sequence <= 0:
		_fail("Survival simulation should accept a test projectile")
		return
	state = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return snapshot["last_sequence"] >= projectile_sequence
	)
	if state.is_empty():
		_fail("Survival test projectile spawn timed out")
		return
	session.simulation.step(0.01)
	state = await _wait_until(session, func(_snapshot: Dictionary) -> bool:
		return float(session.get("player_hp")) > 84.0
	)
	if state.is_empty():
		_fail("Enemy death should apply the proposed kill heal to Survival HP")
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
