extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var lab: Control = load("res://scenes/sandbox_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	if lab.context == null or lab.context.simulation == null or \
			lab.context.progression_service != null or lab.context.normal_save_service != null:
		_fail("The player Sandbox Lab should start without progression or save services")
		return
	if lab.context.session.loadout.weapon_level("lightning_conductor") != 1 or \
			lab.context.session.loadout.relic_level("storm_core") != 1:
		_fail("The default Lab preset build should be applied to the real combat loadout")
		return
	var weapon_select: OptionButton = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/WeaponRow/WeaponSelect")
	var weapon_level: SpinBox = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/WeaponRow/WeaponLevel")
	var add_weapon: Button = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/AddWeaponButton")
	var relic_select: OptionButton = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/RelicRow/RelicSelect")
	var relic_level: SpinBox = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/RelicRow/RelicLevel")
	var add_relic: Button = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/AddRelicButton")
	var stat_select: OptionButton = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/StatRow/StatSelect")
	var stat_value: SpinBox = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/StatRow/StatValue")
	var add_stat: Button = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/AddStatButton")
	var apply_build: Button = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/ApplyBuildButton")
	var equipment_slot: OptionButton = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/EquipmentRow/EquipmentSlot")
	var equipment_stat: OptionButton = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/EquipmentRow/EquipmentStat")
	var equipment_value: SpinBox = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/EquipmentRow/EquipmentValue")
	var add_equipment: Button = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/AddEquipmentButton")
	var live_damage: SpinBox = lab.get_node_or_null("Root/Body/Side/Sections/LiveOverride/DamageValue")
	var apply_live_damage: Button = lab.get_node_or_null("Root/Body/Side/Sections/LiveOverride/ApplyDamage")
	if weapon_select == null or weapon_level == null or add_weapon == null or relic_select == null or \
			relic_level == null or add_relic == null or stat_select == null or stat_value == null or \
			add_stat == null or apply_build == null or equipment_slot == null or equipment_stat == null or \
			equipment_value == null or add_equipment == null or live_damage == null or apply_live_damage == null:
		_fail("Sandbox Lab should provide visual build controls and a live damage override")
		return
	weapon_select.select(_option_index_for(weapon_select, "minigun"))
	weapon_level.value = 2
	add_weapon.pressed.emit()
	weapon_level.value = 3
	add_weapon.pressed.emit()
	relic_select.select(_option_index_for(relic_select, "magnet_heart"))
	relic_level.value = 2
	add_relic.pressed.emit()
	stat_select.select(_option_index_for(stat_select, "damage_pct"))
	stat_value.value = 12.5
	add_stat.pressed.emit()
	equipment_slot.select(_option_index_for(equipment_slot, "boots"))
	equipment_stat.select(_option_index_for(equipment_stat, "move_speed_pct"))
	equipment_value.value = 7.5
	add_equipment.pressed.emit()
	var visual_build: Dictionary = JSON.parse_string(lab.get_node("Root/Body/Side/Sections/BuildJson").text)
	if visual_build["weapons"].size() != 2 or visual_build["weapons"][1]["level"] != 3 or \
			visual_build["relics"].size() != 2 or visual_build["stats"]["damage_pct"] != 12.5 or \
			visual_build["equipment"].size() != 1 or \
			visual_build["equipment"][0]["slot"] != "boots" or \
			visual_build["equipment"][0]["stats"]["move_speed_pct"] != 7.5:
		_fail("Visual build controls should update the JSON model without duplicating an item")
		return
	await lab._apply_visual_build()
	if lab.context.session.loadout.weapon_level("minigun") != 3 or \
			lab.context.session.loadout.relic_level("magnet_heart") != 2 or \
			lab.context.session._equipment_bonus("damage_pct") != 12.5 or \
			lab.context.session._equipment_bonus("move_speed_pct") != 7.5 or \
			not bool(lab.context.simulation.snapshot()["paused"]):
		_fail("Apply Build should atomically rebuild the paused isolated combat session from visual controls")
		return
	if not is_equal_approx(lab.context.session._cached_persistent_damage_multiplier, 1.125) or \
			not is_equal_approx(lab.context.session._persistent_damage_multiplier(), 1.18125):
		_fail("Sandbox build damage must affect the same effective multiplier used by combat")
		return
	live_damage.value = 10.0
	apply_live_damage.pressed.emit()
	if not is_equal_approx(float(lab.context.session._cached_equipment_bonuses["damage_pct"]), 22.5) or \
			not is_equal_approx(lab.context.session._persistent_damage_multiplier(), 1.28625) or \
			lab.context.active_preset["initial_build"]["equipment"].size() != 1:
		_fail("Live damage override should update combat immediately without changing the active preset build")
		return
	var diagnostics: Label = lab.get_node_or_null("Root/Body/Side/Sections/Diagnostics/RngLog")
	var dps_summary: Label = lab.get_node_or_null("Root/Body/Side/Sections/Diagnostics/DpsSummary")
	var dps_sources: Label = lab.get_node_or_null("Root/Body/Side/Sections/Diagnostics/DpsSources")
	if diagnostics == null or dps_summary == null or dps_sources == null:
		_fail("Sandbox Lab should expose RNG and source DPS diagnostics")
		return
	if lab.context.session.sandbox_rng_seed != 1 or not lab.context.session.sandbox_diagnostics_enabled:
		_fail("Sandbox diagnostics should use the active preset seed and remain disabled outside Lab")
		return
	var reset_cooldowns: Button = lab.get_node_or_null("Root/Body/Left/ProjectileControls/ResetCooldownsButton")
	if reset_cooldowns == null:
		_fail("Sandbox Lab should expose a reset-cooldowns command")
		return
	for field in ["_next_weapon_time", "_next_inferno_time", "_next_daggers_time", "_next_minigun_time",
			"_next_toxic_time", "_next_sawblades_time", "_next_meteor_time", "_next_prism_time",
			"_next_void_orb_time", "_next_frost_nova_time"]:
		lab.context.session.set(field, 999.0)
	reset_cooldowns.pressed.emit()
	for field in ["_next_weapon_time", "_next_inferno_time", "_next_daggers_time", "_next_minigun_time",
			"_next_toxic_time", "_next_sawblades_time", "_next_meteor_time", "_next_prism_time",
			"_next_void_orb_time", "_next_frost_nova_time"]:
		if not is_zero_approx(float(lab.context.session.get(field))):
			_fail("Reset cooldowns should reset every weapon timer, including %s" % field)
			return
	if lab.context.progression_service != null or lab.context.normal_save_service != null:
		_fail("Sandbox commands must not initialize progression or normal save services")
		return
	var wave_spin: SpinBox = lab.get_node_or_null("Root/Body/Left/WaveControls/WaveSpin")
	var jump_wave_button: Button = lab.get_node_or_null("Root/Body/Left/WaveControls/JumpWaveButton")
	if wave_spin == null or jump_wave_button == null:
		_fail("Sandbox Lab should expose an isolated jump-wave command")
		return
	wave_spin.value = 17
	jump_wave_button.pressed.emit()
	if lab.context.session.wave_director.wave != 17 or \
			lab.context.session.wave_director.elapsed_in_wave != 0.0 or \
			lab.context.session.wave_director.state != lab.context.session.WAVE_DIRECTOR_SCRIPT.State.WAVE or \
			lab.context.session.wave_spawning_enabled:
		_fail("Jump Wave should set the selected wave without enabling regular Sandbox spawns")
		return
	lab.context.session._spawn_wave_enemy()
	if lab.context.session._sandbox_rng_log.is_empty() or \
			not str(lab.context.session._sandbox_rng_log[0]["purpose"]).begins_with("wave_enemy"):
		_fail("Sandbox wave decisions should record their seeded RNG draws with a purpose")
		return
	var expected_rng := RandomNumberGenerator.new()
	expected_rng.seed = 1
	if not is_equal_approx(float(lab.context.session._sandbox_rng_log[0]["value"]), expected_rng.randf()):
		_fail("Sandbox RNG draws should be reproducible from the active preset seed")
		return
	lab._refresh()
	if not diagnostics.text.contains("SEED 1") or not diagnostics.text.contains("wave_enemy_"):
		_fail("The Lab RNG panel should show the preset seed and contextual draw log")
		return
	for _index in range(300):
		lab.context.session._random_float("buffer_limit_probe")
	if lab.context.session._sandbox_rng_log.size() != 256 or \
			lab.context.session._sandbox_rng_log[0]["purpose"] != "buffer_limit_probe":
		_fail("The Sandbox RNG log should remain bounded to its most recent 256 draws")
		return
	if wave_spin.min_value != 1.0 or wave_spin.max_value != 999.0:
		_fail("Jump Wave UI should bound its target to the supported range")
		return
	lab._jump_to_wave(0)
	if lab.context.session.wave_director.wave != 17 or \
			lab.get_node("Root/Body/Side/Sections/Status").text != "WAVE MUST BE BETWEEN 1 AND 999":
		_fail("Jump Wave should reject invalid wave numbers without changing the active wave")
		return
	var god_mode: CheckButton = lab.get_node("Root/Body/Side/Sections/GodModeToggle")
	if not lab.context.session._health_locked:
		_fail("Sandbox Lab should begin with its isolated god mode enabled")
		return
	god_mode.button_pressed = false
	if lab.context.session._health_locked:
		_fail("Sandbox Lab god mode should toggle only its isolated player damage lock")
		return
	god_mode.button_pressed = true
	var directory := ProjectSettings.globalize_path("user://sandbox_lab_smoke/presets")
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	lab.preset_store = load("res://scripts/sandbox_preset_store.gd").new(directory, lab.preset_service)
	lab.get_node("Root/Body/Side/Sections/PresetId").text = "smoke_build"
	lab._save_preset()
	if not lab.preset_store.load_preset("smoke_build").get("ok", false):
		_fail("The Lab UI should save a valid preset in the isolated Sandbox store")
		return
	var imported_path := directory.path_join("imported.json")
	var imported_preset: Dictionary = lab._default_preset()
	imported_preset["preset_id"] = "file_import"
	var imported_file := FileAccess.open(imported_path, FileAccess.WRITE)
	imported_file.store_string(JSON.stringify(imported_preset))
	imported_file.close()
	god_mode.button_pressed = false
	await lab._import_preset_file(imported_path)
	if lab.context.active_preset.get("preset_id", "") != "file_import" or lab.context.session._health_locked:
		_fail("A valid JSON file should import and apply to the isolated Lab: status=%s error=%s" % [
			lab.get_node("Root/Body/Side/Sections/Status").text,
			str(lab.preset_service.import_json(FileAccess.get_file_as_string(imported_path))),
		])
		return
	god_mode.button_pressed = true
	var active_before_invalid_import: String = str(lab.context.active_preset["preset_id"])
	var invalid_file := FileAccess.open(imported_path, FileAccess.WRITE)
	invalid_file.store_string("{invalid json")
	invalid_file.close()
	await lab._import_preset_file(imported_path)
	if lab.context.active_preset["preset_id"] != active_before_invalid_import:
		_fail("Invalid JSON imports must not replace the active Lab preset")
		return
	lab.context.simulation.pause()
	if not await _wait_for_pause(lab.context.simulation, true):
		_fail("The Lab simulation should pause before deterministic spawn checks")
		return
	lab.get_node("Root/Body/Left/Controls/SpawnButton").pressed.emit()
	if not await _wait_for_entities(lab.context.simulation, 10):
		_fail("The Lab spawn control should add enemies to its native simulation")
		return
	lab.context.simulation.resume()
	if not await _wait_for_projectiles(lab.context.simulation):
		_fail("The applied weapon build should fire through the Survival combat implementation")
		return
	if not await _wait_for_lab_damage(lab):
		_fail("The Lab diagnostics should capture real weapon damage events")
		return
	lab._refresh()
	if not dps_summary.text.contains("1S") or not dps_summary.text.contains("10S") or \
			not dps_summary.text.contains("RUN") or not dps_sources.text.contains("LIGHTNING"):
		_fail("The Lab should report rolling DPS windows and damage by weapon source")
		return
	lab.get_node("Root/Body/Left/ProjectileControls/ClearProjectilesButton").pressed.emit()
	if not await _wait_for_projectile_count(lab.context.simulation, 0) or \
			int(lab.context.simulation.snapshot()["metrics"]["entity_count"]) == 0:
		_fail("Clear Projectiles should remove shots while preserving the spawned enemies")
		return
	lab.get_node("Root/Body/Left/Controls/ResetButton").pressed.emit()
	if not await _wait_for_empty_simulation(lab.context) or \
			lab.context.session.loadout.weapon_level("lightning_conductor") != 1 or \
			lab.get_node("Root/Body/Side/Sections/Status").text != "LAB RESET FROM PRESET":
		_fail("Reset should rebuild cleanly; count=%d weapon=%d status=%s paused=%s" % [
			int(lab.context.simulation.snapshot()["metrics"]["entity_count"]),
			lab.context.session.loadout.weapon_level("lightning_conductor"),
			lab.get_node("Root/Body/Side/Sections/Status").text,
			str(lab.context.simulation.snapshot()["paused"]),
		])
		return
	var normal_saves := ProjectSettings.globalize_path("user://saves")
	if DirAccess.dir_exists_absolute(normal_saves) and not DirAccess.get_files_at(normal_saves).is_empty():
		_fail("The Lab smoke should not create or modify normal save slots")
		return
	lab.context.stop()
	lab.queue_free()
	await process_frame
	print("Sandbox Lab smoke passed isolated startup, preset save and native spawn")
	quit()

func _wait_for_entities(simulation: Object, expected_count: int) -> bool:
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if int(simulation.snapshot()["metrics"]["entity_count"]) >= expected_count:
			return true
	return false

func _wait_for_projectiles(simulation: Object) -> bool:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if int(simulation.snapshot()["metrics"]["projectile_count"]) > 0:
			return true
	return false

func _wait_for_projectile_count(simulation: Object, expected_count: int) -> bool:
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if int(simulation.snapshot()["metrics"]["projectile_count"]) == expected_count:
			return true
	return false

func _wait_for_lab_damage(lab: Control) -> bool:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if float(lab.context.session._weapon_damage_by_id.get("lightning_conductor", 0.0)) > 0.0:
			return true
	return false

func _wait_for_empty_simulation(context: Node) -> bool:
	var deadline := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if int(context.simulation.snapshot()["metrics"]["entity_count"]) == 0:
			return true
	return false

func _wait_for_pause(simulation: Object, expected: bool) -> bool:
	var deadline := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if bool(simulation.snapshot()["paused"]) == expected:
			return true
	return false

func _option_index_for(option: OptionButton, metadata: String) -> int:
	for index in range(option.item_count):
		if str(option.get_item_metadata(index)) == metadata:
			return index
	return -1

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
