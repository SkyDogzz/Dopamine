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
	if profile.get("profile_version") != 4 or profile["resources"].get("powder_refined") != 0 or \
			profile["resources"].get("powder_pure") != 0 or profile["resources"].get("powder_prismatic") != 0:
		_fail("New progression profiles should initialize all four powder tiers")
		return
	var inventory: Array = profile["equipment_inventory"]
	if inventory.size() != 1 or inventory[0].get("source_mode") != "survival" or \
			inventory[0].get("instance_id") != "survival_run-win_equipment":
		_fail("Every completed Survival run should add one permanent equipment instance")
		return
	profile["resources"]["powder_basic"] = 100
	inventory[0]["stat_lines"][0]["fail_streak"] = 9
	profile["equipment_inventory"] = inventory
	if not save_service.save_slot("0", profile):
		_fail("The guaranteed enhancement fixture should save")
		return
	var enhanced: Dictionary = service.enhance_equipment(
		inventory[0]["instance_id"], inventory[0]["stat_lines"][0]["stat_id"], "basic"
	)
	var enhanced_profile: Dictionary = save_service.load_slot("0")["payload"]
	if not enhanced.get("ok", false) or not enhanced.get("success", false) or \
			enhanced["profile"]["equipment_inventory"][0]["stat_lines"][0]["enhancement_level"] != 1 or \
			enhanced_profile["resources"]["powder_basic"] != 100 - enhanced["cost"]:
		_fail("A tenth consecutive enhancement attempt should succeed and consume its target-level powder cost")
		return
	inventory = enhanced_profile["equipment_inventory"]
	var conversion: Dictionary = service.convert_powder("basic", 10)
	if not conversion.get("ok", false) or conversion["profile"]["resources"]["powder_basic"] != 90 - enhanced["cost"] or \
			conversion["profile"]["resources"]["powder_refined"] != 1:
		_fail("Ten lower-tier powder should convert into one powder of the next tier")
		return
	if not _valid_equipment_instance(inventory[0]):
		_fail("The equipment instance should use a valid slot, rarity and unique stat lines")
		return
	if inventory[0].get("equipped", true):
		_fail("New permanent equipment should start unequipped")
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
	if profile["resources"].get("essence") != 127 or profile["resources"].get("powder_basic") != 146 - enhanced["cost"]:
		_fail("Distinct completed runs should accumulate their resources")
		return
	if profile["equipment_inventory"].size() != 2 or \
			profile["equipment_inventory"][1].get("instance_id") != "survival_run-loss_equipment":
		_fail("A defeated run should also add exactly one permanent equipment instance")
		return
	var equipment: Array = profile["equipment_inventory"]
	equipment[1]["slot"] = equipment[0]["slot"]
	profile["equipment_inventory"] = equipment
	if not save_service.save_slot("0", profile):
		_fail("The same-slot equipment fixture should save")
		return
	var first_equipped: Dictionary = service.set_equipped("survival_run-win_equipment", true)
	if not first_equipped.get("ok", false) or \
			not first_equipped["profile"]["equipment_inventory"][0].get("equipped", false):
		_fail("Equipping a permanent item should persist its equipped state")
		return
	var replacement: Dictionary = service.set_equipped("survival_run-loss_equipment", true)
	var replaced_inventory: Array = replacement.get("profile", {}).get("equipment_inventory", [])
	if not replacement.get("ok", false) or replaced_inventory.size() != 2 or \
			replaced_inventory[0].get("equipped", false) or not replaced_inventory[1].get("equipped", false):
		_fail("Equipping an item should replace the previously equipped item in the same slot")
		return
	var unequipped: Dictionary = service.set_equipped("survival_run-loss_equipment", false)
	if not unequipped.get("ok", false) or \
			unequipped["profile"]["equipment_inventory"][1].get("equipped", true):
		_fail("A permanent item should be unequippable")
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
			migrated_profile.get("profile_version") != 4 or migrated_profile["resources"].get("essence") != 7 or \
			migrated_profile["equipment_inventory"].size() != 0:
		_fail("A previous progression profile should migrate without losing resources or replaying a reward")
		return
	var version_two_profile: Dictionary = profile.duplicate(true)
	version_two_profile["profile_version"] = 2
	for item in version_two_profile["equipment_inventory"]:
		item.erase("equipped")
	if not save_service.save_slot("version-two", version_two_profile):
		_fail("A version 2 profile fixture should save")
		return
	var version_two_service = load("res://scripts/progression_service.gd").new(save_service, "version-two")
	var migrated_profile_result: Dictionary = version_two_service.load_profile()
	var migrated_inventory: Array = migrated_profile_result.get("profile", {}).get("equipment_inventory", [])
	if not migrated_profile_result.get("ok", false) or migrated_profile_result["profile"].get("profile_version") != 4 or \
			migrated_inventory.size() != 2 or migrated_inventory[0].get("equipped", true) or migrated_inventory[1].get("equipped", true):
		_fail("Version 2 equipment should migrate as unequipped without losing items")
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
				line["enhancement_level"] < 0 or line["enhancement_level"] > 10 or line["fail_streak"] < 0:
			return false
		stats[stat_id] = true
	var rarity: String = equipment["rarity"]
	return ["helmet", "armor", "gloves", "boots", "amulet", "ring"].has(equipment["slot"]) and \
			line_counts.has(rarity) and equipment["stat_lines"].size() == line_counts[rarity] and \
		equipment.get("equipped") is bool and \
			(not rarity in ["legendary", "mythic"] or equipment["unique_effect_id"] == "pending_choice")
