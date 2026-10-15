extends CharacterBody2D

# Starting value only; the GDD does not yet specify player movement speed.
@export var move_speed: float = 240.0
var controls_enabled := true

func _physics_process(_delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	move_and_slide()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 10.0, Color("#152b35"))
	draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 32, Color("#45e5ed"), 1.0)
	draw_line(Vector2(-18, 0), Vector2(18, 0), Color("#45e5ed"), 1.0)
	draw_line(Vector2(0, -18), Vector2(0, 18), Color("#45e5ed"), 1.0)
