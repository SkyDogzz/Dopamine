extends SceneTree

const PRODUCTION_DURATION_ARG := "--production-duration"
const STAY_OPEN_ARG := "--stay-open"

var _stay_open := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var user_args := OS.get_cmdline_user_args()
	_stay_open = STAY_OPEN_ARG in user_args
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
	var long_step_director = director_script.new()
	if not long_step_director.advance(70.0) or long_step_director.wave != 3 or \
			not is_equal_approx(long_step_director.elapsed_in_wave, 10.0):
		_fail("A long delta should preserve its remainder across ordinary wave transitions")
		return
	var boss_boundary_director = director_script.new()
	boss_boundary_director.wave = 11
	if not boss_boundary_director.advance(70.0) or \
			boss_boundary_director.state != director_script.State.MID_BOSS or \
			not is_zero_approx(boss_boundary_director.elapsed_in_wave):
		_fail("A long delta should finish wave 12, stop at the boss, and clear its clock")
		return
	var invalid_duration_director = director_script.new()
	invalid_duration_director.wave_duration_seconds = 0.0
	if invalid_duration_director.advance(1.0) or invalid_duration_director.wave != 1 or \
			not is_zero_approx(invalid_duration_director.elapsed_in_wave):
		_fail("A non-positive wave duration should be ignored without changing state")
		return
	var non_finite_duration_director = director_script.new()
	non_finite_duration_director.wave_duration_seconds = INF
	if non_finite_duration_director.advance(1.0) or non_finite_duration_director.wave != 1 or \
			not is_zero_approx(non_finite_duration_director.elapsed_in_wave):
		_fail("A non-finite wave duration should be ignored without changing state")
		return
	var non_finite_delta_director = director_script.new()
	if non_finite_delta_director.advance(INF) or non_finite_delta_director.wave != 1 or \
			not is_zero_approx(non_finite_delta_director.elapsed_in_wave):
		_fail("A non-finite delta should be ignored without corrupting the wave clock")
		return
	for wave in range(2, 13):
		director.advance(30.0)
	if director.state != director_script.State.MID_BOSS or director.wave != 12:
		_fail("The mid-boss should follow the 30-second wave 12")
		return
	if director.advance(30.0) or not director.boss_defeated() or director.wave != 13:
		_fail("The mid-boss should pause the wave clock and resume at wave 13")
		return
	for wave in range(13, 25):
		director.advance(30.0)
	if director.state != director_script.State.FINAL_BOSS or director.wave != 24:
		_fail("The final boss should follow the 30-second wave 24")
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
	if session.get_node("HUD/MetaPanel/MetaRow/RunState").text != "VICTORY":
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
	if not await _verify_live_full_run():
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

func _verify_live_full_run() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.skip_starting_weapon_choice = true
	var production_duration := PRODUCTION_DURATION_ARG in OS.get_cmdline_user_args()
	session.wave_duration_seconds = 30.0 if production_duration else 0.05
	session.enemy_spawn_interval = 1.0 if production_duration else 1000.0
	session.enemy_spawn_radius = 80.0
	session.chest_collection_radius = 200.0
	session.xp_collection_radius = 200.0
	session.boss_placeholder_hp = 1.0
	session.weapon_enabled = production_duration
	session.contact_damage_per_hit = 0.0
	if production_duration:
		session.player_hp = 10000.0
		session.player_max_hp = 10000.0
	root.add_child(session)
	if production_duration:
		session.simulation.set_speed(4.0)
	var chosen_offers := [0]
	session.chest_option_chosen.connect(func(_option_id: String) -> void: chosen_offers[0] += 1)
	var treated_bosses: Dictionary = {}
	var verified_boss_states: Dictionary = {}
	var deadline := Time.get_ticks_msec() + (240000 if production_duration else 10000)
	while not session.run_over and Time.get_ticks_msec() < deadline:
		var snapshot: Dictionary = session.simulation.snapshot()
		for entity in snapshot["entities"]:
			var components: Dictionary = entity["components"]
			var enemy_type: String = components.get("EnemyType", "")
			if enemy_type != "mid_boss" and enemy_type != "final_boss":
				continue
			var id: Dictionary = entity["id"]
			var key := "%d:%d" % [id["index"], id["generation"]]
			if not verified_boss_states.has(enemy_type):
				var initial_active_time: float = session.player_active_time
				var initial_wave_elapsed := float(session.wave_director.elapsed_in_wave)
				var initial_hp: float = session.player_hp
				while session.player_active_time <= initial_active_time and Time.get_ticks_msec() < deadline:
					await process_frame
				if session.player_active_time <= initial_active_time:
					_fail("Active time and HP decay should continue during a boss fight")
					return false
				if not is_equal_approx(float(session.wave_director.elapsed_in_wave), initial_wave_elapsed):
					_fail("The wave timer should remain stopped during a boss fight")
					return false
				if session.player_hp >= initial_hp:
					_fail("HP decay should continue during a boss fight")
					return false
				verified_boss_states[enemy_type] = true
			if treated_bosses.has(key):
				continue
			var sequence: int = session.simulation.apply_damage_over_time(
				int(id["index"]), int(id["generation"]), 1.0, 0.01, 0.02
			)
			if sequence > 0:
				treated_bosses[key] = true
		if session._chest_open:
			var choice: Button = session.get_node("HUD/ChestOverlay/ChestChoice/Content/Options/Choice0")
			choice.pressed.emit()
		await process_frame
	if not session.run_over:
		_fail("A live accelerated Survival run should reach the final result")
		return false
	if session.wave_director.state != session.WAVE_DIRECTOR_SCRIPT.State.VICTORY:
		_fail("A live full run should defeat the final boss")
		return false
	if session.wave_director.wave != 24 or session.kill_count < 2:
		_fail("A live full run should pass both bosses and finish at wave 24")
		return false
	if session._chest_open or not session._world_chests.is_empty() or chosen_offers[0] < 2:
		_fail("A live victory should collect and resolve the boss chest choices")
		return false
	if verified_boss_states.size() != 2:
		_fail("The live run should verify both boss fights")
		return false
	if session.player_active_time < 1.0:
		_fail("A live run should account for elapsed simulation time")
		return false
	if production_duration and session.player_active_time < 720.0:
		_fail("A production-duration run should account for 24 waves of 30 active seconds")
		return false
	if _stay_open:
		print("Survival run complete; press Escape to close the window")
		while not Input.is_key_pressed(KEY_ESCAPE):
			await process_frame
		quit()
	else:
		session.queue_free()
		await process_frame
	return true

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
