extends SceneTree

func _initialize() -> void:
	var session_script = load("res://scripts/survival_session.gd")
	if session_script == null:
		_fail("The Survival session should parse with perfect dodge enabled")
		return
	var session = session_script.new()
	session.loadout = load("res://scripts/survival_loadout.gd").new(1)
	var projectile_time: float = session._projectile_intercept_time(
		Vector2(-100.0, 0.0), Vector2(500.0, 0.0), Vector2.ZERO, 16.0)
	if not is_equal_approx(projectile_time, 0.2):
		_fail("An approaching projectile should predict an impact inside 250 ms")
		return
	if session._projectile_intercept_time(Vector2(-100.0, 50.0), Vector2(500.0, 0.0), Vector2.ZERO, 16.0) >= 0.0:
		_fail("A projectile outside the player's collision radius should not be a threat")
		return
	if session._projectile_intercept_time(Vector2(-100.0, 0.0), Vector2.ZERO, Vector2.ZERO, 16.0) >= 0.0:
		_fail("A stationary projectile should not be treated as an approaching attack")
		return
	var charge_time: float = session._charge_intercept_time(
		Vector2(-100.0, 0.0), Vector2.RIGHT, Vector2.ZERO, 400.0, 0.0, 42.0)
	if not is_equal_approx(charge_time, 0.25):
		_fail("A telegraphed charge should predict collision at the 250 ms boundary")
		return
	if session._charge_intercept_time(Vector2(-100.0, 50.0), Vector2.RIGHT, Vector2.ZERO,
			400.0, 0.0, 42.0) >= 0.0:
		_fail("A charge that misses the player collision radius should not be a threat")
		return
	if session._charge_intercept_time(Vector2(-100.0, 0.0), Vector2.RIGHT, Vector2.ZERO,
			400.0, 0.1, 42.0) >= 0.0:
		_fail("A charge outside the combined telegraph and travel window should not be a threat")
		return
	session.mode_id = "survival"
	session.player = CharacterBody2D.new()
	var projectile_entity := _enemy_projectile(1, Vector2(-100.0, 0.0))
	var state := {"paused": false, "entities": [projectile_entity]}
	session._update_perfect_dodges(state, 0.0)
	session.player.position = Vector2(0.0, 25.0)
	session._update_perfect_dodges(state, 0.0)
	session._update_perfect_dodges(state, 0.21)
	if session._perfect_dodge_style_points != 20:
		_fail("Moving out of a predicted projectile hit should award exactly 20 style points")
		return
	if not is_equal_approx(session._effective_weapon_cooldown(1.0), 1.0 / 1.1):
		_fail("A perfect dodge should grant 10 percent attack speed")
		return
	session.player_active_time = 2.01
	if not is_equal_approx(session._effective_weapon_cooldown(1.0), 1.0):
		_fail("The perfect dodge attack-speed bonus should expire after two seconds")
		return
	var cancelled_session = session_script.new()
	cancelled_session.loadout = load("res://scripts/survival_loadout.gd").new(1)
	cancelled_session.mode_id = "survival"
	cancelled_session.player = CharacterBody2D.new()
	var cancellation_state := {"paused": false, "entities": [_enemy_projectile(2, Vector2(-100.0, 0.0))]}
	cancelled_session._update_perfect_dodges(cancellation_state, 0.0)
	cancelled_session.player.position = Vector2(0.0, 25.0)
	cancelled_session._update_perfect_dodges(cancellation_state, 0.0)
	cancelled_session._perfect_dodge_enemy_damage_serial += 1
	cancelled_session._update_perfect_dodges(cancellation_state, 0.1)
	cancelled_session._update_perfect_dodges(cancellation_state, 0.3)
	if cancelled_session._perfect_dodge_style_points != 0:
		_fail("Enemy damage during the prediction window should cancel the perfect dodge")
		return
	cancelled_session.player.free()
	cancelled_session.free()
	session.mode_id = ""
	if session._overstimulation_enabled():
		_fail("An unselected mode should not enable perfect dodge")
		return
	session.mode_id = "survival"
	if not session._overstimulation_enabled():
		_fail("Standard Survival should enable perfect dodge")
		return
	session.mode_id = "endless"
	if not session._overstimulation_enabled():
		_fail("Standard Endless should enable perfect dodge")
		return
	session.mode_id = "armorless"
	if session._overstimulation_enabled():
		_fail("Armorless should remain outside perfect dodge")
		return
	session.mode_id = "survival"
	session.sandbox_diagnostics_enabled = true
	if session._overstimulation_enabled():
		_fail("Sandbox diagnostics should remain outside perfect dodge")
		return
	session.player.free()
	session.free()
	print("Survival perfect dodge smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _enemy_projectile(index: int, position: Vector2) -> Dictionary:
	return {
		"id": {"index": index, "generation": 1},
		"components": {
			"IsProjectile": true,
			"EnemyType": "enemy_projectile",
			"Transform2D": {"x": position.x, "y": position.y},
			"Velocity2D": {"x": 500.0, "y": 0.0},
			"Projectile": {"radius": 0.0},
		},
	}
