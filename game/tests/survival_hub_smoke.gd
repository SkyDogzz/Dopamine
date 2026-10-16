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
	var hub := load("res://scenes/survival_hub.tscn").instantiate() as Control
	hub.progression_service = progression
	root.add_child(hub)
	current_scene = hub
	await process_frame
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
	if not hard.tooltip_text.contains("NORMAL"):
		_fail("A locked difficulty should explain its previous-difficulty requirement")
		return
	normal.pressed.emit()
	if hub.selected_difficulty != "easy":
		_fail("A locked difficulty must not replace the selected one")
		return
	var achievements := hub.get_node("Content/Main/PreparationCard/Body/InactiveFeatures/AchievementsButton") as Button
	var bestiary := hub.get_node("Content/Main/PreparationCard/Body/InactiveFeatures/BestiaryButton") as Button
	if achievements == null or bestiary == null or achievements.focus_mode == Control.FOCUS_NONE or \
		bestiary.focus_mode == Control.FOCUS_NONE or not achievements.pressed.get_connections().is_empty() or \
		not bestiary.pressed.get_connections().is_empty():
		_fail("Successes and Bestiary should be focusable and inert")
		return
	if achievements.theme_type_variation != "InactiveButton" or bestiary.theme_type_variation != "InactiveButton" or \
		achievements.disabled or bestiary.disabled:
		_fail("Inactive hub features should use muted visuals but remain focusable")
		return
	if achievements.icon == null or achievements.icon.resource_path != "res://assets/icons/catalog/achievement_medal.png" or \
		bestiary.icon == null or bestiary.icon.resource_path != "res://assets/sprites/roster/enemy_chaser.png":
		_fail("Inactive Success and Bestiary entries should use their existing pixel art icons")
		return
	if achievements.get_theme_constant("icon_max_width") != 16 or bestiary.get_theme_constant("icon_max_width") != 16 or \
		achievements.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST or \
		bestiary.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_fail("Inactive entry icons should keep a compact nearest-filtered pixel size")
		return
	if achievements.get_theme_color("icon_normal_color").to_html(false) != "7b87a2" or \
		bestiary.get_theme_color("icon_normal_color").to_html(false) != "7b87a2" or \
		achievements.get_theme_color("icon_focus_color").to_html(false) != "ffd447" or \
		bestiary.get_theme_color("icon_focus_color").to_html(false) != "ffd447":
		_fail("Inactive entry icons should stay muted at rest and use gold when focused")
		return
	var inactive_style := achievements.get_theme_stylebox("normal") as StyleBoxFlat
	if inactive_style.bg_color.to_html(false) != "1b2340" or \
		achievements.get_theme_stylebox("focus") != hub.theme.get_stylebox("focus", "Button"):
		_fail("Inactive features should look disabled and retain the shared visible focus style")
		return
	var equipment_button := hub.get_node("Content/Main/PreparationCard/Body/EquipmentButton") as Button
	equipment_button.pressed.emit()
	await process_frame
	var equipment_panel: Control = hub.get_node("EquipmentInventoryPanel")
	if not equipment_panel.visible:
		_fail("Equipment should open from the hub")
		return
	var equipment_close := equipment_panel.get_node("Panel/Content/CloseButton") as Button
	equipment_close.pressed.emit()
	await process_frame
	if equipment_panel.visible or root.gui_get_focus_owner() != equipment_button:
		_fail("Closing permanent equipment should return focus to its hub control")
		return
	var skill_button := hub.get_node("Content/Main/PreparationCard/Body/SkillTreeButton") as Button
	skill_button.pressed.emit()
	await process_frame
	var skill_panel: Control = hub.get_node("SkillTreePanel")
	if not skill_panel.visible:
		_fail("The skill tree should open from the hub")
		return
	(skill_panel.get_node("Panel/Content/CloseButton") as Button).pressed.emit()
	await process_frame
	if skill_panel.visible or root.gui_get_focus_owner() != skill_button:
		_fail("Closing the skill tree should return focus to its hub control")
		return
	var broken_hub: Control = load("res://scenes/survival_hub.tscn").instantiate()
	broken_hub.progression_service = load("res://scripts/progression_service.gd").new(FailingSaveService.new(), "0")
	root.add_child(broken_hub)
	await process_frame
	if not broken_hub.get_node("Content/Header/ProfileStatus").text.contains("PROFIL INDISPONIBLE") or \
		not broken_hub.get_node("Content/Main/PreparationCard/Body/LaunchButton").disabled:
		_fail("A profile load error should be clear and must block run launch")
		return
	broken_hub.queue_free()
	await process_frame
	var easy_win: Dictionary = progression.award_survival_run("hub-unlock", 24, true, 0, "easy")
	if not easy_win.get("ok", false):
		_fail("The test profile should record a difficulty unlock")
		return
	hub._load_profile()
	if _difficulty_button(hub, "NORMAL").disabled or not _difficulty_button(hub, "HARD").disabled:
		_fail("The hub should update sequential unlock states from the profile")
		return
	_difficulty_button(hub, "NORMAL").pressed.emit()
	if hub.selected_difficulty != "normal":
		_fail("An unlocked difficulty should become the selected launch value")
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
	if not current_scene.get_node("HUD/ChestOverlay/ChestChoice").visible:
		_fail("The starting weapon choice should remain the first run choice")
		return
	current_scene.queue_free()
	await process_frame
	print("Survival hub profile, difficulty, panels, inactive actions and focus smoke passed")
	quit()

func _difficulty_button(hub: Control, label: String) -> Button:
	var list: VBoxContainer = hub.get_node("Content/Main/DifficultyCard/Body/DifficultyList")
	for child in list.get_children():
		var button := child as Button
		if button.text.begins_with(label):
			return button
	return null

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
