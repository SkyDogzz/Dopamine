extends SceneTree

const TEST_DIRECTORY := "user://survival_hub_smoke"

class FailingSaveService:
	extends RefCounted
	func load_slot(_slot_id: String) -> Dictionary:
		return {"ok": false, "error": "unreadable"}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var save_service = load("res://scripts/save_service.gd").new(directory)
	var progression = load("res://scripts/progression_service.gd").new(save_service, "0")
	var equipment_fixture: Dictionary = progression.load_profile()["profile"]
	equipment_fixture["equipment_inventory"] = [{
		"instance_id": "hub-stale-equipment", "slot": "helmet", "rarity": "normal",
		"stat_lines": [{"stat_id": "max_hp", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0}],
		"equipped": false, "unique_effect_id": "", "source_mode": "survival",
	}]
	if not save_service.save_slot("0", equipment_fixture):
		_fail("Could not seed the isolated equipment failure fixture")
		return
	var hub := load("res://scenes/survival_hub.tscn").instantiate() as Control
	hub.progression_service = progression
	root.add_child(hub)
	current_scene = hub
	await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png("/tmp/dopamine-survival-hub.png") != OK:
			_fail("Could not capture the Survival hub render")
			return
	var bounds := hub.get_viewport_rect()
	for path in ["Content", "Content/Header/BackButton", "Content/Main/DifficultyCard", "Content/Main/PreparationCard/Body/LaunchButton"]:
		var control := hub.get_node(path) as Control
		var rect := control.get_global_rect()
		if not bounds.encloses(rect):
			_fail("Hub control %s should fit the logical viewport %s, got %s" % [path, bounds, rect])
			return
	var difficulty_list: VBoxContainer = hub.get_node("Content/Main/DifficultyCard/Body/DifficultyList")
	if difficulty_list.get_child_count() != 5:
		_fail("The Survival hub should show all five difficulties")
		return
	var easy := _difficulty_button(hub, "EASY")
	var normal := _difficulty_button(hub, "NORMAL")
	var hard := _difficulty_button(hub, "HARD")
	if easy == null or not easy.button_pressed or easy.disabled or not normal.disabled or not hard.disabled:
		_fail("A new profile should select Easy and keep later difficulties visibly locked")
		return
	var launch_button: Button = hub.get_node("Content/Main/PreparationCard/Body/LaunchButton")
	var temporary_launch_button: Button = hub.get_node("Content/Main/PreparationCard/Body/TemporaryLaunchButton")
	var endless_launch_button: Button = hub.get_node("Content/Main/PreparationCard/Body/ModeButtons/EndlessLaunchButton")
	if not endless_launch_button.disabled:
		_fail("Endless standard should stay locked before a Survival victory")
		return
	if launch_button.text != "LANCER LA RUN  ·  EASY  →":
		_fail("The primary launch action should repeat the selected difficulty")
		return
	if not hard.tooltip_text.contains("NORMAL"):
		_fail("A locked difficulty should explain its previous-difficulty requirement")
		return
	normal.pressed.emit()
	if hub.selected_difficulty != "easy":
		_fail("A locked difficulty must not replace the selected one")
		return
	var achievements := hub.get_node("Content/Main/PreparationCard/Body/InactiveFeatures/AchievementsButton") as Button
	var bestiary := hub.get_node("Content/Main/PreparationCard/Body/InactiveFeatures/BestiaryButton") as Button
	var equipment_button := hub.get_node("Content/Main/PreparationCard/Body/EquipmentButton") as Button
	var skill_button := hub.get_node("Content/Main/PreparationCard/Body/SkillTreeButton") as Button
	var records_button := hub.get_node_or_null("Content/Header/RecordsButton") as Button
	if records_button == null or records_button.focus_mode == Control.FOCUS_NONE:
		_fail("Armorless records should have a keyboard-focusable hub action")
		return
	if equipment_button.icon == null or equipment_button.icon.resource_path != "res://assets/icons/catalog/equipment_armor.png" or \
		skill_button.icon == null or skill_button.icon.resource_path != "res://assets/icons/catalog/skill_node.png" or \
		equipment_button.get_theme_constant("icon_max_width") != 16 or skill_button.get_theme_constant("icon_max_width") != 16 or \
		equipment_button.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST or \
		skill_button.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_fail("Permanent preparation actions should use their existing compact pixel icons")
		return
	if achievements == null or bestiary == null or achievements.focus_mode == Control.FOCUS_NONE or \
		bestiary.focus_mode == Control.FOCUS_NONE or achievements.pressed.get_connections().size() != 1 or \
		bestiary.pressed.get_connections().size() != 1:
		_fail("Achievements and Codex should both be focusable and actionable")
		return
	if achievements.theme_type_variation != "Button" or bestiary.theme_type_variation != "Button" or \
		achievements.disabled or bestiary.disabled or bestiary.text != "CODEX" or achievements.text != "SUCCÈS":
		_fail("Achievements and Codex should be available from the hub")
		return
	if achievements.icon == null or achievements.icon.resource_path != "res://assets/icons/catalog/achievement_medal.png" or \
		bestiary.icon == null or bestiary.icon.resource_path != "res://assets/sprites/roster/enemy_chaser.png":
		_fail("Success and Codex entries should use their existing pixel art icons")
		return
	if achievements.get_theme_constant("icon_max_width") != 16 or bestiary.get_theme_constant("icon_max_width") != 16 or \
		achievements.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST or \
		bestiary.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_fail("Inactive entry icons should keep a compact nearest-filtered pixel size")
		return
	if achievements.get_theme_color("icon_normal_color") != hub.theme.get_color("icon_normal_color", "Button") or \
		achievements.get_theme_color("icon_focus_color") != hub.theme.get_color("icon_focus_color", "Button") or \
		bestiary.get_theme_color("icon_focus_color") != hub.theme.get_color("icon_focus_color", "Button"):
		_fail("Hub entry icons should use the shared focus color")
		return
	if achievements.get_theme_stylebox("focus") != hub.theme.get_stylebox("focus", "Button"):
		_fail("Achievement entry should use the shared focus style")
		return
	for variation in ["Button", "OptionButton"]:
		var disabled_style := hub.theme.get_stylebox("disabled", variation) as StyleBoxFlat
		var disabled_text := hub.theme.get_color("font_disabled_color", variation)
		if disabled_style == null or _contrast_ratio(disabled_text, disabled_style.bg_color) < 4.5:
			_fail("Disabled %s labels should keep at least 4.5:1 contrast against their background" % variation)
			return
	equipment_button.grab_focus()
	await _send_key(KEY_DOWN)
	if root.gui_get_focus_owner() != skill_button:
		_fail("Keyboard navigation should reach the skill tree from equipment")
		return
	await _send_key(KEY_DOWN)
	var inactive_focus := root.gui_get_focus_owner()
	if inactive_focus != achievements and inactive_focus != bestiary:
		_fail("Keyboard navigation should reach a feature entry from the skill tree")
		return
	await _send_key(KEY_RIGHT if inactive_focus == achievements else KEY_LEFT)
	if root.gui_get_focus_owner() != (bestiary if inactive_focus == achievements else achievements):
		_fail("Keyboard navigation should reach both inactive features")
		return
	await _send_mouse_click(achievements)
	await process_frame
	var achievements_panel: Control = hub.get_node("AchievementsPanel")
	if not achievements_panel.visible or achievements_panel.get_node("Center/Panel/Content/Body/Entries").get_child_count() != 100:
		_fail("Achievements should open a panel with all 100 achievement families")
		return
	if not bounds.encloses(achievements_panel.get_node("Center/Panel").get_global_rect()):
		_fail("Achievements panel should fit the logical viewport")
		return
	await _send_key(KEY_ESCAPE)
	if achievements_panel.visible or root.gui_get_focus_owner() != achievements:
		_fail("Escape should close Achievements and restore focus to its hub button")
		return
	hub._open_codex()
	await process_frame
	var codex: Control = hub.get_node("CodexPanel")
	if not codex.visible or codex.get_node("Center/Panel/Content/Body/Entries").get_child_count() != 12:
		_fail("Codex should open with the implemented enemy roster")
		return
	var enemy_entries: VBoxContainer = codex.get_node("Center/Panel/Content/Body/Entries")
	if enemy_entries.get_child(0).get_child(1).get_child(0).text != "INCONNU" or \
		enemy_entries.get_child(0).get_child(1).get_child(1).text.find("NON RENCONTRÉ") < 0:
		_fail("An enemy not encountered in Survival should remain hidden in Codex")
		return
	if not bounds.encloses(codex.get_node("Center/Panel").get_global_rect()):
		_fail("Codex should fit the logical viewport")
		return
	var category: OptionButton = codex.get_node("Center/Panel/Content/Category")
	category.select(1)
	category.item_selected.emit(1)
	await process_frame
	var entries: VBoxContainer = codex.get_node("Center/Panel/Content/Body/Entries")
	if entries.get_child_count() != 10 or entries.get_child(0).get_child(1).get_child(0).text != "Lightning Conductor" or \
		entries.get_child(2).get_child(1).get_child(0).text != "Crimson Daggers" or \
		not entries.get_child(2).get_child(1).get_child(1).text.contains("ARME VERROUILLÉE"):
		_fail("Codex should describe locked weapons while clearly marking their locked status")
		return
	if not entries.get_child(0).get_child(1).get_child(1).text.contains("Infinite Circuit") or \
		not entries.get_child(2).get_child(1).get_child(1).text.contains("combo verrouillé"):
		_fail("Unlocked starter combos should be described while locked combinations stay hidden")
		return
	category.select(2)
	category.item_selected.emit(2)
	await process_frame
	if entries.get_child_count() != 11:
		_fail("Codex should show all eleven relics")
		return
	if entries.get_child(2).get_child(1).get_child(0).text != "Blood Chalice" or \
		not entries.get_child(2).get_child(1).get_child(1).text.contains("VERROUILLÉE"):
		_fail("Codex should describe locked relics while clearly marking their locked status")
		return
	await _send_key(KEY_ESCAPE)
	if codex.visible or root.gui_get_focus_owner() != bestiary:
		_fail("Escape should close Codex and restore focus to its hub button")
		return
	equipment_button.grab_focus()
	await _send_gamepad_button(JOY_BUTTON_DPAD_DOWN)
	if root.gui_get_focus_owner() != skill_button:
		_fail("Gamepad navigation should reach the skill tree from equipment")
		return
	await _send_gamepad_button(JOY_BUTTON_DPAD_DOWN)
	inactive_focus = root.gui_get_focus_owner()
	if inactive_focus != achievements and inactive_focus != bestiary:
		_fail("Gamepad navigation should reach a hub feature from the skill tree")
		return
	await _send_gamepad_button(JOY_BUTTON_DPAD_RIGHT if inactive_focus == achievements else JOY_BUTTON_DPAD_LEFT)
	if root.gui_get_focus_owner() != (bestiary if inactive_focus == achievements else achievements):
		_fail("Gamepad navigation should reach both inactive features")
		return
	await _send_gamepad_button(JOY_BUTTON_A)
	var activated_achievements_panel: Control = hub.get_node("AchievementsPanel")
	var codex_panel: Control = hub.get_node("CodexPanel")
	if (inactive_focus == achievements and not activated_achievements_panel.visible) or \
		(inactive_focus == bestiary and not codex_panel.visible):
		_fail("Gamepad activation should open the focused hub reference panel")
		return
	await _send_gamepad_cancel()
	if activated_achievements_panel.visible or codex_panel.visible:
		_fail("Gamepad B should close the focused reference panel")
		return
	equipment_button.pressed.emit()
	await process_frame
	var equipment_panel: Control = hub.get_node("EquipmentInventoryPanel")
	if not equipment_panel.visible:
		_fail("Equipment should open from the hub")
		return
	await _send_gamepad_cancel()
	if equipment_panel.visible or root.gui_get_focus_owner() != equipment_button:
		_fail("Gamepad B should close permanent equipment and restore hub focus")
		return
	skill_button.pressed.emit()
	await process_frame
	var skill_panel: Control = hub.get_node("SkillTreePanel")
	if not skill_panel.visible:
		_fail("The skill tree should open from the hub")
		return
	await _send_gamepad_cancel()
	if skill_panel.visible or root.gui_get_focus_owner() != skill_button:
		_fail("Gamepad B should close the skill tree and restore hub focus")
		return
	equipment_button.grab_focus()
	await _send_key(KEY_ENTER)
	if not equipment_panel.visible:
		_fail("Keyboard Enter should open permanent equipment from the hub")
		return
	await _send_key(KEY_ESCAPE)
	if equipment_panel.visible or root.gui_get_focus_owner() != equipment_button:
		_fail("Keyboard Escape should close equipment and restore hub focus")
		return
	equipment_button.pressed.emit()
	await process_frame
	var management_button: Button = equipment_panel.get_node(
		"Panel/Content/Columns/RightColumn/ItemHeader/ManagementButton"
	)
	management_button.pressed.emit()
	await process_frame
	var stale_equipment_row: Control = equipment_panel.get_node(
		"Panel/Content/Columns/RightColumn/Scroll/Items/Equipment_hub-stale-equipment"
	)
	var stale_equipment_action := stale_equipment_row.find_child("EquipmentStateAction", true, false) as Button
	if stale_equipment_action == null:
		_fail("The temporary equipment item should expose its existing equip action")
		return
	var changed_profile: Dictionary = progression.load_profile()["profile"]
	changed_profile["equipment_inventory"] = []
	if not save_service.save_slot("0", changed_profile):
		_fail("Could not stale the displayed equipment fixture")
		return
	stale_equipment_action.pressed.emit()
	await process_frame
	var equipment_feedback: Label = equipment_panel.get_node("Panel/Content/Feedback")
	if not equipment_panel.visible or not equipment_feedback.visible or \
			not equipment_feedback.text.begins_with("ACTION FAILED:"):
		_fail("A failed equipment service action should retain the panel and show its error feedback")
		return
	if "--capture-equipment-error" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var evidence_path := ProjectSettings.globalize_path(
			"res://../docs/art/evidence/2026-10-18/states/equipment-action-failed.png"
		)
		if root.get_texture().get_image().save_png(evidence_path) != OK:
			_fail("Could not save integrated equipment error evidence")
			return
		print("Equipment action error evidence capture: %s" % evidence_path)
	hub._close_equipment()
	skill_button.grab_focus()
	await _send_key(KEY_ENTER)
	if not skill_panel.visible:
		_fail("Keyboard Enter should open the skill tree from the hub")
		return
	await _send_key(KEY_ESCAPE)
	if skill_panel.visible or root.gui_get_focus_owner() != skill_button:
		_fail("Keyboard Escape should close the skill tree and restore hub focus")
		return
	var broken_hub: Control = load("res://scenes/survival_hub.tscn").instantiate()
	broken_hub.progression_service = load("res://scripts/progression_service.gd").new(FailingSaveService.new(), "0")
	root.add_child(broken_hub)
	await process_frame
	if not broken_hub.get_node("Content/Header/ProfileStatus").text.contains("PROFIL INDISPONIBLE") or \
		not broken_hub.get_node("Content/Main/PreparationCard/Body/LaunchButton").disabled or \
		not broken_hub.get_node("Content/Header/RecordsButton").disabled:
		_fail("A profile load error should be clear and must block run launch")
		return
	broken_hub.queue_free()
	await process_frame
	var easy_win: Dictionary = progression.award_survival_run("hub-unlock", 24, true, 0, "easy")
	if not easy_win.get("ok", false):
		_fail("The test profile should record a difficulty unlock")
		return
	var armorless_record: Dictionary = progression.record_armorless_result("normal", 12, 300.0, 11)
	if not armorless_record.get("ok", false) or not armorless_record.get("updated", false):
		_fail("The test profile should store a Normal Armorless record")
		return
	var endless_record: Dictionary = progression.record_endless_standard_result("normal", 18, 900.0, 27)
	if not endless_record.get("ok", false) or not endless_record.get("updated", false):
		_fail("The test profile should store an Easy Endless standard record")
		return
	hub._load_profile()
	if endless_launch_button.disabled:
		_fail("A Survival final-boss victory should unlock the Endless hub action")
		return
	if _difficulty_button(hub, "NORMAL").disabled or not _difficulty_button(hub, "HARD").disabled:
		_fail("The hub should update sequential unlock states from the profile")
		return
	_difficulty_button(hub, "NORMAL").pressed.emit()
	var record_status: Label = hub.get_node_or_null("Content/Main/DifficultyCard/Body/ArmorlessRecordStatus")
	if record_status == null or not record_status.text.contains("WAVE 12") or \
		not record_status.text.contains("05:00") or not record_status.text.contains("11 KILLS"):
		_fail("Selecting Normal should show its Armorless personal best from the profile")
		return
	var endless_record_status: Label = hub.get_node_or_null("Content/Main/DifficultyCard/Body/EndlessRecordStatus")
	if endless_record_status == null or not endless_record_status.text.contains("WAVE 18") or \
		not endless_record_status.text.contains("15:00") or not endless_record_status.text.contains("27 KILLS"):
		_fail("The hub should show the selected difficulty's Endless standard personal best")
		return
	if hub.selected_difficulty != "normal":
		_fail("An unlocked difficulty should become the selected launch value")
		return
	if launch_button.text != "LANCER LA RUN  ·  NORMAL  →":
		_fail("The primary launch action should track difficulty selection")
		return
	records_button.pressed.emit()
	await process_frame
	var records_panel: Control = hub.get_node_or_null("ArmorlessRecordsPanel")
	var record_rows: VBoxContainer = records_panel.get_node_or_null("Panel/Content/RecordsScroll/Records") if records_panel != null else null
	if records_panel == null or not records_panel.visible or record_rows == null or record_rows.get_child_count() != 5:
		_fail("The hub should open a read-only Armorless records panel with all five difficulties: panel=%s visible=%s rows=%s" % [
			records_panel != null, records_panel.visible if records_panel != null else false,
		record_rows.get_child_count() if record_rows != null else -1,
		])
		return
	var normal_record_row := ""
	var easy_record_row := ""
	for row in record_rows.get_children():
		if row.name == "NORMAL":
			normal_record_row = (row as Label).text
		elif row.name == "EASY":
			easy_record_row = (row as Label).text
	if not easy_record_row.contains("AUCUN RECORD"):
		_fail("The records panel should show an explicit empty state for difficulties without a record")
		return
	if not normal_record_row.contains("VAGUE 12") or not normal_record_row.contains("05:00") or \
		not normal_record_row.contains("11 KILLS"):
		_fail("The records panel should show the saved Normal score: %s" % normal_record_row)
		return
	await _send_gamepad_cancel()
	if records_panel.visible or root.gui_get_focus_owner() != records_button:
		_fail("Gamepad B should close the records panel and restore hub focus")
		return
	if temporary_launch_button.text != "RUN TEMPORAIRE · SANS SAUVEGARDE":
		_fail("The temporary profile action should remain separate from normal difficulty selection")
		return
	_difficulty_button(hub, "EASY").pressed.emit()
	hub._launch_run()
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if current_scene != null and current_scene.scene_file_path.ends_with("survival_session.tscn"):
			break
	if current_scene == null or not current_scene.scene_file_path.ends_with("survival_session.tscn") or \
		current_scene.difficulty_id != "easy" or current_scene.progression_service != progression:
		_fail("Launching from the hub should pass the selected difficulty and normal profile service into the run")
		return
	if current_scene.loadout._weapons.size() != 2 or current_scene.loadout._relics.size() != 2:
		_fail("A normal profile should limit run draws to its two initially unlocked weapons and relics")
		return
	if not current_scene.get_node("HUD/ChestOverlay/ChestChoice").visible:
		_fail("The starting weapon choice should remain the first run choice")
		return
	current_scene.queue_free()
	await process_frame
	var armorless_hub: Control = load("res://scenes/survival_hub.tscn").instantiate()
	armorless_hub.progression_service = progression
	root.add_child(armorless_hub)
	current_scene = armorless_hub
	await process_frame
	var armorless_button: Button = armorless_hub.get_node("Content/Main/PreparationCard/Body/ModeButtons/ArmorlessLaunchButton")
	if armorless_button.disabled or not armorless_button.focus_mode == Control.FOCUS_ALL:
		_fail("Armorless should be an available, keyboard-focusable hub launch action")
		return
	armorless_button.pressed.emit()
	deadline = Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if current_scene != armorless_hub:
			break
	if current_scene == armorless_hub or current_scene.mode_id != "armorless" or \
		current_scene.progression_service != progression or not current_scene.wave_director.endless_armorless:
		_fail("The Armorless hub action should launch the selected difficulty with the persistent profile and endless rules")
		return
	current_scene.queue_free()
	await process_frame
	var back_hub := load("res://scenes/survival_hub.tscn").instantiate() as Control
	back_hub.progression_service = progression
	root.add_child(back_hub)
	current_scene = back_hub
	await process_frame
	await _send_gamepad_cancel()
	await process_frame
	if current_scene == null or current_scene.scene_file_path != "res://scenes/launch_menu.tscn":
		_fail("Gamepad B should return from the hub to the launch menu")
		return
	var endless_hub := load("res://scenes/survival_hub.tscn").instantiate() as Control
	endless_hub.progression_service = progression
	root.add_child(endless_hub)
	current_scene = endless_hub
	await process_frame
	var endless_button: Button = endless_hub.get_node("Content/Main/PreparationCard/Body/ModeButtons/EndlessLaunchButton")
	if endless_button.disabled or endless_button.text != "ENDLESS STANDARD  →":
		_fail("A previously unlocked Endless mode should be clearly available in the hub")
		return
	endless_hub._launch_endless_run()
	deadline = Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if current_scene != endless_hub:
			break
	if current_scene == endless_hub or current_scene.mode_id != "endless" or \
		current_scene.difficulty_id != "easy" or current_scene.progression_service != progression or \
		not current_scene.wave_director.endless_standard:
		_fail("The unlocked hub action should start an Endless standard session with its endless director")
		return
	if current_scene.loadout.weapon_level("lightning_conductor") != 0 or \
		current_scene.loadout.relic_level("magnet_heart") != 0:
		_fail("A hub Endless run should start without carrying weapon or relic run levels")
		return
	var expected_max_hp: float = current_scene.simulation.initial_player_hp() * \
		(1.0 + progression.skill_bonus("max_hp_pct")) + progression.equipment_bonus("max_hp")
	if not is_equal_approx(current_scene.player_max_hp, expected_max_hp):
		_fail("A hub Endless run should apply the permanent skill and equipment HP bonuses")
		return
	print("Survival hub profile, difficulty, panels, inactive actions and focus smoke passed")
	quit()

func _difficulty_button(hub: Control, label: String) -> Button:
	var list: VBoxContainer = hub.get_node("Content/Main/DifficultyCard/Body/DifficultyList")
	for child in list.get_children():
		var button := child as Button
		if button.text.begins_with(label):
			return button
	return null

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

func _send_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
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

func _contrast_ratio(first: Color, second: Color) -> float:
	var first_luminance := _relative_luminance(first)
	var second_luminance := _relative_luminance(second)
	return (maxf(first_luminance, second_luminance) + 0.05) / \
		(minf(first_luminance, second_luminance) + 0.05)

func _relative_luminance(color: Color) -> float:
	var channels := [color.r, color.g, color.b]
	for index in range(channels.size()):
		var channel: float = channels[index]
		channels[index] = channel / 12.92 if channel <= 0.04045 else pow((channel + 0.055) / 1.055, 2.4)
	return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]

func _send_mouse_click(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
