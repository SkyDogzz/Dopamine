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
	if player_sprite.texture == null or not player_sprite.texture.resource_path.ends_with("player_idle.png"):
		_fail("The Survival player should use the generated pixel-art sprite")
		return
	if player_sprite.texture.get_width() != 128 or player_sprite.texture.get_height() != 128 or not player_sprite.region_enabled or \
		player_sprite.region_rect.size != Vector2(32, 32) or player_sprite.scale != Vector2.ONE:
		_fail("The 32x32 Art Bible player sprite should render at native logical size")
		return
	var choice_buttons: VBoxContainer = current_scene.get_node("HUD/ChestOverlay/ChestChoice/Content/Options")
	var starting_options: Array[Dictionary] = current_scene.loadout.starting_weapon_options()
	for index in range(choice_buttons.get_child_count()):
		var button := choice_buttons.get_child(index) as Button
		var offer_icon := button.get_node_or_null("ContentMargin/OfferRow/OfferIcon") as TextureRect
		if offer_icon == null or offer_icon.texture == null or \
			offer_icon.texture.resource_path != str(starting_options[index].get("icon", "")) or \
			offer_icon.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST or offer_icon.custom_minimum_size != Vector2(32, 32):
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
