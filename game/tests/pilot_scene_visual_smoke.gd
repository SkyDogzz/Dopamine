extends SceneTree

const SCREENSHOT := "/tmp/dopamine-pilot-scene.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	root.add_child(session)
	await process_frame
	if session.simulation == null:
		_fail("Combat simulation did not initialize")
		return
	var player_sprite: Sprite2D = session.player.get_node("Sprite")
	if player_sprite.texture.get_size() != Vector2(32, 32) or player_sprite.scale != Vector2.ONE:
		_fail("Player sprite does not use its native 32x32 size")
		return
	var hud: Control = session.get_node("HUD/RunPanel")
	var hud_rect := hud.get_global_rect()
	var meta: Control = session.get_node("HUD/RunPanel/RunInfo/StatusRow/MetaPanel")
	if hud_rect.position.x > 9.0 or hud_rect.end.x < 631.0 or meta.get_global_rect().position.x < 200.0:
		_fail("Run HUD should be one full-width bar with run metadata aligned on the right")
		return
	for position in [Vector2(80, 20), Vector2(-60, -30), Vector2(-90, 40)]:
		if session.simulation.spawn_enemy("chaser", 1, position, Vector2.ZERO) <= 0:
			_fail("Could not add the combat scene enemies")
			return
	var deadline := Time.get_ticks_msec() + 2000
	while session.simulation.snapshot()["entities"].size() < 3 and Time.get_ticks_msec() < deadline:
		await process_frame
	if session.simulation.snapshot()["entities"].size() < 3:
		_fail("Combat scene did not receive its enemy sprites")
		return
	session._refresh_hud({"paused": false})
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image.is_empty() or image.get_width() != 640 or image.get_height() != 360 or image.save_png(SCREENSHOT) != OK:
		_fail("Could not render the pilot scene at the current gameplay viewport")
		return
	print("Pilot scene screenshot: %s" % SCREENSHOT)
	if "--stay-open" in OS.get_cmdline_user_args():
		while not Input.is_key_pressed(KEY_ESCAPE):
			await process_frame
	else:
		quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
