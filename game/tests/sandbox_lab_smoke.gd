extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var lab: Control = load("res://scenes/sandbox_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	if lab.context == null or lab.context.simulation == null or \
			lab.context.progression_service != null or lab.context.normal_save_service != null:
		_fail("The player Sandbox Lab should start without progression or save services")
		return
	if lab.context.session.loadout.weapon_level("lightning_conductor") != 1 or \
			lab.context.session.loadout.relic_level("storm_core") != 1:
		_fail("The default Lab preset build should be applied to the real combat loadout")
		return
	var god_mode: CheckButton = lab.get_node("Root/Body/Side/Sections/GodModeToggle")
	if not lab.context.session._health_locked:
		_fail("Sandbox Lab should begin with its isolated god mode enabled")
		return
	god_mode.button_pressed = false
	if lab.context.session._health_locked:
		_fail("Sandbox Lab god mode should toggle only its isolated player damage lock")
		return
	god_mode.button_pressed = true
	var directory := ProjectSettings.globalize_path("user://sandbox_lab_smoke/presets")
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	lab.preset_store = load("res://scripts/sandbox_preset_store.gd").new(directory, lab.preset_service)
	lab.get_node("Root/Body/Side/Sections/PresetId").text = "smoke_build"
	lab._save_preset()
	if not lab.preset_store.load_preset("smoke_build").get("ok", false):
		_fail("The Lab UI should save a valid preset in the isolated Sandbox store")
		return
	lab.context.simulation.pause()
	if not await _wait_for_pause(lab.context.simulation, true):
		_fail("The Lab simulation should pause before deterministic spawn checks")
		return
	lab.get_node("Root/Body/Left/Controls/SpawnButton").pressed.emit()
	if not await _wait_for_entities(lab.context.simulation, 10):
		_fail("The Lab spawn control should add enemies to its native simulation")
		return
	lab.context.simulation.resume()
	if not await _wait_for_projectiles(lab.context.simulation):
		_fail("The applied weapon build should fire through the Survival combat implementation")
		return
	lab.get_node("Root/Body/Left/Controls/ResetButton").pressed.emit()
	if not await _wait_for_empty_simulation(lab.context) or \
			lab.context.session.loadout.weapon_level("lightning_conductor") != 1 or \
			lab.get_node("Root/Body/Side/Sections/Status").text != "LAB RESET FROM PRESET":
		_fail("Reset should rebuild cleanly; count=%d weapon=%d status=%s paused=%s" % [
			int(lab.context.simulation.snapshot()["metrics"]["entity_count"]),
			lab.context.session.loadout.weapon_level("lightning_conductor"),
			lab.get_node("Root/Body/Side/Sections/Status").text,
			str(lab.context.simulation.snapshot()["paused"]),
		])
		return
	var normal_saves := ProjectSettings.globalize_path("user://saves")
	if DirAccess.dir_exists_absolute(normal_saves) and not DirAccess.get_files_at(normal_saves).is_empty():
		_fail("The Lab smoke should not create or modify normal save slots")
		return
	lab.context.stop()
	lab.queue_free()
	await process_frame
	print("Sandbox Lab smoke passed isolated startup, preset save and native spawn")
	quit()

func _wait_for_entities(simulation: Object, expected_count: int) -> bool:
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if int(simulation.snapshot()["metrics"]["entity_count"]) >= expected_count:
			return true
	return false

func _wait_for_projectiles(simulation: Object) -> bool:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if int(simulation.snapshot()["metrics"]["projectile_count"]) > 0:
			return true
	return false

func _wait_for_empty_simulation(context: Node) -> bool:
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if int(context.simulation.snapshot()["metrics"]["entity_count"]) == 0:
			return true
	return false

func _wait_for_pause(simulation: Object, expected: bool) -> bool:
	var deadline := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if bool(simulation.snapshot()["paused"]) == expected:
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
