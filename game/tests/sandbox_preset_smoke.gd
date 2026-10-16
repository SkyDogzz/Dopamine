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
	var directory := ProjectSettings.globalize_path("user://sandbox_preset_smoke/presets")
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var preset_store = load("res://scripts/sandbox_preset_store.gd").new(directory, preset_service)
	if not preset_store.save_preset(preset).get("ok", false):
		_fail("A validated preset should save inside the sandbox preset directory")
		return
	var listed: Dictionary = preset_store.list_presets()
	if not listed.get("ok", false) or listed["presets"].size() != 1 or \
			listed["presets"][0]["preset_id"] != preset["preset_id"]:
		_fail("The sandbox preset store should list saved presets")
		return
	if preset_store.load_preset("../slot_0").get("ok", false):
		_fail("Preset identifiers must not escape the sandbox preset directory")
		return
	if not preset_store.delete_preset("test_build").get("ok", false) or \
			preset_store.load_preset("test_build").get("ok", false):
		_fail("A preset should be deletable without touching other files")
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
	var too_many_overrides := preset.duplicate(true)
	for index in range(257):
		too_many_overrides["overrides"]["setting_%d" % index] = index
	if preset_service.validate_preset(too_many_overrides).get("ok", false):
		_fail("Preset override collections must reject excessive entries")
		return
	var too_deep := preset.duplicate(true)
	var nested: Dictionary = too_deep["overrides"]
	for _index in range(18):
		var child := {}
		nested["nested"] = child
		nested = child
	if preset_service.validate_preset(too_deep).get("ok", false):
		_fail("Preset payloads must reject excessive nesting")
		return
	print("Sandbox preset smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
