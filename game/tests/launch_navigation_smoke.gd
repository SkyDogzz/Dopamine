extends SceneTree

const LAUNCH_SCENE_PATH := "res://scenes/launch_menu.tscn"
const MENU_PATH := "Content/Columns/MenuPanel/Menu"

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
	if launch_menu.get_node_or_null("Content/Columns/MenuPanel") == null or \
		launch_menu.get_node_or_null("Content/Columns/Identity") == null:
		_fail("The title screen should place its vertical menu column beside the game identity")
		return
	if launch_menu.get_node_or_null("SkylineLights") == null:
		_fail("The title skyline should include its neon signage layer")
		return
	var menu_music := launch_menu.get_node_or_null("MenuMusic") as AudioStreamPlayer
	if menu_music == null or menu_music.bus != "Music" or menu_music.stream == null:
		_fail("The launch menu should route its original theme through the Music bus")
		return
	var hub_route := Callable(launch_menu, "_open_survival_hub")
	root.add_child(launch_menu)
	await process_frame
	var menu_stream := menu_music.stream as AudioStreamWAV
	if not menu_music.playing or menu_stream == null or menu_stream.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		_fail("The launch theme should play as a loop while the menu is open")
		return
	if launch_menu.play_requested.is_connected(hub_route):
		launch_menu.play_requested.disconnect(hub_route)
	var skyline_lights: Control = launch_menu.get_node("SkylineLights")
	var initial_blink_step := int(skyline_lights.get("_last_blink_step"))
	await create_timer(0.2).timeout
	if int(skyline_lights.get("_last_blink_step")) <= initial_blink_step:
		_fail("Neon skyline signage should animate while the launch menu is open")
		return
	for control_name in ["PlayButton", "OptionsButton", "QuitButton", "SandboxButton", "SandboxLabButton"]:
		var button := launch_menu.get_node_or_null("%s/%s" % [MENU_PATH, control_name]) as Button
		if button == null or button.focus_mode == Control.FOCUS_NONE:
			_fail("Launch menu should expose a focusable %s" % control_name)
			return
	var play_button := launch_menu.get_node("%s/PlayButton" % MENU_PATH) as Button
	if root.gui_get_focus_owner() != play_button:
		_fail("Play should receive the initial menu focus")
		return
	var dpad_down := InputEventJoypadButton.new()
	dpad_down.device = 0
	dpad_down.button_index = JOY_BUTTON_DPAD_DOWN
	dpad_down.pressed = true
	Input.parse_input_event(dpad_down)
	await process_frame
	dpad_down.pressed = false
	Input.parse_input_event(dpad_down)
	var options_button := launch_menu.get_node("%s/OptionsButton" % MENU_PATH) as Button
	if root.gui_get_focus_owner() != options_button:
		_fail("A gamepad D-pad press should move focus from Play to Options")
		return
	var play_requests := [0]
	launch_menu.play_requested.connect(func(): play_requests[0] += 1)
	play_button.pressed.emit()
	if play_requests[0] != 1:
		_fail("Play should emit the hub navigation request")
		return
	var enter_key := InputEventKey.new()
	enter_key.keycode = KEY_ENTER
	enter_key.pressed = true
	Input.parse_input_event(enter_key)
	await process_frame
	enter_key.pressed = false
	Input.parse_input_event(enter_key)
	await process_frame
	var options_panel := launch_menu.get_node_or_null("OptionsPanel")
	if options_panel == null:
		_fail("Enter should activate the focused Options button")
		return
	var back_button := options_panel.get_node_or_null("Content/Center/OptionsCard/OptionsContent/BackButton") as Button
	if back_button == null:
		_fail("Options panel should expose its Back action")
		return
	var cancel_b := InputEventJoypadButton.new()
	cancel_b.device = 0
	cancel_b.button_index = JOY_BUTTON_B
	cancel_b.pressed = true
	Input.parse_input_event(cancel_b)
	await process_frame
	cancel_b.pressed = false
	Input.parse_input_event(cancel_b)
	await process_frame
	if launch_menu.get_node_or_null("OptionsPanel") != null:
		_fail("A gamepad B press should close Options")
		return
	if root.gui_get_focus_owner() != options_button:
		_fail("Closing Options should restore focus to its launch button")
		return
	var quit_button := launch_menu.get_node("%s/QuitButton" % MENU_PATH) as Button
	var quit_connections := quit_button.pressed.get_connections()
	if quit_connections.size() != 1 or quit_connections[0]["callable"].get_method() != "_on_quit_pressed":
		_fail("Quit should be connected to the native application close action")
		return
	var sandbox_button := launch_menu.get_node("%s/SandboxButton" % MENU_PATH) as Button
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
	var menu_panel := current_scene.get_node("Content/Columns/MenuPanel") as Control
	var identity := current_scene.get_node("Content/Columns/Identity") as Control
	var logical_viewport: Rect2 = current_scene.get_viewport_rect()
	var menu_rect := menu_panel.get_global_rect()
	var identity_rect := identity.get_global_rect()
	if menu_rect.position.x >= logical_viewport.size.x * 0.1 or identity_rect.position.x <= menu_rect.end.x or \
		not logical_viewport.encloses(menu_rect) or not logical_viewport.encloses(identity_rect):
		_fail("Launch menu should place its vertical menu at the left of the identity area: %s / %s" % [menu_rect, identity_rect])
		return
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png("/tmp/dopamine-launch-menu.png") != OK:
			_fail("Could not capture the launch menu render")
			return
	var sandbox_lab_button := current_scene.get_node("%s/SandboxLabButton" % MENU_PATH) as Button
	sandbox_lab_button.pressed.emit()
	await process_frame
	await process_frame
	if current_scene == null or current_scene.scene_file_path != "res://scenes/sandbox_lab.tscn":
		_fail("The separate Sandbox Lab button should open the player Lab scene")
		return
	print("Launch menu controls, initial focus and hub navigation contract passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
