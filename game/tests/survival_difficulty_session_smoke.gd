extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.difficulty_id = "easy"
	session.wave_population_cap = 500
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	root.add_child(session)
	await process_frame
	if session._wave_population(24) != 320 or not is_equal_approx(session._enemy_hp_multiplier(1), 0.75) or \
		not is_equal_approx(session._enemy_hp_multiplier(24), 0.75 * 12.0):
		_fail("Easy should scale wave population and enemy HP using the proposed difficulty factors")
		return
	session.player_hp = 100.0
	session._take_enemy_damage(10.0)
	if not is_equal_approx(session.player_hp, 93.0):
		_fail("Easy should scale enemy attacks without scaling player HP decay")
		return
	session._take_player_damage(10.0)
	if not is_equal_approx(session.player_hp, 83.0):
		_fail("Player health decay should remain independent of enemy damage difficulty")
		return
	session.player_hp = 100.0
	session._contact_invulnerable_until = 0.0
	session.player.global_position = Vector2.ZERO
	session._entities = [{
		"components": {"EnemyType": "chaser", "Transform2D": {"x": 0.0, "y": 0.0}},
		"id": {"index": 1, "generation": 1},
	}]
	session._apply_contact_damage({"paused": false}, 1.0)
	if not is_equal_approx(session.player_hp, 100.0 - session.contact_damage_per_hit * 0.70):
		_fail("Enemy contact should apply the selected difficulty's damage factor")
		return
	session.queue_free()
	await process_frame
	print("Survival difficulty session smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
