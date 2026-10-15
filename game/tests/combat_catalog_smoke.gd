extends SceneTree

func _initialize() -> void:
	var catalog = load("res://scripts/combat_catalog.gd").new()
	if not catalog.error.is_empty():
		_fail(catalog.error)
		return
	if catalog.weapons.size() != 10 or catalog.relics.size() != 11:
		_fail("Combat catalog should contain ten weapons and eleven relics")
		return
	if catalog.available_ids("weapon").size() != 5 or catalog.available_ids("relic").size() != 6:
		_fail("Survival should expose five available weapon pairs and Magnet Heart")
		return
	if catalog.weapons["crimson_daggers"]["behavior"] != "Dagues en orbite autour du joueur, non lancées":
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
	if loadout._weapons.size() != 5 or loadout._relics.size() != 6:
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
