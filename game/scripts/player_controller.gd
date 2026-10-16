extends CharacterBody2D

# Starting value only; the GDD does not yet specify player movement speed.
@export var move_speed: float = 240.0
var controls_enabled := true
const IDLE_TEXTURE: Texture2D = preload("res://assets/sprites/player_idle.png")
const WALK_TEXTURE: Texture2D = preload("res://assets/sprites/player_walk.png")
const FRAME_SIZE := 32
const IDLE_FRAME_RATE := 3.0
const WALK_FRAME_RATE := 8.0
var _facing_row := 0
var _animation_elapsed := 0.0
var _is_walking := false

@onready var _sprite: Sprite2D = $Sprite

func _physics_process(delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	move_and_slide()
	_update_sprite_animation(direction, delta)

func _update_sprite_animation(direction: Vector2, delta: float) -> void:
	var moving := direction.length_squared() > 0.0001
	if moving:
		_facing_row = _direction_row(direction)
	if moving != _is_walking:
		_is_walking = moving
		_animation_elapsed = 0.0
	_animation_elapsed += delta
	var frame_rate := WALK_FRAME_RATE if moving else IDLE_FRAME_RATE
	var frame := floori(_animation_elapsed * frame_rate) % 4
	var texture := WALK_TEXTURE if moving else IDLE_TEXTURE
	if _sprite.texture != texture:
		_sprite.texture = texture
	_sprite.region_rect = Rect2(frame * FRAME_SIZE, _facing_row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)

func _direction_row(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y):
		return 2 if direction.x > 0.0 else 1
	return 0 if direction.y > 0.0 else 3
