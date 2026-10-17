extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var simulation = ClassDB.instantiate("CombatSimulation")
	if simulation == null or not simulation.has_method("capture_state") or \
			not simulation.has_method("restore_state"):
		_fail("CombatSimulation should expose state capture and restoration to Sandbox Lab")
		return
	var sequence: int = simulation.spawn_enemy("chaser", 1, Vector2(40, 25), Vector2.ZERO)
	if sequence <= 0 or not await _wait_for_sequence(simulation, sequence):
		_fail("The snapshot fixture should create a real native enemy")
		return
	simulation.pause()
	if not await _wait_until(func() -> bool: return bool(simulation.snapshot().get("paused", false))):
		_fail("The snapshot fixture should pause before capture")
		return
	var captured: Dictionary = simulation.capture_state()
	if captured.get("format_version") != 17 or captured.get("native_state") == null or \
			not captured["native_state"].is_valid():
		_fail("A native snapshot should expose its supported format and captured state")
		return
	sequence = simulation.kill_all()
	if sequence <= 0 or not await _wait_for_sequence(simulation, sequence) or \
			int(simulation.snapshot()["metrics"]["entity_count"]) != 0:
		_fail("The test should change the live simulation after capture")
		return
	if not simulation.restore_state(captured) or not await _wait_until(func() -> bool:
		return int(simulation.snapshot()["metrics"]["entity_count"]) == 1
	):
		_fail("Restoring a captured snapshot should recover the enemy and paused worker state")
		return
	var restored: Dictionary = simulation.snapshot()
	if not bool(restored["paused"]) or restored["entities"].size() != 1 or \
			str(restored["entities"][0]["components"]["EnemyType"]) != "chaser":
		_fail("Restoration should preserve the captured simulation state")
		return
	var incompatible: Dictionary = captured.duplicate()
	incompatible["format_version"] = 16
	if simulation.restore_state(incompatible):
		_fail("Restoration should reject an incompatible snapshot version")
		return
	var after_rejection: Dictionary = simulation.snapshot()
	if int(after_rejection["metrics"]["entity_count"]) != 1 or \
			float(after_rejection["simulation_time"]) != float(restored["simulation_time"]):
		_fail("Rejecting an incompatible snapshot must leave the live simulation unchanged")
		return
	quit(0)

func _wait_for_sequence(simulation: Object, sequence: int) -> bool:
	return await _wait_until(func() -> bool:
		return int(simulation.snapshot().get("last_sequence", 0)) >= sequence
	)

func _wait_until(predicate: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if predicate.call():
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
