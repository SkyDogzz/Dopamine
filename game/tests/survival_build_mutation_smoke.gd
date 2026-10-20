extends SceneTree

func _initialize() -> void:
	var session_script = load("res://scripts/survival_session.gd")
	var loadout_script = load("res://scripts/survival_loadout.gd")
	if session_script == null or loadout_script == null:
		_fail("Survival session and loadout should parse with build mutations")
		return
	var session = session_script.new()
	session.loadout = loadout_script.new(1)
	session.mode_id = "survival"
	session.player = load("res://scenes/player.tscn").instantiate()
	session.player.move_speed = session._base_player_move_speed
	var offers: Array[Dictionary] = session._draw_overstimulation_mutation_options()
	var offered_ids: Array[String] = []
	for offer in offers:
		offered_ids.append(str(offer["id"]))
	if offers.size() != 3 or offered_ids.size() != 3 or \
		not session._overstimulation_mutation_due(6, 7, session.WAVE_DIRECTOR_SCRIPT.State.WAVE,
			session.WAVE_DIRECTOR_SCRIPT.State.WAVE) or \
		session._overstimulation_mutation_due(12, 12, session.WAVE_DIRECTOR_SCRIPT.State.WAVE,
			session.WAVE_DIRECTOR_SCRIPT.State.MID_BOSS) or \
		not session._overstimulation_mutation_due(12, 13, session.WAVE_DIRECTOR_SCRIPT.State.MID_BOSS,
			session.WAVE_DIRECTOR_SCRIPT.State.WAVE):
		_fail("Offers should contain three cards and occur at 6/12 after the mid-boss transition")
		return
	session._overstimulation_mutation_active = "redline"
	session._apply_overstimulation_mutation()
	session._overstimulation_mutation_active = "blood_rush"
	session._apply_overstimulation_mutation()
	if session._overstimulation_mutation_attack_speed_bonus != 0.0 or \
		session._overstimulation_mutation_enemy_speed_multiplier != 1.0 or \
		session._overstimulation_mutation_healing_multiplier != 1.5:
		_fail("A new choice should replace all effects from the previous mutation")
		return
	for mutation_id in ["redline", "chain_reaction", "experience_storm", "blood_rush", "frozen_tempo", "prism_volley"]:
		session._overstimulation_mutation_active = mutation_id
		session._apply_overstimulation_mutation()
		match mutation_id:
			"redline":
				if not is_equal_approx(session._effective_weapon_cooldown(1.0), 1.0 / 1.2) or \
					not is_equal_approx(session._overstimulation_mutation_enemy_speed_multiplier, 1.1):
					_fail("Redline should speed up player attacks and enemies")
					return
			"chain_reaction":
				session._overstimulation_mutation_kills = 0
				for _kill in range(7):
					session._record_overstimulation_mutation_kill("chaser")
				if session._overstimulation_mutation_kills != 7:
					_fail("Chain Reaction should count player kills toward its eighth-kill pulse")
					return
				var before_boss: int = session._overstimulation_mutation_kills
				session._record_overstimulation_mutation_kill("mid_boss")
				if session._overstimulation_mutation_kills != before_boss:
					_fail("Bosses should not advance Chain Reaction")
					return
			"experience_storm":
				if not is_equal_approx(session._xp_pickup_radius(0.0), session.xp_collection_radius * 1.5) or \
					not is_equal_approx(session._overstimulation_mutation_player_speed_multiplier, 1.1):
					_fail("Experience Storm should increase XP radius and use the 10 percent player speed multiplier")
					return
			"blood_rush":
				if not is_equal_approx(session._equipment_kill_healing(10.0), 15.0) or \
					not is_equal_approx(session._overstimulation_mutation_health_decay_multiplier, 1.2):
					_fail("Blood Rush should increase kill healing and HP decay")
					return
			"frozen_tempo":
				if not is_equal_approx(session._equipment_area(100.0), 125.0) or \
					not is_equal_approx(session._overstimulation_mutation_spawn_rate_multiplier, 1.15):
					_fail("Frozen Tempo should increase weapon area and enemy spawn rate")
					return
			"prism_volley":
				if not is_equal_approx(session._persistent_damage_multiplier(), 0.9) or \
					not is_equal_approx(session._overstimulation_mutation_critical_damage_bonus, 25.0):
					_fail("Prism Volley should trade base damage for critical damage")
					return
		session._overstimulation_mutation_active = ""
	session.mode_id = "armorless"
	if session._overstimulation_mutation_due(6, 7, session.WAVE_DIRECTOR_SCRIPT.State.WAVE,
			session.WAVE_DIRECTOR_SCRIPT.State.WAVE):
		_fail("Armorless should not receive build mutation offers")
		return
	session.mode_id = "survival"
	session.sandbox_diagnostics_enabled = true
	if session._overstimulation_mutation_due(6, 7, session.WAVE_DIRECTOR_SCRIPT.State.WAVE,
			session.WAVE_DIRECTOR_SCRIPT.State.WAVE):
		_fail("Sandbox diagnostics should not receive build mutation offers")
		return
	session.player.free()
	session.free()
	print("Survival build mutation smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
