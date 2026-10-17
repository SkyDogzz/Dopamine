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
	var frame: Control = panel.get_node("Panel")
	var vitality: Button = panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FoundationCard/Content/VitalityButton")
	var focus: Button = panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/FocusButton")
	var mastery: Button = panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/MasteryButton")
	var precision: Button = panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/PrecisionButton")
	var scroll: ScrollContainer = panel.get_node("Panel/Content/NodeScroll")
	var branch: HBoxContainer = panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch")
	var foundation_card: PanelContainer = panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FoundationCard")
	var followup_card: PanelContainer = panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard")
	var weapon_unlock: Button = panel.get_node("Panel/Content/NodeScroll/Rows/UnlockBranch/UnlockWeaponCard/Content/WeaponUnlockButton")
	var relic_unlock: Button = panel.get_node("Panel/Content/NodeScroll/Rows/UnlockBranch/UnlockRelicCard/Content/RelicUnlockButton")
	var additional_unlocks: VBoxContainer = panel.get_node("Panel/Content/NodeScroll/Rows/AdditionalUnlocks")
	var frame_style := frame.get_theme_stylebox("panel") as StyleBoxFlat
	var foundation_style := foundation_card.get_theme_stylebox("panel") as StyleBoxFlat
	if frame_style == null or frame_style.border_color.to_html(false) != "37e8f5" or \
		foundation_style == null or foundation_style.border_color.to_html(false) != "3d4868":
		_fail("Skill tree frame and node cards should resolve their distinct shared theme variations")
		return
	var essence_icon: TextureRect = panel.get_node("Panel/Content/EssenceRow/EssenceIcon")
	var essence: Label = panel.get_node("Panel/Content/EssenceRow/Essence")
	if essence_icon.texture == null or essence_icon.texture.resource_path != "res://assets/icons/catalog/resource_essence.png" or \
		essence_icon.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST or essence.text != "ESSENCE 300":
		_fail("The skill tree should pair its essence balance with the existing pixel icon")
		return
	if vitality.icon == null or vitality.icon.resource_path != "res://assets/icons/catalog/skill_node.png" or \
		focus.icon == null or focus.icon.resource_path != "res://assets/icons/catalog/skill_node.png" or \
		mastery.icon == null or mastery.icon.resource_path != "res://assets/icons/catalog/skill_node.png" or \
		precision.icon == null or precision.icon.resource_path != "res://assets/icons/catalog/skill_node.png":
		_fail("Existing skill node artwork should identify all three prototype choices")
		return
	if vitality.get_theme_constant("icon_max_width") != 12 or focus.get_theme_constant("icon_max_width") != 12 or \
		vitality.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST or focus.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_fail("Skill node icons should remain compact and pixel crisp")
		return
	if scroll.get_v_scroll_bar().max_value <= 0 or branch.get_child_count() != 3 or foundation_card.size.x < 150 or followup_card.size.x < 150 or \
		followup_card.size.y < 188:
		_fail("The skill tree should scroll through its readable connected branches")
		return
	if not weapon_unlock.disabled or not relic_unlock.disabled:
		_fail("Equipment unlock nodes should remain locked until their prerequisites are met (weapon=%s relic=%s)" % [str(weapon_unlock.disabled), str(relic_unlock.disabled)])
		return
	if _button_count(additional_unlocks) != 94 or progression.skill_node_ids().size() != 100:
		_fail("The tree should render all 100 core-stat and equipment nodes")
		return
	for heading_name in ["CoreStatsHeading", "WeaponUnlocksHeading", "RelicUnlocksHeading"]:
		if additional_unlocks.get_node_or_null(heading_name) == null:
			_fail("Generated skill nodes should be grouped by category: %s" % heading_name)
			return
	var core_heading: Label = additional_unlocks.get_node("CoreStatsHeading")
	var weapon_heading: Label = additional_unlocks.get_node("WeaponUnlocksHeading")
	var relic_heading: Label = additional_unlocks.get_node("RelicUnlocksHeading")
	if core_heading.text != "CORE STAT RANKS" or weapon_heading.text != "WEAPON UNLOCKS" or \
		relic_heading.text != "RELIC UNLOCKS" or \
		core_heading.get_index() >= weapon_heading.get_index() or weapon_heading.get_index() >= relic_heading.get_index():
		_fail("Skill node category headings should be clear and follow the tree's category order")
		return
	var crit_rank_button := _button_for_node(additional_unlocks, "steady_aim_02")
	if crit_rank_button == null or not crit_rank_button.tooltip_text.contains("+0.15%") or \
		crit_rank_button.tooltip_text.contains("+0.1%") or \
		not crit_rank_button.tooltip_text.contains("REQUIRES STEADY AIM"):
		_fail("Generated critical chance nodes should disclose their exact proposed increment and prerequisite")
		return
	var void_unlock_button := _button_for_node(additional_unlocks, "unlock_void_orb")
	if void_unlock_button == null or not void_unlock_button.tooltip_text.contains("REQUIRES CRIMSON DAGGERS"):
		_fail("Equipment unlock tooltips should name the preceding unlocked weapon")
		return
	if panel.get_node("Panel/Content/NodeScroll/Rows/UnlockBranch/UnlockWeaponCard/Content/Effect").text != "CRIMSON DAGGERS  •  130 ESSENCE  •  PROPOSED" or \
		panel.get_node("Panel/Content/NodeScroll/Rows/UnlockBranch/UnlockRelicCard/Content/Effect").text != "BLOOD CHALICE  •  160 ESSENCE  •  PROPOSED":
		_fail("Equipment unlock costs should remain explicitly proposed")
		return
	if vitality.text != "UNLOCK NODE" or focus.text != "UNLOCK NODE" or \
		panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FoundationCard/Content/Effect").text != "+5% MAX HP  •  50 ESSENCE  •  PROPOSED" or \
		panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/Effect").text != "+3% DAMAGE  •  80 ESSENCE  •  PROPOSED" or \
		panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/MasteryEffect").text != "+2% MOVE SPEED  •  110 ESSENCE  •  PROPOSED" or \
		panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/PrecisionEffect").text != "+1% CRIT CHANCE  •  140 ESSENCE  •  PROPOSED":
		_fail("Node actions should stay concise while proposed effects and costs remain explicit")
		return
	if panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FoundationCard/Content/Effect").get_theme_font_size("font_size") < 8 or \
		panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/Effect").get_theme_font_size("font_size") < 8:
		_fail("Proposed skill effects should remain readable at the 640x360 logical viewport")
		return
	if not panel.get_global_rect().encloses(frame.get_global_rect()):
		_fail("Skill tree frame should remain within the 640x360 logical viewport")
		return
	if vitality.disabled or not focus.disabled or not mastery.disabled or not precision.disabled or \
		vitality.focus_mode == Control.FOCUS_NONE:
		_fail("Skill choices should preserve their current prerequisites and keyboard focus")
		return
	panel.present({"resources": {"essence": 300}, "unlocked_skill_nodes": ["vitality_starter"]})
	if weapon_unlock.disabled or not relic_unlock.disabled or \
		panel.get_node("Panel/Content/NodeScroll/Rows/UnlockBranch/UnlockWeaponCard/Content/Prerequisite").text != "WEAPON · AVAILABLE" or \
		panel.get_node("Panel/Content/NodeScroll/Rows/UnlockBranch/UnlockRelicCard/Content/Prerequisite").text != "RELIC · REQUIRES DAGGERS":
		_fail("Weapon unlock should follow Vitality and relic unlock should still require Crimson Daggers")
		return
	panel.present({"resources": {"essence": 300}, "unlocked_skill_nodes": ["vitality_starter", "unlock_crimson_daggers"]})
	var weapon_node_ids: Array[String] = progression.skill_node_ids("weapon_unlocks")
	var first_additional_weapon: String = weapon_node_ids[1]
	var additional_weapon_button := _button_for_node(additional_unlocks, first_additional_weapon)
	if additional_weapon_button == null or additional_weapon_button.disabled:
		_fail("The first additional weapon should become available after Crimson Daggers")
		return
	var requested_nodes: Array[String] = []
	panel.unlock_requested.connect(func(node_id: String) -> void: requested_nodes.append(node_id))
	additional_weapon_button.emit_signal("pressed")
	await process_frame
	if requested_nodes != [first_additional_weapon]:
		_fail("Generated unlock controls should emit their own stable node IDs")
		return
	panel.present({"resources": {"essence": 300}, "unlocked_skill_nodes": ["vitality_starter", "unlock_crimson_daggers"]})
	if not weapon_unlock.disabled or relic_unlock.disabled or \
		panel.get_node("Panel/Content/NodeScroll/Rows/UnlockBranch/UnlockRelicCard/Content/Prerequisite").text != "RELIC · AVAILABLE":
		_fail("Relic unlock should become available only after Crimson Daggers")
		return
	panel.present({"resources": {"essence": 300}, "unlocked_skill_nodes": ["vitality_starter"]})
	if vitality.text != "UNLOCKED" or focus.disabled or \
		panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/Kicker").text != "FOLLOW-UP · AVAILABLE":
		_fail("Unlock state should update on its own node and expose the funded follow-up")
		return
	if not mastery.disabled or panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/MasteryKicker").text != "MASTERY · LOCKED":
		_fail("The skill mastery node should remain locked until Focused Training is unlocked")
		return
	if not precision.disabled or panel.get_node("Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/PrecisionKicker").text != "ADVANCED · LOCKED":
		_fail("The advanced critical node should remain locked until Fleet Footed is unlocked")
		return
	var input_requests: Array[String] = []
	panel.unlock_requested.connect(func(node_id: String) -> void: input_requests.append(node_id))
	vitality.grab_focus()
	await _send_key(KEY_RIGHT)
	if root.gui_get_focus_owner() != focus:
		_fail("The right arrow should navigate from Vitality to the available follow-up node")
		return
	await _send_key(KEY_ENTER)
	if input_requests != ["focused_training"]:
		_fail("Enter should request the focused skill node by its stable ID")
		return
	focus.grab_focus()
	await _send_gamepad_button(JOY_BUTTON_DPAD_DOWN)
	var gamepad_target := root.gui_get_focus_owner() as Button
	if gamepad_target == null or gamepad_target == focus:
		_fail("The gamepad D-pad should move focus from the follow-up skill node")
		return
	input_requests.clear()
	weapon_unlock.grab_focus()
	await _send_gamepad_button(JOY_BUTTON_A)
	if input_requests != ["unlock_crimson_daggers"]:
		_fail("Gamepad A should activate the focused skill node by its stable ID")
		return
	var all_node_ids: Array[String] = progression.skill_node_ids()
	var final_node_id: String = all_node_ids.back()
	all_node_ids.pop_back()
	panel.present({"resources": {"essence": 10000}, "unlocked_skill_nodes": all_node_ids})
	var final_unlock_button := _button_for_node(additional_unlocks, final_node_id)
	final_unlock_button.grab_focus()
	await process_frame
	if not scroll.get_global_rect().encloses(final_unlock_button.get_global_rect()):
		_fail("Keyboard focus should scroll the final equipment unlock into the visible panel: %s / %s / %s" % [str(scroll.get_global_rect()), str(final_unlock_button.get_global_rect()), str(scroll.scroll_vertical)])
		return
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png("/tmp/dopamine-skill-tree.png") != OK:
			_fail("Could not capture the skill tree panel render")
			return
	print("Skill tree panel visual hierarchy smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _button_for_node(container: VBoxContainer, node_id: String) -> Button:
	for button in container.get_children():
		if button is Button and button.name == node_id:
			return button as Button
	return null

func _button_count(container: VBoxContainer) -> int:
	var count := 0
	for child in container.get_children():
		if child is Button:
			count += 1
	return count

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
