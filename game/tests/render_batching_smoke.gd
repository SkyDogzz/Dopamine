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
	view.set_entities(entities)
	assert(view._enemy_multimesh.instance_count == 500, "500 enemies should fit one MultiMesh batch")
	assert(view._projectile_multimesh.instance_count == 2000, "2,000 projectiles should fit one MultiMesh batch")
	assert(view._xp_multimesh.instance_count == 1, "XP orbs should use a separate MultiMesh batch")
	assert(view._sprite_renderer.multimesh_for("enemy_tank").instance_count == 1, "Enemy profiles should use their sprite batches")
	assert(view._sprite_renderer.multimesh_for("projectile_inferno").instance_count == 1, "Weapon projectile art should remain distinct")
	assert(view._sprite_renderer.multimesh_for("projectile_minigun").instance_count == 1, "Minigun should use its own projectile art")
	assert(view._sprite_renderer._batches["projectile_minigun"]["texture"].resource_path.ends_with("projectile_minigun.svg"), "Minigun batch should load its distinct pixel-art sprite")
	assert(view._sprite_renderer.multimesh_for("projectile_toxic_cloud").instance_count == 1, "Toxic Cloud should use its own projectile art")
	assert(view._sprite_renderer._batches["projectile_toxic_cloud"]["texture"].resource_path.ends_with("projectile_toxic_cloud.svg"), "Toxic Cloud batch should load its distinct pixel-art sprite")
	assert(view._sprite_renderer._batches["enemy_chaser"]["texture"].resource_path.ends_with("enemy_chaser.png"), "Chaser batch should load its pixel-art sprite")
	view.set_selected_entity(10, 1)
	assert(view._selected_entity_found, "Selecting an enemy should preserve its overlay above the batches")
	if view._selected_point != Vector2(200, 160):
		_fail("Unexpected selected position: %s" % view._selected_point)
		return
	view.set_entities([])
	assert(view._enemy_multimesh.instance_count == 0, "Removing entities should clear stale render instances")
	assert(view._projectile_multimesh.instance_count == 0, "Removing entities should clear stale projectile instances")
	assert(view._xp_multimesh.instance_count == 0, "Removing entities should clear stale XP instances")
	assert(not view._selected_entity_found, "Removing the selected entity should clear its overlay")
	print("Simulation view batches enemies, projectiles and XP with MultiMesh")
	quit()

func _entity(index: int, entity_type: String, x: float, y: float) -> Dictionary:
	var components := {"Transform2D": {"x": x, "y": y}}
	if entity_type == "projectile" or entity_type.begins_with("projectile_"):
		components["IsProjectile"] = true
		if entity_type == "projectile_inferno":
			components["EnemyType"] = "inferno_sprayer"
		elif entity_type == "projectile_minigun":
			components["EnemyType"] = "minigun"
		elif entity_type == "projectile_toxic_cloud":
			components["EnemyType"] = "toxic_cloud"
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
