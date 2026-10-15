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

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_entities(entities: Array) -> void:
	_entities = entities
	queue_redraw()

func set_selected_entity(index: int, generation: int) -> void:
	_selected_index = index
	_selected_generation = generation
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BACKGROUND)
	for x in range(0, int(size.x), GRID_SIZE):
		draw_line(Vector2(x, 0), Vector2(x, size.y), COLOR_GRID, 1.0)
	for y in range(0, int(size.y), GRID_SIZE):
		draw_line(Vector2(0, y), Vector2(size.x, y), COLOR_GRID, 1.0)

	var center := size * 0.5
	draw_circle(center, 10.0, Color("#152b35"))
	draw_arc(center, 11.0, 0.0, TAU, 32, COLOR_CYAN, 1.0)
	draw_line(center + Vector2(-18, 0), center + Vector2(18, 0), COLOR_CYAN, 1.0)
	draw_line(center + Vector2(0, -18), center + Vector2(0, 18), COLOR_CYAN, 1.0)

	for entity in _entities:
		var id: Dictionary = entity["id"]
		var components: Dictionary = entity["components"]
		var transform: Dictionary = components["Transform2D"]
		var point := center + Vector2(transform["x"], transform["y"])
		if point.x < -12 or point.y < -12 or point.x > size.x + 12 or point.y > size.y + 12:
			continue
		if components.get("IsProjectile", false):
			draw_rect(Rect2(point - Vector2(3, 3), Vector2(6, 6)), COLOR_AMBER)
			continue
		if components.get("IsXpOrb", false):
			draw_circle(point, 4.0, COLOR_VIOLET)
			continue
		var color := _entity_color(String(components["EnemyType"]))
		draw_circle(point, 6.0, color.darkened(0.55))
		draw_circle(point, 3.0, color)
		if id["index"] == _selected_index and id["generation"] == _selected_generation:
			draw_arc(point, 11.0, 0.0, TAU, 24, COLOR_TEXT, 2.0)
			draw_string(ThemeDB.fallback_font, point + Vector2(14, -10), "%d / G%d" % [id["index"], id["generation"]], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, COLOR_TEXT)

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
