extends SceneTree

const TARGETING := preload("res://scripts/survival_targeting.gd")

func _initialize() -> void:
	var range_defaults: Array[String] = ["nearest", "highest_threat", "highest_health", "lowest_health", "farthest", "lightning_cluster", "sawblades_cluster", "meteor_centroid", "prism_cluster"]
	for policy in range_defaults:
		var defaults: Dictionary = TARGETING.preview_defaults(policy)
		assert(TARGETING.weapon_range(float(defaults["range"])) <= TARGETING.VISIBLE_TARGET_RADIUS,
			"%s Survival range must stay within the visible radius" % policy)
	assert(is_equal_approx(TARGETING.WEAPON_RANGE_SCALE, 360.0 / 620.0),
		"Every weapon range should use the common reduction derived from Prism's maximum base reach")
	assert(is_equal_approx(TARGETING.weapon_range(620.0, 1.38, 1.2), TARGETING.VISIBLE_TARGET_RADIUS),
		"Even fully upgraded Prism with area bonuses must not target beyond the screen-safe radius")
	assert(is_equal_approx(TARGETING.visible_range(620.0), TARGETING.VISIBLE_TARGET_RADIUS),
		"The common reduction should reduce the former 620-unit reach to the screen-safe radius")
	assert(is_equal_approx(TARGETING.visible_range(1000.0), TARGETING.VISIBLE_TARGET_RADIUS),
		"Edited weapon ranges must also respect the visible radius")
	assert(TARGETING.is_inside_visible_radius(Vector2.ZERO, Vector2(0.0, 360.0)) and
		not TARGETING.is_inside_visible_radius(Vector2.ZERO, Vector2(361.0, 0.0)),
		"Primary and chain target selectors should reject enemies beyond the visible circle")
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
	var cluster_entities := [
		_enemy(10, Vector2(50.0, 0.0), 20.0, 1.0),
		_enemy(11, Vector2(300.0, 0.0), 20.0, 1.0),
		_enemy(12, Vector2(350.0, 0.0), 20.0, 1.0),
		_enemy(13, Vector2(370.0, 0.0), 20.0, 1.0),
		_enemy(14, Vector2(490.0, 0.0), 20.0, 1.0),
	]
	assert(TARGETING.select_dense_cluster_target(cluster_entities, Vector2.ZERO, 400.0, 120.0)["id"].x == 11,
		"Lightning and Prism selectors should choose the nearest member of the densest in-range cluster")
	assert(TARGETING.select_dense_cluster_target(cluster_entities, Vector2.ZERO, 400.0, 150.0, true)["id"].x == 12,
		"Sawblades selector should count live neighbors outside launch range")
	var meteor_target: Dictionary = TARGETING.select_cluster_centroid(cluster_entities, Vector2.ZERO, 400.0, 110.0)
	assert(meteor_target["id"].x == 11 and is_equal_approx(meteor_target["position"].x, 340.0),
		"Meteor selector should aim at the densest cluster centroid while retaining its primary target ID")
	var prism_entities := [
		_enemy(20, Vector2(50.0, 0.0), 100.0, 1.0),
		_enemy(21, Vector2(300.0, 0.0), 20.0, 1.0),
		_enemy(22, Vector2(350.0, 0.0), 200.0, 1.0),
		_enemy(23, Vector2(370.0, 0.0), 40.0, 1.0),
	]
	var lightning_primary: Dictionary = TARGETING.preview_target(prism_entities, Vector2.ZERO, 400.0, 100.0, "lightning_cluster")
	var prism_primary: Dictionary = TARGETING.preview_target(prism_entities, Vector2.ZERO, 400.0, 100.0, "prism_cluster")
	assert(lightning_primary["id"].x == 21 and prism_primary["id"].x == 22,
		"Lightning should start at the nearest member of a dense cluster while Prism should focus its highest-health member")
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
