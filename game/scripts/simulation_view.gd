extends Control

signal entity_selected(index: int, generation: int)

const GRID_SIZE := 32
const COLOR_BACKGROUND := Color("#09111a")
const COLOR_GRID := Color("#162633")
const COLOR_TEXT := Color("#e5f2f5")
const COLOR_CYAN := Color("#45e5ed")
const COLOR_PINK := Color("#ff5ca8")
const COLOR_AMBER := Color("#ffd166")
const COLOR_VIOLET := Color("#b19cff")

var _entities: Array = []
var _selected_index := -1
var _selected_generation := -1
var _enemy_multimesh: MultiMesh
var _projectile_multimesh: MultiMesh
var _xp_multimesh: MultiMesh
var _circle_texture: ImageTexture
var _square_texture: ImageTexture
var _selected_point := Vector2.ZERO
var _selected_entity_found := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_circle_texture = _make_shape_texture(true)
	_square_texture = _make_shape_texture(false)
	_enemy_multimesh = _make_multimesh()
	_projectile_multimesh = _make_multimesh()
	_xp_multimesh = _make_multimesh()

func set_entities(entities: Array) -> void:
	_entities = entities
	var enemies: Array[Dictionary] = []
	var projectiles: Array[Dictionary] = []
	var xp_orbs: Array[Dictionary] = []
	_selected_entity_found = false
	var center := size * 0.5
	for entity in _entities:
		var id: Dictionary = entity["id"]
		var components: Dictionary = entity["components"]
		var transform: Dictionary = components["Transform2D"]
		var point := center + Vector2(transform["x"], transform["y"])
		if point.x < -12 or point.y < -12 or point.x > size.x + 12 or point.y > size.y + 12:
			continue
		if components.get("IsProjectile", false):
			projectiles.append({"point": point, "size": 6.0, "color": COLOR_AMBER})
		elif components.get("IsXpOrb", false):
			xp_orbs.append({"point": point, "size": 8.0, "color": COLOR_VIOLET})
		else:
			enemies.append({"point": point, "size": 12.0, "color": _entity_color(String(components["EnemyType"]))})
			if id["index"] == _selected_index and id["generation"] == _selected_generation:
				_selected_point = point
				_selected_entity_found = true
	_set_multimesh_instances(_enemy_multimesh, enemies)
	_set_multimesh_instances(_projectile_multimesh, projectiles)
	_set_multimesh_instances(_xp_multimesh, xp_orbs)
	queue_redraw()

func set_selected_entity(index: int, generation: int) -> void:
	_selected_index = index
	_selected_generation = generation
	_selected_entity_found = false
	var center := size * 0.5
	for entity in _entities:
		var id: Dictionary = entity["id"]
		var components: Dictionary = entity["components"]
		if id["index"] != _selected_index or id["generation"] != _selected_generation:
			continue
		if components.get("IsProjectile", false) or components.get("IsXpOrb", false):
			break
		var transform: Dictionary = components["Transform2D"]
		_selected_point = center + Vector2(transform["x"], transform["y"])
		_selected_entity_found = true
		break
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BACKGROUND)
	for x in range(0, int(size.x), GRID_SIZE):
		draw_line(Vector2(x, 0), Vector2(x, size.y), COLOR_GRID, 1.0)
	for y in range(0, int(size.y), GRID_SIZE):
		draw_line(Vector2(0, y), Vector2(size.x, y), COLOR_GRID, 1.0)
	if _enemy_multimesh.instance_count > 0:
		draw_multimesh(_enemy_multimesh, _circle_texture)
	if _projectile_multimesh.instance_count > 0:
		draw_multimesh(_projectile_multimesh, _square_texture)
	if _xp_multimesh.instance_count > 0:
		draw_multimesh(_xp_multimesh, _circle_texture)

	var center := size * 0.5
	draw_circle(center, 10.0, Color("#152b35"))
	draw_arc(center, 11.0, 0.0, TAU, 32, COLOR_CYAN, 1.0)
	draw_line(center + Vector2(-18, 0), center + Vector2(18, 0), COLOR_CYAN, 1.0)
	draw_line(center + Vector2(0, -18), center + Vector2(0, 18), COLOR_CYAN, 1.0)
	if _selected_entity_found:
		draw_arc(_selected_point, 11.0, 0.0, TAU, 24, COLOR_TEXT, 2.0)
		draw_string(ThemeDB.fallback_font, _selected_point + Vector2(14, -10), "%d / G%d" % [_selected_index, _selected_generation], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, COLOR_TEXT)

func _make_multimesh() -> MultiMesh:
	var mesh := MultiMesh.new()
	mesh.transform_format = MultiMesh.TRANSFORM_2D
	mesh.use_colors = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	mesh.mesh = quad
	return mesh

func _make_shape_texture(circle: bool) -> ImageTexture:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(16):
			var inside := not circle or Vector2(x + 0.5, y + 0.5).distance_to(Vector2(8, 8)) <= 8.0
			image.set_pixel(x, y, Color.WHITE if inside else Color.TRANSPARENT)
	return ImageTexture.create_from_image(image)

func _set_multimesh_instances(multimesh: MultiMesh, instances: Array[Dictionary]) -> void:
	multimesh.instance_count = instances.size()
	for index in range(instances.size()):
		var instance: Dictionary = instances[index]
		var diameter: float = instance["size"]
		var point: Vector2 = instance["point"]
		multimesh.set_instance_transform_2d(index, Transform2D(Vector2(diameter, 0), Vector2(0, diameter), point))
		multimesh.set_instance_color(index, instance["color"])

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var nearest_id := Vector2i(-1, -1)
	var nearest_distance := 14.0
	var center := size * 0.5
	for entity in _entities:
		var id: Dictionary = entity["id"]
		var transform: Dictionary = entity["components"]["Transform2D"]
		var point := center + Vector2(transform["x"], transform["y"])
		var distance: float = event.position.distance_to(point)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_id = Vector2i(id["index"], id["generation"])
	emit_signal("entity_selected", nearest_id.x, nearest_id.y)
	accept_event()

func _entity_color(entity_type: String) -> Color:
	match entity_type:
		"chaser":
			return COLOR_CYAN
		"sprinter":
			return COLOR_PINK
		"tank":
			return COLOR_AMBER
		"shooter":
			return COLOR_VIOLET
		_:
			return COLOR_TEXT
