extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var sandbox: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(sandbox)
	current_scene = sandbox
	await process_frame
	sandbox.get_node("Shell/Header/SurvivalButton").emit_signal("pressed")
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if current_scene != sandbox:
			break
	if current_scene == sandbox or not current_scene.scene_file_path.ends_with("survival_session.tscn"):
		_fail("Sandbox Survival entry should open the Survival session scene")
		return
	await process_frame
	if not current_scene.get_node("HUD/ChestOverlay/ChestChoice").visible:
		_fail("Opening Survival should show the starting weapon choice")
		return
	var player_sprite: Sprite2D = current_scene.player.get_node("Sprite")
	if player_sprite.texture == null or not player_sprite.texture.resource_path.ends_with("player_cyan.png"):
		_fail("The Survival player should use the generated pixel-art sprite")
		return
	var choice_buttons: VBoxContainer = current_scene.get_node("HUD/ChestOverlay/ChestChoice/Content/Options")
	for button in choice_buttons.get_children():
		if button.icon == null:
			_fail("Starting weapon choices should display their weapon sprites")
			return
	if current_scene.progression_service != null:
		_fail("The Sandbox Survival route must not receive normal progression save capability")
		return
	if current_scene.difficulty_id != "normal":
		_fail("The isolated Sandbox Survival prototype should keep its default tuning")
		return
	current_scene.queue_free()
	await process_frame
	print("Survival entry smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
