extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not await _overcharge_triggers_on_repeated_electric_hits_only():
		_fail("Direct electric hits should apply one-second Shock and trigger one non-chaining Overcharge on a repeated hit")
		return
	if not await _hemorrhage_adds_one_bleed_tick_without_refreshing_duration():
		_fail("A direct critical hit on a bleeding enemy should add one Bleed tick without refreshing its duration, while DoT and non-critical hits do nothing")
		return
	if not await _thermal_shock_combines_burn_and_chill_once():
		_fail("Thermal Shock should trigger from direct Burn/Chill combinations, obey cooldown, and ignore DoT ticks")
		return
	if not await _toxic_ignition_combines_poison_and_burn_once():
		_fail("Toxic Ignition should trigger on a direct second status hit, obey its local cooldown, and ignore DoT ticks")
		return
	if not await _toxic_ignition_runs_from_real_status_hits():
		_fail("Real Toxic Cloud poison and Inferno burn hits should trigger Toxic Ignition, preserve both statuses, and damage only targets in its radius")
		return
	if not await _electroplague_spreads_existing_poison_on_direct_shock():
		_fail("A direct Shock hit on a poisoned target should copy its Poison to every living enemy within 60 px, without extra damage or reapplying existing Poison")
		return
	if not await _gravity_collapse_hits_targets_once_inside_void_orb_fields():
		_fail("Gravity Collapse should deal 50% direct-hit damage once to each enemy within 60 px of an impacted target in a Void Orb field")
		return
	if not await _weapon_progression_config_is_loaded_and_modifiable():
		_fail("Survival should load validated weapon progression milestones from the JSON config")
		return
	if not await _relic_bonuses_and_evolution_are_scoped():
		_fail("Relic global bonuses should scale per level and evolution damage should require and affect only its weapon")
		return
	if not await _nearest_weapon_targets_skip_dead_enemies():
		_fail("Automatic weapons should ignore dead enemies that remain in a simulation snapshot")
		return
	if not await _lightning_prioritizes_chainable_clusters():
		_fail("Lightning Conductor should start at the nearest target in the densest chainable cluster")
		return
	if not await _crimson_daggers_prioritize_finishable_targets():
		_fail("Crimson Daggers should prioritize the lowest-health living target in range")
		return
	if not await _inferno_prioritizes_high_threat():
		_fail("Inferno should prioritize the highest-threat enemy in range, breaking ties by distance")
		return
	if not await _inferno_level_progression():
		_fail("Inferno levels 2–5 should apply their proposed damage, range, width and burn upgrades")
		return
	if not await _crimson_dagger_level_progression():
		_fail("Crimson Daggers levels 2–5 should apply their proposed damage, count and orbit-speed upgrades")
		return
	if not await _lightning_level_progression():
		_fail("Lightning Conductor levels 2–5 should apply their proposed damage, chain and cooldown upgrades")
		return
	if not await _void_orb_level_progression():
		_fail("Void Orb levels 2–5 should apply their proposed damage, radius, duration and pull-force upgrades")
		return
	if not await _prism_laser_level_progression():
		_fail("Prism Laser levels 2–5 should apply their proposed damage, range, tracking and damage upgrades")
		return
	if not await _toxic_cloud_prioritizes_durable_targets():
		_fail("Toxic Cloud should prioritize the highest-health living enemy in range, breaking ties by distance")
		return
	if not await _sawblades_prioritizes_ricochet_clusters():
		_fail("Sawblades should aim at the nearest target in the densest reachable ricochet cluster")
		return
	if not await _void_orb_targets_farthest_live_enemy():
		_fail("Void Orb should target the farthest living enemy inside its range")
		return
	if not await _prism_laser_prioritizes_dense_groups():
		_fail("Prism Laser should select a dense primary group and center secondary beams on it")
		return
	if not await _meteor_staff_prioritizes_densest_group():
		_fail("Meteor Staff should target the densest reachable group and aim at its centroid")
		return
	if not await _minigun_targets_nearest_and_holds_target():
		_fail("Minigun should acquire the nearest target, keep it valid, and retarget when it becomes invalid")
		return
	if not await _weapon_kills_target("lightning_conductor", "storm_core", 12.4):
		_fail("Storm Core should boost Lightning Conductor enough to defeat the test target")
		return
	if not await _weapon_kills_target("inferno_sprayer", "infernal_heart", 8.2):
		_fail("Infernal Heart should boost Inferno Sprayer enough to defeat the test target")
		return
	if not await _weapon_kills_target("crimson_daggers", "blood_chalice", 13.0, 30.0):
		_fail("Crimson Daggers should hit with both prototype projectiles")
		return
	if not await _blood_chalice_boosts_kill_heal():
		_fail("Blood Chalice should increase the proposed kill healing")
		return
	if not await _bloodstorm_requires_level_five_and_bleeds():
		_fail("Bloodstorm should require level 5, orbit, apply bleed and lifesteal")
		return
	if not await _infinite_circuit_branches():
		_fail("Infinite Circuit should branch from its two initial lightning targets")
		return
	if not await _wildfire_explodes_and_spreads():
		_fail("Wildfire should explode on impact and ignite nearby enemies")
		return
	if not await _minigun_hits_target():
		_fail("Minigun should hit a target and the Overdrive/Redline build should shorten its firing interval")
		return
	if not await _toxic_cloud_poison_and_pandemic():
		_fail("Toxic Cloud should poison its impact area and Pandemic should spread poison when an infected target dies")
		return
	if not await _sawblades_ricochet_between_targets():
		_fail("Sawblades should hit their first target and ricochet to another target")
		return
	if not await _magnetic_coil_homing_is_limited_to_level_five():
		_fail("Magnetic Coil should apply its proposed light homing only at relic level 5 and stay inside visible weapon range")
		return
	if not await _meteor_staff_targets_groups_and_starfall_fragments():
		_fail("Meteor Staff should hit a group and Starfall should fragment toward nearby enemies")
		return
	if not await _prism_laser_tracks_and_splits():
		_fail("Prism Laser should hit its priority target and Spectrum Collapse should fire secondary beams")
		return
	if not await _void_orb_pulls_and_pierces():
		_fail("Void Orb should pull nearby enemies and pierce distinct targets")
		return
	if not await _frost_nova_chills_and_shatters():
		_fail("Frost Nova should Chill nearby targets and Absolute Zero should shatter a frozen kill")
		return
	if not await _shatter_reacts_to_approved_direct_impacts_only():
		_fail("Shatter should launch bounded fragments from approved direct weapon hits on chilled targets only")
		return
	print("Survival weapon catalog smoke passed")
	quit()

func _overcharge_triggers_on_repeated_electric_hits_only() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	session.contact_damage_per_hit = 0.0
	root.add_child(session)
	await process_frame
	session.simulation.pause()
	var pause_deadline := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < pause_deadline and not bool(session.simulation.snapshot().get("paused", false)):
		await process_frame
	if not bool(session.simulation.snapshot().get("paused", false)):
		session.queue_free()
		return false
	var positions: Array[Vector2] = [Vector2(100.0, 100.0), Vector2(150.0, 100.0), Vector2(170.0, 100.0)]
	for position in positions:
		session.simulation.spawn("test_target", 1, position, 100.0, Vector2.ZERO)
	var targets: Array = await _wait_for_targets(session, positions.size())
	if targets.size() != positions.size():
		session.queue_free()
		return false
	var target_id: Dictionary = targets[0]["id"]
	var event := {"source_type": "infinite_circuit_branch", "target": target_id,
		"is_damage_over_time": false, "amount": 20.0, "remaining_health": 80.0,
		"sequence": 100, "reaction_budget": 1, "position": {"x": 100.0, "y": 100.0}}
	var first_hit := int(session.call("_try_overcharge", event, 0.0))
	var second_electric_hit := event.duplicate(true)
	second_electric_hit["source_type"] = "lightning_arc:test"
	var second_hit := int(session.call("_try_overcharge", second_electric_hit, 0.5))
	var cooldown_hit := int(session.call("_try_overcharge", event, 0.75))
	var non_electric := event.duplicate(true)
	non_electric["source_type"] = "minigun"
	var rejected_non_electric := int(session.call("_try_overcharge", non_electric, 1.6))
	var expired_hit := int(session.call("_try_overcharge", event, 2.0))
	session.simulation.resume()
	var deadline := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < deadline and _health_for(session, target_id) > 95.0:
		await process_frame
	var primary_health := _health_for(session, target_id)
	var nearby_health := _health_for(session, targets[1]["id"])
	var outside_health := _health_for(session, targets[2]["id"])
	var valid := first_hit == 0 and second_hit > 0 and \
			cooldown_hit == 0 and rejected_non_electric == 0 and expired_hit == 0 and \
			is_equal_approx(primary_health, 95.0) and is_equal_approx(nearby_health, 95.0) and \
			is_equal_approx(outside_health, 100.0)
	session.queue_free()
	return valid

func _health_for(session: Node2D, entity_id: Dictionary) -> float:
	for entity in session.simulation.snapshot().get("entities", []):
		if entity.get("id", {}) == entity_id:
			return float(entity.get("components", {}).get("Health", {}).get("current", -1.0))
	return -1.0


func _hemorrhage_adds_one_bleed_tick_without_refreshing_duration() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	root.add_child(session)
	await process_frame
	session.simulation.pause()
	session.simulation.spawn("test_target", 1, Vector2(200.0, 0.0), 100.0, Vector2.ZERO)
	var target_id: Dictionary = {}
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline and target_id.is_empty():
		await process_frame
		for entity in session.simulation.snapshot()["entities"]:
			if str(entity["components"].get("EnemyType", "")) == "test_target":
				target_id = entity["id"]
				break
	if target_id.is_empty() or session.simulation.apply_damage_over_time(
			int(target_id["index"]), int(target_id["generation"]), 3.0, 1.0, 5.0, "bleed") <= 0:
		session.queue_free()
		return false
	if not await _wait_for_status(session, target_id, "bleed"):
		session.queue_free()
		return false
	var before: Dictionary = {}
	for entity in session.simulation.snapshot()["entities"]:
		if entity["id"] == target_id:
			before = entity
			break
	var before_health := float(before["components"]["Health"]["current"])
	var before_bleed: Dictionary = before["components"]["DamageOverTime"]
	if session._try_hemorrhage({"critical_hit": true, "target_had_bleed": true,
			"amount": 9.0, "target": target_id, "is_damage_over_time": false}) <= 0:
		session.queue_free()
		return false
	var ticked := false
	deadline = Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline and not ticked:
		await process_frame
		for entity in session.simulation.snapshot()["entities"]:
			if entity["id"] == target_id:
				ticked = float(entity["components"]["Health"]["current"]) == before_health - 3.0
				break
	var unchanged := false
	for entity in session.simulation.snapshot()["entities"]:
		if entity["id"] == target_id:
			unchanged = entity["components"]["DamageOverTime"] == before_bleed
			break
	var rejected_non_crit: int = session._try_hemorrhage({"critical_hit": false,
		"target_had_bleed": true, "amount": 9.0, "target": target_id})
	var rejected_dot: int = session._try_hemorrhage({"critical_hit": true,
		"target_had_bleed": true, "amount": 3.0, "target": target_id, "is_damage_over_time": true})
	session.queue_free()
	return ticked and unchanged and rejected_non_crit == 0 and rejected_dot == 0

func _shatter_reacts_to_approved_direct_impacts_only() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	root.add_child(session)
	await process_frame
	session.simulation.set_speed(4.0)
	await _wait_for_simulation_speed(session, 4.0)
	for position in [Vector2(100.0, 100.0), Vector2(130.0, 100.0), Vector2(70.0, 100.0),
			Vector2(100.0, 130.0), Vector2(400.0, 100.0)]:
		session.simulation.spawn("test_target", 1, position, 1000.0, Vector2.ZERO)
	var targets: Array = await _wait_for_targets(session, 5)
	if targets.size() != 5:
		session.queue_free()
		return false
	var primary: Dictionary = targets[0]
	var primary_id: Dictionary = primary["id"]
	var primary_components: Dictionary = primary["components"]
	var primary_position := Vector2(float(primary_components["Transform2D"]["x"]),
			float(primary_components["Transform2D"]["y"]))
	var hit := {"target": primary_id, "source_type": "minigun", "target_was_chilled": true,
		"is_damage_over_time": false, "amount": 20.0, "remaining_health": 80.0,
		"sequence": 41, "reaction_budget": 1,
		"position": {"x": primary_position.x, "y": primary_position.y}}
	var approved_sources := ["crimson_dagger", "bloodstorm_dagger", "minigun", "redline", "sawblades",
		"razorstorm", "meteor_staff", "starfall", "starfall_fragment", "void_orb", "event_horizon"]
	var spawned_count := 0
	for source_type in approved_sources:
		var source_hit := hit.duplicate(true)
		source_hit["source_type"] = source_type
		spawned_count += int(session.call("_try_shatter", source_hit, session.simulation.snapshot()["entities"]))
	var excluded_count := 0
	for source_type in ["inferno_sprayer", "lightning_primary", "toxic_cloud", "frost_nova", "shatter_fragment"]:
		var excluded_hit := hit.duplicate(true)
		excluded_hit["source_type"] = source_type
		excluded_count += int(session.call("_try_shatter", excluded_hit, session.simulation.snapshot()["entities"]))
	var dot_hit := hit.duplicate(true)
	dot_hit["is_damage_over_time"] = true
	var dot_count := int(session.call("_try_shatter", dot_hit, session.simulation.snapshot()["entities"]))
	var exhausted_hit := hit.duplicate(true)
	exhausted_hit["reaction_budget"] = 0
	var exhausted_count := int(session.call("_try_shatter", exhausted_hit, session.simulation.snapshot()["entities"]))
	var fragment_damage_total := 0.0
	var deadline := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < deadline and fragment_damage_total < 165.0:
		await process_frame
		fragment_damage_total = float(session._weapon_damage_by_id.get("frost_nova", 0.0))
	var unchilled_hit := hit.duplicate(true)
	unchilled_hit["target_was_chilled"] = false
	var unchilled_count := int(session.call("_try_shatter", unchilled_hit, session.simulation.snapshot()["entities"]))
	var no_fragments_session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	no_fragments_session.spawn_initial_enemy = false
	no_fragments_session.wave_spawning_enabled = false
	no_fragments_session.weapon_enabled = false
	no_fragments_session.skip_starting_weapon_choice = true
	no_fragments_session.shatter_fragment_count = 0
	root.add_child(no_fragments_session)
	await process_frame
	no_fragments_session.simulation.spawn("test_target", 1, Vector2(100.0, 100.0), 1000.0, Vector2.ZERO)
	var no_fragments_targets: Array = await _wait_for_targets(no_fragments_session, 1)
	if no_fragments_targets.is_empty():
		no_fragments_session.queue_free()
		session.queue_free()
		return false
	var no_fragments_entities: Array = no_fragments_session.simulation.snapshot()["entities"]
	var no_fragments_target: Dictionary = no_fragments_targets[0]
	var no_fragments_components: Dictionary = no_fragments_target["components"]
	var no_fragments_position := Vector2(float(no_fragments_components["Transform2D"]["x"]),
			float(no_fragments_components["Transform2D"]["y"]))
	var no_fragments_hit := hit.duplicate(true)
	no_fragments_hit["target"] = no_fragments_target["id"]
	no_fragments_hit["position"] = {"x": no_fragments_position.x, "y": no_fragments_position.y}
	var primary_bonus_only := int(no_fragments_session.call("_try_shatter", no_fragments_hit,
			no_fragments_entities)) == 1
	no_fragments_session.queue_free()
	var valid := spawned_count == approved_sources.size() * 4 and excluded_count == 0 and dot_count == 0 and \
			exhausted_count == 0 and unchilled_count == 0 and primary_bonus_only and \
			is_equal_approx(fragment_damage_total, 220.0) and \
			is_equal_approx(_target_health(session, primary_id), 945.0) and \
			is_equal_approx(_target_health(session, targets[1]["id"]), 945.0) and \
			is_equal_approx(_target_health(session, targets[2]["id"]), 945.0) and \
			is_equal_approx(_target_health(session, targets[3]["id"]), 945.0) and \
			is_equal_approx(_target_health(session, targets[4]["id"]), 1000.0)
	if not valid:
		push_error("Shatter diagnostics: spawned=%d excluded=%d dot=%d exhausted=%d unchilled=%d damage=%s hp=%s/%s/%s/%s/%s" %
				[spawned_count, excluded_count, dot_count, exhausted_count, unchilled_count, fragment_damage_total,
				_target_health(session, primary_id), _target_health(session, targets[1]["id"]),
				_target_health(session, targets[2]["id"]), _target_health(session, targets[3]["id"]),
				_target_health(session, targets[4]["id"])])
	session.queue_free()
	return valid

func _weapon_progression_config_is_loaded_and_modifiable() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	root.add_child(session)
	await process_frame
	var valid: bool = session._weapon_progression_valid and session._weapon_progression.size() == 10 and \
		is_equal_approx(session._weapon_level_multiplier("lightning_conductor", "damage_multiplier", 2), 1.2) and \
		is_equal_approx(session._weapon_level_multiplier("lightning_conductor", "damage_multiplier", 5), 1.5) and \
		session._weapon_level_addition("lightning_conductor", "chain_count_add", 2) == 0 and \
		session._weapon_level_addition("lightning_conductor", "chain_count_add", 3) == 1 and \
		is_equal_approx(session._weapon_level_value("crimson_daggers", "projectile_count", 2, 0.0), 2.0) and \
		is_equal_approx(session._weapon_level_value("crimson_daggers", "projectile_count", 3, 0.0), 3.0)
	session._weapon_progression["void_orb"]["attraction_force_multiplier"]["5"] = 1.4
	valid = valid and is_equal_approx(session._weapon_level_multiplier("void_orb", "attraction_force_multiplier", 5), 1.4)
	session.queue_free()
	return valid

func _relic_bonuses_and_evolution_are_scoped() -> bool:
	var loadout_script = load("res://scripts/survival_loadout.gd")
	var catalog_loadout = loadout_script.new(1)
	for relic_id in catalog_loadout._relic_definitions:
		var definition: Dictionary = catalog_loadout._relic_definitions[relic_id]
		var relic_loadout = loadout_script.new(1)
		for level in range(1, relic_loadout.MAX_LEVEL + 1):
			if not relic_loadout.apply_offer("relic:" + relic_id):
				return false
			var expected_bonus := float(definition["global_bonus_per_level"]) * level
			if not is_equal_approx(relic_loadout.global_relic_bonus(str(definition["global_stat"])), expected_bonus):
				return false

	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	for weapon_id in catalog_loadout._weapon_definitions:
		var weapon_definition: Dictionary = catalog_loadout._weapon_definitions[weapon_id]
		var relic_id := str(weapon_definition["relic_id"])
		var pair_loadout = loadout_script.new(1)
		for _level in range(pair_loadout.MAX_LEVEL):
			if not pair_loadout.apply_offer("weapon:" + weapon_id):
				session.queue_free()
				return false
		for _level in range(pair_loadout.MAX_LEVEL - 1):
			if not pair_loadout.apply_offer("relic:" + relic_id):
				session.queue_free()
				return false
		if not _fill_other_weapon_slots(pair_loadout, weapon_id) or pair_loadout.is_evolution_ready(weapon_id) or \
				not pair_loadout.offers("weapon").is_empty():
			session.queue_free()
			return false
		if not pair_loadout.apply_offer("relic:" + relic_id) or not pair_loadout.is_evolution_ready(weapon_id):
			session.queue_free()
			return false
		var evolution_offers: Array[Dictionary] = pair_loadout.offers("weapon")
		if evolution_offers.size() != 1 or str(evolution_offers[0].get("id", "")) != "evolution:" + weapon_id:
			session.queue_free()
			return false
		session.loadout = pair_loadout
		if not is_equal_approx(session._weapon_combo_damage_multiplier(weapon_id), 1.0):
			session.queue_free()
			return false
		if not session.open_chest_family("weapon") or not session._chest_open:
			session.queue_free()
			return false
		var evolution_button: Button = session._chest_choice.get_node("Content/Options/Choice0")
		if not evolution_button.text.contains("EVOLUTION —"):
			session.queue_free()
			return false
		evolution_button.emit_signal("pressed")
		if not pair_loadout.is_evolved(weapon_id) or \
				not is_equal_approx(session._weapon_combo_damage_multiplier(weapon_id), 1.25):
			session.queue_free()
			return false
		if pair_loadout.weapon_level(weapon_id) != pair_loadout.MAX_LEVEL or \
				pair_loadout.relic_level(relic_id) != pair_loadout.MAX_LEVEL or \
				pair_loadout.apply_offer("evolution:" + weapon_id):
			session.queue_free()
			return false
		for other_weapon_id in catalog_loadout._weapon_definitions:
			if other_weapon_id != weapon_id and not is_equal_approx(session._weapon_combo_damage_multiplier(other_weapon_id), 1.0):
				session.queue_free()
				return false
		for offer in pair_loadout.offers("weapon"):
			if str(offer.get("id", "")) == "weapon:" + weapon_id or str(offer.get("id", "")) == "evolution:" + weapon_id:
				session.queue_free()
				return false
		var reverse_loadout = loadout_script.new(1)
		for _level in range(reverse_loadout.MAX_LEVEL):
			if not reverse_loadout.apply_offer("relic:" + relic_id):
				session.queue_free()
				return false
		if not _fill_other_weapon_slots(reverse_loadout, weapon_id, 1):
			session.queue_free()
			return false
		if not reverse_loadout.apply_offer("weapon:" + weapon_id) or reverse_loadout.is_evolution_ready(weapon_id):
			session.queue_free()
			return false
		for _level in range(reverse_loadout.MAX_LEVEL - 1):
			if not reverse_loadout.apply_offer("weapon:" + weapon_id):
				session.queue_free()
				return false
			if _level < reverse_loadout.MAX_LEVEL - 2 and reverse_loadout.is_evolution_ready(weapon_id):
				session.queue_free()
				return false
		var reverse_evolution_offers: Array[Dictionary] = reverse_loadout.offers("weapon")
		if not reverse_loadout.is_evolution_ready(weapon_id) or reverse_evolution_offers.size() != 1 or \
				str(reverse_evolution_offers[0].get("id", "")) != "evolution:" + weapon_id:
			session.queue_free()
			return false
	session.queue_free()
	return true

func _fill_other_weapon_slots(loadout: RefCounted, excluded_weapon_id: String, reserved_slots: int = 0) -> bool:
	var target_slot_count: int = loadout.MAX_SLOTS - reserved_slots
	for weapon_id in loadout._weapon_definitions:
		if weapon_id == excluded_weapon_id:
			continue
		for _level in range(loadout.MAX_LEVEL):
			if not loadout.apply_offer("weapon:" + weapon_id):
				return false
		if loadout.owned_weapons().size() == target_slot_count:
			return true
	return false

func _nearest_weapon_targets_skip_dead_enemies() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	var origin: Vector2 = session.player.global_position
	session._entities = [
		{"id": {"index": 1, "generation": 1}, "components": {
			"Health": {"current": 0.0}, "Transform2D": {"x": origin.x + 12.0, "y": origin.y},
		}},
		{"id": {"index": 2, "generation": 1}, "components": {
			"Health": {"current": 10.0}, "Transform2D": {"x": origin.x + 50.0, "y": origin.y},
		}},
	]
	var nearest: Dictionary = session._nearest_enemy(620.0)
	var excluded_ids: Array[Vector2i] = []
	var lightning_targets: Array = session._nearest_lightning_targets(origin, excluded_ids, 1, 300.0)
	session._entities = [session._entities[0]]
	if not session.loadout.apply_offer("weapon:frost_nova"):
		session.queue_free()
		return false
	session._fire_frost_nova(float(session.simulation.snapshot()["simulation_time"]), false)
	var frost_skipped_dead_targets := is_zero_approx(session._next_frost_nova_time)
	session.queue_free()
	return nearest.get("id", Vector2i(-1, -1)) == Vector2i(2, 1) and \
		lightning_targets.size() == 1 and lightning_targets[0].get("id") == Vector2i(2, 1) and frost_skipped_dead_targets

func _crimson_daggers_prioritize_finishable_targets() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	var origin: Vector2 = session.player.global_position
	session._entities = [
		{"id": {"index": 41, "generation": 1}, "components": {"Health": {"current": 20.0}, "Transform2D": {"x": origin.x + 180.0, "y": origin.y}}},
		{"id": {"index": 42, "generation": 1}, "components": {"Health": {"current": 10.0}, "Transform2D": {"x": origin.x + 120.0, "y": origin.y}}},
		{"id": {"index": 43, "generation": 1}, "components": {"Health": {"current": 50.0}, "Transform2D": {"x": origin.x + 40.0, "y": origin.y}}},
		{"id": {"index": 44, "generation": 1}, "components": {"Health": {"current": 0.0}, "Transform2D": {"x": origin.x + 10.0, "y": origin.y}}},
		{"id": {"index": 45, "generation": 1}, "components": {"Health": {"current": 0.5}, "Transform2D": {"x": origin.x + session.daggers_range + 1.0, "y": origin.y}}},
	]
	var selected: Dictionary = session._lowest_health_enemy(session.daggers_range)
	session.queue_free()
	return selected.get("id", Vector2i(-1, -1)) == Vector2i(42, 1)

func _lightning_prioritizes_chainable_clusters() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	var origin: Vector2 = session.player.global_position
	session.lightning_range = 400.0
	session.lightning_chain_range = 90.0
	session._entities = [
		{"id": {"index": 81, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 20.0, "y": origin.y}}},
		{"id": {"index": 82, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 55.0, "y": origin.y}}},
		{"id": {"index": 83, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 75.0, "y": origin.y + 10.0}}},
		{"id": {"index": 84, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 95.0, "y": origin.y}}},
		{"id": {"index": 85, "generation": 1}, "components": {"Health": {"current": 0.0}, "Transform2D": {"x": origin.x + 65.0, "y": origin.y + 5.0}}},
	]
	var targets: Array[Dictionary] = session._lightning_initial_targets(2)
	session.queue_free()
	return targets.size() == 2 and targets[0].get("id") == Vector2i(83, 1) and targets[1].get("id") == Vector2i(82, 1)

func _inferno_prioritizes_high_threat() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	var origin: Vector2 = session.player.global_position
	session._entities = [
		{"id": {"index": 21, "generation": 1}, "components": {
			"Health": {"current": 100.0}, "ThreatLevel": 1.0,
			"Transform2D": {"x": origin.x + 80.0, "y": origin.y},
		}},
		{"id": {"index": 22, "generation": 1}, "components": {
			"Health": {"current": 100.0}, "ThreatLevel": 4.0,
			"Transform2D": {"x": origin.x + 100.0, "y": origin.y},
		}},
		{"id": {"index": 23, "generation": 1}, "components": {
			"Health": {"current": 100.0}, "ThreatLevel": 4.0,
			"Transform2D": {"x": origin.x + 130.0, "y": origin.y},
		}},
		{"id": {"index": 24, "generation": 1}, "components": {
			"Health": {"current": 100.0}, "ThreatLevel": 10.0,
			"Transform2D": {"x": origin.x + session.inferno_range + 1.0, "y": origin.y},
		}},
	]
	var selected: Dictionary = session._highest_threat_enemy(session.inferno_range)
	session.queue_free()
	return selected.get("id", Vector2i(-1, -1)) == Vector2i(22, 1)

func _inferno_level_progression() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	session.inferno_projectile_speed = 0.0
	session.inferno_burn_damage_per_tick = 4.0
	root.add_child(session)
	await process_frame
	session.simulation.set_speed(1.0)
	if not await _wait_for_simulation_speed(session, 1.0):
		session.queue_free()
		return false
	for _level in range(2):
		if not session.loadout.apply_offer("weapon:inferno_sprayer"):
			session.queue_free()
			return false
	var origin: Vector2 = session.player.global_position
	session._entities = [
		{"id": {"index": 91, "generation": 1}, "components": {"Health": {"current": 100.0}, "ThreatLevel": 1.0, "Transform2D": {"x": origin.x, "y": origin.y + 80.0}}},
		{"id": {"index": 92, "generation": 1}, "components": {"Health": {"current": 100.0}, "ThreatLevel": 10.0, "Transform2D": {"x": origin.x + 160.0, "y": origin.y}}},
	]
	session._next_inferno_time = 0.0
	session.weapon_enabled = true
	session._fire_inferno_sprayer(1.0, false)
	session.weapon_enabled = false
	var level_two_shot := await _wait_for_projectile_count(session, 1)
	if level_two_shot.size() != 1:
		session.queue_free()
		return false
	var level_two_position := _projectile_position(level_two_shot[0]) - origin
	if level_two_position.x > 1.0 or level_two_position.y <= 1.0:
		session.queue_free()
		return false
	if not session.loadout.apply_offer("weapon:inferno_sprayer"):
		session.queue_free()
		return false
	session._entities = [
		{"id": {"index": 91, "generation": 1}, "components": {"Health": {"current": 100.0}, "ThreatLevel": 1.0, "Transform2D": {"x": origin.x, "y": origin.y + 80.0}}},
		{"id": {"index": 92, "generation": 1}, "components": {"Health": {"current": 100.0}, "ThreatLevel": 10.0, "Transform2D": {"x": origin.x + 160.0, "y": origin.y}}},
	]
	session._next_inferno_time = 0.0
	session.weapon_enabled = true
	session._fire_inferno_sprayer(2.0, false)
	session.weapon_enabled = false
	var level_three_shots := await _wait_for_projectile_count(session, 2)
	if level_three_shots.size() != 2:
		session.queue_free()
		return false
	var level_three_position := _projectile_position(level_three_shots[1]) - origin
	if level_three_position.x <= 1.0 or absf(level_three_position.y) > 1.0:
		session.queue_free()
		return false
	if not session.loadout.apply_offer("weapon:inferno_sprayer"):
		session.queue_free()
		return false
	session._entities = [
		{"id": {"index": 91, "generation": 1}, "components": {"Health": {"current": 100.0}, "ThreatLevel": 1.0, "Transform2D": {"x": origin.x, "y": origin.y + 80.0}}},
		{"id": {"index": 92, "generation": 1}, "components": {"Health": {"current": 100.0}, "ThreatLevel": 10.0, "Transform2D": {"x": origin.x + 160.0, "y": origin.y}}},
	]
	session._next_inferno_time = 0.0
	session.weapon_enabled = true
	session._fire_inferno_sprayer(3.0, false)
	session.weapon_enabled = false
	var level_four_shots := await _wait_for_projectile_count(session, 3)
	if level_four_shots.size() != 3:
		session.queue_free()
		return false
	var level_four_projectile: Dictionary = level_four_shots[2]["components"]["Projectile"]
	if not is_equal_approx(float(level_four_projectile["radius"]), session.inferno_projectile_radius * 1.2) or \
		not is_equal_approx(float(level_four_projectile["damage"]), session.inferno_damage * 1.2):
		session.queue_free()
		return false
	if not session.loadout.apply_offer("weapon:inferno_sprayer"):
		session.queue_free()
		return false
	session.simulation.kill_all()
	if not await _wait_for_no_entities(session):
		session.queue_free()
		return false
	session.inferno_projectile_speed = 1000.0
	session.simulation.spawn("test_target", 1, Vector2(80.0, 0.0), 100.0, Vector2.ZERO)
	if (await _wait_for_targets(session, 1)).size() != 1:
		session.queue_free()
		return false
	session._entities = session.simulation.snapshot()["entities"]
	session._next_inferno_time = 0.0
	session.weapon_enabled = true
	session._fire_inferno_sprayer(4.0, false)
	session.weapon_enabled = false
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		for entity in session.simulation.snapshot()["entities"]:
			var status: Dictionary = entity["components"].get("DamageOverTime", {})
			if status.get("status_type", "") == "burn":
				var valid_burn := is_equal_approx(float(status["damage_per_tick"]), 5.0)
				session.queue_free()
				return valid_burn
	session.queue_free()
	return false

func _crimson_dagger_level_progression() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	session.daggers_projectile_speed = 0.0
	root.add_child(session)
	await process_frame
	session.simulation.set_speed(1.0)
	if not await _wait_for_simulation_speed(session, 1.0):
		session.queue_free()
		return false
	for level in range(1, session.loadout.MAX_LEVEL + 1):
		if not session.loadout.apply_offer("weapon:crimson_daggers"):
			session.queue_free()
			return false
		var origin: Vector2 = session.player.global_position
		session._entities = [{"id": {"index": 101, "generation": 1}, "components": {
			"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 40.0, "y": origin.y},
		}}]
		session._next_daggers_time = 0.0
		session.weapon_enabled = true
		session._fire_crimson_daggers(float(level), false)
		session.weapon_enabled = false
		var expected_count := 3 if level >= 3 else 2
		var shots := await _wait_for_projectile_count(session, expected_count, "crimson_dagger")
		if shots.size() != expected_count:
			session.queue_free()
			return false
		var projectile: Dictionary = shots[0]["components"]["Projectile"]
		var expected_damage: float = session.daggers_damage * (1.2 if level >= 2 else 1.0) * (1.25 if level >= 5 else 1.0)
		var expected_orbit_speed: float = 6.0 if level >= 4 else 5.0
		if not is_equal_approx(float(projectile["damage"]), expected_damage) or \
			not is_equal_approx(float(projectile["orbit_angular_speed"]), expected_orbit_speed):
			session.queue_free()
			return false
		session.simulation.kill_all()
		if not await _wait_for_no_entities(session):
			session.queue_free()
			return false
	session.queue_free()
	return true

func _lightning_level_progression() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	session.lightning_projectile_speed = 0.0
	root.add_child(session)
	await process_frame
	session.simulation.set_speed(1.0)
	if not await _wait_for_simulation_speed(session, 1.0):
		session.queue_free()
		return false
	session.loadout._weapon_levels.erase("lightning_conductor")
	var base_damage := 0.0
	for level in range(1, session.loadout.MAX_LEVEL + 1):
		if not session.loadout.apply_offer("weapon:lightning_conductor"):
			session.queue_free()
			return false
		var origin: Vector2 = session.player.global_position
		session._entities = [{"id": {"index": 102, "generation": 1}, "components": {
			"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 40.0, "y": origin.y},
		}}]
		session._lightning_chain_states.clear()
		session._next_weapon_time = 0.0
		session.weapon_enabled = true
		session._fire_lightning_conductor(float(level), false)
		session.weapon_enabled = false
		var projectile: Dictionary = await _wait_for_projectile_prefix(session, "lightning_primary:")
		if projectile.is_empty():
			session.queue_free()
			return false
		if level == 1:
			base_damage = float(projectile["components"]["Projectile"]["damage"])
		var expected_damage: float = base_damage * (1.2 if level >= 2 else 1.0) * (1.25 if level >= 5 else 1.0)
		var expected_chain_count: int = session.lightning_chain_count + (1 if level >= 3 else 0)
		var chain_ids: Array = session._lightning_chain_states.keys()
		var expected_cooldown: float = session.lightning_cooldown * (0.85 if level >= 4 else 1.0)
		if not is_equal_approx(float(projectile["components"]["Projectile"]["damage"]), expected_damage) or \
			chain_ids.size() != 1 or int(session._lightning_chain_states[chain_ids[0]]["remaining"]) != expected_chain_count - 1 or \
			not is_equal_approx(float(session._next_weapon_time) - float(level), expected_cooldown):
			session.queue_free()
			return false
		session.simulation.kill_all()
		if not await _wait_for_no_entities(session):
			session.queue_free()
			return false
	session.queue_free()
	return true

func _void_orb_level_progression() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	session.void_orb_speed = 0.0
	root.add_child(session)
	await process_frame
	session.simulation.set_speed(1.0)
	if not await _wait_for_simulation_speed(session, 1.0):
		session.queue_free()
		return false
	session.loadout._weapon_levels.erase("void_orb")
	var base_damage := 0.0
	for level in range(1, session.loadout.MAX_LEVEL + 1):
		if not session.loadout.apply_offer("weapon:void_orb"):
			session.queue_free()
			return false
		var origin: Vector2 = session.player.global_position
		session._entities = [{"id": {"index": 103, "generation": 1}, "components": {
			"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 40.0, "y": origin.y},
		}}]
		session._next_void_orb_time = 0.0
		session.weapon_enabled = true
		session._fire_void_orb(float(level), false)
		session.weapon_enabled = false
		var shots := await _wait_for_projectile_count(session, 1, "void_orb")
		if shots.is_empty():
			session.queue_free()
			return false
		var projectile: Dictionary = shots[0]["components"]["Projectile"]
		if level == 1:
			base_damage = float(projectile["damage"])
		var expected_damage: float = base_damage * (1.2 if level >= 2 else 1.0) * (1.25 if level >= 5 else 1.0)
		var expected_radius: float = session.void_orb_attraction_radius * (1.2 if level >= 3 else 1.0)
		var expected_lifetime: float = session.void_orb_lifetime * (1.15 if level >= 4 else 1.0)
		var expected_force: float = session.void_orb_attraction_speed * (1.25 if level >= 5 else 1.0)
		if not is_equal_approx(float(projectile["damage"]), expected_damage) or \
			not is_equal_approx(float(projectile["attraction_radius"]), expected_radius) or \
			absf(float(projectile["remaining_seconds"]) - expected_lifetime) > 0.1 or \
			not is_equal_approx(float(projectile["attraction_speed"]), expected_force):
			session.queue_free()
			return false
		session.simulation.kill_all()
		if not await _wait_for_no_entities(session):
			session.queue_free()
			return false
	session.queue_free()
	return true

func _prism_laser_level_progression() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	session.prism_laser_projectile_speed = 100.0
	session.prism_laser_range = 200.0
	root.add_child(session)
	await process_frame
	session.simulation.set_speed(1.0)
	if not await _wait_for_simulation_speed(session, 1.0):
		session.queue_free()
		return false
	session.loadout._weapon_levels.erase("prism_laser")
	var base_damage := 0.0
	for level in range(1, session.loadout.MAX_LEVEL + 1):
		if not session.loadout.apply_offer("weapon:prism_laser"):
			session.queue_free()
			return false
		var origin: Vector2 = session.player.global_position
		session._entities = [{"id": {"index": 104, "generation": 1}, "components": {
			"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 20.0, "y": origin.y},
		}}]
		session._next_prism_time = 0.0
		session.weapon_enabled = true
		session._fire_prism_laser(float(level), false)
		session.weapon_enabled = false
		var shots := await _wait_for_projectile_count(session, 1, "prism_laser")
		if shots.is_empty():
			session.queue_free()
			return false
		var shot: Dictionary = shots[0]["components"]
		var velocity: Dictionary = shot["Velocity2D"]
		var speed := Vector2(float(velocity["x"]), float(velocity["y"])).length()
		var projectile: Dictionary = shot["Projectile"]
		if level == 1:
			base_damage = float(projectile["damage"])
		var expected_damage: float = base_damage * (1.2 if level >= 2 else 1.0) * (1.25 if level >= 5 else 1.0)
		var expected_speed: float = session.prism_laser_projectile_speed
		var range_multiplier: float = 1.2 if level >= 3 else 1.0
		var expected_lifetime: float = session.prism_laser_range * (240.0 / 620.0) * range_multiplier / expected_speed
		if not is_equal_approx(float(projectile["damage"]), expected_damage) or \
			absf(speed - expected_speed) > 0.1 or absf(float(projectile["remaining_seconds"]) - expected_lifetime) > 0.1:
			session.queue_free()
			return false
		session._entities = [{"id": {"index": 104, "generation": 1}, "components": {
			"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 40.0, "y": origin.y},
		}}]
		session.weapon_enabled = true
		session._fire_prism_laser(float(level) + 0.1, false)
		session.weapon_enabled = false
		var expected_follow_distance: float = session.prism_laser_projectile_speed * (1.15 if level >= 4 else 1.0) * 0.1
		if absf(float(session._prism_beams[0]["to"].x) - (origin.x + 20.0 + expected_follow_distance)) > 0.1:
			session.queue_free()
			return false
		session.simulation.kill_all()
		if not await _wait_for_no_entities(session):
			session.queue_free()
			return false
	session.queue_free()
	return true

func _wait_for_projectile_count(session: Node2D, expected_count: int, projectile_type: String = "inferno_sprayer") -> Array[Dictionary]:
	return await _wait_for_projectile_count_of_type(session, expected_count, projectile_type)

func _wait_for_projectile_count_of_type(session: Node2D, expected_count: int, projectile_type: String) -> Array[Dictionary]:
	var deadline := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var projectiles: Array[Dictionary] = []
		for entity in session.simulation.snapshot()["entities"]:
			if entity["components"].get("EnemyType", "") == projectile_type:
				projectiles.append(entity)
		if projectiles.size() >= expected_count:
			return projectiles
	return []

func _wait_for_projectile_prefix(session: Node2D, prefix: String) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		for entity in session.simulation.snapshot()["entities"]:
			if str(entity["components"].get("EnemyType", "")).begins_with(prefix):
				return entity
	return {}

func _projectile_position(entity: Dictionary) -> Vector2:
	var transform: Dictionary = entity["components"]["Transform2D"]
	return Vector2(float(transform["x"]), float(transform["y"]))

func _toxic_cloud_prioritizes_durable_targets() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	var origin: Vector2 = session.player.global_position
	session._entities = [
		{"id": {"index": 31, "generation": 1}, "components": {
			"Health": {"current": 20.0}, "Transform2D": {"x": origin.x + 60.0, "y": origin.y},
		}},
		{"id": {"index": 32, "generation": 1}, "components": {
			"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 100.0, "y": origin.y},
		}},
		{"id": {"index": 33, "generation": 1}, "components": {
			"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 130.0, "y": origin.y},
		}},
		{"id": {"index": 34, "generation": 1}, "components": {
			"Health": {"current": 1000.0}, "Transform2D": {"x": origin.x + 20.0, "y": origin.y},
		}},
		{"id": {"index": 35, "generation": 1}, "components": {
			"Health": {"current": 10000.0},
			"Transform2D": {"x": origin.x + session.toxic_range + 1.0, "y": origin.y},
		}},
	]
	session._entities[3]["components"]["Health"]["current"] = 0.0
	var selected: Dictionary = session._highest_health_enemy(session.toxic_range)
	session.queue_free()
	return selected.get("id", Vector2i(-1, -1)) == Vector2i(32, 1)

func _minigun_targets_nearest_and_holds_target() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	root.add_child(session)
	await process_frame
	if not session.loadout.apply_offer("weapon:minigun"):
		session.queue_free()
		return false
	session.weapon_enabled = true
	var first_id := Vector2i(11, 1)
	var second_id := Vector2i(12, 1)
	session._entities = [
		{"id": {"index": first_id.x, "generation": first_id.y}, "components": {
		"Health": {"current": 100.0}, "ThreatLevel": 1.0, "Transform2D": {"x": 80.0, "y": 0.0},
		}},
		{"id": {"index": second_id.x, "generation": second_id.y}, "components": {
		"Health": {"current": 100.0}, "ThreatLevel": 4.0, "Transform2D": {"x": 140.0, "y": 0.0},
		}},
	]
	session._fire_minigun(10.0, false)
	var acquired_nearest: bool = session._minigun_target_id == first_id
	session._entities.reverse()
	session._entities[0]["components"]["Transform2D"]["x"] = 20.0
	session._entities[1]["components"]["Transform2D"]["x"] = 160.0
	session._fire_minigun(11.0, false)
	var retained_target: bool = session._minigun_target_id == first_id
	session._entities[1]["components"]["Health"]["current"] = 0.0
	session._fire_minigun(12.0, false)
	var retargeted_after_death: bool = session._minigun_target_id == second_id and is_equal_approx(session._redline_fire_time, 12.0)
	session._entities[1]["components"]["Health"]["current"] = 100.0
	session._entities[0]["components"]["Transform2D"]["x"] = 700.0
	session._entities[1]["components"]["Transform2D"]["x"] = 30.0
	session._fire_minigun(13.0, false)
	var retargeted_after_leaving_range: bool = session._minigun_target_id == first_id and is_equal_approx(session._redline_fire_time, 13.0)
	session.queue_free()
	return acquired_nearest and retained_target and retargeted_after_death and retargeted_after_leaving_range

func _prism_laser_tracks_and_splits() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	session.xp_collection_radius = 0.0
	session.prism_laser_cooldown = 1000.0
	root.add_child(session)
	await process_frame
	for _level in range(5):
		if not session.loadout.apply_offer("weapon:prism_laser") or not session.loadout.apply_offer("relic:prism_crystal"):
			session.queue_free()
			return false
	if not session.loadout.apply_offer("evolution:prism_laser"):
		session.queue_free()
		return false
	session.simulation.set_speed(4.0)
	await _wait_for_simulation_speed(session, 4.0)
	session.simulation.spawn("test_target", 1, Vector2(180.0, 0.0), 100.0, Vector2.ZERO)
	session.simulation.spawn("test_target", 1, Vector2(180.0, 100.0), 100.0, Vector2.ZERO)
	if (await _wait_for_targets(session, 2)).size() != 2:
		session.queue_free()
		return false
	var before := int(session.simulation.snapshot()["metrics"]["collision_count"])
	var active_time := float(session.simulation.snapshot()["simulation_time"])
	session.weapon_enabled = true
	session._entities = session.simulation.snapshot()["entities"]
	session._fire_prism_laser(active_time, false)
	var deadline := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if int(session.simulation.snapshot()["metrics"]["collision_count"]) >= before + 2:
			session.queue_free()
			return true
	session.queue_free()
	return false

func _sawblades_prioritizes_ricochet_clusters() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	var origin: Vector2 = session.player.global_position
	session._entities = [
		{"id": {"index": 31, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 20.0, "y": origin.y}}},
		{"id": {"index": 32, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 90.0, "y": origin.y}}},
		{"id": {"index": 33, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 110.0, "y": origin.y + 10.0}}},
		{"id": {"index": 34, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 130.0, "y": origin.y}}},
	]
	var clustered: Dictionary = session._sawblades_cluster_target()
	var cluster_selected: bool = clustered.get("id", Vector2i(-1, -1)) == Vector2i(32, 1)
	session._entities = [session._entities[0], session._entities[3]]
	var fallback: Dictionary = session._sawblades_cluster_target()
	var nearest_fallback: bool = fallback.get("id", Vector2i(-1, -1)) == Vector2i(31, 1)
	session.queue_free()
	return cluster_selected and nearest_fallback

func _void_orb_targets_farthest_live_enemy() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	var origin: Vector2 = session.player.global_position
	session._entities = [
		{"id": {"index": 51, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 80.0, "y": origin.y}}},
		{"id": {"index": 52, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 260.0, "y": origin.y}}},
		{"id": {"index": 53, "generation": 1}, "components": {"Health": {"current": 0.0}, "Transform2D": {"x": origin.x + 350.0, "y": origin.y}}},
		{"id": {"index": 54, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + session.void_orb_range + 1.0, "y": origin.y}}},
	]
	var selected: Dictionary = session._farthest_enemy(session.void_orb_range)
	session._entities.clear()
	var no_target: Dictionary = session._farthest_enemy(session.void_orb_range)
	session.queue_free()
	return selected.get("id", Vector2i(-1, -1)) == Vector2i(52, 1) and no_target.is_empty()

func _prism_laser_prioritizes_dense_groups() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	var origin: Vector2 = session.player.global_position
	session._entities = [
		{"id": {"index": 61, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 20.0, "y": origin.y}}},
		{"id": {"index": 62, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 120.0, "y": origin.y}}},
		{"id": {"index": 63, "generation": 1}, "components": {"Health": {"current": 300.0}, "Transform2D": {"x": origin.x + 145.0, "y": origin.y + 10.0}}},
		{"id": {"index": 64, "generation": 1}, "components": {"Health": {"current": 50.0}, "Transform2D": {"x": origin.x + 170.0, "y": origin.y}}},
	]
	var primary: Dictionary = session._prism_cluster_target(session.prism_laser_range)
	var excluded: Array[Vector2i] = [primary.get("id", Vector2i(-1, -1))]
	var secondary: Dictionary = session._nearest_enemy_excluding(primary.get("position", origin), session.spectrum_collapse_cluster_radius, excluded)
	session.queue_free()
	return primary.get("id", Vector2i(-1, -1)) == Vector2i(63, 1) and secondary.get("id", Vector2i(-1, -1)) == Vector2i(62, 1)

func _void_orb_pulls_and_pierces() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	session.xp_collection_radius = 0.0
	session.void_orb_cooldown = 1000.0
	session.void_orb_speed = 1000.0
	session.void_orb_range = 620.0
	session.void_orb_lifetime = 1.0
	root.add_child(session)
	await process_frame
	if not session.loadout.apply_offer("weapon:void_orb"):
		session.queue_free()
		return false
	session.simulation.set_speed(4.0)
	await _wait_for_simulation_speed(session, 4.0)
	session.simulation.spawn("test_target", 1, Vector2(150.0, 0.0), 100.0, Vector2.ZERO)
	session.simulation.spawn("test_target", 1, Vector2(170.0, 0.0), 100.0, Vector2.ZERO)
	if (await _wait_for_targets(session, 2)).size() != 2:
		session.queue_free()
		return false
	session.weapon_enabled = true
	session._entities = session.simulation.snapshot()["entities"]
	var before := int(session.simulation.snapshot()["metrics"]["collision_count"])
	session._fire_void_orb(float(session.simulation.snapshot()["simulation_time"]), false)
	var deadline := Time.get_ticks_msec() + 2500
	var field_is_shared := false
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var state: Dictionary = session.simulation.snapshot()
		for entity in state["entities"]:
			var components: Dictionary = entity["components"]
			if components.get("EnemyType", "") == "void_orb":
				var field: Dictionary = components["Projectile"]
				field_is_shared = bool(field["pierces_targets"]) and float(field["attraction_radius"]) > 0.0
		if field_is_shared and int(state["metrics"]["collision_count"]) >= before + 2:
			session.queue_free()
			return true
	session.queue_free()
	return false

func _frost_nova_chills_and_shatters() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	session.xp_collection_radius = 0.0
	session.frost_nova_radius = 150.0
	session.frost_nova_cooldown = 1000.0
	session.frost_nova_damage = 10.0
	root.add_child(session)
	await process_frame
	for _level in range(5):
		if not session.loadout.apply_offer("weapon:frost_nova") or not session.loadout.apply_offer("relic:frozen_crown"):
			session.queue_free()
			return false
	if not session.loadout.apply_offer("evolution:frost_nova"):
		session.queue_free()
		return false
	session.simulation.set_speed(4.0)
	await _wait_for_simulation_speed(session, 4.0)
	var origin: Vector2 = session.player.global_position
	session.simulation.spawn("test_target", 1, origin + Vector2(20.0, 0.0), 20.0, Vector2.ZERO)
	session.simulation.spawn("test_target", 1, origin + Vector2(30.0, 0.0), 100.0, Vector2.ZERO)
	if (await _wait_for_targets(session, 2)).size() != 2:
		session.queue_free()
		return false
	session.weapon_enabled = true
	session._entities = session.simulation.snapshot()["entities"]
	session._fire_frost_nova(float(session.simulation.snapshot()["simulation_time"]), false)
	session.weapon_enabled = false
	var deadline := Time.get_ticks_msec() + 2500
	var shattered_neighbor := false
	var finishing_projectile_fired := false
	var observed_damage_sources: Array[String] = []
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var state: Dictionary = session.simulation.snapshot()
		if not finishing_projectile_fired:
			for entity in state["entities"]:
				var components: Dictionary = entity["components"]
				if components.get("EnemyType", "") != "test_target" or not components.has("Chill"):
					continue
				var transform: Dictionary = components["Transform2D"]
				session.simulation.spawn_projectile("test_chilled_target_finisher",
						Vector2(float(transform["x"]), float(transform["y"])), Vector2.ZERO,
						100.0, 2.0, 1.0)
				finishing_projectile_fired = true
				break
		for event in state["events"]:
			if event.get("type", "") == "damage":
				observed_damage_sources.append(str(event.get("source_type", "")))
			if event.get("type", "") == "damage" and event.get("source_type", "") == "absolute_zero":
				shattered_neighbor = true
		if shattered_neighbor:
			session.queue_free()
			return true
	push_error("Frost smoke diagnostics: finisher=%s damage_sources=%s" % [finishing_projectile_fired, observed_damage_sources])
	session.queue_free()
	return false

func _thermal_shock_combines_burn_and_chill_once() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	root.add_child(session)
	await process_frame
	session.simulation.spawn("test_target", 1, Vector2(120.0, 80.0), 50.0, Vector2.ZERO)
	session.simulation.spawn("test_target", 1, Vector2(500.0, 300.0), 50.0, Vector2.ZERO)
	var targets: Array = await _wait_for_targets(session, 2)
	if targets.size() != 2:
		session.queue_free()
		return false
	var chilled_target_id: Dictionary = targets[0]["id"]
	var burning_target_id: Dictionary = targets[1]["id"]
	var chilled_position := Vector2(float(targets[0]["components"]["Transform2D"]["x"]),
		float(targets[0]["components"]["Transform2D"]["y"]))
	var burning_position := Vector2(float(targets[1]["components"]["Transform2D"]["x"]),
		float(targets[1]["components"]["Transform2D"]["y"]))
	var chilled_components: Dictionary = targets[0]["components"].duplicate(true)
	chilled_components["Chill"] = {}
	var burning_components: Dictionary = targets[1]["components"].duplicate(true)
	burning_components["DamageOverTime"] = {"status_type": "burn"}
	var entities := [
		{"id": chilled_target_id, "components": chilled_components},
		{"id": burning_target_id, "components": burning_components},
	]
	var burn_hit := {"target": chilled_target_id, "source_type": "inferno_sprayer",
		"target_was_chilled": true, "is_damage_over_time": false, "amount": 10.0, "remaining_health": 40.0,
		"position": {"x": chilled_position.x, "y": chilled_position.y}}
	var burn_sequence: int = session._try_thermal_shock(burn_hit, entities, 0.0)
	var repeated_sequence: int = session._try_thermal_shock(burn_hit, entities, 0.5)
	var lethal_burn_hit := burn_hit.duplicate(true)
	lethal_burn_hit["remaining_health"] = 0.0
	var lethal_sequence: int = session._try_thermal_shock(lethal_burn_hit, entities, 2.0)
	var frost_hit := {"target": burning_target_id, "source_type": "frost_nova",
		"target_was_chilled": false, "is_damage_over_time": false, "amount": 8.0, "remaining_health": 42.0,
		"position": {"x": burning_position.x, "y": burning_position.y}}
	var frost_sequence: int = session._try_thermal_shock(frost_hit, entities, 0.0)
	var dot_hit := burn_hit.duplicate(true)
	dot_hit["target"] = burning_target_id
	dot_hit["is_damage_over_time"] = true
	var dot_sequence: int = session._try_thermal_shock(dot_hit, entities, 2.0)
	var reaction_hit := burn_hit.duplicate(true)
	reaction_hit["source_type"] = "thermal_shock"
	reaction_hit["target"] = burning_target_id
	var reaction_sequence: int = session._try_thermal_shock(reaction_hit, entities, 2.0)
	var burn_damage := false
	var frost_damage := false
	var deadline := Time.get_ticks_msec() + 2500
	# SurvivalSession acknowledges events itself; assert durable HP state, not its transient event buffer.
	while Time.get_ticks_msec() < deadline and not (burn_damage and frost_damage):
		await process_frame
		burn_damage = burn_damage or is_equal_approx(_target_health(session, chilled_target_id), 45.0)
		frost_damage = frost_damage or is_equal_approx(_target_health(session, burning_target_id), 46.0)
	var valid := burn_sequence > 0 and repeated_sequence == 0 and lethal_sequence == 0 and frost_sequence > 0 and dot_sequence == 0 and \
		reaction_sequence == 0 and burn_damage and frost_damage
	if not valid:
		push_error("Thermal Shock fixture diagnostics: sequences=%s burn_damage=%s frost_damage=%s health=%s,%s targets=%s,%s" % [
			[burn_sequence, repeated_sequence, lethal_sequence, frost_sequence, dot_sequence, reaction_sequence],
			burn_damage, frost_damage, _target_health(session, chilled_target_id), _target_health(session, burning_target_id),
			chilled_target_id, burning_target_id,
		])
	session.queue_free()
	return valid

func _toxic_ignition_combines_poison_and_burn_once() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	root.add_child(session)
	await process_frame
	session.simulation.spawn("test_target", 1, Vector2(50.0, 60.0), 100.0, Vector2.ZERO)
	session.simulation.spawn("test_target", 1, Vector2(90.0, 60.0), 100.0, Vector2.ZERO)
	session.simulation.spawn("test_target", 1, Vector2(120.0, 60.0), 100.0, Vector2.ZERO)
	var targets: Array = await _wait_for_targets(session, 3)
	if targets.size() != 3:
		session.queue_free()
		return false
	var target_id: Dictionary = targets[0]["id"]
	var nearby_id: Dictionary = targets[1]["id"]
	var distant_id: Dictionary = targets[2]["id"]
	var transform: Dictionary = targets[0]["components"]["Transform2D"]
	var burn_hit := {"target": target_id, "source_type": "inferno_sprayer", "target_had_poison": true,
		"sequence": 91, "reaction_budget": 1, "is_damage_over_time": false,
		"amount": 20.0, "remaining_health": 40.0,
		"position": {"x": transform["x"], "y": transform["y"]}}
	var sequence: int = session._try_toxic_ignition(burn_hit, 0.0)
	var cooldown_sequence: int = session._try_toxic_ignition(burn_hit, 0.5)
	var dot_hit := burn_hit.duplicate(true)
	dot_hit["is_damage_over_time"] = true
	var dot_sequence: int = session._try_toxic_ignition(dot_hit, 2.0)
	var exhausted_chain_hit := burn_hit.duplicate(true)
	exhausted_chain_hit["reaction_chain_id"] = 91
	exhausted_chain_hit["reaction_budget"] = 0
	var exhausted_chain_sequence: int = session._try_toxic_ignition(exhausted_chain_hit, 2.0)
	var no_prior_status := burn_hit.duplicate(true)
	no_prior_status["target_had_poison"] = false
	var no_pair_sequence: int = session._try_toxic_ignition(no_prior_status, 2.0)
	var nearby_ignition := false
	var distant_ignition := false
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline and not nearby_ignition:
		await process_frame
		for event in session.simulation.snapshot()["events"]:
			if event.get("type", "") != "damage" or event.get("source_type", "") != "toxic_ignition":
				continue
			var hit_id: Dictionary = event["target"]
			if hit_id == nearby_id and is_equal_approx(float(event["amount"]), 10.0):
				nearby_ignition = true
			if hit_id == distant_id:
				distant_ignition = true
	var valid := sequence > 0 and cooldown_sequence == 0 and dot_sequence == 0 and exhausted_chain_sequence == 0 and \
		no_pair_sequence == 0 and nearby_ignition and not distant_ignition
	session.queue_free()
	return valid

func _electroplague_spreads_existing_poison_on_direct_shock() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	session.contact_damage_per_hit = 0.0
	root.add_child(session)
	await process_frame
	session.simulation.pause()
	var pause_deadline := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < pause_deadline and not bool(session.simulation.snapshot().get("paused", false)):
		await process_frame
	if not bool(session.simulation.snapshot().get("paused", false)):
		session.queue_free()
		return false
	var positions: Array[Vector2] = [Vector2(100.0, 100.0), Vector2(110.0, 100.0),
		Vector2(120.0, 100.0), Vector2(130.0, 100.0), Vector2(140.0, 100.0),
		Vector2(150.0, 100.0), Vector2(160.0, 100.0), Vector2(160.5, 100.0)]
	for position in positions:
		session.simulation.spawn("test_target", 1, position, 1000.0, Vector2.ZERO)
	var targets: Array = await _wait_for_targets(session, positions.size())
	if targets.size() != positions.size():
		session.queue_free()
		return false
	var source_id: Dictionary = targets[0]["id"]
	var already_poisoned_id: Dictionary = targets[1]["id"]
	var source_sequence: int = session.simulation.apply_damage_over_time(
		int(source_id["index"]), int(source_id["generation"]), 3.0, 1.0, 3.0, "poison")
	var existing_sequence: int = session.simulation.apply_damage_over_time(
		int(already_poisoned_id["index"]), int(already_poisoned_id["generation"]), 7.0, 0.75, 1.5, "poison")
	if source_sequence <= 0 or existing_sequence <= 0 or \
			not await _wait_for_status(session, source_id, "poison") or \
			not await _wait_for_status(session, already_poisoned_id, "poison"):
		session.queue_free()
		return false
	var existing_state: Dictionary = session.simulation.snapshot()
	var source_entity: Dictionary = {}
	for entity in existing_state["entities"]:
		if entity["id"] == source_id:
			source_entity = entity
			break
	if source_entity.is_empty():
		session.queue_free()
		return false
	var source_status: Dictionary = source_entity["components"]["DamageOverTime"]
	var source_transform: Dictionary = source_entity["components"]["Transform2D"]
	var event := {"type": "damage", "source_type": "lightning_primary:electroplague-test",
		"target": source_id, "target_had_poison": true, "is_damage_over_time": false,
		"amount": 10.0, "remaining_health": 900.0,
		"position": {"x": source_transform["x"], "y": source_transform["y"]}}
	var ineligible_event := event.duplicate(true)
	ineligible_event["source_type"] = "inferno_sprayer"
	var rejected_source: Variant = session.call("_try_electroplague", ineligible_event, existing_state["entities"])
	ineligible_event = event.duplicate(true)
	ineligible_event["is_damage_over_time"] = true
	var rejected_tick: Variant = session.call("_try_electroplague", ineligible_event, existing_state["entities"])
	ineligible_event = event.duplicate(true)
	ineligible_event["target_had_poison"] = false
	var rejected_unpoisoned: Variant = session.call("_try_electroplague", ineligible_event, existing_state["entities"])
	var propagated: Variant = session.call("_try_electroplague", event, existing_state["entities"])
	if rejected_source != 0 or rejected_tick != 0 or rejected_unpoisoned != 0 or propagated != 5:
		session.queue_free()
		return false
	for index in range(2, 7):
		if not await _wait_for_status(session, targets[index]["id"], "poison"):
			session.queue_free()
			return false
	var final_state: Dictionary = session.simulation.snapshot()
	var copied_statuses := 0
	var preserved_existing := false
	var outside_has_poison := false
	for entity in final_state["entities"]:
		var entity_id: Dictionary = entity["id"]
		var components: Dictionary = entity["components"]
		var status: Dictionary = components.get("DamageOverTime", {})
		if entity_id == already_poisoned_id:
			preserved_existing = float(status.get("damage_per_tick", 0.0)) == 7.0 and \
					float(status.get("remaining_seconds", 0.0)) <= 1.5
		elif entity_id == targets[7]["id"]:
			outside_has_poison = status.get("status_type", "") == "poison"
		elif entity_id != source_id and status.get("status_type", "") == "poison":
			copied_statuses += 1
			if not is_equal_approx(float(status.get("damage_per_tick", 0.0)), float(source_status["damage_per_tick"])) or \
					not is_equal_approx(float(status.get("interval_seconds", 0.0)), float(source_status["interval_seconds"])) or \
					float(status.get("remaining_seconds", 0.0)) > float(source_status["remaining_seconds"]):
				session.queue_free()
				return false
	var valid := copied_statuses == 5 and preserved_existing and not outside_has_poison and \
				int(final_state["metrics"]["collision_count"]) == int(existing_state["metrics"]["collision_count"])
	session.queue_free()
	return valid

func _gravity_collapse_hits_targets_once_inside_void_orb_fields() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	session.weapon_enabled = false
	session.contact_damage_per_hit = 0.0
	root.add_child(session)
	await process_frame
	session.simulation.pause()
	var pause_deadline := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < pause_deadline and not bool(session.simulation.snapshot().get("paused", false)):
		await process_frame
	if not bool(session.simulation.snapshot().get("paused", false)):
		session.queue_free()
		return false
	var positions: Array[Vector2] = [Vector2(100.0, 100.0), Vector2(120.0, 100.0),
		Vector2(160.0, 100.0), Vector2(160.5, 100.0)]
	for position in positions:
		session.simulation.spawn("test_target", 1, position, 100.0, Vector2.ZERO)
	var targets: Array = await _wait_for_targets(session, positions.size())
	if targets.size() != positions.size():
		session.queue_free()
		return false
	var primary_id: Dictionary = targets[0]["id"]
	var entities: Array = session.simulation.snapshot()["entities"]
	entities.append({"id": {"index": 9999, "generation": 1}, "components": {
		"EnemyType": "void_orb", "IsProjectile": true,
		"Transform2D": {"x": 100.0, "y": 100.0},
		"Projectile": {"attraction_radius": 60.0}}})
	var event := {"type": "damage", "source_type": "minigun", "target": primary_id,
		"is_damage_over_time": false, "amount": 20.0, "remaining_health": 80.0,
		"sequence": 1000, "reaction_budget": 1,
		"position": {"x": 100.0, "y": 100.0}}
	var triggered: int = int(session.call("_try_gravity_collapse", event, entities))
	var rejected_dot := event.duplicate(true)
	rejected_dot["is_damage_over_time"] = true
	var dot_sequence: int = int(session.call("_try_gravity_collapse", rejected_dot, entities))
	var rejected_source := event.duplicate(true)
	rejected_source["source_type"] = "void_orb"
	var gravity_source_sequence: int = int(session.call("_try_gravity_collapse", rejected_source, entities))
	var reaction_event := event.duplicate(true)
	reaction_event["source_type"] = "gravity_collapse"
	var reaction_sequence: int = int(session.call("_try_gravity_collapse", reaction_event, entities))
	var entities_without_gravity: Array = entities.duplicate()
	entities_without_gravity.pop_back()
	var no_gravity_sequence: int = int(session.call("_try_gravity_collapse", event, entities_without_gravity))
	var missing_target_event := event.duplicate(true)
	missing_target_event["target"] = {"index": 9998, "generation": 1}
	var missing_target_sequence: int = int(session.call("_try_gravity_collapse", missing_target_event, entities))
	if triggered <= 0 or dot_sequence != 0 or gravity_source_sequence != 0 or \
		reaction_sequence != 0 or no_gravity_sequence != 0 or missing_target_sequence != 0:
		session.queue_free()
		return false
	session.simulation.resume()
	var deadline := Time.get_ticks_msec() + 2500
	var valid := false
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var state: Dictionary = session.simulation.snapshot()
		var health_by_id: Dictionary = {}
		for entity in state["entities"]:
			if entity["components"].get("EnemyType", "") == "test_target":
				health_by_id[entity["id"].index] = float(entity["components"]["Health"]["current"])
		if health_by_id.get(primary_id["index"], 100.0) <= 90.0:
			valid = is_equal_approx(float(health_by_id.get(targets[0]["id"].index, 0.0)), 90.0) and \
					is_equal_approx(float(health_by_id.get(targets[1]["id"].index, 0.0)), 90.0) and \
					is_equal_approx(float(health_by_id.get(targets[2]["id"].index, 0.0)), 90.0) and \
					is_equal_approx(float(health_by_id.get(targets[3]["id"].index, 0.0)), 100.0)
			break
	session.queue_free()
	return valid

func _toxic_ignition_runs_from_real_status_hits() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	session.inferno_burn_damage_per_tick = 0.1
	session.inferno_burn_interval_seconds = 5.0
	session.inferno_burn_duration_seconds = 10.0
	session.toxic_damage_per_tick = 0.1
	session.toxic_tick_interval_seconds = 5.0
	session.toxic_status_duration_seconds = 10.0
	root.add_child(session)
	await process_frame
	var origin: Vector2 = session.player.global_position
	session.simulation.spawn("test_target", 1, origin + Vector2(80.0, 0.0), 100.0, Vector2.ZERO)
	session.simulation.spawn("test_target", 1, origin + Vector2(120.0, 0.0), 100.0, Vector2.ZERO)
	session.simulation.spawn("test_target", 1, origin + Vector2(150.0, 0.0), 100.0, Vector2.ZERO)
	var targets: Array = await _wait_for_targets(session, 3)
	if targets.size() != 3:
		session.queue_free()
		return false
	var source_id: Dictionary = targets[0]["id"]
	var neighbor_id: Dictionary = targets[1]["id"]
	var distant_id: Dictionary = targets[2]["id"]
	var source_position := origin + Vector2(80.0, 0.0)
	var poison_sequence: int = session.simulation.spawn_projectile("toxic_cloud", origin,
		Vector2.RIGHT * 1000.0, 1.0, 3.0, 1.0, session.toxic_damage_per_tick,
		session.toxic_tick_interval_seconds, session.toxic_status_duration_seconds)
	if poison_sequence <= 0 or not await _wait_for_status(session, source_id, "poison"):
		session.queue_free()
		return false
	var burn_sequence: int = session.simulation.spawn_projectile("inferno_sprayer", origin,
		Vector2.RIGHT * 1000.0, 20.0, 3.0, 1.0, session.inferno_burn_damage_per_tick,
		session.inferno_burn_interval_seconds, session.inferno_burn_duration_seconds)
	var saw_neighbor_blast := false
	var damaged_distant := false
	var preserved_both_statuses := false
	var trigger_event_sequence := 0
	var reaction_chain_id := 0
	var reaction_chain_matches_trigger := false
	var reaction_budget_exhausted := false
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var state: Dictionary = session.simulation.snapshot()
		for entity in state["entities"]:
			if entity["id"] == source_id:
				var components: Dictionary = entity["components"]
				var effects: Array = components.get("DamageOverTimeEffects", [])
				var has_burn := false
				var has_poison := false
				for effect in effects:
					has_burn = has_burn or str(effect.get("status_type", "")) == "burn"
					has_poison = has_poison or str(effect.get("status_type", "")) == "poison"
				preserved_both_statuses = has_burn and has_poison
		for event in state["events"]:
			if event.get("type", "") == "damage" and event.get("source_type", "") == "inferno_sprayer" and \
				event.get("target", {}) == source_id:
				trigger_event_sequence = int(event["sequence"])
			if event.get("type", "") != "damage" or event.get("source_type", "") != "toxic_ignition":
				continue
			var hit_id: Dictionary = event["target"]
			if hit_id == neighbor_id and is_equal_approx(float(event["amount"]), 10.0):
				saw_neighbor_blast = true
				reaction_chain_id = int(event.get("reaction_chain_id", 0))
				reaction_chain_matches_trigger = reaction_chain_id == trigger_event_sequence
				reaction_budget_exhausted = int(event.get("reaction_budget", -1)) == 0
			if hit_id == distant_id:
				damaged_distant = true
		if saw_neighbor_blast and preserved_both_statuses:
			break
	var valid := burn_sequence > 0 and saw_neighbor_blast and not damaged_distant and preserved_both_statuses and \
		reaction_chain_matches_trigger and reaction_budget_exhausted
	if not valid:
		push_error("Toxic Ignition integration diagnostics: burn=%d neighbor=%s distant=%s statuses=%s chain=%d/%d budget_exhausted=%s source=%s" % [
			burn_sequence, saw_neighbor_blast, damaged_distant, preserved_both_statuses,
			reaction_chain_id, trigger_event_sequence, reaction_budget_exhausted, source_position])
	session.queue_free()
	return valid

func _sawblades_ricochet_between_targets() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	session.xp_collection_radius = 0.0
	session.sawblades_cooldown = 1000.0
	root.add_child(session)
	await process_frame
	if not session.loadout.apply_offer("weapon:sawblades"):
		session.queue_free()
		return false
	session.simulation.set_speed(4.0)
	await _wait_for_simulation_speed(session, 4.0)
	session.simulation.spawn("test_target", 1, Vector2(150.0, 0.0), 100.0, Vector2.ZERO)
	session.simulation.spawn("test_target", 1, Vector2(150.0, 150.0), 100.0, Vector2.ZERO)
	if (await _wait_for_targets(session, 2)).size() != 2:
		session.queue_free()
		return false
	session.weapon_enabled = true
	var before_hits := int(session.simulation.snapshot()["metrics"]["collision_count"])
	var active_time := float(session.simulation.snapshot()["simulation_time"])
	session._fire_sawblades(active_time, false)
	var deadline := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if int(session.simulation.snapshot()["metrics"]["collision_count"]) >= before_hits + 2:
			session.queue_free()
			return true
	session.queue_free()
	return false

func _magnetic_coil_homing_is_limited_to_level_five() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.sawblades_cooldown = 1000.0
	session._next_sawblades_time = 1000.0
	root.add_child(session)
	await process_frame
	if not session.loadout.apply_offer("weapon:sawblades"):
		session.queue_free()
		return false
	for _level in range(4):
		if not session.loadout.apply_offer("relic:magnetic_coil"):
			session.queue_free()
			return false
	if session.loadout.relic_level("magnetic_coil") != 4 or session._magnetic_coil_homing_turn_rate() != 0.0:
		session.queue_free()
		return false
	if not session.loadout.apply_offer("relic:magnetic_coil"):
		session.queue_free()
		return false
	session._entities = [{"id": {"index": 81, "generation": 1}, "components": {
		"Health": {"current": 100.0},
		"Transform2D": {"x": session.player.global_position.x + 100.0, "y": session.player.global_position.y + 20.0},
	}}]
	session.weapon_enabled = true
	session._next_sawblades_time = 0.0
	var active_time: float = float(session.simulation.snapshot()["simulation_time"])
	session._fire_sawblades(active_time, false)
	var expected_turn_rate: float = session.magnetic_coil_level_five_homing_turn_rate
	var expected_radius: float = session.SURVIVAL_TARGETING.visible_range(session.magnetic_coil_level_five_homing_radius)
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		for entity in session.simulation.snapshot()["entities"]:
			var components: Dictionary = entity["components"]
			if str(components.get("EnemyType", "")) not in ["sawblades", "razorstorm"]:
				continue
			var projectile: Dictionary = components.get("Projectile", {})
			var valid := is_equal_approx(float(projectile.get("homing_turn_rate", 0.0)), expected_turn_rate) and \
				is_equal_approx(float(projectile.get("homing_radius", 0.0)), expected_radius)
			session.queue_free()
			return valid
	session.queue_free()
	return false

func _meteor_staff_prioritizes_densest_group() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	var origin: Vector2 = session.player.global_position
	session._entities = [
		{"id": {"index": 71, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 20.0, "y": origin.y}}},
		{"id": {"index": 72, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 90.0, "y": origin.y}}},
		{"id": {"index": 73, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 110.0, "y": origin.y}}},
		{"id": {"index": 74, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 130.0, "y": origin.y}}},
		{"id": {"index": 75, "generation": 1}, "components": {"Health": {"current": 0.0}, "Transform2D": {"x": origin.x + 110.0, "y": origin.y + 30.0}}},
	]
	var target: Dictionary = session._meteor_cluster_target()
	session._entities.clear()
	var no_target: Dictionary = session._meteor_cluster_target()
	session.queue_free()
	return target.get("id", Vector2i(-1, -1)) == Vector2i(73, 1) and \
		Vector2(target.get("position", Vector2.ZERO)).is_equal_approx(origin + Vector2(110.0, 0.0)) and no_target.is_empty()

func _meteor_staff_targets_groups_and_starfall_fragments() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	session.xp_collection_radius = 0.0
	session.meteor_staff_cooldown = 1000.0
	root.add_child(session)
	await process_frame
	if not session.loadout.apply_offer("weapon:meteor_staff"):
		session.queue_free()
		return false
	session.simulation.set_speed(4.0)
	await _wait_for_simulation_speed(session, 4.0)
	for point in [Vector2(200.0, 0.0), Vector2(220.0, 30.0), Vector2(350.0, 0.0)]:
		session.simulation.spawn("test_target", 1, point, 100.0, Vector2.ZERO)
	var targets := await _wait_for_targets(session, 3)
	if targets.size() != 3:
		session.queue_free()
		return false
	session._entities = targets
	var meteor_id := _find_target_id_at(session, Vector2(200.0, 0.0))
	var group_id := _find_target_id_at(session, Vector2(220.0, 30.0))
	var distant_id := _find_target_id_at(session, Vector2(350.0, 0.0))
	session.weapon_enabled = true
	var active_time := float(session.simulation.snapshot()["simulation_time"])
	session._fire_meteor_staff(active_time, false)
	if not await _wait_for_target_health_below(session, meteor_id, 99.0) or not await _wait_for_target_health_below(session, group_id, 99.0):
		session.queue_free()
		return false
	if _target_health(session, distant_id) < 99.0:
		session.queue_free()
		return false
	session.simulation.kill_all()
	if not await _wait_for_no_entities(session):
		session.queue_free()
		return false
	for _level in range(4):
		if not session.loadout.apply_offer("weapon:meteor_staff"):
			session.queue_free()
			return false
	for _level in range(5):
		if not session.loadout.apply_offer("relic:celestial_eye"):
			session.queue_free()
			return false
	if not _collect_evolution(session, "meteor_staff", "celestial_eye"):
		session.queue_free()
		return false
	for point in [Vector2(200.0, 0.0), Vector2(330.0, 0.0), Vector2(200.0, 145.0)]:
		session.simulation.spawn("test_target", 1, point, 100.0, Vector2.ZERO)
	targets = await _wait_for_targets(session, 3)
	if targets.size() != 3:
		session.queue_free()
		return false
	session._entities = targets
	var active_projectile_time := float(session.simulation.snapshot()["simulation_time"])
	session._next_meteor_time = active_projectile_time
	session._fire_meteor_staff(active_projectile_time, false)
	var deadline := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if _target_count_below_health(session, 99.0) >= 3:
			session.queue_free()
			return true
	session.queue_free()
	return false

func _target_health(session: Node2D, target_id: Dictionary) -> float:
	for entity in session.simulation.snapshot()["entities"]:
		if entity["id"] == target_id:
			return float(entity["components"]["Health"]["current"])
	return 0.0

func _wait_for_target_health_below(session: Node2D, target_id: Dictionary, health: float) -> bool:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if _target_health(session, target_id) < health:
			return true
	return false

func _toxic_cloud_poison_and_pandemic() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	session.xp_collection_radius = 0.0
	session.lightning_cooldown = 0.0
	session.toxic_cooldown = 1000.0
	root.add_child(session)
	await process_frame
	if not session.loadout.apply_offer("weapon:toxic_cloud"):
		session.queue_free()
		return false
	session.weapon_enabled = true
	session.simulation.spawn("test_target", 1, Vector2(180.0, 0.0), 100.0, Vector2.ZERO)
	session.simulation.spawn("test_target", 1, Vector2(215.0, 0.0), 100.0, Vector2.ZERO)
	session.simulation.spawn("test_target", 1, Vector2(320.0, 0.0), 100.0, Vector2.ZERO)
	if (await _wait_for_targets(session, 3)).size() != 3:
		session.queue_free()
		return false
	var active_time := float(session.simulation.snapshot()["simulation_time"])
	session._fire_toxic_cloud(active_time, false)
	var close_poisoned := await _wait_for_toxic_targets(session, 2)
	var far_unpoisoned := not _target_has_poison(session, Vector2(320.0, 0.0))
	var field_center := Vector2.ZERO
	var field_radius := 0.0
	for entity in session.simulation.snapshot()["entities"]:
		var components: Dictionary = entity["components"]
		var projectile: Dictionary = components.get("Projectile", {})
		if projectile.get("persistent_area", false):
			var transform: Dictionary = components["Transform2D"]
			field_center = Vector2(float(transform["x"]), float(transform["y"]))
			field_radius = float(projectile.get("area_radius", 0.0))
			break
	if not close_poisoned or not far_unpoisoned or field_radius <= 0.0:
		session.queue_free()
		return false
	var late_target_position := field_center + Vector2(field_radius * 0.6, 0.0)
	session.simulation.spawn("test_target", 1, late_target_position, 100.0, Vector2.ZERO)
	var late_target_id := _find_target_id_at(session, late_target_position)
	if late_target_id.is_empty() or not await _wait_for_toxic_id(session, late_target_id):
		session.queue_free()
		return false
	session.simulation.kill_all()
	if not await _wait_for_no_entities(session):
		session.queue_free()
		return false
	for _level in range(4):
		if not session.loadout.apply_offer("weapon:toxic_cloud"):
			session.queue_free()
			return false
	for _level in range(5):
		if not session.loadout.apply_offer("relic:plague_mask"):
			session.queue_free()
			return false
	if not _collect_evolution(session, "toxic_cloud", "plague_mask"):
		session.queue_free()
		return false
	session.simulation.spawn("test_target", 1, Vector2(180.0, 0.0), 0.5, Vector2.ZERO)
	session.simulation.spawn("test_target", 1, Vector2(220.0, 0.0), 100.0, Vector2.ZERO)
	session.simulation.spawn("test_target", 1, Vector2(300.0, 0.0), 100.0, Vector2.ZERO)
	if (await _wait_for_targets(session, 3)).size() != 3:
		session.queue_free()
		return false
	var spread_target_id := _find_target_id_at(session, Vector2(300.0, 0.0))
	if spread_target_id.is_empty():
		session.queue_free()
		return false
	active_time = float(session.simulation.snapshot()["simulation_time"])
	session._next_toxic_time = active_time
	session._fire_toxic_cloud(active_time, false)
	var spread_applied := await _wait_for_toxic_id(session, spread_target_id)
	session.queue_free()
	return spread_applied

func _wait_for_toxic_targets(session: Node2D, count: int) -> bool:
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var poisoned := 0
		for entity in session.simulation.snapshot()["entities"]:
			var components: Dictionary = entity["components"]
			if components.get("EnemyType", "") == "test_target" and \
					str(components.get("DamageOverTime", {}).get("status_type", "")) == "poison":
				poisoned += 1
		if poisoned >= count:
			return true
	return false

func _find_target_id_at(session: Node2D, point: Vector2) -> Dictionary:
	for entity in session.simulation.snapshot()["entities"]:
		var components: Dictionary = entity["components"]
		if components.get("EnemyType", "") != "test_target":
			continue
		var transform: Dictionary = components["Transform2D"]
		if Vector2(float(transform["x"]), float(transform["y"])).distance_to(point) < 20.0:
			return entity["id"]
	return {}

func _wait_for_toxic_id(session: Node2D, target_id: Dictionary) -> bool:
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		for entity in session.simulation.snapshot()["entities"]:
			if entity["id"] == target_id and entity["components"].has("DamageOverTime"):
				return true
	return false

func _target_has_poison(session: Node2D, point: Vector2) -> bool:
	for entity in session.simulation.snapshot()["entities"]:
		var components: Dictionary = entity["components"]
		if components.get("EnemyType", "") != "test_target" or not components.has("DamageOverTime"):
			continue
		var transform: Dictionary = components["Transform2D"]
		if Vector2(float(transform["x"]), float(transform["y"])).distance_to(point) < 20.0:
			return true
	return false

func _minigun_hits_target() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	session.xp_collection_radius = 0.0
	session.minigun_cooldown = 0.2
	root.add_child(session)
	await process_frame
	if not session.loadout.apply_offer("weapon:minigun") or not session.loadout.apply_offer("relic:overdrive_engine"):
		session.queue_free()
		return false
	session.weapon_enabled = true
	session.simulation.spawn("test_target", 1, Vector2(180.0, 0.0), 100.0, Vector2.ZERO)
	var deadline := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var state: Dictionary = session.simulation.snapshot()
		if state["entities"].size() > 0:
			session._entities = state["entities"]
			break
	if session._entities.is_empty():
		session.queue_free()
		return false
	var active_time := float(session.simulation.snapshot()["simulation_time"])
	session._fire_minigun(active_time, false)
	var base_interval: float = session._next_minigun_time - active_time
	var first_hit_deadline := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < first_hit_deadline:
		await process_frame
		if int(session.simulation.snapshot()["metrics"]["collision_count"]) > 0:
			break
	if int(session.simulation.snapshot()["metrics"]["collision_count"]) == 0:
		session.queue_free()
		return false
	for _level in range(4):
		if not session.loadout.apply_offer("weapon:minigun"):
			session.queue_free()
			return false
	if not session.loadout.apply_offer("relic:overdrive_engine"):
		session.queue_free()
		return false
	if not _collect_evolution(session, "minigun", "overdrive_engine"):
		session.queue_free()
		return false
	session._next_minigun_time = active_time + 0.01
	session._fire_minigun(active_time + 0.01, false)
	var redline_interval: float = session._next_minigun_time - (active_time + 0.01)
	await process_frame
	var redline_projectile_seen := false
	for entity in session.simulation.snapshot()["entities"]:
		if str(entity["components"].get("EnemyType", "")) == "redline":
			redline_projectile_seen = true
			break
	var collision_baseline := int(session.simulation.snapshot()["metrics"]["collision_count"])
	var deadline_for_hit := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline_for_hit:
		await process_frame
		if int(session.simulation.snapshot()["metrics"]["collision_count"]) > collision_baseline:
			session.queue_free()
			return redline_projectile_seen and redline_interval < base_interval
	session.queue_free()
	return false

func _infinite_circuit_branches() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	session.xp_collection_radius = 0.0
	session.lightning_cooldown = 1000.0
	root.add_child(session)
	await process_frame
	if not session.loadout.apply_offer("relic:storm_core"):
		session.queue_free()
		return false
	for _level in range(3):
		if not session.loadout.apply_offer("weapon:lightning_conductor"):
			session.queue_free()
			return false
	session.weapon_enabled = false
	session.simulation.set_speed(4.0)
	if not await _wait_for_simulation_speed(session, 4.0):
		session.queue_free()
		return false
	var points := [Vector2(40.0, -10.0), Vector2(40.0, 10.0), Vector2(60.0, -10.0), Vector2(60.0, 10.0), Vector2(80.0, -10.0), Vector2(80.0, 10.0)]
	for point in points:
		session.simulation.spawn("test_target", 1, point, 100.0, Vector2.ZERO)
	var targets := await _wait_for_targets(session, 6)
	if targets.size() != 6:
		session.queue_free()
		return false
	var baseline := int(session.simulation.snapshot()["metrics"]["collision_count"])
	# The proposed level 3 adds one bounce; level 4 keeps the three-target chain.
	session.weapon_enabled = true
	session._next_weapon_time = session.player_active_time
	var normal_cleared := await _wait_for_projectiles_to_clear(session, baseline + 3)
	if not normal_cleared:
		session.queue_free()
		return false
	var normal_hits := _target_count_below_health(session, 100.0)
	if normal_hits != 3:
		session.queue_free()
		return false
	# Evolve the weapon and keep the same two-root target layout.
	session.simulation.kill_all()
	if not await _wait_for_no_entities(session):
		session.queue_free()
		return false
	if not session.loadout.apply_offer("weapon:lightning_conductor") or \
		not _collect_evolution(session, "lightning_conductor", "storm_core"):
		session.queue_free()
		return false
	session.weapon_enabled = false
	for point in points:
		session.simulation.spawn("test_target", 1, point, 100.0, Vector2.ZERO)
	targets = await _wait_for_targets(session, 6)
	if targets.size() != 6:
		session.queue_free()
		return false
	baseline = int(session.simulation.snapshot()["metrics"]["collision_count"])
	session.weapon_enabled = true
	session._next_weapon_time = session.player_active_time
	var branched := await _wait_for_projectiles_to_clear(session, baseline + 3)
	var final_state: Dictionary = session.simulation.snapshot()
	var branch_hits := int(final_state["metrics"]["collision_count"]) - baseline
	session.queue_free()
	return branched and branch_hits > 2

func _wait_for_targets(session: Node2D, count: int) -> Array:
	var deadline := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var targets: Array = []
		for entity in session.simulation.snapshot()["entities"]:
			if entity["components"].get("EnemyType", "") == "test_target":
				targets.append(entity)
		if targets.size() == count:
			return targets
	return []

func _wildfire_explodes_and_spreads() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	session.xp_collection_radius = 0.0
	session.inferno_cooldown = 1000.0
	root.add_child(session)
	await process_frame
	if not session.loadout.apply_offer("relic:infernal_heart"):
		session.queue_free()
		return false
	for _level in range(5):
		if not session.loadout.apply_offer("weapon:inferno_sprayer"):
			session.queue_free()
			return false
	if not _collect_evolution(session, "inferno_sprayer", "infernal_heart"):
		session.queue_free()
		return false
	session.weapon_enabled = true
	session.simulation.set_speed(4.0)
	await _wait_for_simulation_speed(session, 4.0)
	for point in [Vector2(160.0, 0.0), Vector2(160.0, 25.0), Vector2(160.0, 100.0)]:
		session.simulation.spawn("test_target", 1, point, 100.0, Vector2.ZERO)
	var targets := await _wait_for_targets(session, 3)
	if targets.size() != 3:
		session.queue_free()
		return false
	var deadline := Time.get_ticks_msec() + 2000
	var affected := false
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var snapshot: Dictionary = session.simulation.snapshot()
		var hit_targets := 0
		var burned_targets := 0
		var untouched_far_target := false
		for entity in snapshot["entities"]:
			if entity["components"].get("EnemyType", "") != "test_target":
				continue
			var components: Dictionary = entity["components"]
			var transform: Dictionary = components["Transform2D"]
			if float(transform["y"]) > 50.0:
				untouched_far_target = is_equal_approx(float(components["Health"]["current"]), 100.0)
			elif float(components["Health"]["current"]) < 100.0:
				hit_targets += 1
				if components.has("DamageOverTime"):
					burned_targets += 1
		if hit_targets >= 2 and burned_targets >= 2 and untouched_far_target:
			affected = true
			break
	session.queue_free()
	return affected

func _wait_for_projectiles_to_clear(session: Node2D, collisions: int) -> bool:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var metrics: Dictionary = session.simulation.snapshot()["metrics"]
		if int(metrics["collision_count"]) >= collisions and int(metrics["projectile_count"]) == 0:
			return true
	return false

func _wait_for_simulation_speed(session: Node2D, expected_speed: float) -> bool:
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		var state: Dictionary = session.simulation.snapshot()
		if not state["paused"] and is_equal_approx(float(state["speed_multiplier"]), expected_speed):
			return true
		await process_frame
	return false

func _target_count_below_health(session: Node2D, health: float) -> int:
	var count := 0
	for entity in session.simulation.snapshot()["entities"]:
		if entity["components"].get("EnemyType", "") == "test_target" and float(entity["components"]["Health"]["current"]) < health:
			count += 1
	return count

func _bloodstorm_requires_level_five_and_bleeds() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.contact_damage_per_hit = 0.0
	session.xp_collection_radius = 0.0
	session.lightning_cooldown = 0.0
	session.daggers_cooldown = 0.5
	root.add_child(session)
	await process_frame
	if not session.loadout.apply_offer("weapon:crimson_daggers"):
		session.queue_free()
		return false
	session.weapon_enabled = true
	session.simulation.set_speed(4.0)
	await _wait_for_simulation_speed(session, 4.0)
	var normal_target := await _spawn_crimson_target(session, 0, false, 30.0)
	if normal_target.is_empty() or normal_target["components"].has("DamageOverTime"):
		session.queue_free()
		return false
	var previous_collisions := int(session.simulation.snapshot()["metrics"]["collision_count"])
	session.simulation.kill_all()
	if not await _wait_for_no_entities(session):
		session.queue_free()
		return false
	for _level in range(4):
		if not session.loadout.apply_offer("weapon:crimson_daggers"):
			session.queue_free()
			return false
	session._next_daggers_time = session.player_active_time
	var unpaired_target := await _spawn_crimson_target(session, previous_collisions, false, 30.0)
	if unpaired_target.is_empty() or unpaired_target["components"].has("DamageOverTime"):
		session.queue_free()
		return false
	if not session.loadout.apply_offer("relic:blood_chalice"):
		session.queue_free()
		return false
	if not _collect_evolution(session, "crimson_daggers", "blood_chalice"):
		session.queue_free()
		return false
	session.simulation.kill_all()
	if not await _wait_for_no_entities(session):
		session.queue_free()
		return false
	session.player_hp = 50.0
	session._next_daggers_time = session.player_active_time
	var evolved_target := await _spawn_crimson_target(session, previous_collisions + 1, true, 30.0)
	if evolved_target.is_empty():
		session.queue_free()
		return false
	await process_frame
	var target_id: Dictionary = evolved_target["id"]
	var health_before_bleed := float(evolved_target["components"]["Health"]["current"])
	var bleed_applied := await _wait_for_bleed_tick(session, target_id, health_before_bleed)
	var lifesteal_applied: bool = session.player_hp > 50.0
	session.queue_free()
	return bleed_applied and lifesteal_applied

func _spawn_crimson_target(session: Node2D, collision_baseline: int = 0, expect_bleed: bool = false, distance: float = 180.0) -> Dictionary:
	session.simulation.spawn("test_target", 1, Vector2(distance, 0.0), 100.0, Vector2.ZERO)
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var state: Dictionary = session.simulation.snapshot()
		if int(state["metrics"]["collision_count"]) <= collision_baseline:
			continue
		for entity in state["entities"]:
			if entity["components"].get("EnemyType", "") != "test_target":
				continue
			var status: Dictionary = entity["components"].get("DamageOverTime", {})
			if not expect_bleed and status.is_empty():
				return entity
			if expect_bleed and str(status.get("status_type", "")) == "bleed":
				return entity
	return {}

func _wait_for_no_entities(session: Node2D) -> bool:
	var deadline := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if session.simulation.snapshot()["entities"].is_empty():
			return true
	return false

func _wait_for_bleed_tick(session: Node2D, target_id: Dictionary, health_before: float) -> bool:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		for entity in session.simulation.snapshot()["entities"]:
			var id: Dictionary = entity["id"]
			if int(id["index"]) != int(target_id["index"]) or int(id["generation"]) != int(target_id["generation"]):
				continue
			var current_health := float(entity["components"]["Health"]["current"])
			if current_health <= health_before - session.bloodstorm_bleed_damage_per_tick * 0.9:
				return true
	return false

func _weapon_kills_target(weapon_id: String, relic_id: String, target_hp: float, target_distance: float = 180.0) -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	if not session.has_method("open_chest_family"):
		return false
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	root.add_child(session)
	await process_frame
	if not session.loadout.apply_offer("weapon:" + weapon_id):
		session.queue_free()
		return false
	if not session.loadout.apply_offer("relic:" + relic_id):
		session.queue_free()
		return false
	session.weapon_enabled = false
	session.lightning_cooldown = 1000.0
	session.ordinary_chest_drop_chance = 0.0
	session.xp_collection_radius = 0.0
	session.simulation.set_speed(4.0)
	await _wait_for_simulation_speed(session, 4.0)
	session.simulation.spawn("test_target", 1,
			session.player.global_position + Vector2(target_distance, 0.0), target_hp, Vector2.ZERO)
	var spawned := false
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var state: Dictionary = session.simulation.snapshot()
		for entity in state["entities"]:
			if entity["components"].get("EnemyType", "") == "test_target":
				spawned = true
				break
		if spawned:
			break
	if not spawned:
		session.queue_free()
		return false
	var baseline := int(session.simulation.snapshot()["metrics"]["collision_count"])
	session.weapon_enabled = true
	match weapon_id:
		"lightning_conductor": session._next_weapon_time = session.player_active_time
		"inferno_sprayer": session._next_inferno_time = session.player_active_time
		"crimson_daggers": session._next_daggers_time = session.player_active_time
	var required_hits := 2 if weapon_id == "crimson_daggers" else 1
	deadline = Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var state: Dictionary = session.simulation.snapshot()
		if int(state["metrics"]["collision_count"]) >= baseline + required_hits and not _contains_enemy(state, "test_target"):
			session.queue_free()
			return true
	session.queue_free()
	return false

func _collect_evolution(session: Node, weapon_id: String, relic_id: String) -> bool:
	for _level in range(5 - session.loadout.relic_level(relic_id)):
		if not session.loadout.apply_offer("relic:" + relic_id):
			return false
	return session.loadout.is_evolution_ready(weapon_id) and session.loadout.apply_offer("evolution:" + weapon_id)

func _contains_enemy(state: Dictionary, enemy_type: String) -> bool:
	for entity in state["entities"]:
		if entity["components"].get("EnemyType", "") == enemy_type:
			return true
	return false

func _wait_for_status(session: Node, target_id: Dictionary, status_type: String) -> bool:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		for entity in session.simulation.snapshot()["entities"]:
			if entity["id"] != target_id:
				continue
			var components: Dictionary = entity["components"]
			var effects: Array = components.get("DamageOverTimeEffects", [components.get("DamageOverTime", {})])
			for effect in effects:
				if str(effect.get("status_type", "")) == status_type:
					return true
	return false

func _blood_chalice_boosts_kill_heal() -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	session.skip_starting_weapon_choice = true
	session.ordinary_chest_drop_chance = 0.0
	session.xp_collection_radius = 0.0
	session.contact_damage_per_hit = 0.0
	root.add_child(session)
	await process_frame
	session.player_hp = 50.0
	if not session.loadout.apply_offer("relic:blood_chalice"):
		session.queue_free()
		return false
	session.simulation.set_speed(4.0)
	await _wait_for_simulation_speed(session, 4.0)
	session.simulation.spawn_enemy("chaser", 1, Vector2(20.0, 0.0), Vector2.ZERO)
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if not session.simulation.snapshot()["entities"].is_empty():
			break
	session.simulation.spawn_projectile("test", Vector2.ZERO, Vector2(1000.0, 0.0), 30.0, 3.0, 1.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if session.player_hp > 55.2:
			session.queue_free()
			return true
	session.queue_free()
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
