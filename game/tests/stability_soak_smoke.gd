extends SceneTree

const TARGET_SIMULATION_SECONDS := 600.0
const MAX_WALL_SECONDS := 420.0
const MAX_SURVIVAL_RUNS := 64
const SOAK_SPEED := 4.0

var _wall_started := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_wall_started = Time.get_ticks_msec()
	var save_directory := ProjectSettings.globalize_path("user://saves")
	var save_fingerprints := _fingerprint_directory(save_directory)
	var survival_seconds := 0.0
	var survival_runs := 0
	var survival_max_entities := 0
	while survival_seconds < TARGET_SIMULATION_SECONDS and survival_runs < MAX_SURVIVAL_RUNS:
		var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
		session.difficulty_id = "easy"
		session.skip_starting_weapon_choice = true
		session.sandbox_diagnostics_enabled = true
		session.sandbox_rng_seed = 82000 + survival_runs
		root.add_child(session)
		await process_frame
		if session.simulation == null or session.progression_service != null or session._health_locked:
			_fail("Survival soak must use a live session without progression or health lock")
			return
		session._auto_select_first_chest = true
		session.simulation.set_speed(SOAK_SPEED)
		Engine.time_scale = SOAK_SPEED
		var previous_snapshot: Dictionary = session.simulation.snapshot()
		var run_started_at: float = session.player_active_time
		while not session.run_over and session.player_active_time - run_started_at < 90.0 and _within_wall_limit():
			await process_frame
			var snapshot: Dictionary = session.simulation.snapshot()
			if not _snapshot_advances(previous_snapshot, snapshot):
				_fail("Survival soak snapshot sequence or simulation time regressed")
				return
			previous_snapshot = snapshot
			survival_max_entities = maxi(survival_max_entities,
				int(snapshot.get("metrics", {}).get("entity_count", 0)))
		var active_seconds: float = session.player_active_time - run_started_at
		if active_seconds <= 0.0:
			_fail("Survival soak made no active-time progress")
			return
		survival_seconds += active_seconds
		survival_runs += 1
		Engine.time_scale = 1.0
		session.queue_free()
		await process_frame
		if is_instance_valid(session):
			_fail("Survival session did not release after run teardown")
			return
		if not _within_wall_limit():
			_fail("Survival soak exceeded its wall-clock limit")
			return
	if survival_seconds < TARGET_SIMULATION_SECONDS:
		_fail("Survival soak stopped after %.1f of %.1f simulated seconds across %d runs" % [
			survival_seconds, TARGET_SIMULATION_SECONDS, survival_runs,
		])
		return

	var lab: Control = load("res://scenes/sandbox_lab.tscn").instantiate()
	root.add_child(lab)
	if not await _wait_for_sandbox(lab):
		return
	if lab.context.normal_save_service != null or lab.context.progression_service != null:
		_fail("Sandbox soak must remain isolated from normal saves and progression")
		return
	var sandbox_simulation: Object = lab.context.simulation
	if sandbox_simulation == null or int(sandbox_simulation.set_speed(SOAK_SPEED)) <= 0:
		_fail("Sandbox soak could not start its native simulation")
		return
	var previous_sandbox_snapshot: Dictionary = sandbox_simulation.snapshot()
	var next_spawn_at := 15.0
	var spawn_batches := 0
	while float(previous_sandbox_snapshot["simulation_time"]) < TARGET_SIMULATION_SECONDS and _within_wall_limit():
		await process_frame
		var snapshot: Dictionary = sandbox_simulation.snapshot()
		if not _snapshot_advances(previous_sandbox_snapshot, snapshot):
			_fail("Sandbox soak snapshot sequence or simulation time regressed")
			return
		previous_sandbox_snapshot = snapshot
		if float(snapshot["simulation_time"]) >= next_spawn_at:
			var sequence := int(sandbox_simulation.spawn_enemy("chaser", 10, Vector2(120.0, 0.0), Vector2.ZERO))
			if sequence <= 0:
				_fail("Sandbox soak spawn command was rejected")
				return
			spawn_batches += 1
			next_spawn_at += 15.0
	if float(previous_sandbox_snapshot["simulation_time"]) < TARGET_SIMULATION_SECONDS:
		_fail("Sandbox soak exceeded its wall-clock limit")
		return
	var pause_sequence := int(sandbox_simulation.pause())
	if not await _wait_for_sequence(sandbox_simulation, pause_sequence):
		_fail("Sandbox soak worker did not acknowledge pause during shutdown")
		return
	lab.context.stop()
	lab.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	if _fingerprint_directory(save_directory) != save_fingerprints:
		_fail("Survival and Sandbox soak must not write normal profile saves")
		return
	print("Stability soak passed: survival_runs=%d survival_seconds=%.1f survival_max_entities=%d sandbox_seconds=%.1f sandbox_spawn_batches=%d" % [
		survival_runs, survival_seconds, survival_max_entities,
		float(previous_sandbox_snapshot["simulation_time"]), spawn_batches,
	])
	quit(0)

func _wait_for_sandbox(lab: Control) -> bool:
	var deadline := Time.get_ticks_msec() + 10000
	while (lab.context == null or lab.context.simulation == null) and Time.get_ticks_msec() < deadline:
		await process_frame
	if lab.context == null or lab.context.simulation == null:
		_fail("Sandbox Lab did not start its simulation")
		return false
	return true

func _snapshot_advances(previous: Dictionary, current: Dictionary) -> bool:
	return int(current.get("last_sequence", -1)) >= int(previous.get("last_sequence", -1)) and \
		float(current.get("simulation_time", -1.0)) >= float(previous.get("simulation_time", -1.0))

func _wait_for_sequence(simulation: Object, sequence: int) -> bool:
	if sequence <= 0:
		return false
	var deadline := Time.get_ticks_msec() + 5000
	while int(simulation.snapshot().get("last_sequence", -1)) < sequence and Time.get_ticks_msec() < deadline:
		await process_frame
	return int(simulation.snapshot().get("last_sequence", -1)) >= sequence

func _within_wall_limit() -> bool:
	return Time.get_ticks_msec() - _wall_started < int(MAX_WALL_SECONDS * 1000.0)

func _fingerprint_directory(directory: String) -> Dictionary:
	var fingerprints := {}
	if not DirAccess.dir_exists_absolute(directory):
		return fingerprints
	for file_name in DirAccess.get_files_at(directory):
		fingerprints[file_name] = FileAccess.get_sha256(directory.path_join(file_name))
	return fingerprints

func _fail(message: String) -> void:
	Engine.time_scale = 1.0
	push_error(message)
	quit(1)
