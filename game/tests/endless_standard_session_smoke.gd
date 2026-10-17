extends SceneTree

const SAVE_SERVICE := preload("res://scripts/save_service.gd")
const PROGRESSION := preload("res://scripts/progression_service.gd")
const WAVE_DIRECTOR := preload("res://scripts/survival_wave_director.gd")
const TEST_DIRECTORY := "user://endless_standard_session_smoke"

var _session: Node2D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var progression = PROGRESSION.new(SAVE_SERVICE.new(directory), "0")
	progression.award_survival_run("endless-session-unlock", 24, true, 1, "easy")
	var initial_profile: Dictionary = progression.load_profile()["profile"]
	var initial_essence := int(initial_profile["resources"]["essence"])
	var initial_powder := int(initial_profile["resources"]["powder_basic"])
	var initial_equipment_count: int = initial_profile["equipment_inventory"].size()
	_session = await _create_session(progression)
	if _session == null or not _session.wave_director.endless_standard:
		_fail("An Endless session should use the recurring-boss director")
		return
	_session.wave_director.wave = 3
	_session.player_active_time = 90.0
	_session.kill_count = 4
	_session._manually_paused = true
	_session.simulation.pause()
	_session._open_abandon_confirmation()
	_session._confirm_abandon_run()
	if not _session.run_over or not _session.get_node("HUD/RunResultOverlay").visible or \
		_session._manually_paused or not bool(_session.simulation.snapshot()["paused"]):
		_fail("Abandoning Endless should end the paused run and present its result")
		return
	var abandoned_profile: Dictionary = progression.load_profile()["profile"]
	var expected_abandonment_essence := 15
	if abandoned_profile["endless_standard_records"]["easy"]["wave"] != 3 or \
		int(abandoned_profile["resources"]["essence"]) - initial_essence != expected_abandonment_essence or \
		int(abandoned_profile["resources"]["powder_basic"]) - initial_powder != 20 or \
		abandoned_profile["equipment_inventory"].size() != initial_equipment_count:
		_fail("Abandon result mismatch: run_over=%s overlay=%s manually_paused=%s paused=%s record=%s essence_delta=%d powder_delta=%d equipment=%d/%d" % [
			_session.run_over, _session.get_node("HUD/RunResultOverlay").visible, _session._manually_paused,
			_session.simulation.snapshot()["paused"], abandoned_profile["endless_standard_records"]["easy"],
			int(abandoned_profile["resources"]["essence"]) - initial_essence,
			int(abandoned_profile["resources"]["powder_basic"]) - initial_powder,
			abandoned_profile["equipment_inventory"].size(), initial_equipment_count,
		])
		return
	await _cleanup_session()
	_session = await _create_session(progression)
	if _session == null:
		_fail("Could not start the second Endless fixture")
		return
	_session.wave_director.wave = 5
	_session.player_active_time = 150.0
	_session.kill_count = 8
	_session._finish_run(false)
	var death_profile: Dictionary = progression.load_profile()["profile"]
	if not _session.run_over or not _session.get_node("HUD/RunResultOverlay").visible or \
		death_profile["endless_standard_records"]["easy"]["wave"] != 5 or \
		int(death_profile["resources"]["essence"]) - initial_essence != expected_abandonment_essence + 18 or \
		int(death_profile["resources"]["powder_basic"]) - initial_powder != 20 + 25 or \
		death_profile["equipment_inventory"].size() != initial_equipment_count:
		_fail("Death should save the Endless result and proposed reward without permanent equipment")
		return
	await _cleanup_session()
	_session = await _create_session(progression, "survival")
	if _session == null:
		_fail("Could not start the Survival victory fixture")
		return
	_session.wave_director.wave = 24
	_session.wave_director.state = WAVE_DIRECTOR.State.VICTORY
	_session.player_hp = 42.0
	_session._weapon_kills_by_id["lightning_conductor"] = 7
	_session._weapon_damage_by_id["lightning_conductor"] = 450.0
	_session._enemy_kills_by_type["chaser"] = 3
	var survival_run_id: String = _session._run_id
	var carried_weapons: Array = _session.loadout.owned_weapons()
	var carried_relics: Array = _session.loadout.owned_relics()
	var equipment_before_continuation: int = progression.load_profile()["profile"]["equipment_inventory"].size()
	_session._finish_run(true)
	var continuation_button: Button = _session.get_node("HUD/RunResultOverlay/RunResultPanel/Content/ContinueEndlessButton")
	if not continuation_button.visible or not progression.load_profile()["profile"]["endless_standard_unlocked"]:
		_fail("A Survival final-boss victory should grant its rewards and offer Endless continuation")
		return
	continuation_button.pressed.emit()
	if _session.mode_id != "endless" or _session.run_over or _session.wave_director.wave != 25 or \
		_session.wave_director.state != WAVE_DIRECTOR.State.WAVE or \
		not _session.wave_director.endless_standard or _session.player_hp != 42.0 or \
		_session.kill_count != 0 or not is_zero_approx(_session._run_active_time()) or \
		_session.get_node("HUD/MetaPanel/MetaRow/TimeValue").text != "00:00" or \
		not _session._weapon_kills_by_id.is_empty() or not _session._weapon_damage_by_id.is_empty() or \
		not _session._enemy_kills_by_type.is_empty() or \
		_session.loadout.owned_weapons() != carried_weapons or _session.loadout.owned_relics() != carried_relics or \
		_session.get_node("HUD/RunResultOverlay").visible or root.gui_get_focus_owner() != null or \
		bool(_session.simulation.snapshot()["paused"]) or \
		_session._enemy_hp_multiplier(25) <= _session._enemy_hp_multiplier(24):
		_fail("Continuation should preserve HP/build while resetting new-run elapsed time, kills and achievement counters")
		return
	var metrics_after_survival: Dictionary = progression.load_profile()["profile"]["achievement_progress"]["metrics"]
	var endless_run_id: String = _session._run_id
	_session.player_active_time += 30.0
	_session.kill_count = 9
	_session._weapon_kills_by_id["lightning_conductor"] = 2
	_session._weapon_damage_by_id["lightning_conductor"] = 125.0
	_session._enemy_kills_by_type["chaser"] = 1
	_session._finish_run(false)
	var continued_profile: Dictionary = progression.load_profile()["profile"]
	if continued_profile["endless_standard_records"]["easy"]["wave"] != 25 or \
		continued_profile["endless_standard_records"]["easy"]["kills"] != 9 or \
		continued_profile["endless_standard_records"]["easy"]["survival_time_seconds"] != 30.0 or \
		continued_profile["achievement_progress"]["metrics"]["weapon_kills_lightning_conductor"] != \
		float(metrics_after_survival["weapon_kills_lightning_conductor"]) + 2.0 or \
		continued_profile["achievement_progress"]["metrics"]["weapon_damage_lightning_conductor"] != \
		float(metrics_after_survival["weapon_damage_lightning_conductor"]) + 125.0 or \
		continued_profile["achievement_progress"]["metrics"]["enemy_kills_chaser"] != \
		float(metrics_after_survival["enemy_kills_chaser"]) + 1.0 or \
		continued_profile["equipment_inventory"].size() != equipment_before_continuation + 1 or \
		not continued_profile["rewarded_survival_runs"].has(survival_run_id) or \
		not continued_profile["rewarded_survival_runs"].has(endless_run_id):
		_fail("The continued Endless run should record only its own duration/kills and achievement metrics")
		return
	await _cleanup_session()
	print("Endless standard session smoke passed")
	quit()

func _create_session(progression: RefCounted, requested_mode: String = "endless") -> Node2D:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.progression_service = progression
	session.mode_id = requested_mode
	session.difficulty_id = "easy"
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	return session

func _cleanup_session() -> void:
	if is_instance_valid(_session) and _session.is_inside_tree():
		_session.queue_free()
		await process_frame
	_session = null

func _fail(message: String) -> void:
	push_error(message)
	await _cleanup_session()
	quit(1)
