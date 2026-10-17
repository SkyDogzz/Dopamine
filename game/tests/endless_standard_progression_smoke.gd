extends SceneTree

const SAVE_SERVICE := preload("res://scripts/save_service.gd")
const PROGRESSION := preload("res://scripts/progression_service.gd")
const TEST_DIRECTORY := "user://endless_standard_progression_smoke"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var saves = SAVE_SERVICE.new(directory)
	var progression = PROGRESSION.new(saves, "0")
	var initial: Dictionary = progression.load_profile()["profile"]
	if int(initial["profile_version"]) != 9 or initial["endless_standard_unlocked"] or \
			initial["endless_standard_records"]["easy"]["wave"] != 0:
		_fail("New profiles should start at v9 with Endless locked and empty difficulty records")
		return
	var legacy := initial.duplicate(true)
	legacy["profile_version"] = 8
	legacy.erase("endless_standard_unlocked")
	legacy.erase("endless_standard_records")
	if not saves.save_slot("0", legacy):
		_fail("Could not seed a v8 profile")
		return
	var migrated: Dictionary = progression.load_profile()["profile"]
	if int(migrated["profile_version"]) != 9 or migrated["endless_standard_unlocked"] or \
			migrated["endless_standard_records"]["chaos"]["wave"] != 0:
		_fail("A v8 profile should migrate additively with Endless locked and empty records")
		return
	var locked_reward: Dictionary = progression.award_endless_standard_run("locked-run", 1, 0, "easy")
	var locked_record: Dictionary = progression.record_endless_standard_result("easy", 1, 30.0, 0)
	if locked_reward.get("ok", true) or locked_reward.get("error") != "endless_standard_locked" or \
		locked_record.get("ok", true) or locked_record.get("error") != "endless_standard_locked":
		_fail("Endless rewards and records should be rejected until Survival unlocks the mode")
		return
	var survival_win: Dictionary = progression.award_survival_run("endless-unlock", 24, true, 1, "easy")
	if not survival_win.get("ok", false) or \
			not progression.load_profile()["profile"]["endless_standard_unlocked"]:
		_fail("A Survival final-boss victory should unlock Endless standard")
		return
	var record: Dictionary = progression.record_endless_standard_result("easy", 36, 3600.0, 100)
	var weaker_record: Dictionary = progression.record_endless_standard_result("easy", 35, 7200.0, 999)
	if not record.get("ok", false) or not record.get("updated", false) or \
			weaker_record.get("updated", true) or \
			int(progression.load_profile()["profile"]["endless_standard_records"]["easy"]["wave"]) != 36:
		_fail("Endless records should rank wave first, then survival time and kills")
		return
	var equipment_before: Array = progression.load_profile()["profile"]["equipment_inventory"].duplicate(true)
	var resources_before: Dictionary = progression.load_profile()["profile"]["resources"].duplicate(true)
	var reward: Dictionary = progression.award_endless_standard_run("endless-run", 36, 100, "easy")
	var rewarded_profile: Dictionary = progression.load_profile()["profile"]
	if not reward.get("ok", false) or int(reward["essence"]) != 61 or \
			int(reward["powder_basic"]) != 90 or \
		rewarded_profile["equipment_inventory"] != equipment_before or \
		int(rewarded_profile["resources"]["essence"]) - int(resources_before["essence"]) != 61:
		_fail("Endless should grant proposed Survival-formula resources and no permanent equipment")
		return
	var duplicate: Dictionary = progression.award_endless_standard_run("endless-run", 36, 100, "easy")
	var after_duplicate: Dictionary = progression.load_profile()["profile"]
	if not duplicate.get("ok", false) or not duplicate.get("duplicate", false) or \
		after_duplicate["resources"] != rewarded_profile["resources"] or \
		after_duplicate["achievement_progress"] != rewarded_profile["achievement_progress"]:
		_fail("Endless rewards should remain idempotent by run ID")
		return
	print("Endless standard progression smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
