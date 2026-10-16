extends SceneTree

const TEST_DIRECTORY := "user://survival_abandon_smoke"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var save_service = load("res://scripts/save_service.gd").new(directory)
	var progression = load("res://scripts/progression_service.gd").new(save_service, "0")
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.progression_service = progression
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	current_scene = session
	await process_frame
	var before: Dictionary = progression.load_profile()["profile"]
	await _send_escape()
	var abandon_button: Button = session.get_node_or_null("HUD/PauseOverlay/Center/Panel/Content/AbandonButton")
	if abandon_button == null:
		_fail("Pause should expose an abandon action")
		return
	abandon_button.pressed.emit()
	await process_frame
	var confirmation: Control = session.get_node_or_null("HUD/PauseOverlay/ConfirmationOverlay")
	if confirmation == null or not confirmation.visible or not bool(session.simulation.snapshot()["paused"]):
		_fail("Abandon should require confirmation while the run stays paused")
		return
	var original_size: Vector2i = root.size
	var confirmation_card: Control = confirmation.get_node("Center/Panel")
	for size in [Vector2i(960, 600), Vector2i(1280, 800), Vector2i(1600, 900)]:
		root.size = size
		await process_frame
		if not Rect2(Vector2.ZERO, Vector2(size)).encloses(confirmation_card.get_global_rect()):
			_fail("Abandon confirmation should fit viewport %s" % size)
			return
	root.size = original_size
	var cancel_button: Button = confirmation.get_node("Center/Panel/Content/CancelButton")
	if root.gui_get_focus_owner() != cancel_button:
		_fail("Abandon confirmation should focus the safe cancel action first")
		return
	cancel_button.pressed.emit()
	await process_frame
	if confirmation.visible or not session.get_node("HUD/PauseOverlay").visible or \
		root.gui_get_focus_owner() != abandon_button or not bool(session.simulation.snapshot()["paused"]):
		_fail("Cancel should return to Pause without changing or resuming the run")
		return
	abandon_button.pressed.emit()
	await process_frame
	confirmation = session.get_node("HUD/PauseOverlay/ConfirmationOverlay")
	await _send_escape()
	if confirmation.visible or root.gui_get_focus_owner() != abandon_button or \
		not bool(session.simulation.snapshot()["paused"]):
		_fail("Escape should cancel abandonment and keep the run paused")
		return
	abandon_button.pressed.emit()
	await process_frame
	await _send_gamepad_cancel()
	if confirmation.visible or root.gui_get_focus_owner() != abandon_button or \
		not bool(session.simulation.snapshot()["paused"]):
		_fail("Gamepad B should cancel abandonment and keep the run paused")
		return
	abandon_button.pressed.emit()
	await process_frame
	confirmation = session.get_node("HUD/PauseOverlay/ConfirmationOverlay")
	(confirmation.get_node("Center/Panel/Content/ConfirmButton") as Button).pressed.emit()
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if current_scene != session:
			break
	if current_scene == null or not current_scene.scene_file_path.ends_with("launch_menu.tscn"):
		_fail("Confirmed abandonment should return to the launch menu")
		return
	var after: Dictionary = progression.load_profile()["profile"]
	if after["rewarded_survival_runs"] != before["rewarded_survival_runs"] or \
		after["resources"] != before["resources"] or \
		after["equipment_inventory"] != before["equipment_inventory"]:
		_fail("Abandonment must not grant a run reward or modify progression")
		return
	if is_instance_valid(session):
		_fail("The abandoned run session should be removed after returning home")
		return
	print("Survival abandon smoke passed")
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

func _send_gamepad_cancel() -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = JOY_BUTTON_B
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
