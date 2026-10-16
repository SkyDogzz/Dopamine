extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var view := Control.new()
	view.set_script(load("res://scripts/simulation_view.gd"))
	view.size = Vector2(640, 460)
	root.add_child(view)
	await process_frame
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
	for index in range(9):
		var names := ["infinite_circuit", "wildfire", "bloodstorm", "event_horizon", "absolute_zero", "pandemic", "razorstorm", "starfall", "spectrum_collapse"]
		entities.append(_entity(2510 + index, "projectile_" + names[index], -80.0 + index * 18.0, 0.0))
	view.set_entities(entities)
	assert(view._enemy_multimesh.instance_count == 500, "500 enemies should fit one MultiMesh batch")
	assert(view._projectile_multimesh.instance_count == 2000, "2,000 projectiles should fit one MultiMesh batch")
	assert(view._sprite_renderer._projectile_trails.size() == view._sprite_renderer.MAX_PROJECTILE_TRAILS, "Projectile trails should use a fixed visual budget under load")
	assert(view._sprite_renderer._projectile_trails[0]["start"].x < view._sprite_renderer._projectile_trails[0]["end"].x, "A right-moving projectile should trail behind its current position")
	assert(is_equal_approx(view._sprite_renderer._projectile_trails[0]["start"].distance_to(view._sprite_renderer._projectile_trails[0]["end"]), 12.0), "Projectile trails should keep the proposed 12-pixel length")
	assert(view._xp_multimesh.instance_count == 1, "XP orbs should use a separate MultiMesh batch")
	assert(view._sprite_renderer._batches["xp_orb"]["texture"].resource_path.ends_with("rewards/xp_orb.png"), "XP should load its dedicated pixel-art reward sprite")
	assert(view._sprite_renderer.multimesh_for("enemy_tank").instance_count == 1, "Enemy profiles should use their sprite batches")
	assert(view._sprite_renderer.multimesh_for("projectile_inferno").instance_count == 1, "Weapon projectile art should remain distinct")
	assert(view._sprite_renderer.multimesh_for("projectile_minigun").instance_count == 1, "Minigun should use its own projectile art")
	assert(view._sprite_renderer._batches["projectile_minigun"]["texture"].resource_path.ends_with("projectiles/projectile_minigun.png"), "Minigun batch should load its distinct pixel-art sprite")
	assert(view._sprite_renderer.multimesh_for("projectile_toxic_cloud").instance_count == 1, "Toxic Cloud should use its own projectile art")
	assert(view._sprite_renderer.multimesh_for("projectile_sawblades").instance_count == 1, "Sawblades should use their own projectile art")
	assert(view._sprite_renderer.multimesh_for("projectile_meteor").instance_count == 1, "Meteor Staff should use dedicated meteor art")
	assert(view._sprite_renderer.multimesh_for("projectile_starfall_fragment").instance_count == 1, "Starfall fragments should use separate art")
	assert(view._sprite_renderer.multimesh_for("projectile_void_orb").instance_count == 1, "Void Orb and Event Horizon should use dedicated art")
	assert(view._sprite_renderer._batches["projectile_sawblades"]["texture"].resource_path.ends_with("projectiles/projectile_sawblades.png"), "Sawblades should load their dedicated pixel-art sprite")
	assert(view._sprite_renderer._batches["projectile_meteor"]["texture"].resource_path.ends_with("projectiles/projectile_meteor.png"), "Meteor Staff should load its pixel-art meteor")
	assert(view._sprite_renderer._batches["projectile_starfall_fragment"]["texture"].resource_path.ends_with("projectiles/projectile_starfall_fragment.png"), "Starfall should load its fragment sprite")
	assert(view._sprite_renderer._batches["projectile_void_orb"]["texture"].resource_path.ends_with("projectiles/projectile_void_orb.png"), "Void Orb should load its dedicated sprite")
	assert(view._sprite_renderer._batches["projectile_toxic_cloud"]["texture"].resource_path.ends_with("projectiles/projectile_toxic_cloud.png"), "Toxic Cloud batch should load its distinct pixel-art sprite")
	for projectile_name in ["infinite_circuit", "wildfire", "bloodstorm", "event_horizon", "absolute_zero", "pandemic", "razorstorm", "starfall", "spectrum_collapse"]:
		var batch_name: String = "projectile_" + projectile_name
		assert(view._sprite_renderer.multimesh_for(batch_name).instance_count == 1, "Evolved projectile %s should use its own batch" % projectile_name)
	assert(view._sprite_renderer._batches["enemy_chaser"]["texture"].resource_path.ends_with("enemy_chaser.png"), "Chaser batch should load its pixel-art sprite")
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
