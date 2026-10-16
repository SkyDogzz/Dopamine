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
	if profile.get("profile_version") != 7 or profile.get("highest_unlocked_difficulty") != "hard" or \
			profile["resources"].get("powder_refined") != 0 or \
			profile["resources"].get("powder_pure") != 0 or profile["resources"].get("powder_prismatic") != 0:
		_fail("Progression should initialize all powder tiers and unlock the next difficulty after the Normal victory fixture")
		return
	var no_save_progression = load("res://scripts/progression_service.gd").new(null, "temporary")
	if no_save_progression.can_save_profile() or \
			no_save_progression.unlocked_weapon_ids() != ["lightning_conductor", "inferno_sprayer"] or \
			no_save_progression.unlocked_relic_ids() != ["storm_core", "infernal_heart"]:
		_fail("A no-save progression context should expose only the starter loadout without enabling persistence")
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
	var before_restart: Dictionary = service.load_profile()["profile"]
	var restarted_service = load("res://scripts/progression_service.gd").new(save_service, "0")
	var duplicate_after_restart: Dictionary = restarted_service.award_survival_run("run-win", 24, true)
	var after_restart: Dictionary = restarted_service.load_profile()["profile"]
	if not duplicate_after_restart.get("ok", false) or not duplicate_after_restart.get("duplicate", false) or \
			after_restart["resources"] != before_restart["resources"] or \
			after_restart["equipment_inventory"].size() != before_restart["equipment_inventory"].size():
		_fail("A rewarded run ID should remain idempotent after recreating the progression service")
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
	profile["resources"]["essence"] = 50000
	if not save_service.save_slot("0", profile):
		_fail("The skill tree fixture should save")
		return
	if service.unlocked_weapon_ids().size() != 2 or service.unlocked_relic_ids().size() != 2:
		_fail("A new profile should start with exactly two weapons and two relics")
		return
	var every_skill_node: Array[String] = service.skill_node_ids()
	if every_skill_node.size() != 100:
		_fail("The proposed skill tree should expose 100 interconnected nodes")
		return
	var all_node_cost := 0
	var equipment_node_cost := 0
	var equipment_node_count := 0
	for node_id in every_skill_node:
		var cost: int = service.skill_node_cost(node_id)
		all_node_cost += cost
		if node_id.begins_with("unlock_"):
			equipment_node_cost += cost
			equipment_node_count += 1
	var normal_boss_reward := roundi((15.0 + 2.0 * 24.0 + 25.0) * 1.0)
	if all_node_cost != 15900 or equipment_node_cost != 4160 or equipment_node_count != 17 or \
		not is_equal_approx(float(equipment_node_cost) / float(equipment_node_count) / normal_boss_reward, 2.78075):
		_fail("Proposed skill tree cost pacing should remain reproducible against a Normal boss victory")
		return
	var full_tree_victory_equivalents: Array[int] = []
	for difficulty_id in difficulties.ORDER:
		var reward := roundi(88.0 * float(difficulties.DATA[difficulty_id]["essence"]))
		full_tree_victory_equivalents.append(ceili(float(all_node_cost) / float(reward)))
	if full_tree_victory_equivalents != [257, 181, 113, 73, 46]:
		_fail("Full-tree victory equivalents should reflect the proposed Essence multipliers per difficulty")
		return
	if service.unlocked_weapon_ids() != ["lightning_conductor", "inferno_sprayer"] or \
		service.unlocked_relic_ids() != ["storm_core", "infernal_heart"]:
		_fail("A new profile should start with the prototype starter weapon/relic pairs")
		return
	if service.unlock_skill_node("focused_training").get("error") != "skill_prerequisite_locked":
		_fail("A skill node should reject purchase until its prerequisite is unlocked")
		return
	if service.unlock_skill_node("fleet_footed").get("error") != "skill_prerequisite_locked":
		_fail("A mastery node should reject purchase until its branch prerequisite is unlocked")
		return
	if service.unlock_skill_node("steady_aim").get("error") != "skill_prerequisite_locked":
		_fail("An advanced stat node should reject purchase until its mastery prerequisite is unlocked")
		return
	if service.unlock_skill_node("unlock_blood_chalice").get("error") != "skill_prerequisite_locked":
		_fail("A relic unlock should reject purchase until its weapon branch prerequisite is unlocked")
		return
	var unlocked: Dictionary = service.unlock_skill_node("vitality_starter")
	var focused: Dictionary = service.unlock_skill_node("focused_training")
	var fleet: Dictionary = service.unlock_skill_node("fleet_footed")
	var steady_aim: Dictionary = service.unlock_skill_node("steady_aim")
	var daggers: Dictionary = service.unlock_skill_node("unlock_crimson_daggers")
	var chalice: Dictionary = service.unlock_skill_node("unlock_blood_chalice")
	if service.skill_node_cost("vitality_starter") != 50 or service.skill_node_cost("focused_training") != 80 or \
			service.skill_node_cost("fleet_footed") != 110 or service.skill_node_cost("steady_aim") != 140 or \
			service.skill_node_cost("unlock_crimson_daggers") != 130 or \
			service.skill_node_cost("unlock_blood_chalice") != 160 or \
			not unlocked.get("ok", false) or not focused.get("ok", false) or not fleet.get("ok", false) or \
			not steady_aim.get("ok", false) or not daggers.get("ok", false) or not chalice.get("ok", false) or \
			service.skill_bonus("max_hp_pct") != 0.05 or service.skill_bonus("damage_pct") != 0.03 or \
			service.skill_bonus("move_speed_pct") != 0.02 or \
			service.skill_bonus("critical_chance_pct") != 1.0 or \
			steady_aim["profile"]["resources"]["essence"] != 49620 or \
			service.unlocked_weapon_ids().size() != 3 or not service.unlocked_weapon_ids().has("crimson_daggers") or \
			service.unlocked_relic_ids().size() != 3 or not service.unlocked_relic_ids().has("blood_chalice") or \
			service.unlock_skill_node("vitality_starter").get("ok", false):
		_fail("The proposed skill branch should enforce prerequisites, spend Essence once and expose its passive bonuses")
		return
	for node_id in every_skill_node:
		if node_id in ["vitality_starter", "focused_training", "fleet_footed", "steady_aim", \
			"unlock_crimson_daggers", "unlock_blood_chalice"]:
			continue
		var unlock_result: Dictionary = service.unlock_skill_node(node_id)
		if not unlock_result.get("ok", false):
			_fail("Every proposed skill node should be purchasable after its prerequisites: %s" % node_id)
			return
	var catalog = load("res://scripts/combat_catalog.gd").new()
	if service.unlocked_weapon_ids().size() != catalog.available_ids("weapon").size() or \
		service.unlocked_relic_ids().size() != catalog.available_ids("relic").size():
		_fail("Purchasing every equipment node should expose all playable catalog entries")
		return
	var power_budget_proxy: float = service.skill_bonus("max_hp_pct") * 100.0 + \
		service.skill_bonus("damage_pct") * 100.0 + service.skill_bonus("move_speed_pct") * 100.0 + \
		service.skill_bonus("critical_chance_pct")
	if not is_equal_approx(power_budget_proxy, 29.7):
		_fail("All stat nodes should stay near the proposed 30-point linear power budget: %.2f" % power_budget_proxy)
		return
	var respecced: Dictionary = service.respec_skill_tree()
	if not respecced.get("ok", false) or service.skill_bonus("max_hp_pct") != 0.0 or \
			service.skill_bonus("damage_pct") != 0.0 or service.skill_bonus("move_speed_pct") != 0.0 or \
		service.skill_bonus("critical_chance_pct") != 0.0 or respecced["profile"]["resources"]["essence"] != 50000 or \
			service.unlocked_weapon_ids().size() != 2 or service.unlocked_relic_ids().size() != 2:
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
			migrated_profile.get("profile_version") != 7 or \
			migrated_profile.get("highest_unlocked_difficulty") != "easy" or \
			migrated_profile["resources"].get("essence") != 7 or \
			migrated_profile["equipment_inventory"].size() != 0:
		_fail("A previous progression profile should migrate without losing resources or replaying a reward")
		return
	var migration_template_service = load("res://scripts/progression_service.gd").new(save_service, "migration-template")
	for version in range(3, 6):
		var fixture: Dictionary = migration_template_service.load_profile()["profile"].duplicate(true)
		fixture["profile_version"] = version
		fixture["resources"] = {
			"essence": 17, "powder_basic": 23, "powder_refined": 4,
			"powder_pure": 2, "powder_prismatic": 1,
		}
		fixture["rewarded_survival_runs"] = ["migration-v%d-run" % version]
		fixture["equipment_inventory"] = []
		fixture.erase("highest_unlocked_difficulty")
		fixture.erase("unlocked_skill_nodes")
		fixture.erase("achievement_progress")
		if version <= 4:
			fixture["equipment_inventory"] = [
				_capacity_migration_item("migration-v%d-item" % version),
			]
		if not save_service.save_slot("migration-v%d" % version, fixture):
			_fail("A version %d profile fixture should save" % version)
			return
		var migration_service = load("res://scripts/progression_service.gd").new(
			save_service, "migration-v%d" % version
		)
		var migration_result: Dictionary = migration_service.load_profile()
		if not migration_result.get("ok", false):
			_fail("A version %d profile should migrate: %s" % [version, migration_result])
			return
		var migrated_fixture: Dictionary = migration_result["profile"]
		var migrated_resources: Dictionary = migrated_fixture["resources"]
		var expected_equipment_count := 1 if version <= 4 else 0
		if migrated_fixture["profile_version"] != 7 or migrated_fixture["highest_unlocked_difficulty"] != "easy" or \
				migrated_fixture["rewarded_survival_runs"] != ["migration-v%d-run" % version] or \
				migrated_resources["essence"] != 17 or migrated_resources["powder_basic"] != 23 or \
				migrated_fixture["equipment_inventory"].size() != expected_equipment_count or \
				migrated_fixture["achievement_progress"]["metrics"]["total_kills"] != 0 or \
				migrated_fixture["achievement_progress"]["tiers"]["exterminator"] != 0:
			_fail("Version %d migration should preserve owned data and initialize only missing fields" % version)
			return
	if not save_service.save_slot("version-six", {
		"profile_version": 6,
		"resources": {"essence": 19, "powder_basic": 2, "powder_refined": 0, "powder_pure": 0, "powder_prismatic": 0},
		"equipment_inventory": [], "rewarded_survival_runs": ["v6-run"], "unlocked_skill_nodes": [],
		"highest_unlocked_difficulty": "normal",
		"achievement_progress": {"total_kills": 1234, "exterminator_tier": 2},
	}):
		_fail("A version 6 profile fixture should save")
		return
	var v6_service = load("res://scripts/progression_service.gd").new(save_service, "version-six")
	var v6_result: Dictionary = v6_service.load_profile()
	var v6_profile: Dictionary = v6_result.get("profile", {})
	if not v6_result.get("ok", false) or v6_profile.get("profile_version") != 7 or \
			v6_profile["achievement_progress"]["metrics"]["total_kills"] != 1234 or \
			v6_profile["achievement_progress"]["tiers"]["exterminator"] != 2 or \
			v6_profile["achievement_progress"]["tiers"]["survivor_depth"] != 0 or \
			v6_profile["resources"]["essence"] != 19 or v6_profile["rewarded_survival_runs"] != ["v6-run"]:
		_fail("Version 6 achievement progress should migrate to the generic metric/tier shape without loss")
		return
	var invalid_achievement_profile: Dictionary = v6_service.load_profile()["profile"]
	invalid_achievement_profile["achievement_progress"] = {"metrics": "invalid", "tiers": {}}
	if not save_service.save_slot("invalid-achievements", invalid_achievement_profile):
		_fail("Could not save a malformed achievement fixture")
		return
	var invalid_achievement_path := directory.path_join("slot_invalid-achievements.json")
	var invalid_achievement_bytes := FileAccess.get_file_as_string(invalid_achievement_path)
	var invalid_achievement_result: Dictionary = load("res://scripts/progression_service.gd").new(
		save_service, "invalid-achievements"
	).load_profile()
	if invalid_achievement_result.get("ok", false) or \
			FileAccess.get_file_as_string(invalid_achievement_path) != invalid_achievement_bytes:
		_fail("Malformed current achievement data should be rejected without being overwritten by migration")
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
	if not migrated_profile_result.get("ok", false) or migrated_profile_result["profile"].get("profile_version") != 7 or \
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
	if achievement_service._achievement_definitions.size() != 9 or \
		not achievement_service._achievement_definitions.has("survivor_depth") or \
		not achievement_service._achievement_definitions.has("veteran_runner") or \
		not achievement_service._achievement_definitions.has("boss_slayer") or \
		not achievement_service._achievement_definitions.has("chaos_conqueror"):
		_fail("Achievement catalog should include data-backed families across the currently supported run metrics")
		return
	var achievement_categories := {}
	for definition in achievement_service._achievement_definitions.values():
		achievement_categories[str(definition["category"])] = true
	if not achievement_categories.has("combat") or not achievement_categories.has("survival") or \
			not achievement_categories.has("progression") or not achievement_categories.has("difficulty_bosses") or \
			not achievement_categories.has("secrets") or not achievement_categories.has("weapons") or \
			not achievement_categories.has("relics_evolutions") or not achievement_categories.has("equipment") or \
			not achievement_service._achievement_definitions["chaos_conqueror"]["secret"]:
		_fail("The data-backed achievement tranche should cover all eight categories and retain secret state")
		return
	var run_metrics_directory := directory.path_join("run_metrics")
	DirAccess.make_dir_recursive_absolute(run_metrics_directory)
	var run_metrics_save = load("res://scripts/save_service.gd").new(run_metrics_directory)
	var run_metrics_service = load("res://scripts/progression_service.gd").new(run_metrics_save, "0")
	var run_metrics_award: Dictionary = run_metrics_service.award_survival_run("metrics-run", 12, false, 0, "easy", {
		"max_weapon_loadout": 3,
		"max_relic_loadout": 4,
		"evolutions_in_run": 2,
	})
	var run_metrics_profile: Dictionary = run_metrics_service.load_profile()["profile"]
	if not run_metrics_award.get("ok", false) or run_metrics_award.get("new_achievement_tier_count") != 8 or \
		run_metrics_profile["achievement_progress"]["metrics"].get("max_weapon_loadout") != 3 or \
		run_metrics_profile["achievement_progress"]["metrics"].get("max_relic_loadout") != 4 or \
		run_metrics_profile["achievement_progress"]["metrics"].get("evolutions_in_run") != 2 or \
		run_metrics_profile["achievement_progress"]["metrics"].get("equipment_items_collected") != 1 or \
		run_metrics_profile["achievement_progress"]["tiers"].get("arsenal_builder") != 2 or \
		run_metrics_profile["achievement_progress"]["tiers"].get("relic_collector") != 3 or \
		run_metrics_profile["achievement_progress"]["tiers"].get("evolutionist") != 1:
		_fail("Run build metrics should advance weapon, relic, evolution and survival achievements: %s" % [str(run_metrics_award)])
		return
	if run_metrics_service.award_survival_run("invalid-metrics", 12, false, 0, "easy", {"unknown_metric": 1}).get("error") != "invalid_achievement_metrics" or \
		run_metrics_service.load_profile()["profile"]["rewarded_survival_runs"].has("invalid-metrics"):
		_fail("Unknown run metrics must be rejected before any reward or idempotency state is saved")
		return
	var exterminator_definition: Dictionary = achievement_service._achievement_definitions.get("exterminator", {})
	if exterminator_definition.get("category", "") != "combat" or \
		exterminator_definition.get("metric", "") != "total_kills" or \
		exterminator_definition.get("aggregation", "") != "sum" or \
		exterminator_definition.get("secret", true) or exterminator_definition.get("tiers", []).size() != 4:
		_fail("Achievement definitions should load the metric/category/secret/tier schema from JSON")
		return
	var achievement_run: Dictionary = achievement_service.award_survival_run("kill-run", 24, true, 100, "easy")
	var achievement_profile: Dictionary = achievement_service.load_profile()["profile"]
	if achievement_run.get("new_achievement_tiers") != 1 or \
			achievement_run.get("new_achievement_tier_count") != 6 or \
			achievement_profile["achievement_progress"]["metrics"]["total_kills"] != 100 or \
			achievement_profile["achievement_progress"]["metrics"]["highest_wave"] != 24 or \
			achievement_profile["achievement_progress"]["metrics"]["boss_victories"] != 1 or \
			achievement_profile["achievement_progress"]["tiers"]["survivor_depth"] != 4 or \
			not is_equal_approx(achievement_service.achievement_bonus("damage_pct"), 0.0016):
		_fail("The first Exterminator tier should grant only its proposed cumulative damage bonus: award=%s progress=%s bonus=%s" % [
			str(achievement_run), str(achievement_profile["achievement_progress"]),
			str(achievement_service.achievement_bonus("damage_pct")),
		])
		return
	var second_achievement_run: Dictionary = achievement_service.award_survival_run("kill-run-two", 24, true, 900, "easy")
	if second_achievement_run.get("new_achievement_tiers") != 1 or \
			not is_equal_approx(achievement_service.achievement_bonus("damage_pct"), 0.0026) or \
			achievement_service.award_survival_run("kill-run-two", 24, true, 1000, "easy").get("duplicate") != true or \
			achievement_service.load_profile()["profile"]["achievement_progress"]["metrics"]["total_kills"] != 1000:
		_fail("The proposed Exterminator tier should unlock once and run rewards should stay idempotent: run=%s bonus=%s progress=%s" % [
			str(second_achievement_run), str(achievement_service.achievement_bonus("damage_pct")),
			str(achievement_service.load_profile()["profile"]["achievement_progress"]),
		])
		return
	achievement_service.award_survival_run("kill-run-three", 24, true, 9000, "easy")
	achievement_service.award_survival_run("kill-run-four", 24, true, 90000, "easy")
	if not is_equal_approx(achievement_service.achievement_bonus("damage_pct"), 0.0061) or \
			achievement_service.load_profile()["profile"]["achievement_progress"]["tiers"]["exterminator"] != 4:
		_fail("All four proposed Exterminator tiers should accumulate the example total bonus")
		return
	var achievement_before_chaos: Dictionary = achievement_service.load_profile()["profile"]
	achievement_before_chaos["highest_unlocked_difficulty"] = "chaos"
	if not save_service.save_slot("achievement", achievement_before_chaos):
		_fail("Could not prepare the Chaos achievement fixture")
		return
	var chaos_achievement_run: Dictionary = achievement_service.award_survival_run("chaos-achievement", 24, true, 0, "chaos")
	var chaos_achievement_profile: Dictionary = achievement_service.load_profile()["profile"]
	if chaos_achievement_run.get("new_achievement_tier_count") != 2 or \
			chaos_achievement_profile["achievement_progress"]["metrics"]["chaos_victories"] != 1 or \
			chaos_achievement_profile["achievement_progress"]["tiers"]["chaos_conqueror"] != 1 or \
			not is_equal_approx(achievement_service.achievement_bonus("damage_pct"), 0.0064):
		_fail("Secret Chaos achievements should track their metric before revealing their first tier")
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
	var recovery_baseline: Dictionary = service.load_profile()["profile"]
	var newer_profile := recovery_baseline.duplicate(true)
	newer_profile["resources"]["essence"] = int(newer_profile["resources"]["essence"]) + 1
	if not save_service.save_slot("0", newer_profile):
		_fail("A newer progression profile should be saved before corruption recovery")
		return
	var slot_path := directory.path_join("slot_0.json")
	var corrupt_file := FileAccess.open(slot_path, FileAccess.WRITE)
	corrupt_file.store_string("not json")
	corrupt_file.close()
	var restarted_save_service = load("res://scripts/save_service.gd").new(directory)
	var recovered_slot: Dictionary = restarted_save_service.load_slot("0")
	var restarted_progression_service = load("res://scripts/progression_service.gd").new(
		restarted_save_service, "0"
	)
	var recovered_profile: Dictionary = restarted_progression_service.load_profile()
	if not recovered_slot.get("ok", false) or not recovered_slot.get("recovered", false) or \
			int(recovered_slot["payload"]["resources"]["essence"]) != int(recovery_baseline["resources"]["essence"]) or \
			not recovered_profile.get("ok", false) or \
			recovered_profile["profile"]["equipment_inventory"].size() != recovery_baseline["equipment_inventory"].size() or \
			recovered_profile["profile"]["rewarded_survival_runs"] != recovery_baseline["rewarded_survival_runs"]:
		_fail("A restarted progression service should recover and validate the previous full profile backup")
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

func _capacity_migration_item(instance_id: String) -> Dictionary:
	return {
		"instance_id": instance_id, "slot": "helmet", "rarity": "normal",
		"equipped": false, "source_mode": "survival", "unique_effect_id": "",
		"stat_lines": [{
			"stat_id": "damage_pct", "roll_percentile": 0.5,
			"enhancement_level": 0, "fail_streak": 0,
		}],
	}
