extends SceneTree

class FakeSimulation:
	var explosions: Array[Array] = []

	func apply_boss_chain_explosion(center: Vector2, radius: float, damage: float,
			damage_is_health_fraction: bool, knockback_speed: float, chain_depth: int) -> int:
		explosions.append([center, radius, damage, damage_is_health_fraction, knockback_speed, chain_depth])
		return explosions.size()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session_script = load("res://scripts/survival_session.gd")
	if session_script == null:
		_fail("SurvivalSession should parse with boss chain explosions")
		return
	var session = session_script.new()
	var fake := FakeSimulation.new()
	session.simulation = fake
	session.mode_id = "survival"
	var boss_event := {"source_type": "minigun", "causal_damage": 0.0}
	session._overstimulation_boss_chain_death(boss_event, "mid_boss", Vector2(12.0, 34.0))
	if fake.explosions.size() != 1 or fake.explosions[0] != [Vector2(12.0, 34.0), 160.0, 0.2, true, 220.0, 0]:
		_fail("A boss death should create one 160 px blast dealing 20 percent max HP and knockback")
		return
	var chain_event := {"source_type": "boss_chain_0", "causal_damage": 20.0}
	session._overstimulation_boss_chain_death(chain_event, "chaser", Vector2(20.0, 30.0))
	if fake.explosions.size() != 2 or fake.explosions[1] != [Vector2(20.0, 30.0), 72.0, 10.0, false, 220.0, 1]:
		_fail("A chain kill should spread 50 percent of its causal blast damage to radius 72")
		return
	for depth in [1, 2]:
		session._overstimulation_boss_chain_death({"source_type": "boss_chain_%s" % depth,
			"causal_damage": 10.0}, "elite", Vector2.ZERO)
	if fake.explosions.size() != 4 or fake.explosions[2][5] != 2 or fake.explosions[3][5] != 3:
		_fail("Boss chain explosions should stop after three secondary bonds")
		return
	session._overstimulation_boss_chain_death({"source_type": "boss_chain_3", "causal_damage": 5.0},
			"chaser", Vector2.ZERO)
	if fake.explosions.size() != 4:
		_fail("The third secondary bond must not spread further")
		return
	var finisher_event := {"target": {"index": 2, "generation": 1}, "target_type": "chaser",
		"source_type": "boss_chain_0", "amount": 100.0, "remaining_health": 1.0}
	if session._try_overstimulation_finisher_hit(finisher_event,
			[{"id": finisher_event["target"], "components": {"Health": {"current": 1.0, "maximum": 100.0}}}], 1.0):
		_fail("Boss chain blasts must not trigger direct-impact finishers")
		return
	session.sandbox_diagnostics_enabled = true
	session._overstimulation_boss_chain_death(boss_event, "final_boss", Vector2.ZERO)
	if fake.explosions.size() != 4:
		_fail("Sandbox diagnostics must stay outside boss chain explosions")
		return
	session.sandbox_diagnostics_enabled = false
	session.mode_id = "armorless"
	session._overstimulation_boss_chain_death(boss_event, "final_boss", Vector2.ZERO)
	if fake.explosions.size() != 4:
		_fail("Armorless must stay outside boss chain explosions")
		return
	session.free()
	if not await _verify_native_explosion():
		return
	print("Survival boss chain smoke passed")
	quit()

func _verify_native_explosion() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	session.xp_collection_radius = 0.0
	root.add_child(session)
	await process_frame
	session.player.global_position = Vector2(-1000.0, 1000.0)
	if session.simulation == null or not session.simulation.has_method("apply_boss_chain_explosion"):
		session.queue_free()
		_fail("The compiled CombatSimulation should expose the boss chain command")
		return false
	session.simulation.spawn("chaser", 1, Vector2(100.0, 0.0), 100.0, Vector2.ZERO, 1.0)
	session.simulation.spawn("sprinter", 1, Vector2(-40.0, 0.0), 20.0, Vector2.ZERO, 1.0)
	session.simulation.spawn("mid_boss", 1, Vector2(30.0, 0.0), 500.0, Vector2.ZERO, 1.0)
	session.simulation.spawn_projectile("enemy_projectile", Vector2(20.0, 0.0), Vector2.ZERO,
			10.0, 3.0, 5.0)
	if not await _wait_for_native_entities(session, 4):
		session.queue_free()
		_fail("Native boss chain smoke entities should spawn")
		return false
	var sequence: int = session.simulation.apply_boss_chain_explosion(Vector2.ZERO, 160.0, 0.2, true, 220.0, 0)
	if sequence <= 0 or not await _wait_for_native_blast(session):
		session.queue_free()
		_fail("The native boss blast should damage ordinary enemies, preserve bosses/projectiles and emit source metadata")
		return false
	session.queue_free()
	await process_frame
	return true

func _wait_for_native_entities(session: Node2D, expected: int) -> bool:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if session.simulation.snapshot()["entities"].size() >= expected:
			return true
	return false

func _wait_for_native_blast(session: Node2D) -> bool:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var state: Dictionary = session.simulation.snapshot()
		var health_by_type: Dictionary = {}
		var chain_damage_events := 0
		for entity in state["entities"]:
			var enemy_type := str(entity["components"].get("EnemyType", ""))
			if enemy_type in ["chaser", "sprinter", "mid_boss"]:
				health_by_type[enemy_type] = float(entity["components"]["Health"]["current"])
		for event in state["events"]:
			if event.get("type", "") == "damage" and event.get("source_type", "") == "boss_chain_0" and \
					is_equal_approx(float(event.get("amount", 0.0)), 20.0):
				chain_damage_events += 1
		if is_equal_approx(float(health_by_type.get("chaser", 0.0)), 80.0) and \
				is_equal_approx(float(health_by_type.get("sprinter", 0.0)), 16.0) and \
				is_equal_approx(float(health_by_type.get("mid_boss", 0.0)), 500.0) and chain_damage_events == 1:
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
