extends RefCounted

# Prototype selection from the first three GDD pairs is [PROPOSED] until the starter pool is confirmed.
const WEAPONS := {
	"lightning_conductor": "Lightning Conductor",
	"inferno_sprayer": "Inferno Sprayer",
	"crimson_daggers": "Crimson Daggers",
}
const RELICS := {
	"storm_core": "Storm Core",
	"infernal_heart": "Infernal Heart",
	"blood_chalice": "Blood Chalice",
}
const STARTING_WEAPONS := ["lightning_conductor", "inferno_sprayer"]
const MAX_SLOTS := 5
const MAX_LEVEL := 5

var _weapon_levels := {}
var _relic_levels := {}
var _rng := RandomNumberGenerator.new()

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value

func offers(family: String) -> Array[Dictionary]:
	var catalog: Dictionary
	var owned: Dictionary
	if family == "weapon":
		catalog = WEAPONS
		owned = _weapon_levels
	elif family == "relic":
		catalog = RELICS
		owned = _relic_levels
	else:
		return []
	var candidates: Array[Dictionary] = []
	for item_id in catalog:
		if owned.has(item_id):
			if int(owned[item_id]) >= MAX_LEVEL:
				continue
			candidates.append({
				"id": "%s:%s" % [family, item_id],
				"title": "%s — niveau %d" % [catalog[item_id], int(owned[item_id]) + 1],
				"description": "Améliore l’objet équipé.",
			})
		elif owned.size() < MAX_SLOTS:
			candidates.append({
				"id": "%s:%s" % [family, item_id],
				"title": catalog[item_id],
				"description": "Ajoute cet objet à la run au niveau 1.",
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
			"title": WEAPONS[weapon_id],
			"description": "Arme de départ du prototype.",
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
		catalog = WEAPONS
	elif parts[0] == "relic":
		owned = _relic_levels
		catalog = RELICS
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
