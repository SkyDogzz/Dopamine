extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.time_scale = 1.0
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	await _send_escape()
	var speed_select: OptionButton = session.get_node_or_null("HUD/PauseOverlay/Center/Panel/Content/SpeedSelect")
	if speed_select == null:
		_fail("Pause menu should expose simulation speed choices")
		return
	speed_select.select(4)
	speed_select.item_selected.emit(4)
	var deadline := Time.get_ticks_msec() + 1000
	while float(session.simulation.snapshot()["speed_multiplier"]) != 4.0 and Time.get_ticks_msec() < deadline:
		await process_frame
	if not is_equal_approx(Engine.time_scale, 4.0) or not is_equal_approx(float(session.simulation.snapshot()["speed_multiplier"]), 4.0):
		_fail("Selecting ×4 should speed both Godot and combat simulation")
		return
	session.queue_free()
	await process_frame
	if not is_equal_approx(Engine.time_scale, 1.0):
		_fail("Leaving Survival should restore the normal game speed")
		return
	print("Survival speed control smoke passed")
	quit()

func _escape_event() -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	return event

func _send_escape() -> void:
	var event := _escape_event()
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _fail(message: String) -> void:
	Engine.time_scale = 1.0
	push_error(message)
	quit(1)
