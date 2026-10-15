extends RefCounted

const PROFILE_VERSION := 1
const RUN_ID_PATTERN := "^[A-Za-z0-9_-]{1,128}$"

var _save_service: RefCounted
var _slot_id: String

func _init(save_service: RefCounted, slot_id: String = "0") -> void:
	_save_service = save_service
	_slot_id = slot_id

func award_survival_run(run_id: String, wave_reached: int, victory: bool) -> Dictionary:
	if _save_service == null or not _valid_run_id(run_id):
		return _award_error("invalid_run")
	var loaded: Dictionary = _save_service.load_slot(_slot_id)
	var profile: Dictionary
	if loaded.get("ok", false):
		profile = loaded["payload"]
		if not _valid_profile(profile):
			return _award_error("invalid_profile")
	elif loaded.get("error") == "not_found":
		profile = _empty_profile()
	else:
		return _award_error(str(loaded.get("error", "load_failed")))
	var rewarded_runs: Array = profile["rewarded_survival_runs"]
	if rewarded_runs.has(run_id):
		return {"ok": true, "duplicate": true, "essence": 0, "powder_basic": 0}
	var wave := clampi(wave_reached, 1, 24)
	var final_boss_vanquished := victory and wave >= 24
	# Normal difficulty uses the GDD's proposed base multipliers of 1.0.
	var essence_reward := roundi(15.0 + 2.0 * wave + (25.0 if final_boss_vanquished else 0.0))
	var powder_reward := roundi(20.0 + 3.0 * wave + (30.0 if final_boss_vanquished else 0.0))
	profile["resources"]["essence"] = int(profile["resources"]["essence"]) + essence_reward
	profile["resources"]["powder_basic"] = int(profile["resources"]["powder_basic"]) + powder_reward
	rewarded_runs.append(run_id)
	profile["rewarded_survival_runs"] = rewarded_runs
	if not _save_service.save_slot(_slot_id, profile):
		return _award_error("save_failed")
	return {
		"ok": true,
		"duplicate": false,
		"essence": essence_reward,
		"powder_basic": powder_reward,
	}

func _empty_profile() -> Dictionary:
	return {
		"profile_version": PROFILE_VERSION,
		"resources": {"essence": 0, "powder_basic": 0},
		"rewarded_survival_runs": [],
	}

func _valid_profile(profile: Dictionary) -> bool:
	if profile.get("profile_version") != PROFILE_VERSION or not profile.get("resources") is Dictionary or \
			not profile.get("rewarded_survival_runs") is Array:
		return false
	var resources: Dictionary = profile["resources"]
	for resource in ["essence", "powder_basic"]:
		var value = resources.get(resource)
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or value < 0.0:
			return false
	for run_id in profile["rewarded_survival_runs"]:
		if typeof(run_id) != TYPE_STRING or not _valid_run_id(run_id):
			return false
	return true

func _valid_run_id(run_id: String) -> bool:
	var pattern := RegEx.new()
	pattern.compile(RUN_ID_PATTERN)
	return pattern.search(run_id) != null

func _award_error(code: String) -> Dictionary:
	return {"ok": false, "duplicate": false, "essence": 0, "powder_basic": 0, "error": code}
