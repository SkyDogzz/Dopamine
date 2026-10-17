extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var preset_service = load("res://scripts/sandbox_preset_service.gd").new()
	var preset := {
		"schema_version": 1,
		"preset_id": "test_build",
		"name": "Test Build",
		"description": "A bounded test preset",
		"base_mode": "survival",
		"seed": 12345,
		"overrides": {"enemy_hp": 2.0, "enemy_speed": 2.0, "spawn_count": 25,
			"spawn_enemy_type": "elite", "spawn_enemy_affix": "Hasted", "contact_damage_per_hit": 5.0},
		"flags": {"god_mode": false},
		"initial_build": {"weapons": [{"id": "lightning_conductor", "level": 2}]},
	}
	var encoded: Dictionary = preset_service.encode_share_code(preset)
	if not encoded.get("ok", false):
		_fail("A valid preset should encode to a share code: %s" % encoded)
		return
	var decoded: Dictionary = preset_service.decode_share_code(encoded["code"])
	if not decoded.get("ok", false) or decoded["preset"].size() != preset.size() or \
			decoded["preset"]["preset_id"] != preset["preset_id"] or \
			decoded["preset"]["base_mode"] != preset["base_mode"] or \
			int(decoded["preset"]["seed"]) != preset["seed"] or \
			decoded["preset"]["initial_build"]["weapons"][0]["id"] != "lightning_conductor":
		_fail("A preset should survive a share-code round trip: %s" % decoded)
		return
	for key in decoded["preset"]:
		if key not in preset_service.PRESET_KEYS:
			_fail("Share codes must serialize only the public preset schema")
			return
	var directory := ProjectSettings.globalize_path("user://sandbox_preset_smoke/presets")
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var preset_store = load("res://scripts/sandbox_preset_store.gd").new(directory, preset_service)
	if not preset_store.save_preset(preset).get("ok", false):
		_fail("A validated preset should save inside the sandbox preset directory")
		return
	var listed: Dictionary = preset_store.list_presets()
	if not listed.get("ok", false) or listed["presets"].size() != 1 or \
			listed["presets"][0]["preset_id"] != preset["preset_id"]:
		_fail("The sandbox preset store should list saved presets")
		return
	if preset_store.load_preset("../slot_0").get("ok", false):
		_fail("Preset identifiers must not escape the sandbox preset directory")
		return
	if not preset_store.delete_preset("test_build").get("ok", false) or \
			preset_store.load_preset("test_build").get("ok", false):
		_fail("A preset should be deletable without touching other files")
		return
	var hostile := preset.duplicate(true)
	hostile["file_path"] = "/tmp/save.json"
	if preset_service.validate_preset(hostile).get("ok", false):
		_fail("Unknown path fields must be rejected")
		return
	for forbidden_key in ["script", "command", "system_path", "private_data", "password", "access_token", "email"]:
		var nested_hostile := preset.duplicate(true)
		nested_hostile["overrides"]["nested"] = {forbidden_key: "must_not_be_shared"}
		if preset_service.validate_preset(nested_hostile).get("ok", false) or \
				preset_service.encode_share_code(nested_hostile).get("ok", false):
			_fail("Preset import and share codes must reject executable, path and private-data fields: %s" % forbidden_key)
			return
	if preset_service.decode_share_code(encoded["code"].substr(0, encoded["code"].length() - 1) + "A").get("ok", false):
		_fail("A damaged share code must fail checksum validation")
		return
	if preset_service.import_json("{}".repeat(300000)).get("ok", false):
		_fail("An oversized preset JSON payload must be rejected")
		return
	var too_many_overrides := preset.duplicate(true)
	too_many_overrides["overrides"].clear()
	for index in range(257):
		too_many_overrides["flags"]["flag_%d" % index] = index
	if preset_service.validate_preset(too_many_overrides).get("ok", false):
		_fail("Preset flag collections must reject excessive entries")
		return
	var too_deep := preset.duplicate(true)
	var nested: Dictionary = too_deep["flags"]
	for _index in range(18):
		var child := {}
		nested["nested"] = child
		nested = child
	if preset_service.validate_preset(too_deep).get("ok", false):
		_fail("Preset payloads must reject excessive nesting")
		return
	var unsupported_override := preset.duplicate(true)
	unsupported_override["overrides"]["unknown_setting"] = 2.0
	if preset_service.validate_preset(unsupported_override).get("ok", false):
		_fail("Presets must reject configuration overrides without a runtime contract")
		return
	var invalid_spawn_type := preset.duplicate(true)
	invalid_spawn_type["overrides"]["spawn_enemy_type"] = "unknown_enemy"
	if preset_service.validate_preset(invalid_spawn_type).get("ok", false):
		_fail("Presets should reject enemy types outside the Sandbox Lab roster")
		return
	var invalid_spawn_affix := preset.duplicate(true)
	invalid_spawn_affix["overrides"]["spawn_enemy_affix"] = "Ghost"
	if preset_service.validate_preset(invalid_spawn_affix).get("ok", false):
		_fail("Presets should reject elite affixes outside the supported set")
		return
	var out_of_range_override := preset.duplicate(true)
	out_of_range_override["overrides"]["enemy_hp"] = 1000.1
	if preset_service.validate_preset(out_of_range_override).get("ok", false):
		_fail("Enemy HP multiplier should respect its hard upper bound")
		return
	var excessive_enemy_speed := preset.duplicate(true)
	excessive_enemy_speed["overrides"]["enemy_speed"] = 10.1
	if preset_service.validate_preset(excessive_enemy_speed).get("ok", false):
		_fail("Enemy speed multiplier should respect its hard upper bound")
		return
	var too_slow_enemy_speed := preset.duplicate(true)
	too_slow_enemy_speed["overrides"]["enemy_speed"] = 0.05
	if preset_service.validate_preset(too_slow_enemy_speed).get("ok", false):
		_fail("Enemy speed multiplier should respect its hard lower bound")
		return
	var excessive_spawn_count := preset.duplicate(true)
	excessive_spawn_count["overrides"]["spawn_count"] = 501
	if preset_service.validate_preset(excessive_spawn_count).get("ok", false):
		_fail("Spawn count should respect the native per-command cap")
		return
	var fractional_spawn_count := preset.duplicate(true)
	fractional_spawn_count["overrides"]["spawn_count"] = 2.5
	if preset_service.validate_preset(fractional_spawn_count).get("ok", false):
		_fail("Spawn count should reject fractional enemy counts")
		return
	var invalid_contact_damage := preset.duplicate(true)
	invalid_contact_damage["overrides"]["contact_damage_per_hit"] = -0.1
	if preset_service.validate_preset(invalid_contact_damage).get("ok", false):
		_fail("Contact damage should not allow a negative value")
		return
	var context = load("res://scripts/sandbox_lab_context.gd").new(preset_service)
	root.add_child(context)
	var context_start: Dictionary = await context.start(preset)
	if not context_start.get("ok", false) or context.progression_service != null or \
			context.normal_save_service != null or context.seed != preset["seed"] or \
			context.session.sandbox_rng_seed != 12345 or \
			not is_equal_approx(context.session.contact_damage_per_hit, 5.0):
		_fail("Sandbox Lab context must start from validated data without normal progression services")
		return
	var materialized_weapons: Array = context.build.to_dictionary()["weapons"]
	if materialized_weapons.size() != 1 or materialized_weapons[0]["id"] != "lightning_conductor" or \
			int(materialized_weapons[0]["level"]) != 2:
		_fail("The preset initial build should be materialized in the isolated Lab model")
		return
	var invalid_apply: Dictionary = await context.apply_preset(too_deep)
	if invalid_apply.get("ok", false) or context.active_preset["preset_id"] != preset["preset_id"]:
		_fail("A rejected preset must not replace the active Sandbox Lab context")
		return
	var invalid_build_preset := preset.duplicate(true)
	invalid_build_preset["initial_build"]["weapons"] = [{"id": "unknown_weapon", "level": 1}]
	var invalid_build_result: Dictionary = await context.apply_preset(invalid_build_preset)
	if invalid_build_result.get("ok", false) or context.build.to_dictionary()["weapons"].size() != 1:
		_fail("An invalid build must be rejected without replacing the current Lab build")
		return
	var excessive_level_preset := preset.duplicate(true)
	excessive_level_preset["initial_build"]["weapons"] = [{"id": "lightning_conductor", "level": 101}]
	if (await context.apply_preset(excessive_level_preset)).get("ok", false):
		_fail("Sandbox build levels above the proposed technical cap must be rejected")
		return
	context.simulation.pause()
	var reset_apply: Dictionary = await context.apply_preset(preset)
	if not reset_apply.get("ok", false) or context.seed != preset["seed"]:
		_fail("A paused Lab should transactionally reset into a validated preset")
		return
	var evolved_preset := preset.duplicate(true)
	evolved_preset["initial_build"] = {
		"weapons": [{"id": "lightning_conductor", "level": 5, "evolution_id": "infinite_circuit"}],
		"relics": [{"id": "storm_core", "level": 5}], "equipment": [], "stats": {"damage_pct": 25.0},
	}
	var evolved_result: Dictionary = await context.apply_preset(evolved_preset)
	if not evolved_result.get("ok", false) or not context.session.loadout.is_evolved("lightning_conductor") or \
			context.session._equipment_bonus("damage_pct") != 25.0:
		_fail("Sandbox build should apply a valid evolution and isolated custom damage stat")
		return
	var mismatched_evolution := evolved_preset.duplicate(true)
	mismatched_evolution["initial_build"]["weapons"][0]["evolution_id"] = "wildfire"
	if (await context.apply_preset(mismatched_evolution)).get("ok", false):
		_fail("A weapon must reject an evolution belonging to a different catalog pair")
		return
	context.stop()
	context.queue_free()
	print("Sandbox preset smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
