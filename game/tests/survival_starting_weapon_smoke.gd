extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	if not session.has_method("open_chest_family"):
		_fail("Survival session script should load")
		return
	root.add_child(session)
	await process_frame
	var state: Dictionary = session.simulation.snapshot()
	var choice = session.get_node("HUD/ChestOverlay/ChestChoice")
	if not state["paused"] or not choice.visible or choice.get_node("Content/Options").get_child_count() != 2:
		_fail("The interactive run should wait on two starting weapon options")
		return
	var paused_simulation_time := float(state["simulation_time"])
	var paused_active_time := float(session.player_active_time)
	var paused_hp := float(session.player_hp)
	await create_timer(0.2).timeout
	state = session.simulation.snapshot()
	if not is_equal_approx(float(state["simulation_time"]), paused_simulation_time) or \
			not is_equal_approx(session.player_active_time, paused_active_time) or \
			not is_equal_approx(session.player_hp, paused_hp):
		_fail("The starting weapon modal should pause simulation time, active time and HP decay")
		return
	choice.get_node("Content/Options/Choice1").emit_signal("pressed")
	var deadline := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < deadline:
		state = session.simulation.snapshot()
		if not state["paused"] and float(state["simulation_time"]) > paused_simulation_time and \
				session.player_active_time > paused_active_time:
			break
		await process_frame
	if state["paused"] or float(state["simulation_time"]) <= paused_simulation_time or \
			session.loadout.weapon_level("inferno_sprayer") != 1 or session.loadout.weapon_level("lightning_conductor") != 0:
		_fail("Selecting Inferno Sprayer should equip it and start the run")
		return
	if session.player_active_time <= paused_active_time or session.player_hp >= paused_hp:
		_fail("Simulation time and HP decay should resume after the starting choice")
		return
	print("Survival starting weapon smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
