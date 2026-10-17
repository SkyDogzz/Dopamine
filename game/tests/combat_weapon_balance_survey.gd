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

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--weapon="):
			_weapon_filter = argument.trim_prefix("--weapon=")
	if not _weapon_filter.is_empty() and _weapon_filter not in WEAPON_IDS:
		push_error("Unknown weapon filter: %s" % _weapon_filter)
		quit(1)
		return
	print("weapon,build,weapon_level,relic_level,evolved,active_seconds,damage,dps,loop_interval_p95_ms,loop_interval_max_ms")
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
	for index in range(TARGET_COUNT):
		var angle := TAU * float(index) / float(TARGET_COUNT)
		var radius := 58.0 if index % 2 == 0 else 112.0
		var position := player_position + Vector2.from_angle(angle) * radius
		session.simulation.spawn("test_target", 1, position, TARGET_HP, Vector2.ZERO)
	var targets: Array = await _wait_for_targets(session, TARGET_COUNT)
	if targets.size() != TARGET_COUNT:
		push_error("Expected %d targets for %s, got %d" % [TARGET_COUNT, weapon_id, targets.size()])
		session.queue_free()
		return false
	session.simulation.set_speed(4.0)
	Engine.time_scale = 4.0
	session.weapon_enabled = true
	var loop_interval_ms: Array[float] = []
	var previous_frame_us := Time.get_ticks_usec()
	var start_active := float(session.player_active_time)
	var deadline := Time.get_ticks_msec() + 30000
	while float(session.player_active_time) - start_active < ACTIVE_SECONDS and \
			Time.get_ticks_msec() < deadline and not session.run_over:
		await process_frame
		var now_us := Time.get_ticks_usec()
		loop_interval_ms.append(float(now_us - previous_frame_us) / 1000.0)
		previous_frame_us = now_us
	var elapsed := float(session.player_active_time) - start_active
	var damage := float(session._weapon_damage_by_id.get(weapon_id, 0.0))
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
	print("%s,%s,%d,%d,%s,%.2f,%.2f,%.2f,%.3f,%.3f" % [
		weapon_id, build["name"], weapon_level, relic_level, str(build["evolved"]), elapsed,
		damage, damage / elapsed, loop_interval_ms[p95_index], max_loop_interval_ms,
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
