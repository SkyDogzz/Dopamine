extends SceneTree

const LOADOUT_SCRIPT := preload("res://scripts/survival_loadout.gd")
const DEFAULT_OUTPUT := "user://sandbox/logs/latest_weapon_scenario.json"
const MAX_SCENARIO_BYTES := 65_536
const WEAPON_RELICS := {
	"lightning_conductor": "storm_core",
	"inferno_sprayer": "infernal_heart",
	"crimson_daggers": "blood_chalice",
	"minigun": "overdrive_engine",
	"toxic_cloud": "plague_mask",
	"sawblades": "magnetic_coil",
	"meteor_staff": "celestial_eye",
	"prism_laser": "prism_crystal",
	"void_orb": "singularity",
	"frost_nova": "frozen_crown",
}
const FIRE_METHODS := {
	"lightning_conductor": "_fire_lightning_conductor",
	"inferno_sprayer": "_fire_inferno_sprayer",
	"crimson_daggers": "_fire_crimson_daggers",
	"minigun": "_fire_minigun",
	"toxic_cloud": "_fire_toxic_cloud",
	"sawblades": "_fire_sawblades",
	"meteor_staff": "_fire_meteor_staff",
	"prism_laser": "_fire_prism_laser",
	"void_orb": "_fire_void_orb",
	"frost_nova": "_fire_frost_nova",
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var options := _parse_options()
	var scenario_path: String = options.get("scenario", "")
	var output_path: String = options.get("output", DEFAULT_OUTPUT)
	var scenario_file := FileAccess.open(scenario_path, FileAccess.READ)
	if scenario_file == null or scenario_file.get_length() > MAX_SCENARIO_BYTES:
		_fail("Cannot open weapon scenario or scenario exceeds 64 KiB: %s" % scenario_path)
		return
	var scenario: Variant = JSON.parse_string(scenario_file.get_as_text())
	var validation_error := _validate_scenario(scenario)
	if not validation_error.is_empty():
		_fail(validation_error)
		return

	var session_scene: PackedScene = load("res://scenes/survival_session.tscn")
	if session_scene == null:
		_fail("Sandbox weapon scenario could not load the Survival session")
		return
	var session: Node2D = session_scene.instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	session.progression_service = null
	root.add_child(session)
	await process_frame
	if session.simulation == null or not session._weapon_progression_valid:
		_fail("Sandbox weapon scenario could not initialize combat without a progression service")
		return
	session.set_process(false)
	session.set_physics_process(false)
	session.progression_service = null
	session.loadout = LOADOUT_SCRIPT.new(1)
	var sequence: int = session.simulation.pause()
	var state: Dictionary = await _wait_for_sequence(session.simulation, sequence)
	if state.is_empty() or not bool(state["paused"]):
		_fail("Weapon scenario simulation did not pause for deterministic setup")
		return

	var weapon_id: String = scenario["weapon_id"]
	var relic_id: String = scenario["relic_id"]
	for _level in range(int(scenario.get("weapon_level", 1))):
		if not session.loadout.apply_offer("weapon:%s" % weapon_id):
			_fail("Sandbox could not equip weapon %s" % weapon_id)
			return
	for _level in range(int(scenario.get("relic_level", 1))):
		if not session.loadout.apply_offer("relic:%s" % relic_id):
			_fail("Sandbox could not equip relic %s" % relic_id)
			return

	for target in scenario["targets"]:
		var position: Array = target["position"]
		sequence = session.simulation.spawn(str(target.get("entity_type", "weapon_scenario_target")), 1,
				Vector2(float(position[0]), float(position[1])), float(target.get("hp", 100.0)),
				Vector2.ZERO, float(target.get("threat_level", 1.0)))
		if sequence <= 0:
			_fail("Sandbox rejected a weapon scenario target")
			return
	state = await _wait_for_sequence(session.simulation, sequence)
	if state.is_empty():
		_fail("Sandbox timed out while spawning weapon scenario targets")
		return
	session._entities = state["entities"]
	var baseline_collisions := int(state["metrics"]["collision_count"])
	var baseline_sequence := int(state["last_sequence"])
	session.weapon_enabled = true
	session.call(FIRE_METHODS[weapon_id], float(state["simulation_time"]), false)
	state = await _wait_for_projectile(session.simulation, baseline_sequence)
	if state.is_empty():
		_fail("Weapon %s did not create a projectile against its fixture" % weapon_id)
		return

	var expected_damage_events := int(scenario.get("expected", {}).get("damage_events", 1))
	for _step in range(int(scenario.get("max_steps", 80))):
		if int(state["metrics"]["collision_count"]) - baseline_collisions >= expected_damage_events:
			break
		sequence = session.simulation.step(float(scenario.get("step_seconds", 0.05)))
		state = await _wait_for_sequence(session.simulation, sequence)
		if state.is_empty():
			_fail("Sandbox timed out while stepping weapon %s" % weapon_id)
			return
	var actual_damage_events := int(state["metrics"]["collision_count"]) - baseline_collisions
	if actual_damage_events < expected_damage_events:
		_fail("Weapon %s produced %d damage events; expected at least %d" % [weapon_id, actual_damage_events, expected_damage_events])
		return
	if session.progression_service != null:
		_fail("Sandbox weapon scenarios must remain detached from permanent progression")
		return

	var result := {
		"schema_version": 1,
		"scenario_id": scenario["scenario_id"],
		"weapon_id": weapon_id,
		"relic_id": relic_id,
		"weapon_level": int(scenario.get("weapon_level", 1)),
		"relic_level": int(scenario.get("relic_level", 1)),
		"progression_service_attached": false,
		"simulation_time": state["simulation_time"],
		"metrics": state["metrics"],
		"entities": state["entities"],
		"combat_events": state["events"],
	}
	var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_path.get_base_dir()))
	if directory_error != OK:
		_fail("Cannot create weapon scenario output directory: %s" % output_path.get_base_dir())
		return
	var output_file := FileAccess.open(output_path, FileAccess.WRITE)
	if output_file == null:
		_fail("Cannot write weapon scenario metrics to: %s" % output_path)
		return
	output_file.store_string(JSON.stringify(result, "\t", true))
	output_file.flush()
	print("Sandbox weapon scenario %s passed; metrics written to %s" % [scenario["scenario_id"], output_path])
	quit()

static func _validate_scenario(scenario: Variant) -> String:
	if typeof(scenario) != TYPE_DICTIONARY or scenario.get("schema_version") != 1:
		return "Weapon scenario requires schema_version 1"
	if typeof(scenario.get("scenario_id")) != TYPE_STRING or String(scenario["scenario_id"]).is_empty():
		return "Weapon scenario requires a non-empty scenario_id"
	var weapon_id: Variant = scenario.get("weapon_id")
	if typeof(weapon_id) != TYPE_STRING or not WEAPON_RELICS.has(weapon_id):
		return "Weapon scenario weapon_id must name one of the ten available weapons"
	if scenario.get("relic_id") != WEAPON_RELICS[weapon_id]:
		return "Weapon scenario relic_id must match the weapon's catalog pair"
	for level_key in ["weapon_level", "relic_level"]:
		var level: Variant = scenario.get(level_key, 1)
		if not _valid_integer(level) or int(level) < 1 or int(level) > 5:
			return "Weapon scenario %s must be between 1 and 5" % level_key
	var targets: Variant = scenario.get("targets")
	if typeof(targets) != TYPE_ARRAY or targets.is_empty() or targets.size() > 32:
		return "Weapon scenario targets must contain between 1 and 32 fixtures"
	for index in range(targets.size()):
		var target: Variant = targets[index]
		if typeof(target) != TYPE_DICTIONARY or not _valid_vector(target.get("position")):
			return "Weapon scenario target %d requires a finite position" % index
		for key in ["hp", "threat_level"]:
			if target.has(key) and (not _valid_number(target[key]) or float(target[key]) <= 0.0):
				return "Weapon scenario target %d %s must be positive and finite" % [index, key]
		if target.has("entity_type") and (typeof(target["entity_type"]) != TYPE_STRING or String(target["entity_type"]).is_empty()):
			return "Weapon scenario target %d entity_type must be a non-empty string" % index
	var expected: Variant = scenario.get("expected", {})
	if typeof(expected) != TYPE_DICTIONARY or not _valid_integer(expected.get("damage_events", 1)) or int(expected.get("damage_events", 1)) < 1:
		return "Weapon scenario expected.damage_events must be a positive integer"
	if not _valid_number(scenario.get("step_seconds", 0.05)) or float(scenario.get("step_seconds", 0.05)) <= 0.0:
		return "Weapon scenario step_seconds must be positive and finite"
	if not _valid_integer(scenario.get("max_steps", 80)) or int(scenario.get("max_steps", 80)) < 1 or int(scenario.get("max_steps", 80)) > 500:
		return "Weapon scenario max_steps must be between 1 and 500"
	return ""

func _parse_options() -> Dictionary:
	var options := {}
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--scenario="):
			options["scenario"] = argument.trim_prefix("--scenario=")
		elif argument.begins_with("--output="):
			options["output"] = argument.trim_prefix("--output=")
	return options

func _wait_for_sequence(simulation: Object, sequence: int) -> Dictionary:
	if sequence <= 0:
		return {}
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		var state: Dictionary = simulation.snapshot()
		if int(state["last_sequence"]) >= sequence:
			return state
		await process_frame
	return {}

func _wait_for_projectile(simulation: Object, after_sequence: int) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		var state: Dictionary = simulation.snapshot()
		if int(state["last_sequence"]) > after_sequence and int(state["metrics"]["projectile_count"]) > 0:
			return state
		await process_frame
	return {}

static func _valid_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))

static func _valid_integer(value: Variant) -> bool:
	return _valid_number(value) and float(value) == floor(float(value))

static func _valid_vector(value: Variant) -> bool:
	return typeof(value) == TYPE_ARRAY and value.size() == 2 and _valid_number(value[0]) and _valid_number(value[1])

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
