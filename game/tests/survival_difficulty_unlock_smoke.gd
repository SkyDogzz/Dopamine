extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path("user://survival_difficulty_unlock_smoke")
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var save_service = load("res://scripts/save_service.gd").new(directory)
	var service = load("res://scripts/progression_service.gd").new(save_service, "0")
	var loss: Dictionary = service.award_survival_run("loss", 24, false, 0, "easy")
	if not loss.get("ok", false) or service.load_profile()["profile"]["highest_unlocked_difficulty"] != "easy":
		_fail("A defeat must not unlock another difficulty")
		return
	var short_win: Dictionary = service.award_survival_run("short-win", 23, true, 0, "easy")
	if not short_win.get("ok", false) or service.load_profile()["profile"]["highest_unlocked_difficulty"] != "easy":
		_fail("A win before the final boss must not unlock another difficulty")
		return
	var easy_win: Dictionary = service.award_survival_run("easy-win", 24, true, 0, "easy")
	if not easy_win.get("ok", false) or easy_win.get("newly_unlocked_difficulty") != "normal" or \
		service.load_profile()["profile"]["highest_unlocked_difficulty"] != "normal":
		_fail("A final boss victory on the highest unlocked difficulty should unlock only the next one")
		return
	var skipped_win: Dictionary = service.award_survival_run("skipped-win", 24, true, 0, "hard")
	if not skipped_win.get("ok", false) or skipped_win.has("newly_unlocked_difficulty") or \
		service.load_profile()["profile"]["highest_unlocked_difficulty"] != "normal":
		_fail("A victory on a later difficulty must not skip the unlock sequence")
		return
	var normal_win: Dictionary = service.award_survival_run("normal-win", 24, true, 0, "normal")
	var duplicate: Dictionary = service.award_survival_run("normal-win", 24, true, 0, "normal")
	if normal_win.get("newly_unlocked_difficulty") != "hard" or not duplicate.get("duplicate", false) or \
		duplicate.has("newly_unlocked_difficulty") or \
		service.load_profile()["profile"]["highest_unlocked_difficulty"] != "hard":
		_fail("The next difficulty should unlock once, and duplicate rewards must not unlock again")
		return
	if service.award_survival_run("invalid", 24, true, 0, "insane").get("error") != "invalid_difficulty":
		_fail("Unknown difficulty IDs must be rejected before rewards are recorded")
		return
	var easy_reward: Dictionary = service.award_survival_run("easy-reward", 4, false, 0, "easy")
	var hard_reward: Dictionary = service.award_survival_run("hard-reward", 4, false, 0, "hard")
	if easy_reward.get("essence") != 16 or easy_reward.get("powder_basic") != 22 or \
		hard_reward.get("essence") != 37 or hard_reward.get("powder_basic") != 48:
		_fail("The proposed difficulty factors should scale persistent rewards")
		return
	print("Survival difficulty unlock smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
