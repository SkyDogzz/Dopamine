extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	if not session.has_method("open_chest_family"):
		_fail("Survival session script should load")
		return
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.boss_placeholder_hp = 10.0
	session.enemy_spawn_radius = 80.0
	session.chest_collection_radius = 200.0
	session.ordinary_chest_drop_chance = 0.0
	session.weapon_enabled = false
	root.add_child(session)
	await process_frame
	session.spawn_initial_enemy = true
	session.wave_director.wave = 24
	session.wave_director.state = session.WAVE_DIRECTOR_SCRIPT.State.FINAL_BOSS
	session._spawn_boss_placeholder("final_boss")
	var boss_ready: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return _contains_type(snapshot, "final_boss")
	)
	if boss_ready.is_empty():
		_fail("The final boss placeholder should spawn")
		return
	var boss_position: Dictionary = _entity_position(boss_ready, "final_boss")
	session.simulation.spawn_projectile("test", Vector2.ZERO,
		Vector2(float(boss_position["x"]), float(boss_position["y"])).normalized() * 1000.0,
		20.0, 4.0, 1.0)
	var first_chest: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return session._victory_pending and session._chest_open and snapshot["paused"]
	)
	if first_chest.is_empty() or session._world_chests.size() != 1:
		_fail("Final boss victory should wait while both guaranteed chest families are processed")
		return
	var chest_animation_queued := false
	for transient in session._weapon_transient_animations:
		if str(transient.get("role", "")) == "chest" and str(transient.get("state", "")) == "open" and \
			bool(transient.get("use_wall_clock", false)):
			chest_animation_queued = true
	if not chest_animation_queued:
		_fail("A world reward chest should play its opening animation while its choice pauses simulation")
		return
	var choices := [0]
	session.chest_option_chosen.connect(func(_option_id: String) -> void: choices[0] += 1)
	session.get_node("HUD/ChestOverlay/ChestChoice/Content/Options/Choice0").emit_signal("pressed")
	var second_chest: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return session._chest_open and snapshot["paused"]
	)
	if second_chest.is_empty() or session._world_chests.size() != 0:
		_fail("Choosing the first boss chest should expose the second guaranteed family")
		return
	session.get_node("HUD/ChestOverlay/ChestChoice/Content/Options/Choice0").emit_signal("pressed")
	var victory: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return session.run_over and snapshot["paused"] and choices[0] == 2
	)
	if victory.is_empty() or session.get_node("HUD/RunResultOverlay/RunResultPanel/Content/Title").text != "VICTORY":
		_fail("The final victory should appear after both guaranteed boss chest choices")
		return
	print("Survival final boss loot smoke passed")
	quit()

func _contains_type(snapshot: Dictionary, enemy_type: String) -> bool:
	return not _entity_position(snapshot, enemy_type).is_empty()

func _entity_position(snapshot: Dictionary, enemy_type: String) -> Dictionary:
	for entity in snapshot["entities"]:
		var components: Dictionary = entity["components"]
		if components.get("EnemyType", "") == enemy_type:
			return components["Transform2D"]
	return {}

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
