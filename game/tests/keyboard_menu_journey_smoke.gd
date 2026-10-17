extends SceneTree

var _session: Node2D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var menu: Control = load("res://scenes/launch_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	var play: Button = menu.get_node("Content/Columns/MenuPanel/Menu/PlayButton")
	var options: Button = menu.get_node("Content/Columns/MenuPanel/Menu/OptionsButton")
	if root.gui_get_focus_owner() != play:
		_fail("Launch menu should focus Play")
		return
	await _key(KEY_DOWN)
	if root.gui_get_focus_owner() != options:
		_fail("Keyboard should move focus from Play to Options")
		return
	await _key(KEY_ENTER)
	if menu.get_node_or_null("OptionsPanel") == null:
		_fail("Keyboard should open launch Options")
		return
	await _key(KEY_ESCAPE)
	if menu.get_node_or_null("OptionsPanel") != null or root.gui_get_focus_owner() != options:
		_fail("Escape should close launch Options and restore focus")
		return
	await _key(KEY_UP)
	if root.gui_get_focus_owner() != play:
		_fail("Keyboard should return focus to Play")
		return
	await _key(KEY_ENTER)
	await _wait_scene("res://scenes/survival_hub.tscn")
	if current_scene == null or current_scene.scene_file_path != "res://scenes/survival_hub.tscn":
		_fail("Keyboard Play should open the Survival hub")
		return
	var hub: Control = current_scene
	var launch: Button = hub.get_node("Content/Main/PreparationCard/Body/LaunchButton")
	if root.gui_get_focus_owner() != launch:
		_fail("The Survival hub should focus its launch action")
		return
	await _key(KEY_ENTER)
	await _wait_for_session()
	if _session == null or not _session._starting_weapon_choice_open:
		_fail("Keyboard launch should reach the starting weapon choice")
		return
	var starting_choice: Control = _session.get_node("HUD/ChestOverlay/ChestChoice")
	var first_option: Button = starting_choice.get_node("Content/Options/Choice0")
	await _key(KEY_DOWN)
	var selected_start := root.gui_get_focus_owner() as Button
	if selected_start == null or selected_start == first_option:
		_fail("Keyboard should move between starting weapon options")
		return
	var selected_start_title := str(selected_start.get_node("ContentMargin/OfferRow/OfferDetails/OfferTitle").text)
	await _key(KEY_ENTER)
	await _wait_for_unpaused_run()
	var expected_start_id := "lightning_conductor" if selected_start_title == "Lightning Conductor" else "inferno_sprayer"
	var other_start_id := "inferno_sprayer" if expected_start_id == "lightning_conductor" else "lightning_conductor"
	if _session.loadout.weapon_level(expected_start_id) != 1 or _session.loadout.weapon_level(other_start_id) != 0:
		_fail("Keyboard confirmation should equip exactly one starting weapon")
		return
	if not _session.open_chest_family("weapon"):
		_fail("Run should provide a weapon chest choice for the keyboard journey")
		return
	var choice: Control = _session.get_node("HUD/ChestOverlay/ChestChoice")
	var chest_first: Button = choice.get_node("Content/Options/Choice0")
	if root.gui_get_focus_owner() != chest_first:
		_fail("A weapon chest should focus its first choice")
		return
	await _key(KEY_DOWN)
	var selected_chest := root.gui_get_focus_owner() as Button
	if selected_chest == null or selected_chest == chest_first or selected_chest.name != "Choice1":
		_fail("Keyboard should move focus between chest options")
		return
	var selected_chest_id := str(_session._active_chest_options[1].get("id", ""))
	await _key(KEY_ENTER)
	if _session._chest_open or _session.loadout.weapon_level(selected_chest_id.trim_prefix("weapon:")) == 0:
		_fail("Keyboard confirmation should collect the focused chest option")
		return
	await _key(KEY_ESCAPE)
	var pause: Control = _session.get_node("HUD/PauseOverlay")
	if not pause.visible or not _session.simulation.snapshot()["paused"]:
		_fail("Escape should open Pause and freeze the run")
		return
	var options_button: Button = pause.get_node("Center/Panel/Content/OptionsButton")
	await _key(KEY_DOWN)
	if root.gui_get_focus_owner() != options_button:
		_fail("Keyboard should navigate from Resume to pause Options")
		return
	await _key(KEY_ENTER)
	var paused_time := float(_session.simulation.snapshot()["simulation_time"])
	if _session.get_node_or_null("HUD/OptionsPanel") == null:
		_fail("Keyboard should open Options over Pause")
		return
	await _key(KEY_ESCAPE)
	if _session.get_node_or_null("HUD/OptionsPanel") != null or not pause.visible or \
			root.gui_get_focus_owner() != options_button or not _session.simulation.snapshot()["paused"] or \
			not is_equal_approx(float(_session.simulation.snapshot()["simulation_time"]), paused_time):
		_fail("Closing Options should restore Pause without advancing simulation")
		return
	var inventory_button: Button = pause.get_node("Center/Panel/Content/InventoryButton")
	await _key(KEY_DOWN)
	if root.gui_get_focus_owner() != inventory_button:
		_fail("Keyboard should navigate from Options to the run inventory")
		return
	await _key(KEY_ENTER)
	if _session.get_node_or_null("HUD/RunInventoryPanel") == null:
		_fail("Keyboard should open the read-only run inventory")
		return
	await _key(KEY_ESCAPE)
	if _session.get_node_or_null("HUD/RunInventoryPanel") != null or \
			root.gui_get_focus_owner() != inventory_button or not _session.simulation.snapshot()["paused"]:
		_fail("Escape should close inventory and return to the frozen Pause menu")
		return
	await _key(KEY_ESCAPE)
	if pause.visible or _session.simulation.snapshot()["paused"]:
		_fail("Escape should resume the same run from Pause")
		return
	print("Keyboard launch-to-run journey passed (starting=%s)" % expected_start_id)
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

func _key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _fail(message: String) -> void:
	push_error(message)
	if is_instance_valid(_session):
		_session.queue_free()
	quit(1)
