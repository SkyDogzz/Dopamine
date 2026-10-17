extends RefCounted

const SCHEMA_VERSION := 1
const MAX_JSON_BYTES := 1_048_576
const MAX_SHARE_CODE_LENGTH := 2_000_000
const MAX_NESTING_DEPTH := 16
const MAX_COLLECTION_ITEMS := 256
const SHARE_PREFIX := "DSLAB1:"
const FORBIDDEN_SHARED_KEY_PARTS := [
	"script", "command", "path", "password", "token", "secret", "private", "email", "username",
]
const PRESET_KEYS := [
	"schema_version", "preset_id", "name", "description", "base_mode",
	"seed", "overrides", "flags", "initial_build",
]
const VALID_MODES := ["survival", "endless", "armorless"]
const OVERRIDE_LIMITS := {
	"enemy_hp": Vector2(0.1, 1000.0),
	"enemy_speed": Vector2(0.1, 10.0),
	"contact_damage_per_hit": Vector2(0.0, 1000.0),
	"spawn_count": Vector2(1.0, 500.0),
}

func validate_preset(preset: Variant) -> Dictionary:
	if not preset is Dictionary or preset.size() != PRESET_KEYS.size():
		return _error("invalid_shape")
	for key in PRESET_KEYS:
		if not preset.has(key):
			return _error("missing_%s" % key)
	if int(preset["schema_version"]) != SCHEMA_VERSION:
		return _error("unsupported_version")
	if not _valid_identifier(preset["preset_id"], 64) or not _valid_text(preset["name"], 80) or \
			not _valid_text(preset["description"], 240) or str(preset["base_mode"]) not in VALID_MODES:
		return _error("invalid_metadata")
	if typeof(preset["seed"]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(preset["seed"])) or \
			int(preset["seed"]) != float(preset["seed"]) or int(preset["seed"]) < 0 or int(preset["seed"]) > 2147483647:
		return _error("invalid_seed")
	if not preset["overrides"] is Dictionary or not preset["flags"] is Dictionary or \
			not preset["initial_build"] is Dictionary:
		return _error("invalid_payload")
	for override_id in preset["overrides"]:
		if not OVERRIDE_LIMITS.has(override_id):
			return _error("unsupported_override")
		var value: Variant = preset["overrides"][override_id]
		var limits: Vector2 = OVERRIDE_LIMITS[override_id]
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or \
				float(value) < limits.x or float(value) > limits.y:
			return _error("invalid_override_%s" % str(override_id))
		if str(override_id) == "spawn_count" and int(value) != float(value):
			return _error("invalid_override_spawn_count")
	for key in ["overrides", "flags", "initial_build"]:
		if not _valid_tree(preset[key], 0):
			return _error("payload_limits_exceeded")
	var json := JSON.stringify(preset)
	if json.to_utf8_buffer().size() > MAX_JSON_BYTES:
		return _error("too_large")
	return {"ok": true, "preset": preset.duplicate(true)}

func export_json(preset: Variant) -> Dictionary:
	var checked := validate_preset(preset)
	if not checked.get("ok", false):
		return checked
	return {"ok": true, "json": JSON.stringify(checked["preset"])}

func import_json(json: String) -> Dictionary:
	if json.to_utf8_buffer().size() > MAX_JSON_BYTES:
		return _error("too_large")
	var parser := JSON.new()
	if parser.parse(json) != OK:
		return _error("invalid_json")
	return validate_preset(parser.data)

func encode_share_code(preset: Variant) -> Dictionary:
	var exported := export_json(preset)
	if not exported.get("ok", false):
		return exported
	var raw := ("%s\n%s" % [SCHEMA_VERSION, exported["json"]]).to_utf8_buffer()
	var compressed := raw.compress(FileAccess.COMPRESSION_DEFLATE)
	var checksum := _checksum(compressed)
	var code := SHARE_PREFIX + Marshalls.raw_to_base64(compressed).replace("+", "-").replace("/", "_").trim_suffix("=") + "." + checksum
	if code.length() > MAX_SHARE_CODE_LENGTH:
		return _error("share_code_too_large")
	return {"ok": true, "code": code}

func decode_share_code(code: String) -> Dictionary:
	if code.length() > MAX_SHARE_CODE_LENGTH or not code.begins_with(SHARE_PREFIX):
		return _error("invalid_share_code")
	var parts := code.substr(SHARE_PREFIX.length()).split(".", false, 1)
	if parts.size() != 2 or parts[0].is_empty() or parts[1].length() != 64:
		return _error("invalid_share_code")
	var encoded := parts[0].replace("-", "+").replace("_", "/")
	while encoded.length() % 4 != 0:
		encoded += "="
	var compressed := Marshalls.base64_to_raw(encoded)
	if compressed.is_empty() or _checksum(compressed) != parts[1].to_lower():
		return _error("checksum_mismatch")
	var raw := compressed.decompress(MAX_JSON_BYTES + 16, FileAccess.COMPRESSION_DEFLATE)
	if raw.is_empty() or raw.size() > MAX_JSON_BYTES + 16:
		return _error("invalid_compressed_payload")
	var text := raw.get_string_from_utf8()
	var newline := text.find("\n")
	if newline < 0 or text.substr(0, newline) != str(SCHEMA_VERSION):
		return _error("unsupported_version")
	return import_json(text.substr(newline + 1))

func _checksum(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()

func _valid_identifier(value: Variant, max_length: int) -> bool:
	if typeof(value) != TYPE_STRING or str(value).is_empty() or str(value).length() > max_length:
		return false
	var regex := RegEx.new()
	regex.compile("^[A-Za-z0-9_-]+$")
	return regex.search(str(value)) != null

func _valid_text(value: Variant, max_length: int) -> bool:
	return typeof(value) == TYPE_STRING and str(value).length() <= max_length

func _valid_tree(value: Variant, depth: int) -> bool:
	if depth > MAX_NESTING_DEPTH:
		return false
	if value is Dictionary:
		if value.size() > MAX_COLLECTION_ITEMS:
			return false
		for key in value:
			if typeof(key) != TYPE_STRING or _has_forbidden_shared_key(str(key)) or \
					not _valid_tree(value[key], depth + 1):
				return false
	elif value is Array:
		if value.size() > MAX_COLLECTION_ITEMS:
			return false
		for item in value:
			if not _valid_tree(item, depth + 1):
				return false
	elif typeof(value) == TYPE_FLOAT and not is_finite(value):
		return false
	elif typeof(value) not in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING]:
		return false
	return true

func _has_forbidden_shared_key(key: String) -> bool:
	var normalized := key.to_lower()
	for forbidden_part in FORBIDDEN_SHARED_KEY_PARTS:
		if normalized.contains(forbidden_part):
			return true
	return false

func _error(code: String) -> Dictionary:
	return {"ok": false, "error": code}
