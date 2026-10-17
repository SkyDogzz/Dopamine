extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var choice: Control = load("res://scenes/chest_choice.tscn").instantiate()
	root.add_child(choice)
	await process_frame
	var options := [
		{"id": "weapon:lightning_conductor", "title": "Lightning Conductor", "description": "Fires a bolt at the nearest enemy.", "icon": "res://assets/sprites/catalog/weapon_lightning_conductor.png"},
		{"id": "weapon:inferno_sprayer", "title": "Inferno Sprayer", "description": "Launches a flame projectile.", "icon": "res://assets/sprites/catalog/weapon_inferno_sprayer.png"},
		{"id": "weapon:crimson_daggers", "title": "Crimson Daggers", "description": "Throws daggers at nearby enemies.", "icon": "res://assets/sprites/catalog/weapon_crimson_daggers.png"},
	]
	if not choice.present(options, 3, "WEAPON CHEST — CHOOSE ONE"):
		_fail("Chest choice should accept three described offers")
		return
	var title: Label = choice.get_node("Content/Title")
	var buttons: VBoxContainer = choice.get_node("Content/Options")
	if choice.theme == null or not title.text.contains("WEAPON CHEST") or buttons.get_child_count() != 3 or \
		choice.get_node("Content/Instruction").text != "SELECT ONE UPGRADE TO CONTINUE":
		_fail("A weapon chest should identify its family and show all three offers")
		return
	if title.get_theme_color("font_color") != Color("#37E8F5"):
		_fail("Weapon chests should use the weapon-family cyan accent")
		return
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png("/tmp/dopamine-lightning-chest-icon.png") != OK:
			_fail("Could not capture the current Lightning Conductor chest icon")
			return
	var original_size: Vector2i = root.size
	for size in [Vector2i(960, 600), Vector2i(1280, 800), Vector2i(1600, 900)]:
		root.size = size
		await process_frame
		var bounds := Rect2(Vector2.ZERO, Vector2(size))
		if not bounds.encloses(choice.get_global_rect()):
			_fail("Chest choice should fit viewport %s" % size)
			return
		for button in buttons.get_children():
			if not bounds.encloses((button as Control).get_global_rect()):
				_fail("Chest option %s should fit viewport %s" % [button.name, size])
				return
	root.size = original_size
	var first := buttons.get_child(0) as Button
	var offer_icon: TextureRect = first.get_node("ContentMargin/OfferRow/OfferIcon")
	var offer_title: Label = first.get_node("ContentMargin/OfferRow/OfferDetails/OfferTitle")
	var offer_description: Label = first.get_node("ContentMargin/OfferRow/OfferDetails/OfferDescription")
	if root.gui_get_focus_owner() != first or first.focus_mode == Control.FOCUS_NONE or \
		offer_icon.texture == null or offer_icon.texture.resource_path != options[0]["icon"] or \
		offer_icon.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST or offer_icon.custom_minimum_size != Vector2(32, 32) or \
		offer_title.text != "Lightning Conductor" or offer_title.get_theme_font_size("font_size") <= offer_description.get_theme_font_size("font_size") or \
		offer_description.text != "Fires a bolt at the nearest enemy." or \
		offer_description.get_theme_color("font_color").to_html(false) != "a6aec4" or \
		first.get_theme_color("font_color").a != 0.0 or offer_description.mouse_filter != Control.MOUSE_FILTER_IGNORE or \
		not first.text.contains("nearest enemy"):
		_fail("A chest offer should style its icon, name and description separately and keep the full accessible text")
		return
	var selected := [""]
	var selection_count := [0]
	choice.option_selected.connect(func(option_id: String) -> void:
		selected[0] = option_id
		selection_count[0] += 1
	)
	await _send_mouse_click(first)
	if choice.visible or selected[0] != "weapon:lightning_conductor" or selection_count[0] != 1:
		_fail("A mouse click on a chest card should emit its offer id once and close the panel")
		return
	if choice.present(options.slice(0, 2), 3, "INVALID CHEST"):
		_fail("A chest with an incomplete offer set should not open")
		return
	var relic_options := [
		{"id": "relic:storm_core", "title": "Storm Core", "description": "Improves lightning damage.", "icon": "res://assets/sprites/catalog/relic_storm_core.png"},
		{"id": "relic:infernal_heart", "title": "Infernal Heart", "description": "Improves fire damage.", "icon": "res://assets/sprites/catalog/relic_infernal_heart.png"},
		{"id": "relic:blood_chalice", "title": "Blood Chalice", "description": "Restores health on kills.", "icon": "res://assets/sprites/catalog/relic_blood_chalice.png"},
	]
	if not choice.present(relic_options, 3, "RELIC CHEST — CHOOSE ONE") or \
		not title.text.contains("RELIC CHEST") or not (buttons.get_child(0) as Button).text.contains("Storm Core"):
		_fail("A relic chest should identify its family and show its relic offer")
		return
	if title.get_theme_color("font_color") != Color("#FF75E3"):
		_fail("Relic chests should use the relic-family magenta accent")
		return
	await _send_gamepad_button(JOY_BUTTON_DPAD_DOWN)
	var focused_relic := root.gui_get_focus_owner() as Button
	if focused_relic != buttons.get_child(1):
		_fail("The gamepad D-pad should move focus to the second relic offer")
		return
	await _send_gamepad_button(JOY_BUTTON_A)
	if choice.visible or selected[0] != "relic:infernal_heart" or selection_count[0] != 2:
		_fail("Gamepad A should select the focused relic and return its offer id once")
		return
	choice.queue_free()
	await process_frame
	print("Survival chest choice presentation and focus smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _send_gamepad_button(button_index: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button_index
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _send_mouse_click(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
