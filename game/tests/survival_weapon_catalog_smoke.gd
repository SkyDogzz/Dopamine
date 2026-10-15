extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not await _weapon_kills_target("lightning_conductor", "storm_core", 12.4):
		_fail("Storm Core should boost Lightning Conductor enough to defeat the test target")
		return
	if not await _weapon_kills_target("inferno_sprayer", "infernal_heart", 8.2):
		_fail("Infernal Heart should boost Inferno Sprayer enough to defeat the test target")
		return
	if not await _weapon_kills_target("crimson_daggers", "blood_chalice", 13.0):
		_fail("Crimson Daggers should hit with both prototype projectiles")
		return
	if not await _blood_chalice_boosts_kill_heal():
		_fail("Blood Chalice should increase the proposed kill healing")
		return
	print("Survival weapon catalog smoke passed")
	quit()

func _weapon_kills_target(weapon_id: String, relic_id: String, target_hp: float) -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	if not session.has_method("open_chest_family"):
		return false
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	root.add_child(session)
	await process_frame
	if not session.loadout.apply_offer("weapon:" + weapon_id):
		session.queue_free()
		return false
	if not session.loadout.apply_offer("relic:" + relic_id):
		session.queue_free()
		return false
	session.weapon_enabled = true
	session.lightning_cooldown = 1000.0
	session.ordinary_chest_drop_chance = 0.0
	session.xp_collection_radius = 0.0
	session.simulation.set_speed(4.0)
	session.simulation.spawn("test_target", 1, Vector2(180.0, 0.0), target_hp, Vector2.ZERO)
	var spawned := false
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var state: Dictionary = session.simulation.snapshot()
		for entity in state["entities"]:
			if entity["components"].get("EnemyType", "") == "test_target":
				spawned = true
				break
		if spawned and int(state["metrics"]["collision_count"]) > 0 and not _contains_enemy(state, "test_target"):
			session.queue_free()
			return true
	session.queue_free()
	return false

func _contains_enemy(state: Dictionary, enemy_type: String) -> bool:
	for entity in state["entities"]:
		if entity["components"].get("EnemyType", "") == enemy_type:
			return true
	return false

func _blood_chalice_boosts_kill_heal() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.ordinary_chest_drop_chance = 0.0
	session.xp_collection_radius = 0.0
	root.add_child(session)
	await process_frame
	session.player_hp = 50.0
	if not session.loadout.apply_offer("relic:blood_chalice"):
		session.queue_free()
		return false
	session.simulation.set_speed(4.0)
	session.simulation.spawn_enemy("chaser", 1, Vector2(20.0, 0.0), Vector2.ZERO)
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if not session.simulation.snapshot()["entities"].is_empty():
			break
	session.simulation.spawn_projectile("test", Vector2.ZERO, Vector2(1000.0, 0.0), 30.0, 3.0, 1.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if session.player_hp > 55.2:
			session.queue_free()
			return true
	session.queue_free()
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
