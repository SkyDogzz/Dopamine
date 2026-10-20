extends Control

const SAVE_SERVICE_SCRIPT := preload("res://scripts/save_service.gd")
const PROGRESSION_SERVICE_SCRIPT := preload("res://scripts/progression_service.gd")
const DIFFICULTY_SCRIPT := preload("res://scripts/survival_difficulty.gd")
const SURVIVAL_ENTRY_SCENE := preload("res://scenes/survival_entry.tscn")
const EQUIPMENT_PANEL_SCENE := preload("res://scenes/equipment_inventory_panel.tscn")
const SKILL_TREE_PANEL_SCENE := preload("res://scenes/skill_tree_panel.tscn")
const ARMORLESS_RECORDS_PANEL_SCENE := preload("res://scenes/armorless_records_panel.tscn")
const CODEX_PANEL_SCENE := preload("res://scenes/codex_panel.tscn")
const ACHIEVEMENTS_PANEL_SCENE := preload("res://scenes/achievements_panel.tscn")

@onready var _difficulty_list: VBoxContainer = $Content/Main/DifficultyCard/Body/DifficultyList
@onready var _difficulty_status: Label = $Content/Main/DifficultyCard/Body/DifficultyStatus
@onready var _armorless_record_status: Label = $Content/Main/DifficultyCard/Body/ArmorlessRecordStatus
@onready var _endless_record_status: Label = $Content/Main/DifficultyCard/Body/EndlessRecordStatus
@onready var _profile_status: Label = $Content/Header/ProfileStatus
@onready var _launch_button: Button = $Content/Main/PreparationCard/Body/LaunchButton
@onready var _intensity_toggle: CheckButton = $Content/Main/DifficultyCard/Body/IntensityToggle
@onready var _armorless_launch_button: Button = $Content/Main/PreparationCard/Body/ModeButtons/ArmorlessLaunchButton
@onready var _endless_launch_button: Button = $Content/Main/PreparationCard/Body/ModeButtons/EndlessLaunchButton
@onready var _temporary_launch_button: Button = $Content/Main/PreparationCard/Body/TemporaryLaunchButton
@onready var _equipment_button: Button = $Content/Main/PreparationCard/Body/EquipmentButton
@onready var _skill_tree_button: Button = $Content/Main/PreparationCard/Body/SkillTreeButton
@onready var _records_button: Button = $Content/Header/RecordsButton
@onready var _back_button: Button = $Content/Header/BackButton
@onready var _codex_button: Button = $Content/Main/PreparationCard/Body/InactiveFeatures/BestiaryButton
@onready var _achievements_button: Button = $Content/Main/PreparationCard/Body/InactiveFeatures/AchievementsButton

var progression_service: RefCounted
var selected_difficulty := "easy"
var _profile_available := false
var _highest_unlocked_difficulty := "easy"
var _armorless_records: Dictionary = {}
var _endless_records: Dictionary = {}
var _difficulty_buttons: Dictionary = {}
var _difficulty_group := ButtonGroup.new()
var _equipment_panel: Control
var _skill_tree_panel: Control
var _records_panel: Control
var _codex_panel: Control
var _achievements_panel: Control

func _ready() -> void:
	for button_and_path in [
		[$Content/Header/RecordsButton, "res://assets/icons/catalog/run_record.png"],
		[$Content/Main/PreparationCard/Body/EquipmentButton, "res://assets/icons/catalog/equipment_armor.png"],
		[$Content/Main/PreparationCard/Body/SkillTreeButton, "res://assets/icons/catalog/skill_node.png"],
		[$Content/Main/PreparationCard/Body/InactiveFeatures/AchievementsButton, "res://assets/icons/catalog/achievement_medal.png"],
		[$Content/Main/PreparationCard/Body/InactiveFeatures/BestiaryButton, "res://assets/sprites/roster/enemy_chaser.png"],
	]:
		button_and_path[0].icon = load(button_and_path[1]) as Texture2D if ResourceLoader.exists(button_and_path[1]) else null
	if progression_service == null:
		progression_service = PROGRESSION_SERVICE_SCRIPT.new(SAVE_SERVICE_SCRIPT.new(), "0")
	_back_button.pressed.connect(_on_back_pressed)
	_equipment_button.pressed.connect(_open_equipment)
	_skill_tree_button.pressed.connect(_open_skill_tree)
	_records_button.pressed.connect(_open_armorless_records)
	_codex_button.text = "CODEX"
	_codex_button.theme_type_variation = "InactiveButton"
	_codex_button.pressed.connect(_open_codex)
	_achievements_button.text = "SUCCÈS"
	_achievements_button.theme_type_variation = "InactiveButton"
	_achievements_button.pressed.connect(_open_achievements)
	_launch_button.pressed.connect(_launch_run)
	_armorless_launch_button.pressed.connect(_launch_armorless_run)
	_endless_launch_button.pressed.connect(_launch_endless_run)
	_temporary_launch_button.pressed.connect(_launch_temporary_run)
	_create_panels()
	_load_profile()
	_launch_button.grab_focus() if _profile_available else _back_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if (_equipment_panel != null and _equipment_panel.visible) or \
			(_skill_tree_panel != null and _skill_tree_panel.visible) or \
			(_records_panel != null and _records_panel.visible) or \
			(_codex_panel != null and _codex_panel.visible) or \
			(_achievements_panel != null and _achievements_panel.visible):
		return
	_on_back_pressed()
	if get_viewport() != null:
		get_viewport().set_input_as_handled()

func _create_panels() -> void:
	_equipment_panel = EQUIPMENT_PANEL_SCENE.instantiate()
	_equipment_panel.progression_service = progression_service
	_equipment_panel.close_requested.connect(_close_equipment)
	_equipment_panel.equipment_state_requested.connect(_set_equipment_state)
	_equipment_panel.enhancement_requested.connect(_enhance_equipment)
	_equipment_panel.unique_effect_requested.connect(_choose_unique_effect)
	_equipment_panel.unique_effect_reroll_requested.connect(_reroll_unique_effect)
	_equipment_panel.dismantle_requested.connect(_dismantle_equipment)
	_equipment_panel.sell_requested.connect(_sell_equipment)
	add_child(_equipment_panel)
	_records_panel = ARMORLESS_RECORDS_PANEL_SCENE.instantiate()
	_records_panel.close_requested.connect(_close_armorless_records)
	add_child(_records_panel)
	_skill_tree_panel = SKILL_TREE_PANEL_SCENE.instantiate()
	_skill_tree_panel.progression_service = progression_service
	_skill_tree_panel.close_requested.connect(_close_skill_tree)
	_skill_tree_panel.unlock_requested.connect(_unlock_skill_node)
	_skill_tree_panel.respec_requested.connect(_respec_skill_tree)
	add_child(_skill_tree_panel)
	_codex_panel = CODEX_PANEL_SCENE.instantiate()
	_codex_panel.close_requested.connect(_close_codex)
	add_child(_codex_panel)
	_achievements_panel = ACHIEVEMENTS_PANEL_SCENE.instantiate()
	_achievements_panel.close_requested.connect(_close_achievements)
	add_child(_achievements_panel)

func _load_profile() -> void:
	var result: Dictionary = progression_service.load_profile()
	_profile_available = bool(result.get("ok", false))
	_armorless_records = result.get("profile", {}).get("armorless_records", {}) if _profile_available else {}
	_endless_records = result.get("profile", {}).get("endless_standard_records", {}) if _profile_available else {}
	var endless_unlocked := _profile_available and bool(result["profile"].get("endless_standard_unlocked", false))
	_endless_launch_button.disabled = not endless_unlocked
	_endless_launch_button.text = "ENDLESS STANDARD  →" if endless_unlocked else "ENDLESS STANDARD  ·  VERROUILLÉ"
	_endless_launch_button.tooltip_text = "Débloqué après une victoire en Survival." if not endless_unlocked else \
		"Lance une nouvelle run Endless avec les armes et reliques au niveau 1."
	_launch_button.disabled = not _profile_available
	_armorless_launch_button.disabled = not _profile_available
	_temporary_launch_button.disabled = false
	_equipment_button.disabled = not _profile_available
	_skill_tree_button.disabled = not _profile_available
	_records_button.disabled = not _profile_available
	if not _profile_available:
		_profile_status.text = "PROFIL INDISPONIBLE — LANCEMENT BLOQUÉ"
		_profile_status.add_theme_color_override("font_color", Color("#FF75E3"))
		return
	_highest_unlocked_difficulty = str(result["profile"].get("highest_unlocked_difficulty", "easy"))
	_profile_status.text = "PROFIL PRÊT  •  DIFFICULTÉ MAX: %s" % _highest_unlocked_difficulty.to_upper()
	_build_difficulties()

func _build_difficulties() -> void:
	for child in _difficulty_list.get_children():
		_difficulty_list.remove_child(child)
		child.queue_free()
	_difficulty_buttons.clear()
	var highest_index := DIFFICULTY_SCRIPT.ORDER.find(_highest_unlocked_difficulty)
	for index in range(DIFFICULTY_SCRIPT.ORDER.size()):
		var difficulty_id: String = DIFFICULTY_SCRIPT.ORDER[index]
		var unlocked := index <= highest_index
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 23)
		button.add_theme_font_size_override("font_size", 8)
		button.focus_mode = Control.FOCUS_ALL
		button.toggle_mode = true
		button.button_group = _difficulty_group
		button.disabled = not unlocked
		button.text = "%s  ·  %s" % [difficulty_id.to_upper(), "DISPONIBLE" if unlocked else "VERROUILLÉE"]
		if not unlocked:
			button.tooltip_text = "Vaincre la difficulté %s pour déverrouiller celle-ci." % \
				DIFFICULTY_SCRIPT.ORDER[index - 1].to_upper()
		button.pressed.connect(func() -> void: _select_difficulty(difficulty_id))
		_difficulty_list.add_child(button)
		_difficulty_buttons[difficulty_id] = button
	_select_difficulty(selected_difficulty)

func _select_difficulty(difficulty_id: String) -> void:
	if not _profile_available or not _difficulty_buttons.has(difficulty_id):
		return
	var button: Button = _difficulty_buttons[difficulty_id]
	if button.disabled:
		return
	var changed := selected_difficulty != difficulty_id
	selected_difficulty = difficulty_id
	button.button_pressed = true
	for id in _difficulty_buttons:
		var difficulty_button: Button = _difficulty_buttons[id]
		difficulty_button.text = "%s  ·  %s%s" % [str(id).to_upper(), \
			"DISPONIBLE" if not difficulty_button.disabled else "VERROUILLÉE", "  ✓" if id == difficulty_id else ""]
	_launch_button.text = "LANCER LA RUN  ·  %s  →" % difficulty_id.to_upper()
	var index := DIFFICULTY_SCRIPT.ORDER.find(difficulty_id)
	_difficulty_status.text = "CHOISIE: %s  •  UNE VICTOIRE DÉBLOQUE LA SUIVANTE" % difficulty_id.to_upper() \
		if index < DIFFICULTY_SCRIPT.ORDER.size() - 1 else "CHOISIE: CHAOS  •  DIFFICULTÉ MAXIMALE"
	_refresh_armorless_record()
	_refresh_endless_record()
	if changed:
		Sfx.play("ui_confirm")

func _refresh_armorless_record() -> void:
	var record: Dictionary = _armorless_records.get(selected_difficulty, {})
	if record.is_empty() or int(record.get("wave", 0)) <= 0:
		_armorless_record_status.text = "ARMORLESS · NONE"
		return
	var seconds := int(floor(float(record.get("survival_time_seconds", 0.0))))
	_armorless_record_status.text = "ARMORLESS · WAVE %d · %02d:%02d · %d KILLS" % [
		int(record["wave"]), seconds / 60, seconds % 60, int(record["kills"]),
	]

func _refresh_endless_record() -> void:
	var record: Dictionary = _endless_records.get(selected_difficulty, {})
	if record.is_empty() or int(record.get("wave", 0)) <= 0:
		_endless_record_status.text = "ENDLESS PB  ·  NONE"
		return
	var seconds := int(floor(float(record.get("survival_time_seconds", 0.0))))
	_endless_record_status.text = "ENDLESS PB  ·  WAVE %d  ·  %02d:%02d  ·  %d KILLS" % [
		int(record["wave"]), seconds / 60, seconds % 60, int(record["kills"]),
	]

func _on_back_pressed() -> void:
	var error := await UITransitions.change_scene_to_file("res://scenes/launch_menu.tscn")
	if error != OK:
		_profile_status.text = "RETOUR À L’ACCUEIL IMPOSSIBLE"

func _launch_run() -> void:
	if not _profile_available:
		return
	var entry: Node = SURVIVAL_ENTRY_SCENE.instantiate()
	entry.progression_service = progression_service
	entry.difficulty_id = selected_difficulty
	entry.overstimulation_intensity_enabled = _intensity_toggle.button_pressed
	await _change_to_run_entry(entry)

func _launch_armorless_run() -> void:
	if not _profile_available:
		return
	var entry: Node = SURVIVAL_ENTRY_SCENE.instantiate()
	entry.progression_service = progression_service
	entry.difficulty_id = selected_difficulty
	entry.mode_id = "armorless"
	await _change_to_run_entry(entry)

func _launch_endless_run() -> void:
	if not _profile_available or _endless_launch_button.disabled:
		return
	var entry: Node = SURVIVAL_ENTRY_SCENE.instantiate()
	entry.progression_service = progression_service
	entry.difficulty_id = selected_difficulty
	entry.mode_id = "endless"
	entry.overstimulation_intensity_enabled = _intensity_toggle.button_pressed
	await _change_to_run_entry(entry)

func _launch_temporary_run() -> void:
	var temporary_progression = PROGRESSION_SERVICE_SCRIPT.new(null, "temporary")
	var entry: Node = SURVIVAL_ENTRY_SCENE.instantiate()
	entry.progression_service = temporary_progression
	entry.difficulty_id = "easy"
	await _change_to_run_entry(entry)

func _change_to_run_entry(entry: Node) -> void:
	var error: Error = await UITransitions.change_scene_to_node(entry)
	if error != OK:
		entry.queue_free()
		_profile_status.text = "LANCEMENT IMPOSSIBLE"
		push_error("Could not start the selected run: %s" % error_string(error))

func _open_equipment() -> void:
	var result: Dictionary = progression_service.load_profile()
	_equipment_panel.present(result["profile"]) if result.get("ok", false) else _equipment_panel.present_error()
	UITransitions.show_panel(_equipment_panel)

func _open_skill_tree() -> void:
	var result: Dictionary = progression_service.load_profile()
	_skill_tree_panel.present(result["profile"]) if result.get("ok", false) else _skill_tree_panel.present_error()
	UITransitions.show_panel(_skill_tree_panel)

func _open_armorless_records() -> void:
	_records_panel.present(_armorless_records)
	UITransitions.show_panel(_records_panel)

func _close_armorless_records() -> void:
	_records_button.grab_focus()
	await UITransitions.hide_panel(_records_panel)

func _close_equipment() -> void:
	_equipment_button.grab_focus()
	await UITransitions.hide_panel(_equipment_panel)

func _close_skill_tree() -> void:
	_skill_tree_button.grab_focus()
	await UITransitions.hide_panel(_skill_tree_panel)

func _open_codex() -> void:
	var result: Dictionary = progression_service.load_profile()
	if not result.get("ok", false):
		_codex_panel.present_error()
		UITransitions.show_panel(_codex_panel)
		return
	_codex_panel.present({
		"seen_enemies": result["profile"].get("codex_seen_enemies", []),
		"unlocked_weapons": progression_service.unlocked_weapon_ids(),
		"unlocked_relics": progression_service.unlocked_relic_ids(),
	})
	UITransitions.show_panel(_codex_panel)

func _close_codex() -> void:
	_codex_button.grab_focus()
	await UITransitions.hide_panel(_codex_panel)

func _open_achievements() -> void:
	var result: Dictionary = progression_service.load_profile()
	if not result.get("ok", false):
		_achievements_panel.present_error()
		UITransitions.show_panel(_achievements_panel)
		return
	_achievements_panel.present(progression_service.achievement_catalog(), result["profile"])
	UITransitions.show_panel(_achievements_panel)

func _close_achievements() -> void:
	_achievements_button.grab_focus()
	await UITransitions.hide_panel(_achievements_panel)

func _set_equipment_state(instance_id: String, equipped: bool) -> void:
	var result: Dictionary = progression_service.set_equipped(instance_id, equipped)
	_refresh_equipment(result)

func _enhance_equipment(instance_id: String, stat_id: String, powder_tier: String) -> void:
	var result: Dictionary = progression_service.enhance_equipment(instance_id, stat_id, powder_tier)
	_refresh_equipment(result)
	if result.get("ok", false):
		_equipment_panel.show_feedback("ENHANCEMENT SUCCESS" if result["success"] else \
			"CRITICAL FAILURE — LEVEL LOST" if result["critical_failure"] else "ENHANCEMENT FAILED")

func _choose_unique_effect(instance_id: String, effect_id: String) -> void:
	var result: Dictionary = progression_service.choose_unique_effect(instance_id, effect_id)
	_refresh_equipment(result)

func _reroll_unique_effect(instance_id: String, effect_id: String) -> void:
	var result: Dictionary = progression_service.reroll_unique_effect(instance_id, effect_id)
	_refresh_equipment(result)
	if result.get("ok", false):
		_equipment_panel.show_feedback("UNIQUE EFFECT REROLLED  •  %d %s POWDER" % [
			int(result["powder_spent"]), str(result["powder_tier"]).to_upper(),
		])

func _dismantle_equipment(instance_id: String) -> void:
	var result: Dictionary = progression_service.dismantle_equipment(instance_id)
	_refresh_equipment(result)

func _sell_equipment(instance_id: String) -> void:
	var result: Dictionary = progression_service.sell_equipment(instance_id)
	_refresh_equipment(result)
	if result.get("ok", false):
		_equipment_panel.show_feedback("SOLD  •  +%d ESSENCE" % int(result["essence_reward"]))

func _refresh_equipment(result: Dictionary) -> void:
	if result.get("ok", false):
		var previous_slot := str(_equipment_panel.selected_slot())
		_equipment_panel.present(result["profile"])
		_equipment_panel.set_selected_slot(previous_slot)
	else:
		_equipment_panel.show_feedback("ACTION FAILED: %s" % str(result.get("error", "unknown")))

func _unlock_skill_node(node_id: String) -> void:
	var result: Dictionary = progression_service.unlock_skill_node(node_id)
	_skill_tree_panel.present(result["profile"]) if result.get("ok", false) else _skill_tree_panel.present_error()

func _respec_skill_tree() -> void:
	var result: Dictionary = progression_service.respec_skill_tree()
	_skill_tree_panel.present(result["profile"]) if result.get("ok", false) else _skill_tree_panel.present_error()
