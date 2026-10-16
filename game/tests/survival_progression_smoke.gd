extends SceneTree

const TEST_DIRECTORY := "user://survival_progression_smoke"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var save_service = load("res://scripts/save_service.gd").new(directory)
	var progression = load("res://scripts/progression_service.gd").new(save_service, "0")
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.progression_service = progression
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	root.add_child(session)
	await process_frame
	session.kill_count = 100
	session._finish_run(false)
	var reward_label: Label = session.get_node("HUD/RunResultOverlay/RunResultPanel/Content/Rewards")
	var equipment_label: Label = session.get_node("HUD/RunResultOverlay/RunResultPanel/Content/Equipment")
	var achievement_label: Label = session.get_node("HUD/RunResultOverlay/RunResultPanel/Content/Achievement")
	var profile: Dictionary = save_service.load_slot("0")["payload"]
	if not session.run_over or reward_label.text != "+17 ESSENCE  •  +23 BASIC POWDER":
		_fail("A normal Survival defeat should persist and show its proposed Normal rewards")
		return
	if not equipment_label.text.begins_with("EQUIPMENT: "):
		_fail("The Survival result should show its permanent equipment reward")
		return
	if not achievement_label.text.contains("EXTERMINATOR TIER +1") or \
			profile["achievement_progress"]["total_kills"] != 100:
		_fail("Survival results should persist the proposed Exterminator threshold exactly once")
		return
	if profile["resources"].get("essence") != 17 or profile["resources"].get("powder_basic") != 23:
		_fail("The Survival result should save its reward to the progression profile")
		return
	if profile["equipment_inventory"].size() != 1 or profile["equipment_inventory"][0].get("source_mode") != "survival":
		_fail("The Survival result should persist exactly one item in the permanent inventory")
		return
	session._finish_run(false)
	profile = save_service.load_slot("0")["payload"]
	if profile["resources"].get("essence") != 17 or profile["rewarded_survival_runs"].size() != 1 or \
			profile["achievement_progress"]["total_kills"] != 100:
		_fail("Finishing the same run twice must not duplicate its persistent reward")
		return
	var temporary_session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	temporary_session.progression_service = load("res://scripts/progression_service.gd").new(null, "temporary")
	temporary_session.skip_starting_weapon_choice = true
	temporary_session.spawn_initial_enemy = false
	temporary_session.wave_spawning_enabled = false
	temporary_session.weapon_enabled = false
	root.add_child(temporary_session)
	await process_frame
	temporary_session._finish_run(true)
	if temporary_session._run_result.get_node("Content/Rewards").text != "RUN SANS SAUVEGARDE" or \
		save_service.load_slot("0")["payload"] != profile:
		_fail("A temporary run should show no-save feedback and leave the normal profile untouched: %s / %s" % [
			temporary_session._run_result.get_node("Content/Rewards").text,
			save_service.load_slot("0")["payload"] == profile,
		])
		return
	temporary_session.queue_free()
	await process_frame
	print("Survival progression smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
