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
const EVIDENCE_DIR := "res://../docs/art/evidence/2026-10-18/states"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var panel: Control = load("res://scenes/equipment_inventory_panel.tscn").instantiate()
	root.add_child(panel)
	panel.present({"equipment_inventory": EQUIPMENT, "resources": {"essence": 12}})
	await process_frame
	var panel_frame: Control = panel.get_node("Panel")
	var slots: HBoxContainer = panel.get_node("Panel/Content/Columns/Loadout/Body/Slots")
	var portrait: TextureRect = panel.get_node("Panel/Content/Columns/Loadout/Body/Slots/Portrait")
	var items: GridContainer = panel.get_node("Panel/Content/Columns/RightColumn/Scroll/Items")
	var compare: Label = panel.get_node("Panel/Content/Columns/RightColumn/Compare/Comparison/CompareBody")
	var equipped_ring: Button = panel.get_node("Panel/Content/Columns/Loadout/Body/Slots/RightSlots/SlotRing")
	if root.gui_get_focus_owner() != equipped_ring or equipped_ring.get_theme_stylebox("focus") == null:
		_fail("Equipment should focus the equipped slot with the visible Neon focus treatment")
		return
	await _send_key(KEY_UP)
	var keyboard_focus := root.gui_get_focus_owner()
	if keyboard_focus == equipped_ring or keyboard_focus == null:
		_fail("Keyboard navigation should move focus across equipment slots")
		return
	await _send_gamepad(JOY_BUTTON_DPAD_DOWN)
	var gamepad_focus := root.gui_get_focus_owner()
	if gamepad_focus == keyboard_focus or gamepad_focus == null:
		_fail("Gamepad D-pad should move focus across equipment slots")
		return
	if slots.find_children("*", "Button", true, false).size() != 6 or portrait.texture == null or \
		panel_frame.get_global_rect().size.x > root.size.x or panel_frame.get_global_rect().size.y > root.size.y or \
		panel_frame.custom_minimum_size.x > root.size.x - 32.0 or panel_frame.custom_minimum_size.y > root.size.y - 32.0:
		_fail("Equipment screen should show a central character with six surrounding equipment slots")
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
	for slot in ["helmet", "armor", "gloves", "boots", "amulet", "ring"]:
		panel.set_selected_slot(slot)
		await process_frame
		var expected_count := 0
		for equipment in EQUIPMENT:
			if str(equipment["slot"]) == slot:
				expected_count += 1
		if panel.inventory_item_count() != expected_count:
			_fail("The %s slot should show only its %d compatible items" % [slot, expected_count])
			return
	panel.set_selected_slot("boots")
	await process_frame
	var old_button: Button = items.get_node("Equipment_boots-old/CardContent/ItemRow/Preview")
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
	var new_button: Button = items.get_node("Equipment_boots-new/CardContent/ItemRow/Preview")
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
	var inventory_scroll: ScrollContainer = panel.get_node("Panel/Content/Columns/RightColumn/Scroll")
	var right_column: Control = panel.get_node("Panel/Content/Columns/RightColumn")
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
	var original_management_size := root.size
	for viewport_size in [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = viewport_size
		await process_frame
		var viewport_bounds := Rect2(Vector2.ZERO, Vector2(viewport_size))
		if not viewport_bounds.encloses(panel_frame.get_global_rect()) or \
			not panel_frame.get_global_rect().encloses(right_column.get_global_rect()) or \
			not right_column.get_global_rect().encloses(inventory_scroll.get_global_rect()):
			_fail("Equipment Details and its scroll viewport should fit %s" % viewport_size)
			return
		if viewport_size == Vector2i(640, 360) and inventory_scroll.get_v_scroll_bar().max_value <= 0.0:
			_fail("Dense equipment Details should expose vertical scrolling at 640x360")
			return
		if viewport_size == Vector2i(640, 360) and "--capture-details" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			var details_path := ProjectSettings.globalize_path(EVIDENCE_DIR + "/equipment-details.png")
			if root.get_texture().get_image().save_png(details_path) != OK:
				_fail("Could not capture 640x360 equipment Details state")
				return
	root.size = original_management_size
	await process_frame
	if "--capture-sell-confirmation" in OS.get_cmdline_user_args():
		var sell_button := _find_button_with_prefix(management_row, "SELL  •")
		if sell_button == null:
			_fail("Equipment Details should expose the sale confirmation action")
			return
		sell_button.pressed.emit()
		await process_frame
		var sell_confirmation: Control = panel.get_node("SellConfirmation")
		var sell_description: Label = sell_confirmation.get_node("Center/Panel/Content/Description")
		if not sell_confirmation.visible or not sell_description.text.contains("CANNOT BE UNDONE") or \
			root.gui_get_focus_owner() != sell_confirmation.get_node("Center/Panel/Content/Actions/CancelButton"):
			_fail("Sale should show its explicit irreversible-action confirmation")
			return
		await _send_key(KEY_ESCAPE)
		if sell_confirmation.visible:
			_fail("Escape should close sale confirmation without executing the sale")
			return
		sell_button.pressed.emit()
		await process_frame
		var confirmation_panel: Control = sell_confirmation.get_node("Center/Panel")
		var original_confirmation_size: Vector2i = root.size
		for viewport_size in [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1920, 1080)]:
			root.size = viewport_size
			await process_frame
			if not Rect2(Vector2.ZERO, Vector2(viewport_size)).encloses(confirmation_panel.get_global_rect()):
				_fail("Sale confirmation should fit viewport %s" % viewport_size)
				return
			if root.gui_get_focus_owner() != sell_confirmation.get_node("Center/Panel/Content/Actions/CancelButton"):
				_fail("Viewport changes should preserve the safe initial sale confirmation focus")
				return
		root.size = original_confirmation_size
		await process_frame
		await RenderingServer.frame_post_draw
		var confirmation_path := ProjectSettings.globalize_path(EVIDENCE_DIR + "/equipment-sell-confirmation.png")
		if root.get_texture().get_image().save_png(confirmation_path) != OK:
			_fail("Could not capture the equipment sale confirmation")
			return
		sell_confirmation.get_node("Center/Panel/Content/Actions/CancelButton").pressed.emit()
		if sell_confirmation.visible:
			_fail("Cancel button should close sale confirmation without executing the sale")
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
	panel.present({"equipment_inventory": [EQUIPMENT[0]], "resources": {}})
	panel.set_selected_slot("boots")
	await process_frame
	if not empty.visible or error.visible or \
			panel.get_node("Panel/Content/Columns/RightColumn/Compare/Comparison/CompareBody").text != "No item fits this slot.":
		_fail("A slot without compatible inventory should show an explicit empty result and no-change preview")
		return
	if "--capture-states" in OS.get_cmdline_user_args():
		var save_service = load("res://scripts/save_service.gd").new("user://equipment_panel_visual_smoke_context")
		var progression = load("res://scripts/progression_service.gd").new(save_service, "0")
		var hub: Control = load("res://scenes/survival_hub.tscn").instantiate()
		hub.progression_service = progression
		root.add_child(hub)
		await process_frame
		root.remove_child(panel)
		hub.add_child(panel)
		await process_frame
		if not await _save_evidence("equipment-no-compatible"):
			return
		hub.remove_child(panel)
		root.add_child(panel)
		hub.queue_free()
		await process_frame
	error.visible = false
	panel.show_feedback("ACTION FAILED: profile unavailable")
	var feedback: Label = panel.get_node("Panel/Content/Feedback")
	if not feedback.visible or feedback.text != "ACTION FAILED: profile unavailable":
		_fail("Equipment action failures should use the visible feedback banner")
		return
	panel.queue_free()
	await process_frame
	print("Equipment loadout visual smoke passed")
	quit()

func _save_evidence(evidence_id: String) -> bool:
	await RenderingServer.frame_post_draw
	var output_dir := ProjectSettings.globalize_path(EVIDENCE_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var path := output_dir.path_join("%s.png" % evidence_id)
	if root.get_texture().get_image().save_png(path) != OK:
		_fail("Could not save equipment state evidence: %s" % path)
		return false
	print("Equipment state evidence capture: %s" % path)
	return true

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _find_button_with_prefix(node: Node, prefix: String) -> Button:
	if node is Button and (node as Button).text.begins_with(prefix):
		return node as Button
	for child in node.get_children():
		var found := _find_button_with_prefix(child, prefix)
		if found != null:
			return found
	return null

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
