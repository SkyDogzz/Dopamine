extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save_service = load("res://scripts/save_service.gd").new("user://sandbox_profile_build_smoke")
	var progression = load("res://scripts/progression_service.gd").new(save_service, "0")
	var loaded: Dictionary = progression.load_profile()
	if not loaded.get("ok", false):
		_fail("A temporary normal profile should load for the copy fixture")
		return
	var profile: Dictionary = loaded["profile"]
	profile["unlocked_skill_nodes"] = ["unlock_crimson_daggers", "unlock_blood_chalice", "vitality_starter"]
	var equipment_generator = load("res://scripts/equipment_generator.gd").new(55)
	var equipment: Dictionary = equipment_generator.generate_survival_item("copy_fixture", "normal", 1)
	equipment["slot"] = "helmet"
	equipment["equipped"] = true
	profile["equipment_inventory"].append(equipment)
	if not save_service.save_slot("0", profile):
		_fail("The isolated profile fixture should save")
		return
	var source_before := FileAccess.get_file_as_string(ProjectSettings.globalize_path("user://sandbox_profile_build_smoke/slot_0.json"))
	var build = load("res://scripts/sandbox_build.gd").new()
	var result: Dictionary = _import_read_only(save_service, build, "0")
	var copied: Dictionary = build.to_dictionary()
	if not result.get("ok", false) or copied["weapons"].size() != 3 or copied["relics"].size() != 3 or \
			copied["equipment"].size() != 1 or copied["equipment"][0]["id"] != equipment["instance_id"] or \
			copied["stats"].get("max_hp_pct", 0.0) <= 0.0:
		_fail("The profile copy should include unlocks, skill stats and equipped gear only: %s" % copied)
		return
	profile["resources"]["essence"] = 9
	if not _import_read_only(save_service, build, "0").get("ok", false) or \
			FileAccess.get_file_as_string(ProjectSettings.globalize_path("user://sandbox_profile_build_smoke/slot_0.json")) != source_before:
		_fail("Importing or editing the copied build must never write the normal profile")
		return
	var legacy_path := ProjectSettings.globalize_path("user://sandbox_profile_build_smoke/slot_legacy.json")
	var legacy_file := FileAccess.open(legacy_path, FileAccess.WRITE)
	var legacy_profile: Dictionary = profile.duplicate(true)
	legacy_profile["profile_version"] = 6
	legacy_profile.erase("achievement_progress")
	legacy_file.store_string(JSON.stringify(legacy_profile))
	legacy_file.close()
	var legacy_before := FileAccess.get_file_as_string(legacy_path)
	if _import_read_only(save_service, build, "legacy").get("ok", false) or \
		FileAccess.get_file_as_string(legacy_path) != legacy_before:
		_fail("An unmigrated legacy profile must be rejected without modifying its source")
		return
	if build.load_profile_copy({"profile_version": 999}).get("ok", false):
		_fail("An invalid profile must not replace a valid copied build")
		return
	print("Sandbox profile build copy smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _import_read_only(save_service: RefCounted, build: RefCounted, slot_id: String) -> Dictionary:
	var loaded: Dictionary = save_service.read_slot_read_only(slot_id)
	if not loaded.get("ok", false):
		return {"ok": false, "error": loaded.get("error", "read_failed")}
	var progression = load("res://scripts/progression_service.gd").new(null, slot_id)
	if not progression._valid_profile(loaded["payload"]):
		return {"ok": false, "error": "invalid_or_legacy_profile"}
	return build.load_profile_copy(loaded["payload"])
