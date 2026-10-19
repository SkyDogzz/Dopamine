extends SceneTree

func _initialize() -> void:
	var session_script = load("res://scripts/survival_session.gd")
	var loadout_script = load("res://scripts/survival_loadout.gd")
	if session_script == null or loadout_script == null:
		_fail("The session and loadout should load with Style Gauge enabled")
		return
	var session = session_script.new()
	session.loadout = loadout_script.new(1)
	session.mode_id = "survival"
	session._record_overstimulation_style_kill("chaser", "enemy:1")
	session._record_overstimulation_style_kill("chaser", "enemy:1")
	if session._overstimulation_style_points != 1:
		_fail("An ordinary enemy kill should award one style point only once")
		return
	session._record_overstimulation_style_kill("elite", "enemy:2")
	if session._overstimulation_style_points != 9:
		_fail("An elite kill should award eight style points")
		return
	session._record_overstimulation_style_kill("mid_boss", "boss:1")
	session._record_overstimulation_style_kill("final_boss", "boss_chain_1")
	if session._overstimulation_style_points != 9:
		_fail("Bosses and boss-chain kills should not add style")
		return
	for index in range(91):
		session._add_overstimulation_style_points(1, "fill:%d" % index)
	if session._overstimulation_style_points != 0 or session._overstimulation_style_pending_points != 0 or \
			session._overstimulation_style_burst_expires_at != 6.0:
		_fail("Reaching 100 should start a six-second burst and reset the gauge")
		return
	if not is_equal_approx(session._effective_weapon_cooldown(1.0), 1.0 / 1.15) or \
			not is_equal_approx(session._equipment_area(100.0), 110.0) or \
			not is_equal_approx(session._persistent_damage_multiplier(), 1.0):
		_fail("Style Burst should grant only 15 percent attack speed and 10 percent area")
		return
	for index in range(120):
		session._add_overstimulation_style_points(1, "bank:%d" % index)
	if session._overstimulation_style_pending_points != 100:
		_fail("Points earned during Style Burst should bank up to 100")
		return
	session.player_active_time = 6.0
	session._update_overstimulation_style_gauge()
	if session._overstimulation_style_burst_expires_at != 12.0 or \
			session._overstimulation_style_points != 0 or session._overstimulation_style_pending_points != 0:
		_fail("A full bank should chain into another burst without losing overflow")
		return
	session.player_active_time = 12.0
	session._update_overstimulation_style_gauge()
	if session._overstimulation_style_burst_expires_at != 0.0 or \
			session._overstimulation_style_points != 0:
		_fail("An empty bank should end the burst without decaying gauge points")
		return
	session._add_overstimulation_style_points(70, "risk-partial")
	session._risk_reward_buff_expires_at = 20.0
	session.player_active_time = 13.0
	session._add_overstimulation_style_points(30, "dodge-final")
	if session._overstimulation_style_burst_expires_at != 19.0 or \
			not is_equal_approx(session._overstimulation_area_multiplier(), 1.3) or \
			not is_equal_approx(session._persistent_damage_multiplier(), 1.2):
		_fail("Risk and Style Burst area bonuses should add, while burst does not add damage")
		return
	for mode in ["armorless", "sandbox"]:
		session.mode_id = mode
		session.sandbox_diagnostics_enabled = mode == "sandbox"
		session._add_overstimulation_style_points(1, "excluded:%s" % mode)
		if session._overstimulation_style_points != 0:
			_fail("Armorless and Sandbox should not receive Style Gauge points")
			return
	session.free()
	print("Survival style gauge smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
