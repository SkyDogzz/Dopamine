extends SceneTree

const TARGETING := preload("res://scripts/survival_targeting.gd")

func _initialize() -> void:
	var projectile := _enemy(5, Vector2(1.0, 0.0), 100.0, 1000.0)
	projectile["components"]["IsProjectile"] = true
	var xp_orb := _enemy(6, Vector2(2.0, 0.0), 100.0, 1000.0)
	xp_orb["components"]["IsXpOrb"] = true
	var entities := [
		_enemy(1, Vector2(100.0, 0.0), 20.0, 1.0),
		_enemy(2, Vector2(300.0, 0.0), 80.0, 5.0),
		_enemy(3, Vector2(200.0, 0.0), 40.0, 2.0),
		_enemy(4, Vector2(50.0, 0.0), 0.0, 100.0),
		projectile,
		xp_orb,
	]
	assert(_id("nearest", entities) == 1, "Nearest targeting should choose the closest living enemy")
	assert(_id("farthest", entities) == 2, "Farthest targeting should choose the farthest living enemy")
	assert(_id("highest_threat", entities) == 2, "Threat targeting should prefer threat before distance")
	assert(_id("highest_health", entities) == 2, "Highest health targeting should choose the strongest living enemy")
	assert(_id("lowest_health", entities) == 1, "Lowest health targeting should ignore dead enemies")
	assert(TARGETING.select_enemy(entities, Vector2.ZERO, 250.0, "farthest")["id"].x == 3,
		"Range limits should exclude the farthest enemy without excluding closer targets")
	assert(TARGETING.select_enemy(entities, Vector2.ZERO, 90.0, "nearest").is_empty(),
		"Targeting should return no target when enemies exceed the weapon range")
	print("Survival targeting policy smoke passed")
	quit()

func _id(policy: String, entities: Array) -> int:
	return int(TARGETING.select_enemy(entities, Vector2.ZERO, 500.0, policy)["id"].x)

func _enemy(index: int, position: Vector2, health: float, threat: float) -> Dictionary:
	return {
		"id": {"index": index, "generation": 1},
		"components": {
			"Transform2D": {"x": position.x, "y": position.y},
			"Health": {"current": health, "maximum": health},
			"ThreatLevel": threat,
		},
	}
