extends SceneTree

const SAVE_SERVICE := preload("res://scripts/save_service.gd")
const PROGRESSION := preload("res://scripts/progression_service.gd")
const TEST_DIRECTORY := "user://survival_revive_smoke"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var progression = _create_progression_service()
	if progression == null or progression.equipped_unique_effects() != ["revive_once"]:
		_fail("The equipped revive fixture should be loaded through the normal progression service")
		return
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.progression_service = progression
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	root.add_child(session)
	await process_frame
	session._take_player_damage(session.player_max_hp + 1.0)
	var dialog: ConfirmationDialog = session.get_node_or_null("ReviveConfirmationDialog")
	if dialog == null or not dialog.visible or session.run_over or session.player.controls_enabled:
		_fail("A lethal hit with revive_once should ask for confirmation")
		return
	dialog.confirmed.emit()
	if session.run_over or not is_equal_approx(session.player_hp, session.player_max_hp * 0.5) or \
		not session._revive_used or session._revive_invulnerable_until <= session.player_active_time:
		_fail("Confirming revive should restore half HP and grant one protected revive")
		return
	var revived_hp: float = session.player_hp
	session._take_player_damage(10.0)
	if not is_equal_approx(session.player_hp, revived_hp):
		_fail("Revive invulnerability should block incoming damage")
		return
	session.player_active_time = session._revive_invulnerable_until
	session._take_player_damage(10.0)
	if not is_equal_approx(session.player_hp, revived_hp - 10.0):
		_fail("Damage should resume when revive invulnerability expires")
		return
	session._take_player_damage(session.player_hp + 1.0)
	if session.get_node("ReviveConfirmationDialog").visible:
		_fail("A run should not offer a second revive")
		return
	session.queue_free()
	await process_frame
	if await _expect_revive_unavailable("armorless", false, progression):
		return
	if await _expect_revive_unavailable("survival", true, progression):
		return
	if await _expect_revive_available("endless", progression):
		return
	if await _expect_revive_cancelled(progression):
		return
	print("Survival revive smoke passed")
	quit()

func _expect_revive_unavailable(mode: String, sandbox: bool, progression: RefCounted) -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.progression_service = progression
	session.mode_id = mode
	session.sandbox_diagnostics_enabled = sandbox
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	root.add_child(session)
	await process_frame
	session._take_player_damage(session.player_max_hp + 1.0)
	var dialog: ConfirmationDialog = session.get_node_or_null("ReviveConfirmationDialog")
	if dialog != null and dialog.visible:
		_fail("Revive must be unavailable for mode=%s sandbox=%s" % [mode, sandbox])
		return true
	session.queue_free()
	await process_frame
	return false

func _expect_revive_cancelled(progression: RefCounted) -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.progression_service = progression
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	root.add_child(session)
	await process_frame
	session._take_player_damage(session.player_max_hp + 1.0)
	var dialog: ConfirmationDialog = session.get_node("ReviveConfirmationDialog")
	dialog.canceled.emit()
	if not session.run_over or not session.simulation.snapshot()["paused"]:
		_fail("Declining revive should end and pause the run")
		return true
	session.queue_free()
	await process_frame
	return false

func _expect_revive_available(mode: String, progression: RefCounted) -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.progression_service = progression
	session.mode_id = mode
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	root.add_child(session)
	await process_frame
	session._take_player_damage(session.player_max_hp + 1.0)
	if not session.get_node("ReviveConfirmationDialog").visible:
		_fail("Endless standard should allow the equipped revive")
		return true
	session.get_node("ReviveConfirmationDialog").canceled.emit()
	session.queue_free()
	await process_frame
	return false

func _create_progression_service() -> RefCounted:
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var save_service = SAVE_SERVICE.new(directory)
	var progression = PROGRESSION.new(save_service, "0")
	var profile: Dictionary = progression.load_profile()["profile"]
	profile["equipment_inventory"] = [{
		"instance_id": "revive-once-fixture",
		"slot": "helmet",
		"rarity": "legendary",
		"stat_lines": [
			{"stat_id": "damage_pct", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0},
			{"stat_id": "max_hp", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0},
			{"stat_id": "attack_speed_pct", "roll_percentile": 0.5, "enhancement_level": 0, "fail_streak": 0},
		],
		"equipped": true,
		"rolls_calibrated": false,
		"roll_ranges_status": "PROPOSED_ACTIVE",
		"unique_effect_id": "revive_once",
		"source_mode": "survival",
	}]
	if not save_service.save_slot("0", profile):
		return null
	return progression

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
