extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	if not session.has_method("open_chest_family"):
		_fail("Survival session script should load")
		return
	if not session.CHEST_TEXTURE.resource_path.ends_with("rewards/chest_closed.png"):
		_fail("Survival chests should load their dedicated pixel-art reward sprite")
		return
	var chest_position := Vector2.ZERO
	var chest_positions: Array[Vector2] = [chest_position]
	var no_xp_positions: Array[Vector2] = []
	var no_chest_positions: Array[Vector2] = []
	var xp_position: Vector2 = session._find_spaced_drop_position(chest_position, false, chest_positions, no_xp_positions)
	if session._pickup_sprites_overlap(xp_position, session.XP_SPRITE_SIZE,
			chest_position, session.CHEST_SPRITE_SIZE):
		_fail("XP orbs must be placed clear of weapon and relic chests")
		return
	var second_chest_position: Vector2 = session._find_spaced_drop_position(chest_position, true, chest_positions, no_xp_positions)
	if second_chest_position.distance_squared_to(chest_position) < session.PICKUP_SPACING_STEP * session.PICKUP_SPACING_STEP:
		_fail("Weapon and relic chests must not completely overlap")
		return
	var moved_chest_position: Vector2 = session._find_spaced_drop_position(chest_position, true, no_chest_positions, chest_positions)
	if session._pickup_sprites_overlap(moved_chest_position, session.CHEST_SPRITE_SIZE,
			chest_position, session.XP_SPRITE_SIZE):
		_fail("A chest must avoid overlapping a previously dropped XP orb")
		return
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	session.ordinary_chest_drop_chance = 1.0
	session.chest_collection_radius = 100.0
	session.xp_collection_radius = 0.0
	root.add_child(session)
	var active_session: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return not snapshot["paused"]
	)
	if active_session.is_empty():
		_fail("Survival should resume before pickup range checks")
		return
	if session.open_chest([]) or session._chest_open or bool(session.simulation.snapshot()["paused"]):
		_fail("An invalid chest should not pause Survival or leave a stale chest state")
		return
	session.player_hp = 1000.0
	session.simulation.set_speed(4.0)
	session._cached_equipment_bonuses["pickup_radius_pct"] = 900.0
	session.xp_collection_radius = 10.0
	session.chest_collection_radius = 10.0
	session._world_chests.append({"family": "weapon", "position": session.player.global_position + Vector2(50.0, 0.0)})
	session._collect_nearby_chests(session.simulation.snapshot())
	if session._chest_open or session._world_chests.size() != 1:
		_fail("A large pickup bonus must not extend chest collection range")
		return
	session._world_chests.clear()
	var xp_before: float = session.player_xp
	if session.simulation.spawn_xp_orb(session.player.global_position + Vector2(50.0, 0.0), 5.0) <= 0:
		_fail("Survival should spawn the long-range XP pickup fixture")
		return
	var collected_xp: Dictionary = await _wait_until(session, func(_snapshot: Dictionary) -> bool:
		return session.player_xp > xp_before
	)
	if collected_xp.is_empty():
		_fail("A large pickup bonus should extend XP collection range")
		return
	session._cached_equipment_bonuses.clear()
	session.xp_collection_radius = 40.0
	session.chest_collection_radius = 10.0
	if not session.loadout.apply_offer("relic:magnet_heart"):
		_fail("Magnet Heart should be available as a relic choice")
		return
	session._world_chests.append({"family": "weapon", "position": session.player.global_position + Vector2(45.0, 0.0)})
	session._collect_nearby_chests(session.simulation.snapshot())
	if session._chest_open or session._world_chests.size() != 1:
		_fail("Magnet Heart must never extend chest collection range")
		return
	session._world_chests.clear()
	xp_before = session.player_xp
	if session.simulation.spawn_xp_orb(session.player.global_position + Vector2(45.0, 0.0), 1.0) <= 0:
		_fail("Survival should spawn the Magnet Heart XP fixture")
		return
	collected_xp = await _wait_until(session, func(_snapshot: Dictionary) -> bool:
		return session.player_xp > xp_before
	)
	if collected_xp.is_empty():
		_fail("Magnet Heart should extend XP collection range")
		return
	for _level in range(3):
		if not session.loadout.apply_offer("relic:magnet_heart"):
			_fail("Magnet Heart should upgrade through level 5")
			return
	session.magnet_heart_level_five_pulse_interval_seconds = 1.0
	session.magnet_heart_level_five_pulse_duration_seconds = 1.5
	session.magnet_heart_level_five_acceleration = 300.0
	session.magnet_heart_level_five_max_speed = 160.0
	session._on_chest_option_selected("relic:magnet_heart")
	if session.loadout.relic_level("magnet_heart") != 5 or session.loadout.apply_offer("relic:magnet_heart"):
		_fail("Magnet Heart should stop at the proposed level cap of 5")
		return
	session._world_chests.append({"family": "weapon", "position": session.player.global_position + Vector2(85.0, 0.0)})
	session._collect_nearby_chests(session.simulation.snapshot())
	if session._chest_open or session._world_chests.size() != 1:
		_fail("Magnet Heart level 5 must not attract distant chests")
		return
	session._world_chests.clear()
	xp_before = session.player_xp
	var pulse_orb_start: Vector2 = session.player.global_position + Vector2(115.0, 0.0)
	if session.simulation.spawn_xp_orb(pulse_orb_start, 1.0) <= 0:
		_fail("Survival should spawn the level-5 Magnet Heart XP fixture")
		return
	var pulse_orb_state: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		for entity in snapshot["entities"]:
			var components: Dictionary = entity["components"]
			if components.get("IsXpOrb", false) and is_equal_approx(float(components.get("XpValue", 0.0)), 1.0):
				return true
		return false
	)
	var pulse_orb_id := -1
	for entity in pulse_orb_state.get("entities", []):
		var components: Dictionary = entity["components"]
		if components.get("IsXpOrb", false) and is_equal_approx(float(components.get("XpValue", 0.0)), 1.0):
			pulse_orb_id = int(entity["id"]["index"])
			break
	if pulse_orb_id < 0:
		_fail("Magnetic Pulse test should identify its XP orb in the native snapshot")
		return
	var moved_without_teleport := await _wait_until(session, func(snapshot: Dictionary) -> bool:
		for entity in snapshot["entities"]:
			if int(entity["id"]["index"]) != pulse_orb_id:
				continue
			var transform: Dictionary = entity["components"]["Transform2D"]
			var orb_position := Vector2(float(transform["x"]), float(transform["y"]))
			return orb_position.distance_to(session.player.global_position) < 115.0 and \
				orb_position.distance_to(session.player.global_position) > session._xp_pickup_radius(float(snapshot["simulation_time"]))
		return false
	)
	if moved_without_teleport.is_empty():
		_fail("Magnetic Pulse should accelerate the XP orb toward the player without teleporting or collecting it outside normal range")
		return
	session.simulation.pause()
	var paused_pulse: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool: return bool(snapshot["paused"]))
	if paused_pulse.is_empty():
		_fail("Survival should pause during Magnetic Pulse")
		return
	var frozen_position := Vector2.ZERO
	for entity in paused_pulse["entities"]:
		if int(entity["id"]["index"]) == pulse_orb_id:
			var transform: Dictionary = entity["components"]["Transform2D"]
			frozen_position = Vector2(float(transform["x"]), float(transform["y"]))
			break
	var paused_time := float(paused_pulse["simulation_time"])
	await create_timer(0.1).timeout
	var frozen_after_pause := _find_entity_position(session.simulation.snapshot()["entities"], pulse_orb_id)
	if not is_equal_approx(float(session.simulation.snapshot()["simulation_time"]), paused_time) or \
			frozen_after_pause.distance_to(frozen_position) > 0.001 or session.player_xp != xp_before:
		_fail("Magnetic Pulse movement, collection and simulation time should freeze while paused")
		return
	session.simulation.resume()
	collected_xp = await _wait_until(session, func(_snapshot: Dictionary) -> bool:
		return session.player_xp > xp_before
	)
	if collected_xp.is_empty():
		_fail("Magnet Heart level 5 should trigger its proposed pickup impulse")
		return
	var impulse_expires_at: float = session._magnet_heart_impulse_expires_at
	var impulse_radius: float = session._xp_pickup_radius(impulse_expires_at - 0.001)
	var expired_radius: float = session._xp_pickup_radius(impulse_expires_at)
	var pulse_radius: float = session.xp_collection_radius * session.magnet_heart_level_five_radius_multiplier
	var current_simulation_time: float = float(session.simulation.snapshot()["simulation_time"])
	if not is_equal_approx(impulse_radius, 90.0) or not is_equal_approx(expired_radius, 90.0) or \
			not is_equal_approx(pulse_radius, 120.0) or session._magnet_heart_next_pulse_at <= current_simulation_time:
		_fail("Magnet Heart pulse should attract inside 300%% radius, preserve the 90-unit collection radius and keep its next pulse scheduled")
		return
	session.simulation.pause()
	var paused_snapshot: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return snapshot["paused"]
	)
	if paused_snapshot.is_empty():
		_fail("Magnet Heart impulse should remain available while Survival is paused")
		return
	await create_timer(0.1).timeout
	if not is_equal_approx(float(session.simulation.snapshot()["simulation_time"]),
			float(paused_snapshot["simulation_time"])) or not is_equal_approx(
				session._xp_pickup_radius(float(paused_snapshot["simulation_time"])), impulse_radius):
		_fail("Magnet Heart impulse duration should freeze with the paused simulation clock")
		return
	session.simulation.resume()
	session.chest_collection_radius = 100.0
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
	var settled_chest: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return snapshot["paused"] and is_equal_approx(session._last_simulation_time, float(snapshot["simulation_time"]))
	)
	if settled_chest.is_empty():
		_fail("Survival HUD clocks should catch up to the paused chest snapshot")
		return
	var chest_open_time: float = float(settled_chest["simulation_time"])
	var chest_open_active_time: float = session.player_active_time
	await create_timer(0.12).timeout
	var during_chest: Dictionary = session.simulation.snapshot()
	if not during_chest["paused"] or not is_equal_approx(float(during_chest["simulation_time"]), chest_open_time) or \
			not is_equal_approx(session.player_active_time, chest_open_active_time):
		_fail("Opening a chest should freeze both clocks: sim %.6f→%.6f, active %.6f→%.6f, paused=%s" % [
			chest_open_time, float(during_chest["simulation_time"]), chest_open_active_time,
		session.player_active_time, str(during_chest["paused"]),
		])
		return
	if session.get_node("HUD/ChestOverlay/ChestChoice/Content/Title").text != "WEAPON CHEST — CHOOSE ONE":
		_fail("Collected weapon chests should identify their item type in the heading")
		return
	session._on_chest_option_selected("weapon:not_an_active_offer")
	await process_frame
	if not session._chest_open or not bool(session.simulation.snapshot()["paused"]) or \
			not session.get_node("HUD/ChestOverlay/ChestChoice").visible:
		_fail("An invalid selection should leave the chest open and the simulation paused")
		return
	# Isolate the resume assertion from a second random chest opening immediately.
	session._world_chests.clear()
	var chosen_ids := [""]
	session.chest_option_chosen.connect(func(option_id: String) -> void: chosen_ids[0] = option_id)
	session.get_node("HUD/ChestOverlay/ChestChoice/Content/Options/Choice0").emit_signal("pressed")
	var resumed: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return not snapshot["paused"] and not session._chest_open and not chosen_ids[0].is_empty()
	)
	if resumed.is_empty():
		var final_state: Dictionary = session.simulation.snapshot()
		_fail("Chest choice timed out: paused=%s chest_open=%s choice=%s run_over=%s logs=%s" % [
			final_state["paused"], session._chest_open, chosen_ids[0], session.run_over, final_state["logs"]
		])
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

func _find_entity_position(entities: Array, entity_index: int) -> Vector2:
	for entity in entities:
		if int(entity["id"]["index"]) != entity_index:
			continue
		var transform: Dictionary = entity["components"]["Transform2D"]
		return Vector2(float(transform["x"]), float(transform["y"]))
	return Vector2.INF

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
