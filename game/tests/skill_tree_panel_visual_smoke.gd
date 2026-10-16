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
