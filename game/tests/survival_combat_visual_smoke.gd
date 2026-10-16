extends SceneTree

const SCREENSHOT := "/tmp/dopamine-survival-combat-visual.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.contact_damage_per_hit = 0.0
	session.xp_collection_radius = 0.0
	session.lightning_cooldown = 1000.0
	root.add_child(session)
	await process_frame
	if session.simulation == null:
		_fail("Combat simulation did not initialize")
		return
	var enemy_types := ["chaser", "sprinter", "tank", "shooter", "buffer", "exploder", "shielder", "summoner", "elite"]
	var targets := [Vector2(72, -26), Vector2(120, 18), Vector2(164, -8), Vector2(206, 36),
		Vector2(244, -28), Vector2(-92, -48), Vector2(-142, 8), Vector2(-192, 52), Vector2(26, 92)]
	var sequence := 0
	for index in range(enemy_types.size()):
		sequence = session.simulation.spawn_enemy(enemy_types[index], 1, targets[index], Vector2.ZERO, 8.0)
	if not await _wait_for_sequence(session.simulation, sequence):
		_fail("Could not publish the combat visual targets")
		return
	var entities: Array = session.simulation.snapshot()["entities"]
	var first_target: Dictionary = {}
	for entity in entities:
		if entity["components"].get("EnemyType", "") == "chaser":
			first_target = entity
			break
	if first_target.is_empty():
		_fail("Combat visual target missing from snapshot")
		return
	session._fire_lightning_conductor(float(session.simulation.snapshot()["simulation_time"]), false)
	var projectile_types := ["lightning_conductor", "inferno_sprayer", "crimson_dagger", "minigun",
		"toxic_cloud", "sawblades", "meteor_staff", "prism_laser", "void_orb", "frost_nova",
		"enemy_projectile", "infinite_circuit_branch", "wildfire_sprayer", "bloodstorm_dagger",
		"event_horizon", "absolute_zero", "pandemic_cloud", "razorstorm", "starfall",
		"spectrum_collapse", "unique_lightning_burst", "evolution_shockwave"]
	for index in range(projectile_types.size()):
		var column := index % 8
		var row := index / 8
		sequence = session.simulation.spawn_projectile(projectile_types[index],
				Vector2(-220 + column * 62, -108 + row * 90), Vector2(18, -12), 1.0, 3.0, 2.0)
	sequence = session.simulation.spawn_projectile("enemy_projectile", Vector2(250, -72), Vector2(-20, 30), 1.0, 6.0, 2.0)
	sequence = session.simulation.spawn_projectile("meteor_staff", Vector2(148, 48), Vector2.ZERO, 1.0, 70.0, 0.15)
	if not await _wait_for_sequence(session.simulation, sequence):
		_fail("Could not publish the combat visual projectiles")
		return
	session._entities = session.simulation.snapshot()["entities"]
	session._add_weapon_impact("inferno_sprayer", Vector2(72, -26), false)
	session._add_weapon_impact("prism_laser", Vector2(206, 36), false)
	session._add_enemy_death_pixels("chaser", Vector2(164, -8))
	session._world_chests.append({"family": "weapon", "position": Vector2(-42, 44)})
	sequence = session.simulation.spawn_xp_orb(Vector2(42, 62), 1.0)
	if not await _wait_for_sequence(session.simulation, sequence):
		_fail("Could not publish the combat visual XP orb")
		return
	var camera: Camera2D = session.player.get_node("Camera2D")
	camera.zoom = Vector2.ONE
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image.is_empty() or image.get_width() != 640 or image.get_height() != 360:
		_fail("Survival combat render is not 640x360")
		return
	if image.save_png(SCREENSHOT) != OK:
		_fail("Could not save Survival combat visual capture")
		return
	print("Survival combat visual capture: %s" % SCREENSHOT)
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
