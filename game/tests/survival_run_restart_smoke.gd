extends SceneTree

const SAVE_SERVICE := preload("res://scripts/save_service.gd")
const PROGRESSION_SERVICE := preload("res://scripts/progression_service.gd")
const TEST_DIRECTORY := "user://survival_run_restart_smoke"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var progression = PROGRESSION_SERVICE.new(SAVE_SERVICE.new(directory), "0")
	progression.load_profile()
	var first: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	first.difficulty_id = "easy"
	first.progression_service = progression
	root.add_child(first)
	current_scene = first
	await process_frame
	var first_run_id: String = first._run_id
	first._finish_run(false)
	first._restart_run()
	var deadline := Time.get_ticks_msec() + 2000
	var restarted: Node2D
	while Time.get_ticks_msec() < deadline:
		await process_frame
		restarted = current_scene as Node2D
		if restarted != null and restarted != first:
			break
	if restarted == null or restarted == first:
		_fail("Run Again should replace the completed Survival session")
		return
	if restarted.difficulty_id != "easy":
		_fail("Run Again should preserve the selected difficulty")
		return
	if restarted.progression_service != progression:
		_fail("Run Again should preserve the normal progression service")
		return
	if restarted._run_id == first_run_id or restarted.run_over:
		_fail("Run Again should create a fresh active run identity")
		return
	var first_profile: Dictionary = progression.load_profile()["profile"]
	if first_profile["rewarded_survival_runs"].size() != 1 or first_profile["equipment_inventory"].size() != 1:
		_fail("The first run should be rewarded exactly once before restart")
		return
	if not restarted._starting_weapon_choice_open:
		_fail("A restarted run should present the normal starting weapon choice")
		return
	var first_choice_id := str(restarted.loadout.starting_weapon_options()[0]["id"])
	restarted._on_chest_option_selected(first_choice_id)
	restarted._finish_run(false)
	var final_profile: Dictionary = progression.load_profile()["profile"]
	if final_profile["rewarded_survival_runs"].size() != 2 or final_profile["equipment_inventory"].size() != 2:
		_fail("The restarted run should award its own reward through the preserved progression service")
		return
	print("Survival run restart smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
