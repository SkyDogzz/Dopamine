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
	var progression_fixture = loadout_script.new(19)
	var unlocked_weapons: Array[String] = ["lightning_conductor", "inferno_sprayer", "crimson_daggers"]
	var unlocked_relics: Array[String] = ["storm_core", "infernal_heart", "blood_chalice"]
	progression_fixture.set_unlocked_content(unlocked_weapons, unlocked_relics)
	if progression_fixture._weapons.size() != 3 or progression_fixture._relics.size() != 3 or \
		progression_fixture.starting_weapon_options().size() != 2 or \
		progression_fixture.choose_starting_weapon("frost_nova") or \
		progression_fixture.choose_starting_weapon("crimson_daggers") == false or \
		progression_fixture.apply_offer("weapon:frost_nova") or \
		progression_fixture.apply_offer("relic:frozen_crown") or \
		progression_fixture.apply_offer("relic:blood_chalice") == false:
		_fail("A run should draw only the profile's unlocked weapons and relics while accepting newly unlocked content")
		return
	var combat_catalog = load("res://scripts/combat_catalog.gd").new()
	var full_catalog_fixture = loadout_script.new(21)
	full_catalog_fixture.set_unlocked_content(combat_catalog.available_ids("weapon"), combat_catalog.available_ids("relic"))
	if full_catalog_fixture._weapons.size() != 10 or full_catalog_fixture._relics.size() != 11 or \
		full_catalog_fixture.starting_weapon_options().size() != 2:
		_fail("Unlocking every progression node should make all ten weapons and eleven relics available")
		return
	for relic_id in loadout._relics:
		var icon_path: String = loadout.ICONS.get(relic_id, "")
		if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
			_fail("Every available relic should have a loadable icon: %s" % relic_id)
			return
		var definition: Dictionary = loadout._relic_definitions[relic_id]
		var stat_id := str(definition.get("global_stat", ""))
		var expected_bonus := float(definition.get("global_bonus_per_level", 0.0))
		var relic_fixture = loadout_script.new(23)
		if stat_id.is_empty() or expected_bonus <= 0.0 or not relic_fixture.apply_offer("relic:" + relic_id) or \
			not is_equal_approx(relic_fixture.global_relic_bonus(stat_id), expected_bonus):
			_fail("Every relic should grant its configured global stat bonus: %s" % relic_id)
			return
	for weapon_id in loadout._weapon_definitions:
		var definition: Dictionary = loadout._weapon_definitions[weapon_id]
		var pair_fixture = loadout_script.new(29)
		for _level in range(loadout.MAX_LEVEL):
			if not pair_fixture.apply_offer("weapon:" + weapon_id) or \
				not pair_fixture.apply_offer("relic:" + str(definition["relic_id"])):
				_fail("Each weapon/relic pair should be upgradeable to level 5: %s" % weapon_id)
				return
		if not pair_fixture.is_evolution_ready(weapon_id) or pair_fixture.is_evolved(weapon_id) or \
			not pair_fixture.apply_offer("evolution:" + weapon_id) or not pair_fixture.is_evolved(weapon_id):
			_fail("Each combo should activate only when its evolution offer is collected: %s" % weapon_id)
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
	if not is_equal_approx(loadout._offer_weight("relic", "relic:storm_core"), 1.5):
		_fail("A relic paired with an owned weapon should receive its validated preference weight")
		return
	if not is_equal_approx(loadout._offer_weight("weapon", "weapon:minigun"), 1.0):
		_fail("An unrelated new weapon should keep a positive baseline offer weight")
		return
	var preference_fixture = loadout_script.new(41)
	preference_fixture.choose_starting_weapon("lightning_conductor")
	var matching_relic_appearances := 0
	for _sample in range(300):
		if not _find_offer(preference_fixture.offers("relic"), "relic:storm_core").is_empty():
			matching_relic_appearances += 1
	if matching_relic_appearances <= 100:
		_fail("Weighted offers should present a matching relic more often than a uniform three-of-eleven draw")
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
	var upgraded_weapon_offer := _find_offer(loadout.offers("weapon"), "weapon:inferno_sprayer")
	if upgraded_weapon_offer.is_empty() or not str(upgraded_weapon_offer["title"]).contains("2 → 3") or \
			not str(upgraded_weapon_offer["description"]).contains("NEXT LEVEL: +15% range"):
		_fail("Owned weapon offers should explain the effect of the next level")
		return
	if loadout._weapon_level_description("inferno_sprayer", 2) != "+20% direct damage" or \
		loadout._weapon_level_description("inferno_sprayer", 3) != "+15% range" or \
		loadout._weapon_level_description("inferno_sprayer", 4) != "+20% jet width" or \
		not loadout._weapon_level_description("inferno_sprayer", 5).contains("+25% Burn"):
		_fail("Inferno level descriptions should match the proposed level 2–5 progression")
		return
	if loadout._weapon_level_description("crimson_daggers", 2) != "+20% damage" or \
		loadout._weapon_level_description("crimson_daggers", 3) != "+1 orbiting dagger" or \
		loadout._weapon_level_description("crimson_daggers", 4) != "+20% orbit speed" or \
		not loadout._weapon_level_description("crimson_daggers", 5).contains("+25% damage"):
		_fail("Crimson level descriptions should match the proposed level 2–5 progression")
		return
	if loadout._weapon_level_description("lightning_conductor", 2) != "+20% damage" or \
		loadout._weapon_level_description("lightning_conductor", 3) != "+1 chain bounce" or \
		loadout._weapon_level_description("lightning_conductor", 4) != "-15% cooldown" or \
		not loadout._weapon_level_description("lightning_conductor", 5).contains("+25% damage"):
		_fail("Lightning level descriptions should match the proposed level 2–5 progression")
		return
	if loadout._weapon_level_description("void_orb", 2) != "+20% damage" or \
		loadout._weapon_level_description("void_orb", 3) != "+20% attraction radius" or \
		loadout._weapon_level_description("void_orb", 4) != "+15% projectile lifetime" or \
		not loadout._weapon_level_description("void_orb", 5).contains("+25% attraction force"):
		_fail("Void Orb level descriptions should match the proposed level 2–5 progression")
		return
	if loadout._weapon_level_description("prism_laser", 2) != "+20% damage" or \
		loadout._weapon_level_description("prism_laser", 3) != "+20% range" or \
		loadout._weapon_level_description("prism_laser", 4) != "+15% beam tracking speed" or \
		not loadout._weapon_level_description("prism_laser", 5).contains("+25% damage"):
		_fail("Prism level descriptions should match the proposed level 2–5 progression")
		return
	if not loadout._weapon_level_description("minigun", 5).contains("collect Redline") or \
		not loadout._weapon_level_description("toxic_cloud", 5).contains("collect Pandemic") or \
		not loadout._weapon_level_description("sawblades", 5).contains("+25% damage") or \
		not loadout._weapon_level_description("meteor_staff", 5).contains("+30% damage") or \
		not loadout._weapon_level_description("frost_nova", 5).contains("-20% cooldown"):
		_fail("Level-five offers should explain their proposed upgrade and available evolution")
		return
	if not loadout.apply_offer("relic:storm_core") or loadout.relic_level("storm_core") != 1:
		_fail("Selecting a new relic should add it at level 1")
		return
	if not is_equal_approx(loadout.global_relic_bonus("damage_pct"), 5.0):
		_fail("Storm Core should grant a global damage bonus before its weapon combo evolves")
		return
	if not is_equal_approx(loadout._offer_weight("weapon", "weapon:lightning_conductor"), 1.5625) or \
		not is_equal_approx(loadout._offer_weight("relic", "relic:storm_core"), 1.875):
		_fail("Owned upgrades and matching pairs should combine their validated weights")
		return
	var near_evolution_fixture = loadout_script.new(37)
	near_evolution_fixture._weapon_levels["lightning_conductor"] = 4
	near_evolution_fixture._relic_levels["storm_core"] = 4
	near_evolution_fixture.offer_weights = {
		"owned_upgrade": 1.0, "matching_relic": 1.0, "matching_weapon": 1.0,
		"near_evolution": 1.25, "combined_cap": 5.0,
	}
	if not is_equal_approx(near_evolution_fixture._offer_weight("relic", "relic:storm_core"), 1.25) or \
		not is_equal_approx(near_evolution_fixture._offer_weight("weapon", "evolution:lightning_conductor"), 1.25):
		_fail("Near-ready pairs and eligible evolutions should receive the proposed evolution weight")
		return
	var default_cap_fixture = loadout_script.new(38)
	default_cap_fixture._weapon_levels["lightning_conductor"] = 4
	default_cap_fixture._relic_levels["storm_core"] = 4
	if not is_equal_approx(default_cap_fixture._offer_weight("relic", "relic:storm_core"), 2.0):
		_fail("The transformed default combined preference should stop at its cap of 2.0")
		return
	if loadout.is_evolved("lightning_conductor"):
		_fail("Owning the matching relic should not evolve an unmaxed weapon")
		return
	var upgraded_relic_offer := {}
	for _attempt in range(50):
		upgraded_relic_offer = _find_offer(loadout.offers("relic"), "relic:storm_core")
		if not upgraded_relic_offer.is_empty():
			break
	if upgraded_relic_offer.is_empty() or not str(upgraded_relic_offer["title"]).contains("1 → 2") or \
		not str(upgraded_relic_offer["description"]).contains("NEXT LEVEL: +5% global damage"):
		_fail("Owned relic offers should explain their next global stat bonus")
		return
	for level in range(2, 6):
		if not loadout.apply_offer("weapon:lightning_conductor"):
			_fail("An owned weapon should upgrade through level 5")
			return
	if loadout.weapon_level("lightning_conductor") != 5 or loadout.apply_offer("weapon:lightning_conductor"):
		_fail("Weapon level 5 should be the cap")
		return
	if loadout.apply_offer("evolution:lightning_conductor"):
		_fail("The matching relic must also reach max level before an evolution can be claimed")
		return
	for level in range(2, 6):
		if not loadout.apply_offer("relic:storm_core"):
			_fail("The matching relic should upgrade through level 5")
			return
	if loadout.is_evolved("lightning_conductor"):
		_fail("Max-level weapon and relic should wait for the player to collect the evolution upgrade")
		return
	var evolution_offer := {}
	for _attempt in range(100):
		evolution_offer = _find_offer(loadout.offers("weapon"), "evolution:lightning_conductor")
		if not evolution_offer.is_empty():
			break
	if evolution_offer.is_empty() or not str(evolution_offer.get("description", "")).to_lower().contains("weapon only"):
		_fail("A max-level matching pair should offer its weapon-only evolution upgrade")
		return
	if not loadout.apply_offer("evolution:lightning_conductor") or not loadout.is_evolved("lightning_conductor"):
		_fail("Collecting the eligible evolution offer should activate the weapon combo")
		return
	if not _has_three_unique(loadout.offers("weapon")):
		_fail("A max-level weapon should be excluded while other weapon choices remain")
		return
	loadout._weapon_levels["inferno_sprayer"] = loadout.MAX_LEVEL
	if loadout.weapon_level("inferno_sprayer") != 5 or not _has_three_unique(loadout.offers("weapon")):
		_fail("Max-level weapons should not consume slots or remove unrelated offers")
		return
	for weapon_id in loadout._weapons:
		if weapon_id in ["lightning_conductor", "inferno_sprayer"]:
			continue
		if loadout.owned_weapons().size() >= loadout.MAX_SLOTS:
			break
		if not loadout.apply_offer("weapon:%s" % weapon_id):
			_fail("A free weapon slot should accept each distinct weapon")
			return
	if loadout.owned_weapons().size() != loadout.MAX_SLOTS or not _has_three_unique(loadout.offers("weapon")):
		_fail("A full weapon loadout should still offer eligible upgrades")
		return
	for weapon_id in loadout._weapons:
		if not loadout._weapon_levels.has(weapon_id):
			continue
		loadout._weapon_levels[weapon_id] = loadout.MAX_LEVEL
	if not loadout.offers("weapon").is_empty():
		_fail("A full loadout with all weapons at max level should expose no chest choices")
		return
	if loadout.offers("relic").size() != 3:
		_fail("A max-level weapon without its matching relic should not block relic choices")
		return
	var full_relic_fixture = loadout_script.new(31)
	var relic_ids: Array = full_relic_fixture._relics.keys()
	for index in range(full_relic_fixture.MAX_SLOTS):
		if not full_relic_fixture.apply_offer("relic:%s" % relic_ids[index]):
			_fail("Each of the five normal relic slots should accept a distinct relic")
			return
	if full_relic_fixture.owned_relics().size() != 5 or \
		full_relic_fixture.apply_offer("relic:%s" % relic_ids[5]):
		_fail("A normal run should reject a sixth relic without an active capacity effect")
		return
	for offer in full_relic_fixture.offers("relic"):
		if not full_relic_fixture.owned_relics().has(str(offer["id"]).trim_prefix("relic:")):
			_fail("A full relic loadout should offer upgrades only, not another new relic")
			return
	var expanded_fixture = loadout_script.new(37)
	expanded_fixture.set_slot_capacity_bonus(1, 1)
	var weapon_ids: Array = expanded_fixture._weapons.keys()
	var expanded_relic_ids: Array = expanded_fixture._relics.keys()
	for index in range(6):
		if not expanded_fixture.apply_offer("weapon:%s" % weapon_ids[index]) or \
				not expanded_fixture.apply_offer("relic:%s" % expanded_relic_ids[index]):
			_fail("An active capacity effect should allow six weapons and six relics")
			return
	if expanded_fixture.owned_weapons().size() != 6 or expanded_fixture.owned_relics().size() != 6 or \
		expanded_fixture.apply_offer("weapon:%s" % weapon_ids[6]) or \
		expanded_fixture.apply_offer("relic:%s" % expanded_relic_ids[6]):
		_fail("Expanded loadout capacity should stop at six and reject a seventh item")
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

func _find_offer(offers: Array, offer_id: String) -> Dictionary:
	for offer in offers:
		if str(offer.get("id", "")) == offer_id:
			return offer
	return {}

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
