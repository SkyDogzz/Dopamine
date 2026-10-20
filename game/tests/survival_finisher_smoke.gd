extends SceneTree

class FakeSimulation:
	var finisher_calls: Array[Array] = []
	var area_calls: Array[Array] = []

	func apply_finisher_damage(index: int, generation: int, damage: float) -> int:
		finisher_calls.append([index, generation, damage])
		return 1

	func damage_enemies_in_radius(position: Vector2, radius: float, damage: float) -> int:
		area_calls.append([position, radius, damage])
		return 1

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session_script = load("res://scripts/survival_session.gd")
	if session_script == null:
		_fail("SurvivalSession should parse with finishers")
		return
	var session = session_script.new()
	var fake := FakeSimulation.new()
	session.simulation = fake
	session.mode_id = "survival"
	var target_id := {"index": 5, "generation": 2}
	var entities := [{"id": target_id, "components": {"EnemyType": "elite",
		"Health": {"current": 9.0, "maximum": 100.0}}}]
	var event := {"target": target_id, "target_type": "elite", "source_type": "minigun",
		"source": {"index": 8, "generation": 1}, "amount": 4.0, "remaining_health": 9.0,
		"is_damage_over_time": false}
	var dot_event := event.duplicate(true)
	dot_event["is_damage_over_time"] = true
	if session._try_overstimulation_finisher_hit(dot_event, entities, 1.0) or \
			session._overstimulation_finisher_targets.has("5:2"):
		_fail("Damage over time must not create or trigger a finisher")
		return
	if session._try_overstimulation_finisher_hit(event, entities, 1.0) or \
			not session._overstimulation_finisher_targets.has("5:2") or \
			not session._overstimulation_finisher_markers.has("5:2"):
		_fail("A non-boss at 10 percent health should enter finisher state and show its marker")
		return
	var weak_hit := event.duplicate(true)
	weak_hit["amount"] = 9.0
	if session._try_overstimulation_finisher_hit(weak_hit, entities, 1.1) or not fake.finisher_calls.is_empty():
		_fail("An impact below 10 percent max HP should deal normal damage")
		return
	var strong_hit := weak_hit.duplicate(true)
	strong_hit["amount"] = 10.0
	strong_hit["remaining_health"] = 1.0
	if not session._try_overstimulation_finisher_hit(strong_hit, entities, 1.2) or \
			fake.finisher_calls.size() != 1 or fake.finisher_calls[0] != [5, 2, 100.0]:
		_fail("A qualifying direct impact should issue one lethal command for the marked target")
		return
	session._resolve_overstimulation_finisher_death("5:2", Vector2(12.0, 34.0))
	if fake.area_calls.size() != 1 or fake.area_calls[0] != [Vector2(12.0, 34.0), 48.0, 5.0] or \
			session._overstimulation_finisher_pending.has("5:2"):
		_fail("A finisher death should trigger one radius-48 blast at half the impact damage")
		return
	var lethal_id := {"index": 6, "generation": 1}
	var lethal_event := event.duplicate(true)
	lethal_event["target"] = lethal_id
	lethal_event["remaining_health"] = 8.0
	if session._try_overstimulation_finisher_hit(lethal_event,
			[{"id": lethal_id, "components": {"Health": {"current": 8.0, "maximum": 100.0}}}], 1.3):
		_fail("Entering finisher state should not consume the impact")
		return
	lethal_event["remaining_health"] = 0.0
	lethal_event["amount"] = 10.0
	if not session._try_overstimulation_finisher_hit(lethal_event, [], 1.4) or fake.finisher_calls.size() != 1:
		_fail("A qualifying hit that already killed the marked target should use its normal death event")
		return
	var lethal_result: Dictionary = session._resolve_overstimulation_finisher_death("6:1", Vector2(0.0, 0.0))
	if str(lethal_result.get("source_type", "")) != "minigun" or fake.area_calls.size() != 2:
		_fail("A native lethal impact should keep its weapon credit and trigger the finisher blast once")
		return
	var boss_event := event.duplicate(true)
	boss_event["target_type"] = "mid_boss"
	if session._try_overstimulation_finisher_hit(boss_event, entities, 2.0):
		_fail("Bosses must never enter finisher state")
		return
	session.mode_id = "armorless"
	if session._try_overstimulation_finisher_hit(event, entities, 3.0):
		_fail("Armorless must remain outside the finisher feature")
		return
	session.free()
	if not await _verify_native_finisher():
		return
	print("Survival finisher smoke passed")
	quit()

func _verify_native_finisher() -> bool:
	var native_session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	native_session.spawn_initial_enemy = false
	native_session.wave_spawning_enabled = false
	native_session.weapon_enabled = false
	native_session.skip_starting_weapon_choice = true
	native_session.contact_damage_per_hit = 0.0
	native_session.xp_collection_radius = 0.0
	root.add_child(native_session)
	await process_frame
	native_session.player.global_position = Vector2(-1000.0, 1000.0)
	if native_session.simulation == null or not native_session.simulation.has_method("apply_finisher_damage"):
		native_session.queue_free()
		_fail("The compiled CombatSimulation binding should expose apply_finisher_damage")
		return false
	native_session._health_locked = true
	native_session.simulation.spawn("chaser", 1, Vector2(100.0, 0.0), 100.0, Vector2.ZERO, 1.0)
	native_session.simulation.spawn("chaser", 1, Vector2(100.0, 40.0), 100.0, Vector2.ZERO, 1.0)
	if not await _wait_for_enemy_count(native_session, 2):
		native_session.queue_free()
		_fail("Native finisher smoke targets should spawn")
		return false
	var state: Dictionary = native_session.simulation.snapshot()
	var target_id: Dictionary = {}
	var neighbor_id: Dictionary = {}
	var target_distance := INF
	var neighbor_distance := INF
	for entity in state["entities"]:
		var transform: Dictionary = entity["components"]["Transform2D"]
		var position := Vector2(float(transform["x"]), float(transform["y"]))
		if position.distance_squared_to(Vector2(100.0, 0.0)) < target_distance:
			target_id = entity["id"]
			target_distance = position.distance_squared_to(Vector2(100.0, 0.0))
		if position.distance_squared_to(Vector2(100.0, 40.0)) < neighbor_distance:
			neighbor_id = entity["id"]
			neighbor_distance = position.distance_squared_to(Vector2(100.0, 40.0))
	if target_id.is_empty() or neighbor_id.is_empty():
		native_session.queue_free()
		_fail("Native finisher smoke should identify its target and neighbor")
		return false
	var target_key: String = native_session._entity_key(int(target_id["index"]), int(target_id["generation"]))
	native_session._overstimulation_finisher_pending[target_key] = {
		"impact_damage": 10.0, "maximum_health": 100.0, "source_type": "minigun",
	}
	native_session.simulation.apply_finisher_damage(int(target_id["index"]), int(target_id["generation"]), 100.0)
	if not await _wait_for_native_result(native_session, neighbor_id, 95.0):
		native_session.queue_free()
		_fail("A finisher death should retain the normal kill/XP event and burst for half impact damage")
		return false
	native_session.queue_free()
	await process_frame
	return true

func _wait_for_enemy_count(session: Node2D, expected: int) -> bool:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var count := 0
		for entity in session.simulation.snapshot()["entities"]:
			if entity["components"].get("EnemyType", "") == "chaser":
				count += 1
		if count >= expected:
			return true
	return false

func _wait_for_native_result(session: Node2D, target_id: Dictionary, expected_health: float) -> bool:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var neighbor_damaged := false
		for entity in session.simulation.snapshot()["entities"]:
			var components: Dictionary = entity["components"]
			if components.get("EnemyType", "") != "chaser":
				continue
			if entity.get("id", {}) == target_id:
				neighbor_damaged = is_equal_approx(float(components["Health"]["current"]), expected_health)
		if neighbor_damaged and session.kill_count == 1 and _xp_orb_count(session) == 1:
			return true
	return false

func _xp_orb_count(session: Node2D) -> int:
	var count := 0
	for entity in session.simulation.snapshot()["entities"]:
		if entity["components"].get("IsXpOrb", false):
			count += 1
	return count

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
