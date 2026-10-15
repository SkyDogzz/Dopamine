extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var simulation = ClassDB.instantiate("CombatSimulation")
	if simulation == null:
		_fail("CombatSimulation GDExtension class should be available")
		return
	var shield_sequence: int = simulation.spawn_enemy("shielder", 1, Vector2.ZERO, Vector2.ZERO)
	var ally_sequence: int = simulation.spawn_enemy("chaser", 1, Vector2(50.0, 0.0), Vector2.ZERO)
	var distant_sequence: int = simulation.spawn_enemy("chaser", 1, Vector2(190.0, 0.0), Vector2.ZERO)
	var target_sequence: int = simulation.set_steering_target(Vector2(500.0, 0.0), 75.0, 0.0, 0.0)
	var resume_sequence: int = simulation.resume()
	if shield_sequence <= 0 or ally_sequence <= 0 or distant_sequence <= 0 or target_sequence <= 0 or resume_sequence <= 0:
		_fail("Shielder and ally setup commands should be accepted")
		return
	if not await _wait_until(func() -> bool: return _has_expected_shield_state(simulation.snapshot()["entities"])):
		_fail("Only allies within the Shielder's radius should expose Shielded=true: %s" % [simulation.snapshot()["entities"]])
		return
	var renderer: RefCounted = load("res://scripts/sprite_batch_renderer.gd").new()
	renderer.set_entities(simulation.snapshot()["entities"])
	if renderer._batches["enemy_shielder"]["texture"] == null or \
			renderer.multimesh_for("enemy_shielder").instance_count != 1:
		_fail("Shielder should render its dedicated visible sprite")
		return
	simulation.pause()
	print("Survival Shielder smoke passed")
	quit()

func _wait_until(predicate: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if predicate.call():
			return true
	return false

func _has_expected_shield_state(entities: Array) -> bool:
	var shield_has_profile := false
	var nearby_shielded := false
	var far_unshielded := false
	for entity in entities:
		var components: Dictionary = entity["components"]
		match int(entity["id"]["index"]):
			0:
				shield_has_profile = components.get("EnemyType", "") == "shielder" and \
						is_equal_approx(float(components.get("ShieldRadius", 0.0)), 150.0) and \
						is_equal_approx(float(components.get("ShieldDamageMultiplier", 1.0)), 0.65)
			1:
				nearby_shielded = bool(components.get("Shielded", false))
			2:
				far_unshielded = not bool(components.get("Shielded", false))
	return shield_has_profile and nearby_shielded and far_unshielded

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
