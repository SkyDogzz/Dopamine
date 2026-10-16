extends RefCounted

const WEAPON_CAP := 64
const RELIC_CAP := 128
const LEVEL_CAP := 5
const COMBAT_CATALOG_SCRIPT := preload("res://scripts/combat_catalog.gd")
const PROGRESSION_SCRIPT := preload("res://scripts/progression_service.gd")
const EQUIPMENT_GENERATOR_SCRIPT := preload("res://scripts/equipment_generator.gd")
const PROFILE_WEAPON_STARTERS := ["lightning_conductor", "inferno_sprayer"]
const PROFILE_RELIC_STARTERS := ["storm_core", "infernal_heart"]

var weapons: Dictionary = {}
var relics: Dictionary = {}
var equipment: Array[Dictionary] = []
var stats: Dictionary = {}
var _weapon_ids: Dictionary = {}
var _relic_ids: Dictionary = {}

func _init() -> void:
	var catalog = COMBAT_CATALOG_SCRIPT.new()
	for weapon_id in catalog.weapons:
		_weapon_ids[weapon_id] = true
	for relic_id in catalog.relics:
		_relic_ids[relic_id] = true

func load_build(build: Variant) -> Dictionary:
	var checked := _validate(build)
	if not checked.get("ok", false):
		return checked
	weapons = checked["build"]["weapons"].duplicate(true)
	relics = checked["build"]["relics"].duplicate(true)
	equipment.clear()
	for item in checked["build"]["equipment"]:
		equipment.append(item.duplicate(true))
	stats = checked["build"]["stats"].duplicate(true)
	return {"ok": true, "build": to_dictionary()}

func to_dictionary() -> Dictionary:
	return {
		"weapons": _entries_from_levels(weapons),
		"relics": _entries_from_levels(relics),
		"equipment": equipment.duplicate(true),
		"stats": stats.duplicate(true),
	}

func load_profile_copy(profile: Variant) -> Dictionary:
	if not profile is Dictionary:
		return _error("invalid_profile")
	var progression = PROGRESSION_SCRIPT.new(null, "sandbox_copy")
	if not progression._valid_profile(profile):
		return _error("invalid_profile")
	var unlocked_nodes: Array = profile["unlocked_skill_nodes"]
	var copied_weapons: Array[Dictionary] = []
	var copied_relics: Array[Dictionary] = []
	for weapon_id in PROFILE_WEAPON_STARTERS:
		copied_weapons.append({"id": weapon_id, "level": 1})
	for relic_id in PROFILE_RELIC_STARTERS:
		copied_relics.append({"id": relic_id, "level": 1})
	for node_id in unlocked_nodes:
		var definition: Dictionary = progression.skill_node_definition(str(node_id))
		var weapon_id := str(definition.get("unlocks_weapon", ""))
		var relic_id := str(definition.get("unlocks_relic", ""))
		if not weapon_id.is_empty():
			copied_weapons.append({"id": weapon_id, "level": 1})
		if not relic_id.is_empty():
			copied_relics.append({"id": relic_id, "level": 1})
	var copied_stats: Dictionary = {}
	var stat_ids: Array[String] = ["damage_pct", "attack_speed_pct", "critical_chance_pct", "critical_damage_pct",
		"max_hp_pct", "move_speed_pct", "kill_healing_pct", "area_pct", "cooldown_reduction_pct",
		"xp_pct", "pickup_radius_pct", "projectile_speed_pct"]
	for stat_id in stat_ids:
		var value := 0.0
		for node_id in unlocked_nodes:
			value += float(progression.skill_node_definition(str(node_id)).get(stat_id, 0.0))
		var tiers: Dictionary = profile["achievement_progress"]["tiers"]
		for achievement_id in progression._achievement_definitions:
			var achievement: Dictionary = progression._achievement_definitions[achievement_id]
			var reward_tiers: Array = achievement["tiers"]
			for index in range(mini(int(tiers[achievement_id]), reward_tiers.size())):
				value += float(reward_tiers[index]["rewards"].get(stat_id, 0.0))
		if not is_zero_approx(value):
			copied_stats[stat_id] = value
	var copied_equipment: Array[Dictionary] = []
	for equipment in profile["equipment_inventory"]:
		if not equipment["equipped"]:
			continue
		var equipment_stats: Dictionary = {}
		for line in equipment["stat_lines"]:
			var stat_id := str(line["stat_id"])
			equipment_stats[stat_id] = float(equipment_stats.get(stat_id, 0.0)) + \
				EQUIPMENT_GENERATOR_SCRIPT.stat_value(stat_id, float(line["roll_percentile"]), int(line["enhancement_level"]))
		copied_equipment.append({"id": str(equipment["instance_id"]), "slot": str(equipment["slot"]), "stats": equipment_stats})
	return load_build({"weapons": copied_weapons, "relics": copied_relics,
		"equipment": copied_equipment, "stats": copied_stats})

func _validate(build: Variant) -> Dictionary:
	if not build is Dictionary:
		return _error("invalid_build")
	for key in build:
		if str(key) not in ["weapons", "relics", "equipment", "stats"]:
			return _error("unknown_build_field")
	var candidate := {"weapons": {}, "relics": {}, "equipment": [], "stats": {}}
	var catalog = COMBAT_CATALOG_SCRIPT.new()
	for family in ["weapons", "relics"]:
		var entries = build.get(family, [])
		if not entries is Array or entries.size() > (WEAPON_CAP if family == "weapons" else RELIC_CAP):
			return _error("invalid_%s" % family)
		var known_ids: Dictionary = _weapon_ids if family == "weapons" else _relic_ids
		for entry in entries:
			if not entry is Dictionary:
				return _error("invalid_%s_entry" % family)
			var expected_keys := ["id", "level", "evolution_id"] if family == "weapons" else ["id", "level"]
			if entry.size() < 2 or entry.size() > expected_keys.size():
				return _error("invalid_%s_entry" % family)
			for key in entry:
				if str(key) not in expected_keys:
					return _error("unknown_%s_entry_field" % family)
			var item_id := str(entry.get("id", ""))
			var level_value = entry.get("level", 0)
			if not known_ids.has(item_id) or candidate[family].has(item_id) or \
					typeof(level_value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(level_value)) or \
					int(level_value) != float(level_value) or int(level_value) < 1 or int(level_value) > LEVEL_CAP:
				return _error("invalid_%s_value" % family)
			var item := {"level": int(level_value)}
			if family == "weapons":
				var evolution_id := str(entry.get("evolution_id", ""))
				# The catalog is validated by CombatCatalog; only accept no evolution or the paired ID.
				var expected_evolution := str(catalog.weapons[item_id].get("evolution_id", ""))
				if not evolution_id.is_empty() and evolution_id != expected_evolution:
					return _error("invalid_evolution")
				item["evolution_id"] = evolution_id
			candidate[family][item_id] = item
		if family == "weapons":
			candidate["weapon_count"] = entries.size()
		if family == "relics":
			candidate["relic_count"] = entries.size()
	var equipment_entries = build.get("equipment", [])
	if not equipment_entries is Array or equipment_entries.size() > 128:
		return _error("invalid_equipment")
	for item in equipment_entries:
		if not item is Dictionary or item.size() != 3 or not item.has("id") or \
				not item.has("slot") or not item.has("stats") or not item["stats"] is Dictionary:
			return _error("invalid_equipment_entry")
		if typeof(item["id"]) != TYPE_STRING or str(item["id"]).is_empty() or \
				typeof(item["slot"]) != TYPE_STRING or str(item["slot"]).is_empty():
			return _error("invalid_equipment_entry")
		for equipment_stat in item["stats"]:
			var stat_value = item["stats"][equipment_stat]
			if typeof(equipment_stat) != TYPE_STRING or str(equipment_stat).is_empty() or \
					typeof(stat_value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(stat_value)):
				return _error("invalid_equipment_stat")
		candidate["equipment"].append(item.duplicate(true))
	var custom_stats = build.get("stats", {})
	if not custom_stats is Dictionary or custom_stats.size() > 256:
		return _error("invalid_stats")
	for stat_id in custom_stats:
		var value = custom_stats[stat_id]
		if typeof(stat_id) != TYPE_STRING or str(stat_id).is_empty() or str(stat_id).length() > 64 or \
				typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
			return _error("invalid_stat_value")
		candidate["stats"][stat_id] = float(value)
	return {"ok": true, "build": candidate}

func _entries_from_levels(levels: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in levels:
		var entry: Dictionary = {"id": item_id, "level": int(levels[item_id]["level"])}
		if levels[item_id].has("evolution_id"):
			entry["evolution_id"] = levels[item_id]["evolution_id"]
		result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["id"]) < str(b["id"]))
	return result

func _error(code: String) -> Dictionary:
	return {"ok": false, "error": code}
