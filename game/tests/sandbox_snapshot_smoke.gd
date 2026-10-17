extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	const slot_path := "user://saves/slot_0.json"
	const sentinel := "{\"schema_version\":1,\"fixture\":\"sandbox-snapshot-must-preserve-this-slot\"}"
	var save_directory := ProjectSettings.globalize_path("user://saves")
	if DirAccess.make_dir_recursive_absolute(save_directory) != OK:
		_fail("Could not prepare an isolated save sentinel for snapshot isolation")
		return
	var sentinel_file := FileAccess.open(slot_path, FileAccess.WRITE)
	if sentinel_file == null:
		_fail("Could not write an isolated save sentinel for snapshot isolation")
		return
	sentinel_file.store_string(sentinel)
	sentinel_file.close()
	var simulation = ClassDB.instantiate("CombatSimulation")
	if simulation == null or not simulation.has_method("capture_state") or \
			not simulation.has_method("restore_state"):
		_fail("CombatSimulation should expose state capture and restoration to Sandbox Lab")
		return
	var sequence: int = simulation.spawn_enemy("chaser", 1, Vector2(40, 25), Vector2.ZERO)
	if sequence <= 0 or not await _wait_for_sequence(simulation, sequence):
		_fail("The snapshot fixture should create a real native enemy")
		return
	simulation.pause()
	if not await _wait_until(func() -> bool: return bool(simulation.snapshot().get("paused", false))):
		_fail("The snapshot fixture should pause before capture")
		return
	var captured: Dictionary = simulation.capture_state()
	if captured.get("format_version") != 17 or captured.get("native_state") == null or \
			not captured["native_state"].is_valid():
		_fail("A native snapshot should expose its supported format and captured state")
		return
	sequence = simulation.kill_all()
	if sequence <= 0 or not await _wait_for_sequence(simulation, sequence) or \
			int(simulation.snapshot()["metrics"]["entity_count"]) != 0:
		_fail("The test should change the live simulation after capture")
		return
	if not simulation.restore_state(captured) or not await _wait_until(func() -> bool:
		return int(simulation.snapshot()["metrics"]["entity_count"]) == 1
	):
		_fail("Restoring a captured snapshot should recover the enemy and paused worker state")
		return
	var restored: Dictionary = simulation.snapshot()
	if not bool(restored["paused"]) or restored["entities"].size() != 1 or \
			str(restored["entities"][0]["components"]["EnemyType"]) != "chaser":
		_fail("Restoration should preserve the captured simulation state")
		return
	var incompatible: Dictionary = captured.duplicate()
	incompatible["format_version"] = 16
	if simulation.restore_state(incompatible):
		_fail("Restoration should reject an incompatible snapshot version")
		return
	var after_rejection: Dictionary = simulation.snapshot()
	if int(after_rejection["metrics"]["entity_count"]) != 1 or \
			float(after_rejection["simulation_time"]) != float(restored["simulation_time"]):
		_fail("Rejecting an incompatible snapshot must leave the live simulation unchanged")
		return
	var queued_simulation = ClassDB.instantiate("CombatSimulation")
	var first_queued_spawn: int = queued_simulation.spawn_enemy("chaser", 1, Vector2(10, 10), Vector2.ZERO)
	var second_queued_spawn: int = queued_simulation.spawn_enemy("sprinter", 1, Vector2(20, 20), Vector2.ZERO)
	var queued_pause: int = queued_simulation.pause()
	var queued_capture: Dictionary = queued_simulation.capture_state()
	var queued_state: Dictionary = queued_simulation.snapshot()
	if first_queued_spawn <= 0 or second_queued_spawn <= first_queued_spawn or queued_pause <= second_queued_spawn or \
			queued_capture.is_empty() or queued_state["entities"].size() != 2 or not queued_state["paused"]:
		_fail("The GDExtension capture barrier should include accepted queued spawns and pause commands")
		return
	if not queued_simulation.restore_state(queued_capture) or \
			queued_simulation.snapshot()["entities"].size() != 2 or \
			not queued_simulation.snapshot()["paused"]:
		_fail("A GDExtension snapshot should restore the queued command results and paused worker")
		return
	var resumed_sequence: int = queued_simulation.spawn_enemy("tank", 1, Vector2(30, 30), Vector2.ZERO)
	if resumed_sequence <= queued_pause or not await _wait_for_sequence(queued_simulation, resumed_sequence) or \
			queued_simulation.snapshot()["entities"].size() != 3:
		_fail("The restored GDExtension worker should continue command numbering after queued work")
		return
	queued_simulation = null
	var lab: Control = load("res://scenes/sandbox_lab.tscn").instantiate()
	root.add_child(lab)
	var lab_context: Node = lab.context
	if lab_context == null or not lab_context.has_method("capture_snapshot") or \
			not lab_context.has_method("restore_snapshot"):
		_fail("Sandbox Lab should expose complete isolated session capture and restore")
		return
	var deadline := Time.get_ticks_msec() + 3000
	while lab_context.simulation == null and Time.get_ticks_msec() < deadline:
		await process_frame
	if lab_context.simulation == null or lab_context.progression_service != null or \
			lab_context.normal_save_service != null:
		_fail("Snapshot fixture should use an initialized isolated Lab")
		return
	if not bool(lab_context.simulation.snapshot().get("paused", false)):
		lab._toggle_pause()
		if not await _wait_until(func() -> bool:
			return bool(lab_context.simulation.snapshot().get("paused", false))
		):
			_fail("Sandbox snapshot fixture should pause before capture")
			return
	var lab_sequence: int = lab_context.simulation.spawn_enemy("tank", 1, Vector2(120, 90), Vector2.ZERO)
	if lab_sequence <= 0 or not await _wait_for_sequence(lab_context.simulation, lab_sequence):
		_fail("Sandbox snapshot should begin with a real Lab enemy")
		return
	var lab_session: Node2D = lab_context.session
	lab_session.player_active_time = 12.5
	lab_session.player_hp = 37.0
	lab_session._next_weapon_time = 17.0
	lab_session._sandbox_rng.state = 123456789
	lab_session.loadout._rng.state = 87654321
	lab_session._chest_director._rng.state = 123987
	lab_session.wave_director.wave = 4
	lab_session.wave_director.elapsed_in_wave = 11.25
	lab_session.player.global_position = Vector2(222.0, 144.0)
	var contact_damage_control: SpinBox = lab.get_node("Root/Body/Side/Sections/EnemyConfig/ContactDamage")
	var enemy_speed_control: SpinBox = lab.get_node("Root/Body/Side/Sections/EnemyConfig/EnemySpeedMultiplier")
	var spawn_count_control: SpinBox = lab.get_node("Root/Body/Side/Sections/EnemyConfig/SpawnCount")
	var enemy_select: OptionButton = lab.get_node("Root/Body/Side/Sections/EnemySelect")
	var sprinter_index := _enemy_type_index(enemy_select, "sprinter")
	var tank_index := _enemy_type_index(enemy_select, "tank")
	enemy_select.select(sprinter_index)
	enemy_select.item_selected.emit(sprinter_index)
	contact_damage_control.value = 3.0
	enemy_speed_control.value = 2.0
	spawn_count_control.value = 3.0
	lab_context.live_stat_overrides["damage_pct"] = 15.0
	var capture_button: Button = lab.get_node("Root/Body/Left/SnapshotControls/CaptureButton")
	var restore_button: Button = lab.get_node("Root/Body/Left/SnapshotControls/RestoreButton")
	capture_button.pressed.emit()
	if lab_context.latest_snapshot.is_empty() or restore_button.disabled:
		_fail("Capture Snapshot should expose a valid in-memory Lab checkpoint (%s)" % \
			str(lab.get_node("Root/Body/Side/Sections/Status").text))
		return
	lab_session.player_active_time = 0.0
	lab_session.player_hp = 1.0
	lab_session._next_weapon_time = 0.0
	lab_session._sandbox_rng.state = 987654321
	lab_session.loadout._rng.state = 987654321
	lab_session._chest_director._rng.state = 987654321
	lab_session.wave_director.wave = 1
	lab_session.wave_director.elapsed_in_wave = 0.0
	lab_session.player.global_position = Vector2.ZERO
	contact_damage_control.value = 9.0
	enemy_speed_control.value = 4.0
	spawn_count_control.value = 4.0
	enemy_select.select(tank_index)
	enemy_select.item_selected.emit(tank_index)
	lab_context.live_stat_overrides.clear()
	var clear_sequence: int = lab_context.simulation.kill_all()
	if clear_sequence <= 0 or not await _wait_for_sequence(lab_context.simulation, clear_sequence):
		_fail("Sandbox snapshot fixture should alter native state before restore")
		return
	restore_button.pressed.emit()
	if lab_session.player_active_time != 12.5 or lab_session.player_hp != 37.0 or \
			lab_session._next_weapon_time != 17.0 or lab_session._sandbox_rng.state != 123456789 or \
			lab_session.loadout._rng.state != 87654321 or lab_session._chest_director._rng.state != 123987 or \
			lab_session.wave_director.wave != 4 or lab_session.wave_director.elapsed_in_wave != 11.25 or \
			lab_session.player.global_position != Vector2(222.0, 144.0) or \
			lab_session.contact_damage_per_hit != 3.0 or contact_damage_control.value != 3.0 or \
			float(lab_context.active_preset["overrides"].get("contact_damage_per_hit", -1.0)) != 3.0 or \
			enemy_speed_control.value != 2.0 or \
			float(lab_context.active_preset["overrides"].get("enemy_speed", -1.0)) != 2.0 or \
			int(spawn_count_control.value) != 3 or \
			int(lab_context.active_preset["overrides"].get("spawn_count", 0)) != 3 or \
			str(enemy_select.get_item_metadata(enemy_select.selected)) != "sprinter" or \
			str(lab_context.active_preset["overrides"].get("spawn_enemy_type", "")) != "sprinter" or \
			lab_context.live_stat_overrides.get("damage_pct") != 15.0 or \
			lab_context.build.to_dictionary()["weapons"].size() != 1 or \
			int(lab_context.simulation.snapshot()["metrics"]["entity_count"]) != 1:
		_fail("Lab restore should recover build, RNG, clocks, player, simulation and UI override state: %s" % str({
			"time": lab_session.player_active_time, "hp": lab_session.player_hp,
			"weapon_time": lab_session._next_weapon_time, "rng": lab_session._sandbox_rng.state,
			"loadout_rng": lab_session.loadout._rng.state, "chest_rng": lab_session._chest_director._rng.state,
			"wave": lab_session.wave_director.wave, "wave_time": lab_session.wave_director.elapsed_in_wave,
			"position": lab_session.player.global_position,
			"overrides": lab_context.live_stat_overrides,
			"build": lab_context.build.to_dictionary(),
			"entities": lab_context.simulation.snapshot()["metrics"]["entity_count"],
			"status": lab.get_node("Root/Body/Side/Sections/Status").text,
		}))
		return
	var next_lab_sequence := int(lab_context.simulation.snapshot()["last_sequence"]) + 1
	lab._spawn_enemies()
	if not await _wait_for_sequence(lab_context.simulation, next_lab_sequence) or \
			lab_context.simulation.snapshot()["entities"].size() != 4 or \
			float(lab_context.simulation.snapshot()["entities"][1]["components"]["MoveSpeed"]) != 250.0:
		_fail("Restored enemy speed override should affect subsequent Lab spawns")
		return
	var corrupt_lab_snapshot: Dictionary = lab_context.latest_snapshot.duplicate(true)
	corrupt_lab_snapshot["format_version"] = 99
	if lab_context.restore_snapshot(corrupt_lab_snapshot) or lab_session.player_active_time != 12.5 or \
			int(lab_context.simulation.snapshot()["metrics"]["entity_count"]) != 4:
		_fail("Lab must reject incompatible snapshots before changing current state")
		return
	var oversized_build_snapshot: Dictionary = lab_context.latest_snapshot.duplicate(true)
	var oversized_build: Dictionary = oversized_build_snapshot["build"].duplicate(true)
	oversized_build["weapons"] = []
	for weapon_id in ["lightning_conductor", "inferno_sprayer", "crimson_daggers", "minigun", "toxic_cloud", "sawblades"]:
		oversized_build["weapons"].append({"id": weapon_id, "level": 1})
	oversized_build_snapshot["build"] = oversized_build
	if lab_context.restore_snapshot(oversized_build_snapshot) or lab_session.player_active_time != 12.5 or \
			int(lab_context.simulation.snapshot()["metrics"]["entity_count"]) != 4:
		_fail("Lab must reject snapshots whose build exceeds loadout slots without changing the session")
		return
	if not FileAccess.file_exists(slot_path) or FileAccess.get_file_as_string(slot_path) != sentinel:
		_fail("Snapshot capture, restore and rejection must preserve a normal save byte-for-byte")
		return
	lab_context.stop()
	lab.queue_free()
	await process_frame
	quit(0)

func _wait_for_sequence(simulation: Object, sequence: int) -> bool:
	return await _wait_until(func() -> bool:
		return int(simulation.snapshot().get("last_sequence", 0)) >= sequence
	)

func _wait_until(predicate: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if predicate.call():
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _enemy_type_index(select: OptionButton, enemy_id: String) -> int:
	for index in range(select.item_count):
		if str(select.get_item_metadata(index)) == enemy_id:
			return index
	return -1
