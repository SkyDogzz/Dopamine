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
