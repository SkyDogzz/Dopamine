extends SceneTree

func _initialize() -> void:
	var loadout_script = load("res://scripts/survival_loadout.gd")
	if loadout_script == null:
		_fail("Survival loadout script should exist")
		return
	var loadout = loadout_script.new(17)
	if loadout.owned_weapons().size() != 0 or loadout.starting_weapon_options().size() != 2:
		_fail("A new run should offer two proposed starting weapons")
		return
	for relic_id in loadout._relics:
		var icon_path: String = loadout.ICONS.get(relic_id, "")
		if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
			_fail("Every available relic should have a loadable icon: %s" % relic_id)
			return
	for weapon_id in loadout._weapons:
		var weapon_icon_path: String = loadout.ICONS.get(weapon_id, "")
		if weapon_icon_path.is_empty() or not ResourceLoader.exists(weapon_icon_path):
			_fail("Every available weapon should have a loadable icon: %s" % weapon_id)
			return
	if not loadout.choose_starting_weapon("lightning_conductor"):
		_fail("The player should be able to choose an available starting weapon")
		return
	if loadout.weapon_level("lightning_conductor") != 1 or loadout.owned_weapons().size() != 1:
		_fail("The chosen starting weapon should enter the loadout at level 1")
		return
	var weapon_offers: Array = loadout.offers("weapon")
	if not _has_three_unique(weapon_offers):
		_fail("Weapon chest should offer three unique eligible upgrades or new weapons")
		return
	for offer in weapon_offers:
		if str(offer.get("icon", "")).is_empty() or not ResourceLoader.exists(str(offer["icon"])):
			_fail("Weapon offers should include their generated icon assets")
			return
	var relic_offers: Array = loadout.offers("relic")
	if not _has_three_unique(relic_offers):
		_fail("Relic chest should offer three unique relic choices")
		return
	for offer in relic_offers:
		if str(offer.get("icon", "")).is_empty() or not ResourceLoader.exists(str(offer["icon"])):
			_fail("Relic offers should include their generated icon assets")
			return
	if not loadout.apply_offer("weapon:inferno_sprayer") or loadout.weapon_level("inferno_sprayer") != 1:
		_fail("Selecting a new weapon should add it at level 1")
		return
	if not loadout.apply_offer("weapon:inferno_sprayer") or loadout.weapon_level("inferno_sprayer") != 2:
		_fail("Selecting an owned weapon should upgrade it")
		return
	if not loadout.apply_offer("relic:storm_core") or loadout.relic_level("storm_core") != 1:
		_fail("Selecting a new relic should add it at level 1")
		return
	for level in range(2, 6):
		if not loadout.apply_offer("weapon:lightning_conductor"):
			_fail("An owned weapon should upgrade through level 5")
			return
	if loadout.weapon_level("lightning_conductor") != 5 or loadout.apply_offer("weapon:lightning_conductor"):
		_fail("Weapon level 5 should be the cap")
		return
	print("Survival loadout smoke passed")
	quit()

func _has_three_unique(offers: Array) -> bool:
	if offers.size() != 3:
		return false
	var ids := {}
	for offer in offers:
		ids[offer["id"]] = true
	return ids.size() == 3

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
