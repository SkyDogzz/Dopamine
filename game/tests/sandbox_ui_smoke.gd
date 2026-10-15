extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var sandbox: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(sandbox)
	await process_frame
	assert(sandbox.get_node("Shell/Header/SurvivalButton").text == "PLAY SURVIVAL", "Sandbox should expose the Survival prototype entry")
	assert(sandbox.simulation != null, "Sandbox UI should create its simulation without a save")
	for node_path in [
		"Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/StatusTitle",
		"Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/StatusDamageSpin",
		"Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/StatusIntervalSpin",
		"Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/StatusDurationSpin",
		"Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/ApplyStatusButton",
	]:
		if sandbox.get_node(node_path).tooltip_text.is_empty():
			_fail("%s should explain itself on hover" % node_path)
			return
	for node_path in [
		"Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnTitle",
		"Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/TypeRow/EntityType",
		"Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/TypeRow/CountSpin",
		"Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/PositionRow/XSpin",
		"Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/PositionRow/YSpin",
		"Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/HealthRow/HealthSpin",
		"Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/HealthRow/VelocityXSpin",
		"Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/HealthRow/VelocityYSpin",
		"Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/SpawnButton",
		"Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/DespawnButton",
		"Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/KillButton",
	]:
		if sandbox.get_node(node_path).tooltip_text.is_empty():
			_fail("%s should explain itself on hover" % node_path)
			return

	var count_spin: SpinBox = sandbox.get_node("Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/TypeRow/CountSpin")
	count_spin.value = 2
	sandbox.get_node("Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/SpawnButton").pressed.emit()
	var state: Dictionary = await _wait_for_entity_count(sandbox.simulation, 2)
	var id: Dictionary = state["entities"][0]["id"]

	sandbox.get_node("Shell/Content/MainColumn/SimulationView").entity_selected.emit(id["index"], id["generation"])
	var status_damage: SpinBox = sandbox.get_node("Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/StatusDamageSpin")
	status_damage.value = 2.0
	var status_interval: SpinBox = sandbox.get_node("Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/StatusIntervalSpin")
	status_interval.value = 0.1
	var status_duration: SpinBox = sandbox.get_node("Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/StatusDurationSpin")
	status_duration.value = 0.2
	sandbox.get_node("Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/ApplyStatusButton").pressed.emit()
	state = await _wait_for_status(sandbox.simulation, id["index"])
	assert(state["entities"][0]["components"].has("DamageOverTime"), "Sandbox should apply a status to the selected entity")
	assert(sandbox.get_node("Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/EntityInfo").text.contains("DAMAGE OVER TIME"), "Inspector should display active status")
	sandbox.simulation.step(0.2)
	state = await _wait_for_damage(sandbox.simulation)
	assert(state["events"][0]["is_damage_over_time"], "Status damage events should be identified")
	var expected_damage := 0.0
	for event in state["events"]:
		if event["type"] == "damage":
			expected_damage += float(event["amount"])
	sandbox._refresh()
	var dps_label: Label = sandbox.get_node("Shell/Content/MainColumn/Metrics/MetricRow/MetricDPS")
	var expected_dps := expected_damage / float(state["simulation_time"])
	assert(dps_label.text == "AVG DPS  %.1f" % expected_dps, "Sandbox DPS should use damage events divided by simulated time")
	var pause_button: Button = sandbox.get_node("Shell/Content/MainColumn/Toolbar/Row/PauseButton")
	pause_button.pressed.emit()
	state = await _wait_for_paused(sandbox.simulation, false)
	assert(not state["paused"], "Sandbox UI should resume the simulation")
	pause_button.pressed.emit()
	state = await _wait_for_paused(sandbox.simulation, true)
	assert(state["paused"], "Sandbox UI should pause the simulation")
	sandbox._refresh()
	state = sandbox.simulation.snapshot()
	var time_before_step := float(state["simulation_time"])
	var speed_select: OptionButton = sandbox.get_node("Shell/Content/MainColumn/Toolbar/Row/SpeedSelect")
	speed_select.item_selected.emit(3)
	var duration: SpinBox = sandbox.get_node("Shell/Content/MainColumn/Toolbar/Row/StepDuration")
	duration.value = 0.1
	sandbox.get_node("Shell/Content/MainColumn/Toolbar/Row/StepButton").pressed.emit()
	state = await _wait_for_simulation_time(sandbox.simulation, time_before_step + 0.2)
	assert(is_equal_approx(float(state["speed_multiplier"]), 2.0), "Sandbox UI should apply the selected speed")
	assert(is_equal_approx(float(state["simulation_time"]), time_before_step + 0.2), "Sandbox UI Step should advance its explicit duration at selected speed")
	sandbox.get_node("Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/DespawnButton").pressed.emit()
	await _wait_for_entity_count(sandbox.simulation, 1)

	sandbox.get_node("Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/KillButton").pressed.emit()
	state = await _wait_for_entity_count(sandbox.simulation, 0)
	assert(state["entities"].is_empty())
	sandbox.get_node("Shell/Content/MainColumn/Toolbar/Row/ResetButton").pressed.emit()
	var reset_deadline := Time.get_ticks_msec() + 1000
	state = sandbox.simulation.snapshot()
	while state["simulation_time"] > 0.0 and Time.get_ticks_msec() < reset_deadline:
		await process_frame
		state = sandbox.simulation.snapshot()
	assert(state["simulation_time"] == 0.0, "Sandbox reset should restart simulated time")
	sandbox._refresh()
	assert(dps_label.text == "AVG DPS  0.0", "Sandbox reset should clear accumulated damage")
	print("Sandbox UI spawn, inspect, despawn and kill-all checks passed")
	quit()

func _wait_for_entity_count(simulation: Object, expected_count: int) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 1000
	var state: Dictionary = simulation.snapshot()
	while state["entities"].size() != expected_count and Time.get_ticks_msec() < deadline:
		await process_frame
		state = simulation.snapshot()
	assert(state["entities"].size() == expected_count, "Sandbox UI command timed out")
	return state

func _wait_for_status(simulation: Object, entity_index: int) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 1000
	var state: Dictionary = simulation.snapshot()
	while Time.get_ticks_msec() < deadline:
		for entity in state["entities"]:
			if entity["id"]["index"] == entity_index and entity["components"].has("DamageOverTime"):
				return state
		await process_frame
		state = simulation.snapshot()
	_fail("Sandbox status command timed out")
	return state

func _wait_for_damage(simulation: Object) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 1000
	var state: Dictionary = simulation.snapshot()
	while Time.get_ticks_msec() < deadline:
		if not state["events"].is_empty():
			return state
		await process_frame
		state = simulation.snapshot()
	_fail("Sandbox status tick timed out")
	return state

func _wait_for_paused(simulation: Object, expected_paused: bool) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 1000
	var state: Dictionary = simulation.snapshot()
	while state["paused"] != expected_paused and Time.get_ticks_msec() < deadline:
		await process_frame
		state = simulation.snapshot()
	assert(state["paused"] == expected_paused, "Sandbox pause command timed out")
	return state

func _wait_for_simulation_time(simulation: Object, expected_time: float) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 1000
	var state: Dictionary = simulation.snapshot()
	while not is_equal_approx(float(state["simulation_time"]), expected_time) and Time.get_ticks_msec() < deadline:
		await process_frame
		state = simulation.snapshot()
	assert(is_equal_approx(float(state["simulation_time"]), expected_time), "Sandbox Step timed out")
	return state

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
