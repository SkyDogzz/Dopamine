extends SceneTree

const LAUNCH_SCENE_PATH := "res://scenes/launch_menu.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ResourceLoader.exists(LAUNCH_SCENE_PATH):
		_fail("Launch menu scene is missing")
		return
	var launch_menu := load(LAUNCH_SCENE_PATH).instantiate() as Control
	if launch_menu == null:
		_fail("Launch menu should instantiate as a Control")
		return
	root.add_child(launch_menu)
	await process_frame
	for control_name in ["PlayButton", "OptionsButton", "QuitButton", "SandboxButton"]:
		var button := launch_menu.get_node_or_null("Content/Card/Columns/Menu/%s" % control_name) as Button
		if button == null or button.focus_mode == Control.FOCUS_NONE:
			_fail("Launch menu should expose a focusable %s" % control_name)
			return
	var play_button := launch_menu.get_node("Content/Card/Columns/Menu/PlayButton") as Button
	if root.gui_get_focus_owner() != play_button:
		_fail("Play should receive the initial menu focus")
		return
	var play_requests := [0]
	launch_menu.play_requested.connect(func(): play_requests[0] += 1)
	play_button.pressed.emit()
	if play_requests[0] != 1:
		_fail("Play should emit the hub navigation request")
		return
	var options_button := launch_menu.get_node("Content/Card/Columns/Menu/OptionsButton") as Button
	options_button.pressed.emit()
	await process_frame
	var options_panel := launch_menu.get_node_or_null("OptionsPanel")
	if options_panel == null:
		_fail("Options should open from the launch menu")
		return
	var back_button := options_panel.get_node_or_null("Content/Center/OptionsCard/OptionsContent/BackButton") as Button
	if back_button == null:
		_fail("Options panel should expose its Back action")
		return
	back_button.pressed.emit()
	await process_frame
	await process_frame
	if launch_menu.get_node_or_null("OptionsPanel") != null:
		_fail("Back should close Options")
		return
	if root.gui_get_focus_owner() != options_button:
		_fail("Closing Options should restore focus to its launch button")
		return
	print("Launch menu controls, initial focus and hub navigation contract passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
