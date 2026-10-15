extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var director_script = load("res://scripts/survival_wave_director.gd")
	var director = director_script.new()
	var debug_director = director_script.new()
	debug_director.elapsed_in_wave = debug_director.wave_duration_seconds
	if not debug_director.advance(0.0) or debug_director.wave != 2:
		_fail("A debug-advanced wave deadline should transition without adding active time")
		return
	if director.wave != 1 or director.state != director_script.State.WAVE:
		_fail("A run should start at wave 1")
		return
	if director.advance(29.0) or director.wave != 1:
		_fail("A wave should remain active before its duration")
		return
	if not director.advance(1.0) or director.wave != 2:
		_fail("A completed wave should advance exactly once")
		return
	for wave in range(2, 12):
		director.advance(30.0)
	if director.state != director_script.State.MID_BOSS or director.wave != 12:
		_fail("The mid-boss should follow wave 11")
		return
	if director.advance(30.0) or not director.boss_defeated() or director.wave != 13:
		_fail("The mid-boss should pause the wave clock and resume at wave 13")
		return
	for wave in range(13, 24):
		director.advance(30.0)
	if director.state != director_script.State.FINAL_BOSS or director.wave != 24:
		_fail("The final boss should follow wave 23")
		return
	if not director.boss_defeated() or director.state != director_script.State.VICTORY:
		_fail("Defeating the final boss should complete the run")
		return
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.player_hp = 1000.0
	session.skip_starting_weapon_choice = true
	root.add_child(session)
	await process_frame
	while session.wave_director.state != director_script.State.VICTORY:
		session.debug_advance_wave()
		if session.wave_director.state == director_script.State.MID_BOSS:
			if not await _wait_for_entity_type(session, "mid_boss"):
				return
		elif session.wave_director.state == director_script.State.FINAL_BOSS:
			if not await _wait_for_entity_type(session, "final_boss"):
				return
		if session.wave_director.state == director_script.State.MID_BOSS or session.wave_director.state == director_script.State.FINAL_BOSS:
			await process_frame
			if not session.get_node("HUD/BossPanel/BossInfo/BossHPBar").visible:
				_fail("Survival HUD should show the active boss health bar")
				return
		await process_frame
	if not session.run_over or not session.simulation.snapshot()["paused"]:
		_fail("Defeating the final boss placeholder should complete and pause the Survival run")
		return
	if session.get_node("HUD/RunPanel/RunInfo/RunState").text != "VICTORY":
		_fail("The final boss should show a distinct victory state")
		return
	var result_panel = session.get_node("HUD/RunResultOverlay/RunResultPanel")
	if not session.get_node("HUD/RunResultOverlay").visible or result_panel.get_node("Content/Title").text != "VICTORY":
		_fail("Winning should display the victory result screen")
		return
	if not result_panel.get_node("Content/Summary").text.begins_with("WAVE 24"):
		_fail("A completed Survival run should record the final boss as wave 24")
		return
	session.queue_free()
	await process_frame
	if not await _verify_live_wave_clock():
		return
	print("Survival wave director smoke passed")
	quit()

func _verify_live_wave_clock() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.skip_starting_weapon_choice = true
	session.wave_duration_seconds = 0.05
	session.enemy_spawn_interval = 100.0
	session.weapon_enabled = false
	session.contact_damage_per_hit = 0.0
	session.player_hp = 1000.0
	root.add_child(session)
	if not await _wait_for_wave(session, 2):
		_fail("The live simulation clock should advance the first wave")
		return false
	session.simulation.pause()
	var pause_deadline := Time.get_ticks_msec() + 1000
	var state: Dictionary = session.simulation.snapshot()
	while not state["paused"] and Time.get_ticks_msec() < pause_deadline:
		await process_frame
		state = session.simulation.snapshot()
	if not state["paused"]:
		_fail("Survival pause command should pause the live simulation")
		return false
	await process_frame
	var paused_simulation_time := float(session.simulation.snapshot()["simulation_time"])
	var paused_wave_elapsed := float(session.wave_director.elapsed_in_wave)
	await create_timer(0.1).timeout
	if not is_equal_approx(float(session.simulation.snapshot()["simulation_time"]), paused_simulation_time):
		_fail("The live simulation clock should stop while paused")
		return false
	if not is_equal_approx(float(session.wave_director.elapsed_in_wave), paused_wave_elapsed):
		_fail("The active wave timer should stop while paused")
		return false
	session.simulation.resume()
	if not await _wait_for_wave(session, 3):
		_fail("The active wave timer should resume from the live simulation clock")
		return false
	session.queue_free()
	await process_frame
	return true

func _wait_for_wave(session: Node2D, expected_wave: int) -> bool:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if session.wave_director.wave >= expected_wave:
			return true
	return false

func _wait_for_entity_type(session: Node2D, expected_type: String) -> bool:
	var deadline := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		for entity in session.simulation.snapshot()["entities"]:
			if entity["components"].get("EnemyType", "") == expected_type:
				return true
	_fail("Timed out waiting for %s placeholder" % expected_type)
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
