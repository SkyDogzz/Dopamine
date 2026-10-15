extends RefCounted

const PROFILE_VERSION := 2
const RUN_ID_PATTERN := "^[A-Za-z0-9_-]{1,128}$"
const EQUIPMENT_GENERATOR_SCRIPT := preload("res://scripts/equipment_generator.gd")

var _save_service: RefCounted
var _slot_id: String
var _equipment_generator: RefCounted

func _init(save_service: RefCounted, slot_id: String = "0") -> void:
	_save_service = save_service
	_slot_id = slot_id
	_equipment_generator = EQUIPMENT_GENERATOR_SCRIPT.new()

func award_survival_run(run_id: String, wave_reached: int, victory: bool) -> Dictionary:
	if _save_service == null or not _valid_run_id(run_id):
		return _award_error("invalid_run")
	var loaded: Dictionary = _save_service.load_slot(_slot_id)
	var profile: Dictionary
	var profile_migrated := false
	if loaded.get("ok", false):
		profile = loaded["payload"]
		if profile.get("profile_version") == 1:
			profile_migrated = true
			profile["profile_version"] = PROFILE_VERSION
			profile["equipment_inventory"] = profile.get("equipment_inventory", [])
		if not _valid_profile(profile):
			return _award_error("invalid_profile")
	elif loaded.get("error") == "not_found":
		profile = _empty_profile()
	else:
		return _award_error(str(loaded.get("error", "load_failed")))
	var rewarded_runs: Array = profile["rewarded_survival_runs"]
	if rewarded_runs.has(run_id):
		if profile_migrated or loaded.get("migrated", false):
			if not _save_service.save_slot(_slot_id, profile):
				return _award_error("save_failed")
		return {"ok": true, "duplicate": true, "essence": 0, "powder_basic": 0}
	var wave := clampi(wave_reached, 1, 24)
	var final_boss_vanquished := victory and wave >= 24
	# Normal difficulty uses the GDD's proposed base multipliers of 1.0.
	var essence_reward := roundi(15.0 + 2.0 * wave + (25.0 if final_boss_vanquished else 0.0))
	var powder_reward := roundi(20.0 + 3.0 * wave + (30.0 if final_boss_vanquished else 0.0))
	profile["resources"]["essence"] = int(profile["resources"]["essence"]) + essence_reward
	profile["resources"]["powder_basic"] = int(profile["resources"]["powder_basic"]) + powder_reward
	var equipment: Dictionary = _equipment_generator.generate_survival_item(run_id)
	profile["equipment_inventory"].append(equipment)
	rewarded_runs.append(run_id)
	profile["rewarded_survival_runs"] = rewarded_runs
	if not _save_service.save_slot(_slot_id, profile):
		return _award_error("save_failed")
	return {
		"ok": true,
		"duplicate": false,
		"essence": essence_reward,
		"powder_basic": powder_reward,
		"equipment": equipment,
	}

func _empty_profile() -> Dictionary:
	return {
		"profile_version": PROFILE_VERSION,
		"resources": {"essence": 0, "powder_basic": 0},
		"equipment_inventory": [],
		"rewarded_survival_runs": [],
	}

func _valid_profile(profile: Dictionary) -> bool:
	if profile.get("profile_version") != 2 or not profile.get("resources") is Dictionary or \
			not profile.get("equipment_inventory") is Array or not profile.get("rewarded_survival_runs") is Array:
		return false
	var resources: Dictionary = profile["resources"]
	for resource in ["essence", "powder_basic"]:
		var value = resources.get(resource)
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or value < 0.0:
			return false
	for run_id in profile["rewarded_survival_runs"]:
		if typeof(run_id) != TYPE_STRING or not _valid_run_id(run_id):
			return false
	for equipment in profile["equipment_inventory"]:
		if not _valid_equipment(equipment):
			return false
	return true

func _valid_equipment(equipment: Variant) -> bool:
	if not equipment is Dictionary or equipment.get("source_mode") != "survival" or \
			typeof(equipment.get("instance_id")) != TYPE_STRING or \
			typeof(equipment.get("slot")) != TYPE_STRING or not EQUIPMENT_GENERATOR_SCRIPT.SLOTS.has(equipment["slot"]) or \
			typeof(equipment.get("rarity")) != TYPE_STRING or not EQUIPMENT_GENERATOR_SCRIPT.RARITIES.has(equipment["rarity"]) or \
			not equipment.get("stat_lines") is Array:
		return false
	var stat_lines: Array = equipment["stat_lines"]
	if stat_lines.size() != EQUIPMENT_GENERATOR_SCRIPT.STAT_LINE_COUNTS[equipment["rarity"]]:
		return false
	var effect_id = equipment.get("unique_effect_id")
	if typeof(effect_id) != TYPE_STRING or \
			(equipment["rarity"] in ["legendary", "mythic"] and effect_id != "pending_choice") or \
			(equipment["rarity"] not in ["legendary", "mythic"] and not effect_id.is_empty()):
		return false
	var used_stats: Dictionary = {}
	for stat_line in stat_lines:
		if not stat_line is Dictionary or not EQUIPMENT_GENERATOR_SCRIPT.STAT_IDS.has(stat_line.get("stat_id")) or \
				used_stats.has(stat_line["stat_id"]):
			return false
		var percentile = stat_line.get("roll_percentile")
		if typeof(percentile) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(percentile)) or \
				percentile < 0.0 or percentile >= 1.0:
			return false
		used_stats[stat_line["stat_id"]] = true
	return true

func _valid_run_id(run_id: String) -> bool:
	var pattern := RegEx.new()
	pattern.compile(RUN_ID_PATTERN)
	return pattern.search(run_id) != null

func _award_error(code: String) -> Dictionary:
	return {"ok": false, "duplicate": false, "essence": 0, "powder_basic": 0, "equipment": {}, "error": code}
