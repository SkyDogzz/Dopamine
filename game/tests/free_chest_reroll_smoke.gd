extends SceneTree

const TEST_DIRECTORY := "user://free_chest_reroll_smoke"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var save_service = load("res://scripts/save_service.gd").new(directory)
	var progression = load("res://scripts/progression_service.gd").new(save_service, "0")
	var profile: Dictionary = progression.load_profile()["profile"]
	var equipment: Dictionary = load("res://scripts/equipment_generator.gd").new(51).generate_survival_item("reroll")
	equipment["rarity"] = "legendary"
	equipment["stat_lines"] = [
		{"stat_id": "damage_pct", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0},
		{"stat_id": "max_hp", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0},
		{"stat_id": "move_speed_pct", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0},
	]
	equipment["unique_effect_id"] = "free_first_chest_reroll"
	equipment["equipped"] = true
	profile["equipment_inventory"] = [equipment]
	if not save_service.save_slot("0", profile):
		_fail("Could not save the equipped free chest reroll fixture")
		return
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.progression_service = progression
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	root.add_child(session)
	if not await _wait_until(func() -> bool: return not session.simulation.snapshot()["paused"]):
		_fail("Reroll fixture Survival session should start")
		return
	if not session.open_chest_family("weapon"):
		_fail("Weapon chest should open before testing its reroll")
		return
	if not await _wait_until(func() -> bool: return session.simulation.snapshot()["paused"]):
		_fail("The chest should keep the simulation paused while rerolling")
		return
	var initial_options: Array = session._active_chest_options.duplicate(true)
	var initial_ids := _ids(initial_options)
	var reroll_button: Button = session.get_node("HUD/ChestOverlay/ChestChoice/Content/Reroll")
	if not reroll_button.visible or reroll_button.focus_mode != Control.FOCUS_ALL:
		_fail("An equipped free reroll effect should expose the control on the first reward chest")
		return
	reroll_button.grab_focus()
	var accept := InputEventKey.new()
	accept.keycode = KEY_ENTER
	accept.pressed = true
	session.get_node("HUD/ChestOverlay/ChestChoice")._input(accept)
	var rerolled_ids := _ids(session._active_chest_options)
	if not session._chest_open or not session._free_first_chest_reroll_used or \
		reroll_button.visible or rerolled_ids.size() != initial_ids.size():
		_fail("A free reroll should replace the open chest options once without resuming the run")
		return
	for option_id in rerolled_ids:
		if initial_ids.has(option_id):
			_fail("A rerolled chest must not repeat an option already shown")
			return
	session._on_chest_option_selected(rerolled_ids[0])
	if session._chest_open or not session.open_chest_family("weapon"):
		_fail("Choosing a rerolled option should resume the run and allow a later chest")
		return
	reroll_button = session.get_node("HUD/ChestOverlay/ChestChoice/Content/Reroll")
	if reroll_button.visible:
		_fail("The effect should only reroll the first reward chest in a run")
		return
	session.queue_free()
	await process_frame
	print("Free first chest reroll smoke passed")
	quit()

func _ids(options: Array) -> Array[String]:
	var result: Array[String] = []
	for option in options:
		result.append(str(option.get("id", "")))
	return result

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
