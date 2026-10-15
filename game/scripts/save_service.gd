extends RefCounted

const FORMAT_VERSION := 1
const SLOT_ID_PATTERN := "^[A-Za-z0-9_-]{1,32}$"

var _directory: String

func _init(directory: String = "user://saves") -> void:
	_directory = ProjectSettings.globalize_path(directory)

func save_slot(slot_id: String, payload: Dictionary) -> bool:
	if not _valid_slot_id(slot_id) or DirAccess.make_dir_recursive_absolute(_directory) != OK:
		return false
	var slot_path := _slot_path(slot_id)
	var temporary_path := slot_path + ".tmp"
	var backup_path := slot_path + ".bak"
	var backup_temporary_path := backup_path + ".tmp"
	_remove_if_present(temporary_path)
	_remove_if_present(backup_temporary_path)
	var body := {"format_version": float(FORMAT_VERSION), "payload": _normalize_json_numbers(payload)}
	var envelope := body.duplicate(true)
	envelope["checksum"] = _checksum(JSON.stringify(body))
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(envelope))
	file.flush()
	var write_succeeded := file.get_error() == OK
	file.close()
	if not write_succeeded or not _read_path(temporary_path).get("ok", false):
		_remove_if_present(temporary_path)
		return false
	if FileAccess.file_exists(slot_path):
		if DirAccess.copy_absolute(slot_path, backup_temporary_path) != OK:
			_remove_if_present(temporary_path)
			return false
		if _read_path(backup_temporary_path).get("ok", false):
			_remove_if_present(backup_path)
			if DirAccess.rename_absolute(backup_temporary_path, backup_path) != OK:
				_remove_if_present(temporary_path)
				return false
		else:
			_remove_if_present(backup_temporary_path)
	if DirAccess.rename_absolute(temporary_path, slot_path) == OK:
		return true
	_remove_if_present(slot_path)
	if DirAccess.rename_absolute(temporary_path, slot_path) == OK:
		return true
	if FileAccess.file_exists(backup_path):
		DirAccess.copy_absolute(backup_path, slot_path)
	_remove_if_present(temporary_path)
	return false

func load_slot(slot_id: String) -> Dictionary:
	if not _valid_slot_id(slot_id):
		return _load_error("invalid_slot")
	var slot_path := _slot_path(slot_id)
	if not FileAccess.file_exists(slot_path):
		var backup := _read_path(slot_path + ".bak")
		if backup.get("ok", false):
			backup["recovered"] = true
			return backup
		return _load_error("not_found")
	var result := _read_path(slot_path)
	if result.get("ok", false):
		if result.get("migrated", false):
			result["migration_saved"] = save_slot(slot_id, result["payload"])
		return result
	var backup := _read_path(slot_path + ".bak")
	if backup.get("ok", false):
		backup["recovered"] = true
		return backup
	return result

func _read_path(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _load_error("unreadable")
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return _load_error("invalid_json")
	var parsed = parser.data
	if not parsed is Dictionary:
		return _load_error("invalid_json")
	if not parsed.has("format_version"):
		return {"ok": true, "payload": parsed.duplicate(true), "migrated": true, "recovered": false}
	var version = parsed["format_version"]
	if typeof(version) not in [TYPE_INT, TYPE_FLOAT] or version != FORMAT_VERSION or \
			not parsed.get("payload") is Dictionary or typeof(parsed.get("checksum")) != TYPE_STRING:
		return _load_error("unsupported_or_invalid_format")
	var body := {"format_version": float(FORMAT_VERSION), "payload": parsed["payload"]}
	if parsed["checksum"] != _checksum(JSON.stringify(body)):
		return _load_error("checksum_mismatch")
	return {"ok": true, "payload": body["payload"].duplicate(true), "migrated": false, "recovered": false}

func _valid_slot_id(slot_id: String) -> bool:
	var pattern := RegEx.new()
	pattern.compile(SLOT_ID_PATTERN)
	return pattern.search(slot_id) != null

func _slot_path(slot_id: String) -> String:
	return _directory.path_join("slot_%s.json" % slot_id)

func _checksum(value: String) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(value.to_utf8_buffer()) != OK:
		return ""
	return context.finish().hex_encode()

func _normalize_json_numbers(value: Variant) -> Variant:
	if typeof(value) == TYPE_INT:
		return float(value)
	if value is Array:
		var normalized: Array = []
		for entry in value:
			normalized.append(_normalize_json_numbers(entry))
		return normalized
	if value is Dictionary:
		var normalized: Dictionary = {}
		for key in value:
			normalized[key] = _normalize_json_numbers(value[key])
		return normalized
	return value

func _remove_if_present(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func _load_error(code: String) -> Dictionary:
	return {"ok": false, "payload": {}, "migrated": false, "recovered": false, "error": code}
