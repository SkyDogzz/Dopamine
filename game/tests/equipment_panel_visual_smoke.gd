extends SceneTree

const EQUIPMENT := [
	{"instance_id": "ring-equipped", "slot": "ring", "rarity": "magic", "equipped": true,
		"stat_lines": [{"stat_id": "critical_chance_pct", "roll_percentile": 0.5, "enhancement_level": 0}]},
	{"instance_id": "boots-old", "slot": "boots", "rarity": "normal", "equipped": true,
		"stat_lines": [{"stat_id": "move_speed_pct", "roll_percentile": 0.25, "enhancement_level": 0}]},
	{"instance_id": "boots-new", "slot": "boots", "rarity": "legendary", "equipped": false,
		"stat_lines": [
			{"stat_id": "move_speed_pct", "roll_percentile": 0.8, "enhancement_level": 4},
			{"stat_id": "attack_speed_pct", "roll_percentile": 0.6, "enhancement_level": 2},
		], "unique_effect_id": "lightning_burst"},
	{"instance_id": "ring-new", "slot": "ring", "rarity": "magic", "equipped": false,
		"stat_lines": [{"stat_id": "critical_chance_pct", "roll_percentile": 0.5, "enhancement_level": 0}]},
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var panel: Control = load("res://scenes/equipment_inventory_panel.tscn").instantiate()
	root.add_child(panel)
	panel.present({"equipment_inventory": EQUIPMENT, "resources": {"essence": 12}})
	await process_frame
	var panel_frame: Control = panel.get_node("Panel")
	var slots: VBoxContainer = panel.get_node("Panel/Content/Columns/Loadout/Body/Slots")
	var portrait: TextureRect = panel.get_node("Panel/Content/Columns/Loadout/Body/Character/Portrait")
	var items: VBoxContainer = panel.get_node("Panel/Content/Columns/RightColumn/Scroll/Items")
	var compare: Label = panel.get_node("Panel/Content/Columns/RightColumn/Compare/Comparison/CompareBody")
	var equipped_ring: Button = panel.get_node("Panel/Content/Columns/Loadout/Body/Slots/SlotRing")
	if root.gui_get_focus_owner() != equipped_ring or equipped_ring.get_theme_stylebox("focus") == null:
		_fail("Equipment should focus the equipped slot with the visible Neon focus treatment")
		return
	await _send_key(KEY_UP)
	var keyboard_focus := root.gui_get_focus_owner()
	if keyboard_focus == equipped_ring or keyboard_focus == null:
		_fail("Keyboard navigation should move focus across equipment slots")
		return
	await _send_gamepad(JOY_BUTTON_DPAD_UP)
	var gamepad_focus := root.gui_get_focus_owner()
	if gamepad_focus == keyboard_focus or gamepad_focus == null:
		_fail("Gamepad D-pad should move focus across equipment slots")
		return
	if slots.get_child_count() != 6 or portrait.texture == null or panel_frame.custom_minimum_size != Vector2(600, 326):
		_fail("Equipment screen should show a schematic character and all six slots")
		return
	if panel.inventory_item_count() != 2:
		_fail("The selected slot should show only its two compatible items (got %d)" % panel.inventory_item_count())
		return
	panel.set_selected_slot("boots")
	await process_frame
	var boot_buttons := []
	for child in items.get_children():
		if child is Control and child.name.begins_with("Equipment_"):
			boot_buttons.append(child)
	if boot_buttons.size() != 2 or not items.has_node("Equipment_boots-old") or not items.has_node("Equipment_boots-new") or items.has_node("Equipment_ring-equipped"):
		_fail("The loadout list should filter incompatible slots: %s" % str(items.get_children().map(func(child: Node) -> String: return child.name)))
		return
	var old_button: Button = items.get_node("Equipment_boots-old/ItemRow/Preview")
	old_button.pressed.emit()
	await process_frame
	if not compare.text.contains("CRIT CHANCE") or not compare.text.contains("MOVE SPEED") or \
			not compare.text.contains("→") or items.get_child_count() != 5:
		_fail("Selecting the equipped item should produce a zero-change preview and removal action (%s, %d)" % [compare.text, items.get_child_count()])
		return
	var requests: Array[String] = []
	panel.equipment_state_requested.connect(func(instance_id: String, equipped: bool) -> void:
		requests.append("%s:%s" % [instance_id, str(equipped)])
	)
	(items.get_child(4) as Button).pressed.emit()
	if requests != ["boots-old:false"]:
		_fail("Removing a piece should request only its current slot item (got %s)" % str(requests))
		return
	panel.set_selected_slot("ring")
	await process_frame
	if panel.inventory_item_count() != 2:
		_fail("Selecting another slot should refresh compatible items (%d)" % panel.inventory_item_count())
		return
	panel.set_selected_slot("boots")
	await process_frame
	var new_button: Button = items.get_node("Equipment_boots-new/ItemRow/Preview")
	new_button.pressed.emit()
	await process_frame
	if not compare.text.contains("MOVE SPEED") or not compare.text.contains("→") or not compare.text.contains("(+" ):
		_fail("Candidate preview should show before, after and positive/negative deltas")
		return
	var equip_action: Button = items.get_child(items.get_child_count() - 1) as Button
	if equip_action.text != "EQUIP SELECTED ITEM":
		_fail("A selected candidate should require explicit equip confirmation")
		return
	equip_action.pressed.emit()
	if requests.back() != "boots-new:true":
		_fail("Equipping should request the selected compatible item")
		return
	var management: Button = panel.get_node("Panel/Content/Columns/RightColumn/ItemHeader/ManagementButton")
	management.pressed.emit()
	await process_frame
	if not items.has_node("Equipment_boots-new"):
		_fail("Existing enhancement, effect, sale and dismantle management must remain accessible")
		return
	var management_row: Control = items.get_node("Equipment_boots-new")
	var management_text := ""
	for child in management_row.find_children("*", "Label", true, false):
		management_text += (child as Label).text + "\n"
	if not management_text.contains("UNIQUE: LIGHTNING BURST"):
		_fail("Detailed management should retain readable unique effect information")
		return
	if management_row.get_theme_stylebox("panel") == null:
		_fail("Management rows should keep the rarity edge treatment")
		return
	var original_size: Vector2i = root.size
	for viewport_size in [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = viewport_size
		await process_frame
		if not Rect2(Vector2.ZERO, root.get_visible_rect().size).encloses(panel_frame.get_global_rect()):
			_fail("Equipment screen should fit viewport %s" % viewport_size)
			return
		if viewport_size == Vector2i(640, 360) and "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png("/tmp/dopamine-equipment.png") != OK:
				_fail("Could not capture the 640x360 equipment screen")
				return
	root.size = original_size
	panel.present({"equipment_inventory": [], "resources": {}})
	var empty: Label = panel.get_node("Panel/Content/Columns/RightColumn/Scroll/Items/EmptyState")
	if not empty.visible:
		_fail("An empty equipment slot should have a visible empty state")
		return
	panel.present_error()
	var error: Label = panel.get_node("Panel/Content/Columns/RightColumn/Scroll/Items/ErrorState")
	if empty.visible or not error.visible:
		_fail("The equipment error state should be distinct")
		return
	panel.queue_free()
	await process_frame
	print("Equipment loadout visual smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _send_key(keycode: Key) -> void:
	var key_event := InputEventKey.new()
	key_event.keycode = keycode
	key_event.physical_keycode = keycode
	key_event.pressed = true
	Input.parse_input_event(key_event)
	await process_frame
	key_event.pressed = false
	Input.parse_input_event(key_event)
	await process_frame

func _send_gamepad(button_index: JoyButton) -> void:
	var button_event := InputEventJoypadButton.new()
	button_event.device = 0
	button_event.button_index = button_index
	button_event.pressed = true
	Input.parse_input_event(button_event)
	await process_frame
	button_event.pressed = false
	Input.parse_input_event(button_event)
	await process_frame
