extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save_directory := ProjectSettings.globalize_path("user://survival_unique_effects_smoke")
	DirAccess.make_dir_recursive_absolute(save_directory)
	for file_name in DirAccess.get_files_at(save_directory):
		DirAccess.remove_absolute(save_directory.path_join(file_name))
	var save_service = load("res://scripts/save_service.gd").new(save_directory)
	var progression = load("res://scripts/progression_service.gd").new(save_service, "0")
	var profile: Dictionary = progression.load_profile()["profile"]
	profile["unlocked_skill_nodes"] = progression.skill_node_ids("weapon_unlocks") + progression.skill_node_ids("relic_unlocks")
	profile["equipment_inventory"] = [
		_capacity_item("expanded_legendary", "helmet", "legendary", 3),
		_capacity_item("expanded_mythic", "ring", "mythic", 4),
	]
	for equipment in profile["equipment_inventory"]:
		equipment["unique_effect_id"] = "expanded_loadout"
		equipment["equipped"] = true
	if not save_service.save_slot("0", profile):
		_fail("Could not save the equipped capacity effect fixtures")
		return
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.progression_service = progression
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	if session.simulation == null:
		_fail("Survival combat simulation should initialize")
		return
	if progression.equipped_unique_effects() != ["expanded_loadout"] or \
			session.loadout.max_slots("weapon") != 6 or session.loadout.max_slots("relic") != 6:
		_fail("Equipping duplicate capacity effects should unlock only one weapon and relic slot")
		return
	var weapon_ids: Array = session.loadout._weapons.keys()
	var relic_ids: Array = session.loadout._relics.keys()
	for index in range(6):
		if not session.loadout.apply_offer("weapon:%s" % weapon_ids[index]) or \
				not session.loadout.apply_offer("relic:%s" % relic_ids[index]):
			_fail("The equipped effect should allow six weapons and six relics in the run")
			return
	if session.loadout.apply_offer("weapon:%s" % weapon_ids[6]) or \
			session.loadout.apply_offer("relic:%s" % relic_ids[6]):
		_fail("An active capacity effect must not raise either loadout beyond six items")
		return
	session._cached_unique_effects.clear()
	session.loadout.set_slot_capacity_bonus(0, 0)
	if not await _wait_for_simulation_running(session):
		_fail("Survival session should start before the unique-effect checks")
		return
	var enemy_sequence: int = session.simulation.spawn_enemy("chaser", 1, Vector2(40.0, 0.0), Vector2.ZERO)
	if not await _wait_for_sequence(session.simulation, enemy_sequence):
		_fail("Lightning Burst target should spawn")
		return
	var pause_sequence: int = session.simulation.pause()
	if not await _wait_for_sequence(session.simulation, pause_sequence):
		_fail("Unique-effect checks should run against a paused simulation")
		return
	session._entities = session.simulation.snapshot()["entities"]
	session.player_active_time = 0.0
	var success_seed := _seed_for_lightning_success()
	if success_seed < 1:
		_fail("Could not find a deterministic Lightning Burst success seed")
		return
	session._cached_unique_effects.clear()
	seed(success_seed)
	session._try_unique_lightning_burst(100.0)
	if session._next_unique_lightning_time != 0.0 or _count_projectiles(session, "unique_lightning_burst") != 0:
		_fail("Lightning Burst must stay inactive unless its unique effect is equipped")
		return
	session._cached_unique_effects.append("lightning_burst")
	seed(success_seed)
	session._try_unique_lightning_burst(100.0)
	if not await _wait_for_projectile_count(session, "unique_lightning_burst", 1) or \
			session._next_unique_lightning_time != 2.0 or \
			not session._item_level_feedback_label.text.contains("LIGHTNING BURST"):
		_fail("Equipped Lightning Burst should fire at a nearby target, set its 2-second cooldown and show feedback")
		return
	session._try_unique_lightning_burst(100.0)
	if _count_projectiles(session, "unique_lightning_burst") != 1:
		_fail("Lightning Burst should not fire again before its internal cooldown expires")
		return
	var clear_sequence: int = session.simulation.kill_all()
	if not await _wait_for_sequence(session.simulation, clear_sequence) or \
			not await _wait_for_no_entities(session):
		_fail("The nearby Lightning Burst target should clear before the range check")
		return
	var distant_sequence: int = session.simulation.spawn_enemy("chaser", 1, Vector2(300.0, 0.0), Vector2.ZERO)
	if not await _wait_for_sequence(session.simulation, distant_sequence):
		_fail("Distant range-check target should spawn")
		return
	session._entities = session.simulation.snapshot()["entities"]
	session.player_active_time = 2.0
	seed(success_seed)
	session._try_unique_lightning_burst(100.0)
	if session._next_unique_lightning_time != 2.0 or _count_projectiles(session, "unique_lightning_burst") != 0:
		_fail("Lightning Burst should reject targets outside its visible weapon range")
		return
	clear_sequence = session.simulation.kill_all()
	if not await _wait_for_sequence(session.simulation, clear_sequence) or \
			not await _wait_for_no_entities(session):
		_fail("Distant Lightning target should clear before the evolution check")
		return
	var evolved_target_sequence: int = session.simulation.spawn_enemy(
		"chaser", 1, Vector2(40.0, 0.0), Vector2.ZERO
	)
	if not await _wait_for_sequence(session.simulation, evolved_target_sequence):
		_fail("Evolution test target should spawn within Lightning range")
		return
	session._entities = session.simulation.snapshot()["entities"]
	session._cached_unique_effects.clear()
	session._cached_unique_effects.append("evolution_shockwave")
	session._evolution_shockwave_triggered = false
	session.loadout._weapon_levels["lightning_conductor"] = 1
	session.loadout._evolved_weapons.clear()
	session._next_weapon_time = 0.0
	session._fire_lightning_conductor(2.0, false)
	if session._evolution_shockwave_triggered or _count_projectiles(session, "evolution_shockwave") != 0:
		_fail("Evolution Shockwave must stay inactive before an evolution is acquired")
		return
	session.loadout._weapon_levels["lightning_conductor"] = 5
	session.loadout._evolved_weapons["lightning_conductor"] = true
	session._fire_lightning_conductor(3.0, false)
	if not await _wait_for_projectile_count(session, "evolution_shockwave", 8) or \
			not session._evolution_shockwave_triggered or \
			not session._item_level_feedback_label.text.contains("EVOLUTION SHOCKWAVE"):
		_fail("The first Lightning fire after evolution should create one eight-projectile shockwave and show feedback")
		return
	session._fire_lightning_conductor(4.0, false)
	if _count_projectiles(session, "evolution_shockwave") != 8:
		_fail("Evolution Shockwave should activate only once in a run")
		return
	session.queue_free()
	await process_frame
	print("survival_unique_effects_smoke: passed equipment, range, cooldown and evolution gates")
	quit(0)

func _seed_for_lightning_success() -> int:
	for seed_value in range(1, 10000):
		seed(seed_value)
		if randf() < 0.1:
			return seed_value
	return 0

func _capacity_item(instance_id: String, slot: String, rarity: String, stat_count: int) -> Dictionary:
	var generator = load("res://scripts/equipment_generator.gd")
	var stat_lines: Array[Dictionary] = []
	for index in range(stat_count):
		stat_lines.append({
			"stat_id": generator.STAT_IDS[index], "roll_percentile": 0.5,
			"enhancement_level": 0, "fail_streak": 0,
		})
	return {
		"instance_id": instance_id, "slot": slot, "rarity": rarity,
		"stat_lines": stat_lines, "equipped": true,
		"rolls_calibrated": false, "unique_effect_id": "expanded_loadout",
		"source_mode": "survival",
	}

func _count_projectiles(session: Node2D, projectile_type: String) -> int:
	var count := 0
	for entity in session.simulation.snapshot()["entities"]:
		if str(entity["components"].get("EnemyType", "")) == projectile_type:
			count += 1
	return count

func _wait_for_projectile_count(session: Node2D, projectile_type: String, expected: int) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		if _count_projectiles(session, projectile_type) >= expected:
			return true
		await process_frame
	return false

func _wait_for_no_entities(session: Node2D) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		if session.simulation.snapshot()["entities"].is_empty():
			return true
		await process_frame
	return false

func _wait_for_sequence(simulation: Object, sequence: int) -> bool:
	if sequence <= 0:
		return false
	var deadline := Time.get_ticks_msec() + 3000
	while int(simulation.snapshot()["last_sequence"]) < sequence and Time.get_ticks_msec() < deadline:
		await process_frame
	return int(simulation.snapshot()["last_sequence"]) >= sequence

func _wait_for_simulation_running(session: Node2D) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while bool(session.simulation.snapshot()["paused"]) and Time.get_ticks_msec() < deadline:
		await process_frame
	return not bool(session.simulation.snapshot()["paused"])

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
