extends SceneTree

func _initialize() -> void:
	if load("res://scripts/survival_session.gd") == null:
		_fail("The Survival session should parse with phase feedback enabled")
		return
	var script = load("res://scripts/survival_wave_director.gd")
	var director = script.new()
	if director.phase_name() != "RISING" or not is_equal_approx(director.spawn_rate_multiplier(), 0.5):
		_fail("A wave should begin with a rising phase and half spawn cadence")
		return
	director.advance(2.5)
	if not is_equal_approx(director.spawn_rate_multiplier(), 0.75):
		_fail("Spawn cadence should rise progressively during the first five seconds")
		return
	director.advance(2.5)
	if director.phase_name() != "PRESSURE" or not is_equal_approx(director.spawn_rate_multiplier(), 1.0):
		_fail("Pressure should use the normal spawn cadence")
		return
	director.advance(20.0)
	if director.phase_name() != "CALM" or not is_equal_approx(director.spawn_rate_multiplier(), 0.5):
		_fail("Waves 1-4 should end with five seconds at half cadence")
		return
	director.advance(5.0)
	if director.wave != 2 or director.phase_name() != "RISING":
		_fail("Phases should preserve the fixed 30-second wave duration")
		return
	for check in [{"wave": 5, "elapsed": 27.0}, {"wave": 13, "elapsed": 28.0}]:
		var later = script.new()
		later.wave = int(check["wave"])
		later.elapsed_in_wave = float(check["elapsed"])
		if later.phase_name() != "CALM":
			_fail("The wave-group calm duration should match its specification")
			return
	var boss = script.new()
	boss.wave = 12
	boss.state = script.State.MID_BOSS
	if boss.phase_name() != "PRESSURE" or not is_equal_approx(boss.spawn_rate_multiplier(), 1.0):
		_fail("A boss phase should not inherit a wave calm")
		return
	var scaled = script.new()
	scaled.wave_duration_seconds = 0.05
	scaled.advance(0.025)
	if scaled.phase_name() != "PRESSURE":
		_fail("Phase timing should scale with the configured test wave duration")
		return
	print("Survival wave phase smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
