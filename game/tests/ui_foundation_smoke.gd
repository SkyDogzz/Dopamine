extends SceneTree

const PREVIEW_SCENE_PATH := "res://scenes/ui_foundation_preview.tscn"
const THEME_PATH := "res://themes/dopamine_ui.tres"
const PIXEL_HEADING_PATHS := {
	"res://scenes/launch_menu.tscn": ["Content/Columns/Identity/TitleRow/Title"],
	"res://scenes/options_panel.tscn": ["Content/Center/OptionsCard/OptionsContent/Title"],
	"res://scenes/survival_hub.tscn": ["Content/Header/Identity/Title", "Content/Main/DifficultyCard/Body/SectionTitle", "Content/Main/PreparationCard/Body/ModeTitle", "Content/Main/PreparationCard/Body/PreparationTitle"],
	"res://scenes/chest_choice.tscn": ["Content/Title"],
	"res://scenes/equipment_inventory_panel.tscn": ["Panel/Content/Title"],
	"res://scenes/skill_tree_panel.tscn": ["Panel/Content/Title"],
	"res://scenes/run_inventory_panel.tscn": ["Center/Panel/Content/Title"],
	"res://scenes/run_result_panel.tscn": ["Content/Title"],
	"res://scenes/pause_menu.tscn": ["Center/Panel/Content/Title", "ConfirmationOverlay/Center/Panel/Content/Title"],
	"res://scenes/main.tscn": ["Shell/Header/Title", "Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnTitle", "Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningTitle", "Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/InspectorTitle", "Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/StatusTitle", "Shell/Content/SidePanel/Sections/LogPanel/LogForm/LogTitle"],
	"res://scenes/ui_foundation_preview.tscn": ["Content/PreviewCenter/SamplePanel/SampleContent/Title", "Content/PreviewCenter/SamplePanel/SampleContent/ControlTitle"],
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ResourceLoader.exists(PREVIEW_SCENE_PATH):
		_fail("UI foundation preview scene is missing")
		return

	var packed_scene: PackedScene = load(PREVIEW_SCENE_PATH)
	if packed_scene == null:
		_fail("UI foundation preview scene could not be loaded")
		return

	var preview := packed_scene.instantiate() as Control
	if preview == null:
		_fail("UI foundation preview root should be a Control")
		return
	root.add_child(preview)
	await process_frame

	var shared_theme: Theme = load(THEME_PATH)
	if shared_theme == null or preview.theme != shared_theme:
		_fail("Preview should use the shared UI Theme")
		return
	if not shared_theme.has_font("font", "PixelHeading"):
		_fail("Shared Theme should provide the Art Bible pixel-heading font")
		return
	for scene_path in PIXEL_HEADING_PATHS:
		var heading_scene: Control = load(scene_path).instantiate()
		for node_path in PIXEL_HEADING_PATHS[scene_path]:
			var heading := heading_scene.get_node_or_null(node_path) as Label
			if heading == null or heading.theme_type_variation != "PixelHeading":
				_fail("%s/%s should use the PixelHeading variation" % [scene_path, node_path])
				return
		heading_scene.free()
	for color_name in ["background", "surface", "surface_hover", "text", "text_muted", "accent", "focus", "alert", "border"]:
		if not shared_theme.has_color(color_name, "Dopamine"):
			_fail("Shared Theme is missing semantic color: %s" % color_name)
			return
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		if not shared_theme.has_stylebox(style_name, "Button"):
			_fail("Shared Theme is missing Button style: %s" % style_name)
			return
	for style_name in ["normal", "focus", "disabled"]:
		if not shared_theme.has_stylebox(style_name, "LineEdit"):
			_fail("Shared Theme is missing LineEdit style: %s" % style_name)
			return
		if not shared_theme.has_stylebox(style_name, "SpinBox"):
			_fail("Shared Theme is missing SpinBox style: %s" % style_name)
			return
	if not shared_theme.has_stylebox("panel", "PanelContainer"):
		_fail("Shared Theme is missing PanelContainer surface style")
		return
	for scrollbar_type in ["VScrollBar", "HScrollBar"]:
		for style_name in ["scroll", "grabber", "grabber_highlight", "grabber_pressed"]:
			if not shared_theme.has_stylebox(style_name, scrollbar_type):
				_fail("Shared Theme is missing %s style: %s" % [scrollbar_type, style_name])
				return
	var scrollbar_grabber := shared_theme.get_stylebox("grabber", "VScrollBar") as StyleBoxFlat
	if scrollbar_grabber.bg_color.to_html(false) != "293354":
		_fail("Scrollbar grabbers should use the shared dark neon palette")
		return
	var scrollbar_focus := shared_theme.get_stylebox("scroll_focus", "VScrollBar") as StyleBoxFlat
	if scrollbar_focus.border_color.to_html(false) != "ffd447":
		_fail("Scrollbars should keep a visible gold keyboard/gamepad focus state")
		return
	for style_name in ["slider", "grabber_area", "grabber_area_highlight"]:
		if not shared_theme.has_stylebox(style_name, "HSlider"):
			_fail("Shared Theme is missing HSlider style: %s" % style_name)
			return
	var slider_track := shared_theme.get_stylebox("slider", "HSlider") as StyleBoxFlat
	var slider_fill := shared_theme.get_stylebox("grabber_area", "HSlider") as StyleBoxFlat
	if slider_track.bg_color.to_html(false) != "10152b" or slider_fill.bg_color.to_html(false) != "37e8f5":
		_fail("Slider track and filled value should use the shared neon palette")
		return
	var slider_grabber := shared_theme.get_icon("grabber", "HSlider") as GradientTexture2D
	var slider_grabber_hover := shared_theme.get_icon("grabber_highlight", "HSlider") as GradientTexture2D
	if slider_grabber == null or slider_grabber.width != 12 or slider_grabber.height != 12 or slider_grabber_hover == null:
		_fail("Slider handles should use compact pixel-grid theme textures")
		return
	if shared_theme.get_color("button_checked_color", "CheckButton").to_html(false) != "37e8f5" or \
		shared_theme.get_color("button_unchecked_color", "CheckButton").to_html(false) != "64708c":
		_fail("CheckButton on/off states should use the shared neon palette")
		return

	for node_name in [
		"Content/PreviewCenter/SamplePanel/SampleContent/Actions/PrimaryButton",
		"Content/PreviewCenter/SamplePanel/SampleContent/Actions/SecondaryButton",
		"Content/PreviewCenter/SamplePanel/SampleContent/Actions/DisabledButton",
		"Content/PreviewCenter/SamplePanel/SampleContent/Fields/SampleLineEdit",
		"Content/PreviewCenter/SamplePanel/SampleContent/Fields/SampleOptionButton",
		"Content/PreviewCenter/SamplePanel/SampleContent/Fields/SampleSpinBox",
		"Content/PreviewCenter/SamplePanel",
	]:
		if preview.get_node_or_null(node_name) == null:
			_fail("Preview is missing control: %s" % node_name)
			return

	var primary_button := preview.get_node("Content/PreviewCenter/SamplePanel/SampleContent/Actions/PrimaryButton") as Button
	if primary_button == null or primary_button.focus_mode == Control.FOCUS_NONE:
		_fail("Primary action should be keyboard/gamepad focusable")
		return
	if root.gui_get_focus_owner() != primary_button:
		_fail("Primary action should receive initial focus")
		return
	var primary_position := primary_button.position
	primary_button.emit_signal("button_down")
	if primary_button.position.y != primary_position.y + 2.0:
		_fail("Pressing a menu button should show a two-pixel downward offset")
		return
	primary_button.emit_signal("button_up")
	if primary_button.position != primary_position:
		_fail("Releasing a menu button should restore its layout position")
		return
	primary_button.emit_signal("mouse_entered")
	await process_frame
	await process_frame
	if primary_button.scale.x <= 1.0:
		_fail("Hovering a menu button should enlarge it slightly")
		return
	primary_button.emit_signal("mouse_exited")
	await process_frame
	await process_frame
	var mouse_click := InputEventMouseButton.new()
	mouse_click.button_index = MOUSE_BUTTON_LEFT
	mouse_click.position = primary_button.get_global_rect().get_center()
	mouse_click.pressed = true
	root.push_input(mouse_click, true)
	await process_frame
	mouse_click.pressed = false
	root.push_input(mouse_click, true)
	await process_frame
	var status_label := preview.get_node("Content/PreviewCenter/SamplePanel/SampleContent/Status") as Label
	if status_label.text != "PRIMARY ACTION ACTIVATED  •  LEVEL 3":
		_fail("Mouse click failed at local viewport coordinates %s" % mouse_click.position)
		return

	var preview_panel := preview.get_node("Content/PreviewCenter/SamplePanel") as Control
	for viewport_size in [Vector2i(1280, 800), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		root.size = viewport_size
		await process_frame
		var panel_rect := preview_panel.get_global_rect()
		if panel_rect.position.x < 0.0 or panel_rect.position.y < 0.0:
			_fail("Preview panel should remain inside the viewport at %s" % viewport_size)
			return
		if panel_rect.end.x > viewport_size.x or panel_rect.end.y > viewport_size.y:
			_fail("Preview panel should not overflow the viewport at %s" % viewport_size)
			return
	root.size = Vector2i(1280, 800)
	await process_frame
	var tab_event := InputEventKey.new()
	tab_event.keycode = KEY_TAB
	tab_event.physical_keycode = KEY_TAB
	tab_event.pressed = true
	Input.parse_input_event(tab_event)
	await process_frame
	var secondary_button := preview.get_node("Content/PreviewCenter/SamplePanel/SampleContent/Actions/SecondaryButton") as Button
	if root.gui_get_focus_owner() != secondary_button:
		_fail("Tab should move focus to the next enabled control")
		return
	tab_event.pressed = false
	Input.parse_input_event(tab_event)
	var gamepad_accept_mapping_found := false
	var gamepad_cancel_mapping_found := false
	for action_name in ["ui_accept", "ui_cancel", "ui_up", "ui_down", "ui_left", "ui_right"]:
		if not InputMap.has_action(action_name):
			_fail("Standard UI action is missing: %s" % action_name)
			return
		for input_event in InputMap.action_get_events(action_name):
			if action_name == "ui_accept" and input_event is InputEventJoypadButton and input_event.button_index == JOY_BUTTON_A:
				gamepad_accept_mapping_found = true
			if action_name == "ui_cancel" and input_event is InputEventJoypadButton and input_event.button_index == JOY_BUTTON_B:
				gamepad_cancel_mapping_found = true
	if not gamepad_accept_mapping_found or not gamepad_cancel_mapping_found:
		_fail("Standard UI accept/cancel actions should map to gamepad A/B")
		return

	print("UI foundation theme, preview controls, focus, viewport layout and keyboard/gamepad mappings passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
