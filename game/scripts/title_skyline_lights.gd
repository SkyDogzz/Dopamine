extends Control

const LOGICAL_SIZE := Vector2(640.0, 360.0)
const DIM_COLOR := Color("#10152B", 0.82)
const CYAN_LIGHT := Color("#37E8F5", 0.48)
const AMBER_LIGHT := Color("#FFD447", 0.48)
const SIGNS := [
	{"rect": Rect2(76.0, 119.0, 6.0, 33.0), "period": 1.7, "offset": 0.0, "color": AMBER_LIGHT},
	{"rect": Rect2(544.0, 131.0, 6.0, 33.0), "period": 2.2, "offset": 0.8, "color": AMBER_LIGHT},
	{"rect": Rect2(616.0, 10.0, 3.0, 42.0), "period": 1.4, "offset": 0.35, "color": CYAN_LIGHT},
]

var _elapsed := 0.0
var _last_blink_step := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	_elapsed += delta
	var blink_step := int(_elapsed * 8.0)
	if blink_step != _last_blink_step:
		_last_blink_step = blink_step
		queue_redraw()

func _draw() -> void:
	if not ResourceLoader.exists("res://assets/backgrounds/title_skyline.png"):
		return
	var scale := size / LOGICAL_SIZE
	for sign in SIGNS:
		var period := float(sign["period"])
		var phase := fposmod(_elapsed + float(sign["offset"]), period)
		var is_dimmed := phase >= period * 0.82
		var rect: Rect2 = sign["rect"]
		rect.position *= scale
		rect.size *= scale
		draw_rect(rect, DIM_COLOR if is_dimmed else sign["color"])
