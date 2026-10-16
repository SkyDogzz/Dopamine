extends SceneTree

class FakeProgression:
	func equipment_bonuses() -> Dictionary:
		return {"damage_pct": 20.0, "move_speed_pct": 5.0}
	func equipped_unique_effects() -> Array[String]:
		return []
	func skill_bonus(stat_id: String) -> float:
		return {"damage_pct": 0.1, "move_speed_pct": 0.02}.get(stat_id, 0.0)
	func achievement_bonus(stat_id: String) -> float:
		return 0.05 if stat_id == "damage_pct" else 0.0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	var spawn_sequence: int = session.simulation.spawn_enemy(
		"chaser", 1, session.player.global_position + Vector2(120.0, 0.0), Vector2.ZERO
	)
	var spawn_deadline := Time.get_ticks_msec() + 1000
	while int(session.simulation.snapshot()["last_sequence"]) < spawn_sequence and Time.get_ticks_msec() < spawn_deadline:
		await process_frame
	var hub: Control = session.get_node_or_null("HUD/RunStatHub")
	if hub == null:
		_fail("A compact run stat hub should be visible during Survival")
		return
	session.progression_service = FakeProgression.new()
	session._refresh_persistent_bonuses()
	session.loadout.apply_offer("relic:storm_core")
	var stats: Dictionary = session._run_stat_breakdown()
	var damage: Dictionary = stats["damage_pct"]
	if not is_equal_approx(float(damage["run"]), 5.0) or \
			not is_equal_approx(float(damage["equipment"]), 20.0) or \
			not is_equal_approx(float(damage["achievements"]), 5.0) or \
			not is_equal_approx(float(damage["skill_tree"]), 10.0) or \
				not is_equal_approx(float(damage["total"]), 141.75):
		_fail("Damage should expose each contribution and the same combined multiplier as combat: %s" % damage)
		return
	if not hub.visible or hub.detail_open:
		_fail("The compact hub should be visible while its detail is closed")
		return
	var start_time := float(session.simulation.snapshot()["simulation_time"])
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	session._unhandled_input(tab)
	if not hub.detail_open or root.gui_get_focus_owner() != hub.get_node("Detail/Content/Header/CloseButton"):
		_fail("Tab should open the read-only detail and place keyboard/gamepad focus on Close")
		return
	var scroll: ScrollContainer = hub.get_node("Detail/Content/StatsScroll")
	var close_button: Button = hub.get_node("Detail/Content/Header/CloseButton")
	if scroll.focus_mode != Control.FOCUS_ALL or close_button.focus_neighbor_bottom != hub.get_node("Detail").get_path_to(scroll):
		_fail("Keyboard and gamepad focus should move from Close into the scrollable stat details")
		return
	var state: Dictionary = {}
	var advance_deadline := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < advance_deadline:
		await process_frame
		state = session.simulation.snapshot()
		if float(state["simulation_time"]) > start_time:
			break
	if not hub.detail_open or bool(state["paused"]) or float(state["simulation_time"]) <= start_time:
		_fail("Opening run stats must leave gameplay and the simulation clock running: %s / %s / %s" % [hub.detail_open, state["paused"], state["simulation_time"]])
		return
	if not hub.get_node("Detail/Content/XPStatus").text.contains("NOT CONFIGURED"):
		_fail("The detail panel should make the unconfigured XP stat bonus explicit")
		return
	session._unhandled_input(tab)
	if hub.detail_open:
		_fail("Tab should close the stat detail without pausing the run")
		return
	session._unhandled_input(tab)
	var cancel := InputEventKey.new()
	cancel.keycode = KEY_ESCAPE
	cancel.pressed = true
	session._unhandled_input(cancel)
	if hub.detail_open or bool(session.simulation.snapshot()["paused"]):
		_fail("Cancel should close the detail without pausing the run")
		return
	var original_size: Vector2i = root.size
	for size in [Vector2i(640, 360), Vector2i(960, 600), Vector2i(1280, 720)]:
		root.size = size
		await process_frame
		var bounds := Rect2(Vector2.ZERO, session.get_viewport().get_visible_rect().size)
		hub.set_detail_open(true)
		if not bounds.encloses(hub.get_node("Detail").get_global_rect()):
			_fail("Run stat details should fit viewport %s" % size)
			return
		hub.set_detail_open(false)
	root.size = original_size
	session.queue_free()
	await process_frame
	print("Survival run stat hub smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
