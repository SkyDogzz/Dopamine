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
	var lifesteal: Dictionary = stats["lifesteal_pct"]
	if not is_equal_approx(float(lifesteal["run"]), session.base_lifesteal_pct) or \
			not is_equal_approx(float(lifesteal["total"]), session.base_lifesteal_pct):
		_fail("Run stat details should include the proposed base lifesteal rate")
		return
	var lifesteal_row: VBoxContainer = session._run_stat_hub._stat_row(lifesteal)
	var lifesteal_icon: TextureRect = lifesteal_row.get_child(1).get_child(0)
	if lifesteal["label"] != "LIFESTEAL" or lifesteal_icon.texture == null or \
			lifesteal_icon.texture.resource_path != "res://assets/sprites/catalog/relic_blood_chalice.png":
		_fail("Lifesteal should have a matching relic icon in the detailed run stats")
		return
	lifesteal_row.free()
	if not hub.visible or hub.detail_open:
		_fail("The compact hub should be visible while its detail is closed")
		return
	var compact: VBoxContainer = hub.get_node("Compact")
	var damage_row: HBoxContainer = compact.get_node("damage_pct")
	if compact.get_child_count() != 3 or damage_row.get_child_count() != 2 or \
			damage_row.get_child(0) is not TextureRect or damage_row.get_child(1) is not Label:
		_fail("Compact stats should use one icon and value per vertically stacked row")
		return
	var detail_row: VBoxContainer = hub._stat_row(damage)
	var detail_label: Label = detail_row.get_child(0)
	var detail_value_row: HBoxContainer = detail_row.get_child(1)
	if detail_label.text != damage["label"] or detail_value_row.get_child_count() != 2 or \
			detail_value_row.get_child(0) is not TextureRect or \
			detail_value_row.get_child(1).text != damage["total_text"] or \
			detail_row.get_child_count() != 3 or detail_row.get_child(2).get_child_count() != 8:
		_fail("Detailed stats should stack the label over an icon and value on the left")
		return
	var source_row: HBoxContainer = detail_row.get_child(2)
	for index in range(0, source_row.get_child_count(), 2):
		if source_row.get_child(index) is not TextureRect or source_row.get_child(index + 1) is not Label:
			_fail("Stat contributions should use source icon and value pairs without text labels")
			return
	var compact_bounds := compact.get_global_rect()
	var compact_panel: PanelContainer = hub.get_node("CompactPanel")
	var run_panel: PanelContainer = session.get_node("HUD/RunPanel")
	if compact_panel.get_global_rect().position.x != run_panel.get_global_rect().position.x or \
		compact_panel.get_global_rect().position.y < run_panel.get_global_rect().end.y or \
		compact_bounds.size.x > 100.0:
		_fail("The compact stats should sit in their own panel directly below the run panel")
		return
	var start_time := float(session.simulation.snapshot()["simulation_time"])
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	session._unhandled_input(tab)
	if not hub.detail_open or root.gui_get_focus_owner() != hub.get_node("Detail/Content/Header/CloseButton"):
		_fail("Tab should open the read-only detail and place keyboard/gamepad focus on Close")
		return
	var detail_panel: PanelContainer = hub.get_node("Detail")
	if compact_panel.visible or detail_panel.get_global_rect().position.x != compact_panel.get_global_rect().position.x or \
		detail_panel.get_global_rect().position.y != compact_panel.get_global_rect().position.y:
		_fail("The compact and detailed stats should share the same top-left position")
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
	if not hub.get_node("Detail/Content/XPStatus").text.contains("RUN BONUSES 0"):
		_fail("The detail panel should show the current XP run bonus count")
		return
	if "--capture" in OS.get_cmdline_user_args() and not await _capture_detail(session):
		return
	session._unhandled_input(tab)
	if hub.detail_open or not compact_panel.visible:
		_fail("Pressing Tab again should collapse details back into the compact panel")
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

func _capture_detail(session: Node2D) -> bool:
	if root.get_visible_rect().size != Vector2(640, 360):
		_fail("Expected a 640x360 logical viewport for run stat details")
		return false
	var was_processing := session.is_processing()
	session.set_process(false)
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../docs/art/evidence/2026-10-18/states/run-stat-detail.png")
	var save_error := root.get_texture().get_image().save_png(path)
	session.set_process(was_processing)
	if save_error != OK:
		_fail("Could not capture the run stat details")
		return false
	print("Run stat detail visual capture: %s" % path)
	return true
