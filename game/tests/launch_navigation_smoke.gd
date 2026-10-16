extends SceneTree

const LAUNCH_SCENE_PATH := "res://scenes/launch_menu.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if ProjectSettings.get_setting("application/run/main_scene") != LAUNCH_SCENE_PATH:
		_fail("The launch menu should be the project's main scene")
		return
	if not ResourceLoader.exists(LAUNCH_SCENE_PATH):
		_fail("Launch menu scene is missing")
		return
	var launch_menu := load(LAUNCH_SCENE_PATH).instantiate() as Control
	if launch_menu == null:
		_fail("Launch menu should instantiate as a Control")
		return
	var hub_route := Callable(launch_menu, "_open_survival_hub")
	if launch_menu.play_requested.is_connected(hub_route):
		launch_menu.play_requested.disconnect(hub_route)
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
	var quit_button := launch_menu.get_node("Content/Card/Columns/Menu/QuitButton") as Button
	var quit_connections := quit_button.pressed.get_connections()
	if quit_connections.size() != 1 or quit_connections[0]["callable"].get_method() != "_on_quit_pressed":
		_fail("Quit should be connected to the native application close action")
		return
	var sandbox_button := launch_menu.get_node("Content/Card/Columns/Menu/SandboxButton") as Button
	sandbox_button.pressed.emit()
	await process_frame
	await process_frame
	if current_scene == null or current_scene.scene_file_path != "res://scenes/main.tscn":
		_fail("The discrete Sandbox entry should open the existing developer scene")
		return
	var home_button := current_scene.get_node_or_null("Shell/Header/HomeButton") as Button
	if home_button == null or home_button.focus_mode == Control.FOCUS_NONE:
		_fail("The Sandbox should provide a focusable return to the home menu")
		return
	if root.gui_get_focus_owner() != home_button:
		_fail("The Sandbox return action should receive initial keyboard/gamepad focus")
		return
	home_button.pressed.emit()
	await process_frame
	await process_frame
	if current_scene == null or current_scene.scene_file_path != LAUNCH_SCENE_PATH:
		_fail("The Sandbox home action should return to the launch menu")
		return
	var card := current_scene.get_node("Content/Card") as Control
	var logical_viewport: Rect2 = current_scene.get_viewport_rect()
	var card_rect := card.get_global_rect()
	if card_rect.position.x < logical_viewport.position.x or card_rect.position.y < logical_viewport.position.y or \
		card_rect.end.x > logical_viewport.end.x or card_rect.end.y > logical_viewport.end.y:
		_fail("Launch menu card %s should fit inside logical viewport %s" % [card_rect, logical_viewport])
		return
	print("Launch menu controls, initial focus and hub navigation contract passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
