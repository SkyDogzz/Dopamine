extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	root.add_child(session)
	await process_frame
	if session.simulation == null:
		_fail("Survival session should create the shared simulation")
		return
	if session.get_node("HUD/RunPanel/RunInfo/HPBar").value != 100.0:
		_fail("Survival HUD should start at the validated player HP")
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
		_fail("Lightning Conductor should fire both chains, kill both chasers and heal the player")
		return
	if session.player_hp <= 85.0 or int(state["metrics"]["collision_count"]) < 4:
		_fail("Lightning Conductor should hit both enemies twice and apply both kill heals")
		return
	if session.get_node("HUD/RunPanel/RunInfo/RunState").text != "IN RUN":
		_fail("Survival HUD should reflect the active run state")
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
