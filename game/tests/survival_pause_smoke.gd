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
	var state: Dictionary = session.simulation.snapshot()
	if bool(state["paused"]):
		_fail("The pause smoke requires an active run")
		return

	session._unhandled_key_input(_escape_event())
	await process_frame
	state = session.simulation.snapshot()
	var pause_menu: Control = session.get_node_or_null("HUD/PauseOverlay")
	if pause_menu == null or not pause_menu.visible or not bool(state["paused"]):
		_fail("Escape should pause the active run and show the pause menu: paused=%s manual=%s menu=%s" % [state["paused"], session._manually_paused, pause_menu])
		return
	var resume_button: Button = pause_menu.get_node_or_null("Center/Panel/Content/ResumeButton")
	if resume_button == null or root.gui_get_focus_owner() != resume_button:
		_fail("The pause menu should focus Resume when it opens: button=%s owner=%s visible=%s" % [resume_button, root.gui_get_focus_owner(), pause_menu.visible])
		return

	var paused_simulation_time := float(state["simulation_time"])
	var paused_active_time := float(session.player_active_time)
	var paused_wave_time := float(session.wave_director.elapsed_in_wave)
	var paused_player_position: Vector2 = session.player.global_position
	await create_timer(0.2).timeout
	state = session.simulation.snapshot()
	if not is_equal_approx(float(state["simulation_time"]), paused_simulation_time) or \
		not is_equal_approx(session.player_active_time, paused_active_time) or \
		not is_equal_approx(session.wave_director.elapsed_in_wave, paused_wave_time) or \
		session.player.global_position != paused_player_position:
		_fail("Simulation, run clocks, wave clock and player position should stay frozen during pause")
		return

	session._unhandled_key_input(_escape_event())
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

	print("Survival pause smoke passed")
	quit()

func _escape_event() -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	return event

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
