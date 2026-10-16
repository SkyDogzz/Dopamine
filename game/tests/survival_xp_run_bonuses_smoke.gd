extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame

	var rotation: Array[String] = [
		"damage_pct", "attack_speed_pct", "critical_chance_pct", "critical_damage_pct",
		"max_hp", "move_speed_pct", "kill_healing_pct", "area_pct",
		"cooldown_reduction_pct", "xp_pct", "pickup_radius_pct", "projectile_speed_pct",
	]
	var base_hp: float = session.player_max_hp
	session.player_hp = base_hp * 0.5
	for index in range(rotation.size() + 1):
		session._add_xp(session.player_xp_to_next)
		if session.player_level != index + 2:
			_fail("Each XP threshold should grant exactly one level")
			return
		var expected_stat: String = rotation[index % rotation.size()]
		if not is_equal_approx(float(session._xp_run_stat_bonuses.get(expected_stat, 0.0)),
				2.0 if index == rotation.size() else 1.0):
			_fail("XP bonus rotation should award %s in order and restart after twelve levels" % expected_stat)
			return
		if index == 4 and (not is_equal_approx(session.player_max_hp, base_hp * 1.01) or
				not is_equal_approx(session.player_hp / session.player_max_hp, 0.5)):
			_fail("Max HP level bonus should multiply current/max HP by 1.01 while preserving the health ratio")
			return
		if index == 6 and not is_equal_approx(float(session._xp_run_stat_bonuses["kill_healing_pct"]), 1.0):
			_fail("The seventh run level should add one percentage point of kill healing")
			return

	var stats: Dictionary = session._run_stat_breakdown()
	for index in range(rotation.size()):
		var stat_id: String = rotation[index]
		var expected_run_bonus := 2.01 if stat_id == "max_hp" else (2.0 if index == 0 else 1.0)
		if stat_id == "max_hp":
			expected_run_bonus = 1.0
		if not is_equal_approx(float(stats[stat_id]["run"]), expected_run_bonus):
			_fail("The run stat hub should expose the XP contribution for %s" % stat_id)
			return
	if stats["max_hp"]["label"] != "MAX HP" or not str(stats["max_hp"]["total_text"]).ends_with(" HP") or \
			float(stats["max_hp"]["total"]) <= base_hp:
		_fail("The run stat hub should show the effective max HP gained during the run")
		return
	if session.player_level != 14 or session._xp_level_bonus_count != 13:
		_fail("XP bonuses should remain run-local and count each level after level one")
		return

	session.queue_free()
	await process_frame
	var next_session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	next_session.skip_starting_weapon_choice = true
	next_session.spawn_initial_enemy = false
	next_session.wave_spawning_enabled = false
	root.add_child(next_session)
	await process_frame
	if next_session.player_level != 1 or next_session._xp_level_bonus_count != 0 or \
			not next_session._xp_run_stat_bonuses.is_empty():
		_fail("Automatic XP stat bonuses should reset for every new run")
		return
	next_session.queue_free()
	await process_frame
	print("Survival XP run bonuses smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
