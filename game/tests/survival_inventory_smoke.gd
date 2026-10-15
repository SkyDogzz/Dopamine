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
	fixture_profile["resources"]["powder_basic"] = 100
	fixture_profile["resources"]["essence"] = 200
	fixture_profile["equipment_inventory"][0]["rarity"] = "legendary"
	fixture_profile["equipment_inventory"][0]["stat_lines"] = [
		{"stat_id": "damage_pct", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 9},
		{"stat_id": "attack_speed_pct", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0},
		{"stat_id": "critical_chance_pct", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0},
	]
	fixture_profile["equipment_inventory"][0]["unique_effect_id"] = "pending_choice"
	fixture_profile["equipment_inventory"][0]["stat_lines"][0]["fail_streak"] = 9
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
	var choose_effect_button: Button = _find_button(item_content, "CHOOSE EFFECT")
	if choose_effect_button.text != "CHOOSE EFFECT":
		_fail("Legendary equipment should expose its unique effect choice")
		return
	choose_effect_button.pressed.emit()
	var chosen_effect_profile: Dictionary = progression.load_profile()["profile"]
	if chosen_effect_profile["equipment_inventory"][0]["unique_effect_id"] == "pending_choice":
		_fail("Selecting a unique effect should persist the choice")
		return
	item_content = items.get_child(0).get_child(0).get_child(1)
	var status_label: Label = _find_label(item_content, "PROPOSED STAT ROLLS")
	if not item_content.get_child(0).text.contains(" • ") or status_label == null:
		_fail("An inventory item should show its slot, rarity and proposed roll status")
		return
	var enhancement_row: HBoxContainer = item_content.get_child(1)
	var enhance_button: Button = enhancement_row.get_child(2)
	if enhance_button.disabled or not enhancement_row.get_child(1).text.contains("BASIC"):
		_fail("The inventory should expose an enabled enhancement control and Powder tier selector")
		return
	enhance_button.pressed.emit()
	var enhanced_profile: Dictionary = progression.load_profile()["profile"]
	if enhanced_profile["equipment_inventory"][0]["stat_lines"][0]["enhancement_level"] != 1 or \
			"SUCCESS" not in panel.get_node("Panel/Content/Feedback").text:
		_fail("The inventory enhancement action should persist and report its guaranteed success")
		return
	item_content = items.get_child(0).get_child(0).get_child(1)
	var equip_button: Button = _find_button(item_content, "EQUIP")
	equip_button.pressed.emit()
	var equipped_profile: Dictionary = progression.load_profile()["profile"]
	if not equipped_profile["equipment_inventory"][0].get("equipped", false) or \
			equipped_profile["equipment_inventory"][1].get("equipped", false) or \
				not _find_label(items.get_child(0).get_child(0).get_child(1),
				"EQUIPPED — proposed stat rolls active"):
		_fail("Equipping an item should persist and show that its proposed stat rolls are active")
		return
	_find_button(items.get_child(1).get_child(0).get_child(1), "EQUIP").pressed.emit()
	var replaced_profile: Dictionary = progression.load_profile()["profile"]
	if replaced_profile["equipment_inventory"][0].get("equipped", false) or \
			not replaced_profile["equipment_inventory"][1].get("equipped", false):
		_fail("Equipping another item in the same slot should replace the first one")
		return
	_find_button(items.get_child(1).get_child(0).get_child(1), "UNEQUIP").pressed.emit()
	var unequipped_profile: Dictionary = progression.load_profile()["profile"]
	if unequipped_profile["equipment_inventory"][0].get("equipped", false) or \
			unequipped_profile["equipment_inventory"][1].get("equipped", false):
		_fail("The inventory should allow its equipped item to be unequipped")
		return
	var dismantle_button: Button = _find_button(items.get_child(1).get_child(0).get_child(1), "DISMANTLE  •  +1 BASIC POWDER")
	if dismantle_button == null:
		var second_content: VBoxContainer = items.get_child(1).get_child(0).get_child(1)
		for child in second_content.get_children():
			if child is Button and child.text.begins_with("DISMANTLE"):
				dismantle_button = child
				break
	if dismantle_button == null:
		_fail("Equipment should expose a dismantle action")
		return
	dismantle_button.pressed.emit()
	if items.get_child_count() != 1 or not panel.get_node("Panel/Content/Feedback").text.contains("ITEM DISMANTLED"):
		_fail("Dismantling should remove the item from the inventory and report the powder reward")
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
	var skills_button: Button = session.get_node("HUD/SkillsButton")
	skills_button.pressed.emit()
	if not await _wait_for_pause_state(session, true):
		_fail("Opening the skill tree should pause the running simulation")
		return
	var skill_panel = session.get_node("HUD/SkillTreeOverlay")
	if not skill_panel.visible or skill_panel.get_node("Panel/Content/VitalityButton").disabled:
		_fail("The skill tree should show the proposed node when enough Essence is available")
		return
	skill_panel.get_node("Panel/Content/VitalityButton").pressed.emit()
	if not is_equal_approx(progression.skill_bonus("max_hp_pct"), 0.05):
		_fail("Unlocking the vitality node should apply its proposed maximum HP bonus")
		return
	var focus_button: Button = skill_panel.get_node("Panel/Content/FocusButton")
	if focus_button.disabled:
		_fail("The dependent prototype skill node should become available after Vitality")
		return
	focus_button.pressed.emit()
	if not is_equal_approx(progression.skill_bonus("damage_pct"), 0.03):
		_fail("Unlocking Focused Training should apply its proposed damage bonus")
		return
	skill_panel.get_node("Panel/Content/RespecButton").pressed.emit()
	if not is_zero_approx(progression.skill_bonus("max_hp_pct")) or \
			not is_zero_approx(progression.skill_bonus("damage_pct")) or \
			progression.load_profile()["profile"]["resources"]["essence"] != 200:
		_fail("Free skill respec should restore Essence and remove the prototype bonus")
		return
	skill_panel.get_node("Panel/Content/CloseButton").pressed.emit()
	if not await _wait_for_pause_state(session, false):
		_fail("Closing the skill tree should resume the previously running simulation")
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

func _find_label(parent: Node, text_fragment: String) -> Label:
	for child in parent.get_children():
		if child is Label and text_fragment in child.text:
			return child
	return null

func _find_button(parent: Node, text_value: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text == text_value:
			return child
		if child.get_child_count() > 0:
			var nested := _find_button(child, text_value)
			if nested != null:
				return nested
	return null
