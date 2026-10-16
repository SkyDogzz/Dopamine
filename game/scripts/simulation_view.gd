extends Control

signal entity_selected(index: int, generation: int)

const SPRITE_RENDERER_SCRIPT := preload("res://scripts/sprite_batch_renderer.gd")
const GRID_SIZE := 32
const COLOR_BACKGROUND := Color("#09111a")
const COLOR_GRID := Color("#162633")
const COLOR_TEXT := Color("#e5f2f5")
const COLOR_CYAN := Color("#45e5ed")

var _entities: Array = []
var _selected_index := -1
var _selected_generation := -1
var _sprite_renderer: RefCounted
var _enemy_multimesh: MultiMesh
var _projectile_multimesh: MultiMesh
var _xp_multimesh: MultiMesh
var _selected_point := Vector2.ZERO
var _selected_entity_found := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite_renderer = SPRITE_RENDERER_SCRIPT.new()
	_enemy_multimesh = _sprite_renderer.multimesh_for("enemy_chaser")
	_projectile_multimesh = _sprite_renderer.multimesh_for("projectile_lightning")
	_xp_multimesh = _sprite_renderer.multimesh_for("xp_orb")

func set_entities(entities: Array) -> void:
	_entities = entities
	var center := size * 0.5
	var visible_entities: Array = []
	for entity in _entities:
		var transform: Dictionary = entity["components"]["Transform2D"]
		var point := center + Vector2(transform["x"], transform["y"])
		if point.x < -32 or point.y < -32 or point.x > size.x + 32 or point.y > size.y + 32:
			continue
		visible_entities.append(entity)
	_sprite_renderer.set_entities(visible_entities, center)
	_selected_point = _sprite_renderer.selected_point
	_selected_entity_found = _sprite_renderer.selected_entity_found
	queue_redraw()

func set_selected_entity(index: int, generation: int) -> void:
	_selected_index = index
	_selected_generation = generation
	_sprite_renderer.set_selected_entity(index, generation)
	set_entities(_entities)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BACKGROUND)
	for x in range(0, int(size.x), GRID_SIZE):
		draw_line(Vector2(x, 0), Vector2(x, size.y), COLOR_GRID, 1.0)
	for y in range(0, int(size.y), GRID_SIZE):
		draw_line(Vector2(0, y), Vector2(size.x, y), COLOR_GRID, 1.0)
	_sprite_renderer.draw_projectile_trails(self)
	_sprite_renderer.draw_batches(self)

	var center := size * 0.5
	_sprite_renderer.draw_enemy_feedback(self, _entities, center)
	draw_circle(center, 10.0, Color("#152b35"))
	draw_arc(center, 11.0, 0.0, TAU, 32, COLOR_CYAN, 1.0)
	draw_line(center + Vector2(-18, 0), center + Vector2(18, 0), COLOR_CYAN, 1.0)
	draw_line(center + Vector2(0, -18), center + Vector2(0, 18), COLOR_CYAN, 1.0)
	if _selected_entity_found:
		draw_arc(_selected_point, 16.0, 0.0, TAU, 24, COLOR_TEXT, 2.0)
		draw_string(ThemeDB.fallback_font, _selected_point + Vector2(14, -10), "%d / G%d" % [_selected_index, _selected_generation], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, COLOR_TEXT)

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
