extends SceneTree

func _initialize() -> void:
	var session_script = load("res://scripts/survival_session.gd")
	var director_script = load("res://scripts/survival_wave_director.gd")
	if session_script == null or director_script == null:
		_fail("Boss combo scripts should parse")
		return
	var session = session_script.new()
	session.wave_director = director_script.new()
	session.player = CharacterBody2D.new()
	session.mode_id = "survival"
	session.difficulty_id = "chaos"
	for wave_number in [12, 24]:
		session.wave_director.wave = wave_number
		var patterns: Array = ["radial", "aimed", "charge"] if wave_number == 12 else ["ray", "zone", "spiral", "summon"]
		var attack := {"normal_attack_count": 2, "main_attack_count": 2, "pattern_index": 2,
			"last_normal_pattern": patterns[0], "last_attack_pattern": patterns[0],
			"chaos_followup_pending": true, "is_chaos_followup": false}
		if not session._schedule_overstimulation_boss_combo(attack, 2, patterns, 10.0):
			_fail("Every third main attack should become a combo on boss waves 12 and 24")
			return
		var steps: Array = attack["combo_steps"]
		if steps.size() != 2 or steps[0] == patterns[0] or not patterns.has(steps[0]) or not patterns.has(steps[1]):
			_fail("A combo should contain two known patterns and exclude the previous main pattern")
			return
		if bool(attack["chaos_followup_pending"]):
			_fail("A combo should replace the already scheduled Chaos follow-up")
			return
		session._finish_boss_attack(attack, 10.0, 2.0, 0.3)
		if str(attack["stage"]) != "telegraph" or not bool(attack["combo_pending"]) or \
				not is_equal_approx(float(attack["fire_at"]), 10.6 + session.final_boss_telegraph_seconds):
			_fail("The second pattern should start its normal telegraph after a 0.6 second gap")
			return
		attack["pattern"] = str(steps[1])
		session._finish_boss_attack(attack, 11.0, 2.0, 0.3)
		if bool(attack["combo_pending"]) or bool(attack["chaos_followup_pending"]):
			_fail("A completed combo should not schedule another Chaos follow-up")
			return
	session.wave_director.wave = 13
	var excluded := {"normal_attack_count": 2, "main_attack_count": 2, "pattern_index": 2}
	if session._schedule_overstimulation_boss_combo(excluded, 1, ["radial", "aimed", "charge"], 0.0):
		_fail("Boss combos should only activate on waves 12 and 24")
		return
	session.player.free()
	session.free()
	print("Survival boss combo smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
