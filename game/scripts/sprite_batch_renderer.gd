extends RefCounted

const MAX_PROJECTILE_TRAILS := 256
const PROJECTILE_TRAIL_LENGTH := 12.0
const PROJECTILE_TRAIL_SHADOW := Color("#075A80", 0.8)
const PROJECTILE_TRAIL_COLOR := Color("#37E8F5", 0.72)
const SPRITE_FILES := {
	"enemy_chaser": "roster/enemy_chaser",
	"enemy_sprinter": "roster/enemy_sprinter",
	"enemy_tank": "roster/enemy_tank",
	"enemy_shooter": "roster/enemy_shooter",
	"enemy_buffer": "roster/enemy_buffer",
	"enemy_exploder": "roster/enemy_exploder",
	"enemy_shielder": "roster/enemy_shielder",
	"enemy_summoner": "roster/enemy_summoner",
	"enemy_summoned": "roster/enemy_summoned",
	"boss_mid_placeholder": "roster/boss_mid_placeholder",
	"boss_final_placeholder": "roster/boss_final_placeholder",
	"xp_orb": "rewards/xp_orb",
	"projectile_lightning": "projectiles/projectile_lightning",
	"projectile_inferno": "projectiles/projectile_inferno",
	"projectile_crimson": "projectiles/projectile_crimson",
	"projectile_enemy": "projectiles/projectile_enemy",
	"projectile_minigun": "projectiles/projectile_minigun",
	"projectile_toxic_cloud": "projectiles/projectile_toxic_cloud",
	"projectile_sawblades": "projectiles/projectile_sawblades",
	"projectile_meteor": "projectiles/projectile_meteor",
	"projectile_starfall_fragment": "projectiles/projectile_starfall_fragment",
	"projectile_prism_laser": "projectiles/projectile_prism_laser",
	"projectile_prism_secondary": "projectiles/projectile_prism_secondary",
	"projectile_void_orb": "projectiles/projectile_void_orb",
	"projectile_frost_nova": "projectiles/projectile_frost_nova",
	"projectile_infinite_circuit": "projectiles/projectile_infinite_circuit",
	"projectile_wildfire": "projectiles/projectile_wildfire",
	"projectile_bloodstorm": "projectiles/projectile_bloodstorm",
	"projectile_event_horizon": "projectiles/projectile_event_horizon",
	"projectile_absolute_zero": "projectiles/projectile_absolute_zero",
	"projectile_pandemic": "projectiles/projectile_pandemic",
	"projectile_razorstorm": "projectiles/projectile_razorstorm",
	"projectile_starfall": "projectiles/projectile_starfall",
	"projectile_spectrum_collapse": "projectiles/projectile_spectrum_collapse",
	"projectile_unique_lightning_burst": "projectiles/projectile_unique_lightning_burst",
	"projectile_evolution_shockwave": "projectiles/projectile_evolution_shockwave",
}

var _batches: Dictionary = {}
var _projectile_trails: Array[Dictionary] = []
var _selected_index := -1
var _selected_generation := -1
var selected_point := Vector2.ZERO
var selected_entity_found := false

func _init() -> void:
	for sprite_id in SPRITE_FILES:
		var mesh := MultiMesh.new()
		mesh.transform_format = MultiMesh.TRANSFORM_2D
		mesh.use_colors = true
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE
		mesh.mesh = quad
		var filename: String = SPRITE_FILES[sprite_id]
		if not filename.contains("."):
			filename += ".png"
		_batches[sprite_id] = {
			"texture": load("res://assets/sprites/%s" % filename),
			"multimesh": mesh,
		}

func set_entities(entities: Array, origin: Vector2 = Vector2.ZERO) -> void:
	var instances_by_sprite: Dictionary = {}
	_projectile_trails.clear()
	for sprite_id in _batches:
		instances_by_sprite[sprite_id] = []
	selected_entity_found = false
	for entity in entities:
		var components: Dictionary = entity["components"]
		var sprite_id := _sprite_for_entity(components)
		if not instances_by_sprite.has(sprite_id):
			continue
		var transform: Dictionary = components["Transform2D"]
		var point := origin + Vector2(float(transform["x"]), float(transform["y"]))
		var size := _size_for_entity(sprite_id)
		var rotation := 0.0
		if sprite_id.begins_with("projectile_"):
			var velocity: Dictionary = components.get("Velocity2D", {})
			var direction := Vector2(float(velocity.get("x", 0.0)), float(velocity.get("y", 0.0)))
			if direction.length_squared() > 0.001:
				rotation = direction.angle() + PI * 0.5
				if _projectile_trails.size() < MAX_PROJECTILE_TRAILS:
					var trail_end := point.round()
					_projectile_trails.append({
						"start": (point - direction.normalized() * PROJECTILE_TRAIL_LENGTH).round(),
						"end": trail_end,
					})
		instances_by_sprite[sprite_id].append({"point": point, "size": size, "rotation": rotation})
		var id: Dictionary = entity["id"]
		if int(id["index"]) == _selected_index and int(id["generation"]) == _selected_generation:
			selected_point = point
			selected_entity_found = not sprite_id.begins_with("projectile_") and sprite_id != "xp_orb"
	for sprite_id in _batches:
		_set_instances(_batches[sprite_id]["multimesh"], instances_by_sprite[sprite_id])

func set_selected_entity(index: int, generation: int) -> void:
	_selected_index = index
	_selected_generation = generation
	selected_entity_found = false

func draw_batches(canvas: CanvasItem) -> void:
	for sprite_id in _batches:
		var batch: Dictionary = _batches[sprite_id]
		var multimesh: MultiMesh = batch["multimesh"]
		if multimesh.instance_count > 0:
			canvas.draw_multimesh(multimesh, batch["texture"])

func draw_projectile_trails(canvas: CanvasItem) -> void:
	for trail in _projectile_trails:
		canvas.draw_line(trail["start"], trail["end"], PROJECTILE_TRAIL_SHADOW, 3.0, false)
		canvas.draw_line(trail["start"], trail["end"], PROJECTILE_TRAIL_COLOR, 1.0, false)

func draw_enemy_feedback(canvas: CanvasItem, entities: Array, origin: Vector2 = Vector2.ZERO) -> void:
	for entity in entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false):
			continue
		var transform: Dictionary = components["Transform2D"]
		var center := origin + Vector2(float(transform["x"]), float(transform["y"]))
		if str(components.get("EnemyType", "")) == "buffer":
			var radius := float(components.get("SupportRadius", 0.0))
			canvas.draw_circle(center, radius, Color(0.18, 0.96, 0.73, 0.055))
			canvas.draw_arc(center, radius, 0.0, TAU, 64, Color(0.25, 1.0, 0.78, 0.45), 2.0, true)
		elif components.get("Supported", false):
			canvas.draw_arc(center, 14.0, 0.0, TAU, 24, Color(0.3, 1.0, 0.72, 0.8), 2.0, true)
		if str(components.get("EnemyType", "")) == "shielder":
			var shield_radius := float(components.get("ShieldRadius", 0.0))
			canvas.draw_circle(center, shield_radius, Color(0.55, 0.48, 1.0, 0.045))
			canvas.draw_arc(center, shield_radius, 0.0, TAU, 64, Color(0.68, 0.61, 1.0, 0.5), 2.0, true)
		elif components.get("Shielded", false):
			canvas.draw_arc(center, 15.0, 0.0, TAU, 24, Color(0.55, 0.85, 1.0, 0.9), 2.0, true)
		if components.get("Affix", "") == "Hasted":
			canvas.draw_arc(center, 18.0, 0.0, TAU, 32, Color(1.0, 0.36, 0.25, 0.95), 2.5, true)

func multimesh_for(sprite_id: String) -> MultiMesh:
	if not _batches.has(sprite_id):
		return null
	return _batches[sprite_id]["multimesh"]

func _sprite_for_entity(components: Dictionary) -> String:
	if components.get("IsProjectile", false):
		var projectile_type: String = str(components.get("EnemyType", ""))
		match projectile_type:
			"inferno_sprayer":
				return "projectile_inferno"
			"wildfire_sprayer":
				return "projectile_wildfire"
			"crimson_dagger":
				return "projectile_crimson"
			"bloodstorm_dagger":
				return "projectile_bloodstorm"
			"enemy_projectile":
				return "projectile_enemy"
			"infinite_circuit_branch":
				return "projectile_infinite_circuit"
			"unique_lightning_burst":
				return "projectile_unique_lightning_burst"
			"evolution_shockwave":
				return "projectile_evolution_shockwave"
			"minigun":
				return "projectile_minigun"
			"toxic_cloud":
				return "projectile_toxic_cloud"
			"pandemic_cloud":
				return "projectile_pandemic"
			"sawblades":
				return "projectile_sawblades"
			"razorstorm":
				return "projectile_razorstorm"
			"meteor_staff":
				return "projectile_meteor"
			"starfall":
				return "projectile_starfall"
			"starfall_fragment":
				return "projectile_starfall_fragment"
			"spectrum_collapse":
				return "projectile_spectrum_collapse"
			"prism_secondary":
				return "projectile_prism_secondary"
			"prism_laser":
				return "projectile_prism_laser"
			"void_orb":
				return "projectile_void_orb"
			"event_horizon":
				return "projectile_event_horizon"
			"frost_nova":
				return "projectile_frost_nova"
			"absolute_zero":
				return "projectile_absolute_zero"
			_:
				return "projectile_lightning"
	if components.get("IsXpOrb", false):
		return "xp_orb"
	var enemy_type: String = str(components.get("EnemyType", "chaser"))
	match enemy_type:
		"sprinter":
			return "enemy_sprinter"
		"tank":
			return "enemy_tank"
		"shooter":
			return "enemy_shooter"
		"buffer":
			return "enemy_buffer"
		"exploder":
			return "enemy_exploder"
		"shielder":
			return "enemy_shielder"
		"summoner":
			return "enemy_summoner"
		"summoned":
			return "enemy_summoned"
		"elite":
			return "enemy_sprinter"
		"mid_boss":
			return "boss_mid_placeholder"
		"final_boss":
			return "boss_final_placeholder"
		_:
			return "enemy_chaser"

func _size_for_entity(sprite_id: String) -> float:
	if sprite_id == "projectile_starfall_fragment":
		return 10.0
	if sprite_id.begins_with("boss_"):
		return 52.0
	if sprite_id.begins_with("projectile_"):
		return 14.0
	if sprite_id == "xp_orb":
		return 18.0
	return 24.0

func _set_instances(multimesh: MultiMesh, instances: Array) -> void:
	multimesh.instance_count = instances.size()
	for index in range(instances.size()):
		var instance: Dictionary = instances[index]
		var size: float = instance["size"]
		var transform := Transform2D(float(instance["rotation"]), instance["point"])
		transform.x *= size
		transform.y *= size
		multimesh.set_instance_transform_2d(index, transform)
		multimesh.set_instance_color(index, Color.WHITE)
