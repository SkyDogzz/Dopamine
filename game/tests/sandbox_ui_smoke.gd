extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var sandbox: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(sandbox)
	await process_frame
	assert(sandbox.simulation != null, "Sandbox UI should create its simulation without a save")

	var count_spin: SpinBox = sandbox.get_node("Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/TypeRow/CountSpin")
	count_spin.value = 2
	sandbox.get_node("Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/SpawnButton").pressed.emit()
	var state: Dictionary = await _wait_for_entity_count(sandbox.simulation, 2)
	var id: Dictionary = state["entities"][0]["id"]

	sandbox.get_node("Shell/Content/MainColumn/SimulationView").entity_selected.emit(id["index"], id["generation"])
	sandbox.get_node("Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/DespawnButton").pressed.emit()
	await _wait_for_entity_count(sandbox.simulation, 1)

	sandbox.get_node("Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/KillButton").pressed.emit()
	state = await _wait_for_entity_count(sandbox.simulation, 0)
	assert(state["entities"].is_empty())
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
