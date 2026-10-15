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
	Input.parse_input_event(_key_event(KEY_D, true))
	await physics_frame
	await physics_frame
	Input.parse_input_event(_key_event(KEY_D, false))
	if player.position.x <= 0.0:
		_fail("Player should move from the right input action")
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

func _key_event(keycode: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	return event

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
