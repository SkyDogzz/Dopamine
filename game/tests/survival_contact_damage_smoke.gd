extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	if session.player.controls_enabled or not session.simulation.snapshot()["paused"]:
		_fail("Starting weapon choice should pause simulation and player controls")
		return
	session.get_node("HUD/ChestOverlay/ChestChoice/Content/Options/Choice0").emit_signal("pressed")
	if not await _wait_until(func() -> bool: return session.player.controls_enabled):
		_fail("Choosing a starting weapon should resume player controls")
		return
	session.player.global_position = Vector2.ZERO
	session.player_hp = 100.0
	session._entities = [{"components": {
		"EnemyType": "inferno_sprayer",
		"IsProjectile": true,
		"Transform2D": {"x": 14.0, "y": 0.0},
	}}]
	session._apply_contact_damage({"paused": false}, 5.0)
	if not is_equal_approx(session.player_hp, 100.0):
		_fail("Friendly projectiles near the player must not cause contact damage")
		return
	session._entities = [{"components": {
		"EnemyType": "xp_orb",
		"IsXpOrb": true,
		"Transform2D": {"x": 14.0, "y": 0.0},
	}}]
	session._apply_contact_damage({"paused": false}, 5.0)
	if not is_equal_approx(session.player_hp, 100.0):
		_fail("XP orbs near the player must not cause contact damage")
		return
	session._entities = [{"components": {
		"EnemyType": "chaser",
		"Transform2D": {"x": 20.0, "y": 0.0},
	}}]
	session._apply_contact_damage({"paused": false}, 5.0)
	if not is_equal_approx(session.player_hp, 100.0):
		_fail("Enemy contact damage should not trigger before the visible hit circles touch")
		return
	session._entities = [{"id": {"index": 7, "generation": 1}, "components": {
		"EnemyType": "chaser",
		"Transform2D": {"x": 0.0, "y": 0.0},
	}}]
	session.player_hp = 100.0
	var active_state := {"paused": false}
	session._apply_contact_damage(active_state, 10.0)
	if not is_equal_approx(session.player_hp, 90.0):
		_fail("Enemy contact should apply one proposed damage hit")
		return
	session._apply_contact_damage(active_state, 10.1)
	if not is_equal_approx(session.player_hp, 90.0):
		_fail("The same enemy should respect its body-contact cooldown")
		return
	session._entities = [{"id": {"index": 8, "generation": 1}, "components": {
		"EnemyType": "chaser", "Transform2D": {"x": 0.0, "y": 0.0},
	}}]
	session._apply_contact_damage(active_state, 10.1)
	if not is_equal_approx(session.player_hp, 80.0):
		_fail("A different enemy should have its own body-contact cooldown")
		return
	session._entities = [{"id": {"index": 9, "generation": 1}, "components": {
		"EnemyType": "enemy_projectile", "IsProjectile": true, "Transform2D": {"x": 0.0, "y": 0.0},
		"Projectile": {"damage": 7.0, "radius": 2.0},
	}}]
	session._apply_contact_damage(active_state, 10.11)
	if not is_equal_approx(session.player_hp, 73.0):
		_fail("An enemy projectile should not be blocked by a body-contact cooldown")
		return
	session._entities = [{"id": {"index": 7, "generation": 1}, "components": {
		"EnemyType": "chaser", "Transform2D": {"x": 0.0, "y": 0.0},
	}}]
	session._apply_contact_damage(active_state, 10.36)
	if not is_equal_approx(session.player_hp, 63.0):
		_fail("The first enemy should damage again after its own contact cooldown expires")
		return
	session.simulation.pause()
	if not await _wait_until(func() -> bool:
		return session.simulation.snapshot()["paused"] and not session.player.controls_enabled
	):
		_fail("Pausing the simulation should disable player controls")
		return
	session.simulation.resume()
	if not await _wait_until(func() -> bool: return session.player.controls_enabled):
		_fail("Resuming the simulation should enable player controls")
		return
	session._finish_run(false)
	await process_frame
	if session.player.controls_enabled:
		_fail("Ending a run should disable player controls")
		return
	print("Survival contact damage smoke passed")
	quit()

func _wait_until(predicate: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if predicate.call():
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
