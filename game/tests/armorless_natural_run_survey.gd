extends SceneTree

const ARMORLESS_RUN_STATE := preload("res://scripts/armorless_run_state.gd")
const EQUIPMENT_GENERATOR := preload("res://scripts/equipment_generator.gd")
const DEFAULT_MAX_WAVE := 60
const MAX_WAVE_LIMIT := 120
const DEFAULT_MAX_WALL_SECONDS := 300.0
const MAX_WALL_SECONDS_LIMIT := 3600.0

var _movement_actions: Array[String] = []
const DRAFT_STAT_WEIGHTS := {
	"max_hp": 1.0,
	"kill_healing_pct": 8.0,
	"move_speed_pct": 2.0,
	"damage_pct": 1.5,
	"attack_speed_pct": 1.0,
	"xp_pct": 0.5,
	"pickup_radius_pct": 0.25,
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var run_seed := 20261017
	var movement_mode := "kite"
	var draft_strategy := "first"
	var max_wave := DEFAULT_MAX_WAVE
	var max_wall_seconds := DEFAULT_MAX_WALL_SECONDS
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="):
			run_seed = int(argument.trim_prefix("--seed="))
		elif argument.begins_with("--movement="):
			movement_mode = argument.trim_prefix("--movement=")
		elif argument.begins_with("--draft="):
			draft_strategy = argument.trim_prefix("--draft=")
		elif argument.begins_with("--max-wall-seconds="):
			max_wall_seconds = float(argument.trim_prefix("--max-wall-seconds="))
		elif argument.begins_with("--max-wave="):
			max_wave = int(argument.trim_prefix("--max-wave="))
	if movement_mode not in ["kite", "stationary"]:
		_fail("Movement mode must be kite or stationary")
		return
	if draft_strategy not in ["first", "survival"]:
		_fail("Draft strategy must be first or survival")
		return
	if max_wave < 1 or max_wave > MAX_WAVE_LIMIT:
		_fail("Maximum wave must be between 1 and %d" % MAX_WAVE_LIMIT)
		return
	if not is_finite(max_wall_seconds) or max_wall_seconds <= 0.0 or max_wall_seconds > MAX_WALL_SECONDS_LIMIT:
		_fail("Maximum wall duration must be between 0 and %d seconds" % int(MAX_WALL_SECONDS_LIMIT))
		return
	if not _verify_draft_strategy():
		_fail("The survival draft strategy failed its deterministic ranking checks")
		return
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
	# The production run id intentionally uses cryptographic randomness. Replace only
	# the survey's temporary RNG owners so a fixed survey seed also fixes its drafts.
	session.loadout._rng.seed = run_seed
	session.armorless_run_state = ARMORLESS_RUN_STATE.new(run_seed ^ 0xA24B)
	session.armorless_run_state.begin_run()
	session._armorless_equipment_generator = EQUIPMENT_GENERATOR.new(run_seed ^ 0x24A2)
	session._auto_select_first_chest = draft_strategy == "first"
	# Keep real-time rates here: fast-forwarding the worker changes how often
	# the frame-driven kite can react, which changes combat behavior.
	session.simulation.set_speed(1.0)
	Engine.time_scale = 1.0
	var started_at := Time.get_ticks_msec()
	var next_move_at: float = session.player_active_time
	var direction_seed := 0
	var frame_count := 0
	var path_distance := 0.0
	var drafts_selected := 0
	var max_temporary_items := 0
	var max_flux := 0
	var previous_position: Vector2 = session.player.global_position
	while not session.run_over and session.wave_director.wave <= max_wave and \
			Time.get_ticks_msec() - started_at < int(max_wall_seconds * 1000.0):
		if movement_mode == "kite" and session.player_active_time >= next_move_at:
			_set_kite_movement(session, direction_seed)
			direction_seed += 1
			next_move_at = session.player_active_time + 0.5
		await process_frame
		frame_count += 1
		if draft_strategy == "survival" and session._chest_open and session.mode_id == "armorless":
			var draft: Array[Dictionary] = session.armorless_run_state.current_draft()
			var equipment: Array[Dictionary] = session.armorless_run_state.temporary_equipment()
			var selected_index := _best_survival_draft_index(draft, equipment)
			if selected_index >= 0 and selected_index < draft.size():
				session._choose_armorless_draft_option("armorless:%s" % str(draft[selected_index]["instance_id"]))
				drafts_selected += 1
				max_temporary_items = maxi(max_temporary_items, session.armorless_run_state.temporary_equipment().size())
		max_flux = maxi(max_flux, session.armorless_run_state.flux())
		var current_position: Vector2 = session.player.global_position
		path_distance += previous_position.distance_to(current_position)
		previous_position = current_position
	_clear_movement_actions()
	var result := "timeout"
	if session.run_over:
		var title := str(session.get_node("HUD/RunResultOverlay/RunResultPanel/Content/Title").text)
		result = "victory" if title == "VICTORY" else "defeat" if title == "RUN OVER" else "unknown"
	elif session.wave_director.wave > max_wave:
		result = "wave_limit_complete"
	var active_seconds: float = session.player_active_time
	var wall_seconds := float(Time.get_ticks_msec() - started_at) / 1000.0
	var final_snapshot: Dictionary = session.simulation.snapshot()
	var metrics: Dictionary = final_snapshot.get("metrics", {})
	var wall_hz := float(frame_count) / wall_seconds if wall_seconds > 0.0 else 0.0
	var simulation_rate := active_seconds / wall_seconds if wall_seconds > 0.0 else 0.0
	var reward_label := str(session._run_result_overlay.get_node("RunResultPanel/Content/Rewards").text)
	print("armorless_natural_run,seed=%d,difficulty=easy,movement=%s,draft=%s,result=%s,wave=%d,wave_state=%s,paused=%s,chest_open=%s,active_seconds=%.2f,wall_seconds=%.2f,simulation_rate=%.3f,frame_hz=%.1f,entities=%d,projectiles=%d,xp_orbs=%d,collisions=%d,kills=%d,level=%d,hp=%.1f/%.1f,path=%.1f,drafts_selected=%d,max_temporary_items=%d,max_flux=%d,profile_attached=false,reward_summary=%s" % [
		run_seed,
		movement_mode, draft_strategy, result, session.wave_director.wave, session.wave_director.state,
		final_snapshot.get("paused", false), session._chest_open, active_seconds, wall_seconds,
		simulation_rate, wall_hz, int(metrics.get("entity_count", 0)), int(metrics.get("projectile_count", 0)),
		int(metrics.get("xp_orb_count", 0)), int(metrics.get("collision_count", 0)),
		session.kill_count, session.player_level,
		session.player_hp, session.player_max_hp, path_distance, drafts_selected,
		max_temporary_items, max_flux,
		reward_label,
	])
	session.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	if _save_fingerprints(save_directory) != save_fingerprints:
		_fail("A natural Armorless run must not create or modify normal save slots")
		return
	if active_seconds <= 0.0 or (movement_mode == "kite" and path_distance <= 0.0):
		_fail("The Armorless survey must advance combat and its selected movement mode")
		return
	quit(0)

func _best_survival_draft_index(draft: Array[Dictionary], current_equipment: Array[Dictionary]) -> int:
	if draft.is_empty():
		return -1
	var best_index := 0
	var best_score := -INF
	for index in range(draft.size()):
		var candidate: Dictionary = draft[index]
		var score := _survival_item_score(candidate)
		for current_item in current_equipment:
			if str(current_item.get("slot", "")) == str(candidate.get("slot", "")):
				score -= _survival_item_score(current_item)
				break
		if score > best_score:
			best_score = score
			best_index = index
	return best_index

func _survival_item_score(item: Dictionary) -> float:
	var score := 0.0
	for line in item.get("stat_lines", []):
		if not line is Dictionary:
			continue
		var stat_id := str(line.get("stat_id", ""))
		var weight := float(DRAFT_STAT_WEIGHTS.get(stat_id, 0.0))
		if weight <= 0.0:
			continue
		var value := EQUIPMENT_GENERATOR.stat_value(
			stat_id, float(line.get("roll_percentile", 0.0)), int(line.get("enhancement_level", 0))
		)
		score += value * weight
	return score

func _verify_draft_strategy() -> bool:
	var healing_item := {"slot": "ring", "stat_lines": [
		{"stat_id": "kill_healing_pct", "roll_percentile": 1.0, "enhancement_level": 0},
	]}
	var health_item := {"slot": "ring", "stat_lines": [
		{"stat_id": "max_hp", "roll_percentile": 1.0, "enhancement_level": 0},
	]}
	if _best_survival_draft_index([health_item, healing_item], []) != 1:
		return false
	var stronger_health_item := health_item.duplicate(true)
	stronger_health_item["stat_lines"][0]["roll_percentile"] = 0.8
	var weaker_health_item := health_item.duplicate(true)
	weaker_health_item["stat_lines"][0]["roll_percentile"] = 0.0
	var mobility_item := {"slot": "boots", "stat_lines": [
		{"stat_id": "move_speed_pct", "roll_percentile": 1.0, "enhancement_level": 0},
	]}
	return _best_survival_draft_index(
		[weaker_health_item, mobility_item], [stronger_health_item]
	) == 1

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
