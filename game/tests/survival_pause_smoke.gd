extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	var spawn_sequence: int = session.simulation.spawn_enemy(
		"chaser", 1, session.player.global_position + Vector2(120.0, 0.0), Vector2(-20.0, 0.0)
	)
	var spawn_deadline := Time.get_ticks_msec() + 1000
	while int(session.simulation.snapshot()["last_sequence"]) < spawn_sequence and Time.get_ticks_msec() < spawn_deadline:
		await process_frame
	var state: Dictionary = session.simulation.snapshot()
	if bool(state["paused"]) or state["entities"].is_empty():
		_fail("The pause smoke requires an active run with an enemy fixture")
		return

	await _send_input(_escape_event())
	state = session.simulation.snapshot()
	var pause_menu: Control = session.get_node_or_null("HUD/PauseOverlay")
	if pause_menu == null or not pause_menu.visible or not bool(state["paused"]):
		_fail("Escape should pause the active run and show the pause menu: paused=%s manual=%s menu=%s" % [state["paused"], session._manually_paused, pause_menu])
		return
	var resume_button: Button = pause_menu.get_node_or_null("Center/Panel/Content/ResumeButton")
	if resume_button == null or root.gui_get_focus_owner() != resume_button:
		_fail("The pause menu should focus Resume when it opens: button=%s owner=%s visible=%s" % [resume_button, root.gui_get_focus_owner(), pause_menu.visible])
		return
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png("/tmp/dopamine-pause.png") != OK:
			_fail("Could not capture the paused Survival HUD")
			return

	var paused_simulation_time := float(state["simulation_time"])
	var paused_active_time := float(session.player_active_time)
	var paused_wave_time := float(session.wave_director.elapsed_in_wave)
	var paused_player_position: Vector2 = session.player.global_position
	var paused_enemy_position := _enemy_position(state)
	var original_size: Vector2i = root.size
	var pause_card: Control = pause_menu.get_node("Center/Panel")
	for size in [Vector2i(960, 600), Vector2i(1280, 800), Vector2i(1600, 900)]:
		root.size = size
		await process_frame
		if not Rect2(Vector2.ZERO, Vector2(size)).encloses(pause_card.get_global_rect()):
			_fail("Pause menu should fit viewport %s" % size)
			return
	root.size = original_size
	var options_button: Button = pause_menu.get_node("Center/Panel/Content/OptionsButton")
	options_button.pressed.emit()
	await process_frame
	var options_panel: Control = session.get_node_or_null("HUD/OptionsPanel")
	if options_panel == null or not options_panel.visible:
		_fail("Options should open above the visible pause menu")
		return
	if not bool(session.simulation.snapshot()["paused"]):
		_fail("Opening Options from pause must not resume the run")
		return
	await create_timer(0.1).timeout
	state = session.simulation.snapshot()
	if not is_equal_approx(float(state["simulation_time"]), paused_simulation_time) or \
		not is_equal_approx(session.player_active_time, paused_active_time) or \
		session.player.global_position != paused_player_position:
		_fail("Simulation clocks and player position should stay frozen with Options open")
		return
	var back_button: Button = options_panel.get_node("Content/Center/OptionsCard/OptionsContent/BackButton")
	back_button.pressed.emit()
	await process_frame
	await process_frame
	if session.get_node_or_null("HUD/OptionsPanel") != null or not pause_menu.visible or \
		root.gui_get_focus_owner() != options_button or not bool(session.simulation.snapshot()["paused"]):
		_fail("Closing Options should return to Pause, restore focus and keep the run paused")
		return
	options_button.pressed.emit()
	await process_frame
	options_panel = session.get_node("HUD/OptionsPanel")
	await _send_gamepad_button(JOY_BUTTON_B)
	await process_frame
	if session.get_node_or_null("HUD/OptionsPanel") != null or not pause_menu.visible or \
		root.gui_get_focus_owner() != options_button or not bool(session.simulation.snapshot()["paused"]):
		_fail("Escape in Options should return to Pause without resuming the run")
		return
	await create_timer(0.2).timeout
	state = session.simulation.snapshot()
	if not is_equal_approx(float(state["simulation_time"]), paused_simulation_time) or \
		not is_equal_approx(session.player_active_time, paused_active_time) or \
		not is_equal_approx(session.wave_director.elapsed_in_wave, paused_wave_time) or \
		session.player.global_position != paused_player_position or _enemy_position(state) != paused_enemy_position:
		_fail("Simulation, run clocks, wave clock and actor positions should stay frozen during pause")
		return

	await _send_gamepad_button(JOY_BUTTON_B)
	var resumed_deadline := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < resumed_deadline:
		state = session.simulation.snapshot()
		if not bool(state["paused"]) and float(state["simulation_time"]) > paused_simulation_time:
			break
		await process_frame
	if pause_menu.visible or bool(state["paused"]):
		_fail("Escape should close the pause menu and resume the same run")
		return
	if float(state["simulation_time"]) <= paused_simulation_time:
		_fail("The simulation should advance again after resuming")
		return
	await _send_gamepad_button(JOY_BUTTON_B)
	state = session.simulation.snapshot()
	if not bool(state["paused"]) or not pause_menu.visible:
		_fail("Gamepad B should pause the active run")
		return
	await _send_input(_escape_event())
	state = session.simulation.snapshot()
	if bool(state["paused"]) or pause_menu.visible:
		_fail("Escape should resume the same run after a gamepad pause")
		return

	print("Survival pause smoke passed")
	quit()

func _escape_event() -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	return event

func _send_input(event: InputEventKey) -> void:
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _send_gamepad_button(button_index: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button_index
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _enemy_position(state: Dictionary) -> Vector2:
	var transform: Dictionary = state["entities"][0]["components"]["Transform2D"]
	return Vector2(float(transform["x"]), float(transform["y"]))

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
