extends RefCounted

# The camera shows a 1280x720 logical viewport centered on the player. Keeping
# every weapon's targeting radius within the 360-unit half-height guarantees
# selected targets stay inside the visible rectangle in every direction.
const VISIBLE_TARGET_RADIUS := 360.0
const BASE_MAX_WEAPON_RANGE := 620.0
const WEAPON_RANGE_SCALE := VISIBLE_TARGET_RADIUS / BASE_MAX_WEAPON_RANGE

const MINIGUN_RANGE := 620.0
const INFERNO_RANGE := 520.0
const TOXIC_RANGE := 560.0
const DAGGERS_RANGE := 480.0
const VOID_ORB_RANGE := 620.0
const LIGHTNING_RANGE := 300.0
const LIGHTNING_CLUSTER_RADIUS := 120.0
const SAWBLADES_RANGE := 520.0
const SAWBLADES_CLUSTER_RADIUS := 160.0
const METEOR_RANGE := 620.0
const METEOR_CLUSTER_RADIUS := 110.0
const PRISM_RANGE := 620.0
const PRISM_CLUSTER_RADIUS := 180.0

static func weapon_range(base_range: float, upgrade_multiplier := 1.0, area_multiplier := 1.0) -> float:
	return minf(base_range * WEAPON_RANGE_SCALE * upgrade_multiplier * area_multiplier, VISIBLE_TARGET_RADIUS)

static func visible_range(base_range: float) -> float:
	return minf(base_range * WEAPON_RANGE_SCALE, VISIBLE_TARGET_RADIUS)

static func is_inside_visible_radius(origin: Vector2, target: Vector2) -> bool:
	return origin.distance_squared_to(target) <= VISIBLE_TARGET_RADIUS * VISIBLE_TARGET_RADIUS

static func preview_defaults(policy: String) -> Dictionary:
	match policy:
		"nearest":
			return {"range": MINIGUN_RANGE, "cluster_radius": 0.0}
		"highest_threat":
			return {"range": INFERNO_RANGE, "cluster_radius": 0.0}
		"highest_health":
			return {"range": TOXIC_RANGE, "cluster_radius": 0.0}
		"lowest_health":
			return {"range": DAGGERS_RANGE, "cluster_radius": 0.0}
		"farthest":
			return {"range": VOID_ORB_RANGE, "cluster_radius": 0.0}
		"lightning_cluster":
			return {"range": LIGHTNING_RANGE, "cluster_radius": LIGHTNING_CLUSTER_RADIUS}
		"sawblades_cluster":
			return {"range": SAWBLADES_RANGE, "cluster_radius": SAWBLADES_CLUSTER_RADIUS}
		"meteor_centroid":
			return {"range": METEOR_RANGE, "cluster_radius": METEOR_CLUSTER_RADIUS}
		"prism_cluster":
			return {"range": PRISM_RANGE, "cluster_radius": PRISM_CLUSTER_RADIUS}
	return {}

static func preview_target(entities: Array, origin: Vector2, max_range: float,
		cluster_radius: float, policy: String) -> Dictionary:
	match policy:
		"lightning_cluster":
			return select_dense_cluster_target(entities, origin, max_range, cluster_radius)
		"prism_cluster":
			return select_dense_cluster_target(entities, origin, max_range, cluster_radius, false, "highest_health")
		"sawblades_cluster":
			return select_dense_cluster_target(entities, origin, max_range, cluster_radius, true)
		"meteor_centroid":
			return select_cluster_centroid(entities, origin, max_range, cluster_radius)
		_:
			return select_enemy(entities, origin, max_range, policy)

static func select_enemy(entities: Array, origin: Vector2, max_range: float, policy: String) -> Dictionary:
	var nearest: Dictionary = {}
	var best_distance_squared := max_range * max_range
	var best_value := -INF if policy in ["farthest", "highest_threat", "highest_health"] else INF
	for entity in entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("IsXpOrb", false):
			continue
		var health: Variant = components.get("Health")
		if components.has("Health"):
			if not health is Dictionary or not (float(health.get("current", 0.0)) > 0.0):
				continue
		var transform: Dictionary = components["Transform2D"]
		var position := Vector2(float(transform["x"]), float(transform["y"]))
		var distance_squared := origin.distance_squared_to(position)
		if distance_squared >= max_range * max_range:
			continue
		var value := 0.0
		match policy:
			"nearest":
				value = distance_squared
			"farthest":
				value = distance_squared
			"highest_threat":
				value = float(components.get("ThreatLevel", 1.0))
				if not is_finite(value) or value <= 0.0:
					value = 1.0
			"highest_health", "lowest_health":
				if not health is Dictionary:
					continue
				value = float(health.get("current", 0.0))
				if not is_finite(value) or value <= 0.0:
					continue
			_:
				return {}
		var selected := false
		match policy:
			"nearest":
				selected = distance_squared < best_value
			"farthest":
				selected = distance_squared > best_value
			"highest_threat", "highest_health":
				selected = value > best_value or (is_equal_approx(value, best_value) and distance_squared < best_distance_squared)
			"lowest_health":
				selected = value < best_value or (is_equal_approx(value, best_value) and distance_squared < best_distance_squared)
		if selected:
			best_value = value
			best_distance_squared = distance_squared
			var id: Dictionary = entity["id"]
			nearest = {"position": position, "id": Vector2i(int(id["index"]), int(id["generation"]))}
	return nearest

static func select_dense_cluster_target(entities: Array, origin: Vector2, max_range: float,
		cluster_radius: float, include_out_of_range_neighbors := false,
		priority := "nearest") -> Dictionary:
	var candidates: Array[Dictionary] = []
	var all_targets: Array[Dictionary] = []
	for entity in entities:
		var target := _target_for(entity)
		if target.is_empty():
			continue
		var health: Variant = entity["components"].get("Health", {})
		target["health"] = float(health.get("current", 0.0)) if health is Dictionary else 0.0
		all_targets.append(target)
		if origin.distance_squared_to(target["position"]) < max_range * max_range:
			candidates.append(target)
	if candidates.is_empty():
		return {}
	var cluster_targets := all_targets if include_out_of_range_neighbors else candidates
	var best_target: Dictionary = candidates[0]
	var best_neighbor_count := 0
	var best_distance_squared := origin.distance_squared_to(best_target["position"])
	var best_priority_value := -INF
	var cluster_radius_squared := cluster_radius * cluster_radius
	for candidate in candidates:
		var neighbor_count := 0
		for other in cluster_targets:
			if candidate["position"].distance_squared_to(other["position"]) <= cluster_radius_squared:
				neighbor_count += 1
		var distance_squared: float = origin.distance_squared_to(candidate["position"])
		var priority_value := 0.0
		if priority == "highest_health":
			priority_value = float(candidate["health"])
		var selected := neighbor_count > best_neighbor_count
		if neighbor_count == best_neighbor_count:
			selected = priority_value > best_priority_value or (
				is_equal_approx(priority_value, best_priority_value) and distance_squared < best_distance_squared
			) if priority == "highest_health" else distance_squared < best_distance_squared
		if selected:
			best_target = candidate
			best_neighbor_count = neighbor_count
			best_distance_squared = distance_squared
			best_priority_value = priority_value
	return {"position": best_target["position"], "id": best_target["id"]}

static func select_cluster_centroid(entities: Array, origin: Vector2, max_range: float,
		cluster_radius: float) -> Dictionary:
	var targets: Array[Dictionary] = []
	var candidates: Array[Dictionary] = []
	for entity in entities:
		var target := _target_for(entity)
		if target.is_empty():
			continue
		targets.append(target)
		if origin.distance_squared_to(target["position"]) < max_range * max_range:
			candidates.append(target)
	if candidates.is_empty():
		return {}
	var best_target: Dictionary = {}
	var best_center := Vector2.ZERO
	var best_cluster_size := 0
	var best_distance_squared := max_range * max_range
	var cluster_radius_squared := cluster_radius * cluster_radius
	for candidate in candidates:
		var center := Vector2.ZERO
		var cluster_size := 0
		for other in targets:
			if candidate["position"].distance_squared_to(other["position"]) <= cluster_radius_squared:
				center += other["position"]
				cluster_size += 1
		var distance_squared: float = origin.distance_squared_to(candidate["position"])
		if cluster_size > best_cluster_size or (cluster_size == best_cluster_size and distance_squared < best_distance_squared):
			best_target = candidate
			best_center = center / float(cluster_size)
			best_cluster_size = cluster_size
			best_distance_squared = distance_squared
	return {"id": best_target["id"], "position": best_center} if not best_target.is_empty() else {}

static func _target_for(entity: Dictionary) -> Dictionary:
	var components: Dictionary = entity["components"]
	if components.get("IsProjectile", false) or components.get("IsXpOrb", false):
		return {}
	if components.has("Health"):
		var health: Variant = components["Health"]
		if not health is Dictionary or not (float(health.get("current", 0.0)) > 0.0):
			return {}
	var transform: Dictionary = components["Transform2D"]
	var id: Dictionary = entity["id"]
	return {
		"position": Vector2(float(transform["x"]), float(transform["y"])),
		"id": Vector2i(int(id["index"]), int(id["generation"])),
	}
