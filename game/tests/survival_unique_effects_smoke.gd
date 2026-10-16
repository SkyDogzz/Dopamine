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
	if session.simulation == null:
		_fail("Survival combat simulation should initialize")
		return
	if not await _wait_for_simulation_running(session):
		_fail("Survival session should start before the unique-effect checks")
		return
	var enemy_sequence: int = session.simulation.spawn_enemy("chaser", 1, Vector2(40.0, 0.0), Vector2.ZERO)
	if not await _wait_for_sequence(session.simulation, enemy_sequence):
		_fail("Lightning Burst target should spawn")
		return
	var pause_sequence: int = session.simulation.pause()
	if not await _wait_for_sequence(session.simulation, pause_sequence):
		_fail("Unique-effect checks should run against a paused simulation")
		return
	session._entities = session.simulation.snapshot()["entities"]
	session.player_active_time = 0.0
	var success_seed := _seed_for_lightning_success()
	if success_seed < 1:
		_fail("Could not find a deterministic Lightning Burst success seed")
		return
	session._cached_unique_effects.clear()
	seed(success_seed)
	session._try_unique_lightning_burst(100.0)
	if session._next_unique_lightning_time != 0.0 or _count_projectiles(session, "unique_lightning_burst") != 0:
		_fail("Lightning Burst must stay inactive unless its unique effect is equipped")
		return
	session._cached_unique_effects.append("lightning_burst")
	seed(success_seed)
	session._try_unique_lightning_burst(100.0)
	if not await _wait_for_projectile_count(session, "unique_lightning_burst", 1) or \
			session._next_unique_lightning_time != 2.0 or \
			not session._item_level_feedback_label.text.contains("LIGHTNING BURST"):
		_fail("Equipped Lightning Burst should fire at a nearby target, set its 2-second cooldown and show feedback")
		return
	session._try_unique_lightning_burst(100.0)
	if _count_projectiles(session, "unique_lightning_burst") != 1:
		_fail("Lightning Burst should not fire again before its internal cooldown expires")
		return
	var clear_sequence: int = session.simulation.kill_all()
	if not await _wait_for_sequence(session.simulation, clear_sequence) or \
			not await _wait_for_no_entities(session):
		_fail("The nearby Lightning Burst target should clear before the range check")
		return
	var distant_sequence: int = session.simulation.spawn_enemy("chaser", 1, Vector2(300.0, 0.0), Vector2.ZERO)
	if not await _wait_for_sequence(session.simulation, distant_sequence):
		_fail("Distant range-check target should spawn")
		return
	session._entities = session.simulation.snapshot()["entities"]
	session.player_active_time = 2.0
	seed(success_seed)
	session._try_unique_lightning_burst(100.0)
	if session._next_unique_lightning_time != 2.0 or _count_projectiles(session, "unique_lightning_burst") != 0:
		_fail("Lightning Burst should reject targets outside its visible weapon range")
		return
	clear_sequence = session.simulation.kill_all()
	if not await _wait_for_sequence(session.simulation, clear_sequence) or \
			not await _wait_for_no_entities(session):
		_fail("Distant Lightning target should clear before the evolution check")
		return
	var evolved_target_sequence: int = session.simulation.spawn_enemy(
		"chaser", 1, Vector2(40.0, 0.0), Vector2.ZERO
	)
	if not await _wait_for_sequence(session.simulation, evolved_target_sequence):
		_fail("Evolution test target should spawn within Lightning range")
		return
	session._entities = session.simulation.snapshot()["entities"]
	session._cached_unique_effects.clear()
	session._cached_unique_effects.append("evolution_shockwave")
	session._evolution_shockwave_triggered = false
	session.loadout._weapon_levels["lightning_conductor"] = 1
	session.loadout._evolved_weapons.clear()
	session._next_weapon_time = 0.0
	session._fire_lightning_conductor(2.0, false)
	if session._evolution_shockwave_triggered or _count_projectiles(session, "evolution_shockwave") != 0:
		_fail("Evolution Shockwave must stay inactive before an evolution is acquired")
		return
	session.loadout._weapon_levels["lightning_conductor"] = 5
	session.loadout._evolved_weapons["lightning_conductor"] = true
	session._fire_lightning_conductor(3.0, false)
	if not await _wait_for_projectile_count(session, "evolution_shockwave", 8) or \
			not session._evolution_shockwave_triggered or \
			not session._item_level_feedback_label.text.contains("EVOLUTION SHOCKWAVE"):
		_fail("The first Lightning fire after evolution should create one eight-projectile shockwave and show feedback")
		return
	session._fire_lightning_conductor(4.0, false)
	if _count_projectiles(session, "evolution_shockwave") != 8:
		_fail("Evolution Shockwave should activate only once in a run")
		return
	session.queue_free()
	await process_frame
	print("survival_unique_effects_smoke: passed equipment, range, cooldown and evolution gates")
	quit(0)

func _seed_for_lightning_success() -> int:
	for seed_value in range(1, 10000):
		seed(seed_value)
		if randf() < 0.1:
			return seed_value
	return 0

func _count_projectiles(session: Node2D, projectile_type: String) -> int:
	var count := 0
	for entity in session.simulation.snapshot()["entities"]:
		if str(entity["components"].get("EnemyType", "")) == projectile_type:
			count += 1
	return count

func _wait_for_projectile_count(session: Node2D, projectile_type: String, expected: int) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		if _count_projectiles(session, projectile_type) >= expected:
			return true
		await process_frame
	return false

func _wait_for_no_entities(session: Node2D) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		if session.simulation.snapshot()["entities"].is_empty():
			return true
		await process_frame
	return false

func _wait_for_sequence(simulation: Object, sequence: int) -> bool:
	if sequence <= 0:
		return false
	var deadline := Time.get_ticks_msec() + 3000
	while int(simulation.snapshot()["last_sequence"]) < sequence and Time.get_ticks_msec() < deadline:
		await process_frame
	return int(simulation.snapshot()["last_sequence"]) >= sequence

func _wait_for_simulation_running(session: Node2D) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while bool(session.simulation.snapshot()["paused"]) and Time.get_ticks_msec() < deadline:
		await process_frame
	return not bool(session.simulation.snapshot()["paused"])

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
