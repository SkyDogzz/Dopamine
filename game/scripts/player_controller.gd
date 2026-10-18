extends CharacterBody2D

# Starting value only; the GDD does not yet specify player movement speed.
@export var move_speed: float = 240.0
var controls_enabled := true
const IDLE_TEXTURE_PATH := "res://assets/sprites/player_idle.png"
const WALK_TEXTURE_PATH := "res://assets/sprites/player_walk.png"
const ATTACK_TEXTURE_PATH := "res://assets/sprites/player_attack.png"
const DEATH_TEXTURE_PATH := "res://assets/sprites/player_death.png"
const FRAME_SIZE := 32
const IDLE_FRAME_RATE := 3.0
const WALK_FRAME_RATE := 8.0
const ATTACK_FRAME_RATE := 10.0
const DEATH_FRAME_RATE := 10.0
var _facing_row := 0
var _animation_elapsed := 0.0
var _is_walking := false
var _idle_texture: Texture2D
var _walk_texture: Texture2D
var _attack_texture: Texture2D
var _death_texture: Texture2D
var _one_shot_elapsed := 0.0
var _one_shot_frame := 0
var _one_shot_state := ""

@onready var _sprite: Sprite2D = $Sprite

func _ready() -> void:
	if ResourceLoader.exists(IDLE_TEXTURE_PATH):
		_idle_texture = load(IDLE_TEXTURE_PATH) as Texture2D
	if ResourceLoader.exists(WALK_TEXTURE_PATH):
		_walk_texture = load(WALK_TEXTURE_PATH) as Texture2D
	if ResourceLoader.exists(ATTACK_TEXTURE_PATH):
		_attack_texture = load(ATTACK_TEXTURE_PATH) as Texture2D
	if ResourceLoader.exists(DEATH_TEXTURE_PATH):
		_death_texture = load(DEATH_TEXTURE_PATH) as Texture2D
	if _idle_texture == null or _walk_texture == null:
		_sprite.region_enabled = false
		_sprite.texture = null
	else:
		_sprite.region_enabled = true
		_sprite.texture = _idle_texture
		_sprite.region_rect = Rect2(0, 0, FRAME_SIZE, FRAME_SIZE)

func _physics_process(delta: float) -> void:
	if _one_shot_state == "death":
		return
	if not controls_enabled:
		velocity = Vector2.ZERO
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	move_and_slide()
	if _one_shot_state == "attack":
		_advance_one_shot(delta)
		return
	_update_sprite_animation(direction, delta)

func play_attack(direction: Vector2) -> void:
	if _attack_texture == null or _one_shot_state == "death" or _one_shot_state == "attack":
		return
	_facing_row = _direction_row(direction) if direction.length_squared() > 0.0001 else _facing_row
	_one_shot_state = "attack"
	_one_shot_elapsed = 0.0
	_one_shot_frame = 0
	_show_frame(_attack_texture, _one_shot_frame, _facing_row)

func play_death() -> void:
	controls_enabled = false
	velocity = Vector2.ZERO
	if _death_texture == null:
		return
	_one_shot_state = "death"
	_one_shot_elapsed = 0.0
	_one_shot_frame = 0
	_show_frame(_death_texture, _one_shot_frame, _facing_row)

func _advance_one_shot(delta: float) -> void:
	_one_shot_elapsed += delta
	var frame_rate := DEATH_FRAME_RATE if _one_shot_state == "death" else ATTACK_FRAME_RATE
	var next_frame := mini(floori(_one_shot_elapsed * frame_rate), 3)
	if next_frame != _one_shot_frame:
		_one_shot_frame = next_frame
		_show_frame(_death_texture if _one_shot_state == "death" else _attack_texture,
				_one_shot_frame, _facing_row)
	if _one_shot_elapsed >= 4.0 / frame_rate and _one_shot_state == "attack":
		_one_shot_state = ""
		_animation_elapsed = 0.0
		_show_frame(_walk_texture if _is_walking else _idle_texture, 0, _facing_row)

func _show_frame(texture: Texture2D, frame: int, row: int) -> void:
	if texture == null:
		return
	_sprite.texture = texture
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(frame * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)

func _update_sprite_animation(direction: Vector2, delta: float) -> void:
	if _one_shot_state == "attack" or _one_shot_state == "death":
		_advance_one_shot(delta)
		if _one_shot_state == "":
			_update_sprite_animation(direction, 0.0)
		return
	var moving := direction.length_squared() > 0.0001
	if moving:
		_facing_row = _direction_row(direction)
	if moving != _is_walking:
		_is_walking = moving
		_animation_elapsed = 0.0
	_animation_elapsed += delta
	var frame_rate := WALK_FRAME_RATE if moving else IDLE_FRAME_RATE
	var frame := floori(_animation_elapsed * frame_rate) % 4
	var texture := _walk_texture if moving else _idle_texture
	if texture == null:
		return
	_show_frame(texture, frame, _facing_row)

func _direction_row(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y):
		return 2 if direction.x > 0.0 else 1
	return 0 if direction.y > 0.0 else 3
