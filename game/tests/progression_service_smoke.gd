extends SceneTree

const TEST_DIRECTORY := "user://progression_service_smoke"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var save_service = load("res://scripts/save_service.gd").new(directory)
	var service = load("res://scripts/progression_service.gd").new(save_service, "0")
	var victory: Dictionary = service.award_survival_run("run-win", 24, true)
	if not victory.get("ok", false) or victory.get("essence") != 88 or victory.get("powder_basic") != 122:
		_fail("A Normal wave 24 victory should grant the GDD proposed 88 Essence and 122 Basic Powder")
		return
	var duplicate: Dictionary = service.award_survival_run("run-win", 24, true)
	if not duplicate.get("ok", false) or not duplicate.get("duplicate", false):
		_fail("Reprocessing one run ID should be idempotent")
		return
	var defeat: Dictionary = service.award_survival_run("run-loss", 12, false)
	if not defeat.get("ok", false) or defeat.get("essence") != 39 or defeat.get("powder_basic") != 56:
		_fail("A defeated run should grant the proposed resources for its last reached wave")
		return
	var profile: Dictionary = save_service.load_slot("0")["payload"]
	if profile["resources"].get("essence") != 127 or profile["resources"].get("powder_basic") != 178:
		_fail("Distinct completed runs should accumulate their resources")
		return
	print("Progression service smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
