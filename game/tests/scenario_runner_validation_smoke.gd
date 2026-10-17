extends SceneTree

const RUNNER := preload("res://scripts/scenario_runner.gd")
const ELITE_AFFIXES := ["Hasted", "Armored", "Regenerating", "Volatile", "Shielded", "Split-on-Death"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for affix in ELITE_AFFIXES:
		if not RUNNER._validate_scenario(_scenario("elite", affix)).is_empty():
			_fail("Sandbox scenario validation should accept the elite affix %s" % affix)
			return
	if not RUNNER._validate_scenario(_scenario("elite", "Unknown")).contains("supported elite affix"):
		_fail("Sandbox scenario validation should reject an unsupported elite affix")
		return
	if not RUNNER._validate_scenario(_scenario("chaser", "Hasted")).contains("requires enemy_type elite"):
		_fail("Sandbox scenario validation should reject elite affixes on other enemy profiles")
		return
	var speed_override := _scenario("chaser", "Hasted")
	speed_override["commands"][0].erase("affix")
	speed_override["commands"][0]["movement_speed_multiplier"] = 2.0
	if not RUNNER._validate_scenario(speed_override).is_empty():
		_fail("Sandbox scenarios should accept an in-range enemy speed multiplier")
		return
	speed_override["commands"][0]["movement_speed_multiplier"] = 0.05
	if not RUNNER._validate_scenario(speed_override).contains("movement_speed_multiplier"):
		_fail("Sandbox scenarios should reject enemy speed multipliers below the technical minimum")
		return
	speed_override["commands"][0]["movement_speed_multiplier"] = 10.1
	if not RUNNER._validate_scenario(speed_override).contains("movement_speed_multiplier"):
		_fail("Sandbox scenarios should reject enemy speed multipliers above the technical cap")
		return
	print("Sandbox scenario runner validation smoke passed")
	quit()

func _scenario(enemy_type: String, affix: String) -> Dictionary:
	return {
		"schema_version": 1,
		"scenario_id": "elite_affix_validation",
		"commands": [{"type": "spawn_enemy", "enemy_type": enemy_type, "affix": affix}],
	}

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
