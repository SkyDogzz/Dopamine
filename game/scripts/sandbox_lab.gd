extends Control

const PRESET_SERVICE_SCRIPT := preload("res://scripts/sandbox_preset_service.gd")
const PRESET_STORE_SCRIPT := preload("res://scripts/sandbox_preset_store.gd")
const LAB_CONTEXT_SCRIPT := preload("res://scripts/sandbox_lab_context.gd")
const COMBAT_CATALOG_SCRIPT := preload("res://scripts/combat_catalog.gd")
const EQUIPMENT_GENERATOR_SCRIPT := preload("res://scripts/equipment_generator.gd")
const SAVE_SERVICE_SCRIPT := preload("res://scripts/save_service.gd")
const PROGRESSION_SCRIPT := preload("res://scripts/progression_service.gd")
const MAX_DPS_SAMPLES := 4096
const MAX_SIMULATION_ENTITIES := 2500
const SPAWN_BATCH_SIZE := 10

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
@onready var _dps_summary: Label = $Root/Body/Side/Sections/Diagnostics/DpsSummary
@onready var _dps_sources: Label = $Root/Body/Side/Sections/Diagnostics/DpsSources
@onready var _rng_log_label: Label = $Root/Body/Side/Sections/Diagnostics/RngLog
@onready var _weapon_select: OptionButton = $Root/Body/Side/Sections/VisualBuild/WeaponRow/WeaponSelect
@onready var _weapon_level: SpinBox = $Root/Body/Side/Sections/VisualBuild/WeaponRow/WeaponLevel
@onready var _relic_select: OptionButton = $Root/Body/Side/Sections/VisualBuild/RelicRow/RelicSelect
@onready var _relic_level: SpinBox = $Root/Body/Side/Sections/VisualBuild/RelicRow/RelicLevel
@onready var _stat_select: OptionButton = $Root/Body/Side/Sections/VisualBuild/StatRow/StatSelect
@onready var _stat_value: SpinBox = $Root/Body/Side/Sections/VisualBuild/StatRow/StatValue
@onready var _equipment_slot: OptionButton = $Root/Body/Side/Sections/VisualBuild/EquipmentRow/EquipmentSlot
@onready var _equipment_stat: OptionButton = $Root/Body/Side/Sections/VisualBuild/EquipmentRow/EquipmentStat
@onready var _equipment_value: SpinBox = $Root/Body/Side/Sections/VisualBuild/EquipmentRow/EquipmentValue
@onready var _live_stat_select: OptionButton = $Root/Body/Side/Sections/LiveOverride/StatSelect
@onready var _live_stat_value: SpinBox = $Root/Body/Side/Sections/LiveOverride/StatValue
@onready var _enemy_hp_multiplier: SpinBox = $Root/Body/Side/Sections/EnemyConfig/EnemyHpMultiplier
@onready var _contact_damage: SpinBox = $Root/Body/Side/Sections/EnemyConfig/ContactDamage
@onready var _seed_control: SpinBox = $Root/Body/Side/Sections/EnemyConfig/Seed
@onready var _capture_snapshot_button: Button = $Root/Body/Left/SnapshotControls/CaptureButton
@onready var _restore_snapshot_button: Button = $Root/Body/Left/SnapshotControls/RestoreButton
@onready var _restore_hp_button: Button = $Root/Body/Left/Controls/RestoreHpButton

var preset_service: RefCounted
var preset_store: RefCounted
var context: Node
var _elapsed := 0.0
var _diagnostic_session_id := 0
var _damage_totals: Dictionary = {}
var _dps_samples: Array[Dictionary] = []

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
	_capture_snapshot_button.pressed.connect(_capture_snapshot)
	_restore_snapshot_button.pressed.connect(_restore_snapshot)
	_restore_hp_button.pressed.connect(_restore_player_hp)
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
	$Root/Body/Side/Sections/VisualBuild/AddWeaponButton.pressed.connect(_add_visual_weapon)
	$Root/Body/Side/Sections/VisualBuild/AddRelicButton.pressed.connect(_add_visual_relic)
	$Root/Body/Side/Sections/VisualBuild/AddStatButton.pressed.connect(_add_visual_stat)
	$Root/Body/Side/Sections/VisualBuild/AddEquipmentButton.pressed.connect(_add_visual_equipment)
	$Root/Body/Side/Sections/VisualBuild/ApplyBuildButton.pressed.connect(_apply_visual_build)
	$Root/Body/Side/Sections/VisualBuild/ImportProfileButton.pressed.connect(_import_normal_profile)
	$Root/Body/Side/Sections/LiveOverride/ApplyStat.pressed.connect(_apply_live_stat_override)
	_enemy_hp_multiplier.value_changed.connect(_set_enemy_hp_override)
	_contact_damage.value_changed.connect(_set_contact_damage_override)
	_seed_control.value_changed.connect(_set_seed_override)
	_populate_visual_build_options()
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
	_enemy_hp_multiplier.value = float(context.active_preset["overrides"].get("enemy_hp", 1.0))
	_contact_damage.value = float(context.active_preset["overrides"].get("contact_damage_per_hit", 0.0))
	_seed_control.value = float(context.active_preset["seed"])
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

func _populate_visual_build_options() -> void:
	var catalog = COMBAT_CATALOG_SCRIPT.new()
	for weapon_id in catalog.weapons:
		_weapon_select.add_item(str(catalog.weapons[weapon_id]["name"]))
		_weapon_select.set_item_metadata(_weapon_select.item_count - 1, weapon_id)
	for relic_id in catalog.relics:
		_relic_select.add_item(str(catalog.relics[relic_id]["name"]))
		_relic_select.set_item_metadata(_relic_select.item_count - 1, relic_id)
	for stat_id in EQUIPMENT_GENERATOR_SCRIPT.STAT_IDS:
		_stat_select.add_item(str(stat_id).replace("_", " ").to_upper())
		_stat_select.set_item_metadata(_stat_select.item_count - 1, stat_id)
		_equipment_stat.add_item(str(stat_id).replace("_", " ").to_upper())
		_equipment_stat.set_item_metadata(_equipment_stat.item_count - 1, stat_id)
		_live_stat_select.add_item(str(stat_id).replace("_", " ").to_upper())
		_live_stat_select.set_item_metadata(_live_stat_select.item_count - 1, stat_id)
	for slot in EQUIPMENT_GENERATOR_SCRIPT.SLOTS:
		_equipment_slot.add_item(str(slot).to_upper())
		_equipment_slot.set_item_metadata(_equipment_slot.item_count - 1, slot)
	_weapon_select.select(_option_index_for_id(_weapon_select, "lightning_conductor"))
	_relic_select.select(_option_index_for_id(_relic_select, "storm_core"))
	_equipment_slot.select(0)
	_equipment_stat.select(_option_index_for_id(_equipment_stat, "damage_pct"))

func _option_index_for_id(option: OptionButton, item_id: String) -> int:
	for index in range(option.item_count):
		if str(option.get_item_metadata(index)) == item_id:
			return index
	return 0

func _add_visual_weapon() -> void:
	_add_visual_item("weapons", _weapon_select, _weapon_level)

func _add_visual_relic() -> void:
	_add_visual_item("relics", _relic_select, _relic_level)

func _add_visual_item(family: String, option: OptionButton, level: SpinBox) -> void:
	var item_id := str(option.get_item_metadata(option.selected))
	if item_id.is_empty():
		_set_status("BUILD ITEM UNAVAILABLE", true)
		return
	var build_data := _read_visual_build()
	if build_data.is_empty():
		return
	var entries: Array = build_data[family]
	var updated := false
	for entry in entries:
		if str(entry.get("id", "")) != item_id:
			continue
		entry["level"] = int(level.value)
		if family == "weapons" and int(level.value) < 5:
			entry.erase("evolution_id")
		updated = true
		break
	if not updated:
		entries.append({"id": item_id, "level": int(level.value)})
	_write_visual_build(build_data)

func _add_visual_stat() -> void:
	var stat_id := str(_stat_select.get_item_metadata(_stat_select.selected))
	if stat_id.is_empty():
		_set_status("BUILD STAT UNAVAILABLE", true)
		return
	var build_data := _read_visual_build()
	if build_data.is_empty():
		return
	build_data["stats"][stat_id] = _stat_value.value
	_write_visual_build(build_data)

func _add_visual_equipment() -> void:
	var slot := str(_equipment_slot.get_item_metadata(_equipment_slot.selected))
	var stat_id := str(_equipment_stat.get_item_metadata(_equipment_stat.selected))
	if slot.is_empty() or stat_id.is_empty():
		_set_status("BUILD EQUIPMENT UNAVAILABLE", true)
		return
	var build_data := _read_visual_build()
	if build_data.is_empty():
		return
	var equipment_id := "lab_%s" % slot
	var equipment: Dictionary = {}
	for item in build_data["equipment"]:
		if str(item.get("slot", "")) == slot:
			equipment = item
			equipment_id = str(item.get("id", equipment_id))
			break
	if equipment.is_empty():
		equipment = {"id": equipment_id, "slot": slot, "stats": {}}
		build_data["equipment"].append(equipment)
	equipment["stats"] = {stat_id: _equipment_value.value}
	_write_visual_build(build_data)

func _apply_live_stat_override() -> void:
	if context.session == null:
		_set_status("LIVE OVERRIDE UNAVAILABLE", true)
		return
	var stat_id := str(_live_stat_select.get_item_metadata(_live_stat_select.selected))
	if stat_id.is_empty():
		_set_status("LIVE STAT UNAVAILABLE", true)
		return
	var new_value: float = _live_stat_value.value
	var session = context.session
	var previous_value := float(context.live_stat_overrides.get(stat_id, 0.0))
	var base_bonus := float(session._cached_equipment_bonuses.get(stat_id, 0.0)) - previous_value
	var total_bonus := base_bonus + new_value
	session._cached_equipment_bonuses[stat_id] = total_bonus
	context.live_stat_overrides[stat_id] = new_value
	match stat_id:
		"damage_pct":
			session._cached_persistent_damage_multiplier = maxf(0.0, 1.0 + total_bonus / 100.0)
		"move_speed_pct": session._refresh_player_move_speed()
		"max_hp":
			var max_hp_delta := new_value - previous_value
			session.player_max_hp = maxf(1.0, session.player_max_hp + max_hp_delta)
			session.player_hp = minf(session.player_hp, session.player_max_hp)
	session._run_stat_hub_dirty = true
	_set_status("LIVE %s %+0.1f" % [stat_id.to_upper(), new_value], false)

func _read_visual_build() -> Dictionary:
	var parser := JSON.new()
	if parser.parse(_build_json.text) != OK or not parser.data is Dictionary:
		_set_status("BUILD JSON INVALID", true)
		return {}
	var build = load("res://scripts/sandbox_build.gd").new()
	var result: Dictionary = build.load_build(parser.data)
	if not result.get("ok", false):
		_set_status("BUILD REJECTED", true)
		return {}
	return build.to_dictionary()

func _write_visual_build(build_data: Dictionary) -> void:
	var build = load("res://scripts/sandbox_build.gd").new()
	var result: Dictionary = build.load_build(build_data)
	if not result.get("ok", false):
		_set_status("BUILD REJECTED", true)
		return
	_build_json.text = JSON.stringify(build.to_dictionary(), "  ")
	_set_status("BUILD EDITED · APPLY WHILE PAUSED", false)

func _apply_visual_build() -> void:
	var preset := _preset_from_editor()
	if preset.is_empty():
		return
	await _apply_preset(preset)

func _import_normal_profile() -> void:
	var save_service = SAVE_SERVICE_SCRIPT.new()
	var loaded: Dictionary = save_service.read_slot_read_only("0")
	if not loaded.get("ok", false):
		_set_status("PROFILE IMPORT FAILED: %s" % str(loaded.get("error", "unavailable")).to_upper(), true)
		return
	var profile: Variant = loaded.get("payload", {})
	var progression = PROGRESSION_SCRIPT.new(null, "0")
	if not profile is Dictionary or not progression._valid_profile(profile):
		_set_status("PROFILE IMPORT FAILED: INVALID / LEGACY PROFILE", true)
		return
	var build = load("res://scripts/sandbox_build.gd").new()
	var result: Dictionary = build.load_profile_copy(profile)
	if not result.get("ok", false):
		_set_status("PROFILE IMPORT FAILED: %s" % str(result.get("error", "invalid")).to_upper(), true)
		return
	_build_json.text = JSON.stringify(build.to_dictionary(), "  ")
	_set_status("PROFILE COPIED · SANDBOX BUILD ONLY", false)

func _toggle_pause() -> void:
	var state: Dictionary = context.simulation.snapshot()
	context.simulation.resume() if state["paused"] else context.simulation.pause()
	_refresh()

func _restore_player_hp() -> void:
	if context.session == null or context.session.run_over:
		_set_status("RESET REQUIRED TO RESTORE HP", true)
		return
	context.session.player_hp = context.session.player_max_hp
	context.session._refresh_hud(context.simulation.snapshot())
	_set_status("PLAYER HP RESTORED", false)

func _spawn_enemies() -> void:
	var current_count := int(context.simulation.snapshot()["metrics"]["entity_count"])
	if not _can_spawn_batch(current_count):
		_set_status("ENTITY LIMIT %d · REMOVE ENTITIES BEFORE SPAWNING" % MAX_SIMULATION_ENTITIES, true)
		return
	var enemy_id := str(_enemy_select.get_item_metadata(_enemy_select.selected))
	var sequence: int = context.simulation.spawn_enemy(enemy_id, SPAWN_BATCH_SIZE,
		Vector2(120.0, 0.0), Vector2.ZERO, float(_enemy_hp_multiplier.value))
	_set_status("SPAWN QUEUED" if sequence > 0 else "SPAWN REJECTED", sequence <= 0)

func _set_enemy_hp_override(value: float) -> void:
	if context == null or context.active_preset.is_empty():
		return
	context.active_preset["overrides"]["enemy_hp"] = value

func _set_contact_damage_override(value: float) -> void:
	if context == null or context.active_preset.is_empty():
		return
	context.active_preset["overrides"]["contact_damage_per_hit"] = value
	if context.session != null:
		context.session.contact_damage_per_hit = value

func _set_seed_override(value: float) -> void:
	if context == null or context.active_preset.is_empty():
		return
	context.active_preset["seed"] = int(value)
	var seed_needs_restart: bool = int(value) != context.seed
	if seed_needs_restart:
		context.latest_snapshot.clear()
		_restore_snapshot_button.disabled = true
	var paused := context.simulation != null and bool(context.simulation.snapshot().get("paused", false))
	_capture_snapshot_button.disabled = seed_needs_restart or not paused
	if seed_needs_restart:
		_set_status("SEED SET · RESET TO APPLY", false)

func _can_spawn_batch(current_count: int) -> bool:
	return current_count >= 0 and current_count + SPAWN_BATCH_SIZE <= MAX_SIMULATION_ENTITIES

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

func _capture_snapshot() -> void:
	var result: Dictionary = context.capture_snapshot()
	if not result.get("ok", false):
		_set_status("SNAPSHOT FAILED: %s" % str(result.get("error", "unknown")).to_upper(), true)
		return
	_restore_snapshot_button.disabled = false
	_set_status("SNAPSHOT CAPTURED · FORMAT %d" % int(result["snapshot"]["format_version"]), false)

func _restore_snapshot() -> void:
	if context.latest_snapshot.is_empty():
		_restore_snapshot_button.disabled = true
		_set_status("NO SNAPSHOT CAPTURED", true)
		return
	if not context.restore_snapshot(context.latest_snapshot):
		_set_status("SNAPSHOT RESTORE REJECTED", true)
		return
	_enemy_hp_multiplier.value = float(context.active_preset["overrides"].get("enemy_hp", 1.0))
	_contact_damage.value = float(context.active_preset["overrides"].get("contact_damage_per_hit", 0.0))
	_seed_control.value = float(context.seed)
	var stat_id := str(_live_stat_select.get_item_metadata(_live_stat_select.selected))
	_live_stat_value.value = float(context.live_stat_overrides.get(stat_id, 0.0))
	_refresh()
	_set_status("SNAPSHOT RESTORED", false)

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
	var preset: Dictionary = context.active_preset.duplicate(true) if not context.active_preset.is_empty() else _default_preset()
	preset["preset_id"] = _preset_id.text.strip_edges()
	preset["name"] = _preset_id.text.strip_edges()
	preset["seed"] = int(_seed_control.value)
	preset["initial_build"] = parser.data
	preset["overrides"]["enemy_hp"] = _enemy_hp_multiplier.value
	preset["overrides"]["contact_damage_per_hit"] = _contact_damage.value
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
	_enemy_hp_multiplier.value = float(preset["overrides"].get("enemy_hp", 1.0))
	_contact_damage.value = float(preset["overrides"].get("contact_damage_per_hit", 0.0))
	_seed_control.value = float(preset["seed"])
	context.live_stat_overrides.clear()
	_restore_snapshot_button.disabled = true
	_live_stat_value.value = 0.0
	_set_status("PRESET APPLIED TO COMBAT", false)

func _refresh() -> void:
	var state: Dictionary = context.simulation.snapshot()
	_view.set_entities(state["entities"])
	_pause_button.text = "RESUME" if state["paused"] else "PAUSE"
	_capture_snapshot_button.disabled = not bool(state["paused"])
	_restore_snapshot_button.disabled = not bool(state["paused"]) or context.latest_snapshot.is_empty()
	var active_speed: float = float(state.get("speed_multiplier", 1.0))
	for index in range(_speed_select.item_count):
		if is_equal_approx(float(_speed_select.get_item_metadata(index)), active_speed):
			_speed_select.select(index)
			break
	var metrics: Dictionary = state["metrics"]
	_metrics.text = "ENTITIES %d  ·  PROJECTILES %d\nSIM %.2f s  ·  FPS %d" % [
		int(metrics["entity_count"]), int(metrics["projectile_count"]),
		float(state["simulation_time"]), Engine.get_frames_per_second(),
	]
	_refresh_diagnostics(float(state["simulation_time"]))

func _refresh_diagnostics(simulation_time: float) -> void:
	var session_id: int = context.session.get_instance_id()
	if session_id != _diagnostic_session_id:
		_diagnostic_session_id = session_id
		_damage_totals.clear()
		_dps_samples.clear()
	for source_id in context.session._sandbox_damage_by_source:
		var total := float(context.session._sandbox_damage_by_source[source_id])
		var delta := total - float(_damage_totals.get(source_id, 0.0))
		if delta > 0.0:
			_dps_samples.append({"time": simulation_time, "source": str(source_id), "damage": delta})
			if _dps_samples.size() > MAX_DPS_SAMPLES:
				_dps_samples.pop_front()
	_damage_totals = context.session._sandbox_damage_by_source.duplicate(true)
	var window_cutoff := simulation_time - 10.0
	while not _dps_samples.is_empty() and float(_dps_samples[0]["time"]) < window_cutoff:
		_dps_samples.pop_front()
	var one_second_total := _damage_in_window(simulation_time - 1.0, "")
	var ten_second_total := _damage_in_window(window_cutoff, "")
	var run_total := 0.0
	for total in context.session._sandbox_damage_by_source.values():
		run_total += float(total)
	var one_second_duration := maxf(0.1, minf(1.0, simulation_time))
	var ten_second_duration := maxf(0.1, minf(10.0, simulation_time))
	var run_duration := maxf(0.1, simulation_time)
	_dps_summary.text = "DPS 1S %.1f  ·  10S %.1f  ·  RUN %.1f" % [
		one_second_total / one_second_duration,
		ten_second_total / ten_second_duration,
		run_total / run_duration,
	]
	var sources: Array = context.session._sandbox_damage_by_source.keys()
	sources.sort()
	var source_lines: PackedStringArray = []
	for source in sources:
		var source_id := str(source)
		var one_second := _damage_in_window(simulation_time - 1.0, source_id)
		var ten_seconds := _damage_in_window(window_cutoff, source_id)
		var source_run := float(context.session._sandbox_damage_by_source[source])
		source_lines.append("%s  ·  1S %.1f / 10S %.1f / RUN %.1f" % [
			source_id.replace("_", " ").to_upper(),
			one_second / one_second_duration,
			ten_seconds / ten_second_duration,
			source_run / run_duration,
		])
	_dps_sources.text = "NO WEAPON DAMAGE YET" if source_lines.is_empty() else "\n".join(source_lines)
	var rng_entries: Array[Dictionary] = context.session._sandbox_rng_log
	var rng_lines := PackedStringArray(["SEED %d" % context.session.sandbox_rng_seed])
	for index in range(maxi(0, rng_entries.size() - 6), rng_entries.size()):
		var entry: Dictionary = rng_entries[index]
		rng_lines.append("%.2fs  %s  %.3f" % [float(entry["time"]), str(entry["purpose"]), float(entry["value"])])
	_rng_log_label.text = "\n".join(rng_lines)

func _damage_in_window(cutoff: float, source_id: String) -> float:
	var total := 0.0
	for sample in _dps_samples:
		if float(sample["time"]) < cutoff or (not source_id.is_empty() and str(sample["source"]) != source_id):
			continue
		total += float(sample["damage"])
	return total

func _set_status(message: String, error: bool) -> void:
	_status.text = message
	_status.add_theme_color_override("font_color", Color("#ff7181") if error else Color("#ffd447"))

func _go_home() -> void:
	context.stop()
	var error := get_tree().change_scene_to_file("res://scenes/launch_menu.tscn")
	if error != OK:
		push_error("Could not return from Sandbox Lab: %s" % error_string(error))
