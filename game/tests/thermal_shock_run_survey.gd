extends SceneTree

const MAX_ACTIVE_SECONDS := 120.0
const MAX_WALL_SECONDS := 180.0

var _last_sequence := 0
var _burn_damage := 0.0
var _chill_damage := 0.0
var _reaction_damage := 0.0
var _reaction_damage_events := 0
var _movement_actions: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var run_seed := 20261017
	var difficulty := "easy"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="):
			run_seed = int(argument.trim_prefix("--seed="))
		elif argument.begins_with("--difficulty="):
			difficulty = argument.trim_prefix("--difficulty=")
	if difficulty not in ["easy", "normal", "hard", "nightmare", "chaos"]:
		_fail("Unknown difficulty: %s" % difficulty)
		return
	seed(run_seed)
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.difficulty_id = difficulty
	session.sandbox_diagnostics_enabled = true
	session.sandbox_rng_seed = run_seed
	session.skip_starting_weapon_choice = true
	root.add_child(session)
	await process_frame
	if session.simulation == null:
		_fail("SurvivalSession failed to initialize")
		return
	# Grant only the two production weapons needed to observe Burn/Chill overlap.
	session.loadout._weapon_levels.clear()
	session.loadout._weapon_levels["inferno_sprayer"] = 1
	session.loadout._weapon_levels["frost_nova"] = 1
	session.loadout._rng.seed = run_seed ^ 0x4c4f4144
	session._chest_director._rng.seed = run_seed ^ 0x43484553
	session._auto_select_first_chest = true
	session.simulation.set_speed(1.0)
	Engine.time_scale = 1.0
	var started_at := Time.get_ticks_msec()
	var next_movement_at: float = session.player_active_time
	var movement_step := 0
	while not session.run_over and session.player_active_time < MAX_ACTIVE_SECONDS and \
		Time.get_ticks_msec() - started_at < int(MAX_WALL_SECONDS * 1000.0):
		if session.player_active_time >= next_movement_at:
			_set_kite_movement(session, movement_step)
			movement_step += 1
			next_movement_at = session.player_active_time + 0.5
		await process_frame
		_capture_damage(session)
	_clear_movement_actions()
	var result := "timeout"
	if session.run_over:
		var title := str(session.get_node("HUD/RunResultOverlay/RunResultPanel/Content/Title").text)
		result = "victory" if title == "VICTORY" else "defeat" if title == "RUN OVER" else "unknown"
	var active_seconds: float = session.player_active_time
	print("thermal_shock_run,seed=%d,difficulty=%s,result=%s,active_seconds=%.2f,wave=%d,kills=%d,level=%d,burn_damage=%.2f,chill_damage=%.2f,thermal_shock_damage_events=%d,thermal_shock_damage=%.2f,hp=%.1f/%.1f" % [
		run_seed, difficulty, result, active_seconds, session.wave_director.wave,
		session.kill_count, session.player_level, _burn_damage, _chill_damage, _reaction_damage_events,
		_reaction_damage, session.player_hp, session.player_max_hp,
	])
	session.queue_free()
	Engine.time_scale = 1.0
	await process_frame
	if active_seconds <= 0.0:
		_fail("Run did not advance simulation time")
		return
	quit(0)

func _capture_damage(session: Node2D) -> void:
	for event in session.simulation.snapshot()["events"]:
		var sequence := int(event.get("sequence", 0))
		if sequence <= _last_sequence:
			continue
		_last_sequence = sequence
		if str(event.get("type", "")) != "damage":
			continue
		var source_type := str(event.get("source_type", ""))
		var amount := float(event.get("amount", 0.0))
		match source_type:
			"inferno_sprayer", "wildfire_sprayer":
				_burn_damage += amount
			"frost_nova", "absolute_zero":
				_chill_damage += amount
			"thermal_shock":
				_reaction_damage_events += 1
				_reaction_damage += amount

func _set_kite_movement(session: Node2D, movement_step: int) -> void:
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
	var tangent := Vector2(-away.y, away.x) * (1.0 if movement_step % 2 == 0 else -1.0)
	var direction := (away * 0.8 + tangent * 0.6).normalized()
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

func _fail(message: String) -> void:
	_clear_movement_actions()
	Engine.time_scale = 1.0
	push_error(message)
	quit(1)
