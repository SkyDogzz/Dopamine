extends RefCounted

const MINIGUN_RANGE := 620.0

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
