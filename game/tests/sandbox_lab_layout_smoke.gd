extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for viewport_size in [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		var viewport := SubViewport.new()
		viewport.size = viewport_size
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var lab: Control = load("res://scenes/sandbox_lab.tscn").instantiate()
		viewport.add_child(lab)
		await process_frame
		await process_frame
		var bounds := Rect2(Vector2.ZERO, Vector2(viewport_size))
		for path in ["Root", "Root/Header", "Root/Header/Title", "Root/Header/HomeButton", "Root/Body", "Root/Body/Left/SimulationView", "Root/Body/Left/Controls", "Root/Body/Left/SnapshotControls", "Root/Body/Left/ProjectileControls", "Root/Body/Left/WaveControls"]:
			var control := lab.get_node(path) as Control
			if control.size == Vector2.ZERO or not bounds.encloses(control.get_global_rect()):
				_fail("Sandbox Lab %s outside viewport %s: %s" % [path, viewport_size, control.get_global_rect()])
				return
		if lab.context.session.get_node("HUD").visible or (lab.context.session._game_camera != null and lab.context.session._game_camera.enabled) or \
			lab.context.progression_service != null or lab.context.normal_save_service != null:
			_fail("Sandbox Lab session HUD/camera or normal progression/save services must stay isolated")
			return
		var sections: Control = lab.get_node("Root/Body/Left/Side/Sections")
		var page_content: Control = lab.get_node("Root/Body/Left")
		var body_scroll := lab.get_node("Root/Body") as ScrollContainer
		if not sections.is_visible_in_tree() or (viewport_size == Vector2i(640, 360) and page_content.size.y <= body_scroll.size.y):
			_fail("Sandbox configuration should remain reachable by scrolling beyond the visible simulation controls")
			return
		if viewport_size == Vector2i(640, 360):
			var initial_sections_y := sections.get_global_rect().position.y
			body_scroll.scroll_vertical = int(body_scroll.get_v_scroll_bar().max_value)
			await process_frame
			if sections.get_global_rect().position.y >= initial_sections_y:
				_fail("Scrolling the Sandbox Lab should move configuration sections into view")
				return
		viewport.remove_child(lab)
		lab.free()
		viewport.queue_free()
		await process_frame
	print("Sandbox Lab layout and isolation fit 640x360, 1280x720 and 1920x1080")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
