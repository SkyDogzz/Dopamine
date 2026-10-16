extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	if session._elite_affix_for_roll(0.1) != "Hasted" or session._elite_affix_for_roll(0.3) != "Armored" or \
			session._elite_affix_for_roll(0.6) != "Regenerating" or session._elite_affix_for_roll(0.9) != "Volatile":
		_fail("Elite roll should select all four supported affixes at their thresholds")
		return
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = true
	session.skip_starting_weapon_choice = true
	session.elite_spawn_interval_seconds = 20.0
	session.elite_spawn_chance = 1.0
	session.elite_chest_drop_chance = 1.0
	root.add_child(session)
	await process_frame
	if session.simulation.spawn_enemy("elite", 1, Vector2.ZERO, Vector2.ZERO, 1.0, "Shielded") != 0:
		_fail("Elite spawn should reject an affix that has no gameplay implementation")
		return
	if session.simulation.spawn_enemy("chaser", 1, Vector2.ZERO, Vector2.ZERO, 1.0, "Hasted") != 0:
		_fail("Non-elite families should reject elite-only affixes")
		return
	if not await _wait_until(func() -> bool: return not session.simulation.snapshot()["paused"]):
		_fail("Elite test session should start its simulation")
		return
	session.player_active_time = 20.0
	session._next_elite_spawn_time = 20.0
	session._advance_wave_director(0.0, false)
	if not await _wait_until(func() -> bool:
		for entity in session.simulation.snapshot()["entities"]:
			if entity["components"]["EnemyType"] == "elite":
				return true
		return false
	):
		_fail("Elite director should spawn a Hasted elite when its cooldown is ready")
		return
	var elite: Dictionary = {}
	for entity in session.simulation.snapshot()["entities"]:
		if entity["components"]["EnemyType"] == "elite":
			elite = entity
			break
	var components: Dictionary = elite["components"]
	var affix: String = str(components.get("Affix", ""))
	var valid_hasted := affix == "Hasted" and is_equal_approx(float(components["MoveSpeed"]), 100.0)
	var valid_armored := affix == "Armored" and is_equal_approx(float(components["MoveSpeed"]), 75.0) and \
			is_equal_approx(float(components["DamageTakenMultiplier"]), 0.65)
	var valid_regenerating := affix == "Regenerating" and is_equal_approx(float(components["HealthRegenPerSecond"]),
			float(components["Health"]["maximum"]) * 0.01)
	var valid_volatile := affix == "Volatile" and is_equal_approx(float(components["DeathExplosionRadius"]), 82.0) and \
			is_equal_approx(float(components["DeathExplosionDamage"]), 18.0)
	if not valid_hasted and not valid_armored and not valid_regenerating and not valid_volatile:
		_fail("Elite snapshot should expose a working Hasted, Armored, Regenerating or Volatile affix")
		return
	session._try_spawn_elite()
	await process_frame
	var elite_count := 0
	for entity in session.simulation.snapshot()["entities"]:
		if entity["components"]["EnemyType"] == "elite":
			elite_count += 1
	if elite_count != 1:
		_fail("Elite threat budget should allow only one active elite")
		return
	session._entities = []
	for index in range(8):
		session._entities.append({"components": {
			"EnemyType": "chaser",
			"ThreatLevel": 1.0,
		}})
	session.player_active_time = 30.0
	session._next_elite_spawn_time = 30.0
	session._try_spawn_elite()
	if session._next_elite_spawn_time != 30.0:
		_fail("Elite should wait when the wave threat budget is already full")
		return
	session._entities = session.simulation.snapshot()["entities"]
	session.player_active_time = 20.0
	var pause_sequence: int = session.simulation.pause()
	if not await _wait_until(func() -> bool:
		return session.simulation.snapshot()["paused"] and \
				int(session.simulation.snapshot()["last_sequence"]) >= pause_sequence
	):
		_fail("Simulation should pause before the deterministic elite kill")
		return
	var transform: Dictionary = components["Transform2D"]
	var projectile_sequence: int = session.simulation.spawn_projectile(
		"elite_smoke_bolt", Vector2(float(transform["x"]), float(transform["y"])),
		Vector2.ZERO, 1000.0, 32.0, 1.0
	)
	if not await _wait_until(func() -> bool:
		return int(session.simulation.snapshot()["last_sequence"]) >= projectile_sequence
	):
		_fail("Test projectile should reach the simulation")
		return
	var step_sequence: int = session.simulation.step(0.01)
	if not await _wait_until(func() -> bool:
		return int(session.simulation.snapshot()["last_sequence"]) >= step_sequence
	):
		_fail("Deterministic elite kill step should complete")
		return
	if not await _wait_until(func() -> bool: return session.kill_count == 1):
		_fail("Elite death should enter the ordinary kill reward path")
		return
	if session._world_chests.is_empty():
		_fail("Guaranteed elite chest setting should produce a reward")
		return
	print("Survival elite smoke passed")
	quit()

func _wait_until(predicate: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if predicate.call():
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
