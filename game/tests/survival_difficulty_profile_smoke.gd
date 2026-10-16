extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path("user://survival_difficulty_profile_smoke")
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var save_service = load("res://scripts/save_service.gd").new(directory)
	var service = load("res://scripts/progression_service.gd").new(save_service, "fresh")
	var profile: Dictionary = service.load_profile()["profile"]
	if profile["profile_version"] != 7 or profile["highest_unlocked_difficulty"] != "easy":
		_fail("A new profile should start with Easy unlocked")
		return
	var difficulty = load("res://scripts/survival_difficulty.gd")
	if difficulty.ORDER != ["easy", "normal", "hard", "nightmare", "chaos"] or \
		difficulty.DATA["normal"]["enemy_hp"] != 1.0 or difficulty.DATA["chaos"]["powder"] != 3.5:
		_fail("Difficulty order and provisional GDD factors should be centralized")
		return
	if not save_service.save_slot("legacy", {
		"profile_version": 5, "resources": {
			"essence": 47, "powder_basic": 9, "powder_refined": 2,
			"powder_pure": 1, "powder_prismatic": 0,
		},
		"equipment_inventory": [], "rewarded_survival_runs": ["old-run"],
		"unlocked_skill_nodes": [], "achievement_progress": {"total_kills": 12, "exterminator_tier": 0},
	}):
		_fail("The legacy profile fixture should save")
		return
	var legacy_service = load("res://scripts/progression_service.gd").new(save_service, "legacy")
	var migrated: Dictionary = legacy_service.load_profile()
	if not migrated.get("ok", false) or migrated["profile"]["profile_version"] != 7 or \
		migrated["profile"]["highest_unlocked_difficulty"] != "easy" or \
		migrated["profile"]["resources"]["essence"] != 47 or \
		migrated["profile"]["rewarded_survival_runs"] != ["old-run"] or \
		migrated["profile"]["achievement_progress"]["metrics"]["total_kills"] != 12:
		_fail("A version 5 profile should gain the default unlock without losing progression")
		return
	if not save_service.save_slot("version-two", {
		"profile_version": 2, "resources": {"essence": 13, "powder_basic": 4},
		"equipment_inventory": [], "rewarded_survival_runs": [],
	}):
		_fail("The version 2 profile fixture should save")
		return
	var version_two_service = load("res://scripts/progression_service.gd").new(save_service, "version-two")
	var migrated_v2: Dictionary = version_two_service.load_profile()
	if not migrated_v2.get("ok", false) or migrated_v2["profile"]["profile_version"] != 7 or \
		migrated_v2["profile"]["highest_unlocked_difficulty"] != "easy" or \
		migrated_v2["profile"]["resources"]["essence"] != 13:
		_fail("A version 2 profile should migrate to the current schema without losing resources")
		return
	print("Survival difficulty profile smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
