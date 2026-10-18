extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var view := Control.new()
	view.set_script(load("res://scripts/simulation_view.gd"))
	view.size = Vector2(640, 460)
	root.add_child(view)
	await process_frame
	for role_id in view._sprite_renderer._role_animation_sets:
		for state in view._sprite_renderer._role_animation_sets[role_id]:
			var sprite_frames: SpriteFrames = view._sprite_renderer._role_animation_sets[role_id][state]
			for animation_name in sprite_frames.get_animation_names():
				for frame in range(sprite_frames.get_frame_count(animation_name)):
					var frame_texture: Texture2D = sprite_frames.get_frame_texture(animation_name, frame)
					var batch: Dictionary = view._sprite_renderer._get_animation_batch(role_id, state, animation_name, frame)
					var expected_size := (frame_texture as AtlasTexture).region.size if frame_texture is AtlasTexture else frame_texture.get_size()
					assert(batch["texture"].get_size() == expected_size,
							"%s:%d should render one cropped frame, not its full source atlas" % [animation_name, frame])
					if frame_texture is AtlasTexture:
						var atlas_frame := frame_texture as AtlasTexture
						var expected_image := atlas_frame.atlas.get_image().get_region(Rect2i(atlas_frame.region))
						if role_id == "xp_orb":
							expected_image.flip_y()
						assert(batch["texture"].get_image().get_data() == expected_image.get_data(),
							"%s:%d should contain the selected atlas region pixels" % [animation_name, frame])
						if animation_name.ends_with("_up"):
							var flipped_batch: Dictionary = view._sprite_renderer._get_animation_batch(
								role_id, state, animation_name, frame, true)
							expected_image.flip_x()
							assert(flipped_batch["texture"].get_image().get_data() == expected_image.get_data(),
								"%s:%d left-facing frame should be an upright horizontal flip" % [animation_name, frame])
	var entities: Array[Dictionary] = []
	for index in range(500):
		entities.append(_entity(index, "chaser", float(index % 40) * 12.0 - 240.0, float(index / 40) * 12.0 - 70.0))
	for index in range(2000):
		entities.append(_entity(500 + index, "projectile", float(index % 40) * 12.0 - 240.0, float(index / 40) * 8.0 - 200.0))
	entities.append(_entity(2500, "xp", 0, -20))
	entities.append(_entity(2501, "tank", 80, 0))
	entities.append(_entity(2502, "projectile_inferno", 100, 0))
	entities.append(_entity(2503, "projectile_minigun", 120, 0))
	entities.append(_entity(2504, "projectile_toxic_cloud", 140, 0))
	entities.append(_entity(2505, "projectile_sawblades", 160, 0))
	entities.append(_entity(2506, "projectile_meteor", 180, 0))
	entities.append(_entity(2507, "projectile_starfall_fragment", 200, 0))
	entities.append(_entity(2508, "projectile_void_orb", 220, 0))
	entities.append(_entity(2530, "projectile_shatter_fragment", 260, 0))
	entities.append(_entity(2531, "projectile_shatter_impact", 280, 0))
	for index in range(9):
		var names := ["infinite_circuit", "wildfire", "bloodstorm", "event_horizon", "absolute_zero", "pandemic", "razorstorm", "starfall", "spectrum_collapse"]
		entities.append(_entity(2510 + index, "projectile_" + names[index], -80.0 + index * 18.0, 0.0))
	entities.append(_entity(2519, "projectile_redline", 220, 0))
	var pandemic_field := _entity(2520, "projectile_pandemic", 240, 0)
	pandemic_field["components"]["Projectile"] = {
		"persistent_area": true, "area_radius": 48.0, "remaining_seconds": 0.9,
	}
	entities.append(pandemic_field)
	view.set_entities(entities)
	for weapon_id in view._sprite_renderer.WEAPON_ANIMATION_IDS:
		var weapon_role := "weapon_%s" % weapon_id
		assert(view._sprite_renderer._role_animation_sets.has(weapon_role),
				"Weapon %s should resolve its authored attack animation" % weapon_id)
		var attack_frames: SpriteFrames = view._sprite_renderer._role_animation_sets[weapon_role]["attack"]
		assert(attack_frames.get_frame_count("%s_attack" % weapon_role) == 4,
				"Weapon %s should have all four attack frames" % weapon_id)
	for family in view._sprite_renderer.WEAPON_VFX_FAMILIES:
		var vfx_role := "weapon_%s" % family
		for state in ["fire_vfx", "impact_vfx"]:
			var vfx_frames: SpriteFrames = view._sprite_renderer._role_animation_sets[vfx_role][state]
			assert(vfx_frames.get_frame_count("%s_%s" % [vfx_role, state]) == 4,
					"Weapon %s %s should have all four frames" % [family, state])
	for relic_id in view._sprite_renderer.RELIC_ANIMATION_IDS:
		var relic_role := "relic_%s" % relic_id
		assert(view._sprite_renderer._role_animation_sets.has(relic_role),
				"Relic %s should resolve its authored acquisition animation" % relic_id)
		var acquisition_frames: SpriteFrames = view._sprite_renderer._role_animation_sets[relic_role]["acquisition"]
		assert(acquisition_frames.get_frame_count("%s_acquisition" % relic_role) == 4,
				"Relic %s should have all four acquisition frames" % relic_id)
	assert(view._sprite_renderer._role_animation_sets["chest"]["open"].get_frame_count("chest_open") == 4,
			"Reward chest should resolve all four opening frames")
	for sprite_id in view._sprite_renderer.SPRITE_FILES:
		if not str(sprite_id).begins_with("projectile_"):
			continue
		assert(view._sprite_renderer._role_animation_sets.has(sprite_id),
				"Projectile %s should resolve to an authored SpriteFrames resource" % sprite_id)
		var animation_set: Dictionary = view._sprite_renderer._role_animation_sets[sprite_id]
		var projectile_frames: SpriteFrames = animation_set["projectile"]
		var animation_names := projectile_frames.get_animation_names()
		assert(not animation_names.is_empty(), "Projectile %s should expose an animation" % sprite_id)
		var animation_name: String = animation_names[0]
		assert(projectile_frames.get_animation_loop(animation_name) and
				projectile_frames.get_frame_count(animation_name) > 1,
				"Projectile %s should have a repeating multi-frame animation" % sprite_id)
		assert(view._sprite_renderer._batches[sprite_id]["texture"].get_size() == Vector2(16.0, 16.0),
				"Projectile %s must use its standalone single-sprite art in gameplay" % sprite_id)
	var chaser_instances := 0
	for animation_key in view._sprite_renderer._animated_batches:
		if str(animation_key).begins_with("enemy_chaser_idle_"):
			chaser_instances += view._sprite_renderer._animated_batches[animation_key]["multimesh"].instance_count
	assert(chaser_instances == 500, "500 enemies should remain batched by their current animation frame")
	assert(view._sprite_renderer.multimesh_for("projectile_lightning").instance_count == 2000,
			"2,000 common projectiles should use their standalone sprite batch")
	assert(view._sprite_renderer._projectile_trails.size() == view._sprite_renderer.MAX_PROJECTILE_TRAILS, "Projectile trails should use a fixed visual budget under load")
	assert(view._sprite_renderer._projectile_trails[0]["start"].x < view._sprite_renderer._projectile_trails[0]["end"].x, "A right-moving projectile should trail behind its current position")
	assert(is_equal_approx(view._sprite_renderer._projectile_trails[0]["start"].distance_to(view._sprite_renderer._projectile_trails[0]["end"]), 12.0), "Projectile trails should keep the proposed 12-pixel length")
	assert(view._xp_multimesh.instance_count == 1, "XP orbs should use a separate MultiMesh batch")
	var xp_source: Image = load("res://assets/sprites/rewards/xp_orb.png").get_image()
	xp_source.flip_y()
	assert(view._sprite_renderer._batches["xp_orb"]["texture"].get_image().get_data() == xp_source.get_data(),
			"XP should use its dedicated sprite in the corrected vertical orientation")
	var tank_idle_instances := 0
	for animation_key in view._sprite_renderer._animated_batches:
		if str(animation_key).begins_with("enemy_tank_idle_up:"):
			tank_idle_instances += view._sprite_renderer._animated_batches[animation_key]["multimesh"].instance_count
	assert(tank_idle_instances == 1, "Idle enemies should render from their directional animation frames")
	var moving_tank: Dictionary = view._sprite_renderer._animation_for_entity({"EnemyType": "tank", "Velocity2D": {"x": 80.0, "y": 0.0}}, 0.0)
	assert(moving_tank["name"] == "enemy_tank_move_up" and not moving_tank["flip_x"] and moving_tank["frame"] == 0,
			"Enemies should use the corrected up row for their upright base pose")
	var test_facing: String = view._sprite_renderer._horizontal_facing_for_entity("test:1", {"Velocity2D": {"x": -80.0, "y": 0.0}})
	test_facing = view._sprite_renderer._horizontal_facing_for_entity("test:1", {"Velocity2D": {"x": 0.0, "y": -80.0}})
	var vertical_tank: Dictionary = view._sprite_renderer._animation_for_entity(
		{"EnemyType": "tank", "Velocity2D": {"x": 0.0, "y": -80.0}}, 0.0, "", test_facing)
	assert(test_facing == "left" and vertical_tank["name"] == "enemy_tank_move_up" and vertical_tank["flip_x"],
			"Vertical movement must preserve an upright left-facing frame")
	assert(is_equal_approx(view._sprite_renderer._size_for_entity("enemy_chaser", {"CollisionRadius": 12.0}), 24.0), "Mob sprite diameter should match its shared collision radius")
	assert(is_equal_approx(view._sprite_renderer._size_for_entity("boss_dopamine_core", {"CollisionRadius": 26.0}), 52.0), "Boss sprite diameter should match its shared collision radius")
	assert(view._sprite_renderer.multimesh_for("projectile_inferno").instance_count == 1, "Weapon projectile art should remain distinct")
	assert(view._sprite_renderer.multimesh_for("projectile_minigun").instance_count == 1, "Minigun should use its own projectile art")
	assert(view._sprite_renderer._batches["projectile_minigun"]["texture"].resource_path.ends_with("projectiles/projectile_minigun.png"), "Minigun batch should load its distinct pixel-art sprite")
	assert(view._sprite_renderer.multimesh_for("projectile_toxic_cloud").instance_count == 1, "Toxic Cloud should use its own projectile art")
	assert(view._sprite_renderer.multimesh_for("projectile_sawblades").instance_count == 1, "Sawblades should use their own projectile art")
	assert(view._sprite_renderer.multimesh_for("projectile_meteor").instance_count == 1, "Meteor Staff should use dedicated meteor art")
	assert(view._sprite_renderer.multimesh_for("projectile_starfall_fragment").instance_count == 1, "Starfall fragments should use separate art")
	assert(view._sprite_renderer.multimesh_for("projectile_absolute_zero").instance_count == 1,
			"Absolute Zero should use the dedicated frost sprite")
	assert(view._sprite_renderer.multimesh_for("projectile_void_orb").instance_count == 1, "Void Orb should use dedicated art")
	var first_ripple: float = view._sprite_renderer.persistent_area_ripple_radius(0.9, 48.0)
	var next_ripple: float = view._sprite_renderer.persistent_area_ripple_radius(0.6, 48.0)
	assert(first_ripple > 0.0 and first_ripple < 48.0 and not is_equal_approx(first_ripple, next_ripple), "Pandemic field ripple should travel inside the field as simulation time advances")
	assert(is_zero_approx(view._sprite_renderer.persistent_area_ripple_radius(0.6, 0.0)), "A zero-radius persistent field should not draw a ripple")
	assert(is_zero_approx(view._sprite_renderer.persistent_area_ripple_radius(0.0, 48.0)), "An expired persistent field should not draw a ripple")
	assert(view._sprite_renderer._batches["projectile_sawblades"]["texture"].resource_path.ends_with("projectiles/projectile_sawblades.png"), "Sawblades should load their dedicated pixel-art sprite")
	assert(view._sprite_renderer._batches["projectile_meteor"]["texture"].resource_path.ends_with("projectiles/projectile_meteor.png"), "Meteor Staff should load its pixel-art meteor")
	assert(view._sprite_renderer._batches["projectile_starfall_fragment"]["texture"].resource_path.ends_with("projectiles/projectile_starfall_fragment.png"), "Starfall should load its fragment sprite")
	assert(view._sprite_renderer._batches["projectile_shatter_fragment"]["texture"].resource_path.ends_with("projectiles/projectile_absolute_zero.png"), "Shatter should reuse the existing Absolute Zero frost fragment sprite")
	assert(view._sprite_renderer._batches["projectile_shatter_impact"]["texture"].resource_path.ends_with("projectiles/projectile_absolute_zero.png"), "Shatter bonus impact should reuse the existing Absolute Zero frost sprite")
	assert(view._sprite_renderer._batches["projectile_void_orb"]["texture"].resource_path.ends_with("projectiles/projectile_void_orb.png"), "Void Orb should load its dedicated sprite")
	assert(view._sprite_renderer._batches["projectile_toxic_cloud"]["texture"].resource_path.ends_with("projectiles/projectile_toxic_cloud.png"), "Toxic Cloud batch should load its distinct pixel-art sprite")
	for projectile_name in ["infinite_circuit", "wildfire", "bloodstorm", "event_horizon", "absolute_zero", "pandemic", "razorstorm", "starfall", "spectrum_collapse"]:
		var batch_name: String = "projectile_" + projectile_name
		var expected_instances := 2 if projectile_name == "pandemic" else 1
		assert(view._sprite_renderer.multimesh_for(batch_name).instance_count == expected_instances, "Evolved projectile %s should use its own batch" % projectile_name)
	assert(view._sprite_renderer.multimesh_for("projectile_redline").instance_count == 1, "Redline should render in its own evolved projectile batch")
	assert(view._sprite_renderer._batches["projectile_redline"]["texture"].resource_path.ends_with("projectiles/projectile_minigun.png"), "Redline should retain the Minigun bolt silhouette")
	assert(view._sprite_renderer.SPRITE_COLORS["projectile_redline"] == Color("#FF7181"), "Redline bolts should use the established neon red tint")
	assert(view._sprite_renderer._batches["enemy_chaser"]["texture"].resource_path.ends_with("enemy_chaser.png"), "Chaser batch should load its pixel-art sprite")
	view._sprite_renderer.set_entities([], Vector2.ZERO, 0.1, {}, [{
		"role": "weapon_minigun", "state": "fire_vfx", "position": Vector2(20, 30),
		"size": 28.0, "direction": Vector2.ZERO, "started_at": 0.0,
	}])
	assert(view._sprite_renderer.animated_multimesh_for("weapon_minigun_fire_vfx", 1).instance_count == 1,
			"Transient weapon fire VFX should render on its authored second frame")
	var minigun_impact_frames: SpriteFrames = view._sprite_renderer._role_animation_sets["weapon_minigun"]["impact_vfx"]
	var impact_animation: String = minigun_impact_frames.get_animation_names()[0]
	var impact_texture: Texture2D = minigun_impact_frames.get_frame_texture(impact_animation, 2)
	var impact_batch: Dictionary = view._sprite_renderer._get_animation_batch(
		"weapon_minigun", "impact_vfx", impact_animation, 2)
	assert(impact_batch["texture"].get_size() == Vector2(32.0, 32.0),
			"Weapon impact VFX must render one 32x32 animation cell, not the full strip")
	var impact_source := (impact_texture as AtlasTexture).atlas.get_image().get_region(
		Rect2i((impact_texture as AtlasTexture).region))
	assert(impact_batch["texture"].get_image().get_data() == impact_source.get_data(),
			"Weapon impact VFX batch must contain only its selected atlas region")
	view._sprite_renderer.set_entities([], Vector2.ZERO, 0.2, {}, [{
		"role": "weapon_minigun", "state": "impact_vfx", "position": Vector2(20, 30),
		"size": 28.0, "direction": Vector2.ZERO, "started_at": 0.0,
	}])
	assert(view._sprite_renderer.animated_multimesh_for(impact_animation, 2).instance_count == 1,
			"Weapon impact VFX should reach the cropped atlas frame in its runtime batch")
	view._sprite_renderer.set_entities([], Vector2.ZERO, 0.1, {}, [{
		"role": "xp_orb", "state": "collect", "position": Vector2(40, 50),
		"size": 14.0, "direction": Vector2.ZERO, "started_at": 0.0,
	}])
	assert(view._sprite_renderer.animated_multimesh_for("xp_orb_collect", 1).instance_count == 1,
			"Collected XP should play its authored collection animation after the orb despawns")
	var wall_start := Time.get_ticks_msec() * 0.001 - 0.2
	view._sprite_renderer.set_entities([], Vector2.ZERO, 0.1, {}, [{
		"role": "relic_storm_core", "state": "acquisition", "position": Vector2(60, 70),
		"size": 32.0, "direction": Vector2.ZERO, "started_at": wall_start, "use_wall_clock": true,
	}])
	assert(view._sprite_renderer.animated_multimesh_for("relic_storm_core_acquisition", 1).instance_count == 1,
			"Relic acquisition animation should advance on wall time while the reward choice pauses simulation")
	view.set_selected_entity(2502, 1)
	assert(not view._selected_entity_found, "Projectile animation instances should not become selectable targets")
	var shooter := _entity(2600, "shooter", 0, 0)
	shooter["components"]["Velocity2D"] = {"x": 80.0, "y": 0.0}
	view._sprite_renderer.set_entities([shooter], Vector2.ZERO, 0.2, {
		"2600:1": {"state": "attack", "started_at": 0.0},
	})
	assert(view._sprite_renderer.animated_multimesh_for("enemy_shooter_attack_up", 2).instance_count == 1,
			"Attack phase overrides should play the upright shooter attack frame")
	view._sprite_renderer.set_entities([], Vector2.ZERO, 0.15, {}, [{
		"role": "enemy_shooter", "state": "death", "position": Vector2(20, 30),
		"size": 24.0, "direction": Vector2.LEFT, "started_at": 0.0,
	}])
	assert(view._sprite_renderer.animated_multimesh_for("enemy_shooter_death_up", 1, true).instance_count == 1,
			"Transient deaths should preserve upright horizontal facing after despawn")
	view.set_selected_entity(10, 1)
	assert(view._selected_entity_found, "Selecting an enemy should preserve its overlay above the batches")
	if view._selected_point != Vector2(200, 160):
		_fail("Unexpected selected position: %s" % view._selected_point)
		return
	view.set_entities([])
	assert(view._enemy_multimesh.instance_count == 0, "Removing entities should clear stale render instances")
	assert(view._projectile_multimesh.instance_count == 0, "Removing entities should clear stale projectile instances")
	assert(view._sprite_renderer._projectile_trails.is_empty(), "Removing entities should clear projectile trails")
	assert(view._xp_multimesh.instance_count == 0, "Removing entities should clear stale XP instances")
	assert(not view._selected_entity_found, "Removing the selected entity should clear its overlay")
	print("Simulation view batches enemies, projectiles and XP with MultiMesh")
	quit()

func _entity(index: int, entity_type: String, x: float, y: float) -> Dictionary:
	var components := {"Transform2D": {"x": x, "y": y}}
	if entity_type == "projectile" or entity_type.begins_with("projectile_"):
		components["IsProjectile"] = true
		components["Velocity2D"] = {"x": 80.0, "y": 0.0}
		if entity_type == "projectile_inferno":
			components["EnemyType"] = "inferno_sprayer"
		elif entity_type == "projectile_minigun":
			components["EnemyType"] = "minigun"
		elif entity_type == "projectile_toxic_cloud":
			components["EnemyType"] = "toxic_cloud"
		elif entity_type == "projectile_sawblades":
			components["EnemyType"] = "sawblades"
		elif entity_type == "projectile_meteor":
			components["EnemyType"] = "meteor_staff"
		elif entity_type == "projectile_starfall_fragment":
			components["EnemyType"] = "starfall_fragment"
		elif entity_type == "projectile_void_orb":
			components["EnemyType"] = "void_orb"
		else:
			components["EnemyType"] = entity_type.trim_prefix("projectile_")
			match components["EnemyType"]:
				"infinite_circuit": components["EnemyType"] = "infinite_circuit_branch"
				"wildfire": components["EnemyType"] = "wildfire_sprayer"
				"bloodstorm": components["EnemyType"] = "bloodstorm_dagger"
				"pandemic": components["EnemyType"] = "pandemic_cloud"
	elif entity_type == "xp":
		components["IsXpOrb"] = true
	elif entity_type == "tank":
		components["EnemyType"] = "tank"
	else:
		components["EnemyType"] = entity_type
	return {"id": {"index": index, "generation": 1}, "components": components}

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
