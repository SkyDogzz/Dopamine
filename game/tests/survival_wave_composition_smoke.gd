extends SceneTree

func _initialize() -> void:
	if load("res://scripts/survival_session.gd") == null:
		_fail("The Survival session should parse with wave compositions enabled")
		return
	var script = load("res://scripts/survival_wave_director.gd")
	var director = script.new()
	for expected in [
		{"wave": 3, "name": ""}, {"wave": 4, "name": "HUNT"},
		{"wave": 5, "name": "PURSUIT"}, {"wave": 9, "name": "BLAST"},
		{"wave": 11, "name": "CROSSFIRE"}, {"wave": 13, "name": "NEST"},
	]:
		director.wave = int(expected["wave"])
		if director.composition_name() != expected["name"]:
			_fail("Wave composition rotation should be stable and use only unlocked archetypes")
			return
	director.state = script.State.MID_BOSS
	if not director.composition_name().is_empty():
		_fail("Boss phases should not advertise a regular enemy composition")
		return
	var session_script = load("res://scripts/survival_session.gd")
	var session = session_script.new()
	session.wave_director = script.new()
	session.wave_director.wave = 12
	var allowed_roles := {
		"HUNT": ["chaser", "sprinter"],
		"CROSSFIRE": ["chaser", "tank", "shooter"],
		"NEST": ["chaser", "buffer", "shielder", "summoner"],
		"BLAST": ["chaser", "exploder"],
		"PURSUIT": ["chaser", "sprinter", "buffer"],
	}
	var normal_role_chance: float = session._composition_role_chance()
	for composition in allowed_roles:
		for spawn_index in range(100):
			var enemy_type: String = session._composed_enemy_type(composition, spawn_index)
			if not allowed_roles[composition].has(enemy_type):
				_fail("A composition should spawn only its complementary existing archetypes")
				return
			var repeated_type: String = session._composed_enemy_type(composition, spawn_index)
			if enemy_type != repeated_type:
				_fail("The same wave and spawn index should select the same composition role")
				return
	var complementary_count := 0
	for spawn_index in range(100):
		if session._composed_enemy_type("CROSSFIRE", spawn_index) != "chaser":
			complementary_count += 1
	if complementary_count != roundi(normal_role_chance * 100.0):
		_fail("Normal difficulty should use the documented proposed complementary-role share")
		return
	session.difficulty_id = "easy"
	var easy_role_chance: float = session._composition_role_chance()
	session.difficulty_id = "chaos"
	if session._composition_role_chance() <= easy_role_chance:
		_fail("Higher difficulty should increase the relative weight of complementary roles")
		return
	session.wave_director.wave = 5
	if not is_equal_approx(session._composition_elite_spawn_multiplier(), 1.5):
		_fail("Pursuit should favor elite appearances without bypassing their existing budget")
		return
	session.sandbox_diagnostics_enabled = true
	if not is_equal_approx(session._composition_elite_spawn_multiplier(), 1.0):
		_fail("The Sandbox should not receive the Survival composition modifier")
		return
	session.free()
	print("Survival wave composition smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
