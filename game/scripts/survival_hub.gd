extends Control

const SAVE_SERVICE_SCRIPT := preload("res://scripts/save_service.gd")
const PROGRESSION_SERVICE_SCRIPT := preload("res://scripts/progression_service.gd")
const DIFFICULTY_SCRIPT := preload("res://scripts/survival_difficulty.gd")
const SURVIVAL_ENTRY_SCENE := preload("res://scenes/survival_entry.tscn")
const EQUIPMENT_PANEL_SCENE := preload("res://scenes/equipment_inventory_panel.tscn")
const SKILL_TREE_PANEL_SCENE := preload("res://scenes/skill_tree_panel.tscn")
const ARMORLESS_RECORDS_PANEL_SCENE := preload("res://scenes/armorless_records_panel.tscn")

@onready var _difficulty_list: VBoxContainer = $Content/Main/DifficultyCard/Body/DifficultyList
@onready var _difficulty_status: Label = $Content/Main/DifficultyCard/Body/DifficultyStatus
@onready var _armorless_record_status: Label = $Content/Main/DifficultyCard/Body/ArmorlessRecordStatus
@onready var _endless_record_status: Label = $Content/Main/DifficultyCard/Body/EndlessRecordStatus
@onready var _profile_status: Label = $Content/Header/ProfileStatus
@onready var _launch_button: Button = $Content/Main/PreparationCard/Body/LaunchButton
@onready var _armorless_launch_button: Button = $Content/Main/PreparationCard/Body/ModeButtons/ArmorlessLaunchButton
@onready var _endless_launch_button: Button = $Content/Main/PreparationCard/Body/ModeButtons/EndlessLaunchButton
@onready var _temporary_launch_button: Button = $Content/Main/PreparationCard/Body/TemporaryLaunchButton
@onready var _equipment_button: Button = $Content/Main/PreparationCard/Body/EquipmentButton
@onready var _skill_tree_button: Button = $Content/Main/PreparationCard/Body/SkillTreeButton
@onready var _records_button: Button = $Content/Header/RecordsButton
@onready var _back_button: Button = $Content/Header/BackButton

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

func _ready() -> void:
	if progression_service == null:
		progression_service = PROGRESSION_SERVICE_SCRIPT.new(SAVE_SERVICE_SCRIPT.new(), "0")
	_back_button.pressed.connect(_on_back_pressed)
	_equipment_button.pressed.connect(_open_equipment)
	_skill_tree_button.pressed.connect(_open_skill_tree)
	_records_button.pressed.connect(_open_armorless_records)
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
			(_records_panel != null and _records_panel.visible):
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
	selected_difficulty = difficulty_id
	button.button_pressed = true
	_launch_button.text = "LANCER LA RUN  ·  %s  →" % difficulty_id.to_upper()
	var index := DIFFICULTY_SCRIPT.ORDER.find(difficulty_id)
	_difficulty_status.text = "CHOISIE: %s  •  UNE VICTOIRE DÉBLOQUE LA SUIVANTE" % difficulty_id.to_upper() \
		if index < DIFFICULTY_SCRIPT.ORDER.size() - 1 else "CHOISIE: CHAOS  •  DIFFICULTÉ MAXIMALE"
	_refresh_armorless_record()
	_refresh_endless_record()

func _refresh_armorless_record() -> void:
	var record: Dictionary = _armorless_records.get(selected_difficulty, {})
	if record.is_empty() or int(record.get("wave", 0)) <= 0:
		_armorless_record_status.text = "ARMORLESS PB  ·  NONE"
		return
	var seconds := int(floor(float(record.get("survival_time_seconds", 0.0))))
	_armorless_record_status.text = "ARMORLESS PB  ·  WAVE %d  ·  %02d:%02d  ·  %d KILLS" % [
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
	var error := get_tree().change_scene_to_file("res://scenes/launch_menu.tscn")
	if error != OK:
		_profile_status.text = "RETOUR À L’ACCUEIL IMPOSSIBLE"

func _launch_run() -> void:
	if not _profile_available:
		return
	var entry: Node = SURVIVAL_ENTRY_SCENE.instantiate()
	entry.progression_service = progression_service
	entry.difficulty_id = selected_difficulty
	get_tree().root.add_child(entry)
	get_tree().current_scene = entry
	queue_free()

func _launch_armorless_run() -> void:
	if not _profile_available:
		return
	var entry: Node = SURVIVAL_ENTRY_SCENE.instantiate()
	entry.progression_service = progression_service
	entry.difficulty_id = selected_difficulty
	entry.mode_id = "armorless"
	get_tree().root.add_child(entry)
	get_tree().current_scene = entry
	queue_free()

func _launch_endless_run() -> void:
	if not _profile_available or _endless_launch_button.disabled:
		return
	var entry: Node = SURVIVAL_ENTRY_SCENE.instantiate()
	entry.progression_service = progression_service
	entry.difficulty_id = selected_difficulty
	entry.mode_id = "endless"
	get_tree().root.add_child(entry)
	get_tree().current_scene = entry
	queue_free()

func _launch_temporary_run() -> void:
	var temporary_progression = PROGRESSION_SERVICE_SCRIPT.new(null, "temporary")
	var entry: Node = SURVIVAL_ENTRY_SCENE.instantiate()
	entry.progression_service = temporary_progression
	entry.difficulty_id = "easy"
	get_tree().root.add_child(entry)
	get_tree().current_scene = entry
	queue_free()

func _open_equipment() -> void:
	var result: Dictionary = progression_service.load_profile()
	_equipment_panel.present(result["profile"]) if result.get("ok", false) else _equipment_panel.present_error()

func _open_skill_tree() -> void:
	var result: Dictionary = progression_service.load_profile()
	_skill_tree_panel.present(result["profile"]) if result.get("ok", false) else _skill_tree_panel.present_error()

func _open_armorless_records() -> void:
	_records_panel.present(_armorless_records)

func _close_armorless_records() -> void:
	_records_panel.visible = false
	_records_button.grab_focus()

func _close_equipment() -> void:
	_equipment_panel.visible = false
	_equipment_button.grab_focus()

func _close_skill_tree() -> void:
	_skill_tree_panel.visible = false
	_skill_tree_button.grab_focus()

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
		_equipment_panel.present(result["profile"])
	else:
		_equipment_panel.show_feedback("ACTION FAILED: %s" % str(result.get("error", "unknown")))

func _unlock_skill_node(node_id: String) -> void:
	var result: Dictionary = progression_service.unlock_skill_node(node_id)
	_skill_tree_panel.present(result["profile"]) if result.get("ok", false) else _skill_tree_panel.present_error()

func _respec_skill_tree() -> void:
	var result: Dictionary = progression_service.respec_skill_tree()
	_skill_tree_panel.present(result["profile"]) if result.get("ok", false) else _skill_tree_panel.present_error()
