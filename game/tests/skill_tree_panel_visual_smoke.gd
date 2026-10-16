extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var panel: Control = load("res://scenes/skill_tree_panel.tscn").instantiate()
	root.add_child(panel)
	panel.present({"resources": {"essence": 100}, "unlocked_skill_nodes": []})
	await process_frame
	var frame: Control = panel.get_node("Panel")
	var vitality: Button = panel.get_node("Panel/Content/VitalityButton")
	var focus: Button = panel.get_node("Panel/Content/FocusButton")
	var essence_icon: TextureRect = panel.get_node("Panel/Content/EssenceRow/EssenceIcon")
	var essence: Label = panel.get_node("Panel/Content/EssenceRow/Essence")
	if essence_icon.texture == null or essence_icon.texture.resource_path != "res://assets/icons/catalog/resource_essence.png" or \
		essence_icon.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST or essence.text != "ESSENCE 100":
		_fail("The skill tree should pair its essence balance with the existing pixel icon")
		return
	if vitality.icon == null or vitality.icon.resource_path != "res://assets/icons/catalog/skill_node.png" or \
		focus.icon == null or focus.icon.resource_path != "res://assets/icons/catalog/skill_node.png":
		_fail("Existing skill node artwork should identify both prototype choices")
		return
	if vitality.get_theme_constant("icon_max_width") != 12 or focus.get_theme_constant("icon_max_width") != 12 or \
		vitality.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST or focus.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_fail("Skill node icons should remain compact and pixel crisp")
		return
	if vitality.size.x < 390 or focus.size.x < 390:
		_fail("Skill node choices should have enough width for their cost and effect text")
		return
	if not panel.get_global_rect().encloses(frame.get_global_rect()):
		_fail("Skill tree frame should remain within the 640x360 logical viewport")
		return
	if vitality.disabled or not focus.disabled or vitality.focus_mode == Control.FOCUS_NONE:
		_fail("Skill choices should preserve their current prerequisites and keyboard focus")
		return
	print("Skill tree panel visual hierarchy smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
