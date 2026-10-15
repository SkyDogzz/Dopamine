extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var sandbox: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(sandbox)
	await process_frame
	var simulation: Object = sandbox.simulation
	assert(simulation != null, "Combat Sandbox should create its simulation without a save")

	var target_sequence: int = simulation.spawn("chaser", 1, Vector2(50, -100), 10.0, Vector2(0, 1000))
	var state: Dictionary = await _wait_for_sequence(simulation, target_sequence)
	assert(state["metrics"]["entity_count"] == 1)
	var projectile_sequence: int = simulation.spawn_projectile(
		"smoke_bolt", Vector2.ZERO, Vector2(500, 0), 12.0, 2.0, 1.0
	)
	state = await _wait_for_sequence(simulation, projectile_sequence)
	assert(state["metrics"]["projectile_count"] == 1)
	var step_sequence: int = simulation.step(0.2)
	state = await _wait_for_events(simulation, step_sequence)
	assert(state["events"].size() == 2, "lethal swept hit should expose damage and death events")
	assert(state["metrics"]["collision_count"] == 1)
	var death_event: Dictionary = state["events"][1]
	assert(death_event["type"] == "death" and is_equal_approx(death_event["threat_level"], 1.0))
	assert(is_equal_approx(simulation.kill_heal_amount(death_event["threat_level"]), 5.0),
			"death threat should be available to the proposed kill heal rule")

	var log_label: RichTextLabel = sandbox.get_node("Shell/Content/SidePanel/Sections/LogPanel/LogForm/LogText")
	state = await _wait_for_event_ack(simulation)
	assert(state["events"].is_empty(), "Sandbox UI should acknowledge consumed events")
	assert(log_label.text.contains("DAMAGE"), "Sandbox UI should display damage events")
	assert(log_label.text.contains("DEATH"), "Sandbox UI should display death events")
	print("Sandbox combat projectile, event display and acknowledgement checks passed")
	if "--stay-open" in OS.get_cmdline_user_args():
		print("Combat result is on screen; press Escape to close the window")
		while not Input.is_key_pressed(KEY_ESCAPE):
			await process_frame
	else:
		quit()

func _wait_for_sequence(simulation: Object, sequence: int) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 1000
	var state: Dictionary = simulation.snapshot()
	while state["last_sequence"] < sequence and Time.get_ticks_msec() < deadline:
		await process_frame
		state = simulation.snapshot()
	assert(state["last_sequence"] >= sequence, "Sandbox command timed out")
	return state

func _wait_for_events(simulation: Object, sequence: int) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 1000
	var state: Dictionary = simulation.snapshot()
	while (state["last_sequence"] < sequence or state["events"].size() < 2) and Time.get_ticks_msec() < deadline:
		await process_frame
		state = simulation.snapshot()
	assert(state["last_sequence"] >= sequence and state["events"].size() == 2,
			"combat event publication timed out")
	return state

func _wait_for_event_ack(simulation: Object) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 1000
	var state: Dictionary = simulation.snapshot()
	while not state["events"].is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
		state = simulation.snapshot()
	assert(state["events"].is_empty(), "combat event acknowledgement timed out")
	return state
