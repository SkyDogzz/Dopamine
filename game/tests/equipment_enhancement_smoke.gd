extends SceneTree

const TEST_DIRECTORY := "user://equipment_enhancement_smoke"
const POWDER_TIERS := ["basic", "refined", "pure", "prismatic"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var root := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(root)
	for file_name in DirAccess.get_files_at(root):
		DirAccess.remove_absolute(root.path_join(file_name))
	var save_service = load("res://scripts/save_service.gd").new(root)
	var service = load("res://scripts/progression_service.gd").new(save_service, "0")
	var profile: Dictionary = service.load_profile()["profile"]
	profile["equipment_inventory"] = [{
		"instance_id": "enhancement_fixture", "slot": "helmet", "rarity": "normal",
		"stat_lines": [{
			"stat_id": "damage_pct", "roll_percentile": 0.5,
			"enhancement_level": 0, "fail_streak": 9,
		}],
		"equipped": false, "rolls_calibrated": false,
		"unique_effect_id": "", "source_mode": "survival",
	}]
	for tier in POWDER_TIERS:
		profile["resources"]["powder_%s" % tier] = 10000
	if not save_service.save_slot("0", profile):
		_fail("Could not save the enhancement fixture")
		return
	for tier in POWDER_TIERS:
		profile = save_service.load_slot("0")["payload"]
		profile["equipment_inventory"][0]["stat_lines"][0]["enhancement_level"] = 0
		profile["equipment_inventory"][0]["stat_lines"][0]["fail_streak"] = 9
		if not save_service.save_slot("0", profile):
			_fail("Could not reset the enhancement fixture for %s Powder" % tier)
			return
		for level in range(10):
			profile = save_service.load_slot("0")["payload"]
			profile["equipment_inventory"][0]["stat_lines"][0]["fail_streak"] = 9
			if not save_service.save_slot("0", profile):
				_fail("Could not prepare guaranteed %s enhancement at +%d" % [tier, level])
				return
			var before: Dictionary = save_service.load_slot("0")["payload"]
			var result: Dictionary = service.enhance_equipment(
				"enhancement_fixture", "damage_pct", tier
			)
			var after: Dictionary = save_service.load_slot("0")["payload"]
			var line: Dictionary = after["equipment_inventory"][0]["stat_lines"][0]
			var cost: int = service.enhancement_cost("normal", level)
			if not result.get("ok", false) or not result.get("success", false) or \
					line["enhancement_level"] != level + 1 or line["fail_streak"] != 0 or \
					int(after["resources"]["powder_%s" % tier]) != int(before["resources"]["powder_%s" % tier]) - cost:
				_fail("Guaranteed %s enhancement should advance +%d to +%d and consume the level cost" % [tier, level, level + 1])
				return
			var expected_value: float = 3.0 * (1.0 + 0.08 * float(level + 1))
			if not is_equal_approx(load("res://scripts/equipment_generator.gd").stat_value(
				"damage_pct", 0.5, level + 1), expected_value):
				_fail("The stat value should increase by 8%% per enhancement level")
				return
	for rarity in {"normal": 1.0, "magic": 1.5, "mystic": 2.0, "legendary": 3.0, "mythic": 4.0}:
		for level in range(10):
			var expected_cost := ceili(float([10, 15, 22, 32, 46, 65, 90, 125, 175, 250][level]) * float({
				"normal": 1.0, "magic": 1.5, "mystic": 2.0, "legendary": 3.0, "mythic": 4.0,
			}[rarity]))
			if service.enhancement_cost(str(rarity), level) != expected_cost:
				_fail("Enhancement cost should follow the proposed rarity and level table")
				return
	if not _verify_failures(service, save_service):
		return
	for index in range(POWDER_TIERS.size()):
		var tier_name: String = POWDER_TIERS[index]
		var before_conversion: Dictionary = service.load_profile()["profile"]
		if index == POWDER_TIERS.size() - 1:
			var invalid: Dictionary = service.convert_powder(tier_name, 10)
			if invalid.get("error") != "invalid_conversion":
				_fail("Prismatic Powder must not convert into a lower tier or another resource")
				return
		else:
			var conversion: Dictionary = service.convert_powder(tier_name, 10)
			if not conversion.get("ok", false):
				_fail("Ten %s Powder should convert into one next-tier Powder" % tier_name)
				return
			var next_tier: String = POWDER_TIERS[index + 1]
			if int(conversion["profile"]["resources"]["powder_%s" % tier_name]) != \
					int(before_conversion["resources"]["powder_%s" % tier_name]) - 10 or \
					int(conversion["profile"]["resources"]["powder_%s" % next_tier]) != \
					int(before_conversion["resources"]["powder_%s" % next_tier]) + 1:
				_fail("Powder conversion should consume 10 and grant exactly one next tier")
				return
	if service.enhancement_cost("normal", 10) != 0 or service.enhancement_cost("unknown", 0) != 0:
		_fail("Enhancement costs should reject invalid rarity or capped levels")
		return
	print("equipment_enhancement_smoke: passed +0..+10 for all Powder tiers, failure paths, costs and conversion direction")
	quit(0)

func _verify_failures(service: RefCounted, save_service: RefCounted) -> bool:
	var ordinary_seed := _seed_for_outcome(50.0, 10.0, false)
	var critical_seed := _seed_for_outcome(47.0, 10.0, true)
	for failure_case in [
		{"seed": ordinary_seed, "level": 0, "expected_level": 0, "critical": false},
		{"seed": critical_seed, "level": 1, "expected_level": 0, "critical": true},
	]:
		var profile: Dictionary = save_service.load_slot("0")["payload"]
		var line: Dictionary = profile["equipment_inventory"][0]["stat_lines"][0]
		line["enhancement_level"] = int(failure_case["level"])
		line["fail_streak"] = 0
		profile["resources"]["powder_basic"] = 10000
		if not save_service.save_slot("0", profile):
			_fail("Could not save a %s failure fixture" % ("critical" if failure_case["critical"] else "normal"))
			return false
		service._rng.seed = int(failure_case["seed"])
		var result: Dictionary = service.enhance_equipment("enhancement_fixture", "damage_pct", "basic")
		var updated: Dictionary = save_service.load_slot("0")["payload"]
		var updated_line: Dictionary = updated["equipment_inventory"][0]["stat_lines"][0]
		if not result.get("ok", false) or result.get("success", true) or \
				bool(result.get("critical_failure", false)) != bool(failure_case["critical"]) or \
				int(updated_line["enhancement_level"]) != int(failure_case["expected_level"]) or \
				int(updated_line["fail_streak"]) != 1:
			_fail("Enhancement %s failure should preserve/lose one level as specified and increase fail streak" % ("critical" if failure_case["critical"] else "normal"))
			return false
	return true

func _seed_for_outcome(success_chance: float, critical_chance: float, critical: bool) -> int:
	var rng := RandomNumberGenerator.new()
	for seed_value in range(1, 10000):
		rng.seed = seed_value
		if rng.randf() * 100.0 < success_chance:
			continue
		var is_critical := rng.randf() * 100.0 < critical_chance
		if is_critical == critical:
			return seed_value
	return 0

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
