extends SceneTree

const LOADOUT_SCRIPT := preload("res://scripts/survival_loadout.gd")
const WEAPON_IDS := ["lightning_conductor", "inferno_sprayer", "crimson_daggers", "minigun",
		"toxic_cloud", "sawblades", "meteor_staff", "prism_laser", "void_orb", "frost_nova"]
const BUILD_CASES := [
	{"name": "level_1", "weapon_level": 1, "relic_level": 0, "evolved": false},
	{"name": "level_5", "weapon_level": 5, "relic_level": 5, "evolved": false},
	{"name": "evolved", "weapon_level": 5, "relic_level": 5, "evolved": true},
]
const ACTIVE_SECONDS := 18.0
const TARGET_COUNT := 24
const TARGET_HP := 1000000.0
var _weapon_filter := ""
var _formation_filter := "cluster"
var _survey_seed := 20261017
var _overcharge_multiplier := -1.0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--weapon="):
			_weapon_filter = argument.trim_prefix("--weapon=")
		elif argument.begins_with("--formation="):
			_formation_filter = argument.trim_prefix("--formation=")
		elif argument.begins_with("--seed="):
			_survey_seed = int(argument.trim_prefix("--seed="))
		elif argument.begins_with("--overcharge-multiplier="):
			var value_text: String = argument.trim_prefix("--overcharge-multiplier=")
			if not value_text.is_valid_float():
				push_error("Overcharge multiplier must be a number from 0 to 2")
				quit(1)
				return
			_overcharge_multiplier = float(value_text)
			if not is_finite(_overcharge_multiplier) or _overcharge_multiplier < 0.0 or _overcharge_multiplier > 2.0:
				push_error("Overcharge multiplier must be a number from 0 to 2")
				quit(1)
				return
	if not _weapon_filter.is_empty() and _weapon_filter not in WEAPON_IDS:
		push_error("Unknown weapon filter: %s" % _weapon_filter)
		quit(1)
		return
	if _formation_filter not in ["single", "cluster", "approach"]:
		push_error("Unknown formation filter: %s" % _formation_filter)
		quit(1)
		return
	print("# survey_seed=%d" % _survey_seed)
	print("# overcharge_multiplier=%s" % ("default" if _overcharge_multiplier < 0.0 else str(_overcharge_multiplier)))
	print("weapon,formation,build,weapon_level,relic_level,evolved,active_seconds,damage,dps,overcharge_multiplier,loop_interval_p95_ms,loop_interval_max_ms")
	for weapon_id in WEAPON_IDS:
		if not _weapon_filter.is_empty() and weapon_id != _weapon_filter:
			continue
		for build in BUILD_CASES:
			if not await _measure(str(weapon_id), build):
				Engine.time_scale = 1.0
				quit(1)
				return
	Engine.time_scale = 1.0
	print("Combat weapon balance survey completed; raw comparisons only, no tuning judgement applied")
	quit()

func _measure(weapon_id: String, build: Dictionary) -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	session._health_locked = true
	session.sandbox_diagnostics_enabled = true
	session.sandbox_rng_seed = _survey_seed
	if _overcharge_multiplier >= 0.0:
		session.overcharge_damage_multiplier = _overcharge_multiplier
	root.add_child(session)
	await process_frame
	if session.simulation == null:
		push_error("Could not initialize SurvivalSession for %s/%s" % [weapon_id, build["name"]])
		session.queue_free()
		return false

	var loadout = LOADOUT_SCRIPT.new()
	if not loadout.apply_offer("weapon:" + weapon_id):
		push_error("Could not select survey weapon %s" % weapon_id)
		session.queue_free()
		return false
	var weapon_level := int(build["weapon_level"])
	var relic_level := int(build["relic_level"])
	for _level in range(1, weapon_level):
		if not loadout.apply_offer("weapon:" + weapon_id):
			push_error("Could not set %s to weapon level %d" % [weapon_id, weapon_level])
			session.queue_free()
			return false
	if relic_level > 0:
		var definition: Dictionary = loadout._weapon_definitions[weapon_id]
		var relic_id := str(definition["relic_id"])
		for _level in range(relic_level):
			if not loadout.apply_offer("relic:" + relic_id):
				push_error("Could not set %s to relic level %d" % [relic_id, relic_level])
				session.queue_free()
				return false
		if bool(build["evolved"]) and not loadout.apply_offer("evolution:" + weapon_id):
			push_error("Could not evolve %s at the configured levels" % weapon_id)
			session.queue_free()
			return false
	session.loadout = loadout

	var player_position: Vector2 = session.player.global_position
	var target_count := TARGET_COUNT
	if _formation_filter == "single":
		target_count = 1
	elif _formation_filter == "approach":
		target_count = 8
	for index in range(target_count):
		var angle := TAU * float(index) / float(target_count)
		var radius := 58.0 if index % 2 == 0 else 112.0
		if _formation_filter == "single":
			angle = 0.0
			radius = 26.0
		elif _formation_filter == "approach":
			radius = 220.0
		var position := player_position + Vector2.from_angle(angle) * radius
		if _formation_filter == "approach":
			session.simulation.spawn_enemy("chaser", 1, position, Vector2.ZERO, 10000.0)
		else:
			session.simulation.spawn("test_target", 1, position, TARGET_HP, Vector2.ZERO)
	var targets: Array = await _wait_for_targets(session, target_count)
	if targets.size() != target_count:
		push_error("Expected %d targets for %s, got %d" % [target_count, weapon_id, targets.size()])
		session.queue_free()
		return false
	session.simulation.set_speed(4.0)
	Engine.time_scale = 4.0
	session.weapon_enabled = true
	var starting_collision_count := int(session.simulation.snapshot()["metrics"]["collision_count"])
	var loop_interval_ms: Array[float] = []
	var previous_frame_us := Time.get_ticks_usec()
	var previous_dagger_fire_at := float(session._next_daggers_time)
	var dagger_volley_count := 0
	var start_active := float(session.player_active_time)
	var deadline := Time.get_ticks_msec() + 30000
	while float(session.player_active_time) - start_active < ACTIVE_SECONDS and \
			Time.get_ticks_msec() < deadline and not session.run_over:
		await process_frame
		var now_us := Time.get_ticks_usec()
		loop_interval_ms.append(float(now_us - previous_frame_us) / 1000.0)
		previous_frame_us = now_us
		var dagger_fire_at := float(session._next_daggers_time)
		if dagger_fire_at > previous_dagger_fire_at:
			dagger_volley_count += 1
			previous_dagger_fire_at = dagger_fire_at
	var elapsed := float(session.player_active_time) - start_active
	var damage := float(session._weapon_damage_by_id.get(weapon_id, 0.0))
	var collision_count := int(session.simulation.snapshot()["metrics"]["collision_count"]) - starting_collision_count
	Engine.time_scale = 1.0
	session.weapon_enabled = false
	if elapsed < ACTIVE_SECONDS * 0.95 or damage <= 0.0 or loop_interval_ms.is_empty():
		push_error("Incomplete %s/%s survey: active=%.2fs damage=%.1f frames=%d" % [
			weapon_id, build["name"], elapsed, damage, loop_interval_ms.size(),
		])
		session.queue_free()
		return false
	loop_interval_ms.sort()
	var p95_index := mini(loop_interval_ms.size() - 1,
			int(floor(float(loop_interval_ms.size() - 1) * 0.95)))
	var max_loop_interval_ms := loop_interval_ms[loop_interval_ms.size() - 1]
	print("%s,%s,%s,%d,%d,%s,%.2f,%.2f,%.2f,%.2f,%.3f,%.3f" % [
		weapon_id, _formation_filter, build["name"], weapon_level, relic_level, str(build["evolved"]), elapsed,
		damage, damage / elapsed,
		session.overcharge_damage_multiplier, loop_interval_ms[p95_index], max_loop_interval_ms,
	])
	if weapon_id == "crimson_daggers":
		print("# Crimson volleys=%d (expected approx %.0f); native collisions=%d at %.2fs cooldown" % [
			dagger_volley_count, elapsed / session.daggers_cooldown, collision_count, session.daggers_cooldown,
		])
	session.queue_free()
	await process_frame
	return true

func _wait_for_targets(session: Node, expected_count: int) -> Array:
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var entities: Array = session.simulation.snapshot()["entities"]
		if entities.size() >= expected_count:
			return entities
	return []
