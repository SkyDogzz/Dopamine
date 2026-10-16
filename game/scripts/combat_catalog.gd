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
		weapons.clear()
		relics.clear()
		if error.is_empty():
			error = "Combat catalog has an invalid structure"

func _load_definitions(data: Dictionary) -> bool:
	if data.size() != 3 or not data.has("schema_version") or not data.has("weapons") or not data.has("relics"):
		error = "Combat catalog has unknown or missing top-level fields"
		return false
	if not (data.get("schema_version") is int or data.get("schema_version") is float) or \
			float(data["schema_version"]) != 1.0:
		error = "Unsupported combat catalog schema version"
		return false
	if not (data.get("weapons") is Array) or not (data.get("relics") is Array):
		error = "Combat catalog requires weapon and relic arrays"
		return false
	var evolution_ids: Dictionary = {}
	for entry in data["weapons"]:
		if not _valid_definition(entry, ["id", "name", "behavior", "relic_id", "evolution_id", "available_in_survival"], weapons):
			return false
		if not (entry["relic_id"] is String) or not (entry["evolution_id"] is String) or \
				str(entry["relic_id"]).is_empty() or str(entry["evolution_id"]).is_empty() or \
				evolution_ids.has(entry["evolution_id"]):
			error = "Weapon relic/evolution references must be non-empty and evolutions unique: %s" % entry["id"]
			return false
		evolution_ids[entry["evolution_id"]] = true
	for entry in data["relics"]:
		if not _valid_definition(entry, ["id", "name", "behavior", "global_stat", "global_bonus_per_level", "available_in_survival"], relics, ["weapon_id"]):
			return false
		for field in entry:
			if not ["id", "name", "behavior", "global_stat", "global_bonus_per_level", "weapon_id", "available_in_survival"].has(field):
				error = "Relic contains fields outside its schema: %s" % entry["id"]
				return false
		if not (entry["global_stat"] is String) or str(entry["global_stat"]).is_empty() or \
				(entry["id"] == "magnet_heart" and entry.has("weapon_id")) or \
				(entry["id"] != "magnet_heart" and (not entry.has("weapon_id") or \
					not (entry["weapon_id"] is String) or str(entry["weapon_id"]).is_empty())):
			error = "Relic stat and optional weapon/evolution references are invalid: %s" % entry["id"]
			return false
	if weapons.size() != 10 or relics.size() != 11:
		error = "Combat catalog must define ten weapons and eleven relics"
		return false
	for relic_id in relics:
		var relic: Dictionary = relics[relic_id]
		if not (relic.get("global_bonus_per_level", 0) is int or relic.get("global_bonus_per_level", 0) is float) or \
			float(relic["global_bonus_per_level"]) <= 0.0:
			error = "Relics must define a positive global stat bonus: %s" % relic_id
			return false
	for weapon_id in weapons:
		var weapon: Dictionary = weapons[weapon_id]
		var relic_id: String = weapon["relic_id"]
		if not relics.has(relic_id) or relics[relic_id].get("weapon_id", "") != weapon_id:
			error = "Weapon/relic association is inconsistent: %s" % weapon_id
			return false
	return true

func _valid_definition(entry: Variant, required_fields: Array, destination: Dictionary, optional_fields: Array = []) -> bool:
	if not entry is Dictionary:
		error = "Combat catalog entries must be objects"
		return false
	for field in required_fields:
		if not entry.has(field):
			error = "Combat catalog entry is missing %s" % field
			return false
	for field in entry:
		if not required_fields.has(field) and not optional_fields.has(field):
			error = "Combat catalog entry contains fields outside its schema"
			return false
	var item_id: String = str(entry["id"])
	if item_id.is_empty() or destination.has(item_id):
		error = "Combat catalog IDs must be non-empty and unique"
		return false
	if not (entry["id"] is String) or not (entry["name"] is String) or \
			not (entry["behavior"] is String) or str(entry["name"]).is_empty() or \
			str(entry["behavior"]).is_empty() or not (entry["available_in_survival"] is bool):
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
