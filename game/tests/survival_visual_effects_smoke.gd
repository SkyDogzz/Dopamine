extends SceneTree

var _settings: SettingsService

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_settings = root.get_node("Settings") as SettingsService
	_settings.set_reduced_visual_effects_enabled(false)
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.sandbox_diagnostics_enabled = true
	session.sandbox_rng_seed = 9137
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	if session.simulation == null:
		_fail("Survival session failed to initialize")
		return
	session.simulation.pause()
	await process_frame
	var state_before: Dictionary = session.simulation.snapshot()
	session._add_weapon_impact("inferno_sprayer", Vector2.ZERO, false)
	session._add_weapon_impact("inferno_sprayer", Vector2.RIGHT * 20.0, false, true)
	session._add_enemy_death_pixels("chaser", Vector2.ZERO)
	session._add_lightning_arc(Vector2.ZERO, Vector2.RIGHT * 20.0)
	if session._weapon_impacts.size() != 2 or \
		bool(session._weapon_impacts[0].get("critical_hit", true)) or \
		bool(session._weapon_impacts[1].get("critical_hit", false)) != true or \
		float(session._weapon_impacts[1].get("emphasis_scale", 1.0)) <= \
		float(session._weapon_impacts[0].get("emphasis_scale", 1.0)) or \
		session._enemy_death_pixels.size() != 8 or \
		session._lightning_arcs.size() != 1:
		_fail("Critical direct hits should retain metadata and receive visible size emphasis")
		return
	var normal_impact_next_random := _next_impact_random(session, false)
	var reduced_impact_next_random := _next_impact_random(session, true)
	var normal_arc_next_random := _next_arc_random(session, false)
	var reduced_arc_next_random := _next_arc_random(session, true)
	if not is_equal_approx(normal_impact_next_random, reduced_impact_next_random) or \
		not is_equal_approx(normal_arc_next_random, reduced_arc_next_random):
		_fail("Reduced visual effects must not change the gameplay random stream")
		return
	_settings.set_reduced_visual_effects_enabled(true)
	session._add_weapon_impact("inferno_sprayer", Vector2.ZERO, false)
	session._add_enemy_death_pixels("chaser", Vector2.ZERO)
	session._add_lightning_arc(Vector2.ZERO, Vector2.RIGHT * 20.0)
	if not session._visual_effects_reduced() or not session._weapon_impacts.is_empty() or \
		not session._enemy_death_pixels.is_empty() or not session._lightning_arcs.is_empty():
		_fail("Reduced effects should clear and suppress impact, death and lightning visuals")
		return
	var state_after: Dictionary = session.simulation.snapshot()
	if not bool(state_after["paused"]) or int(state_after["last_sequence"]) != int(state_before["last_sequence"]) or \
		state_after["entities"].size() != state_before["entities"].size():
		_fail("Changing visual effects must not advance or alter combat simulation")
		return
	_settings.set_reduced_visual_effects_enabled(false)
	if not session._weapon_impacts.is_empty() or not session._enemy_death_pixels.is_empty() or \
		not session._lightning_arcs.is_empty():
		_fail("Re-enabling effects should not replay visuals that were already on screen")
		return
	session.queue_free()
	await process_frame
	print("survival_visual_effects_smoke: passed")
	quit(0)

func _next_impact_random(session: Node2D, reduced: bool) -> float:
	_settings.set_reduced_visual_effects_enabled(reduced)
	session._sandbox_rng.seed = 7253
	session._sandbox_rng_log.clear()
	session._add_weapon_impact("inferno_sprayer", Vector2.ZERO, false)
	return session._random_float("visual_effect_random_stream_probe")

func _next_arc_random(session: Node2D, reduced: bool) -> float:
	_settings.set_reduced_visual_effects_enabled(reduced)
	session._sandbox_rng.seed = 8129
	session._sandbox_rng_log.clear()
	session._add_lightning_arc(Vector2.ZERO, Vector2.RIGHT * 20.0)
	return session._random_float("visual_effect_random_stream_probe")

func _fail(message: String) -> void:
	if _settings != null:
		_settings.set_reduced_visual_effects_enabled(false)
	push_error(message)
	quit(1)
