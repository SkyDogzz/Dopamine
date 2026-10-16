extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	session.xp_collection_radius = 0.0
	session.ordinary_chest_drop_chance = 0.0
	root.add_child(session)
	await process_frame
	session._health_locked = true

	# A direct lethal impact must produce one death and one XP reward.
	session.simulation.spawn("causality_direct", 1, Vector2(80.0, 0.0), 5.0, Vector2.ZERO, 1.0)
	session.simulation.spawn_projectile("test_weapon", Vector2.ZERO, Vector2(1200.0, 0.0), 10.0, 3.0, 1.0)
	if not await _wait_for_counts(session, 1, 1):
		_fail("A direct lethal impact should award one kill and one XP orb")
		return
	await create_timer(0.15).timeout
	if session.kill_count != 1 or _xp_orb_count(session) != 1:
		_fail("Direct damage events must not credit the same death twice")
		return

	# The final DoT tick is also lethal; its damage and death remain one kill.
	session.simulation.spawn("causality_dot", 1, Vector2(80.0, 0.0), 4.0, Vector2.ZERO, 1.0)
	session.simulation.spawn_projectile("inferno_sprayer", Vector2.ZERO, Vector2(1200.0, 0.0),
		1.0, 3.0, 1.0, 10.0, 0.05, 0.2)
	if not await _wait_for_counts(session, 2, 2):
		_fail("A lethal DoT should award one kill and one XP orb (kills=%d xp=%d entities=%s)" % [
			session.kill_count, _xp_orb_count(session), str(session.simulation.snapshot()["entities"]),
		])
		return
	await create_timer(0.15).timeout
	if session.kill_count != 2 or _xp_orb_count(session) != 2:
		_fail("A lethal DoT event must not duplicate death or XP credit")
		return

	session.queue_free()
	await process_frame
	print("Survival damage causality smoke passed")
	quit()

func _wait_for_counts(session: Node2D, kills: int, xp_orbs: int) -> bool:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if session.kill_count == kills and _xp_orb_count(session) == xp_orbs:
			return true
	return false

func _xp_orb_count(session: Node2D) -> int:
	var count := 0
	for entity in session.simulation.snapshot()["entities"]:
		if bool(entity["components"].get("IsXpOrb", false)):
			count += 1
	return count

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
