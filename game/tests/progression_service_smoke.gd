extends SceneTree

const TEST_DIRECTORY := "user://progression_service_smoke"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var save_service = load("res://scripts/save_service.gd").new(directory)
	var service = load("res://scripts/progression_service.gd").new(save_service, "0")
	var victory: Dictionary = service.award_survival_run("run-win", 24, true)
	if not victory.get("ok", false) or victory.get("essence") != 88 or victory.get("powder_basic") != 122:
		_fail("A Normal wave 24 victory should grant the GDD proposed 88 Essence and 122 Basic Powder")
		return
	var profile: Dictionary = save_service.load_slot("0")["payload"]
	var inventory: Array = profile["equipment_inventory"]
	if inventory.size() != 1 or inventory[0].get("source_mode") != "survival" or \
			inventory[0].get("instance_id") != "survival_run-win_equipment":
		_fail("Every completed Survival run should add one permanent equipment instance")
		return
	if not _valid_equipment_instance(inventory[0]):
		_fail("The equipment instance should use a valid slot, rarity and unique stat lines")
		return
	var duplicate: Dictionary = service.award_survival_run("run-win", 24, true)
	if not duplicate.get("ok", false) or not duplicate.get("duplicate", false):
		_fail("Reprocessing one run ID should be idempotent")
		return
	var defeat: Dictionary = service.award_survival_run("run-loss", 12, false)
	if not defeat.get("ok", false) or defeat.get("essence") != 39 or defeat.get("powder_basic") != 56:
		_fail("A defeated run should grant the proposed resources for its last reached wave")
		return
	profile = save_service.load_slot("0")["payload"]
	if profile["resources"].get("essence") != 127 or profile["resources"].get("powder_basic") != 178:
		_fail("Distinct completed runs should accumulate their resources")
		return
	if profile["equipment_inventory"].size() != 2 or \
			profile["equipment_inventory"][1].get("instance_id") != "survival_run-loss_equipment":
		_fail("A defeated run should also add exactly one permanent equipment instance")
		return
	var legacy_service = load("res://scripts/progression_service.gd").new(save_service, "legacy")
	if not save_service.save_slot("legacy", {
		"profile_version": 1,
		"resources": {"essence": 7, "powder_basic": 3},
		"rewarded_survival_runs": ["already-awarded"],
	}):
		_fail("A version 1 profile fixture should save")
		return
	var migrated_duplicate: Dictionary = legacy_service.award_survival_run("already-awarded", 24, true)
	var migrated_profile: Dictionary = save_service.load_slot("legacy")["payload"]
	if not migrated_duplicate.get("ok", false) or not migrated_duplicate.get("duplicate", false) or \
			migrated_profile.get("profile_version") != 2 or migrated_profile["resources"].get("essence") != 7 or \
			migrated_profile["equipment_inventory"].size() != 0:
		_fail("A previous progression profile should migrate without losing resources or replaying a reward")
		return
	print("Progression service smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _valid_equipment_instance(equipment: Dictionary) -> bool:
	var line_counts := {"normal": 1, "magic": 2, "mystic": 3, "legendary": 3, "mythic": 4}
	var stats: Dictionary = {}
	for line in equipment["stat_lines"]:
		var stat_id: String = line["stat_id"]
		var percentile := float(line["roll_percentile"])
		if stats.has(stat_id) or percentile < 0.0 or percentile >= 1.0 or \
				line["enhancement_level"] != 0 or line["fail_streak"] != 0:
			return false
		stats[stat_id] = true
	var rarity: String = equipment["rarity"]
	return ["helmet", "armor", "gloves", "boots", "amulet", "ring"].has(equipment["slot"]) and \
			line_counts.has(rarity) and equipment["stat_lines"].size() == line_counts[rarity] and \
			(not rarity in ["legendary", "mythic"] or equipment["unique_effect_id"] == "pending_choice")
