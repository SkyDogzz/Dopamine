extends SceneTree

const OPTIONS_SCENE_PATH := "res://scenes/options_panel.tscn"
const THEME_PATH := "res://themes/dopamine_ui.tres"

var _settings: SettingsService

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_settings = root.get_node("Settings") as SettingsService
	_settings.set_fullscreen_enabled(false)
	_settings.set_master_volume_percent(100.0)
	if not ResourceLoader.exists(OPTIONS_SCENE_PATH):
		_fail("Options panel scene is missing")
		return
	var packed_scene: PackedScene = load(OPTIONS_SCENE_PATH)
	if packed_scene == null:
		_fail("Options panel scene could not be loaded")
		return
	var panel := packed_scene.instantiate() as Control
	if panel == null:
		_fail("Options panel root should be a Control")
		return
	root.add_child(panel)
	await process_frame
	var shared_theme: Theme = load(THEME_PATH)
	if shared_theme == null or panel.theme != shared_theme:
		_fail("Options panel should use the shared UI Theme")
		return
	for node_path in [
		"Content/Center/OptionsCard/OptionsContent/DisplayTitle",
		"Content/Center/OptionsCard/OptionsContent/DisplayDivider",
		"Content/Center/OptionsCard/OptionsContent/FullscreenToggle",
		"Content/Center/OptionsCard/OptionsContent/VolumeRow/VolumeSlider",
		"Content/Center/OptionsCard/OptionsContent/VolumeRow/VolumeValue",
		"Content/Center/OptionsCard/OptionsContent/BackButton",
	]:
		if panel.get_node_or_null(node_path) == null:
			_fail("Options panel is missing control: %s" % node_path)
			return
	var fullscreen_toggle := panel.get_node("Content/Center/OptionsCard/OptionsContent/FullscreenToggle") as CheckButton
	var volume_slider := panel.get_node("Content/Center/OptionsCard/OptionsContent/VolumeRow/VolumeSlider") as HSlider
	var volume_value := panel.get_node("Content/Center/OptionsCard/OptionsContent/VolumeRow/VolumeValue") as Label
	var back_button := panel.get_node("Content/Center/OptionsCard/OptionsContent/BackButton") as Button
	var options_card := panel.get_node("Content/Center/OptionsCard") as Control
	var display_title := panel.get_node("Content/Center/OptionsCard/OptionsContent/DisplayTitle") as Label
	var display_divider := panel.get_node("Content/Center/OptionsCard/OptionsContent/DisplayDivider") as HSeparator
	var options_content := panel.get_node("Content/Center/OptionsCard/OptionsContent") as VBoxContainer
	if display_title.theme_type_variation != "PixelHeading" or \
		display_title.get_theme_color("font_color").to_html(false) != "37e8f5" or \
		display_divider.get_index() <= display_title.get_index() or \
		options_content.get_node("FullscreenToggle").get_index() <= display_title.get_index() or \
		options_content.get_node("VolumeTitle").get_index() <= display_divider.get_index():
		_fail("Options should separate the display section from audio controls with the shared pixel heading style")
		return
	if fullscreen_toggle == null or fullscreen_toggle.focus_mode == Control.FOCUS_NONE:
		_fail("Fullscreen setting should be focusable")
		return
	if volume_slider.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_fail("The volume slider should preserve its pixel-grid handle texture")
		return
	var slider_focus := volume_slider.get_theme_stylebox("focus") as StyleBoxFlat
	if slider_focus == null or slider_focus.bg_color.to_html(false) != "1b2340" or \
		slider_focus.border_color.to_html(false) != "ffd447" or slider_focus.border_width_left < 2:
		_fail("The volume slider should use the shared visible gold focus style")
		return
	if root.gui_get_focus_owner() != fullscreen_toggle:
		_fail("Fullscreen setting should receive initial focus")
		return
	volume_slider.value = 42.0
	await process_frame
	if _settings.master_volume_percent != 42.0 or volume_value.text != "42%":
		_fail("Volume slider should update Settings and show its percentage")
		return
	fullscreen_toggle.toggled.emit(true)
	await process_frame
	if not _settings.fullscreen_enabled:
		_fail("Fullscreen toggle should update Settings")
		return
	for action_name in ["ui_accept", "ui_cancel", "ui_up", "ui_down", "ui_left", "ui_right"]:
		if not InputMap.has_action(action_name):
			_fail("Standard UI action is missing: %s" % action_name)
			return
	var accept_a_found := false
	var cancel_b_found := false
	for input_event in InputMap.action_get_events("ui_accept"):
		if input_event is InputEventJoypadButton and input_event.button_index == JOY_BUTTON_A:
			accept_a_found = true
	for input_event in InputMap.action_get_events("ui_cancel"):
		if input_event is InputEventJoypadButton and input_event.button_index == JOY_BUTTON_B:
			cancel_b_found = true
	if not accept_a_found or not cancel_b_found:
		_fail("Standard UI accept/cancel actions should map to gamepad A/B")
		return
	for viewport_size in [Vector2i(1280, 800), Vector2i(960, 600), Vector2i(1600, 900)]:
		root.size = viewport_size
		await process_frame
		var card_rect := options_card.get_global_rect()
		if card_rect.position.x < 0.0 or card_rect.position.y < 0.0 or card_rect.end.x > viewport_size.x or card_rect.end.y > viewport_size.y:
			_fail("Options card should fit inside viewport %s" % viewport_size)
			return
	var close_signal_found := false
	for signal_info in panel.get_signal_list():
		if signal_info.name == "close_requested":
			close_signal_found = true
	if not close_signal_found:
		_fail("Options panel should request closure from its owner")
		return
	var close_requests := [0]
	panel.close_requested.connect(func(): close_requests[0] += 1)
	back_button.pressed.emit()
	if close_requests[0] != 1:
		_fail("Back button should request closure from its owner")
		return
	var cancel_event := InputEventJoypadButton.new()
	cancel_event.device = 0
	cancel_event.button_index = JOY_BUTTON_B
	cancel_event.pressed = true
	Input.parse_input_event(cancel_event)
	await process_frame
	cancel_event.pressed = false
	Input.parse_input_event(cancel_event)
	if close_requests[0] != 2:
		_fail("Gamepad B should request closure from its owner")
		return
	var reopened_panel := packed_scene.instantiate() as Control
	root.add_child(reopened_panel)
	await process_frame
	var reopened_toggle := reopened_panel.get_node("Content/Center/OptionsCard/OptionsContent/FullscreenToggle") as CheckButton
	var reopened_slider := reopened_panel.get_node("Content/Center/OptionsCard/OptionsContent/VolumeRow/VolumeSlider") as HSlider
	if not reopened_toggle.button_pressed or reopened_slider.value != 42.0:
		_fail("Reopened Options panel should reflect the latest stored preferences")
		return
	_settings.set_fullscreen_enabled(false)
	_settings.set_master_volume_percent(100.0)

	print("Options panel theme, controls, focus, preference updates and close contract passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
