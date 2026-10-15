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
	var active_session: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return not snapshot["paused"]
	)
	if active_session.is_empty():
		_fail("Survival should resume before pickup range checks")
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
	for _level in range(4):
		if not session.loadout.apply_offer("relic:magnet_heart"):
			_fail("Magnet Heart should upgrade through level 5")
			return
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
	if session.simulation.spawn_xp_orb(session.player.global_position + Vector2(85.0, 0.0), 1.0) <= 0:
		_fail("Survival should spawn the level-5 Magnet Heart XP fixture")
		return
	collected_xp = await _wait_until(session, func(_snapshot: Dictionary) -> bool:
		return session.player_xp > xp_before
	)
	if collected_xp.is_empty():
		_fail("Magnet Heart level 5 should apply its configured pickup radius")
		return
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
	if session.get_node("HUD/ChestOverlay/ChestChoice/Content/Title").text != "WEAPON CHEST — CHOOSE ONE":
		_fail("Collected weapon chests should identify their item type in the heading")
		return
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

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
