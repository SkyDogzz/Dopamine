extends SceneTree

var _session: Node2D
var _gamepad := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_gamepad = "--gamepad" in OS.get_cmdline_user_args()
	var menu: Control = load("res://scenes/launch_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	var play: Button = menu.get_node("Content/Columns/MenuPanel/Menu/PlayButton")
	var options: Button = menu.get_node("Content/Columns/MenuPanel/Menu/OptionsButton")
	if root.gui_get_focus_owner() != play:
		_fail("Launch menu should focus Play")
		return
	await _down()
	if root.gui_get_focus_owner() != options:
		_fail("Input should move focus from Play to Options")
		return
	await _confirm()
	if menu.get_node_or_null("OptionsPanel") == null:
		_fail("Input should open launch Options")
		return
	await _cancel()
	if menu.get_node_or_null("OptionsPanel") != null or root.gui_get_focus_owner() != options:
		_fail("Cancel should close launch Options and restore focus")
		return
	await _up()
	if root.gui_get_focus_owner() != play:
		_fail("Input should return focus to Play")
		return
	await _confirm()
	await _wait_scene("res://scenes/survival_hub.tscn")
	if current_scene == null or current_scene.scene_file_path != "res://scenes/survival_hub.tscn":
		_fail("Input confirmation should open the Survival hub")
		return
	var hub: Control = current_scene
	var launch: Button = hub.get_node("Content/Main/PreparationCard/Body/LaunchButton")
	if root.gui_get_focus_owner() != launch:
		_fail("The Survival hub should focus its launch action")
		return
	await _confirm()
	await _wait_for_session()
	if _session == null or not _session._starting_weapon_choice_open:
		_fail("Input confirmation should reach the starting weapon choice")
		return
	var starting_choice: Control = _session.get_node("HUD/ChestOverlay/ChestChoice")
	var first_option: Button = starting_choice.get_node("Content/Options/Choice0")
	await _down()
	var selected_start := root.gui_get_focus_owner() as Button
	if selected_start == null or selected_start == first_option or not _has_visible_focus(selected_start):
		_fail("Input should move between starting weapon options and show the focus ring")
		return
	var selected_start_title := str(selected_start.get_node("ContentMargin/OfferRow/OfferDetails/OfferTitle").text)
	await _confirm()
	await _wait_for_unpaused_run()
	var expected_start_id := "lightning_conductor" if selected_start_title == "Lightning Conductor" else "inferno_sprayer"
	var other_start_id := "inferno_sprayer" if expected_start_id == "lightning_conductor" else "lightning_conductor"
	if _session.loadout.weapon_level(expected_start_id) != 1 or _session.loadout.weapon_level(other_start_id) != 0:
		_fail("Input confirmation should equip exactly one starting weapon")
		return
	if not _session.open_chest_family("weapon"):
		_fail("Run should provide a weapon chest choice for the keyboard journey")
		return
	var choice: Control = _session.get_node("HUD/ChestOverlay/ChestChoice")
	var chest_first: Button = choice.get_node("Content/Options/Choice0")
	if root.gui_get_focus_owner() != chest_first:
		_fail("A weapon chest should focus its first choice")
		return
	await _down()
	var selected_chest := root.gui_get_focus_owner() as Button
	if selected_chest == null or selected_chest == chest_first or selected_chest.name != "Choice1" or \
			not _has_visible_focus(selected_chest):
		_fail("Input should move focus between chest options and show the focus ring")
		return
	var selected_chest_id := str(_session._active_chest_options[1].get("id", ""))
	await _confirm()
	if _session._chest_open or _session.loadout.weapon_level(selected_chest_id.trim_prefix("weapon:")) == 0:
		_fail("Input confirmation should collect the focused chest option")
		return
	await _cancel()
	var pause: Control = _session.get_node("HUD/PauseOverlay")
	if not pause.visible or not _session.simulation.snapshot()["paused"]:
		_fail("Cancel should open Pause and freeze the run")
		return
	var options_button: Button = pause.get_node("Center/Panel/Content/OptionsButton")
	await _down()
	if root.gui_get_focus_owner() != options_button:
		_fail("Input should navigate from Resume to pause Options")
		return
	await _confirm()
	var paused_time := float(_session.simulation.snapshot()["simulation_time"])
	if _session.get_node_or_null("HUD/OptionsPanel") == null:
		_fail("Input should open Options over Pause")
		return
	await _cancel()
	if _session.get_node_or_null("HUD/OptionsPanel") != null or not pause.visible or \
			root.gui_get_focus_owner() != options_button or not _session.simulation.snapshot()["paused"] or \
			not is_equal_approx(float(_session.simulation.snapshot()["simulation_time"]), paused_time):
		_fail("Closing Options should restore Pause without advancing simulation")
		return
	var inventory_button: Button = pause.get_node("Center/Panel/Content/InventoryButton")
	await _down()
	if root.gui_get_focus_owner() != inventory_button:
		_fail("Keyboard should navigate from Options to the run inventory")
		return
	await _confirm()
	if _session.get_node_or_null("HUD/RunInventoryPanel") == null:
		_fail("Keyboard should open the read-only run inventory")
		return
	await _cancel()
	if _session.get_node_or_null("HUD/RunInventoryPanel") != null or \
			root.gui_get_focus_owner() != inventory_button or not _session.simulation.snapshot()["paused"]:
		_fail("Cancel should close inventory and return to the frozen Pause menu")
		return
	await _cancel()
	if pause.visible or _session.simulation.snapshot()["paused"]:
		_fail("Escape should resume the same run from Pause")
		return
	print("%s launch-to-run journey passed (starting=%s)" % ["Gamepad" if _gamepad else "Keyboard", expected_start_id])
	_session.queue_free()
	await process_frame
	_session = null
	current_scene = null
	await process_frame
	quit(0)

func _wait_scene(path: String) -> void:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == path:
			return

func _wait_for_session() -> void:
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == "res://scenes/survival_session.tscn":
			_session = current_scene
			return

func _wait_for_unpaused_run() -> void:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if _session != null and not _session.simulation.snapshot()["paused"]:
			return

func _down() -> void:
	await _send_input(KEY_DOWN, JOY_BUTTON_DPAD_DOWN)

func _up() -> void:
	await _send_input(KEY_UP, JOY_BUTTON_DPAD_UP)

func _confirm() -> void:
	await _send_input(KEY_ENTER, JOY_BUTTON_A)

func _cancel() -> void:
	await _send_input(KEY_ESCAPE, JOY_BUTTON_B)

func _send_input(keycode: Key, joy_button: JoyButton) -> void:
	if _gamepad:
		var button_event := InputEventJoypadButton.new()
		button_event.device = 0
		button_event.button_index = joy_button
		button_event.pressed = true
		Input.parse_input_event(button_event)
		await process_frame
		button_event.pressed = false
		Input.parse_input_event(button_event)
		await process_frame
		return
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _has_visible_focus(control: Control) -> bool:
	var focus_style := control.get_theme_stylebox("focus")
	if focus_style is StyleBoxFlat:
		return focus_style.border_width_left > 0 or focus_style.border_width_top > 0 or \
				focus_style.border_width_right > 0 or focus_style.border_width_bottom > 0
	return focus_style != null

func _fail(message: String) -> void:
	push_error(message)
	if is_instance_valid(_session):
		_session.queue_free()
	quit(1)
