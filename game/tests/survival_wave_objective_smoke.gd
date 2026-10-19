extends SceneTree

func _initialize() -> void:
	if load("res://scripts/survival_session.gd") == null:
		_fail("The Survival session should parse with wave objectives enabled")
		return
	var director_script = load("res://scripts/survival_wave_director.gd")
	var director = director_script.new()
	if director.objective_due():
		_fail("No objective should appear during wave 1")
		return
	director.wave = 2
	if not director.objective_due():
		_fail("Objectives should be scheduled on even non-boss waves")
		return
	director.wave = 12
	director.state = director_script.State.MID_BOSS
	if director.objective_due():
		_fail("The wave-12 boss transition should not receive an objective")
		return
	director.boss_defeated()
	if director.wave != 13 or director.objective_due():
		_fail("Objective scheduling should resume after the boss on the next even wave")
		return
	director.wave = 14
	if not director.objective_due():
		_fail("The first even wave after a boss should receive the next objective")
		return
	director.wave = 24
	director.state = director_script.State.FINAL_BOSS
	if director.objective_due():
		_fail("The final-boss transition should not receive an objective")
		return
	var session = load("res://scripts/survival_session.gd").new()
	if session._wave_objective_kill_quota(2) != 3 or session._wave_objective_kill_quota(24) != 7:
		_fail("The kill quota should scale with the wave")
		return
	session.player_xp_to_next = 100.0
	session._add_xp(session.player_xp_to_next * 0.15)
	if not is_equal_approx(session.player_xp, 15.0):
		_fail("Objective success should award 15 percent of progress to the next level")
		return
	session.loadout = load("res://scripts/survival_loadout.gd").new(1)
	session.player_active_time = 2.0
	session._wave_objective_attack_speed_expires_at = 8.0
	if not is_equal_approx(session._effective_weapon_cooldown(1.0), 1.0 / 1.1):
		_fail("Objective success should grant a 10 percent attack-speed bonus")
		return
	session.player_active_time = 8.0
	if not is_equal_approx(session._effective_weapon_cooldown(1.0), 1.0):
		_fail("The objective attack-speed bonus should expire after six active seconds")
		return
	session.free()
	print("Survival wave objective smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
