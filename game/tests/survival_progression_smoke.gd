extends SceneTree

const TEST_DIRECTORY := "user://survival_progression_smoke"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var save_service = load("res://scripts/save_service.gd").new(directory)
	var progression = load("res://scripts/progression_service.gd").new(save_service, "0")
	var profile_fixture: Dictionary = progression.load_profile()["profile"]
	profile_fixture["highest_unlocked_difficulty"] = "normal"
	if not save_service.save_slot("0", profile_fixture):
		_fail("Could not prepare the Normal difficulty result fixture")
		return
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.progression_service = progression
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	root.add_child(session)
	await process_frame
	session.difficulty_id = "easy"
	session.player_hp = 100.0
	var easy_population: int = session._wave_population(5)
	session._take_enemy_damage(10.0)
	if not is_equal_approx(session._enemy_hp_multiplier(1), 0.75) or \
		not is_equal_approx(session.player_hp, 93.0):
		_fail("Easy should apply separate proposed enemy HP and damage factors")
		return
	session.difficulty_id = "normal"
	session.player_hp = 100.0
	var normal_population: int = session._wave_population(5)
	session._take_enemy_damage(10.0)
	if not is_equal_approx(session._enemy_hp_multiplier(1), 1.0) or \
		not is_equal_approx(session.player_hp, 90.0) or easy_population >= normal_population:
		_fail("Normal should preserve baseline factors and its density should exceed Easy")
		return
	session.difficulty_id = "chaos"
	session.player_hp = 100.0
	var chaos_population: int = session._wave_population(5)
	session._take_enemy_damage(10.0)
	if not is_equal_approx(session._enemy_hp_multiplier(1), 3.2) or \
		not is_equal_approx(session.player_hp, 77.0) or chaos_population <= normal_population:
		_fail("Chaos should use its own HP, damage, and density factors")
		return
	session.difficulty_id = "normal"
	session.kill_count = 100
	session._record_enemy_kill("tank")
	session._record_enemy_kill("tank")
	session._record_enemy_kill("not_an_enemy")
	session._record_weapon_damage("lightning_primary:1", 1200.0)
	session._record_weapon_damage("lightning_arc:1", 300.0)
	session._record_weapon_damage("enemy_projectile", 5000.0)
	session._record_weapon_kill("lightning_primary:1")
	session._record_weapon_kill("lightning_arc:1")
	session._record_weapon_kill("enemy_projectile")
	session.loadout._relic_levels["storm_core"] = 5
	session.loadout._evolved_weapons["lightning_conductor"] = true
	session._finish_run(false)
	var reward_label: Label = session.get_node("HUD/RunResultOverlay/RunResultPanel/Content/Rewards")
	var equipment_label: Label = session.get_node("HUD/RunResultOverlay/RunResultPanel/Content/Equipment")
	var achievement_label: Label = session.get_node("HUD/RunResultOverlay/RunResultPanel/Content/Achievement")
	var profile: Dictionary = save_service.load_slot("0")["payload"]
	if not session.run_over or reward_label.text != "+17 ESSENCE  •  +23 BASIC POWDER":
		_fail("A normal Survival defeat should persist and show its proposed Normal rewards")
		return
	if not equipment_label.text.begins_with("EQUIPMENT: "):
		_fail("The Survival result should show its permanent equipment reward")
		return
	if not achievement_label.text.contains("EXTERMINATOR TIER +1") or \
			profile["achievement_progress"]["metrics"]["total_kills"] != 100 or \
			profile["achievement_progress"]["metrics"]["enemy_kills_tank"] != 2 or \
			profile["achievement_progress"]["metrics"]["weapon_damage_lightning_conductor"] != 1500.0 or \
			profile["achievement_progress"]["metrics"]["weapon_kills_lightning_conductor"] != 2 or \
			profile["achievement_progress"]["metrics"]["max_relic_level_storm_core"] != 5 or \
			profile["achievement_progress"]["metrics"]["evolutions_lightning_conductor"] != 1 or \
			profile["achievement_progress"]["metrics"]["weapon_damage_minigun"] != 0.0:
		_fail("Survival results should persist Exterminator, per-enemy kills and mapped weapon damage metrics")
		return
	if profile["resources"].get("essence") != 17 or profile["resources"].get("powder_basic") != 23:
		_fail("The Survival result should save its reward to the progression profile")
		return
	if profile["equipment_inventory"].size() != 1 or profile["equipment_inventory"][0].get("source_mode") != "survival":
		_fail("The Survival result should persist exactly one item in the permanent inventory")
		return
	session._finish_run(false)
	profile = save_service.load_slot("0")["payload"]
	if profile["resources"].get("essence") != 17 or profile["rewarded_survival_runs"].size() != 1 or \
			profile["achievement_progress"]["metrics"]["total_kills"] != 100 or \
			profile["achievement_progress"]["metrics"]["enemy_kills_tank"] != 2 or \
			profile["achievement_progress"]["metrics"]["weapon_damage_lightning_conductor"] != 1500.0 or \
			profile["achievement_progress"]["metrics"]["weapon_kills_lightning_conductor"] != 2 or \
			profile["achievement_progress"]["metrics"]["max_relic_level_storm_core"] != 5 or \
			profile["achievement_progress"]["metrics"]["evolutions_lightning_conductor"] != 1:
		_fail("Finishing the same run twice must not duplicate its persistent reward")
		return
	var temporary_session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	temporary_session.progression_service = load("res://scripts/progression_service.gd").new(null, "temporary")
	temporary_session.skip_starting_weapon_choice = true
	temporary_session.spawn_initial_enemy = false
	temporary_session.wave_spawning_enabled = false
	temporary_session.weapon_enabled = false
	root.add_child(temporary_session)
	await process_frame
	temporary_session._finish_run(true)
	if temporary_session._run_result.get_node("Content/Rewards").text != "RUN SANS SAUVEGARDE" or \
		save_service.load_slot("0")["payload"] != profile:
		_fail("A temporary run should show no-save feedback and leave the normal profile untouched: %s / %s" % [
			temporary_session._run_result.get_node("Content/Rewards").text,
			save_service.load_slot("0")["payload"] == profile,
		])
		return
	temporary_session.queue_free()
	await process_frame
	print("Survival progression smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
