extends SceneTree

func _initialize() -> void:
	var session_script = load("res://scripts/survival_session.gd")
	if session_script == null:
		_fail("The Survival session should parse with surprise events enabled")
		return
	var session = session_script.new()
	session.loadout = load("res://scripts/survival_loadout.gd").new(1)
	session.mode_id = "survival"
	if not session._overstimulation_enabled():
		_fail("Standard Survival should enable overstimulation events")
		return
	session.mode_id = "endless"
	if not session._overstimulation_enabled():
		_fail("Standard Endless should enable overstimulation events")
		return
	session.mode_id = "armorless"
	if session._overstimulation_enabled():
		_fail("Armorless should remain outside the overstimulation event system")
		return
	session.mode_id = "survival"
	session.sandbox_diagnostics_enabled = true
	if session._overstimulation_enabled():
		_fail("Sandbox diagnostics should remain outside the event system")
		return
	session.sandbox_diagnostics_enabled = false
	session._overstimulation_attack_speed_bonus = 20.0
	if not is_equal_approx(session._effective_weapon_cooldown(1.0), 1.0 / 1.2):
		_fail("Overclock should increase player attack speed by 20 percent")
		return
	session._overstimulation_attack_speed_bonus = 0.0
	session.wave_director = load("res://scripts/survival_wave_director.gd").new()
	session.wave_director.elapsed_in_wave = 5.0
	var normal_interval: float = session._wave_enemy_spawn_interval()
	session._overstimulation_event_anomaly = "FERAL_SURGE"
	var feral_interval: float = session._wave_enemy_spawn_interval()
	if not is_equal_approx(feral_interval, normal_interval / 1.5):
		_fail("Feral Surge should raise spawn cadence by 50 percent")
		return
	var first_rng = RandomNumberGenerator.new()
	var second_rng = RandomNumberGenerator.new()
	first_rng.seed = 8172
	second_rng.seed = 8172
	if first_rng.randi() != second_rng.randi():
		_fail("Anomaly selection should use a seedable run-local random stream")
		return
	session._overstimulation_event_anomaly = "MAGNETIC_STORM"
	session._overstimulation_xp_storm = true
	session._cached_equipment_bonuses = {}
	var storm_radius: float = session._xp_pickup_radius(0.0)
	session._overstimulation_xp_storm = false
	var base_radius: float = session._xp_pickup_radius(0.0)
	if not is_equal_approx(storm_radius, base_radius * 2.0):
		_fail("Magnetic Storm should double XP pickup radius")
		return
	session.free()
	print("Survival wave event smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
