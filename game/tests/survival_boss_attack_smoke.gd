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
	session._update_pulse_warden_attacks(session.pulse_warden_attack_interval_seconds, false)
	var attack: Dictionary = session._pulse_warden_attacks[boss_key]
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
	var deadline := Time.get_ticks_msec() + 1500
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

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
