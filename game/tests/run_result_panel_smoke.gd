extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var panel: Control = load("res://scenes/run_result_panel.tscn").instantiate()
	root.add_child(panel)
	await process_frame
	if panel.theme == null:
		_fail("Run result should use the shared UI theme")
		return
	var summary: Label = panel.get_node("Content/Summary")
	var rewards: Label = panel.get_node("Content/Rewards")
	var equipment: Label = panel.get_node("Content/Equipment")
	panel.show_result(false, 4, 65.8, 12)
	if panel.get_node("Content/Title").text != "RUN OVER" or \
		not summary.text.contains("WAVE 04") or not summary.text.contains("01:05") or \
		not summary.text.contains("12 KILLS") or rewards.text != "RUN SANS SAUVEGARDE":
		_fail("A run without progression should clearly identify its no-save result")
		return
	var restart := panel.get_node("Content/RestartButton") as Button
	if root.gui_get_focus_owner() != restart:
		_fail("The result action should receive visible keyboard/gamepad focus")
		return
	var success_reward := {
		"ok": true,
		"duplicate": false,
		"essence": 22,
		"powder_basic": 34,
		"equipment": {"rarity": "mystic", "slot": "helmet"},
		"new_achievement_tiers": 1,
	}
	panel.show_result(true, 24, 605.0, 90, success_reward)
	if panel.get_node("Content/Title").text != "VICTORY" or not rewards.text.contains("+22 ESSENCE") or \
		not rewards.text.contains("+34 BASIC POWDER") or not equipment.text.contains("HELMET") or \
		panel.get_node("Content/Achievement").text.is_empty():
		_fail("Victory should display only the provided rewards, item and achievement summary")
		return
	panel.show_result(false, 8, 120.0, 30, {"ok": true, "duplicate": true})
	if rewards.text != "ALREADY REWARDED" or not equipment.text.is_empty() or \
		panel.get_node("Content").get_node_or_null("RewardIcons") != null or \
		panel.get_node("Content").get_node_or_null("EquipmentIcon") != null:
		_fail("A duplicate reward should be identified without repeating equipment rewards")
		return
	panel.show_result(false, 8, 120.0, 30, {"ok": false, "error": "save_failed"})
	if rewards.text != "PROGRESSION SAVE FAILED":
		_fail("A progression save error should stay distinct from an empty profile")
		return
	var original_size: Vector2i = root.size
	for size in [Vector2i(960, 600), Vector2i(1280, 800), Vector2i(1600, 900)]:
		root.size = size
		await process_frame
		if not Rect2(Vector2.ZERO, Vector2(size)).encloses(panel.get_global_rect()):
			_fail("Run result should fit viewport %s" % size)
			return
	root.size = original_size
	panel.queue_free()
	await process_frame
	print("Run result panel states, focus and layout smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
