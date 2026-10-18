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
		var first_enemy := chunk * 50
		var last_enemy := mini((chunk + 1) * 50, 499)
		for local_index in range(first_enemy, last_enemy):
			var column := local_index % 25
			var row := local_index / 25
			var position := Vector2(-168.0 + float(column) * 14.0, -96.0 + float(row) * 10.0)
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
			var column := index % 50
			var row := index / 50
			var position := Vector2(-154.0 + float(column) * 6.2, -112.0 + float(row) * 5.6)
			last_sequence = simulation.spawn_projectile("lightning_conductor", position, Vector2.ZERO, 1.0, 2.0, 60.0)
			if last_sequence == 0:
				_fail("Projectile render load exceeded the simulation command capacity")
				return
		if not await _wait_for_sequence(simulation, last_sequence):
			_fail("Could not spawn the projectile render batch")
			return
	var elite_sequence: int = simulation.spawn_enemy("elite", 1, Vector2(150.0, 100.0), Vector2.ZERO)
	if elite_sequence <= 0:
		_fail("Could not spawn the Hasted elite render probe")
		return
	var elite_spawned := false
	var elite_deadline := Time.get_ticks_msec() + 3000
	while not elite_spawned and Time.get_ticks_msec() < elite_deadline:
		await process_frame
		for entity in simulation.snapshot()["entities"]:
			if entity["components"].get("EnemyType", "") == "elite":
				elite_spawned = true
				break
	if not elite_spawned:
		_fail("The Hasted elite was not published in the simulation snapshot")
		return
	var state: Dictionary = simulation.snapshot()
	if state["entities"].size() != 2500:
		_fail("Expected 499 enemies, 2,000 projectiles and one elite, got %d entities" % state["entities"].size())
		return
	var view: Control = sandbox.get_node("Shell/Content/MainColumn/SimulationView")
	sandbox._refresh()
	var chaser_animation_instances := 0
	var elite_animation_instances := 0
	for animation_key in view._sprite_renderer._animated_batches:
		var count: int = view._sprite_renderer._animated_batches[animation_key]["multimesh"].instance_count
		if str(animation_key).begins_with("enemy_chaser_"):
			chaser_animation_instances += count
		elif str(animation_key).begins_with("elite_sprinter_"):
			elite_animation_instances += count
	var projectile_instances: int = view._sprite_renderer.multimesh_for("projectile_lightning").instance_count
	if chaser_animation_instances != 499 or projectile_instances != 2000 or elite_animation_instances != 1:
		_fail("MultiMesh batches do not contain the target load and elite sprite")
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_root().get_texture().get_image()
	if image.is_empty() or image.get_width() != 853 or image.get_height() != 480:
		_fail("Godot did not produce the logical 1280x720 frame")
		return
	var enemy_pixel: Vector2 = view.get_global_transform_with_canvas() * (view.size * 0.5 + Vector2(-168.0, -96.0))
	var cyan_highlight_visible := false
	var sampled_color := Color.TRANSPARENT
	for y in range(int(enemy_pixel.y) - 12, int(enemy_pixel.y) + 13):
		for x in range(int(enemy_pixel.x) - 12, int(enemy_pixel.x) + 13):
			var candidate := image.get_pixel(x, y)
			if candidate.g > 0.4 and candidate.b > 0.55 and candidate.r < 0.5:
				cyan_highlight_visible = true
				sampled_color = candidate
				break
		if cyan_highlight_visible:
			break
	if not cyan_highlight_visible:
		_fail("The cyan highlight on the known enemy sprite was not visible in the rendered frame: %s" % sampled_color)
		return
	var elite_center: Vector2 = view.get_global_transform_with_canvas() * (view.size * 0.5 + Vector2(150.0, 100.0))
	var haste_ring_visible := false
	for y in range(int(elite_center.y) - 22, int(elite_center.y) + 23):
		for x in range(int(elite_center.x) - 22, int(elite_center.x) + 23):
			var candidate := image.get_pixel(x, y)
			if candidate.r > 0.65 and candidate.g > 0.15 and candidate.g < 0.65 and candidate.b < 0.5:
				haste_ring_visible = true
				break
		if haste_ring_visible:
			break
	if not haste_ring_visible:
		_fail("The Hasted elite red affix ring was not visible in the rendered frame")
		return
	if image.save_png(SCREENSHOT_PATH) != OK:
		_fail("Could not save render smoke screenshot")
		return
	print("Rendered 499 enemies, 2,000 projectiles and one elite with %s; sample=%s; screenshot=%s" % [RenderingServer.get_video_adapter_name(), sampled_color, SCREENSHOT_PATH])
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
