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
			"stat_lines": [],
			"equipped": false,
		}],
		"resources": {},
	})
	await process_frame
	var panel_frame: Control = panel.get_node("Panel")
	var row: Control = panel.get_node("Panel/Content/Scroll/Items/Equipment_visual-fixture")
	var row_style := row.get_theme_stylebox("panel") as StyleBoxFlat
	if panel_frame.custom_minimum_size.x < 400:
		_fail("Equipment panel should reserve enough width for item stats and actions")
		return
	if row_style == null or row_style.border_color.to_html(false) != "ffd447" or row_style.border_width_left < 3:
		_fail("Equipment rows should use the rarity color as a strong left edge")
		return
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
