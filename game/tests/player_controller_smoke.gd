extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed_scene: PackedScene = load("res://scenes/player.tscn")
	if packed_scene == null:
		_fail("Player scene should load")
		return
	var player: CharacterBody2D = packed_scene.instantiate()
	root.add_child(player)
	await process_frame
	if player.move_speed <= 0.0:
		_fail("Player should expose a positive configurable move speed")
		return
	var sprite: Sprite2D = player.get_node("Sprite")
	if sprite.texture == null or not sprite.region_enabled or sprite.texture.get_size() != Vector2(128.0, 128.0):
		_fail("Player should render a 32x32 region from the 4x4 animation sheet")
		return
	player._update_sprite_animation(Vector2.RIGHT, 0.125)
	if sprite.texture.resource_path.get_file() != "player_walk.png" or sprite.region_rect != Rect2(32, 64, 32, 32):
		_fail("Rightward movement should select the right-facing walk frame")
		return
	player.play_attack(Vector2.LEFT)
	if sprite.texture.resource_path.get_file() != "player_attack.png" or sprite.region_rect.position.y != 32.0:
		_fail("Player attacks should use the matching directional attack sheet row")
		return
	player._update_sprite_animation(Vector2.ZERO, 0.5)
	if sprite.texture.resource_path.get_file() != "player_idle.png":
		_fail("A completed attack should return to the idle sheet")
		return
	player._update_sprite_animation(Vector2.ZERO, 0.0)
	if sprite.texture.resource_path.get_file() != "player_idle.png" or sprite.region_rect.position.y != 32.0:
		_fail("Stopping should return to idle while preserving the last facing direction")
		return
	player.play_death()
	if sprite.texture.resource_path.get_file() != "player_death.png" or player.controls_enabled:
		_fail("Player death should display its sheet and disable movement")
		return
	player._physics_process(0.11)
	if sprite.region_rect.position.x < 32.0:
		_fail("Player death should advance its one-shot frames while controls are disabled")
		return
	player._one_shot_state = ""
	player.controls_enabled = true
	Input.parse_input_event(_key_event(KEY_D, true))
	await physics_frame
	await physics_frame
	Input.parse_input_event(_key_event(KEY_D, false))
	if player.position.x <= 0.0:
		_fail("Player should move from the right input action")
		return
	if sprite.region_rect.position.y != 64.0:
		_fail("Right input should keep the player facing right")
		return
	for action_and_key in [["move_left", KEY_LEFT], ["move_right", KEY_RIGHT], ["move_up", KEY_UP], ["move_down", KEY_DOWN]]:
		if not _has_physical_key(action_and_key[0], action_and_key[1]):
			_fail("Each movement action should include its matching arrow key")
			return
	var before_right := player.position.x
	Input.action_press("move_right")
	await physics_frame
	await physics_frame
	Input.action_release("move_right")
	if player.position.x <= before_right:
		_fail("The right arrow should move the player through the right input action")
		return
	var before_left := player.position.x
	Input.action_press("move_left")
	await physics_frame
	await physics_frame
	Input.action_release("move_left")
	if player.position.x >= before_left:
		_fail("The left arrow should move the player through the left input action")
		return
	if sprite.region_rect.position.y != 32.0:
		_fail("Left input should keep the player facing left")
		return
	var before_up := player.position.y
	Input.action_press("move_up")
	await physics_frame
	await physics_frame
	Input.action_release("move_up")
	if player.position.y >= before_up:
		_fail("The up arrow should move the player through the up input action")
		return
	if sprite.region_rect.position.y != 96.0:
		_fail("Up input should keep the player facing up")
		return
	var before_down := player.position.y
	Input.action_press("move_down")
	await physics_frame
	await physics_frame
	Input.action_release("move_down")
	if player.position.y <= before_down:
		_fail("The down arrow should move the player through the down input action")
		return
	if sprite.region_rect.position.y != 0.0:
		_fail("Down input should keep the player facing down")
		return
	Input.parse_input_event(_key_event(KEY_D, true))
	Input.parse_input_event(_key_event(KEY_S, true))
	await physics_frame
	await physics_frame
	var diagonal_speed: float = player.velocity.length()
	Input.parse_input_event(_key_event(KEY_D, false))
	Input.parse_input_event(_key_event(KEY_S, false))
	if not is_equal_approx(diagonal_speed, player.move_speed):
		_fail("Diagonal movement should be normalized")
		return
	print("Player scene and movement input smoke passed")
	quit()

func _has_physical_key(action: String, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == keycode:
			return true
	return false

func _key_event(keycode: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	return event

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
