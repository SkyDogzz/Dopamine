extends Node

var preset_service: RefCounted
var active_preset: Dictionary = {}
var build
var simulation: Object
var session: Node2D
var seed := 0
var god_mode_enabled := true
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
	return {"ok": true, "preset": active_preset.duplicate(true)}

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
	return true
