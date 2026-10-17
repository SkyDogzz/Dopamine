extends SceneTree

const SAVE_SERVICE := preload("res://scripts/save_service.gd")
const PROGRESSION := preload("res://scripts/progression_service.gd")
const TEST_DIRECTORY := "user://armorless_records_smoke"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var saves = SAVE_SERVICE.new(directory)
	var progression = PROGRESSION.new(saves, "0")
	var legacy_profile: Dictionary = progression.load_profile()["profile"]
	legacy_profile["profile_version"] = 7
	legacy_profile.erase("armorless_records")
	if not saves.save_slot("0", legacy_profile):
		_fail("Could not seed the previous v7 profile")
		return
	var migrated: Dictionary = progression.load_profile()
	if not migrated.get("ok", false) or int(migrated["profile"]["profile_version"]) != 8 or \
		migrated["profile"]["armorless_records"]["normal"]["wave"] != 0:
		_fail("A v7 profile should migrate additively to v8 with empty Armorless records")
		return
	var first: Dictionary = progression.record_armorless_result("normal", 12, 240.0, 300)
	if not first.get("ok", false) or not first.get("updated", false):
		_fail("The first Armorless result should create a local record")
		return
	var same_wave_more_time: Dictionary = progression.record_armorless_result("normal", 12, 300.0, 10)
	if not same_wave_more_time.get("ok", false) or not same_wave_more_time.get("updated", false) or \
		int(same_wave_more_time["record"]["kills"]) != 10:
		_fail("Survival time should break ties before kills")
		return
	var same_wave_same_time_more_kills: Dictionary = progression.record_armorless_result("normal", 12, 300.0, 11)
	if not same_wave_same_time_more_kills.get("ok", false) or \
		not same_wave_same_time_more_kills.get("updated", false):
		_fail("Kills should break ties after wave and survival time")
		return
	var lower_wave: Dictionary = progression.record_armorless_result("normal", 11, 720.0, 999)
	if not lower_wave.get("ok", false) or lower_wave.get("updated", true):
		_fail("A lower wave should not replace the best Armorless record")
		return
	var separate_difficulty: Dictionary = progression.record_armorless_result("hard", 1, 20.0, 1)
	if not separate_difficulty.get("ok", false) or not separate_difficulty.get("updated", false):
		_fail("Armorless records should be kept separately by difficulty")
		return
	var before: Dictionary = progression.load_profile()["profile"]
	var resources_before: Dictionary = before["resources"].duplicate(true)
	var achievements_before: Dictionary = before["achievement_progress"].duplicate(true)
	var repeated: Dictionary = progression.record_armorless_result("normal", 12, 300.0, 11)
	var after: Dictionary = progression.load_profile()["profile"]
	if not repeated.get("ok", false) or repeated.get("updated", true) or \
		after["resources"] != resources_before or after["achievement_progress"] != achievements_before or \
		after["rewarded_survival_runs"].size() != 0 or \
		int(after["armorless_records"]["normal"]["kills"]) != 11:
		_fail("Recording Armorless results must be idempotent and grant no unapproved rewards")
		return
	var invalid: Dictionary = progression.record_armorless_result("chaos", 0, -1.0, -1)
	if invalid.get("ok", true):
		_fail("Armorless records should reject invalid wave, time and kills")
		return
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.mode_id = "armorless"
	session.difficulty_id = "easy"
	session.progression_service = progression
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	root.add_child(session)
	await process_frame
	session.wave_director.wave = 30
	session.player_active_time = 1200.0
	session.kill_count = 450
	var resources_before_run: Dictionary = progression.load_profile()["profile"]["resources"].duplicate(true)
	var equipment_count_before_run: int = progression.load_profile()["profile"]["equipment_inventory"].size()
	session._finish_run(false)
	var result_profile: Dictionary = progression.load_profile()["profile"]
	if result_profile["armorless_records"]["easy"]["wave"] != 30 or \
		result_profile["rewarded_survival_runs"].size() != 1 or \
		result_profile["resources"]["essence"] - resources_before_run["essence"] != 53 or \
		result_profile["resources"]["powder_basic"] - resources_before_run["powder_basic"] != 77 or \
		result_profile["equipment_inventory"].size() != equipment_count_before_run or \
		float(result_profile["achievement_progress"]["metrics"]["total_kills"]) != 450.0 or \
		float(result_profile["achievement_progress"]["metrics"]["highest_wave"]) != 30.0 or \
		float(result_profile["achievement_progress"]["metrics"]["completed_runs"]) != 1.0 or \
		float(result_profile["achievement_progress"]["metrics"]["equipment_items_collected"]) != 0.0:
		_fail("An Armorless result should grant persistent resources without permanent equipment")
		return
	var result_panel: Control = session.get_node("HUD/RunResultOverlay/RunResultPanel")
	if not result_panel.get_node("Content/Rewards").text.contains("ESSENCE") or \
		not result_panel.get_node("Content/Record").text.contains("PERSONAL BEST") or \
		not result_panel.get_node("Content/Equipment").text.is_empty():
		_fail("Armorless results should show both rewards and the record without an equipment reward")
		return
	var repeated_reward: Dictionary = progression.award_armorless_run(
		session._run_id, 30, 450, "easy", {}
	)
	var after_duplicate: Dictionary = progression.load_profile()["profile"]
	if not repeated_reward.get("ok", false) or not repeated_reward.get("duplicate", false) or \
		after_duplicate["resources"] != result_profile["resources"] or \
		after_duplicate["achievement_progress"] != result_profile["achievement_progress"] or \
		after_duplicate["equipment_inventory"].size() != equipment_count_before_run:
		_fail("Repeating an Armorless run reward must not grant resources or achievements twice")
		return
	if not _check_proposed_reward_formula(directory):
		return
	session.queue_free()
	await process_frame
	print("armorless_records_smoke: passed difficulty-separated ranking and reward isolation")
	quit(0)

func _check_proposed_reward_formula(directory: String) -> bool:
	var formula_directory := directory.path_join("reward_formula")
	DirAccess.make_dir_recursive_absolute(formula_directory)
	var formula_saves = SAVE_SERVICE.new(formula_directory)
	var formula_progression = PROGRESSION.new(formula_saves, "0")
	var profile: Dictionary = formula_progression.load_profile()["profile"]
	profile["highest_unlocked_difficulty"] = "chaos"
	if not formula_saves.save_slot("0", profile):
		return _fail_formula("Could not prepare isolated difficulty profile")
	var expected := {
		"easy": [[44, 64], [46, 67]],
		"normal": [[63, 92], [65, 95]],
		"hard": [[101, 138], [104, 143]],
		"nightmare": [[158, 212], [163, 218]],
		"chaos": [[252, 322], [260, 333]],
	}
	for difficulty in ["easy", "normal", "hard", "nightmare", "chaos"]:
		for wave_index in range(2):
			var wave := 24 + wave_index
			var before: Dictionary = formula_progression.load_profile()["profile"]["resources"].duplicate()
			var result: Dictionary = formula_progression.award_armorless_run(
				"formula-%s-%d" % [difficulty, wave], wave, 0, difficulty, {}
			)
			var after: Dictionary = formula_progression.load_profile()["profile"]["resources"]
			var expected_reward: Array = expected[difficulty][wave_index]
			if not result.get("ok", false) or \
				int(after["essence"]) - int(before["essence"]) != expected_reward[0] or \
				int(after["powder_basic"]) - int(before["powder_basic"]) != expected_reward[1]:
				return _fail_formula("Proposed Armorless reward formula changed for %s wave %d: expected %s, got %s" % [
					difficulty, wave, expected_reward,
					[int(after["essence"]) - int(before["essence"]), int(after["powder_basic"]) - int(before["powder_basic"])],
				])
	return true

func _fail_formula(message: String) -> bool:
	_fail(message)
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
