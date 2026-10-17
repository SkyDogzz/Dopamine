extends SceneTree

class EntityCountSnapshot:
	extends RefCounted
	var count: int

	func _init(value: int) -> void:
		count = value

	func snapshot() -> Dictionary:
		return {"metrics": {"entity_count": count}}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	const slot_path := "user://saves/slot_0.json"
	const sentinel := "{\"schema_version\":1,\"fixture\":\"sandbox-lab-must-preserve-this-slot\"}"
	var save_directory := ProjectSettings.globalize_path("user://saves")
	if DirAccess.make_dir_recursive_absolute(save_directory) != OK:
		_fail("Could not prepare an isolated normal-save sentinel")
		return
	var sentinel_file := FileAccess.open(slot_path, FileAccess.WRITE)
	if sentinel_file == null:
		_fail("Could not write an isolated normal-save sentinel")
		return
	sentinel_file.store_string(sentinel)
	sentinel_file.close()
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
	var spawn_count: SpinBox = lab.get_node_or_null("Root/Body/Side/Sections/EnemyConfig/SpawnCount")
	var enemy_select: OptionButton = lab.get_node_or_null("Root/Body/Side/Sections/EnemySelect")
	var elite_affix_select: OptionButton = lab.get_node_or_null("Root/Body/Side/Sections/EnemyConfig/EliteAffixSelect")
	if spawn_count == null or enemy_select == null or elite_affix_select == null or \
			spawn_count.value != 10.0 or not elite_affix_select.disabled or \
			not lab._can_spawn_batch(2490) or lab._can_spawn_batch(2491) or lab._can_spawn_batch(2500):
		_fail("The default spawn count should fit exactly within the native 2500-entity limit")
		return
	spawn_count.value = 500.0
	if not lab._can_spawn_batch(2000) or lab._can_spawn_batch(2001) or \
			lab._can_spawn_batch(0, 0) or lab._can_spawn_batch(0, 501):
		_fail("The configurable spawn count should respect native per-command and total entity caps")
		return
	spawn_count.value = 10.0
	if not lab._can_spawn_batch(2490) or lab._can_spawn_batch(2491) or lab._can_spawn_batch(2500):
		_fail("The Lab spawn batch should stop exactly at the native 2500-entity capacity")
		return
	var live_simulation: Object = lab.context.simulation
	lab.context.simulation = EntityCountSnapshot.new(2491)
	lab._spawn_enemies()
	if not str(lab.get_node("Root/Body/Side/Sections/Status").text).contains("ENTITY LIMIT 2500"):
		_fail("The Lab should warn before queuing a spawn batch that exceeds native capacity")
		return
	lab.context.simulation = live_simulation
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
	var import_profile: Button = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/ImportProfileButton")
	var equipment_slot: OptionButton = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/EquipmentRow/EquipmentSlot")
	var equipment_stat: OptionButton = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/EquipmentRow/EquipmentStat")
	var equipment_value: SpinBox = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/EquipmentRow/EquipmentValue")
	var add_equipment: Button = lab.get_node_or_null("Root/Body/Side/Sections/VisualBuild/AddEquipmentButton")
	var live_stat: OptionButton = lab.get_node_or_null("Root/Body/Side/Sections/LiveOverride/StatSelect")
	var live_value: SpinBox = lab.get_node_or_null("Root/Body/Side/Sections/LiveOverride/StatValue")
	var apply_live_stat: Button = lab.get_node_or_null("Root/Body/Side/Sections/LiveOverride/ApplyStat")
	var enemy_hp_override: SpinBox = lab.get_node_or_null("Root/Body/Side/Sections/EnemyConfig/EnemyHpMultiplier")
	var enemy_speed_override: SpinBox = lab.get_node_or_null("Root/Body/Side/Sections/EnemyConfig/EnemySpeedMultiplier")
	var contact_damage: SpinBox = lab.get_node_or_null("Root/Body/Side/Sections/EnemyConfig/ContactDamage")
	var health_decay_multiplier: SpinBox = lab.get_node_or_null("Root/Body/Side/Sections/EnemyConfig/HealthDecayMultiplier")
	var wave_spawning_toggle: CheckBox = lab.get_node_or_null("Root/Body/Side/Sections/EnemyConfig/WaveSpawningToggle")
	var seed_control: SpinBox = lab.get_node_or_null("Root/Body/Side/Sections/EnemyConfig/Seed")
	var restore_hp_button: Button = lab.get_node_or_null("Root/Body/Left/Controls/RestoreHpButton")
	if weapon_select == null or weapon_level == null or add_weapon == null or relic_select == null or \
			relic_level == null or add_relic == null or stat_select == null or stat_value == null or \
			add_stat == null or apply_build == null or import_profile == null or equipment_slot == null or equipment_stat == null or \
			equipment_value == null or add_equipment == null or live_stat == null or live_value == null or \
			apply_live_stat == null or enemy_hp_override == null or enemy_speed_override == null or \
			contact_damage == null or health_decay_multiplier == null or wave_spawning_toggle == null or seed_control == null or \
			restore_hp_button == null:
		_fail("Sandbox Lab should provide profile import, visual build controls and typed combat configuration")
		return
	if wave_spawning_toggle.button_pressed or lab.context.session.wave_spawning_enabled or \
			lab.context.session.spawn_initial_enemy:
		_fail("Sandbox automatic wave spawning should be disabled by default")
		return
	wave_spawning_toggle.button_pressed = true
	wave_spawning_toggle.toggled.emit(true)
	if not lab.context.session.wave_spawning_enabled or not lab.context.session.spawn_initial_enemy or \
			lab.context.active_preset["overrides"].get("wave_spawning_enabled", false) != true:
		_fail("Enabling automatic waves should update the isolated session and active preset")
		return
	wave_spawning_toggle.button_pressed = false
	wave_spawning_toggle.toggled.emit(false)
	if not is_equal_approx(seed_control.value, 1.0) or spawn_count.value != 10.0:
		_fail("The default Sandbox preset should expose seed 1")
		return
	seed_control.value = 42.0
	if int(lab.context.active_preset["seed"]) != 42 or lab.context.seed != 1:
		_fail("Changing seed should stage a RESTART override without changing the current RNG stream")
		return
	var pending_seed_snapshot: Dictionary = lab.context.capture_snapshot()
	if pending_seed_snapshot.get("ok", false) or pending_seed_snapshot.get("error", "") != "restart_pending":
		_fail("Snapshots should be refused until a staged seed is applied by reset")
		return
	await lab._reset()
	if lab.context.seed != 42 or lab.context.session.sandbox_rng_seed != 42 or \
			lab.get_node("Root/Body/Side/Sections/Status").text != "LAB RESET FROM PRESET":
		_fail("Reset should restart the isolated session from the staged seed")
		return
	var lab_session: Node2D = lab.context.session
	var simulation_time_before_restore := float(lab.context.simulation.snapshot()["simulation_time"])
	lab_session.player_hp = 12.0
	lab_session.player_shield = 4.5
	restore_hp_button.pressed.emit()
	if lab_session.player_hp != lab_session.player_max_hp or lab_session.player_shield != 4.5 or \
			float(lab.context.simulation.snapshot()["simulation_time"]) != simulation_time_before_restore:
		_fail("Restore HP should refill only player HP without advancing time or changing shield")
		return
	if not is_equal_approx(float(enemy_hp_override.value), 1.0):
		_fail("A preset without an enemy HP override should use the neutral multiplier")
		return
	enemy_hp_override.value = 2.0
	enemy_speed_override.value = 2.0
	if not is_equal_approx(float(lab.context.active_preset["overrides"]["enemy_hp"]), 2.0) or \
			not is_equal_approx(float(lab.context.active_preset["overrides"]["enemy_speed"]), 2.0):
		_fail("Changing the LIVE Lab control should update the active preset")
		return
	spawn_count.value = 3.0
	if int(lab.context.active_preset["overrides"].get("spawn_count", 0)) != 3:
		_fail("The spawn count control should persist as a bounded Sandbox preset override")
		return
	var previous_spawn_sequence := int(lab.context.simulation.snapshot()["last_sequence"])
	lab._spawn_enemies()
	while int(lab.context.simulation.snapshot()["last_sequence"]) <= previous_spawn_sequence:
		await process_frame
	var spawned_enemy_state: Dictionary = lab.context.simulation.snapshot()
	if spawned_enemy_state["entities"].size() != 3 or \
			float(spawned_enemy_state["entities"][0]["components"]["Health"]["maximum"]) != 40.0 or \
			float(spawned_enemy_state["entities"][0]["components"]["MoveSpeed"]) != 150.0:
		_fail("The configured batch size, enemy HP and speed multipliers should reach each Lab spawn command")
		return
	var sprinter_index := -1
	for index in range(enemy_select.item_count):
		if str(enemy_select.get_item_metadata(index)) == "sprinter":
			sprinter_index = index
			break
	if sprinter_index < 0:
		_fail("The Lab Spawn selector should contain the Sprinter profile")
		return
	for boss_id in ["mid_boss", "final_boss"]:
		var boss_profile_found := false
		for index in range(enemy_select.item_count):
			if str(enemy_select.get_item_metadata(index)) == boss_id:
				boss_profile_found = true
				break
		if not boss_profile_found:
			_fail("The Lab Spawn selector should contain the %s profile" % boss_id)
			return
	enemy_select.select(sprinter_index)
	enemy_select.item_selected.emit(sprinter_index)
	if str(lab.context.active_preset["overrides"].get("spawn_enemy_type", "")) != "sprinter":
		_fail("Changing the Spawn enemy type should persist in the active preset")
		return
	if not elite_affix_select.disabled:
		_fail("Elite affix selection should be disabled for a non-elite profile")
		return
	contact_damage.value = 5.0
	if not is_equal_approx(float(lab.context.session.contact_damage_per_hit), 5.0) or \
			not is_equal_approx(float(lab.context.active_preset["overrides"]["contact_damage_per_hit"]), 5.0):
		_fail("Changing contact damage should affect the isolated session and active preset immediately")
		return
	health_decay_multiplier.value = 2.0
	var base_decay: float = lab.context.simulation.health_decay_amount(5.0, 1.0)
	if not is_equal_approx(float(lab.context.session.sandbox_health_decay_multiplier), 2.0) or \
			not is_equal_approx(float(lab.context.active_preset["overrides"]["health_decay_multiplier"]), 2.0) or \
			not is_equal_approx(lab.context.session._player_health_decay_amount(5.0, 1.0), base_decay * 2.0):
		_fail("The Sandbox HP decay override should update the session and scale actual decay")
		return
	lab.context.session.sandbox_diagnostics_enabled = false
	if not is_equal_approx(lab.context.session._player_health_decay_amount(5.0, 1.0), base_decay):
		_fail("The HP decay override must not affect a non-Sandbox Survival session")
		return
	lab.context.session.sandbox_diagnostics_enabled = true
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
	stat_select.select(_option_index_for(stat_select, "max_hp"))
	stat_value.value = 10.0
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
			visual_build["equipment"][0]["stats"]["move_speed_pct"] != 7.5 or \
			visual_build["stats"]["max_hp"] != 10.0:
		_fail("Visual build controls should update the JSON model without duplicating an item")
		return
	await lab._apply_visual_build()
	if lab.context.session.loadout.weapon_level("minigun") != 3 or \
			lab.context.session.loadout.relic_level("magnet_heart") != 2 or \
			lab.context.session._equipment_bonus("damage_pct") != 12.5 or \
			lab.context.session._equipment_bonus("move_speed_pct") != 7.5 or \
			lab.context.session.player_max_hp != 110.0 or \
			not is_equal_approx(lab.context.session.player.move_speed,
				lab.context.session._base_player_move_speed * 1.075) or \
			not bool(lab.context.simulation.snapshot()["paused"]):
		_fail("Apply Build should atomically rebuild the paused isolated combat session from visual controls")
		return
	if not is_equal_approx(lab.context.session._cached_persistent_damage_multiplier, 1.125) or \
			not is_equal_approx(lab.context.session._persistent_damage_multiplier(), 1.18125):
		_fail("Sandbox build damage must affect the same effective multiplier used by combat")
		return
	live_stat.select(_option_index_for(live_stat, "damage_pct"))
	live_value.value = 10.0
	apply_live_stat.pressed.emit()
	if not is_equal_approx(float(lab.context.session._cached_equipment_bonuses["damage_pct"]), 22.5) or \
			not is_equal_approx(lab.context.session._persistent_damage_multiplier(), 1.28625) or \
			lab.context.active_preset["initial_build"]["equipment"].size() != 1:
		_fail("Live damage override should update combat immediately without changing the active preset build")
		return
	live_stat.select(_option_index_for(live_stat, "critical_chance_pct"))
	live_value.value = 7.5
	apply_live_stat.pressed.emit()
	if not is_equal_approx(lab.context.session._critical_chance(), 7.5) or \
			lab.context.active_preset["initial_build"]["stats"].has("critical_chance_pct"):
		_fail("Live critical chance should affect combat independently of the preset build")
		return
	live_stat.select(_option_index_for(live_stat, "move_speed_pct"))
	live_value.value = 20.0
	apply_live_stat.pressed.emit()
	if not is_equal_approx(lab.context.session.player.move_speed,
			lab.context.session._base_player_move_speed * 1.275):
		_fail("Live move speed should refresh the player controller immediately")
		return
	live_stat.select(_option_index_for(live_stat, "max_hp"))
	live_value.value = 7.5
	apply_live_stat.pressed.emit()
	if not is_equal_approx(lab.context.session.player_max_hp, 117.5):
		_fail("Live max HP should update the player's health ceiling immediately")
		return
	var session = lab.context.session
	live_stat.select(_option_index_for(live_stat, "attack_speed_pct"))
	live_value.value = 25.0
	apply_live_stat.pressed.emit()
	if not session._effective_weapon_cooldown(2.0) < 2.0:
		_fail("Live attack speed should shorten weapon cooldowns immediately")
		return
	live_stat.select(_option_index_for(live_stat, "cooldown_reduction_pct"))
	live_value.value = 20.0
	apply_live_stat.pressed.emit()
	if not session._effective_weapon_cooldown(2.0) < 1.6:
		_fail("Live cooldown reduction should stack with attack speed in weapon cadence")
		return
	live_stat.select(_option_index_for(live_stat, "critical_chance_pct"))
	live_value.value = 100.0
	apply_live_stat.pressed.emit()
	live_stat.select(_option_index_for(live_stat, "critical_damage_pct"))
	live_value.value = 50.0
	apply_live_stat.pressed.emit()
	if not is_equal_approx(session._roll_equipment_critical_multiplier(), 2.0):
		_fail("Live critical damage should change the multiplier used by critical hits")
		return
	live_stat.select(_option_index_for(live_stat, "kill_healing_pct"))
	live_value.value = 40.0
	apply_live_stat.pressed.emit()
	if not is_equal_approx(session._equipment_kill_healing(10.0), 14.0):
		_fail("Live kill healing should change healing immediately")
		return
	live_stat.select(_option_index_for(live_stat, "area_pct"))
	live_value.value = 25.0
	apply_live_stat.pressed.emit()
	if not is_equal_approx(session._equipment_area(100.0), 125.0):
		_fail("Live area should change weapon area immediately")
		return
	var base_xp: float = session._equipment_xp_value(100.0)
	live_stat.select(_option_index_for(live_stat, "xp_pct"))
	live_value.value = 30.0
	apply_live_stat.pressed.emit()
	if not is_equal_approx(session._equipment_xp_value(100.0), base_xp * 1.3):
		_fail("Live XP bonus should change XP pickup value immediately")
		return
	var base_pickup_radius: float = session._xp_pickup_radius(0.0)
	live_stat.select(_option_index_for(live_stat, "pickup_radius_pct"))
	live_value.value = 50.0
	apply_live_stat.pressed.emit()
	if not is_equal_approx(session._xp_pickup_radius(0.0), base_pickup_radius + session.xp_collection_radius * 0.5) or \
			not is_equal_approx(session.chest_collection_radius, 36.0):
		_fail("Live pickup radius should affect XP only and preserve the chest radius (base=%.2f, actual=%.2f, chest=%.2f)" % [
			base_pickup_radius, session._xp_pickup_radius(0.0), session.chest_collection_radius,
		])
		return
	var base_projectile_speed: float = session._equipment_projectile_speed(100.0)
	live_stat.select(_option_index_for(live_stat, "projectile_speed_pct"))
	live_value.value = 20.0
	apply_live_stat.pressed.emit()
	if not is_equal_approx(session._equipment_projectile_speed(100.0), base_projectile_speed * 1.2):
		_fail("Live projectile speed should change projectile velocity immediately")
		return
	await lab._apply_visual_build()
	if not lab.context.live_stat_overrides.is_empty() or \
			not is_equal_approx(lab.context.session._critical_chance(), 0.0) or \
			not is_equal_approx(lab.context.session._persistent_damage_multiplier(), 1.18125) or \
			lab.context.session.player_max_hp != 110.0:
		_fail("Rebuilding the Lab should clear all transient live stat overrides")
		return
	var diagnostics: Label = lab.get_node_or_null("Root/Body/Side/Sections/Diagnostics/RngLog")
	var dps_summary: Label = lab.get_node_or_null("Root/Body/Side/Sections/Diagnostics/DpsSummary")
	var dps_sources: Label = lab.get_node_or_null("Root/Body/Side/Sections/Diagnostics/DpsSources")
	if diagnostics == null or dps_summary == null or dps_sources == null:
		_fail("Sandbox Lab should expose RNG and source DPS diagnostics")
		return
	if lab.context.session.sandbox_rng_seed != 42 or not lab.context.session.sandbox_diagnostics_enabled:
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
	expected_rng.seed = 42
	if not is_equal_approx(float(lab.context.session._sandbox_rng_log[0]["value"]), expected_rng.randf()):
		_fail("Sandbox RNG draws should be reproducible from the active preset seed")
		return
	lab._refresh()
	if not diagnostics.text.contains("SEED 42") or not diagnostics.text.contains("wave_enemy_"):
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
	var saved_preset: Dictionary = lab.preset_store.load_preset("smoke_build")
	if not saved_preset.get("ok", false) or \
			int(saved_preset["preset"]["seed"]) != 42 or \
			float(saved_preset["preset"]["overrides"].get("enemy_hp", 0.0)) != 2.0 or \
			float(saved_preset["preset"]["overrides"].get("enemy_speed", 0.0)) != 2.0 or \
			int(saved_preset["preset"]["overrides"].get("spawn_count", 0)) != 3 or \
			str(saved_preset["preset"]["overrides"].get("spawn_enemy_type", "")) != "sprinter" or \
			str(saved_preset["preset"]["overrides"].get("spawn_enemy_affix", "")) != "Hasted" or \
			float(saved_preset["preset"]["overrides"].get("health_decay_multiplier", 0.0)) != 2.0 or \
			float(saved_preset["preset"]["overrides"].get("contact_damage_per_hit", 0.0)) != 5.0:
		_fail("The Lab UI should save a valid preset in the isolated Sandbox store")
		return
	var imported_path := directory.path_join("imported.json")
	var imported_preset: Dictionary = lab._default_preset()
	imported_preset["preset_id"] = "file_import"
	imported_preset["overrides"] = {"enemy_hp": 3.0, "enemy_speed": 3.0, "spawn_count": 4,
		"spawn_enemy_type": "elite", "spawn_enemy_affix": "Volatile", "contact_damage_per_hit": 7.0}
	var imported_file := FileAccess.open(imported_path, FileAccess.WRITE)
	imported_file.store_string(JSON.stringify(imported_preset))
	imported_file.close()
	god_mode.button_pressed = false
	await lab._import_preset_file(imported_path)
	if lab.context.active_preset.get("preset_id", "") != "file_import" or lab.context.session._health_locked or \
			float(enemy_hp_override.value) != 3.0 or float(contact_damage.value) != 7.0 or \
			float(enemy_speed_override.value) != 3.0 or int(spawn_count.value) != 4 or \
			str(enemy_select.get_item_metadata(enemy_select.selected)) != "elite" or \
			str(elite_affix_select.get_item_metadata(elite_affix_select.selected)) != "Volatile" or \
			elite_affix_select.disabled or \
			not is_equal_approx(float(lab.context.session.contact_damage_per_hit), 7.0):
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
	if not await _wait_for_entities(lab.context.simulation, 4):
		_fail("The Lab spawn control should add enemies to its native simulation")
		return
	if float(lab.context.simulation.snapshot()["entities"][0]["components"]["Health"]["maximum"]) != 150.0:
		_fail("Imported enemy HP configuration should affect the Lab spawn command")
		return
	var imported_elite: Dictionary = lab.context.simulation.snapshot()["entities"][0]["components"]
	if float(imported_elite["MoveSpeed"]) != 225.0 or str(imported_elite["Affix"]) != "Volatile" or \
			float(imported_elite["DeathExplosionRadius"]) != 82.0 or \
			float(imported_elite["DeathExplosionDamage"]) != 18.0:
		_fail("Imported enemy speed configuration should affect the Lab spawn command")
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
	for boss_id in ["mid_boss", "final_boss"]:
		var boss_index := -1
		for index in range(enemy_select.item_count):
			if str(enemy_select.get_item_metadata(index)) == boss_id:
				boss_index = index
				break
		enemy_select.select(boss_index)
		enemy_select.item_selected.emit(boss_index)
		if spawn_count.editable or str(lab.get_node("Root/Body/Left/Controls/SpawnButton").text) != "SPAWN BOSS":
			_fail("Boss profiles should force single-spawn mode in the Lab")
			return
		lab._spawn_enemies()
		if not await _wait_for_entities(lab.context.simulation, 1):
			_fail("The Lab should queue a single %s boss" % boss_id)
			return
		var boss_found := false
		for entity in lab.context.simulation.snapshot()["entities"]:
			var components: Dictionary = entity["components"]
			if str(components.get("EnemyType", "")) == boss_id:
				boss_found = is_equal_approx(float(components["Health"]["maximum"]),
					lab.context.session.boss_placeholder_hp * float(enemy_hp_override.value))
				break
		if not boss_found:
			_fail("The Lab should use the configured boss HP for %s" % boss_id)
			return
		if boss_id == "mid_boss":
			lab.get_node("Root/Body/Left/Controls/ResetButton").pressed.emit()
			if not await _wait_for_empty_simulation(lab.context):
				_fail("The Lab should reset cleanly between boss profile checks")
				return
	if str(lab.context.active_preset["overrides"].get("spawn_enemy_type", "")) != "final_boss":
		_fail("The selected boss should remain part of the isolated Lab preset")
		return
	lab.get_node("Root/Body/Left/Controls/ResetButton").pressed.emit()
	if not await _wait_for_empty_simulation(lab.context):
		_fail("The Lab should clear its final boss when reset")
		return
	if not FileAccess.file_exists(slot_path) or FileAccess.get_file_as_string(slot_path) != sentinel:
		_fail("Sandbox Lab preset, build, combat, and reset operations must preserve the normal save slot byte-for-byte")
		return
	lab.context.stop()
	lab.queue_free()
	await process_frame
	print("Sandbox Lab smoke passed isolated session, reset and normal-save preservation")
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
