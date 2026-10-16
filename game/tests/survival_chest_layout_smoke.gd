extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var options := [
		{"id": "weapon:lightning_conductor", "title": "Lightning Conductor — Lv 1 → 2", "description": "Shoots one bolt at the nearest enemy, then arcs to nearby enemies with reduced damage.\nNEXT LEVEL: +1 chain bounce", "icon": "res://assets/sprites/catalog/weapon_lightning_conductor.png"},
		{"id": "weapon:inferno_sprayer", "title": "Inferno Sprayer", "description": "Fires a flame projectile that burns its target; Infernal Heart unlocks an explosive evolution.", "icon": "res://assets/sprites/catalog/weapon_inferno_sprayer.png"},
		{"id": "relic:storm_core", "title": "Storm Core", "description": "Increases lightning damage and chain range.", "icon": "res://assets/sprites/catalog/relic_storm_core.png"},
	]
	for size in [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		var viewport := SubViewport.new()
		viewport.size = size
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
		session.skip_starting_weapon_choice = true
		session.spawn_initial_enemy = false
		session.wave_spawning_enabled = false
		viewport.add_child(session)
		await process_frame
		var choice: Control = session.get_node("HUD/ChestOverlay/ChestChoice")
		choice.present(options, 3, "WEAPON CHEST — CHOOSE ONE")
		await process_frame
		await process_frame
		var bounds := Rect2(Vector2.ZERO, Vector2(viewport.size))
		var modal := choice.get_global_rect()
		if not bounds.encloses(modal):
			_fail("Chest panel must fit %s gameplay viewport: %s" % [size, modal])
			return
		for button in choice.get_node("Content/Options").get_children():
			if not bounds.encloses(button.get_global_rect()) or button.size.y > 80.0:
				_fail("Chest option must fit %s and remain compact: %s" % [size, button.get_global_rect()])
				return
		viewport.queue_free()
		await process_frame
	print("Chest options fit 640x360, 1280x720 and 1920x1080 with next-level descriptions")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
