extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not await _nearest_weapon_targets_skip_dead_enemies():
		_fail("Automatic weapons should ignore dead enemies that remain in a simulation snapshot")
		return
	if not await _crimson_daggers_prioritize_finishable_targets():
		_fail("Crimson Daggers should prioritize the lowest-health living target in range")
		return
	if not await _inferno_prioritizes_high_threat():
		_fail("Inferno should prioritize the highest-threat enemy in range, breaking ties by distance")
		return
	if not await _toxic_cloud_prioritizes_durable_targets():
		_fail("Toxic Cloud should prioritize the highest-health living enemy in range, breaking ties by distance")
		return
	if not await _sawblades_prioritizes_ricochet_clusters():
		_fail("Sawblades should aim at the nearest target in the densest reachable ricochet cluster")
		return
	if not await _minigun_holds_target_until_invalid():
		_fail("Minigun should keep its target until it dies or leaves range, then select another target")
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
	print("Survival weapon catalog smoke passed")
	quit()

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
	var nearest: Dictionary = session._nearest_enemy(100.0)
	var excluded_ids: Array[Vector2i] = []
	var lightning_targets: Array = session._nearest_lightning_targets(origin, excluded_ids, 1, 100.0)
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
			"Transform2D": {"x": origin.x + 180.0, "y": origin.y},
		}},
		{"id": {"index": 23, "generation": 1}, "components": {
			"Health": {"current": 100.0}, "ThreatLevel": 4.0,
			"Transform2D": {"x": origin.x + 240.0, "y": origin.y},
		}},
		{"id": {"index": 24, "generation": 1}, "components": {
			"Health": {"current": 100.0}, "ThreatLevel": 10.0,
			"Transform2D": {"x": origin.x + session.inferno_range + 1.0, "y": origin.y},
		}},
	]
	var selected: Dictionary = session._highest_threat_enemy(session.inferno_range)
	session.queue_free()
	return selected.get("id", Vector2i(-1, -1)) == Vector2i(22, 1)

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
			"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 180.0, "y": origin.y},
		}},
		{"id": {"index": 33, "generation": 1}, "components": {
			"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 240.0, "y": origin.y},
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

func _minigun_holds_target_until_invalid() -> bool:
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
			"Health": {"current": 100.0}, "Transform2D": {"x": 80.0, "y": 0.0},
		}},
		{"id": {"index": second_id.x, "generation": second_id.y}, "components": {
			"Health": {"current": 100.0}, "Transform2D": {"x": 140.0, "y": 0.0},
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
		{"id": {"index": 31, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 60.0, "y": origin.y}}},
		{"id": {"index": 32, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 220.0, "y": origin.y}}},
		{"id": {"index": 33, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 250.0, "y": origin.y + 20.0}}},
		{"id": {"index": 34, "generation": 1}, "components": {"Health": {"current": 100.0}, "Transform2D": {"x": origin.x + 280.0, "y": origin.y}}},
	]
	var clustered: Dictionary = session._sawblades_cluster_target()
	var cluster_selected: bool = clustered.get("id", Vector2i(-1, -1)) == Vector2i(32, 1)
	session._entities = [session._entities[0], session._entities[3]]
	var fallback: Dictionary = session._sawblades_cluster_target()
	var nearest_fallback: bool = fallback.get("id", Vector2i(-1, -1)) == Vector2i(31, 1)
	session.queue_free()
	return cluster_selected and nearest_fallback

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
	session.void_orb_range = 400.0
	session.void_orb_lifetime = 1.0
	root.add_child(session)
	await process_frame
	if not session.loadout.apply_offer("weapon:void_orb"):
		session.queue_free()
		return false
	session.simulation.set_speed(4.0)
	await _wait_for_simulation_speed(session, 4.0)
	session.simulation.spawn("test_target", 1, Vector2(150.0, 0.0), 100.0, Vector2.ZERO)
	session.simulation.spawn("test_target", 1, Vector2(180.0, 0.0), 100.0, Vector2.ZERO)
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
	session.frost_nova_radius = 160.0
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
	session.simulation.spawn("test_target", 1, Vector2(100.0, 0.0), 20.0, Vector2.ZERO)
	session.simulation.spawn("test_target", 1, Vector2(130.0, 0.0), 100.0, Vector2.ZERO)
	if (await _wait_for_targets(session, 2)).size() != 2:
		session.queue_free()
		return false
	session.weapon_enabled = true
	session._entities = session.simulation.snapshot()["entities"]
	session._fire_frost_nova(float(session.simulation.snapshot()["simulation_time"]), false)
	var deadline := Time.get_ticks_msec() + 2500
	var shattered_neighbor := false
	var finishing_projectile_fired := false
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
			if event.get("type", "") == "damage" and event.get("source_type", "") == "absolute_zero":
				shattered_neighbor = true
		if shattered_neighbor:
			session.queue_free()
			return true
	session.queue_free()
	return false

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
			if entity["components"].get("EnemyType", "") == "test_target" and entity["components"].has("DamageOverTime"):
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
	var collision_baseline := int(session.simulation.snapshot()["metrics"]["collision_count"])
	var deadline_for_hit := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline_for_hit:
		await process_frame
		if int(session.simulation.snapshot()["metrics"]["collision_count"]) > collision_baseline:
			session.queue_free()
			return redline_interval < base_interval
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
	var points := [Vector2(160.0, -20.0), Vector2(160.0, 20.0), Vector2(200.0, -20.0), Vector2(200.0, 20.0), Vector2(240.0, -20.0), Vector2(240.0, 20.0)]
	for point in points:
		session.simulation.spawn("test_target", 1, point, 100.0, Vector2.ZERO)
	var targets := await _wait_for_targets(session, 6)
	if targets.size() != 6:
		session.queue_free()
		return false
	var baseline := int(session.simulation.snapshot()["metrics"]["collision_count"])
	# At level 4, one primary projectile can arc through at most five nearby targets.
	session.weapon_enabled = true
	session._next_weapon_time = session.player_active_time
	if not await _wait_for_projectiles_to_clear(session, baseline + 5):
		session.queue_free()
		return false
	var normal_hits := _target_count_below_health(session, 100.0)
	if normal_hits != 5:
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
	var branched := await _wait_for_projectiles_to_clear(session, baseline + 4)
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
			if entity["components"].has("DamageOverTime") == expect_bleed:
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
