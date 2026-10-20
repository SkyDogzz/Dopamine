extends SceneTree

class FakeSimulation extends RefCounted:
	var radius_calls: Array[Dictionary] = []

	func damage_enemies_in_radius(center: Vector2, radius: float, damage: float) -> int:
		radius_calls.append({"center": center, "radius": radius, "damage": damage})
		return 0

func _initialize() -> void:
	var session_script = load("res://scripts/survival_session.gd")
	var loadout_script = load("res://scripts/survival_loadout.gd")
	if session_script == null or loadout_script == null:
		_fail("Survival session and loadout should parse with cursed items")
		return
	var session = session_script.new()
	session.loadout = loadout_script.new(1)
	session.mode_id = "survival"
	session._overstimulation_cursed_rng.seed = 4302
	if session._overstimulation_cursed_drop_due(false, false) or \
		session._overstimulation_cursed_drop_due(false, false):
		_fail("Ordinary chests should never offer cursed items")
		return
	var cursed_count := 0
	for index in range(1000):
		if session._overstimulation_cursed_drop_due(index % 2 == 0, false):
			cursed_count += 1
	if cursed_count < 80 or cursed_count > 120:
		_fail("Eligible elite chest opportunities should use the 20 percent cursed offer chance")
		return
	var boss_offer_eligible := false
	for index in range(100):
		if session._overstimulation_cursed_drop_due(false, true):
			boss_offer_eligible = true
			break
	if not boss_offer_eligible:
		_fail("Boss chests should be eligible for a cursed offer")
		return
	var replacement: Dictionary = session._overstimulation_cursed_offer()
	session._overstimulation_cursed_item_active = "blood_debt"
	replacement = session._overstimulation_cursed_offer()
	if not str(replacement["description"]).begins_with("Replaces BLOOD DEBT."):
		_fail("Replacing a curse should be clearly disclosed")
		return
	session._base_player_max_hp = 100.0
	session.player_max_hp = 100.0
	session.player_hp = 80.0
	for item_id in ["blood_debt", "glass_cannon", "red_hunger", "volatile_core"]:
		session._overstimulation_cursed_item_active = item_id
		session._apply_overstimulation_cursed_item()
		match item_id:
			"blood_debt":
				if not is_equal_approx(session._persistent_damage_multiplier(), 1.4) or \
					not is_equal_approx(session._overstimulation_cursed_health_decay_multiplier, 1.35):
					_fail("Blood Debt should increase damage and health decay")
					return
			"glass_cannon":
				if not is_equal_approx(session._persistent_damage_multiplier(), 1.6) or \
					not is_equal_approx(session._overstimulation_cursed_max_hp_multiplier, 0.65) or \
					not is_equal_approx(session.player_max_hp, 65.0) or not is_equal_approx(session.player_hp, 52.0):
					_fail("Glass Cannon should trade maximum HP for damage")
					return
			"red_hunger":
				if not is_equal_approx(session._effective_weapon_cooldown(1.0), 1.0 / 1.3) or \
					not is_equal_approx(session._overstimulation_cursed_enemy_speed_multiplier, 1.25):
					_fail("Red Hunger should speed up attacks and enemies")
					return
			"volatile_core":
				if not is_equal_approx(session._overstimulation_cursed_volatility_multiplier, 1.5) or \
					not is_equal_approx(session._overstimulation_cursed_contact_damage_multiplier, 1.5):
					_fail("Volatile Core should amplify kill explosions and contact damage")
					return
				var simulation := FakeSimulation.new()
				session.simulation = simulation
				session._record_overstimulation_cursed_kill("chaser", Vector2(3.0, 4.0))
				session._record_overstimulation_cursed_kill("mid_boss", Vector2.ZERO)
				if simulation.radius_calls.size() != 1 or \
					not is_equal_approx(float(simulation.radius_calls[0]["radius"]),
						session.OVERSTIMULATION_CHAIN_REACTION_RADIUS) or \
					not is_equal_approx(float(simulation.radius_calls[0]["damage"]), 1.5):
					_fail("Volatile Core should explode at 150 percent base damage and exclude bosses")
					return
		session._overstimulation_cursed_item_active = ""
	session.mode_id = "armorless"
	if session._overstimulation_cursed_drop_due(true, true):
		_fail("Armorless should not offer cursed items")
		return
	session.mode_id = "survival"
	session.sandbox_diagnostics_enabled = true
	if session._overstimulation_cursed_drop_due(true, true):
		_fail("Sandbox should not offer cursed items")
		return
	session.free()
	print("Survival cursed item smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
