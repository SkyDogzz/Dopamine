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
	if not save_service.save_slot("0", fixture_profile):
		_fail("Could not save the same-slot inventory fixture")
		return
	var hub: Control = load("res://scenes/survival_hub.tscn").instantiate()
	hub.progression_service = progression
	root.add_child(hub)
	await process_frame
	var equipment_button: Button = hub.get_node("Content/Main/PreparationCard/Body/EquipmentButton")
	equipment_button.pressed.emit()
	var panel: Control = hub.get_node("EquipmentInventoryPanel")
	var items: VBoxContainer = panel.get_node("Panel/Content/Scroll/Items")
	if not panel.visible or items.get_child_count() != 2:
		_fail("The hub equipment panel should list the profile's permanent items")
		return
	var item_content: VBoxContainer = items.get_child(0).get_child(0).get_child(1)
	var rarity_icon: TextureRect = items.get_child(0).get_child(0).get_child(0)
	if rarity_icon.texture == null or rarity_icon.texture.resource_path != "res://assets/icons/catalog/rarity_legendary.png":
		_fail("Inventory rows should display their equipment rarity icon")
		return
	var choose_effect_button := _find_button(item_content, "CHOOSE EFFECT")
	if choose_effect_button == null:
		_fail("Legendary equipment should expose its unique effect choice in the hub")
		return
	(item_content.get_child(5).get_child(0) as OptionButton).select(1)
	choose_effect_button.pressed.emit()
	if progression.load_profile()["profile"]["equipment_inventory"][0]["unique_effect_id"] == "pending_choice":
		_fail("Selecting a unique effect should persist the choice")
		return
	item_content = items.get_child(0).get_child(0).get_child(1)
	var enhancement_row: HBoxContainer = item_content.get_child(1)
	var enhance_button: Button = enhancement_row.get_child(2)
	if enhance_button.disabled or not enhancement_row.get_child(1).text.contains("BASIC"):
		_fail("The inventory should expose enhancement and its Powder selector")
		return
	enhance_button.pressed.emit()
	var enhanced_profile: Dictionary = progression.load_profile()["profile"]
	if enhanced_profile["equipment_inventory"][0]["stat_lines"][0]["enhancement_level"] != 1 or \
		not panel.get_node("Panel/Content/Feedback").text.contains("SUCCESS"):
		_fail("Hub enhancement should persist and report its guaranteed success")
		return
	item_content = items.get_child(0).get_child(0).get_child(1)
	_find_button(item_content, "EQUIP").pressed.emit()
	var equipped_profile: Dictionary = progression.load_profile()["profile"]
	if not equipped_profile["equipment_inventory"][0]["equipped"] or equipped_profile["equipment_inventory"][1]["equipped"]:
		_fail("Equipping a permanent item should persist in the hub")
		return
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.progression_service = progression
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	session.player_hp = session.player_max_hp
	session._pending_lifesteal = 10.0
	session._apply_pending_lifesteal(1.0)
	if not is_equal_approx(session.player_shield, 5.0):
		_fail("The equipped Overflow Shield should remain active in the next run")
		return
	session._take_player_damage(4.0)
	if not is_equal_approx(session.player_shield, 1.0) or not is_equal_approx(session.player_hp, session.player_max_hp):
		_fail("The temporary shield should absorb damage before player HP")
		return
	session.queue_free()
	await process_frame
	_find_button(items.get_child(1).get_child(0).get_child(1), "EQUIP").pressed.emit()
	var replacement: Dictionary = progression.load_profile()["profile"]
	if replacement["equipment_inventory"][0]["equipped"] or not replacement["equipment_inventory"][1]["equipped"]:
		_fail("Equipping another item in the same slot should replace the first one")
		return
	_find_button(items.get_child(1).get_child(0).get_child(1), "UNEQUIP").pressed.emit()
	var dismantle := _find_button(items.get_child(1).get_child(0).get_child(1), "DISMANTLE  •  +1 BASIC POWDER")
	if dismantle == null:
		for child in items.get_child(1).get_child(0).get_child(1).get_children():
			if child is Button and child.text.begins_with("DISMANTLE"):
				dismantle = child
				break
	if dismantle == null:
		_fail("Equipment should expose a dismantle action in the hub")
		return
	dismantle.pressed.emit()
	if items.get_child_count() != 1:
		_fail("Dismantling should remove the item from the hub inventory")
		return
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png("/tmp/dopamine-equipment-inventory.png") != OK:
			_fail("Could not capture the equipment inventory render")
			return
	panel.get_node("Panel/Content/CloseButton").pressed.emit()
	if panel.visible or root.gui_get_focus_owner() != equipment_button:
		_fail("Closing the hub inventory should restore focus to its opener")
		return
	var skill_button: Button = hub.get_node("Content/Main/PreparationCard/Body/SkillTreeButton")
	skill_button.pressed.emit()
	var skill_panel: Control = hub.get_node("SkillTreePanel")
	if not skill_panel.visible or skill_panel.get_node("Panel/Content/VitalityButton").disabled:
		_fail("The hub skill tree should show the proposed node when funded")
		return
	skill_panel.get_node("Panel/Content/VitalityButton").pressed.emit()
	if not is_equal_approx(progression.skill_bonus("max_hp_pct"), 0.05):
		_fail("Unlocking Vitality should persist its proposed maximum HP bonus")
		return
	var focus_button: Button = skill_panel.get_node("Panel/Content/FocusButton")
	if focus_button.disabled:
		_fail("The dependent prototype skill node should become available")
		return
	focus_button.pressed.emit()
	if not is_equal_approx(progression.skill_bonus("damage_pct"), 0.03):
		_fail("Unlocking Focused Training should persist its proposed damage bonus")
		return
	skill_panel.get_node("Panel/Content/RespecButton").pressed.emit()
	if not is_zero_approx(progression.skill_bonus("max_hp_pct")) or \
		not is_zero_approx(progression.skill_bonus("damage_pct")) or \
		progression.load_profile()["profile"]["resources"]["essence"] != 200:
		_fail("Free skill respec should restore Essence and remove prototype bonuses")
		return
	skill_panel.get_node("Panel/Content/CloseButton").pressed.emit()
	if skill_panel.visible or root.gui_get_focus_owner() != skill_button:
		_fail("Closing the skill tree should restore focus to its hub control")
		return
	print("Hub equipment and skill tree smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _find_button(parent: Node, text_value: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text == text_value:
			return child
		if child.get_child_count() > 0:
			var nested := _find_button(child, text_value)
			if nested != null:
				return nested
	return null
