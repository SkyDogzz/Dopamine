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
	var fixture_profile: Dictionary = progression.load_profile()["profile"]
	var equipment_generator = load("res://scripts/equipment_generator.gd").new(17)
	var first_equipment: Dictionary = equipment_generator.generate_survival_item("inventory-fixture")
	var second_equipment: Dictionary = equipment_generator.generate_survival_item("inventory-fixture-two")
	first_equipment["rarity"] = "legendary"
	first_equipment["stat_lines"] = [
		{"stat_id": "damage_pct", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 9},
		{"stat_id": "attack_speed_pct", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0},
		{"stat_id": "critical_chance_pct", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0},
	]
	first_equipment["unique_effect_id"] = "pending_choice"
	second_equipment["rarity"] = "legendary"
	second_equipment["stat_lines"] = [
		{"stat_id": "max_hp", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0},
		{"stat_id": "move_speed_pct", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0},
		{"stat_id": "xp_pct", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0},
	]
	second_equipment["unique_effect_id"] = "overflow_shield"
	fixture_profile["equipment_inventory"] = [first_equipment, second_equipment]
	fixture_profile["equipment_inventory"][1]["slot"] = fixture_profile["equipment_inventory"][0]["slot"]
	fixture_profile["resources"]["powder_basic"] = 100
	fixture_profile["resources"]["essence"] = 200
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
	if not panel.visible or _equipment_rows(items).size() != 2:
		_fail("The hub equipment panel should list the profile's permanent items")
		return
	var item_content: VBoxContainer = _equipment_row(items, 0).get_child(0).get_child(1)
	var rarity_icon: TextureRect = _equipment_row(items, 0).get_child(0).get_child(0).get_child(1)
	if rarity_icon.texture == null or rarity_icon.texture.resource_path != "res://assets/icons/catalog/rarity_legendary.png":
		_fail("Inventory rows should display their equipment rarity icon")
		return
	var choose_effect_button := _find_button(item_content, "CHOOSE EFFECT")
	if choose_effect_button == null:
		_fail("Legendary equipment should expose its unique effect choice in the hub")
		return
	var effect_select := item_content.get_child(5).get_child(0) as OptionButton
	if effect_select.item_count != progression.PROPOSED_UNIQUE_EFFECTS.size():
		_fail("The hub should not offer unique effects without gameplay behavior")
		return
	for option_index in range(effect_select.item_count):
		if effect_select.get_item_metadata(option_index) == "revive_knockback":
			_fail("Revive Knockback should stay unavailable until a resurrection contract exists")
			return
	effect_select.select(1)
	choose_effect_button.pressed.emit()
	if progression.load_profile()["profile"]["equipment_inventory"][0]["unique_effect_id"] == "pending_choice":
		_fail("Selecting a unique effect should persist the choice")
		return
	item_content = _equipment_row(items, 0).get_child(0).get_child(1)
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
	item_content = _equipment_row(items, 0).get_child(0).get_child(1)
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
	_find_button(_equipment_row(items, 1).get_child(0).get_child(1), "EQUIP").pressed.emit()
	var replacement: Dictionary = progression.load_profile()["profile"]
	if replacement["equipment_inventory"][0]["equipped"] or not replacement["equipment_inventory"][1]["equipped"]:
		_fail("Equipping another item in the same slot should replace the first one")
		return
	_find_button(_equipment_row(items, 1).get_child(0).get_child(1), "UNEQUIP").pressed.emit()
	var dismantle := _find_button(_equipment_row(items, 1).get_child(0).get_child(1), "DISMANTLE  •  +1 BASIC POWDER")
	if dismantle == null:
		dismantle = _find_button_with_prefix(_equipment_row(items, 1).get_child(0).get_child(1), "DISMANTLE")
	if dismantle == null:
		_fail("Equipment should expose a dismantle action in the hub")
		return
	dismantle.pressed.emit()
	if _equipment_rows(items).size() != 1:
		_fail("Dismantling should remove the item from the hub inventory")
		return
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png("/tmp/dopamine-equipment-inventory.png") != OK:
			_fail("Could not capture the equipment inventory render")
			return
	var remaining_content: VBoxContainer = _equipment_row(items, 0).get_child(0).get_child(1)
	var sell_button := _find_button_with_prefix(remaining_content, "SELL  •  40 ESSENCE")
	if sell_button == null:
		_fail("Equipment should expose a rarity-priced sell action")
		return
	sell_button.pressed.emit()
	var sell_confirmation: ConfirmationDialog = panel.get_node("SellConfirmation")
	if not sell_confirmation.visible or not sell_confirmation.dialog_text.contains("40 Essence"):
		_fail("Selling an item should show its irreversible Essence value for confirmation")
		return
	sell_confirmation.confirmed.emit()
	var sold_profile: Dictionary = progression.load_profile()["profile"]
	if not sold_profile["equipment_inventory"].is_empty() or sold_profile["resources"]["essence"] != 240 or \
			_equipment_rows(items).size() != 0:
		_fail("Confirmed sale should remove the item, credit Essence once and refresh the empty state")
		return
	sold_profile["resources"]["essence"] = 850
	if not save_service.save_slot("0", sold_profile):
		_fail("The skill tree fixture should save enough Essence for its proposed stat and unlock branches")
		return
	panel.get_node("Panel/Content/CloseButton").pressed.emit()
	if panel.visible or root.gui_get_focus_owner() != equipment_button:
		_fail("Closing the hub inventory should restore focus to its opener")
		return
	var skill_button: Button = hub.get_node("Content/Main/PreparationCard/Body/SkillTreeButton")
	skill_button.pressed.emit()
	var skill_panel: Control = hub.get_node("SkillTreePanel")
	if not skill_panel.visible or skill_panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FoundationCard/Content/VitalityButton").disabled:
		_fail("The hub skill tree should show the proposed node when funded")
		return
	skill_panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FoundationCard/Content/VitalityButton").pressed.emit()
	if not is_equal_approx(progression.skill_bonus("max_hp_pct"), 0.05):
		_fail("Unlocking Vitality should persist its proposed maximum HP bonus")
		return
	var focus_button: Button = skill_panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/FocusButton")
	if focus_button.disabled:
		_fail("The dependent prototype skill node should become available")
		return
	focus_button.pressed.emit()
	if not is_equal_approx(progression.skill_bonus("damage_pct"), 0.03):
		_fail("Unlocking Focused Training should persist its proposed damage bonus")
		return
	var mastery_button: Button = skill_panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/MasteryButton")
	if mastery_button.disabled:
		_fail("The skill mastery node should become available after its branch prerequisite")
		return
	mastery_button.pressed.emit()
	if not is_equal_approx(progression.skill_bonus("move_speed_pct"), 0.02):
		_fail("Unlocking Fleet Footed should persist its proposed move speed bonus")
		return
	var precision_button: Button = skill_panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/PrecisionButton")
	if precision_button.disabled:
		_fail("The advanced critical node should become available after its mastery prerequisite")
		return
	precision_button.pressed.emit()
	if not is_equal_approx(progression.skill_bonus("critical_chance_pct"), 1.0):
		_fail("Unlocking Steady Aim should persist its proposed critical chance bonus")
		return
	var weapon_unlock_button: Button = skill_panel.get_node("Panel/Content/NodeScroll/Rows/UnlockBranch/UnlockWeaponCard/Content/WeaponUnlockButton")
	if weapon_unlock_button.disabled:
		_fail("The proposed weapon unlock should become available after Vitality")
		return
	weapon_unlock_button.pressed.emit()
	if not progression.unlocked_weapon_ids().has("crimson_daggers") or progression.unlocked_relic_ids().has("blood_chalice"):
		_fail("Unlocking Crimson Daggers should add that weapon without unlocking its relic")
		return
	var relic_unlock_button: Button = skill_panel.get_node("Panel/Content/NodeScroll/Rows/UnlockBranch/UnlockRelicCard/Content/RelicUnlockButton")
	if relic_unlock_button.disabled:
		_fail("The Blood Chalice unlock should become available after its weapon node")
		return
	relic_unlock_button.pressed.emit()
	if not progression.unlocked_relic_ids().has("blood_chalice"):
		_fail("Unlocking Blood Chalice should add the relic to future run drafts")
		return
	var skill_session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	skill_session.progression_service = progression
	skill_session.spawn_initial_enemy = false
	skill_session.wave_spawning_enabled = false
	skill_session.skip_starting_weapon_choice = true
	root.add_child(skill_session)
	await process_frame
	if not is_equal_approx(skill_session.player.move_speed, 240.0 * 1.02) or \
		not is_equal_approx(skill_session._critical_chance(), 1.0) or \
		skill_session.loadout._weapons.size() != 3 or skill_session.loadout._relics.size() != 3:
		_fail("The unlocked proposed stats and equipment should affect a real Survival session")
		return
	skill_session.queue_free()
	await process_frame
	skill_panel.get_node("Panel/Content/RespecButton").pressed.emit()
	if not is_zero_approx(progression.skill_bonus("max_hp_pct")) or \
		not is_zero_approx(progression.skill_bonus("damage_pct")) or \
		not is_zero_approx(progression.skill_bonus("move_speed_pct")) or \
		not is_zero_approx(progression.skill_bonus("critical_chance_pct")) or \
		progression.load_profile()["profile"]["resources"]["essence"] != 850 or \
		progression.unlocked_weapon_ids().size() != 2 or progression.unlocked_relic_ids().size() != 2:
		_fail("Free skill respec should restore Essence and remove prototype bonuses")
		return
	skill_panel.get_node("Panel/Content/CloseButton").pressed.emit()
	if skill_panel.visible or root.gui_get_focus_owner() != skill_button:
		_fail("Closing the skill tree should restore focus to its hub control")
		return
	panel.present({})
	var empty_state: Label = panel.get_node("Panel/Content/Scroll/Items/EmptyState")
	var error_state: Label = panel.get_node("Panel/Content/Scroll/Items/ErrorState")
	if not empty_state.visible or error_state.visible:
		_fail("An empty equipment inventory should show its centered empty state")
		return
	panel.present_error()
	if empty_state.visible or not error_state.visible:
		_fail("An unavailable profile should show its error state instead of the empty state")
		return
	panel.get_node("Panel/Content/CloseButton").pressed.emit()
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

func _find_button_with_prefix(parent: Node, text_prefix: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text.begins_with(text_prefix):
			return child
		if child.get_child_count() > 0:
			var nested := _find_button_with_prefix(child, text_prefix)
			if nested != null:
				return nested
	return null

func _equipment_rows(items: VBoxContainer) -> Array[Control]:
	var rows: Array[Control] = []
	for child in items.get_children():
		if child.name.begins_with("Equipment_"):
			rows.append(child)
	return rows

func _equipment_row(items: VBoxContainer, index: int) -> Control:
	return _equipment_rows(items)[index]
