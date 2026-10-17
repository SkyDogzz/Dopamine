extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	session.xp_collection_radius = 10.0
	session.magnet_heart_level_five_pulse_interval_seconds = 1000.0
	session.magnet_heart_level_five_pulse_duration_seconds = 20.0
	session.magnet_heart_level_five_radius_multiplier = 3.0
	session.magnet_heart_level_five_acceleration = 500.0
	session.magnet_heart_level_five_max_speed = 100.0
	root.add_child(session)
	await process_frame
	if not await _set_relic_level(session, "magnet_heart", 5) or \
			not await _set_relic_level(session, "magnetic_coil", 4) or \
			not await _set_relic_level(session, "singularity", 4) or \
			not await _set_relic_level(session, "celestial_eye", 4):
		_fail("Magnet Heart synergy fixture should reach the requested relic levels")
		return
	if not is_equal_approx(session._magnet_heart_effective_pulse_radius(), 30.0) or \
			not is_equal_approx(session._magnet_heart_effective_pulse_max_speed(), 100.0) or \
			not session._magnet_heart_singularity_fields().is_empty():
		_fail("Magnet Heart synergies should remain inactive until both relics reach level 5")
		return
	if not await _set_relic_level(session, "magnetic_coil", 5) or \
			not await _set_relic_level(session, "celestial_eye", 5):
		_fail("Magnetic Coil and Celestial Eye should reach level 5")
		return
	if not is_equal_approx(session._magnet_heart_effective_pulse_radius(), 45.0) or \
			not is_equal_approx(session._magnet_heart_effective_pulse_max_speed(), 150.0) or \
			not session._magnet_heart_singularity_fields().is_empty():
		_fail("Coil/Celestial levels=%d/%d radius=%.2f speed=%.2f fields=%d" % [
			session.loadout.relic_level("magnetic_coil"), session.loadout.relic_level("celestial_eye"),
			session._magnet_heart_effective_pulse_radius(), session._magnet_heart_effective_pulse_max_speed(),
			session._magnet_heart_singularity_fields().size(),
		])
		return
	if not await _set_relic_level(session, "singularity", 5):
		_fail("Singularity should reach level 5")
		return
	var player_position: Vector2 = session.player.global_position
	var event_horizon_position := player_position + Vector2(200.0, 0.0)
	var event_horizon_sequence: int = session.simulation.spawn_projectile("event_horizon", event_horizon_position,
		Vector2.ZERO, 5.0, 8.0, 20.0, 2.0, 0.5, 2.0, 0.0, 0.0, 0, 80.0, 20.0)
	var void_orb_sequence: int = session.simulation.spawn_projectile("void_orb",
		player_position + Vector2(-500.0, 0.0), Vector2.ZERO, 5.0, 8.0, 20.0,
		2.0, 0.5, 2.0, 0.0, 0.0, 0, 80.0, 20.0)
	var xp_sequence: int = session.simulation.spawn_xp_orb(player_position + Vector2(220.0, 0.0), 1.0)
	if event_horizon_sequence <= 0 or void_orb_sequence <= 0 or xp_sequence <= 0 or \
			not await _wait_for_sequence(session, xp_sequence):
		_fail("Gravity synergy fixtures should enter the native simulation")
		return
	session._entities = session.simulation.snapshot()["entities"]
	if session._magnet_heart_singularity_fields().size() != 2:
		_fail("Max-level Singularity should expose both active gravity field types to Magnet Heart")
		return
	var xp_orb_id := -1
	for entity in session.simulation.snapshot()["entities"]:
		if entity["components"].get("IsXpOrb", false):
			xp_orb_id = int(entity["id"]["index"])
			break
	if xp_orb_id < 0:
		_fail("Gravity synergy should retain its XP fixture")
		return
	var start_position := _find_entity_position(session.simulation.snapshot()["entities"], xp_orb_id)
	var current_state: Dictionary = session.simulation.snapshot()
	session._magnet_heart_next_pulse_at = float(current_state["simulation_time"])
	session._magnet_heart_impulse_expires_at = 0.0
	session._update_magnet_heart_pulse(current_state, 0.1)
	var step_sequence: int = session.simulation.step(0.1)
	if step_sequence <= 0 or not await _wait_for_sequence(session, step_sequence):
		_fail("The magnetic pulse gravity step should be acknowledged")
		return
	var end_position := _find_entity_position(session.simulation.snapshot()["entities"], xp_orb_id)
	var closer_to_gravity := end_position.distance_to(event_horizon_position) < start_position.distance_to(event_horizon_position)
	session.queue_free()
	if not closer_to_gravity:
		_fail("Magnet Heart + Singularity should pull XP toward Event Horizon while a distant Void Orb is also active")
		return
	print("Survival Magnet Heart synergy smoke passed")
	quit()

func _set_relic_level(session: Node2D, relic_id: String, target_level: int) -> bool:
	while session.loadout.relic_level(relic_id) < target_level:
		if not session.loadout.apply_offer("relic:" + relic_id):
			return false
	return session.loadout.relic_level(relic_id) == target_level

func _wait_for_sequence(session: Node2D, sequence: int) -> bool:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if int(session.simulation.snapshot()["last_sequence"]) >= sequence:
			return true
	return false

func _find_entity_position(entities: Array, entity_index: int) -> Vector2:
	for entity in entities:
		if int(entity["id"]["index"]) == entity_index:
			var transform: Dictionary = entity["components"]["Transform2D"]
			return Vector2(float(transform["x"]), float(transform["y"]))
	return Vector2.INF

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
