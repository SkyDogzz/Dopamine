extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	if session.player.controls_enabled or not session.simulation.snapshot()["paused"]:
		_fail("Starting weapon choice should pause simulation and player controls")
		return
	session.get_node("HUD/ChestOverlay/ChestChoice/Content/Options/Choice0").emit_signal("pressed")
	if not await _wait_until(func() -> bool: return session.player.controls_enabled):
		_fail("Choosing a starting weapon should resume player controls")
		return
	session.player.global_position = Vector2.ZERO
	session._entities = [{"components": {
		"EnemyType": "chaser",
		"Transform2D": {"x": 0.0, "y": 0.0},
	}}]
	session.player_hp = 100.0
	var active_state := {"paused": false}
	session._apply_contact_damage(active_state, 10.0)
	if not is_equal_approx(session.player_hp, 90.0):
		_fail("Enemy contact should apply one proposed damage hit")
		return
	session._apply_contact_damage(active_state, 10.1)
	if not is_equal_approx(session.player_hp, 90.0):
		_fail("Contact damage should respect the invulnerability window")
		return
	session._apply_contact_damage(active_state, 10.36)
	if not is_equal_approx(session.player_hp, 80.0):
		_fail("Contact damage should apply again after invulnerability expires")
		return
	session.simulation.pause()
	if not await _wait_until(func() -> bool:
		return session.simulation.snapshot()["paused"] and not session.player.controls_enabled
	):
		_fail("Pausing the simulation should disable player controls")
		return
	session.simulation.resume()
	if not await _wait_until(func() -> bool: return session.player.controls_enabled):
		_fail("Resuming the simulation should enable player controls")
		return
	session._finish_run(false)
	await process_frame
	if session.player.controls_enabled:
		_fail("Ending a run should disable player controls")
		return
	print("Survival contact damage smoke passed")
	quit()

func _wait_until(predicate: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if predicate.call():
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
