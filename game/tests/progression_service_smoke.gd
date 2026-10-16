extends SceneTree

const TEST_DIRECTORY := "user://progression_service_smoke"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var equipment_generator = load("res://scripts/equipment_generator.gd")
	var easy_start: Array = equipment_generator.rarity_weights_for("easy", 1)
	var easy_final: Array = equipment_generator.rarity_weights_for("easy", 24)
	var chaos_final: Array = equipment_generator.rarity_weights_for("chaos", 24)
	if easy_start != [60.0, 30.0, 9.0, 0.9, 0.1] or \
		not is_equal_approx(easy_final[0], 56.0) or \
		not is_equal_approx(easy_final[1], 33.0) or \
		not is_equal_approx(chaos_final[0], 0.0) or \
		not is_equal_approx(easy_final.reduce(func(sum: float, weight: float) -> float: return sum + weight, 0.0), 100.0):
		_fail("Equipment rarity weights should follow difficulty and the proposed wave progression rule")
		return
	var context_changes_roll := false
	for seed_value in range(1, 10001):
		var early_generator = equipment_generator.new(seed_value)
		var late_generator = equipment_generator.new(seed_value)
		var early_item: Dictionary = early_generator.generate_survival_item("early", "easy", 1)
		var late_item: Dictionary = late_generator.generate_survival_item("late", "easy", 24)
		if early_item["rarity"] != late_item["rarity"]:
			context_changes_roll = true
			break
	if not context_changes_roll:
		_fail("Seeded run equipment generation should consume difficulty and reached wave context")
		return
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var save_service = load("res://scripts/save_service.gd").new(directory)
	var service = load("res://scripts/progression_service.gd").new(save_service, "0")
	var initial_profile: Dictionary = service.load_profile()["profile"]
	if initial_profile.get("highest_unlocked_difficulty") != "easy":
		_fail("A new profile should begin with Easy as its only unlocked difficulty")
		return
	initial_profile["highest_unlocked_difficulty"] = "normal"
	if not save_service.save_slot("0", initial_profile):
		_fail("Could not seed the Normal reward fixture")
		return
	var victory: Dictionary = service.award_survival_run("run-win", 24, true)
	if not victory.get("ok", false) or victory.get("essence") != 88 or victory.get("powder_basic") != 122:
		_fail("A Normal wave 24 victory should grant the GDD proposed 88 Essence and 122 Basic Powder")
		return
	var profile: Dictionary = save_service.load_slot("0")["payload"]
	if profile.get("profile_version") != 6 or profile.get("highest_unlocked_difficulty") != "hard" or \
			profile["resources"].get("powder_refined") != 0 or \
			profile["resources"].get("powder_pure") != 0 or profile["resources"].get("powder_prismatic") != 0:
		_fail("Progression should initialize all powder tiers and unlock the next difficulty after the Normal victory fixture")
		return
	var difficulties = load("res://scripts/survival_difficulty.gd")
	if difficulties.ORDER != ["easy", "normal", "hard", "nightmare", "chaos"] or \
		difficulties.DATA["normal"]["enemy_hp"] != 1.0 or \
		difficulties.DATA["chaos"]["powder"] != 3.5:
		_fail("Survival difficulties should expose the GDD tuning table in one place")
		return
	var inventory: Array = profile["equipment_inventory"]
	if inventory.size() != 1 or inventory[0].get("source_mode") != "survival" or \
			inventory[0].get("instance_id") != "survival_run-win_equipment":
		_fail("Every completed Survival run should add one permanent equipment instance")
		return
	if not equipment_generator.PROPOSED_STAT_RANGES.has("damage_pct") or \
				not is_equal_approx(equipment_generator.stat_value("damage_pct", 0.5, 2), 3.48) or \
			equipment_generator.stat_value("damage_pct", 1.0, 0) != 5.0:
		_fail("Proposed equipment stat percentiles and enhancements should produce calibrated values")
		return
	var unique_stat_ids := ["damage_pct", "max_hp", "attack_speed_pct"]
	inventory[0]["rarity"] = "legendary"
	inventory[0]["stat_lines"] = []
	for stat_id in unique_stat_ids:
		inventory[0]["stat_lines"].append({
			"stat_id": stat_id, "roll_percentile": 0.5,
			"enhancement_level": 0, "fail_streak": 0,
		})
	inventory[0]["unique_effect_id"] = "pending_choice"
	if not save_service.save_slot("0", profile):
		_fail("The unique effect fixture should save")
		return
	if service.choose_unique_effect(inventory[0]["instance_id"], "revive_knockback").get("error") != "invalid_unique_effect":
		_fail("Unique effects without gameplay should not be offered for new equipment")
		return
	var chosen_effect: Dictionary = service.choose_unique_effect(inventory[0]["instance_id"], "overflow_shield")
	if not chosen_effect.get("ok", false) or \
			chosen_effect["profile"]["equipment_inventory"][0]["unique_effect_id"] != "overflow_shield":
		_fail("Legendary equipment should persist one eligible unique effect choice")
		return
	profile = chosen_effect["profile"]
	inventory = profile["equipment_inventory"]
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
			not first_equipped["profile"]["equipment_inventory"][0].get("equipped", false) or \
				not is_equal_approx(service.equipment_bonus("damage_pct"), 3.24) or \
				not is_equal_approx(service.equipment_bonus("max_hp"), 5.0) or \
				service.equipped_unique_effects() != ["overflow_shield"]:
		_fail("Equipping a permanent item should persist its state and activate proposed damage/HP lines")
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
	profile = service.load_profile()["profile"]
	inventory = profile["equipment_inventory"]
	inventory[0]["slot"] = "helmet"
	inventory[1]["slot"] = "armor"
	for item in inventory:
		item["rarity"] = "legendary"
		item["stat_lines"] = []
		for stat_id in unique_stat_ids:
			item["stat_lines"].append({
				"stat_id": stat_id, "roll_percentile": 0.5,
				"enhancement_level": 0, "fail_streak": 0,
			})
		item["equipped"] = true
		item["unique_effect_id"] = "overflow_shield"
	profile["equipment_inventory"] = inventory
	if not save_service.save_slot("0", profile):
		_fail("The duplicate unique effect fixture should save")
		return
	if service.equipped_unique_effects() != ["overflow_shield"]:
		_fail("The same unique effect on multiple equipped items should activate once, not stack: %s" % [service.equipped_unique_effects()])
		return
	profile = service.load_profile()["profile"]
	profile["resources"]["essence"] = 200
	if not save_service.save_slot("0", profile):
		_fail("The skill tree fixture should save")
		return
	if service.unlock_skill_node("focused_training").get("error") != "skill_prerequisite_locked":
		_fail("A skill node should reject purchase until its prerequisite is unlocked")
		return
	var unlocked: Dictionary = service.unlock_skill_node("vitality_starter")
	var focused: Dictionary = service.unlock_skill_node("focused_training")
	if service.skill_node_cost("vitality_starter") != 50 or service.skill_node_cost("focused_training") != 80 or \
			not unlocked.get("ok", false) or not focused.get("ok", false) or \
			service.skill_bonus("max_hp_pct") != 0.05 or service.skill_bonus("damage_pct") != 0.03 or \
			focused["profile"]["resources"]["essence"] != 70 or \
			service.unlock_skill_node("vitality_starter").get("ok", false):
		_fail("The prototype skill node should spend Essence once and expose its proposed passive bonus")
		return
	var respecced: Dictionary = service.respec_skill_tree()
	if not respecced.get("ok", false) or service.skill_bonus("max_hp_pct") != 0.0 or \
			service.skill_bonus("damage_pct") != 0.0 or respecced["profile"]["resources"]["essence"] != 200:
		_fail("Skill respec should be free and refund the spent Essence")
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
			migrated_profile.get("profile_version") != 6 or \
			migrated_profile.get("highest_unlocked_difficulty") != "easy" or \
			migrated_profile["resources"].get("essence") != 7 or \
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
	if not migrated_profile_result.get("ok", false) or migrated_profile_result["profile"].get("profile_version") != 6 or \
			migrated_inventory.size() != 2 or migrated_inventory[0].get("equipped", true) or migrated_inventory[1].get("equipped", true):
		_fail("Version 2 equipment should migrate as unequipped without losing items")
		return
	var dismantled: Dictionary = service.dismantle_equipment("survival_run-win_equipment")
	if not dismantled.get("ok", false) or dismantled["profile"]["equipment_inventory"].size() != 1 or \
		dismantled["profile"]["resources"]["powder_refined"] != 4 or \
			service.dismantle_equipment("survival_run-win_equipment").get("ok", false):
		_fail("Dismantling should remove the item once and persist its proposed rarity powder reward")
		return
	var achievement_service = load("res://scripts/progression_service.gd").new(save_service, "achievement")
	var achievement_run: Dictionary = achievement_service.award_survival_run("kill-run", 24, true, 100, "easy")
	var achievement_profile: Dictionary = achievement_service.load_profile()["profile"]
	if achievement_run.get("new_achievement_tiers") != 1 or \
			achievement_profile["achievement_progress"]["total_kills"] != 100 or \
			achievement_service.achievement_bonus("damage_pct") != 0.0005:
		_fail("The first Exterminator tier should grant only its proposed cumulative damage bonus")
		return
	var second_achievement_run: Dictionary = achievement_service.award_survival_run("kill-run-two", 24, true, 900, "easy")
	if second_achievement_run.get("new_achievement_tiers") != 1 or \
			achievement_service.achievement_bonus("damage_pct") != 0.0015 or \
			achievement_service.award_survival_run("kill-run-two", 24, true, 1000, "easy").get("duplicate") != true or \
			achievement_service.load_profile()["profile"]["achievement_progress"]["total_kills"] != 1000:
		_fail("The proposed Exterminator tier should unlock once and run rewards should stay idempotent")
		return
	achievement_service.award_survival_run("kill-run-three", 24, true, 9000, "easy")
	achievement_service.award_survival_run("kill-run-four", 24, true, 90000, "easy")
	if achievement_service.achievement_bonus("damage_pct") != 0.005 or \
			achievement_service.load_profile()["profile"]["achievement_progress"]["exterminator_tier"] != 4:
		_fail("All four proposed Exterminator tiers should accumulate the example total bonus")
		return
	var unlock_directory := directory.path_join("difficulty_unlock")
	DirAccess.make_dir_recursive_absolute(unlock_directory)
	for file_name in DirAccess.get_files_at(unlock_directory):
		DirAccess.remove_absolute(unlock_directory.path_join(file_name))
	var unlock_save_service = load("res://scripts/save_service.gd").new(unlock_directory)
	var unlock_service = load("res://scripts/progression_service.gd").new(unlock_save_service, "0")
	var locked_normal: Dictionary = unlock_service.award_survival_run("locked-normal", 24, true, 0, "normal")
	if locked_normal.get("ok", false) or locked_normal.get("error") != "difficulty_locked":
		_fail("Progression should reject rewards from a difficulty that has not been unlocked")
		return
	var easy_defeat: Dictionary = unlock_service.award_survival_run("easy-defeat", 24, false, 0, "easy")
	if not easy_defeat.get("ok", false) or \
		unlock_service.load_profile()["profile"].get("highest_unlocked_difficulty") != "easy":
		_fail("A defeat should not unlock the next difficulty")
		return
	var easy_victory: Dictionary = unlock_service.award_survival_run("easy-victory", 24, true, 0, "easy")
	if not easy_victory.get("ok", false) or easy_victory.get("essence") != 62 or easy_victory.get("powder_basic") != 85 or \
		unlock_service.load_profile()["profile"].get("highest_unlocked_difficulty") != "normal":
		_fail("An Easy victory should unlock Normal and apply Easy reward multipliers")
		return
	var skipped_hard: Dictionary = unlock_service.award_survival_run("skipped-hard", 24, true, 0, "hard")
	if skipped_hard.get("ok", false) or skipped_hard.get("error") != "difficulty_locked":
		_fail("The profile should not skip Normal and enter Hard")
		return
	for index in range(1, difficulties.ORDER.size()):
		var difficulty_id: String = difficulties.ORDER[index]
		var result: Dictionary = unlock_service.award_survival_run("difficulty-win-%s" % difficulty_id, 24, true, 0, difficulty_id)
		var expected_unlocked: String = difficulties.ORDER[mini(index + 1, difficulties.ORDER.size() - 1)]
		if not result.get("ok", false) or \
				unlock_service.load_profile()["profile"].get("highest_unlocked_difficulty") != expected_unlocked:
			_fail("A victory on %s should unlock only its next difficulty" % difficulty_id)
			return
		if difficulty_id == "chaos" and (result.get("essence") != 352 or result.get("powder_basic") != 427):
			_fail("Chaos victory rewards should use their separate proposed multipliers")
			return
	var legacy_effect_profile: Dictionary = service.load_profile()["profile"]
	legacy_effect_profile["equipment_inventory"][0]["unique_effect_id"] = "revive_knockback"
	if not save_service.save_slot("0", legacy_effect_profile) or not service.load_profile().get("ok", false) or \
		service.equipped_unique_effects().has("revive_knockback"):
		_fail("A stored unsupported effect should remain loadable but must not activate or be newly selectable")
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
			(not rarity in ["legendary", "mythic"] or equipment["unique_effect_id"] in ["pending_choice", "overflow_shield"])
