extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var director_script = load("res://scripts/survival_wave_director.gd")
	var director = director_script.new()
	var debug_director = director_script.new()
	debug_director.elapsed_in_wave = debug_director.wave_duration_seconds
	if not debug_director.advance(0.0) or debug_director.wave != 2:
		_fail("A debug-advanced wave deadline should transition without adding active time")
		return
	if director.wave != 1 or director.state != director_script.State.WAVE:
		_fail("A run should start at wave 1")
		return
	if director.advance(29.0) or director.wave != 1:
		_fail("A wave should remain active before its duration")
		return
	if not director.advance(1.0) or director.wave != 2:
		_fail("A completed wave should advance exactly once")
		return
	for wave in range(2, 12):
		director.advance(30.0)
	if director.state != director_script.State.MID_BOSS or director.wave != 11:
		_fail("The mid-boss should follow wave 11")
		return
	if director.advance(30.0) or not director.boss_defeated() or director.wave != 13:
		_fail("The mid-boss should pause the wave clock and resume at wave 13")
		return
	for wave in range(13, 24):
		director.advance(30.0)
	if director.state != director_script.State.FINAL_BOSS or director.wave != 23:
		_fail("The final boss should follow wave 23")
		return
	if not director.boss_defeated() or director.state != director_script.State.VICTORY:
		_fail("Defeating the final boss should complete the run")
		return
	print("Survival wave director smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
