extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.mode_id = "armorless"
	session.wave_duration_seconds = 0.03
	session.spawn_initial_enemy = true
	session.enemy_spawn_interval = 1000.0
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	root.add_child(session)
	await process_frame
	if session.armorless_run_state == null or not session.armorless_run_state.is_active() or \
		session.progression_service != null:
		_fail("Armorless session should initialize temporary state without a permanent progression service")
		return
	for completed_wave in range(1, 13):
		if not await _wait_until(func() -> bool:
			return session._chest_open and session._active_chest_options.size() == 3
		):
			_fail("Armorless should open a three-choice draft after wave %d" % completed_wave)
			return
		var choice: Button = session.get_node("HUD/ChestOverlay/ChestChoice/Content/Options").get_child(0)
		if not choice.text.contains("TEMPORARY EQUIPMENT"):
			_fail("Every Armorless wave draft should identify its offer as temporary")
			return
		choice.pressed.emit()
		if session._chest_open or session.armorless_run_state.temporary_equipment().is_empty() or \
			int(session.armorless_run_state.flux()) < completed_wave:
			_fail("Choosing wave %d equipment should resume and update only the temporary build/Flux" % completed_wave)
			return
	if session.wave_director.wave != 12 or session.wave_director.state != session.wave_director.State.MID_BOSS:
		_fail("Twelve completed drafts should lead into the Armorless mid-boss state")
		return
	if not await _wait_for_boss(session):
		_fail("The production session should spawn the wave 12 mid-boss after its draft")
		return
	var boss: Dictionary = _find_enemy(session, "mid_boss")
	var id: Dictionary = boss["id"]
	if session.simulation.apply_damage_over_time(
		int(id["index"]), int(id["generation"]), 100000.0, 0.05, 0.05
	) <= 0:
		_fail("The integration fixture should be able to resolve the boss encounter")
		return
	if not await _wait_until(func() -> bool:
		return session.wave_director.wave == 13 and \
			session.wave_director.state == session.wave_director.State.WAVE
	):
		_fail("Defeating the Armorless mid-boss should resume the endless run at wave 13")
		return
	if session.run_over or session.armorless_run_state.temporary_equipment().is_empty() or \
		session.progression_service != null:
		_fail("Armorless should continue with its temporary build and no permanent progression service")
		return
	session._finish_run(false)
	if not session.armorless_run_state.temporary_equipment().is_empty() or session.armorless_run_state.flux() != 0:
		_fail("Ending the integrated Armorless cycle should discard temporary items and Flux")
		return
	session.queue_free()
	await process_frame
	var normal_saves := ProjectSettings.globalize_path("user://saves")
	if DirAccess.dir_exists_absolute(normal_saves) and not DirAccess.get_files_at(normal_saves).is_empty():
		_fail("An Armorless session cycle must not create or modify normal save slots")
		return
	print("Armorless session cycle smoke passed 12 drafts, boss transition and temporary cleanup")
	quit(0)

func _wait_for_boss(session: Node2D) -> bool:
	return await _wait_until(func() -> bool: return not _find_enemy(session, "mid_boss").is_empty())

func _find_enemy(session: Node2D, enemy_type: String) -> Dictionary:
	if session.simulation == null:
		return {}
	for entity in session.simulation.snapshot()["entities"]:
		if str(entity["components"].get("EnemyType", "")) == enemy_type:
			return entity
	return {}

func _wait_until(predicate: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if predicate.call():
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
