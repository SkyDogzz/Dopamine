extends SceneTree

func _initialize() -> void:
	var session_script = load("res://scripts/survival_session.gd")
	var loadout_script = load("res://scripts/survival_loadout.gd")
	if session_script == null or loadout_script == null:
		_fail("Survival session and loadout should parse with weapon/relic synergies")
		return
	var session = session_script.new()
	session.loadout = loadout_script.new(1)
	session.mode_id = "survival"
	var pairs: Dictionary = session.OVERSTIMULATION_WEAPON_RELIC_PAIRS
	if pairs.size() != 10 or pairs.get("lightning_conductor", "") != "storm_core":
		_fail("All ten approved evolved weapon/relic pairings should be registered")
		return
	for paired_weapon in pairs:
		var definition: Dictionary = session.loadout._weapon_definitions.get(paired_weapon, {})
		if definition.is_empty() or str(definition.get("relic_id", "")) != str(pairs[paired_weapon]):
			_fail("Synergy pairing for %s should match the weapon catalog" % paired_weapon)
			return
	var weapon_id := "lightning_conductor"
	var relic_id := str(pairs[weapon_id])
	for _level in range(session.loadout.MAX_LEVEL):
		if not session.loadout.apply_offer("weapon:" + weapon_id) or \
			not session.loadout.apply_offer("relic:" + relic_id):
			_fail("The Lightning/Storm fixture should reach level five")
			return
	if not session.loadout.apply_offer("evolution:" + weapon_id):
		_fail("The fixture should acquire its evolution")
		return
	if not session._activate_overstimulation_weapon_relic_synergy(weapon_id, 0.0):
		_fail("Pair fixture failed: evolved=%s weapon=%d relic=%d" % [
			session.loadout.is_evolved(weapon_id), session.loadout.weapon_level(weapon_id),
			session.loadout.relic_level(relic_id)])
		return
	if session._overstimulation_weapon_relic_synergy_available(weapon_id, 11.99) or \
		not session._overstimulation_weapon_relic_synergy_available(weapon_id, 12.0):
		_fail("Each evolved pair should become eligible again after 12 seconds")
		return
	session.sandbox_diagnostics_enabled = true
	if session._overstimulation_weapon_relic_synergy_available(weapon_id, 24.0):
		_fail("Sandbox diagnostics should disable weapon/relic synergy procs")
		return
	session.sandbox_diagnostics_enabled = false
	session.mode_id = "armorless"
	if session._overstimulation_weapon_relic_synergy_available(weapon_id, 24.0):
		_fail("Armorless should not receive Overstimulation weapon/relic synergy procs")
		return
	session.free()
	print("Survival weapon/relic synergy smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
