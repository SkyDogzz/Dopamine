extends SceneTree

const ENDLESS_CYCLES := 5
const WAVES_PER_CYCLE := 12

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var production_duration := OS.get_cmdline_user_args().has("--production-duration")
	var final_wave := ENDLESS_CYCLES * WAVES_PER_CYCLE if production_duration else WAVES_PER_CYCLE
	var normal_saves := ProjectSettings.globalize_path("user://saves")
	var saves_before := _save_fingerprints(normal_saves)
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.mode_id = "armorless"
	session.wave_duration_seconds = 30.0 if production_duration else 0.03
	session.spawn_initial_enemy = true
	session.enemy_spawn_interval = 1000.0
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	# Long-run integration checks progression and transitions, not natural survivability.
	session._health_locked = production_duration
	root.add_child(session)
	await process_frame
	session._chest_director.ordinary_drop_chance = 0.0
	session._chest_director.elite_drop_chance = 0.0
	session._chest_director.guarantee_interval_seconds = 0.0
	if production_duration:
		Engine.time_scale = 4.0
		session.simulation.set_speed(4.0)
	if session.armorless_run_state == null or not session.armorless_run_state.is_active() or \
		session.progression_service != null:
		_fail("Armorless session should initialize temporary state without a permanent progression service")
		return
	var bosses_defeated := 0
	for completed_wave in range(1, final_wave + 1):
		if not await _wait_until(func() -> bool:
			return session._chest_open and session._active_chest_options.size() == 3
		, production_duration):
			var state: Dictionary = session.simulation.snapshot()
			_fail("Armorless should open a three-choice draft after wave %d (wave=%d, state=%s, simulation_time=%.2f, speed=%.1f, paused=%s, chest=%s, options=%d, pending=%s, flux=%d)" % [
				completed_wave, session.wave_director.wave, str(session.wave_director.state),
				float(state.get("simulation_time", 0.0)), float(state.get("speed_multiplier", 1.0)),
				str(state.get("paused", false)), str(session._chest_open), session._active_chest_options.size(),
				str(session._pending_armorless_draft_waves), session.armorless_run_state.flux()])
			return
		var choice: Button = session.get_node("HUD/ChestOverlay/ChestChoice/Content/Options").get_child(0)
		if not choice.text.contains("TEMPORARY EQUIPMENT"):
			_fail("Every Armorless wave draft should identify its offer as temporary (wave=%d, heading=%s, offer=%s)" % [
				completed_wave, session._active_chest_heading, choice.text])
			return
		choice.pressed.emit()
		if session._chest_open or session.armorless_run_state.temporary_equipment().is_empty() or \
			int(session.armorless_run_state.flux()) < completed_wave:
			_fail("Choosing wave %d equipment should resume and update only the temporary build/Flux" % completed_wave)
			return
		if completed_wave % WAVES_PER_CYCLE != 0:
			continue
		if session.wave_director.wave != completed_wave or \
			session.wave_director.state != session.wave_director.State.MID_BOSS:
			_fail("Wave %d draft should lead into its Armorless mid-boss" % completed_wave)
			return
		if not await _wait_for_boss(session):
			_fail("The production session should spawn the wave %d mid-boss" % completed_wave)
			return
		var boss: Dictionary = _find_enemy(session, "mid_boss")
		var id: Dictionary = boss["id"]
		if session.simulation.apply_damage_over_time(
			int(id["index"]), int(id["generation"]), 100000.0, 0.05, 0.05
		) <= 0:
			_fail("The integration fixture should be able to resolve the wave %d boss" % completed_wave)
			return
		if not await _wait_until(func() -> bool:
			return session.wave_director.wave == completed_wave + 1 and \
				session.wave_director.state == session.wave_director.State.WAVE
		):
			_fail("Defeating the wave %d boss should resume the endless run" % completed_wave)
			return
		bosses_defeated += 1
	if session.wave_director.wave != final_wave + 1 or session.run_over or \
		session.armorless_run_state.temporary_equipment().is_empty() or \
		session.progression_service != null:
		_fail("Armorless should continue past its final tested boss with its temporary build and no permanent progression service")
		return
	if production_duration and bosses_defeated != ENDLESS_CYCLES:
		_fail("A long Armorless session should defeat all five scheduled bosses")
		return
	session._finish_run(false)
	if not session.armorless_run_state.temporary_equipment().is_empty() or session.armorless_run_state.flux() != 0:
		_fail("Ending the integrated Armorless cycle should discard temporary items and Flux")
		return
	session.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	if _save_fingerprints(normal_saves) != saves_before:
		_fail("An Armorless session cycle must not create or modify normal save slots")
		return
	print("Armorless session cycle smoke passed %d waves, %d boss cycles and temporary cleanup" % [final_wave, bosses_defeated])
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

func _wait_until(predicate: Callable, production_duration: bool = false) -> bool:
	var timeout_ms := 15000 if production_duration else 5000
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if predicate.call():
			return true
	return false

func _save_fingerprints(directory: String) -> Dictionary:
	var fingerprints := {}
	if not DirAccess.dir_exists_absolute(directory):
		return fingerprints
	for file_name in DirAccess.get_files_at(directory):
		fingerprints[file_name] = FileAccess.get_sha256(directory.path_join(file_name))
	return fingerprints

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
