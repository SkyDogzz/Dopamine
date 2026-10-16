extends RefCounted

const PRESET_ID_PATTERN := "^[A-Za-z0-9_-]{1,64}$"

var _directory: String
var _preset_service: RefCounted

func _init(directory: String = "user://sandbox/presets", preset_service: RefCounted = null) -> void:
	_directory = ProjectSettings.globalize_path(directory)
	_preset_service = preset_service if preset_service != null else load("res://scripts/sandbox_preset_service.gd").new()

func save_preset(preset: Variant) -> Dictionary:
	var checked: Dictionary = _preset_service.validate_preset(preset)
	if not checked.get("ok", false):
		return checked
	if DirAccess.make_dir_recursive_absolute(_directory) != OK:
		return _error("directory_unavailable")
	var preset_id := str(checked["preset"]["preset_id"])
	var path := _path_for(preset_id)
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return _error("write_failed")
	file.store_string(JSON.stringify(checked["preset"]))
	file.flush()
	var write_ok := file.get_error() == OK
	file.close()
	if not write_ok or _preset_service.import_json(FileAccess.get_file_as_string(temporary_path)).get("ok", false) == false:
		DirAccess.remove_absolute(temporary_path)
		return _error("write_failed")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if DirAccess.rename_absolute(temporary_path, path) != OK:
		DirAccess.remove_absolute(temporary_path)
		return _error("write_failed")
	return {"ok": true, "preset_id": preset_id}

func load_preset(preset_id: String) -> Dictionary:
	if not _valid_id(preset_id):
		return _error("invalid_preset_id")
	var path := _path_for(preset_id)
	if not FileAccess.file_exists(path):
		return _error("not_found")
	return _preset_service.import_json(FileAccess.get_file_as_string(path))

func list_presets() -> Dictionary:
	if DirAccess.make_dir_recursive_absolute(_directory) != OK:
		return _error("directory_unavailable")
	var presets: Array[Dictionary] = []
	var directory := DirAccess.open(_directory)
	if directory == null:
		return _error("directory_unavailable")
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.ends_with(".json"):
			var preset_id := file_name.trim_suffix(".json")
			if _valid_id(preset_id):
				var result := load_preset(preset_id)
				if result.get("ok", false):
					presets.append(result["preset"])
		file_name = directory.get_next()
	directory.list_dir_end()
	presets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("name", "")).nocasecmp_to(str(b.get("name", ""))) < 0
	)
	return {"ok": true, "presets": presets}

func delete_preset(preset_id: String) -> Dictionary:
	if not _valid_id(preset_id):
		return _error("invalid_preset_id")
	var path := _path_for(preset_id)
	if not FileAccess.file_exists(path):
		return _error("not_found")
	if DirAccess.remove_absolute(path) != OK:
		return _error("delete_failed")
	return {"ok": true, "preset_id": preset_id}

func _path_for(preset_id: String) -> String:
	return _directory.path_join("%s.json" % preset_id)

func _valid_id(preset_id: String) -> bool:
	var regex := RegEx.new()
	regex.compile(PRESET_ID_PATTERN)
	return regex.search(preset_id) != null

func _error(code: String) -> Dictionary:
	return {"ok": false, "error": code}
