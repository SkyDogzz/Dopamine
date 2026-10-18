extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var panel: Control = load("res://scenes/skill_tree_panel.tscn").instantiate()
	var save_service = load("res://scripts/save_service.gd").new("user://skill_tree_panel_visual_smoke")
	var progression = load("res://scripts/progression_service.gd").new(save_service, "0")
	panel.progression_service = progression
	root.add_child(panel)
	panel.present({"resources": {"essence": 300}, "unlocked_skill_nodes": []})
	await process_frame
	var frame: PanelContainer = panel.get_node("Panel")
	var scroll: ScrollContainer = panel.get_node("Panel/Content/TreeScroll")
	var graph: Control = panel.get_node("Panel/Content/TreeScroll/Graph")
	var essence_icon: TextureRect = panel.get_node("Panel/Content/EssenceRow/EssenceIcon")
	var essence: Label = panel.get_node("Panel/Content/EssenceRow/Essence")
	var vitality: Button = panel.node_button_for_id("vitality_starter")
	var focus: Button = panel.node_button_for_id("focused_training")
	var weapon: Button = panel.node_button_for_id("unlock_crimson_daggers")
	var relic: Button = panel.node_button_for_id("unlock_blood_chalice")
	var graph_layer: Control = graph.get_node("Connections")
	var frame_style := frame.get_theme_stylebox("panel") as StyleBoxFlat
	if frame_style == null or frame_style.border_color.to_html(false) != "37e8f5":
		_fail("Skill tree should use the shared Neon Arcade panel surface")
		return
	if essence_icon.texture == null or essence_icon.texture.resource_path != "res://assets/icons/catalog/resource_essence.png" or \
		essence_icon.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST or essence.text != "ESSENCE 300":
		_fail("Essence balance should retain its original pixel icon and value")
		return
	if panel.node_button_count() != progression.skill_node_ids().size() or panel.node_button_count() != 100:
		_fail("Every existing skill definition should appear as a graph node")
		return
	if not _graph_definitions_are_valid(progression):
		_fail("Skill prerequisites should resolve and form an acyclic graph")
		return
	if graph_layer.edges.size() < 90 or scroll.get_h_scroll_bar().max_value <= 0 or scroll.get_v_scroll_bar().max_value <= 0:
		_fail("The graph should draw prerequisite connections and expose both scroll directions")
		return
	if vitality == null or focus == null or weapon == null or relic == null or vitality.disabled or \
		focus.disabled or not focus.text.begins_with("·") or not weapon.text.begins_with("·") or not relic.text.begins_with("·"):
		_fail("The tree should derive available and locked states from current prerequisites and Essence")
		return
	if frame.size.x > 640.0 or frame.size.y > 360.0 or not panel.get_global_rect().encloses(frame.get_global_rect()):
		_fail("The tree frame should fit the 640x360 logical viewport")
		return
	if vitality.focus_mode == Control.FOCUS_NONE or panel.get_node("Panel/Content/ActionRow/UnlockButton").disabled:
		_fail("Available nodes and their action should remain keyboard accessible")
		return
	if not scroll.get_global_rect().encloses(vitality.get_global_rect()):
		_fail("The selected starting node should be visible when the tree opens")
		return
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		var viewport_image := root.get_texture().get_image()
		if viewport_image.save_png("/tmp/dopamine-skill-tree.png") != OK:
			_fail("Could not save skill tree review capture")
			return
	var requests: Array[String] = []
	panel.unlock_requested.connect(func(node_id: String) -> void: requests.append(node_id))
	panel.get_node("Panel/Content/ActionRow/UnlockButton").pressed.emit()
	await process_frame
	if requests != ["vitality_starter"]:
		_fail("The selected node action should emit its stable progression ID")
		return
	panel.present({"resources": {"essence": 300}, "unlocked_skill_nodes": ["vitality_starter"]})
	if vitality.text.find("✓") < 0 or focus.text.begins_with("·") or not weapon.text.begins_with("◆"):
		_fail("Unlock status should update from the profile and enable dependent branches")
		return
	var selected_effect: Label = panel.get_node("Panel/Content/Details/DetailContent/SelectedEffect")
	if not selected_effect.text.contains("PROPOSED") or not selected_effect.text.contains("ESSENCE"):
		_fail("Proposed costs and effects should remain explicitly labelled")
		return
	vitality.grab_focus()
	await _send_key(KEY_RIGHT)
	var keyboard_focus := root.gui_get_focus_owner() as Control
	if keyboard_focus == null or not keyboard_focus.name.begins_with("Node_") or keyboard_focus == vitality:
		_fail("Keyboard arrows should navigate between graph nodes")
		return
	await _send_gamepad_button(JOY_BUTTON_DPAD_DOWN)
	var gamepad_focus := root.gui_get_focus_owner() as Control
	if gamepad_focus == null or not gamepad_focus.name.begins_with("Node_") or gamepad_focus == keyboard_focus:
		_fail("Gamepad D-pad should navigate between graph nodes")
		return
	panel.present_error()
	if not panel.get_node("Panel/Content/ActionRow/UnlockButton").disabled or \
		panel.get_node("Panel/Content/Details/DetailContent/SelectedTitle").text != "PROFILE COULD NOT BE READ":
		_fail("An unavailable profile should disable actions and show an explicit error state")
		return
	print("Skill tree graph smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _send_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _send_gamepad_button(button_index: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button_index
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _graph_definitions_are_valid(progression: RefCounted) -> bool:
	var ids: Array[String] = progression.skill_node_ids()
	var known := {}
	for node_id in ids:
		if known.has(node_id):
			return false
		known[node_id] = true
	for node_id in ids:
		var definition: Dictionary = progression.skill_node_definition(node_id)
		for prerequisite in definition.get("prerequisites", []):
			if not known.has(str(prerequisite)) or str(prerequisite) == node_id:
				return false
	var visiting := {}
	var visited := {}
	for node_id in ids:
		if not _visit_prerequisites(node_id, progression, visiting, visited):
			return false
	return true

func _visit_prerequisites(node_id: String, progression: RefCounted, visiting: Dictionary, visited: Dictionary) -> bool:
	if visiting.has(node_id):
		return false
	if visited.has(node_id):
		return true
	visiting[node_id] = true
	var definition: Dictionary = progression.skill_node_definition(node_id)
	for prerequisite in definition.get("prerequisites", []):
		if not _visit_prerequisites(str(prerequisite), progression, visiting, visited):
			return false
	visiting.erase(node_id)
	visited[node_id] = true
	return true
