extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	for _level in range(4):
		if not session.loadout.apply_offer("weapon:lightning_conductor"):
			_fail("The lightning weapon fixture should upgrade to level five")
			return
	for _level in range(5):
		if not session.loadout.apply_offer("relic:storm_core"):
			_fail("Storm Core should reach its max level for the evolution fixture")
			return
	if session.loadout.has_method("is_evolution_ready") and \
		session.loadout.call("is_evolution_ready", "lightning_conductor") and \
		not session.loadout.apply_offer("evolution:lightning_conductor"):
		_fail("The inventory fixture should claim its ready max-level combo")
		return
	if not session.loadout.apply_offer("weapon:minigun") or \
		not session.loadout.apply_offer("relic:magnet_heart"):
		_fail("The inventory fixture should equip an evolved weapon, a base weapon and relics")
		return

	await _send_escape()
	var inventory_button: Button = session.get_node_or_null("HUD/PauseOverlay/Center/Panel/Content/InventoryButton")
	if inventory_button == null:
		_fail("Pause should provide access to the run inventory")
		return
	inventory_button.pressed.emit()
	await process_frame
	var inventory: Control = session.get_node_or_null("HUD/RunInventoryPanel")
	if inventory == null or not inventory.visible:
		_fail("The run inventory should open over the paused run")
		return
	var items: VBoxContainer = inventory.get_node("Center/Panel/Content/Scroll/Items")
	var scroll: ScrollContainer = inventory.get_node("Center/Panel/Content/Scroll")
	if inventory.get_node("Center/Panel").custom_minimum_size.x < 400 or scroll.custom_minimum_size.y < 180:
		_fail("Run inventory should reserve enough width and scroll height to show more than one short item")
		return
	if root.gui_get_focus_owner() != items.get_child(1) or not scroll.draw_focus_border or not scroll.follow_focus:
		_fail("Run inventory should focus its first read-only item when opened")
		return
	var down_event := InputEventKey.new()
	down_event.keycode = KEY_DOWN
	down_event.physical_keycode = KEY_DOWN
	down_event.pressed = true
	Input.parse_input_event(down_event)
	await process_frame
	down_event.pressed = false
	Input.parse_input_event(down_event)
	await process_frame
	if root.gui_get_focus_owner() != items.get_child(2):
		_fail("Keyboard navigation should focus the next item")
		return
	var focused_item_style := (items.get_child(2) as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
	if focused_item_style.border_color != Color("#FFD447"):
		_fail("Focused read-only items should show the visible gold focus outline")
		return
	(items.get_child(items.get_child_count() - 1) as Control).grab_focus()
	await process_frame
	if scroll.scroll_vertical <= 0:
		_fail("Focusing an offscreen item should scroll it into view")
		return
	(items.get_child(1) as Control).grab_focus()
	if (items.get_child(0) as Label).theme_type_variation != "PixelHeading" or \
			(items.get_child(3) as Label).theme_type_variation != "PixelHeading":
		_fail("Run inventory section labels should use the Art Bible pixel heading font")
		return
	var row_count := 0
	var icon_count := 0
	for child in items.get_children():
		if child.name.begins_with("ItemRow_"):
			row_count += 1
			var icon: TextureRect = child.get_child(0).get_child(0)
			if icon.custom_minimum_size != Vector2(24, 24):
				_fail("Run inventory catalog icons should use the 24x24 readability size")
				return
			if icon.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
				_fail("Run inventory catalog icons should use nearest filtering")
				return
			if icon.texture != null:
				icon_count += 1
	if row_count != 4:
		_fail("Inventory should list exactly two weapons and two relics")
		return
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png("/tmp/dopamine-run-inventory-current.png") != OK:
			_fail("Could not capture the run inventory at the logical viewport")
			return
	if inventory.get_node("Center/Panel/Content/Counts").text != "WEAPONS 2  •  RELICS 2  •  SCROLL ↑↓ / WHEEL":
		_fail("Run inventory should keep counts and its scroll hint visible above the item list")
		return
	if icon_count != 4:
		_fail("Every equipped weapon and relic should show its catalog icon")
		return
	var text := _all_label_text(inventory)
	for expected in ["Lightning Conductor", "Minigun", "Storm Core", "Magnet Heart", "EVOLVED", "Shoots one bolt"]:
		if not text.contains(expected):
			_fail("Run inventory is missing canonical item data: %s" % expected)
			return
	var first_details: VBoxContainer = (items.get_child(1) as PanelContainer).get_child(0).get_child(1)
	var item_title := first_details.get_child(0) as Label
	var evolution := first_details.get_child(1) as Label
	var description := first_details.get_child(2) as Label
	if item_title.get_theme_color("font_color").to_html(false) != "f6f7ff" or \
		item_title.get_theme_font_size("font_size") != 9 or \
		evolution.get_theme_color("font_color").to_html(false) != "ff75e3" or \
		description.get_theme_color("font_color").to_html(false) != "a6aec4" or \
		description.autowrap_mode != TextServer.AUTOWRAP_WORD_SMART:
		_fail("Run inventory should distinguish item name, evolved state and wrapping description")
		return
	if not bool(session.simulation.snapshot()["paused"]):
		_fail("Opening run inventory must keep the simulation paused")
		return
	var original_size: Vector2i = root.size
	var inventory_card: Control = inventory.get_node("Center/Panel")
	for size in [Vector2i(640, 360), Vector2i(960, 600), Vector2i(1280, 800), Vector2i(1600, 900)]:
		root.size = size
		await process_frame
		if not Rect2(Vector2.ZERO, Vector2(size)).encloses(inventory_card.get_global_rect()):
			_fail("Run inventory should fit viewport %s; card=%s viewport=%s" % [size, inventory_card.get_global_rect(), root.size])
			return
	root.size = original_size
	await _send_gamepad_cancel()
	if session.get_node_or_null("HUD/RunInventoryPanel") != null or \
		root.gui_get_focus_owner() != inventory_button or not bool(session.simulation.snapshot()["paused"]):
		_fail("Gamepad cancel should close inventory, restore Pause focus and keep the run paused")
		return
	if session.loadout.weapon_level("lightning_conductor") != 5 or \
		session.loadout.weapon_level("minigun") != 1 or session.loadout.relic_level("storm_core") != 5 or \
		session.loadout.relic_level("magnet_heart") != 1:
		_fail("Viewing and closing the inventory must not mutate the run loadout")
		return
	print("Survival pause inventory smoke passed")
	quit()

func _escape_event() -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	return event

func _send_escape() -> void:
	var event := _escape_event()
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _send_gamepad_cancel() -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = JOY_BUTTON_B
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _all_label_text(node: Node) -> String:
	var result := ""
	if node is Label:
		result += (node as Label).text + "\n"
	for child in node.get_children():
		result += _all_label_text(child)
	return result

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
