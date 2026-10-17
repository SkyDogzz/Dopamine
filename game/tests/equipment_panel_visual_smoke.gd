extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var panel: Control = load("res://scenes/equipment_inventory_panel.tscn").instantiate()
	root.add_child(panel)
	panel.present({
		"equipment_inventory": [{
			"instance_id": "visual-fixture",
			"slot": "boots",
			"rarity": "legendary",
			"stat_lines": [
				{"stat_id": "move_speed_pct", "roll_percentile": 0.8, "enhancement_level": 4},
				{"stat_id": "attack_speed_pct", "roll_percentile": 0.6, "enhancement_level": 2},
			],
			"equipped": true,
			"unique_effect_id": "lightning_burst",
		}],
		"resources": {},
	})
	await process_frame
	var panel_frame: Control = panel.get_node("Panel")
	var row: Control = panel.get_node("Panel/Content/Scroll/Items/Equipment_visual-fixture")
	var row_style := row.get_theme_stylebox("panel") as StyleBoxFlat
	var item_layout: HBoxContainer = row.get_child(0)
	var badges: HBoxContainer = item_layout.get_child(0)
	var item_content: VBoxContainer = item_layout.get_child(1)
	var status: Label
	var actions: HBoxContainer
	var stat_row_count := 0
	for child in item_content.get_children():
		if child is Label and (child as Label).text.contains("EQUIPPED"):
			status = child as Label
		elif child is HBoxContainer:
			if child.get_child_count() == 3:
				stat_row_count += 1
			elif child.get_child_count() == 2 and child.get_child(0) is Button:
				actions = child as HBoxContainer
	if stat_row_count != 2 or status == null or actions == null:
		_fail("Equipment cards should show both stat rolls, equipped state and item actions")
		return
	var move_speed_row: HBoxContainer
	for child in item_content.get_children():
		if child is HBoxContainer and child.get_child_count() == 3 and \
			(child.get_child(0) as Label).text.contains("MOVE SPEED"):
			move_speed_row = child as HBoxContainer
	if move_speed_row == null or (move_speed_row.get_child(1) as OptionButton).item_count != 4 or \
		(move_speed_row.get_child(2) as Button).text != "ENHANCE":
		_fail("Each equipment stat should show its value, powder choice and enhancement action")
		return
	var dismantle_button: Button = actions.get_child(1)
	var sell_button: Button
	for child in item_content.get_children():
		if child is Button and (child as Button).text.begins_with("SELL  •"):
			sell_button = child as Button
	if panel_frame.custom_minimum_size.x < 400:
		_fail("Equipment panel should reserve enough width for item stats and actions")
		return
	if row_style == null or row_style.border_color.to_html(false) != "ffd447" or row_style.border_width_left < 3:
		_fail("Equipment rows should use the rarity color as a strong left edge")
		return
	if badges.get_child_count() != 2 or \
		(badges.get_child(0) as TextureRect).texture.resource_path != "res://assets/icons/catalog/equipment_boots.png" or \
		(badges.get_child(1) as TextureRect).texture.resource_path != "res://assets/icons/catalog/rarity_legendary.png":
		_fail("Equipment rows should identify both the item slot and its rarity")
		return
	for badge in badges.get_children():
		if (badge as TextureRect).texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST or \
			(badge as TextureRect).custom_minimum_size != Vector2(24, 24):
			_fail("Equipment badges should be legible 24px nearest-filtered pixel art")
			return
	if not status.text.contains("UNIQUE: LIGHTNING BURST") or status.text.contains("LIGHTNING_BURST"):
		_fail("Unique effect IDs should be presented as readable names without code separators")
		return
	if actions.get_child_count() != 2 or (actions.get_child(0) as Button).text != "UNEQUIP" or \
		(actions.get_child(0) as Button).get_theme_color("font_color").to_html(false) != "37e8f5" or \
		(actions.get_child(1) as Button).get_theme_color("font_color").to_html(false) != "ff7181":
		_fail("Equipment actions should share a compact row with distinct equip and dismantle intent")
		return
	if dismantle_button.text != "DISMANTLE  •  3 REFINED" or not dismantle_button.tooltip_text.contains("3 REFINED POWDER"):
		_fail("The dismantle action should fit on its button and keep its full proposed yield in the tooltip")
		return
	var input_requests: Array[String] = []
	panel.equipment_state_requested.connect(func(instance_id: String, equipped: bool) -> void:
		input_requests.append("%s:%s" % [instance_id, str(equipped)])
	)
	var equip_button := actions.get_child(0) as Button
	equip_button.grab_focus()
	await _send_key(KEY_ENTER)
	if input_requests != ["visual-fixture:false"]:
		_fail("Enter should request the focused equipment action without applying it")
		return
	dismantle_button.grab_focus()
	await _send_gamepad_button(JOY_BUTTON_DPAD_LEFT)
	var gamepad_target := root.gui_get_focus_owner() as Button
	if gamepad_target == null or gamepad_target == dismantle_button:
		_fail("The gamepad D-pad should move focus to another equipment control")
		return
	input_requests.clear()
	equip_button.grab_focus()
	await _send_gamepad_button(JOY_BUTTON_A)
	if input_requests != ["visual-fixture:false"]:
		_fail("Gamepad A should activate the focused equipment action without applying it")
		return
	if sell_button == null or sell_button.text != "SELL  •  40 ESSENCE" or \
			sell_button.get_theme_color("font_color").to_html(false) != "ffd447":
		_fail("The sale action should show its proposed Essence value with a distinct visual treatment")
		return
	var original_size: Vector2i = root.size
	for viewport_size in [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = viewport_size
		await process_frame
		var bounds := Rect2(Vector2.ZERO, root.get_visible_rect().size)
		var frame_bounds := panel_frame.get_global_rect()
		if not bounds.encloses(frame_bounds) or not frame_bounds.encloses(row.get_global_rect()) or \
			dismantle_button.size.x < dismantle_button.get_combined_minimum_size().x or \
			sell_button.size.x < sell_button.get_combined_minimum_size().x:
			_fail("Equipment details and the dismantle action should fit viewport %s" % viewport_size)
			return
		for stat_child in move_speed_row.get_children():
			if not move_speed_row.get_global_rect().encloses((stat_child as Control).get_global_rect()):
				_fail("Equipment stat controls should remain inside their row at %s" % viewport_size)
				return
		if viewport_size == Vector2i(640, 360) and "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png("/tmp/dopamine-equipment.png") != OK:
				_fail("Could not capture the 640x360 equipment inventory render")
				return
	root.size = original_size
	if not panel_frame.get_global_rect().size.x <= 640:
		_fail("Equipment panel should stay within the logical 640px viewport")
		return
	panel.present({})
	var empty_state: Label = panel.get_node("Panel/Content/Scroll/Items/EmptyState")
	var error_state: Label = panel.get_node("Panel/Content/Scroll/Items/ErrorState")
	if not empty_state.visible or error_state.visible or empty_state.get_theme_font_size("font_size") < 10:
		_fail("The empty equipment state should remain centered and readable")
		return
	panel.present_error()
	if empty_state.visible or not error_state.visible or error_state.get_theme_font_size("font_size") < 10:
		_fail("The equipment error state should remain distinct and readable")
		return
	print("Equipment panel visual hierarchy smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _send_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _send_gamepad_button(button_index: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button_index
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
