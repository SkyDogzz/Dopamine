extends SceneTree

const DIRECTOR_SCRIPT := preload("res://scripts/survival_wave_director.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var survival = DIRECTOR_SCRIPT.new()
	for _wave in range(12):
		survival.advance(30.0)
	if survival.state != DIRECTOR_SCRIPT.State.MID_BOSS or survival.wave != 12 or \
		not survival.boss_defeated() or survival.wave != 13:
		_fail("Normal Survival should preserve its current wave 12 boss transition")
		return
	var armorless = DIRECTOR_SCRIPT.new(true)
	for boss_wave in [12, 24, 36, 48, 60]:
		var elapsed_steps := 0
		while (armorless.wave < boss_wave or armorless.state != DIRECTOR_SCRIPT.State.MID_BOSS) and elapsed_steps < 60:
			armorless.advance(30.0)
			elapsed_steps += 1
		if armorless.wave != boss_wave or armorless.state != DIRECTOR_SCRIPT.State.MID_BOSS or \
			not armorless.boss_defeated() or armorless.wave != boss_wave + 1 or \
			armorless.state != DIRECTOR_SCRIPT.State.WAVE:
			_fail("Armorless should continue after each boss every 12 completed waves")
			return
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.mode_id = "armorless"
	session.spawn_initial_enemy = false
	session.skip_starting_weapon_choice = true
	session.player_hp = 10000.0
	session.player_max_hp = 10000.0
	root.add_child(session)
	await process_frame
	if session.simulation == null:
		_fail("Armorless long-run session should initialize its simulation")
		return
	var armorless_hp_wave_24: float = pow(1.10, 23.0)
	if session._wave_population(60) <= session._wave_population(24) or \
		not is_equal_approx(session._enemy_hp_multiplier(24), armorless_hp_wave_24) or \
		not is_equal_approx(session._enemy_hp_multiplier(25), armorless_hp_wave_24 * 1.055) or \
		not is_equal_approx(session._enemy_hp_multiplier(60), armorless_hp_wave_24 * pow(1.055, 36.0)):
		_fail("Armorless enemy HP should follow its proposed 1.10 pre-24 and 1.055 post-24 growth curve")
		return
	session.wave_director.wave = 12
	session.wave_director.state = DIRECTOR_SCRIPT.State.MID_BOSS
	var boss_wave_time: float = session.wave_director.elapsed_in_wave
	var initial_active_time: float = session.player_active_time
	var initial_hp: float = session.player_hp
	session.simulation.step(1.0)
	var deadline := Time.get_ticks_msec() + 2000
	while session.player_active_time <= initial_active_time and Time.get_ticks_msec() < deadline:
		await process_frame
	if session.player_active_time <= initial_active_time or session.player_hp >= initial_hp or \
		not is_equal_approx(session.wave_director.elapsed_in_wave, boss_wave_time):
		_fail("Armorless boss time should decay HP and advance active time while the wave clock stays frozen")
		return
	var active_time_before_next_wave: float = session.player_active_time
	session.wave_director.boss_defeated()
	session.simulation.step(1.0)
	deadline = Time.get_ticks_msec() + 2000
	while session.player_active_time <= active_time_before_next_wave and Time.get_ticks_msec() < deadline:
		await process_frame
	if session.player_active_time <= active_time_before_next_wave or session.player_hp >= initial_hp:
		_fail("Armorless active time and HP decay should continue after a boss without resetting")
		return
	session.queue_free()
	await process_frame
	print("armorless_wave_director_smoke: passed five boss cycles through wave 60 and active-time decay")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
