extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session_script = load("res://scripts/survival_session.gd")
	if session_script == null:
		_fail("SurvivalSession should parse with the optional intensity mode")
		return
	var session = session_script.new()
	for method_name in ["_overstimulation_intensity_active", "_overstimulation_event_interval",
			"_mobile_xp_core_interval"]:
		if not session.has_method(method_name):
			_fail("SurvivalSession should expose %s for its run intensity option" % method_name)
			return
	if session.overstimulation_intensity_enabled or session._overstimulation_intensity_active():
		_fail("The optional intensity mode should be disabled by default")
		return
	session.mode_id = "survival"
	if session._overstimulation_event_interval() != 3 or session._mobile_xp_core_interval() != 45.0:
		_fail("Standard runs should keep the original event and mobile core intervals")
		return
	session.overstimulation_intensity_enabled = true
	if not session._overstimulation_intensity_active() or session._overstimulation_event_interval() != 2 or \
		session._mobile_xp_core_interval() != 30.0:
		_fail("Intensity should enable 2-wave events and a 30-second mobile XP core in Survival")
		return
	session._overstimulation_event_wave = 2
	if not session._overstimulation_event_eligible(2) or not session._overstimulation_event_eligible(4) or \
		session._overstimulation_event_eligible(12):
		_fail("Intense events should target every second non-boss wave and skip boss waves")
		return
	if session._next_overstimulation_event_wave(10) != 14 or session._next_overstimulation_event_wave(8) != 10:
		_fail("The event schedule should skip boss wave 12 and continue at the next non-boss interval")
		return
	session.mode_id = "survival"
	session.wave_director = load("res://scripts/survival_wave_director.gd").new()
	session.wave_director.elapsed_in_wave = 6.0
	if not is_equal_approx(session._overstimulation_spawn_rate_multiplier(), 1.25):
		_fail("Intensity should raise the standard pressure spawn rate by 25 percent")
		return
	var normal_interval: float = session._wave_enemy_spawn_interval()
	session.overstimulation_intensity_enabled = false
	var standard_interval: float = session._wave_enemy_spawn_interval()
	if not is_equal_approx(normal_interval, standard_interval / 1.25):
		_fail("The extra spawn cadence should not alter the wave or enemy stat multipliers")
		return
	session.overstimulation_intensity_enabled = true
	for excluded_mode in ["armorless", "sandbox"]:
		session.mode_id = excluded_mode
		if session._overstimulation_intensity_active() or session._overstimulation_event_interval() != 3 or \
			session._mobile_xp_core_interval() != 45.0:
			_fail("%s must ignore the optional intensity mode" % excluded_mode)
			return
	session.mode_id = "endless"
	if not session._overstimulation_intensity_active():
		_fail("Standard Endless should accept the optional intensity mode")
		return
	if not _verify_double_event_chance(session, 0.2, false) or not _verify_double_event_chance(session, 0.4, true):
		return
	if not await _verify_rewards():
		return
	session.free()
	print("Survival intensity mode smoke passed")
	quit()

func _verify_double_event_chance(session: Object, expected: float, enabled: bool) -> bool:
	session.mode_id = "survival"
	session.overstimulation_intensity_enabled = enabled
	session._overstimulation_rng.seed = 918273
	session._overstimulation_last_anomalies.clear()
	var double_events := 0
	for _index in range(10000):
		var anomalies: Array = session._draw_overstimulation_event_anomalies()
		if anomalies.size() == 2:
			double_events += 1
			if not session._overstimulation_pair_compatible(anomalies[0], anomalies[1]):
				_fail("Intensity should preserve the anomaly compatibility table")
				return false
	var rate := float(double_events) / 10000.0
	if absf(rate - expected) > 0.02:
		_fail("Double anomaly chance should be %d%%, got %.1f%%" % [roundi(expected * 100.0), rate * 100.0])
		return false
	return true

func _verify_rewards() -> bool:
	const TEST_DIRECTORY := "user://survival_intensity_mode_smoke"
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var save_service = load("res://scripts/save_service.gd").new(directory)
	var service = load("res://scripts/progression_service.gd").new(save_service, "0")
	var profile: Dictionary = service.load_profile()["profile"]
	profile["highest_unlocked_difficulty"] = "normal"
	if not save_service.save_slot("0", profile):
		_fail("Could not prepare the isolated Normal intensity reward profile")
		return false
	var standard: Dictionary = service.award_survival_run("intensity-standard", 24, true, 0, "normal")
	var intense: Dictionary = service.award_survival_run("intensity-enabled", 24, true, 0, "normal", {}, 7, true)
	if not standard.get("ok", false) or standard.get("essence") != 88 or standard.get("powder_basic") != 122 or \
		not intense.get("ok", false) or intense.get("essence") != 109 or intense.get("powder_basic") != 140:
		_fail("Intensity should multiply the normal end-of-run Essence/Powder reward, including bonus Essence, by 1.15")
		return false
	var endless: Dictionary = service.award_endless_standard_run("intensity-endless", 25, 0, "normal", {}, 0, true)
	if not endless.get("ok", false) or endless.get("essence") != 75 or endless.get("powder_basic") != 109:
		_fail("Intensity should also multiply the Endless standard end-of-run rewards by 1.15")
		return false
	var hub: Control = load("res://scenes/survival_hub.tscn").instantiate()
	hub.progression_service = service
	root.add_child(hub)
	current_scene = hub
	await process_frame
	var toggle: CheckButton = hub.get_node("Content/Main/DifficultyCard/Body/IntensityToggle")
	if toggle.button_pressed or not toggle.text.contains("×1.15"):
		hub.queue_free()
		_fail("The launch hub should show the 1.15 reward multiplier with the option disabled by default")
		return false
	toggle.button_pressed = true
	hub._launch_run()
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if current_scene != null and current_scene.scene_file_path.ends_with("survival_session.tscn"):
			break
	if current_scene == null or not current_scene.scene_file_path.ends_with("survival_session.tscn") or \
			not current_scene._overstimulation_intensity_active() or \
			current_scene._overstimulation_event_wave != 2 or current_scene._mobile_xp_core_next_at != 30.0:
		_fail("Launching an intense Survival run should pass the toggle and initialize its faster schedules")
		return false
	current_scene.queue_free()
	await process_frame
	return true

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
