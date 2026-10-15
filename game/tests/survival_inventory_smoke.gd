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
	progression.award_survival_run("inventory-fixture-two", 5, false)
	var fixture_profile: Dictionary = progression.load_profile()["profile"]
	fixture_profile["equipment_inventory"][1]["slot"] = fixture_profile["equipment_inventory"][0]["slot"]
	if not save_service.save_slot("0", fixture_profile):
		_fail("Could not save the same-slot inventory fixture")
		return
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
	if not panel.visible or panel.get_node("Panel/Content/Scroll/Items").get_child_count() != 2:
		_fail("The inventory should list both permanent items saved in this profile")
		return
	var items: VBoxContainer = panel.get_node("Panel/Content/Scroll/Items")
	var item_row: HBoxContainer = items.get_child(0).get_child(0)
	var item_content: VBoxContainer = item_row.get_child(1)
	var rarity_icon: TextureRect = item_row.get_child(0)
	if rarity_icon.texture == null or rarity_icon.texture.resource_path != "res://assets/icons/rarity_%s.png" % fixture_profile["equipment_inventory"][0]["rarity"]:
		_fail("Inventory rows should display their equipment rarity icon")
		return
	if not item_content.get_child(0).text.contains(" • ") or \
			not item_content.get_child(2).text.contains("ROLLS UNCALIBRATED"):
		_fail("An inventory item should show its slot, rarity and inactive roll state")
		return
	item_content.get_child(3).pressed.emit()
	var equipped_profile: Dictionary = progression.load_profile()["profile"]
	if not equipped_profile["equipment_inventory"][0].get("equipped", false) or \
			equipped_profile["equipment_inventory"][1].get("equipped", false) or \
				not items.get_child(0).get_child(0).get_child(1).get_child(2).text.contains(
				"EQUIPPED — rolls uncalibrated; no gameplay bonus yet"):
		_fail("Equipping an item should persist and show that its rolls remain inactive")
		return
	items.get_child(1).get_child(0).get_child(1).get_child(3).pressed.emit()
	var replaced_profile: Dictionary = progression.load_profile()["profile"]
	if replaced_profile["equipment_inventory"][0].get("equipped", false) or \
			not replaced_profile["equipment_inventory"][1].get("equipped", false):
		_fail("Equipping another item in the same slot should replace the first one")
		return
	items.get_child(1).get_child(0).get_child(1).get_child(3).pressed.emit()
	var unequipped_profile: Dictionary = progression.load_profile()["profile"]
	if unequipped_profile["equipment_inventory"][0].get("equipped", false) or \
			unequipped_profile["equipment_inventory"][1].get("equipped", false):
		_fail("The inventory should allow its equipped item to be unequipped")
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
