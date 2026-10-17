extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path("user://survival_elite_smoke")
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var save_service = load("res://scripts/save_service.gd").new(directory)
	var progression = load("res://scripts/progression_service.gd").new(save_service, "0")
	var profile: Dictionary = progression.load_profile()["profile"]
	var equipment: Dictionary = load("res://scripts/equipment_generator.gd").new(1).generate_survival_item("elite-haste")
	equipment["rarity"] = "legendary"
	equipment["stat_lines"] = [
		{"stat_id": "damage_pct", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0},
		{"stat_id": "max_hp", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0},
		{"stat_id": "move_speed_pct", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0},
	]
	equipment["unique_effect_id"] = "elite_haste"
	equipment["equipped"] = true
	profile["equipment_inventory"] = [equipment]
	if not save_service.save_slot("0", profile):
		_fail("Could not save the equipped Elite Haste fixture")
		return
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.progression_service = progression
	session.difficulty_id = "easy"
	if session._elite_affix_for_roll(0.1) != "Hasted" or session._elite_affix_for_roll(0.25) != "Armored" or \
			session._elite_affix_for_roll(0.4) != "Regenerating" or session._elite_affix_for_roll(0.55) != "Volatile" or \
			session._elite_affix_for_roll(0.75) != "Shielded" or session._elite_affix_for_roll(0.9) != "Split-on-Death":
		_fail("Elite roll should select all six supported affixes at their thresholds")
		return
	if not is_equal_approx(session._support_enemy_spawn_chance(0.10), 0.10):
		_fail("Non-Chaos difficulties should preserve existing support spawn chances")
		return
	session.difficulty_id = "chaos"
	var chaos_affixes: PackedStringArray = session._elite_affixes_for_rolls(0.1, 0.1)
	if not is_equal_approx(session._support_enemy_spawn_chance(0.10), 0.15) or chaos_affixes.size() != 2 or \
			chaos_affixes[0] == chaos_affixes[1]:
		_fail("Chaos should increase support spawn chances and select two distinct elite affixes")
		return
	session.difficulty_id = "easy"
	var combo_simulation = ClassDB.instantiate("CombatSimulation")
	var combo_sequence: int = combo_simulation.spawn_enemy("elite", 1, Vector2.ZERO, Vector2.ZERO,
		1.0, "Armored+Shielded")
	if combo_sequence <= 0 or not await _wait_until(func() -> bool:
		return int(combo_simulation.snapshot()["last_sequence"]) >= combo_sequence
	):
		_fail("A two-affix elite should be accepted by the combat simulation")
		return
	var combined_affix_entity: Dictionary = combo_simulation.snapshot()["entities"][0]
	var combined_affixes: Array = combined_affix_entity["components"].get("Affixes", [])
	if combined_affixes != ["Armored", "Shielded"] or \
			str(combined_affix_entity["components"].get("Affix", "")) != "Armored+Shielded" or \
			not bool(combined_affix_entity["components"].get("Shielded", false)) or \
			not is_equal_approx(float(combined_affix_entity["components"]["DamageTakenMultiplier"]), 0.325):
		_fail("Distinct elite affix effects should coexist and multiply damage reduction")
		return
	var affix_ids := ["Hasted", "Armored", "Regenerating", "Volatile", "Shielded", "Split-on-Death"]
	var expected_pairs := {}
	var last_combo_sequence := 0
	for first_index in range(affix_ids.size()):
		for second_index in range(first_index + 1, affix_ids.size()):
			var first_affix: String = affix_ids[first_index]
			var second_affix: String = affix_ids[second_index]
			var pair_id := first_affix + "+" + second_affix
			expected_pairs[pair_id] = [first_affix, second_affix]
			last_combo_sequence = combo_simulation.spawn_enemy("elite", 1,
				Vector2(first_index * 120.0, second_index * 120.0), Vector2.ZERO, 1.0, pair_id)
			if last_combo_sequence <= 0:
				_fail("The production simulation should accept distinct affix pair %s" % pair_id)
				return
	if not await _wait_until(func() -> bool:
		return int(combo_simulation.snapshot()["last_sequence"]) >= last_combo_sequence
	):
		_fail("The production simulation should publish all fifteen distinct elite affix pairs")
		return
	var observed_pairs := {}
	for entity in combo_simulation.snapshot()["entities"]:
		var components: Dictionary = entity["components"]
		var pair_id := str(components.get("Affix", ""))
		if not expected_pairs.has(pair_id):
			continue
		var pair: Array = expected_pairs[pair_id]
		var has_hasted: bool = pair.has("Hasted")
		var has_armored: bool = pair.has("Armored")
		var has_regenerating: bool = pair.has("Regenerating")
		var has_volatile: bool = pair.has("Volatile")
		var has_shielded: bool = pair.has("Shielded")
		var expected_damage_multiplier := (0.65 if has_armored else 1.0) * \
			(0.5 if has_shielded else 1.0)
		if components.get("Affixes", []) != pair or \
				not is_equal_approx(float(components["MoveSpeed"]), 100.0 if has_hasted else 75.0) or \
				not is_equal_approx(float(components["DamageTakenMultiplier"]), expected_damage_multiplier) or \
				not is_equal_approx(float(components["HealthRegenPerSecond"]), 0.5 if has_regenerating else 0.0) or \
				not is_equal_approx(float(components["DeathExplosionRadius"]), 82.0 if has_volatile else 0.0) or \
				not is_equal_approx(float(components["DeathExplosionDamage"]), 18.0 if has_volatile else 0.0):
			_fail("Pair %s should preserve and combine each affix effect" % pair_id)
			return
		observed_pairs[pair_id] = true
	if observed_pairs.size() != expected_pairs.size():
		_fail("The production simulation should expose every distinct two-affix combination")
		return
	if combo_simulation.spawn_enemy("elite", 1, Vector2.ZERO, Vector2.ZERO, 1.0, "Armored+Armored") != 0 or \
			combo_simulation.spawn_enemy("elite", 1, Vector2.ZERO, Vector2.ZERO, 1.0, "Armored+") != 0:
		_fail("Elite affix combinations should reject duplicate or malformed affixes")
		return
	combo_simulation = null
	await process_frame
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = true
	session.skip_starting_weapon_choice = true
	session.elite_spawn_interval_seconds = 20.0
	session.elite_spawn_chance = 1.0
	session.elite_chest_drop_chance = 1.0
	root.add_child(session)
	await process_frame
	if session.loadout.weapon_level("lightning_conductor") != 1:
		_fail("The real run fixture should own its starter weapon before collecting run metrics")
		return
	if session.simulation.spawn_enemy("elite", 1, Vector2.ZERO, Vector2.ZERO, 1.0, "Phaser") != 0:
		_fail("Elite spawn should reject an affix that has no gameplay implementation")
		return
	if session.simulation.spawn_enemy("chaser", 1, Vector2.ZERO, Vector2.ZERO, 1.0, "Hasted") != 0:
		_fail("Non-elite families should reject elite-only affixes")
		return
	if not await _wait_until(func() -> bool: return not session.simulation.snapshot()["paused"]):
		_fail("Elite test session should start its simulation")
		return
	session.player_active_time = 20.0
	session._next_elite_spawn_time = 20.0
	session._advance_wave_director(0.0, false)
	if not await _wait_until(func() -> bool:
		for entity in session.simulation.snapshot()["entities"]:
			if entity["components"]["EnemyType"] == "elite":
				return true
		return false
	):
		_fail("Elite director should spawn a Hasted elite when its cooldown is ready")
		return
	var elite: Dictionary = {}
	for entity in session.simulation.snapshot()["entities"]:
		if entity["components"]["EnemyType"] == "elite":
			elite = entity
			break
	var components: Dictionary = elite["components"]
	var affix: String = str(components.get("Affix", ""))
	var valid_hasted := affix == "Hasted" and is_equal_approx(float(components["MoveSpeed"]), 100.0)
	var valid_armored := affix == "Armored" and is_equal_approx(float(components["MoveSpeed"]), 75.0) and \
			is_equal_approx(float(components["DamageTakenMultiplier"]), 0.65)
	var valid_regenerating := affix == "Regenerating" and is_equal_approx(float(components["HealthRegenPerSecond"]),
			float(components["Health"]["maximum"]) * 0.01)
	var valid_volatile := affix == "Volatile" and is_equal_approx(float(components["DeathExplosionRadius"]), 82.0) and \
			is_equal_approx(float(components["DeathExplosionDamage"]), 18.0)
	var valid_shielded := affix == "Shielded" and bool(components["Shielded"]) and \
			is_equal_approx(float(components["DamageTakenMultiplier"]), 0.5)
	var valid_split := affix == "Split-on-Death"
	if not valid_hasted and not valid_armored and not valid_regenerating and not valid_volatile and not valid_shielded and not valid_split:
		_fail("Elite snapshot should expose one of the six implemented affixes")
		return
	session._try_spawn_elite()
	await process_frame
	var elite_count := 0
	for entity in session.simulation.snapshot()["entities"]:
		if entity["components"]["EnemyType"] == "elite":
			elite_count += 1
	if elite_count != 1:
		_fail("Elite threat budget should allow only one active elite")
		return
	session._entities = []
	for index in range(8):
		session._entities.append({"components": {
			"EnemyType": "chaser",
			"ThreatLevel": 1.0,
		}})
	session.player_active_time = 30.0
	session._next_elite_spawn_time = 30.0
	session._try_spawn_elite()
	if session._next_elite_spawn_time != 30.0:
		_fail("Elite should wait when the wave threat budget is already full")
		return
	session._entities = session.simulation.snapshot()["entities"]
	session.player_active_time = 20.0
	var pause_sequence: int = session.simulation.pause()
	if not await _wait_until(func() -> bool:
		return session.simulation.snapshot()["paused"] and \
				int(session.simulation.snapshot()["last_sequence"]) >= pause_sequence
	):
		_fail("Simulation should pause before the deterministic elite kill")
		return
	var base_move_speed: float = session.player.move_speed
	if not session._has_unique_effect("elite_haste"):
		_fail("An equipped unique effect should be loaded into the Survival session")
		return
	var transform: Dictionary = components["Transform2D"]
	var projectile_sequence: int = session.simulation.spawn_projectile(
		"elite_smoke_bolt", Vector2(float(transform["x"]), float(transform["y"])),
		Vector2.ZERO, 1000.0, 32.0, 1.0
	)
	if not await _wait_until(func() -> bool:
		return int(session.simulation.snapshot()["last_sequence"]) >= projectile_sequence
	):
		_fail("Test projectile should reach the simulation")
		return
	var step_sequence: int = session.simulation.step(0.01)
	if not await _wait_until(func() -> bool:
		return int(session.simulation.snapshot()["last_sequence"]) >= step_sequence
	):
		_fail("Deterministic elite kill step should complete")
		return
	if not await _wait_until(func() -> bool: return session.kill_count == 1):
		_fail("Elite death should enter the ordinary kill reward path")
		return
	if not session._item_level_feedback.visible or \
			not session._item_level_feedback_label.text.contains("ELITE HASTE"):
		_fail("Elite Haste activation should show a short, readable HUD cue")
		return
	if not is_equal_approx(session._elite_haste_expires_at, session.player_active_time + 3.0) or \
		not is_equal_approx(session.player.move_speed, base_move_speed * 1.15):
		_fail("Elite Haste should grant 15% move speed for three active seconds after an elite death")
		return
	session.player_active_time = session._elite_haste_expires_at
	session._refresh_player_move_speed()
	if not is_equal_approx(session.player.move_speed, base_move_speed):
		_fail("Elite Haste should expire on the active simulation clock")
		return
	if session._world_chests.is_empty():
		_fail("Guaranteed elite chest setting should produce a reward")
		return
	session._finish_run(false)
	var saved_achievement_metrics: Dictionary = progression.load_profile()["profile"]["achievement_progress"]["metrics"]
	var affix_id: String = session.ELITE_AFFIX_ACHIEVEMENT_IDS[affix]
	if saved_achievement_metrics.get("elite_affix_kills_%s" % affix_id, 0) != 1 or \
			saved_achievement_metrics.get("elite_affix_types_defeated", 0) != 1 or \
			saved_achievement_metrics.get("max_weapon_level_lightning_conductor", 0) != 1:
		_fail("The actual Easy run result should persist its elite affix kill and account-wide affix variety: %s / %s / %s" % [affix, str(session._elite_affix_kills), str(saved_achievement_metrics)])
		return
	var armored_kills_before := int(session._elite_affix_kills.get("armored", 0))
	var shielded_kills_before := int(session._elite_affix_kills.get("shielded", 0))
	session._record_enemy_kill("elite", "Armored+Shielded")
	if int(session._elite_affix_kills.get("armored", 0)) != armored_kills_before + 1 or \
			int(session._elite_affix_kills.get("shielded", 0)) != shielded_kills_before + 1:
		_fail("A Chaos elite kill should count progress for both of its affixes")
		return
	var split_session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	split_session.spawn_initial_enemy = false
	split_session.wave_spawning_enabled = false
	split_session.skip_starting_weapon_choice = true
	root.add_child(split_session)
	if not await _wait_until(func() -> bool: return not split_session.simulation.snapshot()["paused"]):
		_fail("Split-on-Death scenario should start its simulation")
		return
	split_session.summoner_max_active_summons = 2
	split_session.split_on_death_summon_count = 2
	var elite_position: Vector2 = split_session.player.global_position + Vector2(180.0, 0.0)
	var split_spawn_sequence: int = split_session.simulation.spawn_enemy(
		"elite", 1, elite_position, Vector2.ZERO, 1.0, "Split-on-Death"
	)
	if not await _wait_until(func() -> bool:
		return int(split_session.simulation.snapshot()["last_sequence"]) >= split_spawn_sequence
	):
		_fail("Split-on-Death elite should reach the simulation")
		return
	var split_entity: Dictionary = {}
	for entity in split_session.simulation.snapshot()["entities"]:
		if entity["components"].get("Affix", "") == "Split-on-Death":
			split_entity = entity
			break
	if split_entity.is_empty():
		_fail("Split-on-Death affix should be published on the elite")
		return
	var split_transform: Dictionary = split_entity["components"]["Transform2D"]
	var split_pause_sequence: int = split_session.simulation.pause()
	if not await _wait_until(func() -> bool:
		var state: Dictionary = split_session.simulation.snapshot()
		return state["paused"] and int(state["last_sequence"]) >= split_pause_sequence
	):
		_fail("Split-on-Death scenario should pause before its deterministic kill")
		return
	var split_position := Vector2(float(split_transform["x"]), float(split_transform["y"]))
	var split_projectile_sequence: int = split_session.simulation.spawn_projectile(
		"split_elite_smoke_bolt", split_position, Vector2.ZERO, 1000.0, 32.0, 1.0
	)
	if not await _wait_until(func() -> bool:
		return int(split_session.simulation.snapshot()["last_sequence"]) >= split_projectile_sequence
	):
		_fail("Split-on-Death test projectile should reach the simulation")
		return
	var split_step_sequence: int = split_session.simulation.step(0.01)
	if not await _wait_until(func() -> bool:
		return int(split_session.simulation.snapshot()["last_sequence"]) >= split_step_sequence
	):
		_fail("Split-on-Death deterministic kill step should complete")
		return
	if not await _wait_until(func() -> bool:
		return _count_enemy_type(split_session.simulation.snapshot()["entities"], "summoned") == 2
	):
		_fail("Split-on-Death should spawn two adds within the global summon cap")
		return
	print("Survival elite smoke passed")
	quit()

func _count_enemy_type(entities: Array, enemy_type: String) -> int:
	var count := 0
	for entity in entities:
		if entity["components"].get("EnemyType", "") == enemy_type:
			count += 1
	return count

func _wait_until(predicate: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if predicate.call():
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
