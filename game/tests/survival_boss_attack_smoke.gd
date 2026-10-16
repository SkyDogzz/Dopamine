extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	session.summoner_max_active_summons = 3
	root.add_child(session)
	await process_frame
	session._spawn_boss_placeholder("mid_boss")
	var boss: Dictionary = await _wait_for_boss(session)
	if boss.is_empty():
		_fail("The Pulse Warden should spawn for its attack smoke")
		return
	var boss_id: Dictionary = boss["id"]
	var boss_key: String = session._entity_key(int(boss_id["index"]), int(boss_id["generation"]))
	session._entities = session.simulation.snapshot()["entities"]
	session._update_pulse_warden_attacks(0.0, false)
	var attack: Dictionary = session._pulse_warden_attacks[boss_key]
	session._update_pulse_warden_attacks(float(attack["next_attack_at"]), false)
	attack = session._pulse_warden_attacks[boss_key]
	if attack["stage"] != "telegraph" or attack["pattern"] != "radial":
		_fail("Phase one should telegraph a radial projectile pattern")
		return
	session._update_pulse_warden_attacks(float(attack["fire_at"]), true)
	if attack["stage"] != "telegraph":
		_fail("A boss telegraph should freeze during a gameplay pause")
		return
	session._update_pulse_warden_attacks(float(attack["fire_at"]), false)
	if not await _wait_for_projectiles(session, session.pulse_warden_radial_projectile_count):
		_fail("The radial telegraph should resolve into its configured projectile ring")
		return
	if session.get_node("HUD/BossPanel/BossInfo/BossValue").text.find("PULSE WARDEN") < 0:
		_fail("The boss HUD should name the mid-boss")
		return
	var damage_sequence: int = session.simulation.apply_damage_over_time(
		int(boss_id["index"]), int(boss_id["generation"]), 500.0, 0.05, 0.05
	)
	if damage_sequence <= 0:
		_fail("The boss phase smoke should be able to damage the Warden")
		return
	var damaged_boss: Dictionary = await _wait_for_health_ratio(session, 0.6)
	if damaged_boss.is_empty():
		_fail("The Warden should enter phase two below its configured health threshold")
		return
	session._entities = session.simulation.snapshot()["entities"]
	var now: float = float(session.simulation.snapshot()["simulation_time"])
	session._update_pulse_warden_attacks(now, false)
	attack = session._pulse_warden_attacks[boss_key]
	if int(attack["phase"]) != 2:
		_fail("The Warden attack director should track its second health phase")
		return
	session._update_pulse_warden_attacks(float(attack["next_attack_at"]), false)
	attack = session._pulse_warden_attacks[boss_key]
	if attack["stage"] != "telegraph" or attack["pattern"] != "aimed":
		_fail("Phase two should telegraph a targeted attack")
		return
	session._update_pulse_warden_attacks(float(attack["fire_at"]), false)
	if not await _wait_for_entity_type(session, "summoned"):
		_fail("Phase two should invoke a capped add alongside its attack")
		return
	attack = session._pulse_warden_attacks[boss_key]
	session._update_pulse_warden_attacks(float(attack["next_attack_at"]), false)
	attack = session._pulse_warden_attacks[boss_key]
	if attack["stage"] != "telegraph" or attack["pattern"] != "charge":
		_fail("Phase two should alternate its aimed attack with a mobile charge")
		return
	var phase_two_boss := await _wait_for_boss(session)
	var phase_two_transform: Dictionary = phase_two_boss["components"]["Transform2D"]
	var before_phase_two_charge := Vector2(float(phase_two_transform["x"]), float(phase_two_transform["y"]))
	session._update_pulse_warden_attacks(float(attack["fire_at"]), false)
	if not await _wait_for_displacement(session, "mid_boss", before_phase_two_charge, 12.0):
		_fail("The phase two Warden charge should move its boss entity")
		return
	session.pulse_warden_phase_three_health_ratio = 0.9
	session._entities = session.simulation.snapshot()["entities"]
	session._update_pulse_warden_attacks(float(session.simulation.snapshot()["simulation_time"]), false)
	attack = session._pulse_warden_attacks[boss_key]
	if int(attack["phase"]) != 3:
		_fail("The Warden should enter phase three at its configured health threshold")
		return
	session._update_pulse_warden_attacks(float(attack["next_attack_at"]), false)
	attack = session._pulse_warden_attacks[boss_key]
	if attack["stage"] != "telegraph" or attack["pattern"] != "radial":
		_fail("Phase three should retain its readable radial projectile pattern")
		return
	session._update_pulse_warden_attacks(float(attack["fire_at"]), false)
	attack = session._pulse_warden_attacks[boss_key]
	session._update_pulse_warden_attacks(float(attack["next_attack_at"]), false)
	attack = session._pulse_warden_attacks[boss_key]
	if attack["stage"] != "telegraph" or attack["pattern"] != "charge":
		_fail("Phase three should telegraph a mobile charge after the radial pattern")
		return
	var boss_now := await _wait_for_boss(session)
	var boss_now_transform: Dictionary = boss_now["components"]["Transform2D"]
	var before_charge := Vector2(float(boss_now_transform["x"]), float(boss_now_transform["y"]))
	session._update_pulse_warden_attacks(float(attack["fire_at"]), false)
	if not await _wait_for_displacement(session, "mid_boss", before_charge, 12.0):
		_fail("The telegraphed Pulse Warden charge should move its boss entity")
		return
	session.queue_free()
	if not await _verify_dopamine_core_patterns_and_phases():
		return
	if not await _verify_chaos_boss_cadence():
		return
	print("Survival boss attack smoke passed")
	quit()

func _wait_for_boss(session: Node2D) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		for entity in session.simulation.snapshot()["entities"]:
			if entity["components"].get("EnemyType", "") == "mid_boss":
				return entity
	return {}

func _wait_for_health_ratio(session: Node2D, ratio: float) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		for entity in session.simulation.snapshot()["entities"]:
			if entity["components"].get("EnemyType", "") != "mid_boss":
				continue
			var health: Dictionary = entity["components"]["Health"]
			if float(health["current"]) / float(health["maximum"]) <= ratio:
				return entity
	return {}

func _wait_for_projectiles(session: Node2D, expected: int) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var count := 0
		for entity in session.simulation.snapshot()["entities"]:
			if entity["components"].get("EnemyType", "") == "enemy_projectile":
				count += 1
		if count >= expected:
			return true
	return false

func _wait_for_entity_type(session: Node2D, expected_type: String) -> bool:
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		for entity in session.simulation.snapshot()["entities"]:
			if entity["components"].get("EnemyType", "") == expected_type:
				return true
	return false

func _wait_for_displacement(session: Node2D, expected_type: String, start: Vector2, distance: float) -> bool:
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		for entity in session.simulation.snapshot()["entities"]:
			if entity["components"].get("EnemyType", "") != expected_type:
				continue
			var transform: Dictionary = entity["components"]["Transform2D"]
			if Vector2(float(transform["x"]), float(transform["y"])).distance_to(start) >= distance:
				return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _verify_dopamine_core_patterns_and_phases() -> bool:
	var core_session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	core_session.wave_spawning_enabled = false
	core_session.spawn_initial_enemy = false
	core_session.weapon_enabled = false
	core_session.skip_starting_weapon_choice = true
	core_session.contact_damage_per_hit = 0.0
	core_session.final_boss_attack_interval_seconds = 1.0
	core_session.final_boss_telegraph_seconds = 0.25
	core_session.final_boss_zone_radius = 70.0
	core_session.summoner_max_active_summons = 3
	root.add_child(core_session)
	await process_frame
	core_session.simulation.spawn("final_boss", 1, Vector2(0.0, -300.0), 1000.0, Vector2.ZERO, 25.0)
	if not await _wait_for_entity_type(core_session, "final_boss"):
		core_session.queue_free()
		_fail("The Dopamine Core should spawn in Survival")
		return false
	core_session._entities = core_session.simulation.snapshot()["entities"]
	var boss: Dictionary = _find_entity(core_session, "final_boss")
	var boss_id: Dictionary = boss["id"]
	var boss_key: String = core_session._entity_key(int(boss_id["index"]), int(boss_id["generation"]))
	var current_time := float(core_session.simulation.snapshot()["simulation_time"])
	core_session._update_dopamine_core_attacks(current_time, false)
	var attack: Dictionary = core_session._dopamine_core_attacks[boss_key]
	core_session._update_dopamine_core_attacks(float(attack["next_attack_at"]), false)
	attack = core_session._dopamine_core_attacks[boss_key]
	if attack["stage"] != "telegraph" or attack["pattern"] != "ray":
		core_session.queue_free()
		_fail("Phase one should telegraph a ray before firing")
		return false
	core_session._update_dopamine_core_attacks(float(attack["fire_at"]), true)
	if attack["stage"] != "telegraph":
		core_session.queue_free()
		_fail("The Dopamine Core telegraph should freeze while paused")
		return false
	core_session.player.global_position += Vector2(100.0, 0.0)
	var hp_before_dodge: float = core_session.player_hp
	core_session._update_dopamine_core_attacks(float(attack["fire_at"]), false)
	if not is_equal_approx(core_session.player_hp, hp_before_dodge):
		core_session.queue_free()
		_fail("Moving out of the telegraphed ray should avoid its damage")
		return false
	var next_attack_at: float = float(attack["next_attack_at"])
	core_session._update_dopamine_core_attacks(next_attack_at, false)
	attack = core_session._dopamine_core_attacks[boss_key]
	if attack["pattern"] != "zone" or attack["stage"] != "telegraph":
		core_session.queue_free()
		_fail("Phase one should also telegraph a dodgeable danger zone")
		return false
	var telegraph_point: Vector2 = attack["aim"]
	core_session.player.global_position = telegraph_point
	var zone_hp_before: float = core_session.player_hp
	core_session._update_dopamine_core_attacks(float(attack["fire_at"]), false)
	if core_session.player_hp >= zone_hp_before:
		core_session.queue_free()
		_fail("Remaining inside the final boss danger zone should deal damage")
		return false
	var damage_sequence: int = core_session.simulation.apply_damage_over_time(
			int(boss_id["index"]), int(boss_id["generation"]), 400.0, 0.05, 0.05)
	if damage_sequence <= 0 or not await _wait_for_boss_health_ratio(core_session, 0.66):
		core_session.queue_free()
		_fail("The final boss should transition into phase two after taking damage")
		return false
	core_session._entities = core_session.simulation.snapshot()["entities"]
	var now: float = float(core_session.simulation.snapshot()["simulation_time"])
	core_session._update_dopamine_core_attacks(now, false)
	attack = core_session._dopamine_core_attacks[boss_key]
	if int(attack["phase"]) != 2:
		core_session.queue_free()
		_fail("The Dopamine Core should expose its second health phase")
		return false
	core_session._update_dopamine_core_attacks(float(attack["next_attack_at"]), false)
	attack = core_session._dopamine_core_attacks[boss_key]
	if attack["pattern"] != "spiral":
		core_session.queue_free()
		_fail("Phase two should telegraph the proposed spiral pattern")
		return false
	core_session._update_dopamine_core_attacks(float(attack["fire_at"]), false)
	for _index in range(8):
		core_session._spawn_boss_summon(attack["origin"])
	if not await _wait_for_enemy_count(core_session, "summoned", core_session.summoner_max_active_summons) or \
			not await _wait_for_projectiles(core_session, core_session.final_boss_spiral_projectile_count):
		core_session.queue_free()
		_fail("Phase two should emit its spiral shots and cap adds at the configured global limit")
		return false
	for _index in range(4):
		core_session._spawn_boss_summon(attack["origin"])
	if not await _wait_for_enemy_count(core_session, "summoned", core_session.summoner_max_active_summons):
		core_session.queue_free()
		_fail("Additional phase two requests should not exceed the active summon cap")
		return false
	damage_sequence = core_session.simulation.apply_damage_over_time(
			int(boss_id["index"]), int(boss_id["generation"]), 300.0, 0.05, 0.05)
	if damage_sequence <= 0 or not await _wait_for_boss_health_ratio(core_session, 0.33):
		core_session.queue_free()
		_fail("The final boss should transition into phase three after taking damage")
		return false
	core_session._entities = core_session.simulation.snapshot()["entities"]
	now = float(core_session.simulation.snapshot()["simulation_time"])
	core_session._update_dopamine_core_attacks(now, false)
	attack = core_session._dopamine_core_attacks[boss_key]
	if int(attack["phase"]) != 3:
		core_session.queue_free()
		_fail("The Dopamine Core should expose its third health phase")
		return false
	core_session._update_dopamine_core_attacks(float(attack["next_attack_at"]), false)
	attack = core_session._dopamine_core_attacks[boss_key]
	if attack["pattern"] != "combined":
		core_session.queue_free()
		_fail("Phase three should telegraph combined attacks")
		return false
	core_session.player.global_position += Vector2(300.0, 0.0)
	var combined_hp_before: float = core_session.player_hp
	core_session._update_dopamine_core_attacks(float(attack["fire_at"]), false)
	if not is_equal_approx(core_session.player_hp, combined_hp_before) or \
			not await _wait_for_projectiles(core_session, core_session.final_boss_spiral_projectile_count * 2) or \
			not await _wait_for_enemy_count(core_session, "summoned", core_session.summoner_max_active_summons):
		core_session.queue_free()
		_fail("Phase three should combine dodgeable signals with a spiral volley without exceeding the summon cap")
		return false
	var removed_summon := _find_entity(core_session, "summoned")
	if removed_summon.is_empty():
		core_session.queue_free()
		_fail("A capped boss phase should have active summons to release")
		return false
	var removed_id: Dictionary = removed_summon["id"]
	core_session.simulation.despawn(int(removed_id["index"]), int(removed_id["generation"]))
	if not await _wait_for_enemy_count(core_session, "summoned", core_session.summoner_max_active_summons - 1):
		core_session.queue_free()
		_fail("Defeating an add should release a slot during the final boss")
		return false
	core_session._entities = core_session.simulation.snapshot()["entities"]
	core_session._spawn_boss_summon(attack["origin"])
	if not await _wait_for_enemy_count(core_session, "summoned", core_session.summoner_max_active_summons):
		core_session.queue_free()
		_fail("The final boss should use a slot freed by a defeated add")
		return false
	var core_hud: String = core_session.get_node("HUD/BossPanel/BossInfo/BossValue").text
	core_session.queue_free()
	if not core_hud.contains("DOPAMINE CORE") or not core_hud.contains("PHASE 3"):
		_fail("The boss HUD should identify the Dopamine Core and its current phase")
		return false
	return true

func _verify_chaos_boss_cadence() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	root.add_child(session)
	await process_frame
	for difficulty in ["easy", "normal", "hard", "nightmare", "chaos"]:
		session.difficulty_id = difficulty
		var attack := {"stage": "telegraph", "pattern": "radial", "pattern_index": 0,
			"normal_attack_count": 0, "chaos_followup_pending": false,
			"chaos_followup_count": 0, "is_chaos_followup": false,
			"next_attack_at": 0.0}
		session._finish_boss_attack(attack, 1.0, 2.0, 0.4)
		if bool(attack["chaos_followup_pending"]):
			session.queue_free()
			_fail("Chaos boss attacks should not chain after the first normal attack")
			return false
		session._finish_boss_attack(attack, 3.0, 2.0, 0.4)
		if difficulty == "chaos":
			if not bool(attack["chaos_followup_pending"]) or \
					not is_equal_approx(float(attack["next_attack_at"]), 3.4):
				session.queue_free()
				_fail("Chaos should schedule a telegraphed follow-up after every second normal attack")
				return false
			for patterns in [["radial", "aimed", "charge"], ["ray", "zone", "spiral"]]:
				attack["chaos_followup_pending"] = true
				attack["last_normal_pattern"] = str(patterns[0])
				if not session._schedule_chaos_followup(attack, patterns) or \
						not patterns.has(str(attack["pattern"])) or \
						str(attack["pattern"]) == str(patterns[0]):
					session.queue_free()
					_fail("Chaos should select the next distinct existing boss pattern")
					return false
			var normal_count := int(attack["normal_attack_count"])
			var normal_pattern_index := int(attack["pattern_index"])
			session._finish_boss_attack(attack, 3.8, 2.0, 0.4)
			if int(attack["normal_attack_count"]) != normal_count or \
					int(attack["pattern_index"]) != normal_pattern_index:
				session.queue_free()
				_fail("A Chaos follow-up should not count as a normal attack")
				return false
		elif bool(attack["chaos_followup_pending"]):
			session.queue_free()
			_fail("Easy through Nightmare must keep their existing boss cadence")
			return false
	if not _verify_chaos_attack_integration(session, "mid_boss") or \
			not _verify_chaos_attack_integration(session, "final_boss"):
		session.queue_free()
		_fail("Both Survival bosses should schedule and pause their Chaos follow-up telegraphs")
		return false
	session.queue_free()
	return true

func _verify_chaos_attack_integration(session: Node2D, boss_type: String) -> bool:
	session.difficulty_id = "chaos"
	session.pulse_warden_attack_interval_seconds = 0.1
	session.pulse_warden_telegraph_seconds = 0.1
	session.final_boss_attack_interval_seconds = 0.1
	session.final_boss_telegraph_seconds = 0.1
	var components := {"EnemyType": boss_type, "Health": {"current": 100.0, "maximum": 100.0},
		"Transform2D": {"x": 0.0, "y": -300.0}}
	var entity := {"id": {"index": 2000, "generation": 1}, "components": components}
	session._entities = [entity]
	var boss_key: String = session._entity_key(2000, 1)
	var update_boss := Callable(session, "_update_pulse_warden_attacks") if boss_type == "mid_boss" else \
			Callable(session, "_update_dopamine_core_attacks")
	update_boss.call(0.0, false)
	var attacks: Dictionary = session._pulse_warden_attacks if boss_type == "mid_boss" else session._dopamine_core_attacks
	var attack: Dictionary = attacks[boss_key]
	for normal_attack_index in range(2):
		update_boss.call(float(attack["next_attack_at"]), false)
		attack = attacks[boss_key]
		if str(attack["stage"]) != "telegraph":
			return false
		update_boss.call(float(attack["fire_at"]), false)
		attack = attacks[boss_key]
		if int(attack["normal_attack_count"]) != normal_attack_index + 1:
			return false
	if not bool(attack["chaos_followup_pending"]):
		return false
	update_boss.call(float(attack["next_attack_at"]), false)
	attack = attacks[boss_key]
	var expected_followup := "aimed" if boss_type == "mid_boss" else "spiral"
	if str(attack["stage"]) != "telegraph" or str(attack["pattern"]) != expected_followup:
		return false
	var stage_before_pause := str(attack["stage"])
	var pattern_before_pause := str(attack["pattern"])
	update_boss.call(float(attack["fire_at"]) + 1.0, true)
	if str(attack["stage"]) != stage_before_pause or str(attack["pattern"]) != pattern_before_pause:
		return false
	if boss_type == "final_boss":
		for summon_index in range(2):
			session._entities.append({"id": {"index": 3000 + summon_index, "generation": 1},
				"components": {"EnemyType": "summoned"}})
		update_boss.call(float(attack["fire_at"]), false)
		if str(attack["stage"]) != "spiral" or session._pending_summon_sequences.size() != 1:
			return false
		session._spawn_boss_summon(Vector2.ZERO)
		return session._pending_summon_sequences.size() == 1
	return true

func _find_entity(session: Node2D, enemy_type: String) -> Dictionary:
	for entity in session.simulation.snapshot()["entities"]:
		if entity["components"].get("EnemyType", "") == enemy_type:
			return entity
	return {}

func _wait_for_boss_health_ratio(session: Node2D, maximum_ratio: float) -> bool:
	var deadline := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var boss := _find_entity(session, "final_boss")
		if not boss.is_empty():
			var health: Dictionary = boss["components"]["Health"]
			if float(health["current"]) / float(health["maximum"]) <= maximum_ratio:
				return true
	return false

func _wait_for_enemy_count(session: Node2D, enemy_type: String, expected: int) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var count := 0
		for entity in session.simulation.snapshot()["entities"]:
			var components: Dictionary = entity["components"]
			if not components.get("IsProjectile", false) and components.get("EnemyType", "") == enemy_type:
				count += 1
		if count == expected:
			return true
	return false
