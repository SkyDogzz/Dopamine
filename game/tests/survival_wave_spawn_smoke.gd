extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	if session._wave_population(24) != 400:
		_fail("Wave population should retain its proposed curve without a hard ceiling")
		return
	if not is_equal_approx(session._wave_enemy_spawn_interval(), 0.5):
		_fail("Normal difficulty should preserve the configured wave spawn interval")
		return
	session.difficulty_id = "chaos"
	if not is_equal_approx(session._wave_enemy_spawn_interval(), 0.5 / 1.8):
		_fail("Difficulty density should scale the continuous spawn interval")
		return
	session.difficulty_id = "normal"
	root.add_child(session)
	await process_frame
	session.set_process(false)
	session.set_physics_process(false)
	session._entities.clear()
	for _index in range(session._wave_population(1)):
		session._entities.append({"components": {"EnemyType": "chaser"}})
	session._spawn_wave_enemy()
	var deadline := Time.get_ticks_msec() + 1000
	var state: Dictionary = session.simulation.snapshot()
	while Time.get_ticks_msec() < deadline:
		state = session.simulation.snapshot()
		if _active_enemy_count(state["entities"]) > 0:
			break
		await process_frame
	if _active_enemy_count(state["entities"]) == 0:
		_fail("A full first-wave population must not stop subsequent enemy spawns")
		return
	if _active_enemy_count(state["entities"]) != 1:
		_fail("The spawn attempt above the former first-wave cap should add one enemy")
		return
	print("Survival wave spawn smoke passed")
	quit()

func _active_enemy_count(entities: Array) -> int:
	var count := 0
	for entity in entities:
		var components: Dictionary = entity["components"]
		if not components.get("IsProjectile", false) and not components.get("IsXpOrb", false):
			count += 1
	return count

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
