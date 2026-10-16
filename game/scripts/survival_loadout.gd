extends RefCounted

const COMBAT_CATALOG_SCRIPT := preload("res://scripts/combat_catalog.gd")
const ICONS := {
	"lightning_conductor": "res://assets/sprites/projectile_lightning.png",
	"inferno_sprayer": "res://assets/sprites/projectile_inferno.png",
	"crimson_daggers": "res://assets/sprites/projectile_crimson.png",
	"minigun": "res://assets/sprites/projectile_minigun.svg",
	"toxic_cloud": "res://assets/sprites/projectile_toxic_cloud.svg",
	"sawblades": "res://assets/sprites/projectile_sawblades.svg",
	"meteor_staff": "res://assets/sprites/projectile_meteor.svg",
	"prism_laser": "res://assets/sprites/projectile_prism_laser.svg",
	"void_orb": "res://assets/sprites/projectile_void_orb.svg",
	"frost_nova": "res://assets/sprites/projectile_frost_nova.svg",
	"storm_core": "res://assets/sprites/relic_storm_core.png",
	"infernal_heart": "res://assets/sprites/relic_infernal_heart.png",
	"blood_chalice": "res://assets/sprites/relic_blood_chalice.png",
	"overdrive_engine": "res://assets/sprites/relic_overdrive_engine.svg",
	"plague_mask": "res://assets/sprites/relic_plague_mask.svg",
	"magnetic_coil": "res://assets/sprites/relic_magnetic_coil.svg",
	"celestial_eye": "res://assets/sprites/relic_celestial_eye.svg",
	"prism_crystal": "res://assets/sprites/relic_prism_crystal.svg",
	"singularity": "res://assets/sprites/relic_singularity.svg",
	"frozen_crown": "res://assets/sprites/relic_frozen_crown.svg",
	"magnet_heart": "res://assets/sprites/relic_magnet_heart.svg",
}
const STARTING_WEAPONS := ["lightning_conductor", "inferno_sprayer"]
const MAX_SLOTS := 5
const MAX_LEVEL := 5

var _weapon_levels := {}
var _relic_levels := {}
var _weapons := {}
var _relics := {}
var _weapon_descriptions := {}
var _relic_descriptions := {}
var _weapon_definitions := {}
var _relic_definitions := {}
var _rng := RandomNumberGenerator.new()

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
			candidates.append({
				"id": "%s:%s" % [family, item_id],
				"title": "%s — niveau %d" % [catalog[item_id], int(owned[item_id]) + 1],
				"description": description,
				"icon": ICONS.get(item_id, ""),
			})
		elif owned.size() < MAX_SLOTS:
			candidates.append({
				"id": "%s:%s" % [family, item_id],
				"title": catalog[item_id],
				"description": description,
				"icon": ICONS.get(item_id, ""),
			})
	if candidates.size() < 3:
		return []
	for index in range(candidates.size() - 1, 0, -1):
		var other := _rng.randi_range(0, index)
		var temporary: Dictionary = candidates[index]
		candidates[index] = candidates[other]
		candidates[other] = temporary
	return candidates.slice(0, 3)

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
			var relic_id: String = definition["relic_id"]
			item["evolution_id"] = definition["evolution_id"]
			item["evolved"] = int(levels[item_id]) >= MAX_LEVEL and relic_level(relic_id) > 0
			item["required_relic_name"] = _relics.get(relic_id, relic_id)
		result.append(item)
	return result
