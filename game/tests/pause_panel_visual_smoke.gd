extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var overlay: Control = load("res://scenes/pause_menu.tscn").instantiate()
	root.add_child(overlay)
	var panel: Control = overlay.get_node("Center/Panel")
	var confirmation: Control = overlay.get_node("ConfirmationOverlay/Center/Panel")
	if panel.custom_minimum_size.x < 240 or confirmation.custom_minimum_size.x < 260:
		_fail("Pause and abandon panels should provide room for their labels and controls")
		return
	if overlay.get_node_or_null("Center/Panel/Content/PausedStatus") == null or \
		overlay.get_node_or_null("Center/Panel/Content/SpeedLabel") == null:
		_fail("Pause should identify its frozen state and separate the speed control")
		return
	var resume := overlay.get_node("Center/Panel/Content/ResumeButton") as Button
	var abandon := overlay.get_node("Center/Panel/Content/AbandonButton") as Button
	var confirm_abandon := overlay.get_node("ConfirmationOverlay/Center/Panel/Content/ConfirmButton") as Button
	if resume.get_theme_color("font_color").to_html(false) != "37e8f5" or \
		abandon.get_theme_color("font_color").to_html(false) != "ff7181" or \
		confirm_abandon.get_theme_color("font_color").to_html(false) != "ff7181":
		_fail("Resume should read as the primary action and abandoning should use the danger accent")
		return
	for path in [
		"Center/Panel/Content/ResumeButton", "Center/Panel/Content/OptionsButton",
		"Center/Panel/Content/InventoryButton", "Center/Panel/Content/AbandonButton",
		"ConfirmationOverlay/Center/Panel/Content/CancelButton",
		"ConfirmationOverlay/Center/Panel/Content/ConfirmButton",
	]:
		var button := overlay.get_node(path) as Button
		if button.focus_mode == Control.FOCUS_NONE:
			_fail("Pause action should remain keyboard/gamepad focusable: %s" % path)
			return
	print("Pause panel visual hierarchy smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
