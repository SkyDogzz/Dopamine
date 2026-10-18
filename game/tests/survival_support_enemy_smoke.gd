extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var simulation = ClassDB.instantiate("CombatSimulation")
	if simulation == null:
		_fail("CombatSimulation GDExtension class should be available")
		return
	simulation.spawn_enemy("buffer", 1, Vector2.ZERO, Vector2.ZERO)
	simulation.spawn_enemy("chaser", 1, Vector2(80.0, 0.0), Vector2.ZERO)
	simulation.spawn_enemy("chaser", 1, Vector2(180.0, 0.0), Vector2.ZERO)
	simulation.set_steering_target(Vector2(500.0, 0.0), 75.0, 0.0, 0.0)
	var step_sequence: int = simulation.step(0.1)
	if not await _wait_until(func() -> bool:
		return int(simulation.snapshot()["last_sequence"]) >= step_sequence
	):
		_fail("Support scenario step should be applied")
		return
	var components_by_type := {}
	for entity in simulation.snapshot()["entities"]:
		var components: Dictionary = entity["components"]
		var kind := str(components["EnemyType"])
		if kind == "buffer":
			components_by_type["buffer"] = components
		elif not components_by_type.has("nearby"):
			components_by_type["nearby"] = components
		else:
			components_by_type["distant"] = components
	if not components_by_type.has_all(["buffer", "nearby", "distant"]):
		_fail("Buffer and both test allies should appear in the snapshot")
		return
	var buffer: Dictionary = components_by_type["buffer"]
	var nearby: Dictionary = components_by_type["nearby"]
	var distant: Dictionary = components_by_type["distant"]
	var nearby_velocity: Dictionary = nearby["Velocity2D"]
	var distant_velocity: Dictionary = distant["Velocity2D"]
	var renderer: RefCounted = load("res://scripts/sprite_batch_renderer.gd").new()
	renderer.set_entities(simulation.snapshot()["entities"])
	if not is_equal_approx(float(buffer["SupportRadius"]), 150.0) or \
			not bool(nearby["Supported"]) or bool(distant["Supported"]) or \
			not is_equal_approx(float(nearby_velocity["x"]), 90.0) or \
			not is_equal_approx(float(distant_velocity["x"]), 75.0) or \
			renderer._batches["enemy_buffer"]["texture"] == null or \
			renderer.animated_instance_count_for_role("enemy_buffer") != 1:
		_fail("Only enemies inside the visible Buffer aura should receive its speed bonus")
		return
	print("Survival support enemy smoke passed")
	quit()

func _wait_until(predicate: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if predicate.call():
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
