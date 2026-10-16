extends RefCounted

const COMBAT_CATALOG_SCRIPT := preload("res://scripts/combat_catalog.gd")
const ICONS := {
	"lightning_conductor": "res://assets/sprites/catalog/weapon_lightning_conductor.png",
	"inferno_sprayer": "res://assets/sprites/catalog/weapon_inferno_sprayer.png",
	"crimson_daggers": "res://assets/sprites/catalog/weapon_crimson_daggers.png",
	"minigun": "res://assets/sprites/catalog/weapon_minigun.png",
	"toxic_cloud": "res://assets/sprites/catalog/weapon_toxic_cloud.png",
	"sawblades": "res://assets/sprites/catalog/weapon_sawblades.png",
	"meteor_staff": "res://assets/sprites/catalog/weapon_meteor_staff.png",
	"prism_laser": "res://assets/sprites/catalog/weapon_prism_laser.png",
	"void_orb": "res://assets/sprites/catalog/weapon_void_orb.png",
	"frost_nova": "res://assets/sprites/catalog/weapon_frost_nova.png",
	"storm_core": "res://assets/sprites/catalog/relic_storm_core.png",
	"infernal_heart": "res://assets/sprites/catalog/relic_infernal_heart.png",
	"blood_chalice": "res://assets/sprites/catalog/relic_blood_chalice.png",
	"overdrive_engine": "res://assets/sprites/catalog/relic_overdrive_engine.png",
	"plague_mask": "res://assets/sprites/catalog/relic_plague_mask.png",
	"magnetic_coil": "res://assets/sprites/catalog/relic_magnetic_coil.png",
	"celestial_eye": "res://assets/sprites/catalog/relic_celestial_eye.png",
	"prism_crystal": "res://assets/sprites/catalog/relic_prism_crystal.png",
	"singularity": "res://assets/sprites/catalog/relic_singularity.png",
	"frozen_crown": "res://assets/sprites/catalog/relic_frozen_crown.png",
	"magnet_heart": "res://assets/sprites/catalog/relic_magnet_heart.png",
}
const EVOLUTION_ICONS := {
	"lightning_conductor": "res://assets/sprites/catalog/evolution_lightning_conductor.png",
	"inferno_sprayer": "res://assets/sprites/catalog/evolution_inferno_sprayer.png",
	"crimson_daggers": "res://assets/sprites/catalog/evolution_crimson_daggers.png",
	"minigun": "res://assets/sprites/catalog/evolution_minigun.png",
	"toxic_cloud": "res://assets/sprites/catalog/evolution_toxic_cloud.png",
	"sawblades": "res://assets/sprites/catalog/evolution_sawblades.png",
	"meteor_staff": "res://assets/sprites/catalog/evolution_meteor_staff.png",
	"prism_laser": "res://assets/sprites/catalog/evolution_prism_laser.png",
	"void_orb": "res://assets/sprites/catalog/evolution_void_orb.png",
	"frost_nova": "res://assets/sprites/catalog/evolution_frost_nova.png",
}
const STARTING_WEAPONS := ["lightning_conductor", "inferno_sprayer"]
const MAX_SLOTS := 5
const MAX_LEVEL := 5

var _weapon_levels := {}
var _relic_levels := {}
var _evolved_weapons := {}
var _weapons := {}
var _relics := {}
var _weapon_descriptions := {}
var _relic_descriptions := {}
var _weapon_definitions := {}
var _relic_definitions := {}
var _rng := RandomNumberGenerator.new()
var offer_weights := {
	"owned_upgrade": 1.5,
	"matching_relic": 2.0,
	"matching_weapon": 1.5,
	"near_evolution": 1.25,
	"combined_cap": 3.0,
}

func _init(seed_value: int = 0) -> void:
	var catalog = COMBAT_CATALOG_SCRIPT.new()
	if not catalog.error.is_empty():
		push_error(catalog.error)
	for item_id in catalog.available_ids("weapon"):
		var weapon_definition: Dictionary = catalog.weapons[item_id]
		_weapon_definitions[item_id] = weapon_definition
		_weapons[item_id] = weapon_definition["name"]
		_weapon_descriptions[item_id] = weapon_definition["behavior"]
	for item_id in catalog.available_ids("relic"):
		var relic_definition: Dictionary = catalog.relics[item_id]
		_relic_definitions[item_id] = relic_definition
		_relics[item_id] = relic_definition["name"]
		_relic_descriptions[item_id] = relic_definition["behavior"]
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value

func offers(family: String) -> Array[Dictionary]:
	var catalog: Dictionary
	var owned: Dictionary
	var descriptions: Dictionary
	if family == "weapon":
		catalog = _weapons
		owned = _weapon_levels
		descriptions = _weapon_descriptions
	elif family == "relic":
		catalog = _relics
		owned = _relic_levels
		descriptions = _relic_descriptions
	else:
		return []
	var candidates: Array[Dictionary] = []
	for item_id in catalog:
		var description: String = str(descriptions[item_id])
		if owned.has(item_id):
			if int(owned[item_id]) >= MAX_LEVEL:
				continue
			var next_level := int(owned[item_id]) + 1
			candidates.append({
				"id": "%s:%s" % [family, item_id],
				"title": "%s — Lv %d → %d" % [catalog[item_id], int(owned[item_id]), next_level],
				"description": "%s\nNEXT LEVEL: %s" % [description, _next_level_description(family, item_id, next_level)],
				"icon": ICONS.get(item_id, ""),
			})
		elif owned.size() < MAX_SLOTS:
			candidates.append({
				"id": "%s:%s" % [family, item_id],
				"title": catalog[item_id],
				"description": description,
				"icon": ICONS.get(item_id, ""),
			})
	if family == "weapon":
		for weapon_id in _weapon_definitions:
			var definition: Dictionary = _weapon_definitions[weapon_id]
			var relic_id: String = str(definition["relic_id"])
			if is_evolution_ready(weapon_id):
				candidates.append({
					"id": "evolution:%s" % weapon_id,
					"title": "EVOLUTION — %s" % str(definition["evolution_id"]).replace("_", " ").to_upper(),
					"description": "WEAPON ONLY: +25%% damage and its evolution effect. Both %s and %s are level 5." % [
						str(_weapons[weapon_id]), str(_relics[relic_id]),
					],
					"icon": EVOLUTION_ICONS.get(weapon_id, ICONS.get(weapon_id, "")),
				})
	if candidates.size() < 3:
		return candidates
	var selected: Array[Dictionary] = []
	var remaining: Array[Dictionary] = candidates.duplicate()
	for _choice_index in range(mini(3, remaining.size())):
		var weights: Array[float] = []
		var total_weight := 0.0
		for candidate in remaining:
			var weight := _offer_weight(family, str(candidate["id"]))
			weights.append(weight)
			total_weight += weight
		var chosen_index := 0
		if total_weight > 0.0:
			var roll := _rng.randf() * total_weight
			for index in range(weights.size()):
				roll -= weights[index]
				if roll < 0.0:
					chosen_index = index
					break
		else:
			chosen_index = _rng.randi_range(0, remaining.size() - 1)
		selected.append(remaining.pop_at(chosen_index))
	return selected

func _offer_weight(family: String, offer_id: String) -> float:
	var weight := 1.0
	var parts := offer_id.split(":", false, 1)
	if parts.size() != 2:
		return weight
	if parts[0] == "evolution":
		weight *= _configured_offer_weight("near_evolution")
	elif family == "weapon" and parts[0] == "weapon":
		var weapon_id: String = parts[1]
		var weapon_definition: Dictionary = _weapon_definitions.get(weapon_id, {})
		if _weapon_levels.has(weapon_id):
			weight *= _configured_offer_weight("owned_upgrade")
		var paired_relic_id := str(weapon_definition.get("relic_id", ""))
		if _relic_levels.has(paired_relic_id):
			weight *= _configured_offer_weight("matching_weapon")
			if not is_evolved(weapon_id) and _weapon_level_after_offer(weapon_id) >= 4 and relic_level(paired_relic_id) >= 4:
				weight *= _configured_offer_weight("near_evolution")
	elif family == "relic" and parts[0] == "relic":
		var relic_id: String = parts[1]
		var relic_definition: Dictionary = _relic_definitions.get(relic_id, {})
		var paired_weapon_id := str(relic_definition.get("weapon_id", ""))
		if _relic_levels.has(relic_id):
			weight *= _configured_offer_weight("owned_upgrade")
		if not paired_weapon_id.is_empty() and weapon_level(paired_weapon_id) > 0:
			weight *= _configured_offer_weight("matching_relic")
			if not is_evolved(paired_weapon_id) and weapon_level(paired_weapon_id) >= 4 and _relic_level_after_offer(relic_id) >= 4:
				weight *= _configured_offer_weight("near_evolution")
	return maxf(minf(weight, _configured_offer_weight("combined_cap")), 0.1)

func _configured_offer_weight(key: String) -> float:
	var value := float(offer_weights.get(key, 1.0))
	return maxf(value, 0.1) if is_finite(value) else 1.0

func _weapon_level_after_offer(weapon_id: String) -> int:
	return mini(weapon_level(weapon_id) + 1, MAX_LEVEL)

func _relic_level_after_offer(relic_id: String) -> int:
	return mini(relic_level(relic_id) + 1, MAX_LEVEL)

func _next_level_description(family: String, item_id: String, level: int) -> String:
	if family == "relic":
		return _relic_level_description(item_id, level)
	return _weapon_level_description(item_id, level)

func _weapon_level_description(item_id: String, level: int) -> String:
	match item_id:
		"lightning_conductor":
			return "+1 chain bounce" if level in [2, 4] else "+25% damage" if level == 3 else "Max level; collect combo when Storm Core is also level 5" if level == 5 else "Improves lightning damage"
		"inferno_sprayer":
			return "+20% direct damage" if level == 2 else "+15% range" if level == 3 else "+20% jet width" if level == 4 else "Max level; +25% Burn, collect combo when Infernal Heart is also level 5" if level == 5 else "Improves the fire jet"
		"crimson_daggers":
			return "Max level; collect combo when matching relic is also level 5" if level == 5 else "+15% damage"
		"minigun":
			return "+20% damage" if level == 2 else "+25% fire rate" if level in [3, 5] else "15% tighter spread" if level == 4 else "Improves shots"
		"toxic_cloud":
			return "+25% poison damage" if level == 5 else "+20% cloud radius" if level == 3 else "+20% poison duration" if level == 4 else "+20% poison damage" if level == 2 else "Improves poison"
		"sawblades":
			return "+20% damage" if level == 2 else "+1 ricochet" if level == 3 else "+20% projectile speed" if level == 4 else "Max level; collect combo when Magnetic Coil is also level 5" if level == 5 else "Improves ricochets"
		"meteor_staff":
			return "+20% damage" if level == 2 else "+20% explosion radius" if level == 3 else "15% shorter cooldown" if level == 4 else "Max level; collect combo when Celestial Eye is also level 5" if level == 5 else "Improves impact"
		"prism_laser":
			return "+20% damage" if level == 2 else "+20% range" if level == 3 else "+15% range" if level == 4 else "Max level; collect combo when Prism Crystal is also level 5" if level == 5 else "Improves beam"
		"void_orb":
			return "+20% damage" if level == 2 else "+20% attraction radius" if level == 3 else "+15% projectile lifetime" if level == 4 else "Max level; collect combo when Singularity is also level 5" if level == 5 else "Improves orb"
		"frost_nova":
			return "+20% damage" if level == 2 else "+20% area" if level == 3 else "+20% chill duration" if level == 4 else "Max level; collect combo when Frozen Crown is also level 5" if level == 5 else "Improves Nova"
	return "Improves the weapon"

func _relic_level_description(item_id: String, level: int) -> String:
	var definition: Dictionary = _relic_definitions.get(item_id, {})
	var stat_id := str(definition.get("global_stat", ""))
	var amount := float(definition.get("global_bonus_per_level", 0.0))
	var description := "+%d%% global %s" % [int(amount), stat_id.replace("_pct", "").replace("_", " ")]
	if item_id == "blood_chalice":
		description += " and +10% kill healing"
	if item_id == "magnet_heart" and level == MAX_LEVEL:
		description += "; reaching level 5 triggers a proposed 20 s impulse with 300% XP pickup radius"
	var weapon_id := str(definition.get("weapon_id", ""))
	if not weapon_id.is_empty():
		description += "; combo requires both level 5 and its evolution pickup"
	return description

func starting_weapon_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for weapon_id in STARTING_WEAPONS:
		options.append({
			"id": "start:%s" % weapon_id,
			"title": _weapons[weapon_id],
			"description": _weapon_descriptions[weapon_id],
			"icon": ICONS[weapon_id],
		})
	return options

func choose_starting_weapon(weapon_id: String) -> bool:
	if not _weapon_levels.is_empty() or not STARTING_WEAPONS.has(weapon_id):
		return false
	_weapon_levels[weapon_id] = 1
	return true

func apply_offer(offer_id: String) -> bool:
	var parts := offer_id.split(":", false, 1)
	if parts.size() != 2:
		return false
	if parts[0] == "evolution":
		var weapon_id: String = parts[1]
		if not is_evolution_ready(weapon_id):
			return false
		_evolved_weapons[weapon_id] = true
		return true
	var owned: Dictionary
	var catalog: Dictionary
	if parts[0] == "weapon":
		owned = _weapon_levels
		catalog = _weapons
	elif parts[0] == "relic":
		owned = _relic_levels
		catalog = _relics
	else:
		return false
	var item_id: String = parts[1]
	if not catalog.has(item_id):
		return false
	if owned.has(item_id):
		if int(owned[item_id]) >= MAX_LEVEL:
			return false
		owned[item_id] = int(owned[item_id]) + 1
	elif owned.size() < MAX_SLOTS:
		owned[item_id] = 1
	else:
		return false
	return true

func weapon_level(item_id: String) -> int:
	return int(_weapon_levels.get(item_id, 0))

func relic_level(item_id: String) -> int:
	return int(_relic_levels.get(item_id, 0))

func global_relic_bonus(stat_id: String) -> float:
	var bonus := 0.0
	for relic_id in _relic_levels:
		var definition: Dictionary = _relic_definitions[relic_id]
		if str(definition.get("global_stat", "")) == stat_id:
			bonus += float(definition.get("global_bonus_per_level", 0.0)) * float(_relic_levels[relic_id])
	return bonus

func is_evolution_ready(weapon_id: String) -> bool:
	if not _weapon_definitions.has(weapon_id) or is_evolved(weapon_id):
		return false
	var definition: Dictionary = _weapon_definitions[weapon_id]
	return weapon_level(weapon_id) >= MAX_LEVEL and relic_level(str(definition["relic_id"])) >= MAX_LEVEL

func is_evolved(weapon_id: String) -> bool:
	return bool(_evolved_weapons.get(weapon_id, false))

func has_any_evolved_weapon() -> bool:
	return not _evolved_weapons.is_empty()

func owned_weapons() -> Array[String]:
	var result: Array[String] = []
	for item_id in _weapon_levels:
		result.append(item_id)
	return result

func owned_relics() -> Array[String]:
	var result: Array[String] = []
	for item_id in _relic_levels:
		result.append(item_id)
	return result

func owned_item_details(family: String) -> Array[Dictionary]:
	var item_ids := owned_weapons() if family == "weapon" else owned_relics() if family == "relic" else []
	var definitions: Dictionary = _weapon_definitions if family == "weapon" else _relic_definitions
	var names: Dictionary = _weapons if family == "weapon" else _relics
	var descriptions: Dictionary = _weapon_descriptions if family == "weapon" else _relic_descriptions
	var levels: Dictionary = _weapon_levels if family == "weapon" else _relic_levels
	var result: Array[Dictionary] = []
	for item_id in item_ids:
		var definition: Dictionary = definitions[item_id]
		var item := {
			"id": item_id,
			"family": family,
			"name": names[item_id],
			"description": descriptions[item_id],
			"icon": ICONS.get(item_id, ""),
			"level": int(levels[item_id]),
		}
		if family == "weapon":
			item["evolution_id"] = definition["evolution_id"]
			item["evolved"] = is_evolved(item_id)
			var relic_id: String = definition["relic_id"]
			item["required_relic_name"] = _relics.get(relic_id, relic_id)
			if bool(item["evolved"]):
				item["icon"] = EVOLUTION_ICONS.get(item_id, item["icon"])
		result.append(item)
	return result
