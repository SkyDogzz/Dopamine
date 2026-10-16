extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	root.add_child(session)
	await process_frame
	if not is_equal_approx(session.wave_duration_seconds, 30.0):
		_fail("The default Survival wave duration should remain 30 seconds")
		return
	var speed_sequence: int = session.simulation.set_speed(4.0)
	if not await _wait_for_sequence(session.simulation, speed_sequence):
		_fail("Simulation worker did not accept ×4 speed")
		return
	var starting_simulation_time: float = session._last_simulation_time
	var starting_wave_elapsed: float = session.wave_director.elapsed_in_wave
	var remaining_wave_seconds: float = session.wave_duration_seconds - starting_wave_elapsed
	var started_at_msec := Time.get_ticks_msec()
	var deadline := started_at_msec + 12000
	while session.wave_director.wave == 1 and Time.get_ticks_msec() < deadline:
		await process_frame
		var elapsed_simulation_time: float = session._last_simulation_time - starting_simulation_time
		if elapsed_simulation_time < remaining_wave_seconds and session.wave_director.wave != 1:
			_fail("Wave 1 must not finish before 30 simulated seconds")
			return
	var elapsed_simulation_time: float = session._last_simulation_time - starting_simulation_time
	if session.wave_director.wave != 2 or elapsed_simulation_time < remaining_wave_seconds:
		var state: Dictionary = session.simulation.snapshot()
		_fail("Wave 1 should advance after 30 simulated seconds at ×4 speed (wave=%d, elapsed=%.2f, paused=%s)" % [session.wave_director.wave, session.wave_director.elapsed_in_wave, state["paused"]])
		return
	var elapsed_wall_seconds := float(Time.get_ticks_msec() - started_at_msec) / 1000.0
	var expected_wall_seconds: float = remaining_wave_seconds / 4.0
	if absf(elapsed_wall_seconds - expected_wall_seconds) > 2.0:
		_fail("A 30-second wave at ×4 should take about 7.5 real seconds (got %.2f)" % elapsed_wall_seconds)
		return
	session.simulation.pause()
	session.queue_free()
	print("Survival 30-second wave clock advances once at ×4 simulation speed")
	quit()

func _wait_for_sequence(simulation: Object, sequence: int) -> bool:
	var deadline := Time.get_ticks_msec() + 1000
	while int(simulation.snapshot()["last_sequence"]) < sequence and Time.get_ticks_msec() < deadline:
		await process_frame
	return int(simulation.snapshot()["last_sequence"]) >= sequence

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
