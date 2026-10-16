extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.difficulty_id = "hard"
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	var difficulty: Label = session.get_node_or_null("HUD/MetaPanel/MetaRow/DifficultyValue")
	if difficulty == null:
		_fail("The run HUD should expose the selected difficulty")
		return
	session._refresh_hud({"paused": false})
	var run_state: Label = session.get_node("HUD/MetaPanel/MetaRow/RunStateBadge/RunState")
	var run_state_style := (session.get_node("HUD/MetaPanel/MetaRow/RunStateBadge") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
	if run_state.text != "IN RUN" or run_state_style.border_color.to_html(false) != "48e69b":
		_fail("Active runs should use the green status badge")
		return
	if not difficulty.text.contains("HARD"):
		_fail("The run HUD should show the selected difficulty id")
		return
	session.player_hp = 42.0
	session.player_shield = 6.0
	session.player_xp = 5.0
	session.player_level = 2
	session.player_xp_to_next = 20.0
	session.player_active_time = 63.0
	session.wave_director.wave = 4
	session.wave_director.elapsed_in_wave = 5.0
	session._refresh_hud({"paused": false})
	if not session.get_node("HUD/RunPanel/RunInfo/StatusRow/HPRow/HPValue").text.contains("SHIELD 6") or \
		session.get_node("HUD/RunPanel/RunInfo/StatusRow/XPRow/XPValue").text != "LV 2  XP 5 / 20" or \
		session.get_node("HUD/MetaPanel/MetaRow/TimeValue").text != "01:03" or \
		not session.get_node("HUD/MetaPanel/MetaRow/WaveValue").text.contains("WAVE 04") or \
		session.get_node("HUD/RunPanel/RunInfo/LoadoutRow/LoadoutLabel").text != "LC Lv1" or \
		session.get_node("HUD/RunPanel/RunInfo/StatusRow/HPRow/HPBar").value != 42.0 or \
		session.get_node("HUD/RunPanel/RunInfo/StatusRow/XPRow/XPBar").value != 5.0:
		_fail("The run HUD should display current health, XP, time, wave and weapon state")
		return
	session._manually_paused = true
	session._refresh_hud({"paused": true})
	if run_state.text != "PAUSED · ESC" or run_state_style.border_color.to_html(false) != "ffd447":
		_fail("Paused runs should use the amber status badge and retain the Escape hint")
		return
	session._manually_paused = false
	session._refresh_hud({"paused": false})
	var boss_panel: Control = session.get_node("HUD/BossPanel")
	var weapon_label: Label = session.get_node("HUD/RunPanel/RunInfo/LoadoutRow/LoadoutLabel")
	var hp_row: HBoxContainer = session.get_node_or_null("HUD/RunPanel/RunInfo/StatusRow/HPRow")
	var xp_row: HBoxContainer = session.get_node_or_null("HUD/RunPanel/RunInfo/StatusRow/XPRow")
	if hp_row == null or xp_row == null or hp_row == xp_row:
		_fail("Health and XP should have separate, readable HUD rows")
		return
	var xp_icon: TextureRect = session.get_node("HUD/RunPanel/RunInfo/StatusRow/XPRow/XPOrb")
	if xp_icon.texture == null or xp_icon.texture.resource_path != "res://assets/sprites/rewards/xp_orb.png" or \
		xp_icon.custom_minimum_size != Vector2(16, 16) or xp_icon.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_fail("The XP HUD row should use the native-size pixel orb as its visual marker")
		return
	if weapon_label.text.is_empty() or weapon_label.size.y <= 0.0:
		_fail("The weapon names in the loadout row should be visible, not clipped to zero height")
		return
	if boss_panel.visible:
		_fail("The boss HUD should stay hidden without a boss")
		return
	session._entities = [{"components": {
		"EnemyType": "mid_boss",
		"Health": {"current": 20.0, "maximum": 100.0},
		"Transform2D": {"x": 300.0, "y": 300.0},
	}}]
	session._refresh_hud({"paused": false})
	if not boss_panel.visible or not session.get_node("HUD/BossPanel/BossInfo/BossValue").text.contains("PHASE 3") or \
		session.get_node("HUD/BossPanel/BossInfo/BossHPBar").value != 20.0:
		_fail("The boss HUD should show the current boss phase when a boss is active")
		return
	for _level in range(5):
		session.loadout.apply_offer("weapon:minigun")
	for _level in range(5):
		session.loadout.apply_offer("relic:overdrive_engine")
	if session.loadout.has_method("is_evolution_ready") and \
		session.loadout.call("is_evolution_ready", "minigun") and \
		not session.loadout.apply_offer("evolution:minigun"):
		_fail("The HUD evolution fixture should claim the ready max-level combo")
		return
	session._refresh_hud({"paused": false})
	if not session.get_node("HUD/RunPanel/RunInfo/LoadoutRow/LoadoutLabel").text.contains("MG Lv5 EVO"):
		_fail("The HUD should show a compact evolution marker from the current run loadout")
		return
	for weapon_id in session.loadout._weapon_definitions:
		session.loadout._weapon_levels.clear()
		session.loadout._weapon_levels[weapon_id] = 5
		session.loadout._evolved_weapons.clear()
		session.loadout._evolved_weapons[weapon_id] = true
		session._refresh_hud({"paused": false})
		if not session.get_node("HUD/RunPanel/RunInfo/LoadoutRow/LoadoutLabel").text.contains("Lv5 EVO"):
			_fail("The HUD should show the evolution marker for %s" % weapon_id)
			return
	var original_size: Vector2i = root.size
	for size in [Vector2i(640, 360), Vector2i(960, 600), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		root.size = size
		await process_frame
		var bounds := Rect2(Vector2.ZERO, session.get_viewport().get_visible_rect().size)
		var panel_rect := (session.get_node("HUD/RunPanel") as Control).get_global_rect()
		var meta_rect := (session.get_node("HUD/MetaPanel") as Control).get_global_rect()
		if not bounds.encloses(panel_rect) or not bounds.encloses(meta_rect):
			_fail("The run HUD should fit viewport %s, got %s" % [size, panel_rect])
			return
		if panel_rect.size.x > bounds.size.x * 0.45 or panel_rect.end.x > bounds.size.x * 0.45 or \
			meta_rect.position.x < bounds.size.x * 0.55:
			_fail("Run status and metadata should stay in separate screen corners at viewport %s (visible %s): %s / %s" % [size, bounds.size, panel_rect, meta_rect])
			return
		for row_path in ["HUD/RunPanel/RunInfo/StatusRow/HPRow", "HUD/RunPanel/RunInfo/StatusRow/XPRow", "HUD/RunPanel/RunInfo/LoadoutRow", "HUD/MetaPanel/MetaRow"]:
			var row := session.get_node(row_path) as Control
			var row_bounds := panel_rect if row_path.begins_with("HUD/RunPanel") else meta_rect
			for child in row.get_children():
				if not row_bounds.encloses((child as Control).get_global_rect()):
					_fail("HUD child %s should fit viewport %s" % [child.name, size])
					return
	root.size = original_size
	session.queue_free()
	await process_frame
	print("Survival HUD smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
