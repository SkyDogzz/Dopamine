extends RefCounted

const MAX_PROJECTILE_TRAILS := 256
const PROJECTILE_TRAIL_LENGTH := 12.0
const PERSISTENT_AREA_RIPPLE_PERIOD := 1.2
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
	"boss_pulse_warden": "roster/boss_pulse_warden",
	"boss_dopamine_core": "roster/boss_dopamine_core",
	"xp_orb": "rewards/xp_orb",
	"projectile_lightning": "projectiles/projectile_lightning",
	"projectile_inferno": "projectiles/projectile_inferno",
	"projectile_crimson": "projectiles/projectile_crimson",
	"projectile_enemy": "projectiles/projectile_enemy",
	"projectile_minigun": "projectiles/projectile_minigun",
	"projectile_redline": "projectiles/projectile_minigun",
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
	"projectile_shatter_impact": "projectiles/projectile_absolute_zero",
	"projectile_shatter_fragment": "projectiles/projectile_absolute_zero",
	"projectile_pandemic": "projectiles/projectile_pandemic",
	"projectile_razorstorm": "projectiles/projectile_razorstorm",
	"projectile_starfall": "projectiles/projectile_starfall",
	"projectile_spectrum_collapse": "projectiles/projectile_spectrum_collapse",
	"projectile_unique_lightning_burst": "projectiles/projectile_unique_lightning_burst",
	"projectile_evolution_shockwave": "projectiles/projectile_evolution_shockwave",
}
const SPRITE_COLORS := {"projectile_redline": Color("#FF7181")}
const PROJECTILE_ANIMATION_ALIASES := {
	"projectile_redline": "projectile_minigun",
	"projectile_shatter_impact": "projectile_absolute_zero",
	"projectile_shatter_fragment": "projectile_absolute_zero",
}
const WEAPON_ANIMATION_IDS := [
	"lightning_conductor", "infinite_circuit", "inferno_sprayer", "wildfire",
	"crimson_daggers", "bloodstorm", "minigun", "redline", "toxic_cloud", "pandemic",
	"sawblades", "razorstorm", "meteor_staff", "starfall", "prism_laser",
	"spectrum_collapse", "void_orb", "event_horizon", "frost_nova", "absolute_zero",
]
const WEAPON_VFX_FAMILIES := [
	"lightning_conductor", "inferno_sprayer", "crimson_daggers", "minigun", "toxic_cloud",
	"sawblades", "meteor_staff", "prism_laser", "void_orb", "frost_nova",
]
const ANIMATED_ROLE_IDS := [
	"enemy_chaser", "enemy_sprinter", "enemy_tank", "enemy_shooter", "enemy_buffer",
	"enemy_exploder", "enemy_shielder", "enemy_summoner", "enemy_summoned",
	"elite_sprinter", "boss_pulse_warden", "boss_dopamine_core",
]

var _batches: Dictionary = {}
var _role_animation_sets: Dictionary = {}
var _animated_batches: Dictionary = {}
var _projectile_trails: Array[Dictionary] = []
var _selected_index := -1
var _selected_generation := -1
var selected_point := Vector2.ZERO
var selected_entity_found := false

func _init() -> void:
	for sprite_id in SPRITE_FILES:
		var mesh := MultiMesh.new()
		mesh.transform_format = MultiMesh.TRANSFORM_2D
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE
		mesh.mesh = quad
		mesh.use_colors = true
		var filename: String = SPRITE_FILES[sprite_id]
		if not filename.contains("."):
			filename += ".png"
		_batches[sprite_id] = {
			"texture": load("res://assets/sprites/%s" % filename) if ResourceLoader.exists("res://assets/sprites/%s" % filename) else null,
			"multimesh": mesh,
		}
	for role_id in ANIMATED_ROLE_IDS:
		_role_animation_sets[role_id] = {}
		for state in ["idle", "move", "attack", "special", "death"]:
			var resource_path := "res://assets/sprites/animation/%s_%s.tres" % [role_id, state]
			if ResourceLoader.exists(resource_path):
				_role_animation_sets[role_id][state] = load(resource_path) as SpriteFrames
	for sprite_id in SPRITE_FILES:
		if not sprite_id.begins_with("projectile_"):
			continue
		var animation_id: String = PROJECTILE_ANIMATION_ALIASES.get(sprite_id, sprite_id)
		var resource_path := "res://assets/sprites/animation/%s.tres" % animation_id
		if ResourceLoader.exists(resource_path):
			_role_animation_sets[sprite_id] = {"projectile": load(resource_path) as SpriteFrames}
	for weapon_id in WEAPON_ANIMATION_IDS:
		var attack_path := "res://assets/sprites/animation/%s_attack.tres" % weapon_id
		if ResourceLoader.exists(attack_path):
			_role_animation_sets["weapon_%s" % weapon_id] = {"attack": load(attack_path) as SpriteFrames}
	for family in WEAPON_VFX_FAMILIES:
		var weapon_role := "weapon_%s" % family
		_role_animation_sets[weapon_role] = _role_animation_sets.get(weapon_role, {})
		for state in ["fire_vfx", "impact_vfx"]:
			var vfx_path := "res://assets/sprites/animation/%s_%s.tres" % [family, state.trim_suffix("_vfx")]
			if ResourceLoader.exists(vfx_path):
				_role_animation_sets[weapon_role][state] = load(vfx_path) as SpriteFrames

func set_entities(entities: Array, origin: Vector2 = Vector2.ZERO, animation_time: float = 0.0,
		animation_overrides: Dictionary = {}, transient_animations: Array = []) -> void:
	var instances_by_sprite: Dictionary = {}
	var instances_by_animation: Dictionary = {}
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
		var size := _size_for_entity(sprite_id, components)
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
		var id: Dictionary = entity["id"]
		var entity_key := "%d:%d" % [int(id["index"]), int(id["generation"])]
		var override: Variant = animation_overrides.get(entity_key, {})
		var override_state := str(override.get("state", "")) if override is Dictionary else str(override)
		var entity_animation_time := animation_time
		if override is Dictionary and override.has("started_at"):
			entity_animation_time = maxf(0.0, animation_time - float(override["started_at"]))
		var animation := _animation_for_projectile(sprite_id, animation_time) if sprite_id.begins_with("projectile_") else \
				_animation_for_entity(components, entity_animation_time, override_state)
		if not animation.is_empty():
			var animation_key := "%s:%d" % [animation["name"], animation["frame"]]
			var animation_batch := _get_animation_batch(animation["role"], animation["state"],
					animation["name"], int(animation["frame"]))
			if not animation_batch.is_empty():
				if not instances_by_animation.has(animation_key):
					instances_by_animation[animation_key] = []
				instances_by_animation[animation_key].append({
					"point": point, "size": size, "rotation": rotation,
					"color": SPRITE_COLORS.get(sprite_id, Color.WHITE),
				})
				if int(id["index"]) == _selected_index and int(id["generation"]) == _selected_generation:
					selected_point = point
					selected_entity_found = not sprite_id.begins_with("projectile_") and sprite_id != "xp_orb"
				continue
		instances_by_sprite[sprite_id].append({"point": point, "size": size, "rotation": rotation})
		instances_by_sprite[sprite_id][-1]["color"] = SPRITE_COLORS.get(sprite_id, Color.WHITE)
		if int(id["index"]) == _selected_index and int(id["generation"]) == _selected_generation:
			selected_point = point
			selected_entity_found = not sprite_id.begins_with("projectile_") and sprite_id != "xp_orb"
	for transient in transient_animations:
		_append_transient_animation(instances_by_animation, transient, origin, animation_time)
	for sprite_id in _batches:
		_set_instances(_batches[sprite_id]["multimesh"], instances_by_sprite[sprite_id])
	for animation_key in _animated_batches:
		_set_instances(_animated_batches[animation_key]["multimesh"],
				instances_by_animation.get(animation_key, []))

func set_selected_entity(index: int, generation: int) -> void:
	_selected_index = index
	_selected_generation = generation
	selected_entity_found = false

func draw_batches(canvas: CanvasItem) -> void:
	for sprite_id in _batches:
		var batch: Dictionary = _batches[sprite_id]
		var multimesh: MultiMesh = batch["multimesh"]
		if multimesh.instance_count > 0 and batch["texture"] != null:
			canvas.draw_multimesh(multimesh, batch["texture"])
	for batch in _animated_batches.values():
		var multimesh: MultiMesh = batch["multimesh"]
		if multimesh.instance_count > 0 and batch["texture"] != null:
			canvas.draw_multimesh(multimesh, batch["texture"])

func animated_multimesh_for(animation_name: String, frame: int) -> MultiMesh:
	var key := "%s:%d" % [animation_name, frame]
	if not _animated_batches.has(key):
		return null
	return _animated_batches[key]["multimesh"]

func animated_instance_count_for_role(role_id: String) -> int:
	var total := 0
	for state in _role_animation_sets.get(role_id, {}).values():
		var sprite_frames: SpriteFrames = state
		for animation_name in sprite_frames.get_animation_names():
			var key_prefix := "%s:" % animation_name
			for animation_key in _animated_batches:
				if str(animation_key).begins_with(key_prefix):
					total += (_animated_batches[animation_key]["multimesh"] as MultiMesh).instance_count
	return total

func _animation_for_projectile(sprite_id: String, animation_time: float) -> Dictionary:
	var sprite_frames: SpriteFrames = _role_animation_sets.get(sprite_id, {}).get("projectile")
	if sprite_frames == null:
		return {}
	var names := sprite_frames.get_animation_names()
	if names.is_empty():
		return {}
	var animation_name: String = names[0]
	var frame_count := sprite_frames.get_frame_count(animation_name)
	var fps := sprite_frames.get_animation_speed(animation_name)
	if frame_count <= 0 or fps <= 0.0:
		return {}
	var frame := posmod(floori(animation_time * fps), frame_count)
	return {"role": sprite_id, "state": "projectile", "name": animation_name, "frame": frame}

func _animation_for_entity(components: Dictionary, animation_time: float, state_override: String = "") -> Dictionary:
	if components.get("IsProjectile", false) or components.get("IsXpOrb", false):
		return {}
	var enemy_type := str(components.get("EnemyType", "chaser"))
	var role_id := ""
	match enemy_type:
		"elite": role_id = "elite_sprinter"
		"mid_boss": role_id = "boss_pulse_warden"
		"final_boss": role_id = "boss_dopamine_core"
		_: role_id = "enemy_%s" % enemy_type
	if not _role_animation_sets.has(role_id):
		return {}
	var velocity: Dictionary = components.get("Velocity2D", {})
	var direction := Vector2(float(velocity.get("x", 0.0)), float(velocity.get("y", 0.0)))
	var state := state_override if state_override in ["attack", "death", "special"] else \
			("move" if direction.length_squared() > 1.0 else "idle")
	var sprite_frames: SpriteFrames = _role_animation_sets[role_id].get(state)
	if sprite_frames == null:
		return {}
	var base_name := "%s_%s" % [role_id, state]
	var animation_name := base_name
	if sprite_frames.has_animation(base_name + "_down"):
		var direction_name := "down"
		if direction.length_squared() > 0.001:
			if absf(direction.x) > absf(direction.y):
				direction_name = "right" if direction.x > 0.0 else "left"
			else:
				direction_name = "down" if direction.y > 0.0 else "up"
		animation_name = base_name + "_" + direction_name
	if not sprite_frames.has_animation(animation_name):
		return {}
	var frame_count := sprite_frames.get_frame_count(animation_name)
	if frame_count <= 0:
		return {}
	var fps := sprite_frames.get_animation_speed(animation_name)
	var frame := posmod(floori(animation_time * fps), frame_count)
	if not sprite_frames.get_animation_loop(animation_name):
		frame = mini(floori(animation_time * fps), frame_count - 1)
	return {"role": role_id, "state": state, "name": animation_name, "frame": frame}

func _get_animation_batch(role_id: String, state: String, animation_name: String, frame: int) -> Dictionary:
	var key := "%s:%d" % [animation_name, frame]
	if _animated_batches.has(key):
		return _animated_batches[key]
	var sprite_frames: SpriteFrames = _role_animation_sets.get(role_id, {}).get(state)
	if sprite_frames == null or frame >= sprite_frames.get_frame_count(animation_name):
		return {}
	var texture := sprite_frames.get_frame_texture(animation_name, frame)
	if texture == null:
		return {}
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	multimesh.mesh = quad
	multimesh.use_colors = true
	var batch := {"texture": texture, "multimesh": multimesh}
	_animated_batches[key] = batch
	return batch

func animation_duration(role_id: String, state: String, direction: String = "down") -> float:
	var sprite_frames: SpriteFrames = _role_animation_sets.get(role_id, {}).get(state)
	if sprite_frames == null:
		return 0.0
	var base_name := "%s_%s" % [role_id, state]
	var animation_name := base_name + "_" + direction if sprite_frames.has_animation(base_name + "_" + direction) else base_name
	if not sprite_frames.has_animation(animation_name):
		return 0.0
	var fps := sprite_frames.get_animation_speed(animation_name)
	return float(sprite_frames.get_frame_count(animation_name)) / fps if fps > 0.0 else 0.0

func _append_transient_animation(instances_by_animation: Dictionary, transient: Dictionary,
		origin: Vector2, animation_time: float) -> void:
	var role_id := str(transient.get("role", ""))
	var state := str(transient.get("state", "death"))
	var sprite_frames: SpriteFrames = _role_animation_sets.get(role_id, {}).get(state)
	if sprite_frames == null:
		return
	var started_at := float(transient.get("started_at", animation_time))
	var elapsed := animation_time - started_at
	if elapsed < 0.0:
		return
	var direction: Vector2 = transient.get("direction", Vector2.DOWN)
	var direction_name := "down"
	if direction.length_squared() > 0.001:
		if absf(direction.x) > absf(direction.y):
			direction_name = "right" if direction.x > 0.0 else "left"
		else:
			direction_name = "down" if direction.y > 0.0 else "up"
	var base_name := "%s_%s" % [role_id, state]
	var animation_name := base_name + "_" + direction_name if sprite_frames.has_animation(base_name + "_" + direction_name) else base_name
	if not sprite_frames.has_animation(animation_name):
		return
	var frame_count := sprite_frames.get_frame_count(animation_name)
	var fps := sprite_frames.get_animation_speed(animation_name)
	if frame_count <= 0 or fps <= 0.0:
		return
	var frame := mini(floori(elapsed * fps), frame_count - 1)
	var key := "%s:%d" % [animation_name, frame]
	if _get_animation_batch(role_id, state, animation_name, frame).is_empty():
		return
	if not instances_by_animation.has(key):
		instances_by_animation[key] = []
	var position: Vector2 = transient.get("position", Vector2.ZERO)
	instances_by_animation[key].append({
		"point": origin + position,
		"size": float(transient.get("size", 24.0)),
		"rotation": float(transient.get("rotation", 0.0)),
	})

func draw_projectile_trails(canvas: CanvasItem) -> void:
	for trail in _projectile_trails:
		canvas.draw_line(trail["start"], trail["end"], PROJECTILE_TRAIL_SHADOW, 3.0, false)
		canvas.draw_line(trail["start"], trail["end"], PROJECTILE_TRAIL_COLOR, 1.0, false)

func draw_enemy_feedback(canvas: CanvasItem, entities: Array, origin: Vector2 = Vector2.ZERO) -> void:
	for entity in entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false):
			var projectile: Dictionary = components.get("Projectile", {})
			if projectile.get("persistent_area", false):
				var field_center := origin + Vector2(
						float(components["Transform2D"]["x"]), float(components["Transform2D"]["y"]))
				var field_radius := float(projectile.get("area_radius", 0.0))
				canvas.draw_circle(field_center, field_radius, Color(0.25, 1.0, 0.58, 0.075))
				canvas.draw_arc(field_center, field_radius, 0.0, TAU, 64,
						Color(0.35, 1.0, 0.62, 0.72), 2.0, true)
				var ripple_radius := persistent_area_ripple_radius(
						float(projectile.get("remaining_seconds", 0.0)), field_radius)
				if ripple_radius > 0.0:
					canvas.draw_arc(field_center, ripple_radius, 0.0, TAU, 32,
							Color(0.82, 1.0, 0.3, 0.62), 2.0, true)
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
		if str(components.get("Affix", "")).split("+").has("Hasted"):
			canvas.draw_arc(center, 18.0, 0.0, TAU, 32, Color(1.0, 0.36, 0.25, 0.95), 2.5, true)

func multimesh_for(sprite_id: String) -> MultiMesh:
	if not _batches.has(sprite_id):
		return null
	return _batches[sprite_id]["multimesh"]

static func persistent_area_ripple_radius(remaining_seconds: float, area_radius: float) -> float:
	if not is_finite(remaining_seconds) or remaining_seconds <= 0.0 or \
			not is_finite(area_radius) or area_radius <= 0.0:
		return 0.0
	var phase := fposmod(remaining_seconds, PERSISTENT_AREA_RIPPLE_PERIOD) / PERSISTENT_AREA_RIPPLE_PERIOD
	return area_radius * lerpf(0.2, 0.82, phase)

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
			"redline":
				return "projectile_redline"
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
			"shatter_impact":
				return "projectile_shatter_impact"
			"shatter_fragment":
				return "projectile_shatter_fragment"
			"thermal_shock":
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
			return "boss_pulse_warden"
		"final_boss":
			return "boss_dopamine_core"
		_:
			return "enemy_chaser"

func _size_for_entity(sprite_id: String, components: Dictionary = {}) -> float:
	if sprite_id == "projectile_starfall_fragment":
		return 10.0
	if components.has("CollisionRadius"):
		return float(components["CollisionRadius"]) * 2.0
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
		multimesh.set_instance_color(index, instance.get("color", Color.WHITE))
