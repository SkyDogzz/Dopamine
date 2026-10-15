extends SceneTree

const TEST_DIRECTORY := "user://survival_inventory_smoke"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var save_service = load("res://scripts/save_service.gd").new(directory)
	var progression = load("res://scripts/progression_service.gd").new(save_service, "0")
	progression.award_survival_run("inventory-fixture", 4, false)
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.progression_service = progression
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	root.add_child(session)
	if not await _wait_for_pause_state(session, false):
		_fail("Survival should resume after the starting weapon is set")
		return
	var button: Button = session.get_node("HUD/EquipmentButton")
	if not button.visible:
		_fail("The normal Survival scene should show its equipment inventory button")
		return
	button.pressed.emit()
	if not await _wait_for_pause_state(session, true):
		_fail("Opening the equipment inventory should pause the simulation")
		return
	var panel = session.get_node("HUD/EquipmentInventoryOverlay")
	if not panel.visible or panel.get_node("Panel/Content/Scroll/Items").get_child_count() != 1:
		_fail("The inventory should list the permanent item saved in this profile")
		return
	var item_row: VBoxContainer = panel.get_node("Panel/Content/Scroll/Items").get_child(0).get_child(0)
	if not item_row.get_child(0).text.contains(" • ") or \
			not item_row.get_child(2).text.contains("ROLLS UNCALIBRATED"):
		_fail("An inventory item should show its slot, rarity and inactive roll state")
		return
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png("/tmp/dopamine-equipment-inventory.png") != OK:
			_fail("Could not capture the equipment inventory render")
			return
	var paused_time := float(session.simulation.snapshot()["simulation_time"])
	await create_timer(0.1).timeout
	if not is_equal_approx(float(session.simulation.snapshot()["simulation_time"]), paused_time):
		_fail("The simulation clock should stay paused while the inventory is open")
		return
	panel.get_node("Panel/Content/CloseButton").pressed.emit()
	if not await _wait_for_pause_state(session, false) or panel.visible or \
			get_root().gui_get_focus_owner() != button:
		_fail("Closing the inventory should resume the run that was previously active")
		return
	session.simulation.pause()
	if not await _wait_for_pause_state(session, true):
		_fail("The manual pause should reach the simulation")
		return
	button.pressed.emit()
	await process_frame
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	panel._input(escape)
	if panel.visible or not bool(session.simulation.snapshot()["paused"]):
		_fail("Escape should close the inventory without resuming a manually paused run")
		return
	print("Survival inventory smoke passed")
	quit()

func _wait_for_pause_state(session: Node2D, expected_paused: bool) -> bool:
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if bool(session.simulation.snapshot()["paused"]) == expected_paused:
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
