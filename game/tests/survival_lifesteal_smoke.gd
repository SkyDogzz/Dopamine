extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	session.ordinary_chest_drop_chance = 0.0
	session.xp_collection_radius = 0.0
	root.add_child(session)
	await process_frame
	if not session.loadout.apply_offer("relic:blood_chalice"):
		_fail("Blood Chalice should be equipable")
		return
	var base_kill_healing: float = session.simulation.kill_heal_amount(1.0)
	for level in range(1, session.loadout.MAX_LEVEL + 1):
		if level > 1 and not session.loadout.apply_offer("relic:blood_chalice"):
			_fail("Blood Chalice should level up through its maximum level")
			return
		var expected_kill_healing: float = base_kill_healing * (1.0 + level * session.blood_chalice_heal_per_level)
		if not is_equal_approx(session._equipment_kill_healing(base_kill_healing), expected_kill_healing):
			_fail("Blood Chalice level %d should apply its configured global kill-healing bonus" % level)
			return
	session.player_hp = 50.0
	session.simulation.set_speed(0.25)
	session.simulation.spawn("test_target", 1, Vector2(60.0, 0.0), 100.0, Vector2.ZERO, 1.0)
	session.simulation.spawn_projectile("test_weapon", Vector2.ZERO, Vector2(1000.0, 0.0), 40.0, 3.0, 1.0)
	if not await _wait_until(func() -> bool:
		return int(session.simulation.snapshot()["metrics"]["collision_count"]) > 0 and session.player_hp > 50.2
	):
		_fail("Blood Chalice should heal from weapon damage events")
		return
	if session.kill_count != 0:
		_fail("Lifesteal should work on damage without requiring an enemy kill")
		return
	session.player_hp = 50.0
	session._pending_lifesteal = 40.0
	session._apply_pending_lifesteal(2.0)
	if not is_equal_approx(session.player_hp, 75.0):
		_fail("Lifesteal should apply the proposed 10 HP/s cap and 25% overflow efficiency")
		return
	session.player_hp = 99.5
	session._pending_lifesteal = 40.0
	session._apply_pending_lifesteal(2.0)
	if not is_equal_approx(session.player_hp, session.player_max_hp):
		_fail("Lifesteal should not heal above maximum HP")
		return
	session.simulation.kill_all()
	session.player_hp = 50.0
	session.inferno_burn_damage_per_tick = 4.0
	session.inferno_burn_interval_seconds = 0.1
	session.inferno_burn_duration_seconds = 0.4
	session.simulation.set_speed(0.25)
	session.simulation.spawn("burn_target", 1, Vector2(80.0, 0.0), 100.0, Vector2.ZERO, 1.0)
	session.simulation.spawn_projectile("inferno_sprayer", Vector2.ZERO, Vector2(1000.0, 0.0),
		1.0, 3.0, 2.0, session.inferno_burn_damage_per_tick,
		session.inferno_burn_interval_seconds, session.inferno_burn_duration_seconds)
	var burned_state: Dictionary = await _wait_for_state(session, func(state: Dictionary) -> bool:
		for entity in state["entities"]:
			if entity["components"].has("DamageOverTime"):
				return true
		return false
	)
	if burned_state.is_empty():
		_fail("Inferno Sprayer impact should apply its configured burn")
		return
	var burn_type := ""
	for entity in burned_state["entities"]:
		if entity["components"].has("DamageOverTime"):
			burn_type = str(entity["components"]["DamageOverTime"].get("status_type", ""))
			break
	if burn_type != "burn" or session._status_effect_color(burn_type) == session._status_effect_color("poison"):
		_fail("Burn should preserve its type and use a visual color distinct from Poison")
		return
	var before_burn_heal: float = session.player_hp
	if not await _wait_until(func() -> bool: return session.player_hp > before_burn_heal):
		_fail("Burn ticks should contribute lifesteal in Survival")
		return
	if session.player_hp - before_burn_heal >= 0.5:
		_fail("Burn lifesteal should be reduced to the proposed 25% rate")
		return
	print("Survival lifesteal smoke passed")
	quit()

func _wait_for_state(session: Node2D, predicate: Callable) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var state: Dictionary = session.simulation.snapshot()
		if predicate.call(state):
			return state
	return {}

func _wait_until(predicate: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if predicate.call():
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
