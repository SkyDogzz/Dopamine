extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	for path in ["HUD/EquipmentButton", "HUD/SkillsButton", "HUD/EquipmentInventoryOverlay", "HUD/SkillTreeOverlay"]:
		if session.get_node_or_null(path) != null:
			_fail("Permanent progression UI path %s must not exist during a run" % path)
			return
	session.queue_free()
	await process_frame
	print("Survival run permanent progression isolation smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
