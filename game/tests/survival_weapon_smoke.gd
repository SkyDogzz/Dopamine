extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	if not session.has_method("open_chest_family"):
		_fail("Survival session script should load")
		return
	session.spawn_initial_enemy = false
	session.xp_collection_radius = 200.0
	session.contact_damage_per_hit = 0.0
	session.ordinary_chest_drop_chance = 0.0
	session.skip_starting_weapon_choice = true
	root.add_child(session)
	await process_frame
	if session.simulation == null:
		_fail("Survival session should create the shared simulation")
		return
	if session.get_node("HUD/RunPanel/RunInfo/HPBar").value != 100.0:
		_fail("Survival HUD should start at the validated player HP")
		return
	var selected_chest_options := [""]
	session.chest_option_chosen.connect(func(option_id: String) -> void: selected_chest_options[0] = option_id)
	var chest_options: Array = session.loadout.offers("weapon")
	if chest_options.size() != 3 or not session.open_chest(chest_options):
		_fail("Survival should open a chest with three valid offers")
		return
	var paused: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool: return snapshot["paused"])
	if paused.is_empty() or not session.get_node("HUD/ChestOverlay/ChestChoice").visible:
		_fail("Opening a chest should pause the simulation and show its modal")
		return
	session.get_node("HUD/ChestOverlay/ChestChoice/Content/Options/Choice0").emit_signal("pressed")
	var resumed: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return not snapshot["paused"] and selected_chest_options[0] == chest_options[0]["id"]
	)
	if resumed.is_empty() or session.get_node("HUD/ChestOverlay/ChestChoice").visible:
		_fail("Choosing an offer should emit its ID and resume the run")
		return
	var selected_weapon_id: String = str(chest_options[0]["id"]).trim_prefix("weapon:")
	if session.loadout.weapon_level(selected_weapon_id) < 1:
		_fail("Choosing a weapon offer should update this run's loadout")
		return
	session.simulation.set_speed(4.0)
	session.player_hp = 80.0
	for position in [Vector2(140.0, -30.0), Vector2(140.0, 30.0)]:
		var sequence: int = session.simulation.spawn_enemy("chaser", 1, position, Vector2.ZERO)
		if sequence <= 0:
			_fail("Survival should accept the two initial chain targets")
			return
	var spawned: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return snapshot["entities"].size() == 2
	)
	if spawned.is_empty():
		_fail("Survival should publish both chain targets")
		return
	var state: Dictionary = await _wait_until(session, func(snapshot: Dictionary) -> bool:
		return snapshot["entities"].is_empty() and snapshot["events"].is_empty() and session.player_hp > 85.0
	)
	if state.is_empty():
		_fail("Lightning Conductor should fire one projectile, arc to a nearby chaser, kill both and heal the player")
		return
	if session.player_hp <= 85.0 or int(state["metrics"]["collision_count"]) < 4:
		_fail("Lightning Conductor should chain damage across both enemies and apply both kill heals")
		return
	if session.get_node("HUD/RunPanel/RunInfo/RunState").text != "IN RUN":
		_fail("Survival HUD should reflect the active run state")
		return
	if session.player_level != 2 or session.player_xp != 0.0:
		_fail("Collected enemy XP should advance the player level")
		return
	if not session.get_node("HUD/RunPanel/RunInfo/XPValue").text.begins_with("LV 2"):
		_fail("Survival HUD should display the new XP level")
		return
	print("Survival automatic weapon smoke passed")
	quit()

func _wait_until(session: Node2D, predicate: Callable) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var state: Dictionary = session.simulation.snapshot()
		if predicate.call(state):
			return state
	return {}

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
