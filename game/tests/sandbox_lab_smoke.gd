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
	lab.get_node("Root/Body/Left/Controls/SpawnButton").pressed.emit()
	if not await _wait_for_entities(lab.context.simulation, 10):
		_fail("The Lab spawn control should add enemies to its native simulation")
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

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
