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
	view.set_entities(entities)
	assert(view._enemy_multimesh.instance_count == 500, "500 enemies should fit one MultiMesh batch")
	assert(view._projectile_multimesh.instance_count == 2000, "2,000 projectiles should fit one MultiMesh batch")
	assert(view._xp_multimesh.instance_count == 1, "XP orbs should use a separate MultiMesh batch")
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
	if entity_type == "projectile":
		components["IsProjectile"] = true
	elif entity_type == "xp":
		components["IsXpOrb"] = true
	else:
		components["EnemyType"] = entity_type
	return {"id": {"index": index, "generation": 1}, "components": components}

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
