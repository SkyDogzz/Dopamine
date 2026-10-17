extends SceneTree

const LOADOUT_SCRIPT := preload("res://scripts/survival_loadout.gd")
const WEAPON_IDS := ["lightning_conductor", "inferno_sprayer", "crimson_daggers", "minigun",
		"toxic_cloud", "sawblades", "meteor_staff", "prism_laser", "void_orb", "frost_nova"]
const ENEMY_TYPES := ["chaser", "sprinter", "tank", "shooter", "buffer", "exploder",
		"shielder", "summoner", "summoned", "elite", "mid_boss", "final_boss"]
const BUILD_CASES := [
	{"name": "level_1", "weapon_level": 1, "relic_level": 0, "evolved": false},
	{"name": "level_5", "weapon_level": 5, "relic_level": 5, "evolved": false},
	{"name": "evolved", "weapon_level": 5, "relic_level": 5, "evolved": true},
]
const ACTIVE_SECONDS := 18.0
const ENEMY_HP_MULTIPLIER := 1000.0
const PLAYER_DISTANCE := 84.0
const SIMULATION_SPEED := 4.0

var _weapon_filter := ""
var _enemy_filter := ""
var _build_filter := ""
var _survey_seed := 20261017

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--weapon="):
			_weapon_filter = argument.trim_prefix("--weapon=")
		elif argument.begins_with("--enemy="):
			_enemy_filter = argument.trim_prefix("--enemy=")
		elif argument.begins_with("--build="):
			_build_filter = argument.trim_prefix("--build=")
		elif argument.begins_with("--seed="):
			_survey_seed = int(argument.trim_prefix("--seed="))
	if not _weapon_filter.is_empty() and _weapon_filter not in WEAPON_IDS:
		_fail("Unknown weapon filter: %s" % _weapon_filter)
		return
	if not _enemy_filter.is_empty() and _enemy_filter not in ENEMY_TYPES:
		_fail("Unknown enemy filter: %s" % _enemy_filter)
		return
	var build_names: Array[String] = []
	for build in BUILD_CASES:
		build_names.append(str(build["name"]))
	if not _build_filter.is_empty() and _build_filter not in build_names:
		_fail("Unknown build filter: %s" % _build_filter)
		return

	print("# survey_seed=%d,difficulty=normal,simulation_speed=%.1fx,player_movement=none,health_decay=disabled" % [
		_survey_seed, SIMULATION_SPEED,
	])
	print("enemy,weapon,build,active_seconds,weapon_damage,weapon_dps,enemy_hp_remaining,enemy_defeated,player_hp_remaining,player_hp_net_loss,player_alive,kills")
	var success := true
	for enemy_type in ENEMY_TYPES:
		if not _enemy_filter.is_empty() and enemy_type != _enemy_filter:
			continue
		for weapon_id in WEAPON_IDS:
			if not _weapon_filter.is_empty() and weapon_id != _weapon_filter:
				continue
			for build in BUILD_CASES:
				if not _build_filter.is_empty() and str(build["name"]) != _build_filter:
					continue
				if not await _measure(enemy_type, weapon_id, build):
					success = false
					break
			if not success:
				break
		if not success:
			break
	Engine.time_scale = 1.0
	if success:
		print("Archetype survival survey completed; raw comparison only, no tuning judgement applied")
		quit(0)
	else:
		quit(1)

func _measure(enemy_type: String, weapon_id: String, build: Dictionary) -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	session._health_locked = false
	session.xp_per_enemy = 0.0
	session._auto_select_first_chest = true
	session.ordinary_chest_drop_chance = 0.0
	session.elite_chest_drop_chance = 0.0
	session.chest_guarantee_interval_seconds = 0.0
	session.sandbox_diagnostics_enabled = true
	session.sandbox_rng_seed = _survey_seed
	session.sandbox_health_decay_multiplier = 0.0
	root.add_child(session)
	await process_frame
	if session.simulation == null:
		push_error("Could not initialize SurvivalSession for %s/%s/%s" % [enemy_type, weapon_id, build["name"]])
		session.queue_free()
		return false
	if session.progression_service != null:
		push_error("Archetype survey must not receive normal progression services")
		session.queue_free()
		return false
	session._chest_director._rng.seed = _survey_seed

	var loadout = LOADOUT_SCRIPT.new()
	loadout._rng.seed = _survey_seed
	if not loadout.apply_offer("weapon:" + weapon_id):
		push_error("Could not select survey weapon %s" % weapon_id)
		session.queue_free()
		return false
	for _level in range(1, int(build["weapon_level"])):
		if not loadout.apply_offer("weapon:" + weapon_id):
			push_error("Could not set %s to weapon level %d" % [weapon_id, build["weapon_level"]])
			session.queue_free()
			return false
	var relic_level := int(build["relic_level"])
	if relic_level > 0:
		var definition: Dictionary = loadout._weapon_definitions[weapon_id]
		var relic_id := str(definition["relic_id"])
		for _level in range(relic_level):
			if not loadout.apply_offer("relic:" + relic_id):
				push_error("Could not set %s to relic level %d" % [relic_id, relic_level])
				session.queue_free()
				return false
		if bool(build["evolved"]) and not loadout.apply_offer("evolution:" + weapon_id):
			push_error("Could not evolve %s at configured levels" % weapon_id)
			session.queue_free()
			return false
	session.loadout = loadout

	var spawn_position: Vector2 = session.player.global_position + Vector2.RIGHT * PLAYER_DISTANCE
	if session.simulation.spawn_enemy(enemy_type, 1, spawn_position, Vector2.ZERO, ENEMY_HP_MULTIPLIER) <= 0:
		push_error("Could not spawn archetype %s" % enemy_type)
		session.queue_free()
		return false
	var initial_health := await _wait_for_enemy_health(session, enemy_type)
	if initial_health <= 0.0:
		push_error("Could not observe spawned archetype %s" % enemy_type)
		session.queue_free()
		return false

	var initial_player_hp := float(session.player_hp)
	session.simulation.set_speed(SIMULATION_SPEED)
	Engine.time_scale = SIMULATION_SPEED
	session.weapon_enabled = true
	var start_active := float(session.player_active_time)
	var deadline := Time.get_ticks_msec() + 60000
	while float(session.player_active_time) - start_active < ACTIVE_SECONDS and \
			Time.get_ticks_msec() < deadline and not session.run_over:
		await process_frame
	var active_seconds := float(session.player_active_time) - start_active
	var health_remaining := _enemy_health(session, enemy_type)
	var weapon_damage := float(session._weapon_damage_by_id.get(weapon_id, 0.0))
	var player_hp_remaining := float(session.player_hp)
	var player_hp_net_loss := initial_player_hp - player_hp_remaining
	var enemy_defeated := int(session._enemy_kills_by_type.get(enemy_type, 0)) > 0
	var alive := player_hp_remaining > 0.0
	var kills := int(session.kill_count)
	var expected_relic_count := 1 if int(build["relic_level"]) > 0 else 0
	if session.loadout.owned_weapons().size() != 1 or \
			session.loadout.weapon_level(weapon_id) != int(build["weapon_level"]) or \
			session.loadout.owned_relics().size() != expected_relic_count or \
			session.loadout.is_evolved(weapon_id) != bool(build["evolved"]):
		push_error("Survey build changed during %s/%s/%s" % [enemy_type, weapon_id, build["name"]])
		Engine.time_scale = 1.0
		session.queue_free()
		return false
	Engine.time_scale = 1.0
	session.weapon_enabled = false
	if active_seconds <= 0.0 or (active_seconds < ACTIVE_SECONDS * 0.95 and not session.run_over):
		push_error("Incomplete archetype survey for %s/%s/%s: active=%.2f, run_over=%s" % [
			enemy_type, weapon_id, build["name"], active_seconds, str(session.run_over),
		])
		session.queue_free()
		return false
	print("%s,%s,%s,%.2f,%.2f,%.2f,%.2f,%s,%.1f,%.1f,%s,%d" % [
		enemy_type, weapon_id, build["name"], active_seconds, weapon_damage,
		weapon_damage / active_seconds, health_remaining, str(enemy_defeated),
		player_hp_remaining, player_hp_net_loss, str(alive), kills,
	])
	session.queue_free()
	await process_frame
	return true

func _wait_for_enemy_health(session: Node, enemy_type: String) -> float:
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var health := _enemy_health(session, enemy_type)
		if health > 0.0:
			return health
	return 0.0

func _enemy_health(session: Node, enemy_type: String) -> float:
	var total := 0.0
	for entity in session.simulation.snapshot()["entities"]:
		var components: Dictionary = entity["components"]
		if components.get("EnemyType", "") == enemy_type and not components.get("IsProjectile", false):
			total += maxf(0.0, float(components.get("Health", {}).get("current", 0.0)))
	return total

func _fail(message: String) -> void:
	Engine.time_scale = 1.0
	push_error(message)
	quit(1)
