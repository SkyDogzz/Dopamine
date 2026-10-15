extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var simulation = ClassDB.instantiate("CombatSimulation")
	if simulation == null or simulation.spawn_enemy("exploder", 1, Vector2.ZERO, Vector2.ZERO) <= 0:
		_fail("Exploder should have a registered Survival profile")
		return
	var renderer: RefCounted = load("res://scripts/sprite_batch_renderer.gd").new()
	if renderer._batches["enemy_exploder"]["texture"] == null or \
			renderer._sprite_for_entity({"EnemyType": "exploder"}) != "enemy_exploder":
		_fail("Exploder should use its dedicated visible sprite")
		return
	if not await _wait_until(func() -> bool:
		for entity in simulation.snapshot()["entities"]:
			if entity["components"].get("EnemyType", "") == "exploder":
				return true
		return false
	):
		_fail("Exploder profile should be accepted by the combat simulation")
		return
	simulation.reset()
	await process_frame
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	root.add_child(session)
	if not await _wait_until(func() -> bool: return session.player.controls_enabled):
		_fail("Survival session should be ready for exploder behavior checks")
		return
	session.player.global_position = Vector2.ZERO
	session.player_hp = 50.0
	var entity := {"id": {"index": 900, "generation": 1}, "components": {
		"EnemyType": "exploder", "Transform2D": {"x": 60.0, "y": 0.0}
	}}
	session._entities = [entity]
	session._update_exploder_attacks(10.0, false)
	var key: String = session._entity_key(900, 1)
	if not session._exploder_attacks.has(key):
		_fail("Exploder should start a proximity fuse inside its trigger radius")
		return
	var detonate_at: float = session._exploder_attacks[key]["detonate_at"]
	session._update_exploder_attacks(detonate_at + 1.0, true)
	if session.player_hp != 50.0 or not session._exploder_attacks.has(key):
		_fail("Exploder fuse and blast should remain frozen during pause")
		return
	session._update_exploder_attacks(detonate_at, false)
	var kill_heal: float = float(session.simulation.kill_heal_amount(2.0))
	var hp_after_blast: float = 50.0 - session.exploder_damage + kill_heal
	if not is_equal_approx(session.player_hp, hp_after_blast) or \
			str(session._exploder_attacks[key].get("phase", "")) != "detonated" or session.kill_count != 1:
		_fail("Exploder should damage a nearby player once when its visible fuse ends")
		return
	session._update_exploder_attacks(detonate_at + 0.1, false)
	if not is_equal_approx(session.player_hp, hp_after_blast) or session.kill_count != 1:
		_fail("A stale Exploder snapshot should not award repeated blast damage or rewards")
		return
	entity["id"]["index"] = 901
	entity["components"]["Transform2D"] = {"x": 60.0, "y": 0.0}
	session.player.global_position = Vector2.ZERO
	session._entities = [entity]
	session._update_exploder_attacks(20.0, false)
	var escape_key: String = session._entity_key(901, 1)
	var escape_at: float = session._exploder_attacks[escape_key]["detonate_at"]
	session.player.global_position = Vector2(200.0, 0.0)
	session._update_exploder_attacks(escape_at, false)
	if not is_equal_approx(session.player_hp, hp_after_blast + kill_heal) or session.kill_count != 2:
		_fail("Player should be able to dodge an Exploder blast by leaving its radius")
		return
	session.simulation.pause()
	print("Survival Exploder smoke passed")
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
