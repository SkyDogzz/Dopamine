extends RefCounted

const CATALOG_PATH := "res://data/combat_catalog.json"

var weapons: Dictionary = {}
var relics: Dictionary = {}
var error := ""

func _init() -> void:
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		error = "Cannot open combat catalog: %s" % CATALOG_PATH
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not _load_definitions(parsed):
		if error.is_empty():
			error = "Combat catalog has an invalid structure"

func _load_definitions(data: Dictionary) -> bool:
	if int(data.get("schema_version", 0)) != 1:
		error = "Unsupported combat catalog schema version"
		return false
	if not (data.get("weapons") is Array) or not (data.get("relics") is Array):
		error = "Combat catalog requires weapon and relic arrays"
		return false
	for entry in data["weapons"]:
		if not _valid_definition(entry, ["id", "name", "behavior", "relic_id", "evolution_id", "available_in_survival"], weapons):
			return false
	for entry in data["relics"]:
		if not _valid_definition(entry, ["id", "name", "available_in_survival"], relics):
			return false
	if weapons.size() != 10 or relics.size() != 11:
		error = "Combat catalog must define ten weapons and eleven relics"
		return false
	for weapon_id in weapons:
		var weapon: Dictionary = weapons[weapon_id]
		var relic_id: String = weapon["relic_id"]
		if not relics.has(relic_id) or relics[relic_id].get("weapon_id", "") != weapon_id:
			error = "Weapon/relic association is inconsistent: %s" % weapon_id
			return false
	return true

func _valid_definition(entry: Variant, required_fields: Array, destination: Dictionary) -> bool:
	if not entry is Dictionary:
		error = "Combat catalog entries must be objects"
		return false
	for field in required_fields:
		if not entry.has(field):
			error = "Combat catalog entry is missing %s" % field
			return false
	var item_id: String = str(entry["id"])
	if item_id.is_empty() or destination.has(item_id):
		error = "Combat catalog IDs must be non-empty and unique"
		return false
	if str(entry["name"]).is_empty() or not (entry["available_in_survival"] is bool):
		error = "Combat catalog name or availability is invalid: %s" % item_id
		return false
	destination[item_id] = entry
	return true

func available_ids(family: String) -> Array[String]:
	var source: Dictionary = {}
	if family == "weapon":
		source = weapons
	elif family == "relic":
		source = relics
	var result: Array[String] = []
	for item_id in source:
		if bool(source[item_id]["available_in_survival"]):
			result.append(item_id)
	return result
