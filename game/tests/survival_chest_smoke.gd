extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	if not session.has_method("open_chest_family"):
		_fail("Survival session script should load")
		return
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	session.ordinary_chest_drop_chance = 1.0
	session.chest_collection_radius = 100.0
	session.xp_collection_radius = 0.0
	root.add_child(session)
	await process_frame
	session.player_hp = 1000.0
	session.simulation.set_speed(4.0)
	if session.simulation.spawn_enemy("chaser", 1, Vector2(20.0, 0.0), Vector2.ZERO) <= 0:
		_fail("Survival should spawn the chest-drop test enemy")
		return
	await _wait_until(session, func(snapshot: Dictionary) -> bool: return snapshot["entities"].size() == 1)
	session.simulation.spawn_projectile("test", Vector2.ZERO, Vector2(1000.0, 0.0), 100.0, 3.0, 1.0)
	var opened: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return session._chest_open and snapshot["paused"]
	)
	if opened.is_empty():
		_fail("An eligible enemy chest drop should be collected and open the three-choice modal")
		return
	var chosen_ids := [""]
	session.chest_option_chosen.connect(func(option_id: String) -> void: chosen_ids[0] = option_id)
	session.get_node("HUD/ChestOverlay/ChestChoice/Content/Options/Choice0").emit_signal("pressed")
	var resumed: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return not snapshot["paused"] and not session._chest_open and not chosen_ids[0].is_empty()
	)
	if resumed.is_empty():
		_fail("Taking a chest offer should apply a loadout choice and resume combat")
		return
	var choice: PackedStringArray = chosen_ids[0].split(":", false, 1)
	if choice.size() != 2 or session.loadout.weapon_level(choice[1]) == 0:
		_fail("Chest selection should update the run's weapon loadout")
		return
	print("Survival chest smoke passed")
	quit()

func _wait_until(session: Node2D, predicate: Callable) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var snapshot: Dictionary = session.simulation.snapshot()
		if predicate.call(snapshot):
			return snapshot
	return {}

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
