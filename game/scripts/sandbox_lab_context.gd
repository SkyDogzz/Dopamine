extends Node

const SNAPSHOT_FORMAT_VERSION := 1
const MAX_SNAPSHOT_SEED := 2147483647

var preset_service: RefCounted
var active_preset: Dictionary = {}
var build
var simulation: Object
var session: Node2D
var seed := 0
var god_mode_enabled := true
var live_stat_overrides: Dictionary = {}
var latest_snapshot: Dictionary = {}
var progression_service: RefCounted
var normal_save_service: RefCounted

func _init(service: RefCounted = null) -> void:
	preset_service = service if service != null else load("res://scripts/sandbox_preset_service.gd").new()

func start(preset: Variant) -> Dictionary:
	var checked: Dictionary = preset_service.validate_preset(preset)
	if not checked.get("ok", false):
		return checked
	var build_script = load("res://scripts/sandbox_build.gd")
	var candidate_build = build_script.new()
	var build_result: Dictionary = candidate_build.load_build(checked["preset"]["initial_build"])
	if not build_result.get("ok", false):
		return {"ok": false, "error": "invalid_initial_build", "details": build_result}
	var candidate_session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	# Keep the candidate inert until its complete build has been applied.
	candidate_session.process_mode = Node.PROCESS_MODE_DISABLED
	candidate_session.progression_service = null
	candidate_session.sandbox_diagnostics_enabled = true
	candidate_session.sandbox_rng_seed = int(checked["preset"]["seed"])
	candidate_session.difficulty_id = "normal"
	candidate_session.skip_starting_weapon_choice = true
	candidate_session.spawn_initial_enemy = false
	candidate_session.wave_spawning_enabled = false
	candidate_session.weapon_enabled = true
	candidate_session.ordinary_chest_drop_chance = 0.0
	candidate_session.elite_chest_drop_chance = 0.0
	candidate_session.chest_guarantee_interval_seconds = 0.0
	candidate_session.contact_damage_per_hit = 0.0
	candidate_session.visible = false
	add_child(candidate_session)
	await Engine.get_main_loop().process_frame
	if candidate_session.simulation == null or not _apply_build(candidate_session, candidate_build):
		candidate_session.queue_free()
		return {"ok": false, "error": "combat_build_unsupported"}
	var was_paused := simulation != null and bool(simulation.snapshot().get("paused", false))
	_clear_simulation()
	session = candidate_session
	session.visible = false
	session.set_process_input(false)
	session.set_process_unhandled_input(false)
	session.set_process_unhandled_key_input(false)
	session._health_locked = god_mode_enabled
	simulation = session.simulation
	session.process_mode = Node.PROCESS_MODE_INHERIT
	if was_paused:
		simulation.pause()
	build = candidate_build
	active_preset = checked["preset"]
	seed = int(active_preset["seed"])
	live_stat_overrides.clear()
	latest_snapshot.clear()
	return {"ok": true, "preset": active_preset.duplicate(true)}

func capture_snapshot() -> Dictionary:
	if session == null or simulation == null or build == null:
		return {"ok": false, "error": "lab_unavailable"}
	if not bool(simulation.snapshot().get("paused", false)):
		return {"ok": false, "error": "pause_required"}
	if session._chest_open or session._starting_weapon_choice_open or session.run_over:
		return {"ok": false, "error": "modal_or_terminal_state"}
	var session_state: Dictionary = session.capture_sandbox_snapshot_state()
	if session_state.is_empty():
		return {"ok": false, "error": "session_state_unavailable"}
	var native_state: Dictionary = simulation.capture_state()
	if native_state.is_empty():
		return {"ok": false, "error": "native_capture_failed"}
	var snapshot := {
		"format_version": SNAPSHOT_FORMAT_VERSION,
		"native_state": native_state,
		"session_state": session_state,
		"active_preset": active_preset.duplicate(true),
		"build": build.to_dictionary(),
		"live_stat_overrides": live_stat_overrides.duplicate(true),
		"seed": seed,
		"god_mode_enabled": god_mode_enabled,
	}
	latest_snapshot = snapshot.duplicate(true)
	return {"ok": true, "snapshot": snapshot}

func restore_snapshot(snapshot: Variant) -> bool:
	if session == null or simulation == null or typeof(snapshot) != TYPE_DICTIONARY or \
			snapshot.size() != 8 or typeof(snapshot.get("format_version", null)) != TYPE_INT or \
			int(snapshot["format_version"]) != SNAPSHOT_FORMAT_VERSION:
		return false
	if not bool(simulation.snapshot().get("paused", false)):
		return false
	for key in ["native_state", "session_state", "active_preset", "build", "live_stat_overrides", "seed", "god_mode_enabled"]:
		if not snapshot.has(key):
			return false
	if typeof(snapshot["seed"]) != TYPE_INT or int(snapshot["seed"]) < 0 or int(snapshot["seed"]) > MAX_SNAPSHOT_SEED or \
			typeof(snapshot["god_mode_enabled"]) != TYPE_BOOL or not snapshot["active_preset"] is Dictionary:
		return false
	var checked_preset: Dictionary = preset_service.validate_preset(snapshot["active_preset"])
	if not checked_preset.get("ok", false) or int(checked_preset["preset"]["seed"]) != int(snapshot["seed"]):
		return false
	var build_script = load("res://scripts/sandbox_build.gd")
	var candidate_build = build_script.new()
	var build_result: Dictionary = candidate_build.load_build(snapshot["build"])
	if not build_result.get("ok", false):
		return false
	var build_data: Dictionary = candidate_build.to_dictionary()
	if build_data["weapons"].size() > session.loadout.MAX_SLOTS or \
			build_data["relics"].size() > session.loadout.MAX_SLOTS:
		return false
	var preset_build = build_script.new()
	var preset_build_result: Dictionary = preset_build.load_build(checked_preset["preset"]["initial_build"])
	if not preset_build_result.get("ok", false) or preset_build.to_dictionary() != candidate_build.to_dictionary():
		return false
	checked_preset["preset"]["initial_build"] = candidate_build.to_dictionary()
	if not session.can_restore_sandbox_snapshot_state(snapshot["session_state"]):
		return false
	var session_fields: Dictionary = snapshot["session_state"]["script_fields"]
	if int(session_fields.get("sandbox_rng_seed", -1)) != int(snapshot["seed"]) or \
			bool(session_fields.get("_health_locked", not bool(snapshot["god_mode_enabled"]))) != \
			bool(snapshot["god_mode_enabled"]):
		return false
	var native_state: Variant = snapshot["native_state"]
	if not native_state is Dictionary or native_state.size() != 2 or \
			int(native_state.get("format_version", -1)) != 17 or \
			not native_state.get("native_state", null) is Object or \
			not native_state["native_state"].is_valid():
		return false
	var overrides: Variant = snapshot["live_stat_overrides"]
	var stat_ids: Array = load("res://scripts/equipment_generator.gd").STAT_IDS
	if not overrides is Dictionary:
		return false
	for stat_id in overrides:
		if str(stat_id) not in stat_ids or typeof(overrides[stat_id]) not in [TYPE_INT, TYPE_FLOAT] or \
				not is_finite(float(overrides[stat_id])):
			return false
	if not simulation.restore_state(native_state):
		return false
	if not _apply_build(session, candidate_build):
		return false
	if not session.restore_sandbox_snapshot_state(snapshot["session_state"]):
		return false
	active_preset = checked_preset["preset"].duplicate(true)
	build = candidate_build
	seed = int(snapshot["seed"])
	god_mode_enabled = bool(snapshot["god_mode_enabled"])
	live_stat_overrides = overrides.duplicate(true)
	session._health_locked = god_mode_enabled
	latest_snapshot = snapshot.duplicate(true)
	return true

func apply_preset(preset: Variant) -> Dictionary:
	var checked: Dictionary = preset_service.validate_preset(preset)
	if not checked.get("ok", false):
		return checked
	var candidate_build = load("res://scripts/sandbox_build.gd").new()
	var build_result: Dictionary = candidate_build.load_build(checked["preset"]["initial_build"])
	if not build_result.get("ok", false):
		return {"ok": false, "error": "invalid_initial_build", "details": build_result}
	if simulation == null:
		return await start(checked["preset"])
	var state: Dictionary = simulation.snapshot()
	if not bool(state.get("paused", false)):
		return {"ok": false, "error": "pause_required"}
	return await start(checked["preset"])

func stop() -> void:
	_clear_simulation()
	active_preset.clear()
	build = null
	seed = 0
	live_stat_overrides.clear()
	latest_snapshot.clear()

func _clear_simulation() -> void:
	if session != null:
		session.queue_free()
		session = null
	simulation = null

func _apply_build(target_session: Node2D, target_build: RefCounted) -> bool:
	var loadout = target_session.loadout
	loadout._weapon_levels.clear()
	loadout._relic_levels.clear()
	loadout._evolved_weapons.clear()
	var build_data: Dictionary = target_build.to_dictionary()
	for family in ["weapons", "relics"]:
		for item in build_data[family]:
			var level := int(item["level"])
			if level > loadout.MAX_LEVEL:
				return false
			var offer_family := "weapon" if family == "weapons" else "relic"
			for _index in range(level):
				if not loadout.apply_offer("%s:%s" % [offer_family, str(item["id"])]):
					return false
	for item in build_data["weapons"]:
		if int(item["level"]) > loadout.MAX_LEVEL:
			return false
		if str(item.get("evolution_id", "")).is_empty():
			continue
		var weapon_id := str(item["id"])
		if not loadout.is_evolution_ready(weapon_id) or not loadout.apply_offer("evolution:%s" % weapon_id):
			return false
	var bonuses: Dictionary = target_session._cached_equipment_bonuses.duplicate(true)
	for stat_id in build_data["stats"]:
		bonuses[stat_id] = float(bonuses.get(stat_id, 0.0)) + float(build_data["stats"][stat_id])
	for equipment in build_data["equipment"]:
		for stat_id in equipment["stats"]:
			bonuses[stat_id] = float(bonuses.get(stat_id, 0.0)) + float(equipment["stats"][stat_id])
	target_session._cached_equipment_bonuses = bonuses
	target_session._cached_persistent_damage_multiplier = maxf(
		0.0, 1.0 + float(bonuses.get("damage_pct", 0.0)) / 100.0
	)
	var base_hp: float = target_session.simulation.initial_player_hp()
	target_session.player_max_hp = base_hp + float(bonuses.get("max_hp", 0.0)) + \
		base_hp * float(bonuses.get("max_hp_pct", 0.0))
	target_session.player_hp = target_session.player_max_hp
	target_session._refresh_player_move_speed()
	return true
