extends SceneTree

const TEST_DIRECTORY := "user://save_service_smoke"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var service = load("res://scripts/save_service.gd").new(directory)
	if not service.save_slot("0", {"essence": 10}):
		_fail("A valid slot should save")
		return
	if not service.save_slot("0", {"essence": 20}):
		_fail("An updated slot should save")
		return
	var loaded: Dictionary = service.load_slot("0")
	if not loaded.get("ok", false) or loaded["payload"].get("essence") != 20:
		_fail("A valid versioned slot should load with its latest payload")
		return
	var slot_path := directory.path_join("slot_0.json")
	var versioned_file := FileAccess.open(slot_path, FileAccess.READ)
	var envelope: Dictionary = JSON.parse_string(versioned_file.get_as_text())
	versioned_file.close()
	envelope["payload"]["essence"] = 99.0
	versioned_file = FileAccess.open(slot_path, FileAccess.WRITE)
	versioned_file.store_string(JSON.stringify(envelope))
	versioned_file.close()
	loaded = service.load_slot("0")
	if not loaded.get("ok", false) or not loaded.get("recovered", false) or \
			loaded["payload"].get("essence") != 10:
		_fail("A payload changed without updating its checksum should recover the previous backup")
		return
	var corrupt_file := FileAccess.open(slot_path, FileAccess.WRITE)
	corrupt_file.store_string("not json")
	corrupt_file.close()
	var corrupt_before := FileAccess.get_file_as_string(slot_path)
	loaded = service.read_slot_read_only("0")
	if loaded.get("ok", false) or loaded.get("recovered", false) or \
			FileAccess.get_file_as_string(slot_path) != corrupt_before:
		_fail("Read-only access should reject a corrupt current slot without restoring its backup")
		return
	loaded = service.load_slot("0")
	if not loaded.get("ok", false) or not loaded.get("recovered", false) or \
			loaded["payload"].get("essence") != 10:
		_fail("A corrupt current slot should recover the previous backup")
		return
	var legacy_path := directory.path_join("slot_legacy.json")
	var legacy_file := FileAccess.open(legacy_path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify({"essence": 7, "legacy_flag": true}))
	legacy_file.close()
	var legacy_before := FileAccess.get_file_as_string(legacy_path)
	loaded = service.read_slot_read_only("legacy")
	if not loaded.get("ok", false) or not loaded.get("migrated", false) or \
			loaded["payload"].get("essence") != 7 or FileAccess.get_file_as_string(legacy_path) != legacy_before:
		_fail("Read-only slot access should return a legacy payload without migrating or rewriting its source")
		return
	loaded = service.load_slot("legacy")
	if not loaded.get("ok", false) or not loaded.get("migrated", false) or \
			not loaded.get("migration_saved", false) or loaded["payload"].get("essence") != 7:
		_fail("A legacy raw JSON dictionary should migrate to the current envelope")
		return
	loaded = service.load_slot("legacy")
	if not loaded.get("ok", false) or loaded.get("migrated", true):
		_fail("A migrated slot should be stored in the current version")
		return
	var invalid_save: bool = service.save_slot("../escape", {"essence": 1})
	var invalid_load: Dictionary = service.load_slot("../escape")
	if invalid_save or invalid_load.get("ok", false):
		_fail("Slot identifiers must not escape the save directory")
		return
	print("Save service smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
