extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var preset_service = load("res://scripts/sandbox_preset_service.gd").new()
	var preset := {
		"schema_version": 1,
		"preset_id": "test_build",
		"name": "Test Build",
		"description": "A bounded test preset",
		"base_mode": "survival",
		"seed": 12345,
		"overrides": {"enemy_hp": 2.0},
		"flags": {"god_mode": false},
		"initial_build": {"weapons": [{"id": "lightning_conductor", "level": 2}]},
	}
	var encoded: Dictionary = preset_service.encode_share_code(preset)
	if not encoded.get("ok", false):
		_fail("A valid preset should encode to a share code: %s" % encoded)
		return
	var decoded: Dictionary = preset_service.decode_share_code(encoded["code"])
	if not decoded.get("ok", false) or decoded["preset"].size() != preset.size() or \
			decoded["preset"]["preset_id"] != preset["preset_id"] or \
			decoded["preset"]["base_mode"] != preset["base_mode"] or \
			int(decoded["preset"]["seed"]) != preset["seed"] or \
			decoded["preset"]["initial_build"]["weapons"][0]["id"] != "lightning_conductor":
		_fail("A preset should survive a share-code round trip: %s" % decoded)
		return
	var hostile := preset.duplicate(true)
	hostile["file_path"] = "/tmp/save.json"
	if preset_service.validate_preset(hostile).get("ok", false):
		_fail("Unknown path fields must be rejected")
		return
	if preset_service.decode_share_code(encoded["code"].substr(0, encoded["code"].length() - 1) + "A").get("ok", false):
		_fail("A damaged share code must fail checksum validation")
		return
	if preset_service.import_json("{}".repeat(300000)).get("ok", false):
		_fail("An oversized preset JSON payload must be rejected")
		return
	print("Sandbox preset smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
