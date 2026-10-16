extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := CenterContainer.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var panel: Control = load("res://scenes/run_result_panel.tscn").instantiate()
	host.add_child(panel)
	await process_frame
	if panel.theme == null:
		_fail("Run result should use the shared UI theme")
		return
	var summary: Label = panel.get_node("Content/Summary")
	var rewards: Label = panel.get_node("Content/Rewards")
	var equipment: Label = panel.get_node("Content/Equipment")
	panel.show_result(false, 4, 65.8, 12)
	if panel.get_node("Content/Title").text != "RUN OVER" or \
		not summary.text.contains("WAVE 04") or not summary.text.contains("01:05") or \
		not summary.text.contains("12 KILLS") or rewards.text != "RUN SANS SAUVEGARDE":
		_fail("A run without progression should clearly identify its no-save result")
		return
	var restart := panel.get_node("Content/RestartButton") as Button
	var quit := panel.get_node("Content/QuitButton") as Button
	if quit.get_index() <= restart.get_index() or quit.text != "QUIT TO MENU":
		_fail("Quit to menu should appear immediately below the restart action")
		return
	if root.gui_get_focus_owner() != restart:
		_fail("The result action should receive visible keyboard/gamepad focus")
		return
	var quit_requested := [false]
	panel.quit_requested.connect(func() -> void: quit_requested[0] = true)
	quit.emit_signal("pressed")
	if not quit_requested[0]:
		_fail("Quit to menu should emit its navigation request")
		return
	var success_reward := {
		"ok": true,
		"duplicate": false,
		"essence": 22,
		"powder_basic": 34,
		"equipment": {"rarity": "mystic", "slot": "helmet"},
		"new_achievement_tiers": 1,
	}
	panel.show_result(true, 24, 605.0, 90, success_reward)
	if panel.get_node("Content/Title").text != "VICTORY" or not rewards.text.contains("+22 ESSENCE") or \
		not rewards.text.contains("+34 BASIC POWDER") or not equipment.text.contains("HELMET") or \
		panel.get_node("Content/Achievement").text.is_empty():
		_fail("Victory should display only the provided rewards, item and achievement summary")
		return
	var achievement_icon_row: HBoxContainer = panel.get_node("Content/AchievementIcon")
	var achievement_icon: TextureRect = achievement_icon_row.get_child(0)
	if achievement_icon.texture == null or achievement_icon.texture.resource_path != "res://assets/icons/catalog/achievement_medal.png" or \
		achievement_icon.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST or \
		achievement_icon.custom_minimum_size != Vector2(24, 24):
		_fail("An achievement tier summary should use its existing compact pixel medal icon")
		return
	var reward_icons: HBoxContainer = panel.get_node("Content/RewardIcons")
	var reward_icon: TextureRect = reward_icons.get_child(0)
	if panel.custom_minimum_size.x < 340 or reward_icon.custom_minimum_size != Vector2(24, 24):
		_fail("Run results should give the reward summary and icons enough visual weight")
		return
	var victory_surface := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if victory_surface == null or victory_surface.border_color.to_html(false) != "48e69b":
		_fail("Victory should use the shared compact frame with a matching green status edge")
		return
	panel.show_result(false, 8, 120.0, 30, {"ok": true, "duplicate": true})
	if rewards.text != "ALREADY REWARDED" or not equipment.text.is_empty() or \
		panel.get_node("Content").get_node_or_null("RewardIcons") != null or \
		panel.get_node("Content").get_node_or_null("AchievementIcon") != null or \
		panel.get_node("Content").get_node_or_null("EquipmentIcon") != null or \
		rewards.get_theme_color("font_color").to_html(false) != "37e8f5":
		_fail("A duplicate reward should be identified without repeating equipment rewards")
		return
	panel.show_result(false, 8, 120.0, 30, {"ok": false, "error": "save_failed"})
	if rewards.text != "PROGRESSION SAVE FAILED" or rewards.get_theme_color("font_color").to_html(false) != "ff7181":
		_fail("A progression save error should stay distinct from an empty profile")
		return
	var defeat_surface := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if defeat_surface == null or defeat_surface.border_color.to_html(false) != "ff7181":
		_fail("Defeat should use a matching danger edge on the compact result frame")
		return
	var long_reward := success_reward.duplicate(true)
	long_reward["equipment"]["unique_effect_id"] = "pending_choice"
	panel.show_result(true, 24, 605.0, 90, long_reward)
	if rewards.get_theme_color("font_color").to_html(false) != "37e8f5":
		_fail("A later reward result should restore the normal rewards color after a save error")
		return
	var original_size: Vector2i = root.size
	for size in [Vector2i(640, 360), Vector2i(960, 600), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		root.size = size
		await process_frame
		var visible_bounds := Rect2(Vector2.ZERO, panel.get_viewport().get_visible_rect().size)
		var panel_bounds := panel.get_global_rect()
		if not visible_bounds.encloses(panel_bounds):
			_fail("Run result should fit viewport %s" % size)
			return
		for child in panel.get_node("Content").get_children():
			if child is Control and child.visible and not panel_bounds.encloses((child as Control).get_global_rect()):
				_fail("Run result content '%s' should stay inside the panel at viewport %s" % [child.name, size])
				return
		if size == Vector2i(640, 360) and "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png("/tmp/dopamine-run-result.png") != OK:
				_fail("Could not capture the 640x360 run result render")
				return
	root.size = original_size
	quit_requested[0] = false
	var cancel := InputEventJoypadButton.new()
	cancel.device = 0
	cancel.button_index = JOY_BUTTON_B
	cancel.pressed = true
	Input.parse_input_event(cancel)
	await process_frame
	cancel.pressed = false
	Input.parse_input_event(cancel)
	if not quit_requested[0]:
		_fail("Gamepad B should activate Quit to Menu from the run result")
		return
	panel.queue_free()
	await process_frame
	print("Run result panel states, focus and layout smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
