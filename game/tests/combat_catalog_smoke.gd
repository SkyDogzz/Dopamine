extends SceneTree

func _initialize() -> void:
	var catalog = load("res://scripts/combat_catalog.gd").new()
	if not catalog.error.is_empty():
		_fail(catalog.error)
		return
	var raw_file := FileAccess.open("res://data/combat_catalog.json", FileAccess.READ)
	var source: Dictionary = JSON.parse_string(raw_file.get_as_text())
	var string_version: Dictionary = source.duplicate(true)
	string_version["schema_version"] = "1"
	if not _catalog_rejects(string_version):
		_fail("Combat catalog schema_version must be an integer")
		return
	var invalid_behavior: Dictionary = source.duplicate(true)
	invalid_behavior["weapons"][0]["behavior"] = 7
	if not _catalog_rejects(invalid_behavior):
		_fail("Combat catalog behavior fields must be strings")
		return
	var invalid_availability: Dictionary = source.duplicate(true)
	invalid_availability["weapons"][0]["available_in_survival"] = "true"
	if not _catalog_rejects(invalid_availability):
		_fail("Combat catalog availability fields must be booleans")
		return
	var duplicate_evolution: Dictionary = source.duplicate(true)
	duplicate_evolution["weapons"][1]["evolution_id"] = duplicate_evolution["weapons"][0]["evolution_id"]
	if not _catalog_rejects(duplicate_evolution):
		_fail("Combat catalog evolution IDs must be unique")
		return
	var unexpected_field: Dictionary = source.duplicate(true)
	unexpected_field["weapons"][0]["experimental"] = true
	if not _catalog_rejects(unexpected_field):
		_fail("Combat catalog entries must reject fields outside their schema")
		return
	if catalog.weapons.size() != 10 or catalog.relics.size() != 11:
		_fail("Combat catalog should contain ten weapons and eleven relics")
		return
	if catalog.available_ids("weapon").size() != 10 or catalog.available_ids("relic").size() != 11:
		_fail("Survival should expose ten available weapon pairs and Magnet Heart")
		return
	if not str(catalog.weapons["crimson_daggers"]["behavior"]).begins_with("Dagues en orbite autour du joueur, non lancées"):
		_fail("Catalog should preserve the validated orbiting dagger behavior")
		return
	if catalog.relics["magnet_heart"].has("weapon_id") or catalog.relics["magnet_heart"].has("evolution_id"):
		_fail("Magnet Heart must remain an unpaired utility relic")
		return
	var magnet_icon: Texture2D = load("res://assets/sprites/relic_magnet_heart.svg")
	if magnet_icon == null:
		_fail("Magnet Heart should have a chest-ready icon asset")
		return
	var loadout = load("res://scripts/survival_loadout.gd").new(19)
	if loadout._weapons.size() != 10 or loadout._relics.size() != 11:
		_fail("Survival loadout should include only implemented catalog entries")
		return
	if not loadout._relics.has("magnet_heart"):
		_fail("Implemented Magnet Heart should enter the Survival relic pool")
		return
	var starting_options: Array = loadout.starting_weapon_options()
	if starting_options.size() != 2 or starting_options[0]["title"] != "Lightning Conductor" or \
			starting_options[1]["title"] != "Inferno Sprayer":
		_fail("Starting weapon choices should resolve names from the loaded catalog")
		return
	print("Combat catalog smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _catalog_rejects(data: Dictionary) -> bool:
	var catalog = load("res://scripts/combat_catalog.gd").new()
	catalog.weapons.clear()
	catalog.relics.clear()
	catalog.error = ""
	return not catalog._load_definitions(data)
