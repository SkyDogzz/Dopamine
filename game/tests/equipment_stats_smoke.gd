extends SceneTree

const TEST_DIRECTORY := "user://equipment_stats_smoke"
const EQUIPMENT_GENERATOR := preload("res://scripts/equipment_generator.gd")

var _save_service: RefCounted
var _progression: RefCounted

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	_save_service = load("res://scripts/save_service.gd").new(directory)
	_progression = load("res://scripts/progression_service.gd").new(_save_service, "0")
	if not await _check_max_hp() or not await _check_mobility() or not await _check_damage():
		return
	if not await _check_attack_speed() or not await _check_critical_chance() or \
		not await _check_critical_damage():
		return
	if not await _check_kill_healing() or not await _check_area() or not await _check_cooldown():
		return
	if not await _check_xp() or not await _check_pickup_radius() or not await _check_projectile_speed():
		return
	print("Equipment stat application smoke passed")
	quit()

func _check_max_hp() -> bool:
	var session: Node2D = await _session_with_stat("max_hp")
	if session == null:
		return false
	var expected: float = session.simulation.initial_player_hp() + EQUIPMENT_GENERATOR.stat_value("max_hp", 0.5)
	var passed := is_equal_approx(session.player_max_hp, expected)
	_free_session(session)
	return _expect(passed, "Equipped max_hp should increase Survival maximum HP by its rolled flat value")

func _check_mobility() -> bool:
	var session: Node2D = await _session_with_stat("move_speed_pct")
	if session == null:
		return false
	var expected: float = session._base_player_move_speed * 1.025
	var passed := is_equal_approx(session.player.move_speed, expected)
	_free_session(session)
	return _expect(passed, "Equipped move_speed_pct should change Survival player movement speed")

func _check_damage() -> bool:
	var session: Node2D = await _session_with_stat("damage_pct")
	if session == null:
		return false
	var passed := is_equal_approx(session._persistent_damage_multiplier(), 1.03)
	_free_session(session)
	return _expect(passed, "Equipped damage_pct should change Survival weapon damage multiplier")

func _check_attack_speed() -> bool:
	var session: Node2D = await _session_with_stat("attack_speed_pct")
	if session == null:
		return false
	var passed := is_equal_approx(session._effective_weapon_cooldown(1.0), 1.0 / 1.025)
	_free_session(session)
	return _expect(passed, "Equipped attack_speed_pct should shorten Survival weapon interval")

func _check_critical_chance() -> bool:
	var session: Node2D = await _session_with_stat("critical_chance_pct")
	if session == null:
		return false
	seed(456789)
	var critical_hits := 0
	for _index in range(10000):
		if session._roll_equipment_critical_multiplier() > 1.0:
			critical_hits += 1
	var expected_hits: float = 10000.0 * EQUIPMENT_GENERATOR.stat_value("critical_chance_pct", 0.5) / 100.0
	var passed := absf(float(critical_hits) - expected_hits) < 5.0 * sqrt(expected_hits) + 2.0
	_free_session(session)
	return _expect(passed, "Equipped critical_chance_pct should control the deterministic critical hit rate")

func _check_critical_damage() -> bool:
	var session: Node2D = await _session_with_stat("critical_damage_pct")
	if session == null:
		return false
	# Force a critical only as the test trigger; the persisted item contributes critical damage alone.
	session._cached_equipment_bonuses["critical_chance_pct"] = 100.0
	var expected: float = 1.5 + EQUIPMENT_GENERATOR.stat_value("critical_damage_pct", 0.5) / 100.0
	var passed := is_equal_approx(session._roll_equipment_critical_multiplier(), expected)
	_free_session(session)
	return _expect(passed, "Equipped critical_damage_pct should increase a guaranteed critical multiplier")

func _check_kill_healing() -> bool:
	var session: Node2D = await _session_with_stat("kill_healing_pct")
	if session == null:
		return false
	var passed := is_equal_approx(session._equipment_kill_healing(10.0), 10.2)
	_free_session(session)
	return _expect(passed, "Equipped kill_healing_pct should increase kill healing")

func _check_area() -> bool:
	var session: Node2D = await _session_with_stat("area_pct")
	if session == null:
		return false
	var passed := is_equal_approx(session._equipment_area(100.0), 102.5)
	_free_session(session)
	return _expect(passed, "Equipped area_pct should increase Survival weapon area")

func _check_cooldown() -> bool:
	var session: Node2D = await _session_with_stat("cooldown_reduction_pct")
	if session == null:
		return false
	var passed := is_equal_approx(session._effective_weapon_cooldown(1.0), 0.9875)
	_free_session(session)
	return _expect(passed, "Equipped cooldown_reduction_pct should reduce Survival weapon cooldown")

func _check_xp() -> bool:
	var session: Node2D = await _session_with_stat("xp_pct")
	if session == null:
		return false
	var passed := is_equal_approx(session._equipment_xp_value(5.0), 5.125)
	_free_session(session)
	return _expect(passed, "Equipped xp_pct should increase XP earned from enemy drops")

func _check_pickup_radius() -> bool:
	var session: Node2D = await _session_with_stat("pickup_radius_pct")
	if session == null:
		return false
	var passed := is_equal_approx(session._xp_pickup_radius(0.0), session.xp_collection_radius * 1.05)
	_free_session(session)
	return _expect(passed, "Equipped pickup_radius_pct should increase the XP pickup radius")

func _check_projectile_speed() -> bool:
	var session: Node2D = await _session_with_stat("projectile_speed_pct")
	if session == null:
		return false
	var passed := is_equal_approx(session._equipment_projectile_speed(100.0), 105.0)
	_free_session(session)
	return _expect(passed, "Equipped projectile_speed_pct should increase Survival projectile speed")

func _session_with_stat(stat_id: String) -> Node2D:
	var profile: Dictionary = _progression.load_profile()["profile"]
	var equipment: Dictionary = EQUIPMENT_GENERATOR.new(9876).generate_survival_item("stats_%s" % stat_id)
	equipment["rarity"] = "normal"
	equipment["equipped"] = true
	equipment["stat_lines"] = [{
		"stat_id": stat_id, "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0,
	}]
	equipment["unique_effect_id"] = ""
	profile["equipment_inventory"] = [equipment]
	if not _save_service.save_slot("0", profile):
		push_error("Could not persist the %s-only equipped stat fixture" % stat_id)
		return null
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.progression_service = _progression
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	root.add_child(session)
	if not await _wait_until(func() -> bool: return not session.simulation.snapshot()["paused"]):
		push_error("Survival test session did not start for %s" % stat_id)
		session.queue_free()
		return null
	return session

func _free_session(session: Node2D) -> void:
	session.queue_free()

func _expect(passed: bool, message: String) -> bool:
	if passed:
		return true
	push_error(message)
	quit(1)
	return false

func _wait_until(predicate: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if predicate.call():
			return true
	return false
