extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	session.get_node("HUD/ChestOverlay/ChestChoice/Content/Options/Choice0").emit_signal("pressed")
	if not await _wait_until(func() -> bool: return session.player.controls_enabled):
		_fail("Choosing a starting weapon should start the simulation")
		return

	session.player.global_position = Vector2.ZERO
	session._entities = [{"id": {"index": 900, "generation": 1}, "components": {
		"EnemyType": "shooter",
		"Transform2D": {"x": 200.0, "y": 0.0},
	}}]
	session._update_shooter_attacks(1.0, false)
	var key: String = session._entity_key(900, 1)
	if not session._shooter_attacks.has(key) or session._shooter_attacks[key]["phase"] != "telegraph":
		_fail("Shooter should telegraph its aimed shot before firing")
		return
	var fire_at: float = session._shooter_attacks[key]["fire_at"]
	session._update_shooter_attacks(fire_at + 1.0, true)
	if session._shooter_attacks[key]["fire_at"] != fire_at:
		_fail("Shooter attacks should stop while the simulation is paused")
		return
	session._update_shooter_attacks(fire_at, false)
	if not await _wait_until(func() -> bool:
		for entity in session.simulation.snapshot()["entities"]:
			var components: Dictionary = entity["components"]
			if components.get("IsProjectile", false) and components.get("EnemyType", "") == "enemy_projectile":
				return true
		return false
	):
		_fail("Shooter should create a moving enemy projectile after its telegraph")
		return
	var spawned_projectile: Dictionary = {}
	for entity in session.simulation.snapshot()["entities"]:
		var candidate_components: Dictionary = entity["components"]
		if candidate_components.get("IsProjectile", false) and candidate_components.get("EnemyType", "") == "enemy_projectile":
			spawned_projectile = entity
			break
	var components: Dictionary = spawned_projectile["components"]
	var velocity: Dictionary = components["Velocity2D"]
	if float(velocity["x"]) >= 0.0:
		_fail("Shooter projectile should travel toward the position shown by its telegraph")
		return
	var projectile_transform: Dictionary = components["Transform2D"]
	session.player.global_position = Vector2(float(projectile_transform["x"]), float(projectile_transform["y"]))
	session._entities = [spawned_projectile]
	session.player_hp = 100.0
	session._contact_damage_until.clear()
	session._apply_contact_damage({"paused": false}, 10.0)
	if not is_equal_approx(session.player_hp, 100.0 - float(components["Projectile"]["damage"])):
		_fail("Enemy projectile should damage the player when its collision reaches them")
		return
	session.simulation.pause()
	print("Survival shooter smoke passed")
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
