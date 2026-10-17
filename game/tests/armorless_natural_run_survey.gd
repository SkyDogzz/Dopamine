extends SceneTree

const MAX_WAVE := 60
const MAX_WALL_SECONDS := 300.0

var _movement_actions: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var run_seed := 20261017
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="):
			run_seed = int(argument.trim_prefix("--seed="))
	var save_directory := ProjectSettings.globalize_path("user://saves")
	var save_fingerprints := _save_fingerprints(save_directory)
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.mode_id = "armorless"
	session.difficulty_id = "easy"
	session.wave_duration_seconds = 30.0
	session.sandbox_diagnostics_enabled = true
	session.sandbox_rng_seed = run_seed
	session.skip_starting_weapon_choice = true
	root.add_child(session)
	await process_frame
	if session.simulation == null or session.progression_service != null or session._health_locked or \
			not session.armorless_run_state.is_active():
		_fail("The natural Armorless survey requires an isolated run with ordinary, unlocked HP")
		return
	session._auto_select_first_chest = true
	session.simulation.set_speed(4.0)
	Engine.time_scale = 4.0
	var started_at := Time.get_ticks_msec()
	var next_move_at: float = session.player_active_time
	var direction_seed := 0
	var path_distance := 0.0
	var previous_position: Vector2 = session.player.global_position
	while not session.run_over and session.wave_director.wave <= MAX_WAVE and \
			Time.get_ticks_msec() - started_at < int(MAX_WALL_SECONDS * 1000.0):
		if session.player_active_time >= next_move_at:
			_set_kite_movement(session, direction_seed)
			direction_seed += 1
			next_move_at = session.player_active_time + 0.5
		await process_frame
		var current_position: Vector2 = session.player.global_position
		path_distance += previous_position.distance_to(current_position)
		previous_position = current_position
	_clear_movement_actions()
	var result := "timeout"
	if session.run_over:
		var title := str(session.get_node("HUD/RunResultOverlay/RunResultPanel/Content/Title").text)
		result = "victory" if title == "VICTORY" else "defeat" if title == "RUN OVER" else "unknown"
	elif session.wave_director.wave > MAX_WAVE:
		result = "wave_60_complete"
	var active_seconds: float = session.player_active_time
	print("armorless_natural_run,seed=%d,difficulty=easy,result=%s,wave=%d,active_seconds=%.2f,kills=%d,level=%d,hp=%.1f/%.1f,path=%.1f" % [
		run_seed,
		result, session.wave_director.wave, active_seconds, session.kill_count, session.player_level,
		session.player_hp, session.player_max_hp, path_distance,
	])
	session.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	if _save_fingerprints(save_directory) != save_fingerprints:
		_fail("A natural Armorless run must not create or modify normal save slots")
		return
	if active_seconds <= 0.0 or path_distance <= 0.0:
		_fail("The natural Armorless survey must advance combat and player movement")
		return
	quit(0)

func _set_kite_movement(session: Node2D, orbit_direction: int) -> void:
	var nearest_offset := Vector2.ZERO
	var nearest_distance_squared := INF
	for entity in session.simulation.snapshot()["entities"]:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("IsXpOrb", false) or \
				float(components.get("Health", {}).get("current", 0.0)) <= 0.0:
			continue
		var transform: Dictionary = components.get("Transform2D", {})
		var enemy_position := Vector2(float(transform.get("x", 0.0)), float(transform.get("y", 0.0)))
		var offset: Vector2 = session.player.global_position - enemy_position
		if offset.length_squared() < nearest_distance_squared:
			nearest_distance_squared = offset.length_squared()
			nearest_offset = offset
	var away := nearest_offset.normalized() if nearest_distance_squared < INF else Vector2.UP
	var tangent := Vector2(-away.y, away.x) * (1.0 if orbit_direction % 2 == 0 else -1.0)
	_set_movement((away * 0.8 + tangent * 0.6).normalized())

func _set_movement(direction: Vector2) -> void:
	var actions: Array[String] = []
	if direction.x < -0.35:
		actions.append("move_left")
	elif direction.x > 0.35:
		actions.append("move_right")
	if direction.y < -0.35:
		actions.append("move_up")
	elif direction.y > 0.35:
		actions.append("move_down")
	_clear_movement_actions()
	_movement_actions = actions
	for action in _movement_actions:
		Input.action_press(action)

func _clear_movement_actions() -> void:
	for action in _movement_actions:
		Input.action_release(action)
	_movement_actions.clear()

func _save_fingerprints(directory: String) -> Dictionary:
	var result := {}
	if not DirAccess.dir_exists_absolute(directory):
		return result
	for file_name in DirAccess.get_files_at(directory):
		result[file_name] = FileAccess.get_sha256(directory.path_join(file_name))
	return result

func _fail(message: String) -> void:
	_clear_movement_actions()
	Engine.time_scale = 1.0
	push_error(message)
	quit(1)
