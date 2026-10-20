extends SceneTree

func _initialize() -> void:
	var session_script = load("res://scripts/survival_session.gd")
	if session_script == null:
		_fail("Survival session should parse with weapon heat")
		return
	var session = session_script.new()
	session.loadout = load("res://scripts/survival_loadout.gd").new(1)
	session.mode_id = "survival"
	for activation in range(7):
		session._record_overstimulation_weapon_activation("minigun", 0.18, float(activation) * 0.1)
	if not is_equal_approx(float(session._overstimulation_weapon_heat["minigun"]), 96.6) or \
		session._overstimulation_weapon_overdrive_active("minigun", 0.7):
		_fail("Each activation should add 12 heat plus the slow-weapon calibration amount")
		return
	session._record_overstimulation_weapon_activation("minigun", 0.18, 0.7)
	if not is_equal_approx(float(session._overstimulation_weapon_heat["minigun"]), 25.0) or \
		not session._overstimulation_weapon_overdrive_active("minigun", 0.7) or \
		not is_equal_approx(session._overstimulation_effective_weapon_cooldown("minigun", 1.35, 0.7), 1.0):
		_fail("Reaching 100 should reset to 25 and grant two seconds of 35 percent faster cadence")
		return
	session._update_overstimulation_weapon_heat(2.8, 0.1)
	if session._overstimulation_weapon_overdrive_active("minigun", 2.8) or \
		not is_equal_approx(float(session._overstimulation_weapon_heat["minigun"]), 24.0):
		_fail("Overdrive should expire after two seconds and resume cooling")
		return
	session._update_overstimulation_weapon_heat(5.3, 2.5)
	if float(session._overstimulation_weapon_heat["minigun"]) != 0.0:
		_fail("Idle weapons should cool at ten heat per second")
		return
	session.mode_id = "armorless"
	session._update_overstimulation_weapon_heat(6.0, 0.0)
	session._record_overstimulation_weapon_activation("minigun", 0.18, 6.0)
	if not session._overstimulation_weapon_heat.is_empty():
		_fail("Armorless should not accumulate Overstimulation weapon heat")
		return
	session.mode_id = "survival"
	session.sandbox_diagnostics_enabled = true
	session._update_overstimulation_weapon_heat(7.0, 0.0)
	session._record_overstimulation_weapon_activation("minigun", 0.18, 7.0)
	if not session._overstimulation_weapon_heat.is_empty():
		_fail("Sandbox should not accumulate Overstimulation weapon heat")
		return
	session.free()
	print("Survival weapon heat smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
