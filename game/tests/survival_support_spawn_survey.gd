extends SceneTree

const SAMPLE_COUNT := 1000
const MAX_WAIT_SECONDS := 30.0
const SUPPORT_TYPES := ["buffer", "shielder", "summoner"]

var _csv_rows: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var seed_value := 20261017
	var replicates := 1
	var output_path := ""
	var save_directory := ProjectSettings.globalize_path("user://saves")
	var save_fingerprints := _save_fingerprints(save_directory)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="):
			seed_value = int(argument.trim_prefix("--seed="))
		elif argument.begins_with("--replicates="):
			replicates = clampi(int(argument.trim_prefix("--replicates=")), 1, 20)
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
	_csv_rows.append("seed,wave,difficulty,samples,support,support_pct,buffer,shielder,summoner,chaser,sprinter,tank,shooter,exploder")
	for replicate in range(replicates):
		var replicate_seed := seed_value + replicate
		for difficulty in ["normal", "chaos"]:
			if not await _sample_difficulty(str(difficulty), replicate_seed):
				quit(1)
				return
	if not output_path.is_empty() and not _write_csv(output_path):
		quit(1)
		return
	if _save_fingerprints(save_directory) != save_fingerprints:
		push_error("Support-spawn survey modified normal save data")
		quit(1)
		return
	quit(0)

func _sample_difficulty(difficulty: String, seed_value: int) -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.difficulty_id = difficulty
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.sandbox_diagnostics_enabled = true
	session.sandbox_rng_seed = seed_value
	root.add_child(session)
	await process_frame
	if session.simulation == null or session.progression_service != null:
		push_error("Spawn survey requires the production session without normal progression")
		return false
	session.wave_director.wave = 12
	session._sandbox_rng.seed = seed_value
	var first_sequence := int(session.simulation.snapshot().get("last_sequence", 0))
	for _index in range(SAMPLE_COUNT):
		session._spawn_wave_enemy()
	var target_sequence := first_sequence + SAMPLE_COUNT
	var deadline := Time.get_ticks_msec() + int(MAX_WAIT_SECONDS * 1000.0)
	while int(session.simulation.snapshot().get("last_sequence", 0)) < target_sequence and \
			Time.get_ticks_msec() < deadline:
		await process_frame
	var snapshot: Dictionary = session.simulation.snapshot()
	if int(snapshot.get("last_sequence", 0)) < target_sequence:
		push_error("Timed out waiting for production enemy-spawn commands")
		session.queue_free()
		return false
	var counts := {"chaser": 0, "sprinter": 0, "tank": 0, "shooter": 0,
		"buffer": 0, "exploder": 0, "shielder": 0, "summoner": 0}
	for entity in snapshot.get("entities", []):
		var components: Dictionary = entity.get("components", {})
		if components.has("EnemyType") and counts.has(str(components["EnemyType"])):
			counts[str(components["EnemyType"])] += 1
	var support_count := 0
	for support_type in SUPPORT_TYPES:
		support_count += int(counts[support_type])
	var row := "%d,12,%s,%d,%d,%.2f,%d,%d,%d,%d,%d,%d,%d,%d" % [
		seed_value, difficulty, SAMPLE_COUNT, support_count,
		100.0 * float(support_count) / SAMPLE_COUNT,
		counts["buffer"], counts["shielder"], counts["summoner"], counts["chaser"],
		counts["sprinter"], counts["tank"], counts["shooter"], counts["exploder"],
	]
	_csv_rows.append(row)
	print("support_spawn_survey," + row)
	session.queue_free()
	await process_frame
	return true

func _write_csv(path: String) -> bool:
	var directory := path.get_base_dir()
	if not directory.is_empty():
		DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write support-spawn survey CSV: %s" % path)
		return false
	for row in _csv_rows:
		file.store_line(row)
	file.close()
	return true

func _save_fingerprints(directory: String) -> Dictionary:
	var fingerprints := {}
	if not DirAccess.dir_exists_absolute(directory):
		return fingerprints
	for file_name in DirAccess.get_files_at(directory):
		fingerprints[file_name] = FileAccess.get_sha256(directory.path_join(file_name))
	return fingerprints
