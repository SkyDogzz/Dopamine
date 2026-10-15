extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var simulation = ClassDB.instantiate("CombatSimulation")
	assert(simulation != null, "CombatSimulation GDExtension class is unavailable")
	assert(is_equal_approx(simulation.health_decay_amount(0.0, 60.0), 97.2),
			"GDExtension decay rule should match the proposed first-minute GDD example")
	assert(is_equal_approx(simulation.health_decay_amount(0.0, 720.0), 2116.8),
			"GDExtension decay rule should match the proposed twelve-minute GDD example")
	assert(is_equal_approx(simulation.kill_heal_amount(1.0), 5.0),
			"GDExtension kill heal rule should match the proposed ordinary enemy value")
	assert(is_equal_approx(simulation.kill_heal_amount(100.0), 17.0),
			"GDExtension kill heal rule should clamp to the proposed maximum threat")
	assert(is_equal_approx(simulation.initial_player_hp(), 100.0),
			"GDExtension should expose the GDD-validated initial player HP")
	assert(simulation.spawn_enemy("not_an_enemy", 1, Vector2.ZERO, Vector2.ZERO) == 0,
			"GDExtension should reject unknown enemy profiles")
	var profile_sequence: int = simulation.spawn_enemy("chaser", 1, Vector2.ZERO, Vector2(0.0, 1.0))
	var profile_state: Dictionary = await _wait_for_sequence(simulation, profile_sequence)
	assert(is_equal_approx(profile_state["entities"][0]["components"]["Health"]["maximum"], 20.0))
	assert(is_equal_approx(profile_state["entities"][0]["components"]["Velocity2D"]["y"], 75.0))
	assert(is_equal_approx(profile_state["entities"][0]["components"]["MoveSpeed"], 75.0))
	var clear_profiles: int = simulation.kill_all()
	await _wait_for_sequence(simulation, clear_profiles)
	var scaled_profile_sequence: int = simulation.spawn_enemy("sprinter", 1, Vector2.ZERO, Vector2.ZERO, 2.0)
	var scaled_profile_state: Dictionary = await _wait_for_sequence(simulation, scaled_profile_sequence)
	assert(simulation.spawn_enemy("sprinter", 1, Vector2.ZERO, Vector2.ZERO, 0.0) == 0,
		"GDExtension should reject a non-positive typed enemy health multiplier")
	assert(simulation.spawn_enemy("sprinter", 1, Vector2.ZERO, Vector2.ZERO, INF) == 0,
		"GDExtension should reject a non-finite typed enemy health multiplier")
	assert(is_equal_approx(scaled_profile_state["entities"][0]["components"]["Health"]["maximum"], 24.0),
		"GDExtension should scale typed enemy health without losing its profile")
	assert(is_equal_approx(scaled_profile_state["entities"][0]["components"]["MoveSpeed"], 125.0),
		"GDExtension should retain typed enemy movement speed with scaled health")
	await _wait_for_sequence(simulation, simulation.kill_all())
	assert(simulation.spawn("", 1, Vector2.ZERO, 10.0, Vector2.ZERO) == 0)
	assert(simulation.set_speed(10.0) == 0)
	var override_sequence: int = simulation.apply_sandbox_overrides({
		"max_speed": 42.0,
		"separation_radius": 24.0,
		"separation_weight": 0.75,
		"cell_size": 48.0,
	})
	var override_state: Dictionary = await _wait_for_sequence(simulation, override_sequence)
	assert(override_state["sandbox_overrides"] == {
		"max_speed": 42.0,
		"separation_radius": 24.0,
		"separation_weight": 0.75,
		"cell_size": 48.0,
	}, "GDExtension should publish committed Sandbox overrides")
	assert(simulation.apply_sandbox_overrides({
		"max_speed": 80.0,
		"separation_radius": 30.0,
		"separation_weight": 1.5,
		"cell_size": 32.0,
	}) == 0, "GDExtension should reject an invalid override transaction")
	assert(simulation.snapshot()["sandbox_overrides"] == override_state["sandbox_overrides"],
		"Rejected GDExtension overrides should leave the effective config unchanged")
	assert(simulation.apply_sandbox_overrides({
		"max_speed": "fast",
		"separation_radius": 18.0,
		"separation_weight": 0.5,
		"cell_size": 64.0,
	}) == 0, "GDExtension should reject non-numeric override values")
	var clear_tuning_sequence: int = simulation.reset()
	await _wait_for_sequence(simulation, clear_tuning_sequence)

	var spawn_sequence: int = simulation.spawn("chaser", 1, Vector2(1.0, 2.0), 10.0, Vector2(2.0, 0.0))
	var state: Dictionary = await _wait_for_sequence(simulation, spawn_sequence)
	assert(state["entities"].size() == 1)
	var entity_id: Dictionary = state["entities"][0]["id"]
	var initial_position: Dictionary = state["entities"][0]["components"]["Transform2D"]

	var speed_sequence: int = simulation.set_speed(2.0)
	await _wait_for_sequence(simulation, speed_sequence)
	var step_sequence: int = simulation.step(0.25)
	state = await _wait_for_sequence(simulation, step_sequence)
	assert(is_equal_approx(state["simulation_time"], 0.5))
	assert(is_equal_approx(state["entities"][0]["components"]["Transform2D"]["x"], 2.0))
	assert(is_equal_approx(initial_position["x"], 1.0), "Older GDScript snapshots should keep their values")

	var pause_sequence: int = simulation.pause()
	state = await _wait_for_sequence(simulation, pause_sequence)
	assert(state["paused"])
	assert(simulation.step(0.0) == 0)

	var despawn_sequence: int = simulation.despawn(entity_id["index"], entity_id["generation"])
	state = await _wait_for_sequence(simulation, despawn_sequence)
	assert(state["entities"].is_empty())

	var respawn_sequence: int = simulation.spawn("tank", 2, Vector2.ZERO, 20.0, Vector2.ZERO)
	state = await _wait_for_sequence(simulation, respawn_sequence)
	assert(state["entities"].size() == 2)
	var kill_sequence: int = simulation.kill_all()
	state = await _wait_for_sequence(simulation, kill_sequence)
	assert(state["entities"].is_empty())

	var reset_spawn_sequence: int = simulation.spawn("chaser", 1, Vector2.ZERO, 10.0, Vector2.ZERO)
	await _wait_for_sequence(simulation, reset_spawn_sequence)
	var reset_sequence: int = simulation.reset()
	state = await _wait_for_sequence(simulation, reset_sequence)
	assert(state["entities"].is_empty())
	assert(state["simulation_time"] == 0.0)
	assert(state["speed_multiplier"] == 1.0)
	assert(state["paused"])
	assert(state["sandbox_overrides"]["max_speed"] == 75.0,
		"Reset should restore the default Sandbox steering configuration")
	print("Sandbox simulation bridge checks passed")
	quit()

func _wait_for_sequence(simulation: Object, sequence: int) -> Dictionary:
	assert(sequence > 0, "Simulation worker rejected command")
	var deadline := Time.get_ticks_msec() + 1000
	var state: Dictionary = simulation.snapshot()
	while state["last_sequence"] < sequence and Time.get_ticks_msec() < deadline:
		await process_frame
		state = simulation.snapshot()
	assert(state["last_sequence"] >= sequence, "Simulation worker timed out")
	return state
