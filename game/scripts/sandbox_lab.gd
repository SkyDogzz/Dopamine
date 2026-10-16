extends Control

const PRESET_SERVICE_SCRIPT := preload("res://scripts/sandbox_preset_service.gd")
const PRESET_STORE_SCRIPT := preload("res://scripts/sandbox_preset_store.gd")
const LAB_CONTEXT_SCRIPT := preload("res://scripts/sandbox_lab_context.gd")

@onready var _view: Control = $Root/Body/Left/SimulationView
@onready var _status: Label = $Root/Body/Side/Sections/Status
@onready var _preset_id: LineEdit = $Root/Body/Side/Sections/PresetId
@onready var _build_json: TextEdit = $Root/Body/Side/Sections/BuildJson
@onready var _share_code: LineEdit = $Root/Body/Side/Sections/ShareCode
@onready var _enemy_select: OptionButton = $Root/Body/Side/Sections/EnemySelect
@onready var _metrics: Label = $Root/Body/Side/Sections/Metrics
@onready var _pause_button: Button = $Root/Body/Left/Controls/PauseButton
@onready var _speed_select: OptionButton = $Root/Body/Left/Controls/SpeedSelect

var preset_service: RefCounted
var preset_store: RefCounted
var context: RefCounted
var _elapsed := 0.0

func _ready() -> void:
	preset_service = PRESET_SERVICE_SCRIPT.new()
	preset_store = PRESET_STORE_SCRIPT.new("user://sandbox/presets", preset_service)
	context = LAB_CONTEXT_SCRIPT.new(preset_service)
	$Root/Header/HomeButton.pressed.connect(_go_home)
	_pause_button.pressed.connect(_toggle_pause)
	$Root/Body/Left/Controls/SpawnButton.pressed.connect(_spawn_enemies)
	$Root/Body/Left/Controls/KillButton.pressed.connect(_kill_all)
	$Root/Body/Left/Controls/ResetButton.pressed.connect(_reset)
	_speed_select.item_selected.connect(_set_speed)
	$Root/Body/Side/Sections/PresetActions/SavePreset.pressed.connect(_save_preset)
	$Root/Body/Side/Sections/PresetActions/LoadPreset.pressed.connect(_load_preset)
	$Root/Body/Side/Sections/PresetActions/ExportCode.pressed.connect(_copy_share_code)
	$Root/Body/Side/Sections/PresetActions/ImportCode.pressed.connect(_import_share_code)
	for enemy_id in ["chaser", "sprinter", "tank", "shooter", "buffer", "exploder", "shielder", "summoner", "elite"]:
		_enemy_select.add_item(enemy_id.to_upper())
		_enemy_select.set_item_metadata(_enemy_select.item_count - 1, enemy_id)
	for speed in [0.25, 0.5, 1.0, 2.0, 4.0]:
		_speed_select.add_item("×%s" % speed)
		_speed_select.set_item_metadata(_speed_select.item_count - 1, speed)
	_speed_select.select(2)
	_build_json.text = JSON.stringify({"weapons": [], "relics": [], "equipment": [], "stats": {}}, "  ")
	var started: Dictionary = context.start(_default_preset())
	if not started.get("ok", false):
		_set_status("LAB INIT FAILED: %s" % str(started.get("error", "unknown")), true)
		return
	_pause_button.grab_focus()
	_refresh()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < 0.1 or context.simulation == null:
		return
	_elapsed = 0.0
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_home()
		get_viewport().set_input_as_handled()

func _default_preset() -> Dictionary:
	return {
		"schema_version": 1, "preset_id": "lab_default", "name": "Lab Default",
		"description": "Empty isolated combat lab", "base_mode": "survival", "seed": 1,
		"overrides": {}, "flags": {},
		"initial_build": {"weapons": [], "relics": [], "equipment": [], "stats": {}},
	}

func _toggle_pause() -> void:
	var state: Dictionary = context.simulation.snapshot()
	context.simulation.resume() if state["paused"] else context.simulation.pause()
	_refresh()

func _spawn_enemies() -> void:
	var enemy_id := str(_enemy_select.get_item_metadata(_enemy_select.selected))
	var sequence: int = context.simulation.spawn_enemy(enemy_id, 10, Vector2.ZERO, Vector2.ZERO)
	_set_status("SPAWN QUEUED" if sequence > 0 else "SPAWN REJECTED", sequence <= 0)

func _kill_all() -> void:
	var sequence: int = context.simulation.kill_all()
	_set_status("KILL ALL QUEUED" if sequence > 0 else "COMMAND REJECTED", sequence <= 0)

func _reset() -> void:
	var sequence: int = context.simulation.reset()
	_set_status("RESET QUEUED" if sequence > 0 else "RESET REJECTED", sequence <= 0)

func _set_speed(index: int) -> void:
	var speed := float(_speed_select.get_item_metadata(index))
	var sequence: int = context.simulation.set_speed(speed)
	_set_status("SPEED ×%s" % speed if sequence > 0 else "SPEED REJECTED", sequence <= 0)

func _save_preset() -> void:
	var data := _preset_from_editor()
	if data.is_empty():
		return
	var result: Dictionary = preset_store.save_preset(data)
	_set_status("PRESET SAVED: %s" % str(data["preset_id"]) if result.get("ok", false) else \
		"SAVE REJECTED: %s" % str(result.get("error", "invalid")), not result.get("ok", false))

func _load_preset() -> void:
	var result: Dictionary = preset_store.load_preset(_preset_id.text.strip_edges())
	if not result.get("ok", false):
		_set_status("LOAD FAILED: %s" % str(result.get("error", "unknown")), true)
		return
	_apply_preset(result["preset"])

func _copy_share_code() -> void:
	var data := _preset_from_editor()
	if data.is_empty():
		return
	var result: Dictionary = preset_service.encode_share_code(data)
	if not result.get("ok", false):
		_set_status("EXPORT FAILED: %s" % str(result.get("error", "invalid")), true)
		return
	DisplayServer.clipboard_set(str(result["code"]))
	_share_code.text = str(result["code"])
	_set_status("SHARE CODE COPIED TO CLIPBOARD", false)

func _import_share_code() -> void:
	var result: Dictionary = preset_service.decode_share_code(_share_code.text.strip_edges())
	if not result.get("ok", false):
		_set_status("IMPORT FAILED: %s" % str(result.get("error", "invalid")), true)
		return
	_apply_preset(result["preset"])

func _preset_from_editor() -> Dictionary:
	var parser := JSON.new()
	if parser.parse(_build_json.text) != OK or not parser.data is Dictionary:
		_set_status("BUILD JSON INVALID", true)
		return {}
	var preset := _default_preset()
	preset["preset_id"] = _preset_id.text.strip_edges()
	preset["name"] = _preset_id.text.strip_edges()
	preset["initial_build"] = parser.data
	var checked: Dictionary = preset_service.validate_preset(preset)
	var build = load("res://scripts/sandbox_build.gd").new()
	var build_result: Dictionary = build.load_build(parser.data)
	if not checked.get("ok", false) or not build_result.get("ok", false):
		_set_status("BUILD/PRESET REJECTED", true)
		return {}
	return checked["preset"]

func _apply_preset(preset: Dictionary) -> void:
	var result: Dictionary = await context.apply_preset(preset)
	if not result.get("ok", false):
		_set_status("APPLY FAILED: %s" % str(result.get("error", "unknown")), true)
		return
	_preset_id.text = str(preset["preset_id"])
	_build_json.text = JSON.stringify(preset["initial_build"], "  ")
	_set_status("PRESET APPLIED · BUILD STORED, COMBAT ROUTING INCOMPLETE", false)

func _refresh() -> void:
	var state: Dictionary = context.simulation.snapshot()
	_view.set_entities(state["entities"])
	_pause_button.text = "RESUME" if state["paused"] else "PAUSE"
	var metrics: Dictionary = state["metrics"]
	_metrics.text = "ENTITIES %d  ·  PROJECTILES %d\nSIM %.2f s  ·  FPS %d" % [
		int(metrics["entity_count"]), int(metrics["projectile_count"]),
		float(state["simulation_time"]), Engine.get_frames_per_second(),
	]

func _set_status(message: String, error: bool) -> void:
	_status.text = message
	_status.add_theme_color_override("font_color", Color("#ff7181") if error else Color("#ffd447"))

func _go_home() -> void:
	context.stop()
	var error := get_tree().change_scene_to_file("res://scenes/launch_menu.tscn")
	if error != OK:
		push_error("Could not return from Sandbox Lab: %s" % error_string(error))
