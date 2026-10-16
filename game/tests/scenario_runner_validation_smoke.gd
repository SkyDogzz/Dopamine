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
