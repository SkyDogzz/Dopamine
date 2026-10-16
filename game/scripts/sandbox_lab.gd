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
@onready var _wave_spin: SpinBox = $Root/Body/Left/WaveControls/WaveSpin

var preset_service: RefCounted
var preset_store: RefCounted
var context: Node
var _elapsed := 0.0

func _ready() -> void:
	preset_service = PRESET_SERVICE_SCRIPT.new()
	preset_store = PRESET_STORE_SCRIPT.new("user://sandbox/presets", preset_service)
	context = LAB_CONTEXT_SCRIPT.new(preset_service)
	add_child(context)
	$Root/Header/HomeButton.pressed.connect(_go_home)
	_pause_button.pressed.connect(_toggle_pause)
	$Root/Body/Left/Controls/SpawnButton.pressed.connect(_spawn_enemies)
	$Root/Body/Left/Controls/KillButton.pressed.connect(_kill_all)
	$Root/Body/Left/Controls/ResetButton.pressed.connect(_reset)
	$Root/Body/Left/ProjectileControls/ClearProjectilesButton.pressed.connect(_clear_projectiles)
	$Root/Body/Left/ProjectileControls/ResetCooldownsButton.pressed.connect(_reset_cooldowns)
	$Root/Body/Left/WaveControls/JumpWaveButton.pressed.connect(_jump_to_selected_wave)
	_speed_select.item_selected.connect(_set_speed)
	$Root/Body/Side/Sections/PresetActions/SavePreset.pressed.connect(_save_preset)
	$Root/Body/Side/Sections/PresetActions/LoadPreset.pressed.connect(_load_preset)
	$Root/Body/Side/Sections/PresetActions/ExportCode.pressed.connect(_copy_share_code)
	$Root/Body/Side/Sections/PresetActions/ImportCode.pressed.connect(_import_share_code)
	$Root/Body/Side/Sections/PresetFileActions/ImportFile.pressed.connect(_open_preset_file)
	$Root/Body/Side/Sections/PresetFileActions/ExportFile.pressed.connect(_save_preset_file)
	$PresetFileDialog.file_selected.connect(_on_preset_file_selected)
	$Root/Body/Side/Sections/GodModeToggle.toggled.connect(_set_god_mode)
	for enemy_id in ["chaser", "sprinter", "tank", "shooter", "buffer", "exploder", "shielder", "summoner", "elite"]:
		_enemy_select.add_item(enemy_id.to_upper())
		_enemy_select.set_item_metadata(_enemy_select.item_count - 1, enemy_id)
	for speed in [0.25, 0.5, 1.0, 2.0, 4.0]:
		_speed_select.add_item("×%s" % speed)
		_speed_select.set_item_metadata(_speed_select.item_count - 1, speed)
	_speed_select.select(2)
	_build_json.text = JSON.stringify(_default_preset()["initial_build"], "  ")
	var started: Dictionary = await context.start(_default_preset())
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
		"initial_build": {
			"weapons": [{"id": "lightning_conductor", "level": 1}],
			"relics": [{"id": "storm_core", "level": 1}], "equipment": [], "stats": {},
		},
	}

func _toggle_pause() -> void:
	var state: Dictionary = context.simulation.snapshot()
	context.simulation.resume() if state["paused"] else context.simulation.pause()
	_refresh()

func _spawn_enemies() -> void:
	var enemy_id := str(_enemy_select.get_item_metadata(_enemy_select.selected))
	var sequence: int = context.simulation.spawn_enemy(enemy_id, 10, Vector2(120.0, 0.0), Vector2.ZERO)
	_set_status("SPAWN QUEUED" if sequence > 0 else "SPAWN REJECTED", sequence <= 0)

func _kill_all() -> void:
	var sequence: int = context.simulation.kill_all()
	_set_status("KILL ALL QUEUED" if sequence > 0 else "COMMAND REJECTED", sequence <= 0)

func _clear_projectiles() -> void:
	var state: Dictionary = context.simulation.snapshot()
	var queued := 0
	for entity in state["entities"]:
		var components: Dictionary = entity["components"]
		if not bool(components.get("IsProjectile", false)):
			continue
		var id: Dictionary = entity["id"]
		if context.simulation.despawn(int(id["index"]), int(id["generation"])) > 0:
			queued += 1
	_set_status("CLEAR %d PROJECTILES QUEUED" % queued if queued > 0 else "NO PROJECTILES", false)

func _reset_cooldowns() -> void:
	for field in ["_next_weapon_time", "_next_inferno_time", "_next_daggers_time", "_next_minigun_time",
			"_next_toxic_time", "_next_sawblades_time", "_next_meteor_time", "_next_prism_time",
			"_next_void_orb_time", "_next_frost_nova_time"]:
		context.session.set(field, 0.0)
	_set_status("WEAPON COOLDOWNS RESET", false)

func _jump_to_selected_wave() -> void:
	_jump_to_wave(int(_wave_spin.value))

func _jump_to_wave(wave_number: int) -> void:
	if wave_number < 1 or wave_number > 999:
		_set_status("WAVE MUST BE BETWEEN 1 AND 999", true)
		return
	var director = context.session.wave_director
	if director == null:
		_set_status("WAVE DIRECTOR UNAVAILABLE", true)
		return
	director.wave = wave_number
	director.elapsed_in_wave = 0.0
	director.state = context.session.WAVE_DIRECTOR_SCRIPT.State.WAVE
	context.session._boss_spawn_pending = false
	_set_status("JUMPED TO WAVE %02d" % wave_number, false)

func _reset() -> void:
	var active_preset: Dictionary = context.active_preset.duplicate(true)
	if active_preset.is_empty():
		_set_status("NO ACTIVE PRESET", true)
		return
	var state: Dictionary = context.simulation.snapshot()
	if not bool(state["paused"]):
		context.simulation.pause()
		var deadline := Time.get_ticks_msec() + 1000
		while not bool(context.simulation.snapshot()["paused"]) and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
	var result: Dictionary = await context.apply_preset(active_preset)
	_set_status("LAB RESET FROM PRESET" if result.get("ok", false) else \
		"RESET FAILED: %s" % str(result.get("error", "unknown")), not result.get("ok", false))

func _set_speed(index: int) -> void:
	var speed := float(_speed_select.get_item_metadata(index))
	var sequence: int = context.simulation.set_speed(speed)
	_set_status("SPEED ×%s" % speed if sequence > 0 else "SPEED REJECTED", sequence <= 0)

func _set_god_mode(enabled: bool) -> void:
	context.god_mode_enabled = enabled
	if context.session != null:
		context.session._health_locked = enabled
	_set_status("GOD MODE ON" if enabled else "GOD MODE OFF", false)

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
	await _apply_preset(result["preset"])

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
	await _apply_preset(result["preset"])

func _open_preset_file() -> void:
	$PresetFileDialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	$PresetFileDialog.title = "Open Sandbox preset"
	$PresetFileDialog.popup_centered_ratio(0.8)

func _on_preset_file_selected(path: String) -> void:
	if $PresetFileDialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		_export_preset_file(path)
	else:
		await _import_preset_file(path)

func _import_preset_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_set_status("IMPORT FAILED: FILE UNAVAILABLE", true)
		return
	if file.get_length() > preset_service.MAX_JSON_BYTES:
		file.close()
		_set_status("IMPORT FAILED: FILE TOO LARGE", true)
		return
	var result: Dictionary = preset_service.import_json(file.get_as_text())
	file.close()
	if not result.get("ok", false):
		_set_status("IMPORT FAILED: %s" % str(result.get("error", "invalid")), true)
		return
	var build = load("res://scripts/sandbox_build.gd").new()
	if not build.load_build(result["preset"]["initial_build"]).get("ok", false):
		_set_status("IMPORT FAILED: INVALID BUILD", true)
		return
	await _apply_preset(result["preset"])

func _save_preset_file() -> void:
	var preset := _preset_from_editor()
	if preset.is_empty():
		return
	$PresetFileDialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	$PresetFileDialog.title = "Save Sandbox preset"
	$PresetFileDialog.current_file = "%s.json" % str(preset["preset_id"])
	$PresetFileDialog.popup_centered_ratio(0.8)

func _export_preset_file(path: String) -> void:
	var preset := _preset_from_editor()
	if preset.is_empty():
		return
	var result: Dictionary = preset_service.export_json(preset)
	if not result.get("ok", false):
		_set_status("EXPORT FAILED: %s" % str(result.get("error", "invalid")), true)
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_set_status("EXPORT FAILED: FILE UNAVAILABLE", true)
		return
	file.store_string(str(result["json"]))
	file.flush()
	var write_ok := file.get_error() == OK
	file.close()
	_set_status("PRESET EXPORTED: %s" % path if write_ok else "EXPORT FAILED: WRITE ERROR", not write_ok)

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
	if context.simulation != null and not bool(context.simulation.snapshot()["paused"]):
		context.simulation.pause()
		var deadline := Time.get_ticks_msec() + 1000
		while not bool(context.simulation.snapshot()["paused"]) and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
	var result: Dictionary = await context.apply_preset(preset)
	if not result.get("ok", false):
		_set_status("APPLY FAILED: %s" % str(result.get("error", "unknown")), true)
		return
	_preset_id.text = str(preset["preset_id"])
	_build_json.text = JSON.stringify(preset["initial_build"], "  ")
	_set_status("PRESET APPLIED TO COMBAT", false)

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
