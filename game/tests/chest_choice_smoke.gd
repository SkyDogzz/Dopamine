extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var choice = load("res://scenes/chest_choice.tscn").instantiate()
	if choice == null:
		_fail("Chest choice scene should load")
		return
	root.add_child(choice)
	var options := [
		{"id": "weapon_upgrade", "title": "Weapon upgrade", "description": "Improve an equipped weapon."},
		{"id": "new_weapon", "title": "New weapon", "description": "Add a weapon to this run."},
		{"id": "relic", "title": "Relic", "description": "Add a matching relic."},
	]
	if choice.present(options.slice(0, 2)):
		_fail("Chest choice should reject fewer than three offers")
		return
	if not choice.present(options) or not choice.visible:
		_fail("Chest choice should show exactly three valid offers")
		return
	var selected_ids := [""]
	choice.option_selected.connect(func(option_id: String) -> void: selected_ids[0] = option_id)
	choice.get_node("Content/Options/Choice0").emit_signal("pressed")
	if selected_ids[0] != "weapon_upgrade" or choice.visible:
		_fail("Selecting an offer should emit its ID and close the modal")
		return
	if choice.present([options[0], options[0], options[2]]):
		_fail("Chest choice should reject duplicate offer IDs")
		return
	print("Chest choice smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
