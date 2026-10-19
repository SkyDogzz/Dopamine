extends SceneTree

func _initialize() -> void:
	var session_script = load("res://scripts/survival_session.gd")
	if session_script == null:
		_fail("The Survival session should parse with the mobile XP core enabled")
		return
	var session = session_script.new()
	session.loadout = load("res://scripts/survival_loadout.gd").new(1)
	var trajectory: Dictionary = session._mobile_xp_core_trajectory(
		Vector2.ZERO, Vector2(1280.0, 720.0), Vector2.RIGHT)
	var half_diagonal := Vector2(640.0, 360.0).length()
	var endpoint: Vector2 = trajectory["position"] + trajectory["velocity"] * 8.0
	if float(trajectory["position"].x) >= -half_diagonal or endpoint.x <= half_diagonal or \
			not is_equal_approx(trajectory["velocity"].length() * 8.0, 2.0 * (half_diagonal + 32.0)):
		_fail("The mobile core should cross the visible arena during its eight-second lifetime")
		return
	session.mode_id = "survival"
	session.player = CharacterBody2D.new()
	session.player_active_time = 45.0
	var state := {"paused": false, "simulation_time": 45.0}
	session._update_mobile_xp_core(state, 0.0)
	if not session._mobile_core_active or not is_equal_approx(session._mobile_xp_core_remaining, 8.0) or \
			not is_equal_approx(session._mobile_xp_core_next_at, 90.0):
		_fail("The core should spawn every 45 active seconds and last eight seconds")
		return
	session._mobile_xp_core_position = Vector2(0.0, 32.0)
	session._update_mobile_xp_core(state, 0.005)
	if session._mobile_xp_core_position.distance_to(session.player.global_position) >= 32.0 or \
			session._mobile_xp_core_position.distance_to(session.player.global_position) <= \
				session.player_contact_radius + session.MOBILE_XP_CORE_RADIUS:
		_fail("An XP pickup radius should attract the core before direct contact collects it")
		return
	session._mobile_xp_core_position = session.player.global_position
	session._update_mobile_xp_core(state, 0.0)
	if session._mobile_core_active or not is_equal_approx(session.player_xp, 2.0) or \
			session._overstimulation_style_points != 10:
		_fail("Touching the core should award 20 percent XP and ten style points once")
		return
	session._collect_mobile_xp_core()
	if session._overstimulation_style_points != 10:
		_fail("A collected core should not award style more than once")
		return
	var missed_session = session_script.new()
	missed_session.loadout = load("res://scripts/survival_loadout.gd").new(1)
	missed_session.mode_id = "survival"
	missed_session.player = CharacterBody2D.new()
	missed_session.player_active_time = 45.0
	missed_session._mobile_xp_core_next_at = 90.0
	missed_session._mobile_core_active = true
	missed_session._mobile_xp_core_remaining = 0.1
	missed_session._mobile_xp_core_position = Vector2(500.0, 500.0)
	missed_session._update_mobile_xp_core(state, 0.2)
	if missed_session._mobile_core_active or missed_session.player_xp != 0.0 or \
			missed_session._overstimulation_style_points != 0:
		_fail("Missing the core should expire it without granting or removing rewards")
		return
	missed_session.mode_id = "armorless"
	missed_session.player_active_time = 90.0
	missed_session._update_mobile_xp_core(state, 0.0)
	if missed_session._mobile_core_active:
		_fail("Armorless should remain outside the mobile core system")
		return
	missed_session.mode_id = "survival"
	missed_session.sandbox_diagnostics_enabled = true
	missed_session._update_mobile_xp_core(state, 0.0)
	if missed_session._mobile_core_active:
		_fail("Sandbox diagnostics should remain outside the mobile core system")
		return
	session.player.free()
	session.free()
	missed_session.player.free()
	missed_session.free()
	print("Survival mobile XP core smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
