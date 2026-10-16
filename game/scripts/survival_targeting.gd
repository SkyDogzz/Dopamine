extends RefCounted

const MINIGUN_RANGE := 620.0

static func nearest_enemy(entities: Array, origin: Vector2, max_range: float) -> Dictionary:
	var nearest: Dictionary = {}
	var best_distance_squared := max_range * max_range
	for entity in entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("IsXpOrb", false):
			continue
		if components.has("Health"):
			var health: Variant = components["Health"]
			if not health is Dictionary or float(health.get("current", 0.0)) <= 0.0:
				continue
		var transform: Dictionary = components["Transform2D"]
		var position := Vector2(float(transform["x"]), float(transform["y"]))
		var distance_squared := origin.distance_squared_to(position)
		if distance_squared < best_distance_squared:
			best_distance_squared = distance_squared
			var id: Dictionary = entity["id"]
			nearest = {"position": position, "id": Vector2i(int(id["index"]), int(id["generation"]))}
	return nearest
