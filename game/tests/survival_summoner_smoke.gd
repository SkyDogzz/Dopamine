extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.summoner_max_active_summons = 3
	session.summoner_warmup_seconds = 0.5
	root.add_child(session)
	if not await _wait_until(func() -> bool: return session.player.controls_enabled):
		_fail("Survival should be ready before the Summoner scenario")
		return
	session.player_hp = 10000.0
	session.simulation.set_speed(0.25)
	var summon_positions := [Vector2(100.0, -120.0), Vector2(0.0, 0.0), Vector2(100.0, 120.0), Vector2(200.0, 0.0)]
	for position in summon_positions:
		if session.simulation.spawn_enemy("summoner", 1, position, Vector2.ZERO) <= 0:
			_fail("Survival should accept the Summoner profile")
			return
	if not await _wait_until(func() -> bool: return _count_enemy_type(session.simulation.snapshot()["entities"], "summoner") == 4):
		_fail("All Summoners should appear in the combat snapshot")
		return
	var entities: Array = session.simulation.snapshot()["entities"]
	session._entities = entities
	session._summoner_attacks.clear()
	var now := float(session.simulation.snapshot()["simulation_time"])
	session._update_summoner_attacks(now, false)
	if session._summoner_attacks.size() != 4:
		_fail("Each Summoner should expose a visible pending spawn telegraph")
		return
	for entity in entities:
		if entity["components"].get("EnemyType", "") != "summoner":
			continue
		var id: Dictionary = entity["id"]
		var key: String = session._entity_key(int(id["index"]), int(id["generation"]))
		var transform: Dictionary = entity["components"]["Transform2D"]
		var origin := Vector2(float(transform["x"]), float(transform["y"]))
		var spawn_position: Vector2 = session._summoner_attacks[key]["spawn_position"]
		if not is_equal_approx(origin.distance_to(spawn_position), session.summoner_spawn_radius):
			_fail("Summoner telegraph should mark the planned spawn location at its configured range")
			return
	var renderer: RefCounted = load("res://scripts/sprite_batch_renderer.gd").new()
	renderer.set_entities(entities)
	if renderer._batches["enemy_summoner"]["texture"] == null:
		_fail("Summoner should use its dedicated sprite")
		return
	var pause_deadlines: Dictionary = {}
	for key in session._summoner_attacks:
		pause_deadlines[key] = session._summoner_attacks[key]["summon_at"]
	session._update_summoner_attacks(now + 100.0, true)
	for key in pause_deadlines:
		if session._summoner_attacks[key]["summon_at"] != pause_deadlines[key]:
			_fail("Summon telegraphs should freeze during pause")
			return
	session._update_summoner_attacks(now + 0.6, false)
	if not await _wait_until(func() -> bool:
		return _count_enemy_type(session.simulation.snapshot()["entities"], "summoned") == 3
	):
		_fail("Four simultaneous Summoners should respect the global cap of three active summons")
		return
	entities = session.simulation.snapshot()["entities"]
	session._entities = entities
	renderer.set_entities(entities)
	if renderer._batches["enemy_summoned"]["texture"] == null or \
			renderer.animated_instance_count_for_role("enemy_summoned") != 3:
		_fail("Summoned adds should use their dedicated visible sprite")
		return
	session._update_summoner_attacks(now + 20.0, false)
	await create_timer(0.1).timeout
	if _count_enemy_type(session.simulation.snapshot()["entities"], "summoned") != 3:
		_fail("A full summon cap should prevent additional spawns")
		return
	var removed_summon: Dictionary = {}
	for entity in entities:
		if entity["components"].get("EnemyType", "") == "summoned":
			removed_summon = entity
			break
	var removed_id: Dictionary = removed_summon["id"]
	session.simulation.despawn(int(removed_id["index"]), int(removed_id["generation"]))
	if not await _wait_until(func() -> bool:
		return _count_enemy_type(session.simulation.snapshot()["entities"], "summoned") == 2
	):
		_fail("Despawned summons should release their active slot")
		return
	session._entities = session.simulation.snapshot()["entities"]
	session._update_summoner_attacks(now + 21.0, false)
	if not await _wait_until(func() -> bool:
		return _count_enemy_type(session.simulation.snapshot()["entities"], "summoned") == 3
	):
		_fail("A freed summon slot should allow one pending Summoner to spawn")
		return
	session.simulation.pause()
	print("Survival Summoner smoke passed")
	quit()

func _count_enemy_type(entities: Array, enemy_type: String) -> int:
	var count := 0
	for entity in entities:
		var components: Dictionary = entity["components"]
		if not components.get("IsProjectile", false) and components.get("EnemyType", "") == enemy_type:
			count += 1
	return count

func _wait_until(predicate: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if predicate.call():
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
