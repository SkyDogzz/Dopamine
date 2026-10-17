extends SceneTree

const LOADOUT_SCRIPT := preload("res://scripts/survival_loadout.gd")
const SURVIVAL_TARGETING := preload("res://scripts/survival_targeting.gd")
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
const STATIONARY_SIMULATION_SPEED := 4.0
const MOBILE_SIMULATION_SPEED := 1.0

var _weapon_filter := ""
var _enemy_filter := ""
var _build_filter := ""
var _movement_mode := "stationary"
var _survey_seed := 20261017
var _movement_actions: Array[String] = []

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
		elif argument.begins_with("--movement="):
			_movement_mode = argument.trim_prefix("--movement=")
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
	if _movement_mode not in ["stationary", "kite", "orbit"]:
		_fail("Movement mode must be stationary, kite, or orbit")
		return

	var simulation_speed := _simulation_speed()
	print("# survey_seed=%d,difficulty=normal,simulation_speed=%.1fx,player_movement=%s,health_decay=disabled" % [
		_survey_seed, simulation_speed, _movement_mode,
	])
	print("enemy,weapon,build,movement,active_seconds,weapon_damage,weapon_dps,enemy_hp_remaining,enemy_defeated,player_hp_remaining,player_hp_net_loss,player_alive,path_distance,kills")
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
	_clear_movement_actions()
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
	var simulation_speed := _simulation_speed()
	session.simulation.set_speed(simulation_speed)
	Engine.time_scale = simulation_speed
	session.weapon_enabled = true
	var start_active := float(session.player_active_time)
	var next_move_at := start_active
	var direction_seed := 0
	var path_distance := 0.0
	var previous_position: Vector2 = session.player.global_position
	var deadline := Time.get_ticks_msec() + 60000
	while float(session.player_active_time) - start_active < ACTIVE_SECONDS and \
			Time.get_ticks_msec() < deadline and not session.run_over:
		if _movement_mode != "stationary" and session.player_active_time >= next_move_at:
			if _movement_mode == "orbit":
				_set_orbit_movement(session, direction_seed, weapon_id)
				next_move_at = session.player_active_time + 0.25
			else:
				_set_kite_movement(session, direction_seed)
				next_move_at = session.player_active_time + 0.5
			direction_seed += 1
		await process_frame
		var current_position: Vector2 = session.player.global_position
		path_distance += previous_position.distance_to(current_position)
		previous_position = current_position
	var active_seconds := float(session.player_active_time) - start_active
	_clear_movement_actions()
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
	print("%s,%s,%s,%s,%.2f,%.2f,%.2f,%.2f,%s,%.1f,%.1f,%s,%.1f,%d" % [
		enemy_type, weapon_id, build["name"], _movement_mode, active_seconds, weapon_damage,
		weapon_damage / active_seconds, health_remaining, str(enemy_defeated),
		player_hp_remaining, player_hp_net_loss, str(alive), path_distance, kills,
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

func _simulation_speed() -> float:
	return STATIONARY_SIMULATION_SPEED if _movement_mode == "stationary" else MOBILE_SIMULATION_SPEED

func _set_kite_movement(session: Node, orbit_direction: int) -> void:
	var away := _nearest_enemy_offset(session).normalized()
	var tangent := Vector2(-away.y, away.x) * (1.0 if orbit_direction % 2 == 0 else -1.0)
	_set_movement((away * 0.8 + tangent * 0.6).normalized())

func _set_orbit_movement(session: Node, orbit_direction: int, weapon_id: String) -> void:
	var offset := _nearest_enemy_offset(session)
	if offset == Vector2.ZERO:
		_set_movement(Vector2.UP)
		return
	var distance := offset.length()
	var away := offset / distance
	var target_distance := minf(_effective_weapon_range(session, weapon_id) * 0.75, 105.0)
	var min_distance := maxf(32.0, target_distance * 0.8)
	var max_distance := target_distance * 1.1
	var radial := Vector2.ZERO
	if distance < min_distance:
		radial = away
	elif distance > max_distance:
		radial = -away
	var turn := floori(float(orbit_direction) / 8.0)
	var tangent := Vector2(-away.y, away.x) * (1.0 if turn % 2 == 0 else -1.0)
	_set_movement((radial + tangent).normalized() if radial != Vector2.ZERO else tangent)

func _effective_weapon_range(session: Node, weapon_id: String) -> float:
	var level: int = session.loadout.weapon_level(weapon_id)
	match weapon_id:
		"lightning_conductor":
			return SURVIVAL_TARGETING.visible_range(session.lightning_range)
		"inferno_sprayer":
			return SURVIVAL_TARGETING.weapon_range(session.inferno_range,
				session._weapon_level_multiplier(weapon_id, "range_multiplier", level))
		"crimson_daggers":
			return SURVIVAL_TARGETING.visible_range(session.daggers_range)
		"minigun":
			return SURVIVAL_TARGETING.visible_range(session.minigun_range)
		"toxic_cloud":
			return SURVIVAL_TARGETING.visible_range(session.toxic_range)
		"sawblades":
			return SURVIVAL_TARGETING.visible_range(session.sawblades_range)
		"meteor_staff":
			return SURVIVAL_TARGETING.visible_range(session.meteor_staff_range)
		"prism_laser":
			return SURVIVAL_TARGETING.visible_range(session.prism_laser_range)
		"void_orb":
			return SURVIVAL_TARGETING.visible_range(session.void_orb_range)
		"frost_nova":
			var area_multiplier: float = 1.0 + session.loadout.global_relic_bonus("area_pct") / 100.0
			return SURVIVAL_TARGETING.weapon_range(session.frost_nova_radius,
				session._weapon_level_multiplier(weapon_id, "area_multiplier", level), area_multiplier)
	return 0.0

func _nearest_enemy_offset(session: Node) -> Vector2:
	var nearest_offset := Vector2.ZERO
	var nearest_distance_squared := INF
	for entity in session.simulation.snapshot()["entities"]:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("IsXpOrb", false) or \
				float(components.get("Health", {}).get("current", 0.0)) <= 0.0:
			continue
		var transform: Dictionary = components.get("Transform2D", {})
		var enemy_position := Vector2(float(transform.get("x", 0.0)), float(transform.get("y", 0.0)))
		var offset: Vector2 = session.player.global_position - enemy_position
		if offset.length_squared() < nearest_distance_squared:
			nearest_distance_squared = offset.length_squared()
			nearest_offset = offset
	return nearest_offset

func _set_movement(direction: Vector2) -> void:
	var actions: Array[String] = []
	if direction.x < -0.35:
		actions.append("move_left")
	elif direction.x > 0.35:
		actions.append("move_right")
	if direction.y < -0.35:
		actions.append("move_up")
	elif direction.y > 0.35:
		actions.append("move_down")
	_clear_movement_actions()
	_movement_actions = actions
	for action in _movement_actions:
		Input.action_press(action)

func _clear_movement_actions() -> void:
	for action in _movement_actions:
		Input.action_release(action)
	_movement_actions.clear()

func _fail(message: String) -> void:
	Engine.time_scale = 1.0
	_clear_movement_actions()
	push_error(message)
	quit(1)
