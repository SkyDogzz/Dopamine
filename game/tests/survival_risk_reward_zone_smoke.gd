extends SceneTree

func _initialize() -> void:
	var session_script = load("res://scripts/survival_session.gd")
	if session_script == null:
		_fail("The Survival session should parse with the risk/reward zone enabled")
		return
	var session = session_script.new()
	session.loadout = load("res://scripts/survival_loadout.gd").new(1)
	session.mode_id = "survival"
	if not session._risk_reward_zone_due(4, session.WAVE_DIRECTOR_SCRIPT.State.WAVE) or \
			session._risk_reward_zone_due(12, session.WAVE_DIRECTOR_SCRIPT.State.MID_BOSS):
		_fail("Risk zones should appear every fourth non-boss wave")
		return
	session.mode_id = "endless"
	if not session._risk_reward_zone_due(16, session.WAVE_DIRECTOR_SCRIPT.State.WAVE):
		_fail("Standard Endless should continue the every-fourth-wave schedule")
		return
	session.mode_id = "armorless"
	if session._risk_reward_zone_due(4, session.WAVE_DIRECTOR_SCRIPT.State.WAVE):
		_fail("Armorless should not receive risk/reward zones")
		return
	session.mode_id = "survival"
	session.sandbox_diagnostics_enabled = true
	if session._risk_reward_zone_due(4, session.WAVE_DIRECTOR_SCRIPT.State.WAVE):
		_fail("Sandbox diagnostics should not receive risk/reward zones")
		return
	session.sandbox_diagnostics_enabled = false
	session.player = CharacterBody2D.new()
	session.player.position = Vector2.ZERO
	session._start_risk_reward_zone(4)
	session.player.position = session._risk_reward_zone_center
	session._update_risk_reward_zone(1.5)
	session.player.position += Vector2.RIGHT * (session.RISK_REWARD_ZONE_RADIUS + 1.0)
	session.player_hp = 100.0
	session._take_enemy_damage(1.0)
	session._update_risk_reward_zone(3.0)
	if not is_equal_approx(session._risk_reward_zone_progress, 1.5) or session.player_hp >= 100.0:
		_fail("Leaving the zone and taking damage should preserve its cumulative charge")
		return
	session.player.position = session._risk_reward_zone_center
	session._update_risk_reward_zone(2.5)
	if session._risk_reward_zone_active or session._overstimulation_style_points != 15:
		_fail("Four cumulative seconds should grant one 15-point zone reward")
		return
	if not is_equal_approx(session._persistent_damage_multiplier(), 1.2) or \
			not is_equal_approx(session._equipment_area(100.0), 120.0):
		_fail("The charged reward should increase damage and weapon area by 20 percent")
		return
	session.player_active_time = 8.01
	if not is_equal_approx(session._persistent_damage_multiplier(), 1.0) or \
			not is_equal_approx(session._equipment_area(100.0), 100.0):
		_fail("The damage and area reward should expire after eight active seconds")
		return
	session.player.free()
	session.free()
	print("Survival risk/reward zone smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
