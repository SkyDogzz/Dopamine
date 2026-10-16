extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var panel: Control = load("res://scenes/skill_tree_panel.tscn").instantiate()
	root.add_child(panel)
	panel.present({"resources": {"essence": 100}, "unlocked_skill_nodes": []})
	await process_frame
	var frame: Control = panel.get_node("Panel")
	var vitality: Button = panel.get_node("Panel/Content/NodeBranch/FoundationCard/Content/VitalityButton")
	var focus: Button = panel.get_node("Panel/Content/NodeBranch/FollowupCard/Content/FocusButton")
	var mastery: Button = panel.get_node("Panel/Content/NodeBranch/FollowupCard/Content/MasteryButton")
	var branch: HBoxContainer = panel.get_node("Panel/Content/NodeBranch")
	var foundation_card: PanelContainer = panel.get_node("Panel/Content/NodeBranch/FoundationCard")
	var followup_card: PanelContainer = panel.get_node("Panel/Content/NodeBranch/FollowupCard")
	var frame_style := frame.get_theme_stylebox("panel") as StyleBoxFlat
	var foundation_style := foundation_card.get_theme_stylebox("panel") as StyleBoxFlat
	if frame_style == null or frame_style.border_color.to_html(false) != "37e8f5" or \
		foundation_style == null or foundation_style.border_color.to_html(false) != "3d4868":
		_fail("Skill tree frame and node cards should resolve their distinct shared theme variations")
		return
	var essence_icon: TextureRect = panel.get_node("Panel/Content/EssenceRow/EssenceIcon")
	var essence: Label = panel.get_node("Panel/Content/EssenceRow/Essence")
	if essence_icon.texture == null or essence_icon.texture.resource_path != "res://assets/icons/catalog/resource_essence.png" or \
		essence_icon.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST or essence.text != "ESSENCE 100":
		_fail("The skill tree should pair its essence balance with the existing pixel icon")
		return
	if vitality.icon == null or vitality.icon.resource_path != "res://assets/icons/catalog/skill_node.png" or \
		focus.icon == null or focus.icon.resource_path != "res://assets/icons/catalog/skill_node.png" or \
		mastery.icon == null or mastery.icon.resource_path != "res://assets/icons/catalog/skill_node.png":
		_fail("Existing skill node artwork should identify all three prototype choices")
		return
	if vitality.get_theme_constant("icon_max_width") != 12 or focus.get_theme_constant("icon_max_width") != 12 or \
		vitality.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST or focus.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_fail("Skill node icons should remain compact and pixel crisp")
		return
	if branch.get_child_count() != 3 or foundation_card.size.x < 150 or followup_card.size.x < 150 or \
		followup_card.size.y < 128:
		_fail("The three existing skill nodes should form a readable connected branch")
		return
	if vitality.text != "UNLOCK NODE" or focus.text != "UNLOCK NODE" or \
		panel.get_node("Panel/Content/NodeBranch/FoundationCard/Content/Effect").text != "+5% MAX HP  •  50 ESSENCE  •  PROPOSED" or \
		panel.get_node("Panel/Content/NodeBranch/FollowupCard/Content/Effect").text != "+3% DAMAGE  •  80 ESSENCE  •  PROPOSED" or \
		panel.get_node("Panel/Content/NodeBranch/FollowupCard/Content/MasteryEffect").text != "+2% MOVE SPEED  •  110 ESSENCE  •  PROPOSED":
		_fail("Node actions should stay concise while proposed effects and costs remain explicit")
		return
	if panel.get_node("Panel/Content/NodeBranch/FoundationCard/Content/Effect").get_theme_font_size("font_size") < 8 or \
		panel.get_node("Panel/Content/NodeBranch/FollowupCard/Content/Effect").get_theme_font_size("font_size") < 8:
		_fail("Proposed skill effects should remain readable at the 640x360 logical viewport")
		return
	if not panel.get_global_rect().encloses(frame.get_global_rect()):
		_fail("Skill tree frame should remain within the 640x360 logical viewport")
		return
	if vitality.disabled or not focus.disabled or not mastery.disabled or vitality.focus_mode == Control.FOCUS_NONE:
		_fail("Skill choices should preserve their current prerequisites and keyboard focus")
		return
	panel.present({"resources": {"essence": 130}, "unlocked_skill_nodes": ["vitality_starter"]})
	if vitality.text != "UNLOCKED" or focus.disabled or \
		panel.get_node("Panel/Content/NodeBranch/FollowupCard/Content/Kicker").text != "FOLLOW-UP · AVAILABLE":
		_fail("Unlock state should update on its own node and expose the funded follow-up")
		return
	if not mastery.disabled or panel.get_node("Panel/Content/NodeBranch/FollowupCard/Content/MasteryKicker").text != "MASTERY · LOCKED":
		_fail("The skill mastery node should remain locked until Focused Training is unlocked")
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
