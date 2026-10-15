extends SceneTree

const DEFAULT_SCENARIO := "res://scenarios/dev_sandbox.json"
const DEFAULT_OUTPUT := "user://sandbox/logs/latest_scenario.json"
const MAX_SCENARIO_BYTES := 1_048_576
const MAX_COMMANDS := 1000

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var options := _parse_options()
	var scenario_path: String = options.get("scenario", DEFAULT_SCENARIO)
	var output_path: String = options.get("output", DEFAULT_OUTPUT)
	var scenario_file := FileAccess.open(scenario_path, FileAccess.READ)
	if scenario_file == null:
		_fail("Cannot open scenario: %s" % scenario_path)
		return
	if scenario_file.get_length() > MAX_SCENARIO_BYTES:
		_fail("Scenario exceeds the 1 MiB size limit")
		return
	var scenario: Variant = JSON.parse_string(scenario_file.get_as_text())
	var validation_error := _validate_scenario(scenario)
	if not validation_error.is_empty():
		_fail(validation_error)
		return

	var simulation = ClassDB.instantiate("CombatSimulation")
	if simulation == null:
		_fail("CombatSimulation GDExtension class is unavailable")
		return
	var state: Dictionary = simulation.snapshot()
	for command in scenario["commands"]:
		var sequence: int = _submit(simulation, command)
		if sequence <= 0:
			_fail("Simulation rejected command %d (%s)" % [state["last_sequence"] + 1, command["type"]])
			return
		state = await _wait_for_sequence(simulation, sequence)
		if state.is_empty():
			_fail("Timed out waiting for command %d" % sequence)
			return
	var expectation_error := _check_expected(scenario.get("expected", {}), state)
	if not expectation_error.is_empty():
		_fail(expectation_error)
		return

	var result := {
		"schema_version": 1,
		"scenario_id": scenario["scenario_id"],
		"godot_version": Engine.get_version_info()["string"],
		"completed_at_utc": Time.get_datetime_string_from_system(true),
		"simulation_time": state["simulation_time"],
		"metrics": state["metrics"],
		"entities": state["entities"],
		"logs": Array(state["logs"]),
	}
	var output_directory := ProjectSettings.globalize_path(output_path.get_base_dir())
	var directory_error := DirAccess.make_dir_recursive_absolute(output_directory)
	if directory_error != OK:
		_fail("Cannot create output directory: %s" % output_directory)
		return
	var output_file := FileAccess.open(output_path, FileAccess.WRITE)
	if output_file == null:
		_fail("Cannot write metrics to: %s" % output_path)
		return
	output_file.store_string(JSON.stringify(result, "\t", true))
	output_file.flush()
	print("Scenario %s complete; metrics written to %s" % [scenario["scenario_id"], output_path])
	quit()

func _parse_options() -> Dictionary:
	var options := {}
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--scenario="):
			options["scenario"] = argument.trim_prefix("--scenario=")
		elif argument.begins_with("--output="):
			options["output"] = argument.trim_prefix("--output=")
	return options

func _validate_scenario(scenario: Variant) -> String:
	if typeof(scenario) != TYPE_DICTIONARY:
		return "Scenario root must be a JSON object"
	if scenario.get("schema_version") != 1:
		return "Unsupported scenario schema_version"
	if typeof(scenario.get("scenario_id")) != TYPE_STRING or String(scenario["scenario_id"]).is_empty():
		return "Scenario requires a non-empty scenario_id"
	var commands: Variant = scenario.get("commands")
	if typeof(commands) != TYPE_ARRAY or commands.size() > MAX_COMMANDS:
		return "Scenario commands must be an array of at most %d entries" % MAX_COMMANDS
	if scenario.has("expected") and typeof(scenario["expected"]) != TYPE_DICTIONARY:
		return "Scenario expected must be a JSON object"
	for index in range(commands.size()):
		var command: Variant = commands[index]
		if typeof(command) != TYPE_DICTIONARY:
			return "Command %d must be a JSON object" % index
		if typeof(command.get("type")) != TYPE_STRING:
			return "Command %d requires a string type" % index
		var kind: String = command["type"]
		match kind:
			"spawn":
				if typeof(command.get("entity_type")) != TYPE_STRING or String(command["entity_type"]).is_empty():
					return "Command %d requires entity_type" % index
				if not _valid_integer(command.get("count", 1)) or int(command.get("count", 1)) < 1 or int(command.get("count", 1)) > 500:
					return "Command %d count must be between 1 and 500" % index
				if not _valid_vector(command.get("position", [0, 0])) or not _valid_vector(command.get("velocity", [0, 0])):
					return "Command %d position and velocity must be finite 2-number arrays" % index
				if not _valid_number(command.get("hp", 1)) or float(command.get("hp", 1)) <= 0.0:
					return "Command %d hp must be a positive finite number" % index
			"despawn":
				if not _valid_id(command.get("index")) or not _valid_id(command.get("generation")) or int(command["generation"]) == 0:
					return "Command %d requires a valid entity index and generation" % index
			"step":
				if not _valid_number(command.get("delta_seconds")) or float(command["delta_seconds"]) <= 0.0:
					return "Command %d step duration must be positive and finite" % index
			"set_speed":
				if not _valid_number(command.get("multiplier")) or float(command["multiplier"]) < 0.25 or float(command["multiplier"]) > 4.0:
					return "Command %d speed must be between 0.25 and 4.0" % index
			"set_steering_target":
				if not _valid_vector(command.get("position")):
					return "Command %d steering target position must be a finite 2-number array" % index
				if not _valid_number(command.get("max_speed", 75)) or float(command.get("max_speed", 75)) < 0.0:
					return "Command %d max_speed must be a non-negative finite number" % index
				if not _valid_number(command.get("separation_radius", 18)) or float(command.get("separation_radius", 18)) < 0.0:
					return "Command %d separation_radius must be a non-negative finite number" % index
				if not _valid_number(command.get("separation_weight", 0.5)) or float(command.get("separation_weight", 0.5)) < 0.0 or float(command.get("separation_weight", 0.5)) > 1.0:
					return "Command %d separation_weight must be between 0 and 1" % index
			"kill_all", "pause", "resume", "reset":
				pass
			_:
				return "Command %d has unsupported type: %s" % [index, kind]
	return ""

func _check_expected(expected: Dictionary, state: Dictionary) -> String:
	if expected.has("simulation_time"):
		if not _valid_number(expected["simulation_time"]) or not is_equal_approx(float(expected["simulation_time"]), float(state["simulation_time"])):
			return "Scenario simulation_time did not match expected value"
	if expected.has("speed_multiplier"):
		if not _valid_number(expected["speed_multiplier"]) or not is_equal_approx(float(expected["speed_multiplier"]), float(state["speed_multiplier"])):
			return "Scenario speed_multiplier did not match expected value"
	if expected.has("entity_count"):
		if not _valid_integer(expected["entity_count"]) or int(expected["entity_count"]) != state["metrics"]["entity_count"]:
			return "Scenario entity_count did not match expected value"
	if expected.has("paused") and (typeof(expected["paused"]) != TYPE_BOOL or expected["paused"] != state["paused"]):
		return "Scenario paused state did not match expected value"
	if expected.has("entity_positions"):
		if typeof(expected["entity_positions"]) != TYPE_ARRAY or expected["entity_positions"].size() != state["entities"].size():
			return "Scenario entity_positions must match the snapshot entity count"
		for index in range(expected["entity_positions"].size()):
			var position: Variant = expected["entity_positions"][index]
			if not _valid_vector(position):
				return "Scenario entity_positions[%d] must be a finite 2-number array" % index
			var transform: Dictionary = state["entities"][index]["components"]["Transform2D"]
			if not is_equal_approx(float(position[0]), float(transform["x"])) or not is_equal_approx(float(position[1]), float(transform["y"])):
				return "Scenario entity position %d did not match expected value" % index
	return ""

func _valid_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))

func _valid_integer(value: Variant) -> bool:
	return _valid_number(value) and float(value) == floor(float(value))

func _valid_vector(value: Variant) -> bool:
	return typeof(value) == TYPE_ARRAY and value.size() == 2 and _valid_number(value[0]) and _valid_number(value[1])

func _valid_id(value: Variant) -> bool:
	return _valid_integer(value) and int(value) >= 0 and int(value) <= 4294967295

func _submit(simulation: Object, command: Dictionary) -> int:
	match command["type"]:
		"spawn":
			var position: Array = command.get("position", [0, 0])
			var velocity: Array = command.get("velocity", [0, 0])
			return simulation.spawn(
				command["entity_type"], int(command.get("count", 1)),
				Vector2(float(position[0]), float(position[1])), float(command.get("hp", 1)),
				Vector2(float(velocity[0]), float(velocity[1]))
			)
		"despawn":
			return simulation.despawn(int(command["index"]), int(command["generation"]))
		"kill_all":
			return simulation.kill_all()
		"pause":
			return simulation.pause()
		"resume":
			return simulation.resume()
		"step":
			return simulation.step(float(command["delta_seconds"]))
		"set_speed":
			return simulation.set_speed(float(command["multiplier"]))
		"set_steering_target":
			var position: Array = command["position"]
			return simulation.set_steering_target(
				Vector2(float(position[0]), float(position[1])),
				float(command.get("max_speed", 75)),
				float(command.get("separation_radius", 18)),
				float(command.get("separation_weight", 0.5))
			)
		"reset":
			return simulation.reset()
	return 0

func _wait_for_sequence(simulation: Object, sequence: int) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 2000
	var state: Dictionary = simulation.snapshot()
	while state["last_sequence"] < sequence and Time.get_ticks_msec() < deadline:
		await process_frame
		state = simulation.snapshot()
	return state if state["last_sequence"] >= sequence else {}

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
