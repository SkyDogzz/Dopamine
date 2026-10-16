extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save_directory := ProjectSettings.globalize_path("user://saves")
	assert(DirAccess.make_dir_recursive_absolute(save_directory) == OK, "Sandbox smoke should create its isolated save fixture")
	const slot_path := "user://saves/slot_0.json"
	const sentinel := "{\"schema_version\":1,\"fixture\":\"sandbox-must-preserve-this-slot\"}"
	var slot_file := FileAccess.open(slot_path, FileAccess.WRITE)
	assert(slot_file != null, "Sandbox isolation fixture should be writable")
	slot_file.store_string(sentinel)
	slot_file.close()
	var sandbox: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(sandbox)
	await process_frame
	assert(sandbox.theme == load("res://themes/dopamine_ui.tres"), "Sandbox should use the shared UI theme")
	var metrics: GridContainer = sandbox.get_node("Shell/Content/MainColumn/Metrics/MetricRow")
	assert(metrics.columns == 4, "Sandbox metrics should use four columns")
	var action_pause: Button = sandbox.get_node("Shell/Content/MainColumn/Toolbar/Row/PauseButton")
	var action_step: Button = sandbox.get_node("Shell/Content/MainColumn/Toolbar/Row/StepButton")
	var action_reset: Button = sandbox.get_node("Shell/Content/MainColumn/Toolbar/Row/ResetButton")
	var state_badge: PanelContainer = sandbox.get_node("Shell/Header/StateBadge")
	var state_label: Label = state_badge.get_node("StateLabel")
	assert(state_badge.custom_minimum_size.x >= 140 and state_label.text.contains("NO SAVE"), "Sandbox should group its isolated simulation state in a clear badge")
	assert(sandbox.get_node("Shell/Header/Title").get_theme_font_size("font_size") == 11, "Sandbox title should retain its intended readable heading size")
	assert(action_pause.get_theme_color("font_color").to_html(false) == "37e8f5", "Pause/resume should use the cyan action accent")
	assert(action_step.get_theme_color("font_color").to_html(false) == "ffd447", "Single-step should use the yellow action accent")
	assert(action_reset.get_theme_color("font_color").to_html(false) == "ff7181", "Reset should use the danger accent")
	var side_panel: ScrollContainer = sandbox.get_node("Shell/Content/SidePanel")
	var spawn_actions: HBoxContainer = sandbox.get_node("Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions")
	for viewport_size in [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = viewport_size
		await process_frame
		await process_frame
		var panel_rect := side_panel.get_global_rect()
		for button in spawn_actions.get_children():
			var button_rect := (button as Control).get_global_rect()
			assert(button_rect.position.x >= panel_rect.position.x, "Sandbox spawn actions should stay inside the side panel at %s" % viewport_size)
			assert(button_rect.end.x <= panel_rect.end.x, "Sandbox spawn actions should not overflow at %s" % viewport_size)
		assert(not side_panel.get_h_scroll_bar().visible, "Sandbox side panel should not show a horizontal scrollbar at %s" % viewport_size)
	root.size = Vector2i(1280, 720)
	await process_frame
	assert(sandbox.get_node("Shell/Content/MainColumn/SimulationView").clip_contents,
		"Simulation entities should stay clipped to the playfield")
	assert(sandbox.get_node("Shell/Header/HomeButton").has_focus(), "Sandbox should start with a visible keyboard focus")
	assert(sandbox.get_node("Shell/Header/SurvivalButton").text == "PLAY SURVIVAL", "Sandbox should expose the Survival prototype entry")
	assert(sandbox.simulation != null, "Sandbox UI should create its simulation without a save")
	for node_path in [
		"Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/StatusTitle",
		"Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/StatusDamageSpin",
		"Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/StatusIntervalSpin",
		"Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/StatusDurationSpin",
		"Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/ApplyStatusButton",
		"Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningTitle",
		"Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningGrid/MaxSpeedSpin",
		"Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningGrid/SeparationRadiusSpin",
		"Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningGrid/SeparationWeightSpin",
		"Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningGrid/CellSizeSpin",
		"Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/ApplyTuningButton",
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
		"Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/HealthRow/VelocityRow/VelocityXSpin",
		"Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/HealthRow/VelocityRow/VelocityYSpin",
		"Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/SpawnButton",
		"Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/DespawnButton",
		"Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/KillButton",
	]:
		if sandbox.get_node(node_path).tooltip_text.is_empty():
			_fail("%s should explain itself on hover" % node_path)
			return
	var separation_weight: SpinBox = sandbox.get_node("Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningGrid/SeparationWeightSpin")
	if separation_weight.prefix != "WGT " or not separation_weight.tooltip_text.contains("separation"):
		_fail("Sandbox tuning prefixes should fit their compact fields and retain the full tooltip")
		return

	var count_spin: SpinBox = sandbox.get_node("Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/TypeRow/CountSpin")
	count_spin.value = 2
	sandbox.get_node("Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/PositionRow/XSpin").value = 100.0
	sandbox.get_node("Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/SpawnButton").pressed.emit()
	var state: Dictionary = await _wait_for_entity_count(sandbox.simulation, 2)
	var id: Dictionary = state["entities"][0]["id"]

	sandbox.get_node("Shell/Content/MainColumn/SimulationView").entity_selected.emit(id["index"], id["generation"])
	var status_damage: SpinBox = sandbox.get_node("Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/StatusDamageSpin")
	status_damage.value = 2.0
	var status_interval: SpinBox = sandbox.get_node("Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/StatusIntervalSpin")
	status_interval.value = 0.1
	var status_duration: SpinBox = sandbox.get_node("Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/StatusDurationSpin")
	status_duration.value = 0.3
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
	var state_badge_style := state_badge.get_theme_stylebox("panel") as StyleBoxFlat
	assert(state_label.text == "PAUSED  /  NO SAVE" and state_badge_style.border_color.to_html(false) == "ffd166" and \
		state_badge_style.border_width_left >= 2, "Sandbox paused state should use its amber status badge")
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
	var tuning_form: Control = sandbox.get_node("Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningGrid")
	tuning_form.get_node("MaxSpeedSpin").value = 10.0
	tuning_form.get_node("SeparationRadiusSpin").value = 0.0
	tuning_form.get_node("SeparationWeightSpin").value = 0.0
	tuning_form.get_node("CellSizeSpin").value = 32.0
	var sequence_before_tuning: int = int(state["last_sequence"])
	sandbox.get_node("Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/ApplyTuningButton").pressed.emit()
	state = await _wait_for_sequence(sandbox.simulation, sequence_before_tuning + 1)
	assert(state["sandbox_overrides"] == {
		"max_speed": 10.0,
		"separation_radius": 0.0,
		"separation_weight": 0.0,
		"cell_size": 32.0,
	}, "Sandbox should publish its complete live steering transaction")
	sandbox._refresh()
	assert(sandbox.get_node("Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningStatus").text == "LIVE TUNING APPLIED",
		"Sandbox should report the transaction only after worker acknowledgement")
	var tuning_step_sequence: int = sandbox.simulation.step(0.1)
	state = await _wait_for_sequence(sandbox.simulation, tuning_step_sequence)
	assert(float(state["entities"][0]["components"]["Transform2D"]["x"]) < 100.0,
		"Applied steering should move generic enemies toward the Sandbox world origin")
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
	var reset_tuning: Control = sandbox.get_node("Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningGrid")
	assert(is_equal_approx(reset_tuning.get_node("MaxSpeedSpin").value, 75.0))
	assert(is_equal_approx(reset_tuning.get_node("SeparationRadiusSpin").value, 18.0))
	assert(is_equal_approx(reset_tuning.get_node("SeparationWeightSpin").value, 0.5))
	assert(is_equal_approx(reset_tuning.get_node("CellSizeSpin").value, 64.0))
	assert(sandbox.get_node("Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningStatus").text == "TUNING RESET",
		"Sandbox reset should acknowledge defaults and refresh the live tuning controls")
	assert(dps_label.text == "AVG DPS  0.0", "Sandbox reset should clear accumulated damage")
	assert(FileAccess.get_file_as_string(slot_path) == sentinel,
		"Sandbox interactions should leave normal progress save bytes unchanged")
	var saved_files := DirAccess.get_files_at(save_directory)
	assert(saved_files.size() == 1 and saved_files[0] == "slot_0.json",
		"Sandbox interactions should not add files to normal progression slots")
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

func _wait_for_sequence(simulation: Object, expected_sequence: int) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 1000
	var state: Dictionary = simulation.snapshot()
	while int(state["last_sequence"]) < expected_sequence and Time.get_ticks_msec() < deadline:
		await process_frame
		state = simulation.snapshot()
	assert(int(state["last_sequence"]) >= expected_sequence, "Sandbox command timed out")
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
