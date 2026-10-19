extends SceneTree

func _initialize() -> void:
	var session_script = load("res://scripts/survival_session.gd")
	if session_script == null:
		_fail("The Survival session should parse with kill combos enabled")
		return
	var session = session_script.new()
	session.loadout = load("res://scripts/survival_loadout.gd").new(1)
	session.mode_id = "survival"
	session.player_hp = 100.0
	for _kill in range(3):
		session._record_overstimulation_combo_kill("chaser")
	if session._overstimulation_combo_kills != 3 or session._overstimulation_combo_milestone != 1 or \
			not is_equal_approx(session._effective_weapon_cooldown(1.0), 1.0 / 1.05):
		_fail("Three kills should reach RUSH and grant 5 percent attack speed")
		return
	session.player_active_time = 1.0
	for _kill in range(3):
		session._record_overstimulation_combo_kill("chaser")
	if session._overstimulation_combo_kills != 6 or session._overstimulation_combo_milestone != 2 or \
			not is_equal_approx(session._effective_weapon_cooldown(1.0), 1.0 / 1.1):
		_fail("Six kills should replace the lower tier with 10 percent attack speed")
		return
	for _kill in range(4):
		session._record_overstimulation_combo_kill("chaser")
	if session._overstimulation_combo_kills != 10 or session._overstimulation_combo_milestone != 3:
		_fail("Ten kills should reach the third combo tier")
		return
	for _kill in range(5):
		session._record_overstimulation_combo_kill("chaser")
	if session._overstimulation_combo_kills != 15 or session._overstimulation_combo_milestone != 4:
		_fail("Fifteen kills should reach the fourth combo tier")
		return
	for _kill in range(10):
		session._record_overstimulation_combo_kill("chaser")
	if session._overstimulation_combo_kills != 25 or session._overstimulation_combo_milestone != 5 or \
			not is_equal_approx(session._effective_weapon_cooldown(1.0), 1.0 / 1.25):
		_fail("Twenty-five kills should reach the maximum 25 percent attack-speed tier")
		return
	session.player_active_time = 4.0
	session._take_player_damage(1.0)
	if session._overstimulation_combo_kills != 25:
		_fail("HP decay should not break an active kill combo")
		return
	session._take_enemy_damage(1.0)
	if session._overstimulation_combo_kills != 0 or session._overstimulation_combo_milestone != 0 or \
			not is_equal_approx(session._effective_weapon_cooldown(1.0), 1.0):
		_fail("Receiving enemy damage should immediately break the combo and remove its bonus")
		return
	for _kill in range(3):
		session._record_overstimulation_combo_kill("chaser")
	session.player_active_time = 8.0
	session._update_overstimulation_combo()
	if session._overstimulation_combo_kills != 0:
		_fail("Four seconds without another kill should break the combo")
		return
	session.player_active_time = 9.0
	session._record_overstimulation_combo_kill("chaser")
	if session._overstimulation_combo_kills != 1:
		_fail("A kill after an expired window should start a new combo")
		return
	session.mode_id = "armorless"
	session._record_overstimulation_combo_kill("chaser")
	if session._overstimulation_combo_kills != 1:
		_fail("Armorless should not advance the Overstimulation combo")
		return
	session.mode_id = "survival"
	session.sandbox_diagnostics_enabled = true
	session._record_overstimulation_combo_kill("chaser")
	if session._overstimulation_combo_kills != 1:
		_fail("Sandbox diagnostics should not advance the Overstimulation combo")
		return
	session.free()
	print("Survival kill combo smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
