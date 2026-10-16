extends SceneTree

const RUNNER := preload("res://scripts/sandbox_weapon_scenario_runner.gd")
const WEAPON_IDS := ["lightning_conductor", "inferno_sprayer", "crimson_daggers", "minigun", "toxic_cloud",
		"sawblades", "meteor_staff", "prism_laser", "void_orb", "frost_nova"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for weapon_id in WEAPON_IDS:
		var file := FileAccess.open("res://scenarios/weapons/%s.json" % weapon_id, FileAccess.READ)
		if file == null:
			_fail("Missing Sandbox scenario for %s" % weapon_id)
			return
		var scenario: Variant = JSON.parse_string(file.get_as_text())
		if not RUNNER._validate_scenario(scenario).is_empty():
			_fail("Invalid Sandbox scenario for %s" % weapon_id)
			return
		if scenario["weapon_id"] != weapon_id:
			_fail("Scenario filename and weapon_id should match for %s" % weapon_id)
			return

	var valid := _scenario()
	var invalid := valid.duplicate(true)
	invalid["weapon_id"] = "unknown_weapon"
	if not RUNNER._validate_scenario(invalid).contains("weapon_id"):
		_fail("Sandbox weapon scenarios should reject an unknown weapon")
		return
	invalid = valid.duplicate(true)
	invalid["relic_id"] = "wrong_relic"
	if not RUNNER._validate_scenario(invalid).contains("relic_id"):
		_fail("Sandbox weapon scenarios should reject a mismatched relic")
		return
	invalid = valid.duplicate(true)
	invalid["targets"] = []
	if not RUNNER._validate_scenario(invalid).contains("targets"):
		_fail("Sandbox weapon scenarios should reject empty target fixtures")
		return
	invalid = valid.duplicate(true)
	invalid["weapon_level"] = 6
	if not RUNNER._validate_scenario(invalid).contains("weapon_level"):
		_fail("Sandbox weapon scenarios should reject levels above the catalog cap")
		return
	invalid = valid.duplicate(true)
	invalid["targets"][0]["position"] = [INF, 0]
	if not RUNNER._validate_scenario(invalid).contains("finite position"):
		_fail("Sandbox weapon scenarios should reject non-finite target positions")
		return
	print("Sandbox weapon scenario validation smoke passed")
	quit()

func _scenario() -> Dictionary:
	return {
		"schema_version": 1,
		"scenario_id": "weapon_validation",
		"weapon_id": "lightning_conductor",
		"relic_id": "storm_core",
		"targets": [{"position": [60, 0]}],
	}

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
