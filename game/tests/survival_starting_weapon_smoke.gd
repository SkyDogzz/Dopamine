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
	var inferno_choice: Button
	for option in choice.get_node("Content/Options").get_children():
		if option.get_node("ContentMargin/OfferRow/OfferDetails/OfferTitle").text == "Inferno Sprayer":
			inferno_choice = option
			break
	if inferno_choice == null:
		_fail("The starting weapon options should include Inferno Sprayer")
		return
	var first_choice := choice.get_node("Content/Options").get_child(0) as Button
	if root.gui_get_focus_owner() != first_choice:
		_fail("The first starting weapon should receive initial focus")
		return
	await _send_key(KEY_DOWN)
	var selected_choice := root.gui_get_focus_owner() as Button
	if selected_choice == null or selected_choice == first_choice:
		_fail("Down arrow should move focus to the other starting weapon")
		return
	var selected_title: String = selected_choice.get_node("ContentMargin/OfferRow/OfferDetails/OfferTitle").text
	var selected_weapon_id := selected_title.to_snake_case()
	await _send_key(KEY_ENTER)
	var deadline := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < deadline:
		state = session.simulation.snapshot()
		if not state["paused"] and float(state["simulation_time"]) > paused_simulation_time and \
				session.player_active_time > paused_active_time:
			break
		await process_frame
	var other_weapon_id := "inferno_sprayer" if selected_weapon_id == "lightning_conductor" else "lightning_conductor"
	if state["paused"] or float(state["simulation_time"]) <= paused_simulation_time or \
		session.loadout.weapon_level(selected_weapon_id) != 1 or session.loadout.weapon_level(other_weapon_id) != 0:
		_fail("The keyboard-selected starting weapon should be equipped and start the run")
		return
	if session.player_active_time <= paused_active_time or session.player_hp >= paused_hp:
		_fail("Simulation time and HP decay should resume after the starting choice")
		return
	var hud_weapon_text: String = session.get_node("HUD/RunPanel/RunInfo/LoadoutRow/LoadoutLabel").text
	var expected_hud_label := "LC Lv1" if selected_weapon_id == "lightning_conductor" else "IS Lv1"
	if not hud_weapon_text.contains(expected_hud_label):
		_fail("The run HUD should show the keyboard-selected weapon: %s" % hud_weapon_text)
		return
	print("Survival starting weapon smoke passed")
	quit()

func _send_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
