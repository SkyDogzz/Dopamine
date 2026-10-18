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
	session.difficulty_id = "easy"
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	root.add_child(session)
	await process_frame
	session._take_player_damage(session.player_max_hp + 1.0)
	var dialog: Control = session.get_node_or_null("HUD/ReviveConfirmationDialog")
	if dialog == null or not dialog.visible or session.run_over or session.player.controls_enabled:
		_fail("A lethal hit with revive_once should ask for confirmation")
		return
	var revive_button: Button = dialog.get_node("Center/Panel/Content/Actions/ReviveButton")
	var decline_button: Button = dialog.get_node("Center/Panel/Content/Actions/DeclineButton")
	if root.gui_get_focus_owner() != revive_button:
		_fail("Revive confirmation should place focus on the REVIVE action")
		return
	var dialog_panel: Control = dialog.get_node("Center/Panel")
	var dialog_actions: Control = dialog.get_node("Center/Panel/Content/Actions")
	var original_viewport_size := root.size
	for viewport_size in [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = viewport_size
		await process_frame
		var viewport_bounds := Rect2(Vector2.ZERO, Vector2(viewport_size))
		if not viewport_bounds.encloses(dialog_panel.get_global_rect()) or \
			not dialog_panel.get_global_rect().encloses(dialog_actions.get_global_rect()) or \
			not dialog_actions.get_global_rect().encloses(decline_button.get_global_rect()) or \
			not dialog_actions.get_global_rect().encloses(revive_button.get_global_rect()):
			_fail("Revive confirmation and both actions should fit the %s viewport" % viewport_size)
			return
	root.size = original_viewport_size
	await process_frame
	if "--capture" in OS.get_cmdline_user_args() and not await _capture_ui_state(session, "revive-confirmation.png"):
		return
	revive_button.pressed.emit()
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
	if session.get_node("HUD/ReviveConfirmationDialog").visible:
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
	if await _expect_revive_escape_declined(progression):
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
	var dialog: Control = session.get_node_or_null("HUD/ReviveConfirmationDialog")
	if dialog != null and dialog.visible:
		_fail("Revive must be unavailable for mode=%s sandbox=%s" % [mode, sandbox])
		return true
	session.queue_free()
	await process_frame
	return false

func _expect_revive_cancelled(progression: RefCounted) -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.progression_service = progression
	session.difficulty_id = "easy"
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	root.add_child(session)
	await process_frame
	session.player_active_time = 65.0
	session.kill_count = 12
	session._take_player_damage(session.player_max_hp + 1.0)
	var dialog: Control = session.get_node("HUD/ReviveConfirmationDialog")
	dialog.get_node("Center/Panel/Content/Actions/DeclineButton").pressed.emit()
	if not session.run_over or not session.simulation.snapshot()["paused"]:
		_fail("Declining revive should end and pause the run")
		return true
	var overlay: Control = session.get_node("HUD/RunResultOverlay")
	var deadline := Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < deadline and not overlay.visible:
		await process_frame
	var rewards: Label = session.get_node("HUD/RunResultOverlay/RunResultPanel/Content/Rewards")
	if not overlay.visible or rewards.text == "PROGRESSION SAVE FAILED" or not rewards.text.contains("ESSENCE"):
		_fail("Declining revive should show a successfully recorded run result")
		return true
	if "--capture" in OS.get_cmdline_user_args() and not await _capture_ui_state(session, "revive-declined-result.png"):
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
	if not session.get_node("HUD/ReviveConfirmationDialog").visible:
		_fail("Endless standard should allow the equipped revive")
		return true
	session.get_node("HUD/ReviveConfirmationDialog/Center/Panel/Content/Actions/DeclineButton").pressed.emit()
	session.queue_free()
	await process_frame
	return false

func _expect_revive_escape_declined(progression: RefCounted) -> bool:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.progression_service = progression
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	root.add_child(session)
	await process_frame
	session._take_player_damage(session.player_max_hp + 1.0)
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	session._unhandled_input(cancel)
	var overlay: Control = session.get_node("HUD/ReviveConfirmationDialog")
	if not session.run_over or overlay.visible or not session.simulation.snapshot()["paused"]:
		_fail("ui_cancel should accept defeat and close the revive confirmation")
		return true
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

func _capture_ui_state(session: Node2D, file_name: String) -> bool:
	if root.get_visible_rect().size != Vector2(853, 480):
		_fail("Expected an 853x480 visible area for %s" % file_name)
		return false
	var was_processing := session.is_processing()
	var was_physics_processing := session.is_physics_processing()
	session.set_process(false)
	session.set_physics_process(false)
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../docs/art/evidence/2026-10-18/states/%s" % file_name)
	var save_error := root.get_texture().get_image().save_png(path)
	session.set_process(was_processing)
	session.set_physics_process(was_physics_processing)
	if save_error != OK:
		_fail("Could not capture %s" % path)
		return false
	print("Revive visual capture: %s" % path)
	return true
