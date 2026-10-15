extends SceneTree

const SCREENSHOT_PATH := "/tmp/dopamine-render-visual-smoke.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var sandbox: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(sandbox)
	await process_frame
	var simulation: Object = sandbox.simulation
	if simulation == null:
		_fail("Sandbox did not create its combat simulation")
		return
	var pause_sequence: int = simulation.pause()
	if not await _wait_for_sequence(simulation, pause_sequence):
		_fail("Could not pause the simulation before preparing the render load")
		return
	for chunk in range(10):
		var last_sequence := 0
		for local_index in range(chunk * 50, (chunk + 1) * 50):
			var column := local_index % 25
			var row := local_index / 25
			var position := Vector2(-350.0 + float(column) * 14.0, -260.0 + float(row) * 26.0)
			last_sequence = simulation.spawn_enemy("chaser", 1, position, Vector2.ZERO)
			if last_sequence == 0:
				_fail("Enemy render load exceeded the simulation command capacity")
				return
		if not await _wait_for_sequence(simulation, last_sequence):
			_fail("Could not spawn the enemy render batch")
			return
	for chunk in range(10):
		var last_sequence := 0
		for index in range(chunk * 200, (chunk + 1) * 200):
			var column := index % 25
			var row := index / 25
			var position := Vector2(3.0 + float(column) * 17.0, -296.0 + float(row) * 7.4)
			last_sequence = simulation.spawn_projectile("lightning_conductor", position, Vector2.ZERO, 1.0, 2.0, 60.0)
			if last_sequence == 0:
				_fail("Projectile render load exceeded the simulation command capacity")
				return
		if not await _wait_for_sequence(simulation, last_sequence):
			_fail("Could not spawn the projectile render batch")
			return
	var state: Dictionary = simulation.snapshot()
	if state["entities"].size() != 2500:
		_fail("Expected 500 enemies and 2,000 projectiles, got %d entities" % state["entities"].size())
		return
	var view: Control = sandbox.get_node("Shell/Content/MainColumn/SimulationView")
	sandbox._refresh()
	if view._enemy_multimesh.instance_count != 500 or view._projectile_multimesh.instance_count != 2000:
		_fail("MultiMesh batches do not contain the full target entity load")
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_root().get_texture().get_image()
	if image.is_empty() or image.get_width() < 1280 or image.get_height() < 800:
		_fail("Godot did not produce a full-size rendered frame")
		return
	var enemy_pixel: Vector2 = view.get_global_transform_with_canvas() * (view.size * 0.5 + Vector2(-350.0, -260.0))
	var sampled_color := image.get_pixel(int(enemy_pixel.x), int(enemy_pixel.y))
	if sampled_color.g < 0.5 or sampled_color.b < 0.5 or sampled_color.r > 0.5:
		_fail("The known cyan enemy was not visible in the rendered frame: %s" % sampled_color)
		return
	if image.save_png(SCREENSHOT_PATH) != OK:
		_fail("Could not save render smoke screenshot")
		return
	print("Rendered 500 enemies and 2,000 projectiles with %s; sample=%s; screenshot=%s" % [RenderingServer.get_video_adapter_name(), sampled_color, SCREENSHOT_PATH])
	simulation.pause()
	if "--stay-open" in OS.get_cmdline_user_args():
		print("Visual load is on screen; press Escape to close the window")
		while not Input.is_key_pressed(KEY_ESCAPE):
			await process_frame
	else:
		quit()

func _wait_for_sequence(simulation: Object, sequence: int) -> bool:
	if sequence <= 0:
		return false
	var deadline := Time.get_ticks_msec() + 3000
	while int(simulation.snapshot()["last_sequence"]) < sequence and Time.get_ticks_msec() < deadline:
		await process_frame
	return int(simulation.snapshot()["last_sequence"]) >= sequence

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
