extends SceneTree

const TEST_DIRECTORY := "user://equipment_economy_smoke"
const RARITIES := ["normal", "magic", "mystic", "legendary", "mythic"]
const ESSENCE_VALUES := {"normal": 5, "magic": 10, "mystic": 20, "legendary": 40, "mythic": 80}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var save_service = load("res://scripts/save_service.gd").new(directory)
	var service = load("res://scripts/progression_service.gd").new(save_service, "0")
	var profile: Dictionary = service.load_profile()["profile"]
	var generator = load("res://scripts/equipment_generator.gd")
	profile["equipment_inventory"] = []
	for rarity in RARITIES:
		var stat_lines: Array[Dictionary] = []
		for index in range(generator.STAT_LINE_COUNTS[rarity]):
			stat_lines.append({
				"stat_id": generator.STAT_IDS[index], "roll_percentile": 0.5,
				"enhancement_level": 0, "fail_streak": 0,
			})
		profile["equipment_inventory"].append({
			"instance_id": "sell_%s" % rarity, "slot": generator.SLOTS[profile["equipment_inventory"].size()],
			"rarity": rarity, "stat_lines": stat_lines, "equipped": false,
			"rolls_calibrated": false,
			"unique_effect_id": "pending_choice" if rarity in ["legendary", "mythic"] else "",
			"source_mode": "survival",
		})
	profile["resources"]["essence"] = 0
	if not save_service.save_slot("0", profile):
		_fail("Could not save sale fixtures")
		return
	var total_essence := 0
	for rarity in RARITIES:
		var result: Dictionary = service.sell_equipment("sell_%s" % rarity)
		var expected_essence: int = ESSENCE_VALUES[rarity]
		total_essence += expected_essence
		if not result.get("ok", false) or result.get("essence_reward") != expected_essence or \
				result["profile"]["resources"]["essence"] != total_essence or \
				result["profile"]["equipment_inventory"].size() != RARITIES.size() - RARITIES.find(rarity) - 1 or \
				int(result["profile"]["resources"]["powder_basic"]) != 0 or \
				int(result["profile"]["resources"]["powder_refined"]) != 0 or \
				int(result["profile"]["resources"]["powder_pure"]) != 0:
			_fail("Selling %s equipment should remove it and grant only its proposed Essence value" % rarity)
			return
		if service.sell_equipment("sell_%s" % rarity).get("ok", false):
			_fail("A sold item must not be sellable a second time")
			return
	profile = service.load_profile()["profile"]
	profile["equipment_inventory"] = [{
		"instance_id": "invalid_pity", "slot": "helmet", "rarity": "normal",
		"stat_lines": [{
			"stat_id": "damage_pct", "roll_percentile": 0.5,
			"enhancement_level": 0, "fail_streak": 10,
		}],
		"equipped": false, "rolls_calibrated": false,
		"unique_effect_id": "", "source_mode": "survival",
	}]
	if not save_service.save_slot("0", profile) or service.load_profile().get("error") != "invalid_profile":
		_fail("A saved failure streak above nine must be rejected before it can bypass pity")
		return
	print("equipment_economy_smoke: passed rarity sales, no duplicate payout and pity validation")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
