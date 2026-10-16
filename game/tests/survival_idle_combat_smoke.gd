extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	seed(23)
	Engine.time_scale = 4.0
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.skip_starting_weapon_choice = true
	session.difficulty_id = "normal"
	session.xp_collection_radius = 0.0
	session.chest_collection_radius = 0.0
	root.add_child(session)
	session.simulation.set_speed(4.0)
	var deadline := Time.get_ticks_msec() + 120000
	while session.player_active_time < 20.0 and not session.run_over and Time.get_ticks_msec() < deadline:
		await process_frame
	var valid_run: bool = session.player_active_time >= 15.0 and session.wave_director.wave == 1 and \
		session.kill_count > 0 and session.player_hp < session.player_max_hp and \
		session.player_level == 1 and is_zero_approx(session.player_xp) and \
		session.loadout.owned_weapons().size() == 1 and session.loadout.owned_relics().is_empty()
	print("Idle combat: %.1fs active, %.1f/%.1f HP, %d kills, no XP or chest choices" % [
		session.player_active_time, session.player_hp, session.player_max_hp, session.kill_count,
	])
	session.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	if not valid_run:
		push_error("A stationary player with only the starting weapon should fight, take damage, and stay below level 2 during the first wave")
		quit(1)
		return
	print("Survival idle combat smoke passed")
	quit()
