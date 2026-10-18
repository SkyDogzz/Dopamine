extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	if not session.has_method("open_chest_family"):
		_fail("Survival session script should load")
		return
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	root.add_child(session)
	await process_frame
	var speed_sequence: int = session.simulation.set_speed(4.0)
	var deadline := Time.get_ticks_msec() + 3000
	var simulation_started := false
	while Time.get_ticks_msec() < deadline:
		var state: Dictionary = session.simulation.snapshot()
		if int(state["last_sequence"]) >= speed_sequence and not state["paused"] and \
				float(state["simulation_time"]) > 0.0:
			simulation_started = true
			break
		await process_frame
	if not simulation_started:
		_fail("Simulation should resume and accept its speed command before the death check")
		return
	session.player_hp = 0.001
	deadline = Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if session.run_over:
			break
	var overlay = session.get_node("HUD/RunResultOverlay")
	var panel = session.get_node("HUD/RunResultOverlay/RunResultPanel")
	var player_sprite: Sprite2D = session.player.get_node("Sprite")
	if overlay.visible or player_sprite.texture.resource_path.get_file() != "player_death.png":
		_fail("The player death animation should remain visible before the opaque result panel")
		return
	deadline = Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < deadline:
		if session.simulation.snapshot()["paused"] and overlay.visible:
			break
		await process_frame
	if not session.run_over or not session.simulation.snapshot()["paused"] or not overlay.visible:
		_fail("HP reaching zero should pause the run and show the result screen")
		return
	if player_sprite.region_rect.position.x < 96.0:
		_fail("The result screen should appear after the player death animation finishes")
		return
	if panel.get_node("Content/Title").text != "RUN OVER" or not panel.get_node("Content/Summary").text.contains("WAVE"):
		_fail("Defeat should show a run summary and RUN OVER title")
		return
	print("Survival run result smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
