extends RefCounted

const PROFILE_VERSION := 8
const STARTER_WEAPONS := ["lightning_conductor", "inferno_sprayer"]
const STARTER_RELICS := ["storm_core", "infernal_heart"]
const POWDER_TIERS := ["basic", "refined", "pure", "prismatic"]
const ENHANCEMENT_BASE_COSTS := [10, 15, 22, 32, 46, 65, 90, 125, 175, 250]
const RARITY_COST_MULTIPLIERS := {"normal": 1.0, "magic": 1.5, "mystic": 2.0, "legendary": 3.0, "mythic": 4.0}
const PROPOSED_SUCCESS_CHANCE := {"basic": 50.0, "refined": 70.0, "pure": 85.0, "prismatic": 95.0}
const PROPOSED_CRITICAL_FAILURE_CHANCE := {"basic": 10.0, "refined": 5.0, "pure": 2.0, "prismatic": 0.5}
const KNOWN_UNIQUE_EFFECTS := [
	"lightning_burst", "overflow_shield", "evolution_shockwave",
	"elite_haste", "free_first_chest_reroll", "expanded_loadout", "revive_knockback",
]
const PROPOSED_UNIQUE_EFFECTS := [
	"lightning_burst", "overflow_shield", "evolution_shockwave",
	"elite_haste", "free_first_chest_reroll", "expanded_loadout",
]
const PROPOSED_DISMANTLE_REWARDS := {
	"normal": {"powder_basic": 1}, "magic": {"powder_basic": 3},
	"mystic": {"powder_refined": 1}, "legendary": {"powder_refined": 3},
	"mythic": {"powder_pure": 1},
}
const PROPOSED_SELL_ESSENCE := {
	"normal": 5, "magic": 10, "mystic": 20, "legendary": 40, "mythic": 80,
}
const ACHIEVEMENT_CATALOG_PATH := "res://data/achievement_catalog.json"
const PROTOTYPE_SKILL_NODES := {
	"vitality_starter": {"category": "core_stats", "depth": 3, "max_hp_pct": 0.05, "prerequisites": [], "status": "PROPOSED"},
	"focused_training": {"category": "core_stats", "depth": 6, "damage_pct": 0.03, "prerequisites": ["vitality_starter"], "status": "PROPOSED"},
	"fleet_footed": {"category": "core_stats", "depth": 9, "move_speed_pct": 0.02, "prerequisites": ["focused_training"], "status": "PROPOSED"},
	"steady_aim": {"category": "core_stats", "depth": 12, "critical_chance_pct": 1.0, "prerequisites": ["fleet_footed"], "status": "PROPOSED"},
	"unlock_crimson_daggers": {"category": "weapon_unlocks", "depth": 3, "unlocks_weapon": "crimson_daggers", "unlock_name": "Crimson Daggers", "prerequisites": ["vitality_starter"], "status": "PROPOSED"},
	"unlock_blood_chalice": {"category": "relic_unlocks", "depth": 6, "unlocks_relic": "blood_chalice", "unlock_name": "Blood Chalice", "prerequisites": ["unlock_crimson_daggers"], "status": "PROPOSED"},
}
const EQUIPMENT_UNLOCKS := {
	"weapon_unlocks": [
		{"id": "crimson_daggers", "name": "Crimson Daggers"},
		{"id": "void_orb", "name": "Void Orb"},
		{"id": "frost_nova", "name": "Frost Nova"},
		{"id": "minigun", "name": "Minigun"},
		{"id": "meteor_staff", "name": "Meteor Staff"},
		{"id": "sawblades", "name": "Sawblades"},
		{"id": "toxic_cloud", "name": "Toxic Cloud"},
		{"id": "prism_laser", "name": "Prism Laser"},
	],
	"relic_unlocks": [
		{"id": "blood_chalice", "name": "Blood Chalice"},
		{"id": "singularity", "name": "Singularity"},
		{"id": "frozen_crown", "name": "Frozen Crown"},
		{"id": "overdrive_engine", "name": "Overdrive Engine"},
		{"id": "celestial_eye", "name": "Celestial Eye"},
		{"id": "magnetic_coil", "name": "Magnetic Coil"},
		{"id": "plague_mask", "name": "Plague Mask"},
		{"id": "prism_crystal", "name": "Prism Crystal"},
		{"id": "magnet_heart", "name": "Magnet Heart"},
	],
}
const RUN_ID_PATTERN := "^[A-Za-z0-9_-]{1,128}$"
const EQUIPMENT_GENERATOR_SCRIPT := preload("res://scripts/equipment_generator.gd")
const SURVIVAL_DIFFICULTY_SCRIPT := preload("res://scripts/survival_difficulty.gd")

var _save_service: RefCounted
var _slot_id: String
var _equipment_generator: RefCounted
var _achievement_definitions: Dictionary
var _rng := RandomNumberGenerator.new()
var _skill_nodes: Dictionary = {}

func _init(save_service: RefCounted, slot_id: String = "0") -> void:
	_save_service = save_service
	_slot_id = slot_id
	_equipment_generator = EQUIPMENT_GENERATOR_SCRIPT.new()
	_achievement_definitions = _load_achievement_catalog()
	_skill_nodes = PROTOTYPE_SKILL_NODES.duplicate(true)
	for category in EQUIPMENT_UNLOCKS:
		var previous_node := "unlock_crimson_daggers" if category == "weapon_unlocks" else "unlock_blood_chalice"
		var entries: Array = EQUIPMENT_UNLOCKS[category]
		for index in range(1, entries.size()):
			var entry: Dictionary = entries[index]
			var node_id := "unlock_%s" % str(entry["id"])
			_skill_nodes[node_id] = {
				"category": category,
				"depth": 3 * (index + 1),
				"unlocks_weapon" if category == "weapon_unlocks" else "unlocks_relic": entry["id"],
				"unlock_name": entry["name"],
				"prerequisites": [previous_node],
				"status": "PROPOSED",
			}
			previous_node = node_id
	_append_stat_nodes("max_hp_pct", "vitality", "MAX HP", "vitality_starter", 19, 0.003)
	_append_stat_nodes("damage_pct", "focused_training", "DAMAGE", "focused_training", 20, 0.003)
	_append_stat_nodes("move_speed_pct", "fleet_footed", "MOVE SPEED", "fleet_footed", 20, 0.002)
	_append_stat_nodes("critical_chance_pct", "steady_aim", "CRIT CHANCE", "steady_aim", 20, 0.15)
	_rng.randomize()

func _append_stat_nodes(stat_id: String, node_prefix: String, stat_name: String, prerequisite: String, count: int, value: float) -> void:
	for index in range(1, count + 1):
		var node_id := "%s_%02d" % [node_prefix, index + 1]
		var bonus_text := "+%.2f%%" % value if stat_id == "critical_chance_pct" else "+%.1f%%" % (value * 100.0)
		_skill_nodes[node_id] = {
			"category": "core_stats",
			"depth": index * 3,
			"cost": 40 + 10 * index,
			"unlock_name": "%s %02d" % [stat_name, index + 1],
			"stat_name": stat_name,
			"display_bonus": bonus_text,
			stat_id: value,
			"prerequisites": [prerequisite],
			"status": "PROPOSED",
		}
		prerequisite = node_id

func award_survival_run(
	run_id: String, wave_reached: int, victory: bool, kills: int = 0, difficulty_id: String = "normal",
	run_metrics: Dictionary = {}
) -> Dictionary:
	if _save_service == null or not _valid_run_id(run_id):
		return _award_error("invalid_run")
	var difficulty_index := SURVIVAL_DIFFICULTY_SCRIPT.ORDER.find(difficulty_id)
	if difficulty_index < 0:
		return _award_error("invalid_difficulty")
	if _achievement_definitions.is_empty():
		return _award_error("achievement_catalog_invalid")
	var metric_aggregations := _achievement_metric_aggregations()
	var derived_metrics := ["total_kills", "highest_wave", "completed_runs", "boss_victories", "chaos_victories", "equipment_items_collected"]
	for rarity in EQUIPMENT_GENERATOR_SCRIPT.RARITIES:
		derived_metrics.append("equipment_rarity_%s" % rarity)
	for slot in EQUIPMENT_GENERATOR_SCRIPT.SLOTS:
		derived_metrics.append("equipment_slot_%s" % slot)
	for run_difficulty in SURVIVAL_DIFFICULTY_SCRIPT.ORDER:
		derived_metrics.append("runs_at_difficulty_%s" % run_difficulty)
		derived_metrics.append("boss_victories_at_difficulty_%s" % run_difficulty)
	derived_metrics.append("elite_affix_types_defeated")
	for metric_id in run_metrics:
		var metric_value: Variant = run_metrics[metric_id]
		if typeof(metric_id) != TYPE_STRING or metric_id in derived_metrics or not metric_aggregations.has(metric_id) or \
			typeof(metric_value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(metric_value)) or float(metric_value) < 0.0:
			return _award_error("invalid_achievement_metrics")
	var profile_result := load_profile()
	if not profile_result.get("ok", false):
		return _award_error(str(profile_result.get("error", "load_failed")))
	var profile: Dictionary = profile_result["profile"]
	var rewarded_runs: Array = profile["rewarded_survival_runs"]
	if rewarded_runs.has(run_id):
		return {"ok": true, "duplicate": true, "essence": 0, "powder_basic": 0}
	var unlocked_index: int = SURVIVAL_DIFFICULTY_SCRIPT.ORDER.find(profile["highest_unlocked_difficulty"])
	if difficulty_index > unlocked_index:
		return _award_error("difficulty_locked")
	var wave := clampi(wave_reached, 1, 24)
	var final_boss_vanquished := victory and wave >= 24
	var difficulty_factors: Dictionary = SURVIVAL_DIFFICULTY_SCRIPT.DATA[difficulty_id]
	var newly_unlocked_difficulty := ""
	if final_boss_vanquished and difficulty_index == unlocked_index and unlocked_index < SURVIVAL_DIFFICULTY_SCRIPT.ORDER.size() - 1:
		newly_unlocked_difficulty = SURVIVAL_DIFFICULTY_SCRIPT.ORDER[unlocked_index + 1]
		profile["highest_unlocked_difficulty"] = newly_unlocked_difficulty
	var essence_reward := roundi((15.0 + 2.0 * wave + (25.0 if final_boss_vanquished else 0.0)) * difficulty_factors["essence"])
	var powder_reward := roundi((20.0 + 3.0 * wave + (30.0 if final_boss_vanquished else 0.0)) * difficulty_factors["powder"])
	profile["resources"]["essence"] = int(profile["resources"]["essence"]) + essence_reward
	profile["resources"]["powder_basic"] = int(profile["resources"]["powder_basic"]) + powder_reward
	var early_death := not victory and wave < EQUIPMENT_GENERATOR_SCRIPT.PROPOSED_EARLY_DEATH_RECOVERY_WAVE
	var equipment: Dictionary = _equipment_generator.generate_survival_item(
		run_id, difficulty_id, wave, early_death
	)
	profile["equipment_inventory"].append(equipment)
	var achievement_progress: Dictionary = profile["achievement_progress"]
	var achievement_metrics: Dictionary = achievement_progress["metrics"]
	var achievement_tiers: Dictionary = achievement_progress["tiers"]
	var metric_deltas := {
		"total_kills": maxi(0, kills),
		"highest_wave": wave,
		"completed_runs": 1,
		"boss_victories": 1 if final_boss_vanquished else 0,
		"chaos_victories": 1 if final_boss_vanquished and difficulty_id == "chaos" else 0,
		"equipment_items_collected": 1,
		"equipment_rarity_%s" % str(equipment["rarity"]): 1,
		"equipment_slot_%s" % str(equipment["slot"]): 1,
		"runs_at_difficulty_%s" % difficulty_id: 1,
		"boss_victories_at_difficulty_%s" % difficulty_id: 1 if final_boss_vanquished else 0,
	}
	metric_deltas.merge(run_metrics)
	for metric_id in metric_deltas:
		if not achievement_metrics.has(metric_id) or not metric_aggregations.has(metric_id):
			continue
		var delta: float = float(metric_deltas[metric_id])
		if metric_aggregations[metric_id] == "max":
			achievement_metrics[metric_id] = maxf(float(achievement_metrics[metric_id]), delta)
		else:
			achievement_metrics[metric_id] = float(achievement_metrics[metric_id]) + delta
	var affix_types_defeated := 0
	for affix_id in ["hasted", "armored", "regenerating", "volatile", "shielded", "split_on_death"]:
		if float(achievement_metrics.get("elite_affix_kills_%s" % affix_id, 0.0)) > 0.0:
			affix_types_defeated += 1
	achievement_metrics["elite_affix_types_defeated"] = affix_types_defeated
	var newly_unlocked_tiers := 0
	var new_exterminator_tiers := 0
	for achievement_id in _achievement_definitions:
		var definition: Dictionary = _achievement_definitions[achievement_id]
		var metric_id := str(definition["metric"])
		var previous_tier := int(achievement_tiers[achievement_id])
		var current_tier := _achievement_tier_for_metric(definition, float(achievement_metrics[metric_id]))
		achievement_tiers[achievement_id] = current_tier
		newly_unlocked_tiers += current_tier - previous_tier
		if achievement_id == "exterminator":
			new_exterminator_tiers = current_tier - previous_tier
	achievement_progress["metrics"] = achievement_metrics
	achievement_progress["tiers"] = achievement_tiers
	profile["achievement_progress"] = achievement_progress
	rewarded_runs.append(run_id)
	profile["rewarded_survival_runs"] = rewarded_runs
	if not _save_service.save_slot(_slot_id, profile):
		return _award_error("save_failed")
	var result := {
		"ok": true,
		"duplicate": false,
		"essence": essence_reward,
		"powder_basic": powder_reward,
		"equipment": equipment,
		"new_achievement_tiers": new_exterminator_tiers,
		"new_achievement_tier_count": newly_unlocked_tiers,
	}
	if not newly_unlocked_difficulty.is_empty():
		result["newly_unlocked_difficulty"] = newly_unlocked_difficulty
	return result

func load_profile() -> Dictionary:
	if _save_service == null:
		return {"ok": false, "error": "save_service_unavailable"}
	var loaded: Dictionary = _save_service.load_slot(_slot_id)
	if not loaded.get("ok", false):
		if loaded.get("error") == "not_found":
			return {"ok": true, "profile": _empty_profile()}
		return {"ok": false, "error": str(loaded.get("error", "load_failed"))}
	var profile: Dictionary = loaded["payload"]
	var migrated := bool(loaded.get("migrated", false))
	var version := int(profile.get("profile_version", 0))
	if version == 1:
		profile["equipment_inventory"] = profile.get("equipment_inventory", [])
	if version in [1, 2]:
		for equipment in profile.get("equipment_inventory", []):
			equipment["equipped"] = false
	if version in [1, 2, 3]:
		var old_resources: Dictionary = profile.get("resources", {})
		profile["resources"] = {
			"essence": old_resources.get("essence", 0),
			"powder_basic": old_resources.get("powder_basic", 0),
			"powder_refined": old_resources.get("powder_refined", 0),
			"powder_pure": old_resources.get("powder_pure", 0),
			"powder_prismatic": old_resources.get("powder_prismatic", 0),
		}
		profile["profile_version"] = PROFILE_VERSION
		migrated = true
	elif version == 4:
		profile["profile_version"] = PROFILE_VERSION
		migrated = true
	elif version == 5:
		profile["profile_version"] = PROFILE_VERSION
		migrated = true
	elif version == 6:
		profile["profile_version"] = PROFILE_VERSION
		migrated = true
	profile["highest_unlocked_difficulty"] = profile.get("highest_unlocked_difficulty", "easy")
	profile["unlocked_skill_nodes"] = profile.get("unlocked_skill_nodes", [])
	if not profile.has("armorless_records") and version < PROFILE_VERSION:
		profile["armorless_records"] = _empty_armorless_records()
		migrated = true
	if not profile.has("achievement_progress"):
		if version < PROFILE_VERSION:
			profile["achievement_progress"] = _empty_achievement_progress()
			migrated = true
	else:
		var achievement_progress: Variant = profile["achievement_progress"]
		if achievement_progress is Dictionary:
			var normalized_achievement_progress := _migrate_achievement_progress(achievement_progress)
			if achievement_progress != normalized_achievement_progress:
				profile["achievement_progress"] = normalized_achievement_progress
				migrated = true
	if migrated:
		profile["profile_version"] = PROFILE_VERSION
	if not _valid_profile(profile):
		return {"ok": false, "error": "invalid_profile"}
	if migrated and not _save_service.save_slot(_slot_id, profile):
		return {"ok": false, "error": "save_failed"}
	return {"ok": true, "profile": profile.duplicate(true)}

func can_save_profile() -> bool:
	return _save_service != null

func record_armorless_result(difficulty_id: String, wave: int, survival_time_seconds: float, kills: int) -> Dictionary:
	if _save_service == null:
		return {"ok": false, "error": "save_service_unavailable"}
	if difficulty_id not in SURVIVAL_DIFFICULTY_SCRIPT.ORDER or wave < 1 or kills < 0 or \
		not is_finite(survival_time_seconds) or survival_time_seconds < 0.0:
		return {"ok": false, "error": "invalid_armorless_record"}
	var profile_result := load_profile()
	if not profile_result.get("ok", false):
		return {"ok": false, "error": str(profile_result.get("error", "load_failed"))}
	var profile: Dictionary = profile_result["profile"]
	var records: Dictionary = profile["armorless_records"]
	var previous: Dictionary = records[difficulty_id]
	var updated := wave > int(previous["wave"]) or (wave == int(previous["wave"]) and
		(survival_time_seconds > float(previous["survival_time_seconds"]) or
		(survival_time_seconds == float(previous["survival_time_seconds"]) and kills > int(previous["kills"]))))
	if updated:
		records[difficulty_id] = {"wave": wave, "survival_time_seconds": survival_time_seconds, "kills": kills}
		profile["armorless_records"] = records
		if not _save_service.save_slot(_slot_id, profile):
			return {"ok": false, "error": "save_failed"}
	return {"ok": true, "updated": updated, "record": records[difficulty_id].duplicate(true)}

func set_equipped(instance_id: String, equipped: bool) -> Dictionary:
	var profile_result := load_profile()
	if not profile_result.get("ok", false):
		return {"ok": false, "error": str(profile_result.get("error", "load_failed"))}
	var profile: Dictionary = profile_result["profile"]
	var target: Dictionary = {}
	for equipment in profile["equipment_inventory"]:
		if equipment["instance_id"] == instance_id:
			target = equipment
			break
	if target.is_empty():
		return {"ok": false, "error": "equipment_not_found"}
	if equipped:
		for equipment in profile["equipment_inventory"]:
			if equipment["slot"] == target["slot"]:
				equipment["equipped"] = false
	target["equipped"] = equipped
	if not _save_service.save_slot(_slot_id, profile):
		return {"ok": false, "error": "save_failed"}
	return {"ok": true, "profile": profile.duplicate(true)}

func enhance_equipment(instance_id: String, stat_id: String, powder_tier: String) -> Dictionary:
	if powder_tier not in POWDER_TIERS:
		return {"ok": false, "error": "invalid_powder_tier"}
	var profile_result := load_profile()
	if not profile_result.get("ok", false):
		return {"ok": false, "error": str(profile_result.get("error", "load_failed"))}
	var profile: Dictionary = profile_result["profile"]
	for equipment in profile["equipment_inventory"]:
		if equipment["instance_id"] != instance_id:
			continue
		var line_index := -1
		for index in range(equipment["stat_lines"].size()):
			if equipment["stat_lines"][index]["stat_id"] == stat_id:
				line_index = index
				break
		if line_index < 0:
			return {"ok": false, "error": "stat_line_not_found"}
		var line: Dictionary = equipment["stat_lines"][line_index]
		var level := int(line["enhancement_level"])
		if level >= 10:
			return {"ok": false, "error": "enhancement_max_level"}
		var cost := enhancement_cost(str(equipment["rarity"]), level)
		var resource_key := "powder_%s" % powder_tier
		if int(profile["resources"].get(resource_key, 0)) < cost:
			return {"ok": false, "error": "insufficient_powder", "cost": cost}
		profile["resources"][resource_key] -= cost
		var chance := maxf(0.0, PROPOSED_SUCCESS_CHANCE[powder_tier] - 3.0 * level)
		var success := int(line["fail_streak"]) >= 9 or _rng.randf() * 100.0 < chance
		var critical_failure := false
		if success:
			line["enhancement_level"] = level + 1
			line["fail_streak"] = 0
		else:
			critical_failure = _rng.randf() * 100.0 < PROPOSED_CRITICAL_FAILURE_CHANCE[powder_tier]
			if critical_failure:
				line["enhancement_level"] = maxi(0, level - 1)
			line["fail_streak"] = int(line["fail_streak"]) + 1
		if not _save_service.save_slot(_slot_id, profile):
			return {"ok": false, "error": "save_failed"}
		return {
			"ok": true, "success": success, "critical_failure": critical_failure,
			"cost": cost, "profile": profile.duplicate(true),
		}
	return {"ok": false, "error": "equipment_not_found"}

func enhancement_cost(rarity: String, current_level: int) -> int:
	if not RARITY_COST_MULTIPLIERS.has(rarity) or current_level < 0 or current_level >= ENHANCEMENT_BASE_COSTS.size():
		return 0
	return ceili(float(ENHANCEMENT_BASE_COSTS[current_level]) * RARITY_COST_MULTIPLIERS[rarity])

func convert_powder(source_tier: String, amount: int) -> Dictionary:
	var source_index := POWDER_TIERS.find(source_tier)
	if source_index < 0 or source_index >= POWDER_TIERS.size() - 1 or amount < 10 or amount % 10 != 0:
		return {"ok": false, "error": "invalid_conversion"}
	var profile_result := load_profile()
	if not profile_result.get("ok", false):
		return {"ok": false, "error": str(profile_result.get("error", "load_failed"))}
	var profile: Dictionary = profile_result["profile"]
	var source_key := "powder_%s" % source_tier
	if int(profile["resources"].get(source_key, 0)) < amount:
		return {"ok": false, "error": "insufficient_powder"}
	profile["resources"][source_key] -= amount
	var next_key := "powder_%s" % POWDER_TIERS[source_index + 1]
	profile["resources"][next_key] += amount / 10
	if not _save_service.save_slot(_slot_id, profile):
		return {"ok": false, "error": "save_failed"}
	return {"ok": true, "profile": profile.duplicate(true)}

func choose_unique_effect(instance_id: String, effect_id: String) -> Dictionary:
	if effect_id not in PROPOSED_UNIQUE_EFFECTS:
		return {"ok": false, "error": "invalid_unique_effect"}
	var profile_result := load_profile()
	if not profile_result.get("ok", false):
		return {"ok": false, "error": str(profile_result.get("error", "load_failed"))}
	var profile: Dictionary = profile_result["profile"]
	for equipment in profile["equipment_inventory"]:
		if equipment["instance_id"] != instance_id:
			continue
		if equipment["rarity"] not in ["legendary", "mythic"] or equipment["unique_effect_id"] != "pending_choice":
			return {"ok": false, "error": "unique_effect_already_set_or_unavailable"}
		equipment["unique_effect_id"] = effect_id
		if not _save_service.save_slot(_slot_id, profile):
			return {"ok": false, "error": "save_failed"}
		return {"ok": true, "profile": profile.duplicate(true)}
	return {"ok": false, "error": "equipment_not_found"}

func dismantle_equipment(instance_id: String) -> Dictionary:
	var profile_result := load_profile()
	if not profile_result.get("ok", false):
		return {"ok": false, "error": str(profile_result.get("error", "load_failed"))}
	var profile: Dictionary = profile_result["profile"]
	for index in range(profile["equipment_inventory"].size()):
		var equipment: Dictionary = profile["equipment_inventory"][index]
		if equipment["instance_id"] != instance_id:
			continue
		var reward: Dictionary = PROPOSED_DISMANTLE_REWARDS[equipment["rarity"]]
		profile["equipment_inventory"].remove_at(index)
		for resource_key in reward:
			profile["resources"][resource_key] += int(reward[resource_key])
		if not _save_service.save_slot(_slot_id, profile):
			return {"ok": false, "error": "save_failed"}
		return {"ok": true, "powder_rewards": reward.duplicate(true), "profile": profile.duplicate(true)}
	return {"ok": false, "error": "equipment_not_found"}

func sell_equipment(instance_id: String) -> Dictionary:
	var profile_result := load_profile()
	if not profile_result.get("ok", false):
		return {"ok": false, "error": str(profile_result.get("error", "load_failed"))}
	var profile: Dictionary = profile_result["profile"]
	for index in range(profile["equipment_inventory"].size()):
		var equipment: Dictionary = profile["equipment_inventory"][index]
		if equipment["instance_id"] != instance_id:
			continue
		var essence_reward: int = PROPOSED_SELL_ESSENCE[equipment["rarity"]]
		profile["equipment_inventory"].remove_at(index)
		profile["resources"]["essence"] += essence_reward
		if not _save_service.save_slot(_slot_id, profile):
			return {"ok": false, "error": "save_failed"}
		return {
			"ok": true, "essence_reward": essence_reward,
			"profile": profile.duplicate(true),
		}
	return {"ok": false, "error": "equipment_not_found"}

func unlock_skill_node(node_id: String) -> Dictionary:
	if not _skill_nodes.has(node_id):
		return {"ok": false, "error": "unknown_skill_node"}
	var result := load_profile()
	if not result.get("ok", false):
		return {"ok": false, "error": str(result.get("error", "load_failed"))}
	var profile: Dictionary = result["profile"]
	if node_id in profile["unlocked_skill_nodes"]:
		return {"ok": false, "error": "skill_node_already_unlocked"}
	for prerequisite in _skill_nodes[node_id]["prerequisites"]:
		if prerequisite not in profile["unlocked_skill_nodes"]:
			return {"ok": false, "error": "skill_prerequisite_locked"}
	var cost := skill_node_cost(node_id)
	if int(profile["resources"]["essence"]) < cost:
		return {"ok": false, "error": "insufficient_essence"}
	profile["resources"]["essence"] -= cost
	profile["unlocked_skill_nodes"].append(node_id)
	if not _save_service.save_slot(_slot_id, profile):
		return {"ok": false, "error": "save_failed"}
	return {"ok": true, "profile": profile.duplicate(true)}

func skill_node_cost(node_id: String) -> int:
	if not _skill_nodes.has(node_id):
		return 0
	var node: Dictionary = _skill_nodes[node_id]
	if node.has("cost"):
		return int(node["cost"])
	var unlock_surcharge := 80 if node["category"] in ["weapon_unlocks", "relic_unlocks"] else 0
	return 20 + 10 * int(node["depth"]) + unlock_surcharge

func respec_skill_tree() -> Dictionary:
	var result := load_profile()
	if not result.get("ok", false):
		return {"ok": false, "error": str(result.get("error", "load_failed"))}
	var profile: Dictionary = result["profile"]
	for node_id in profile["unlocked_skill_nodes"]:
		if _skill_nodes.has(node_id):
			profile["resources"]["essence"] += skill_node_cost(node_id)
	profile["unlocked_skill_nodes"] = []
	if not _save_service.save_slot(_slot_id, profile):
		return {"ok": false, "error": "save_failed"}
	return {"ok": true, "profile": profile.duplicate(true)}

func skill_bonus(stat_id: String) -> float:
	var result := load_profile()
	if not result.get("ok", false):
		return 0.0
	var bonus := 0.0
	for node_id in result["profile"]["unlocked_skill_nodes"]:
		if _skill_nodes.has(node_id):
			bonus += float(_skill_nodes[node_id].get(stat_id, 0.0))
	return bonus

func unlocked_weapon_ids() -> Array[String]:
	var result: Array[String] = []
	for weapon_id in STARTER_WEAPONS:
		result.append(str(weapon_id))
	if _save_service == null:
		return result
	var profile_result := load_profile()
	if not profile_result.get("ok", false):
		return []
	for node_id in profile_result["profile"]["unlocked_skill_nodes"]:
		var weapon_id := str(_skill_nodes.get(str(node_id), {}).get("unlocks_weapon", ""))
		if not weapon_id.is_empty() and weapon_id not in result:
			result.append(weapon_id)
	return result

func unlocked_relic_ids() -> Array[String]:
	var result: Array[String] = []
	for relic_id in STARTER_RELICS:
		result.append(str(relic_id))
	if _save_service == null:
		return result
	var profile_result := load_profile()
	if not profile_result.get("ok", false):
		return []
	for node_id in profile_result["profile"]["unlocked_skill_nodes"]:
		var relic_id := str(_skill_nodes.get(str(node_id), {}).get("unlocks_relic", ""))
		if not relic_id.is_empty() and relic_id not in result:
			result.append(relic_id)
	return result

func skill_node_ids(category: String = "") -> Array[String]:
	var result: Array[String] = []
	for node_id in _skill_nodes:
		if category.is_empty() or str(_skill_nodes[node_id].get("category", "")) == category:
			result.append(str(node_id))
	return result

func skill_node_definition(node_id: String) -> Dictionary:
	return _skill_nodes.get(node_id, {}).duplicate(true)

func equipment_bonus(stat_id: String) -> float:
	return equipment_bonuses().get(stat_id, 0.0)

func equipment_bonuses() -> Dictionary:
	var bonuses: Dictionary = {}
	for stat_id in EQUIPMENT_GENERATOR_SCRIPT.PROPOSED_STAT_RANGES:
		bonuses[stat_id] = 0.0
	var result := load_profile()
	if not result.get("ok", false):
		return bonuses
	for equipment in result["profile"]["equipment_inventory"]:
		if not equipment.get("equipped", false):
			continue
		for line in equipment["stat_lines"]:
			var stat_id: String = line["stat_id"]
			bonuses[stat_id] += EQUIPMENT_GENERATOR_SCRIPT.stat_value(
				stat_id, float(line["roll_percentile"]), int(line["enhancement_level"])
			)
	return bonuses

func equipped_unique_effects() -> Array[String]:
	var effects: Array[String] = []
	var result := load_profile()
	if not result.get("ok", false):
		return effects
	for equipment in result["profile"]["equipment_inventory"]:
		var effect_id := str(equipment.get("unique_effect_id", ""))
		if equipment.get("equipped", false) and effect_id in PROPOSED_UNIQUE_EFFECTS and not effects.has(effect_id):
			effects.append(effect_id)
	return effects

func achievement_bonus(stat_id: String) -> float:
	var result := load_profile()
	if not result.get("ok", false):
		return 0.0
	var bonus := 0.0
	var acquired_tiers: Dictionary = result["profile"]["achievement_progress"]["tiers"]
	for achievement_id in _achievement_definitions:
		var definition: Dictionary = _achievement_definitions[achievement_id]
		var tiers: Array = definition["tiers"]
		for index in range(mini(int(acquired_tiers[achievement_id]), tiers.size())):
			bonus += float(tiers[index]["rewards"].get(stat_id, 0.0))
	return bonus

func _achievement_metric_aggregations() -> Dictionary:
	var result := {}
	for definition in _achievement_definitions.values():
		result[str(definition["metric"])] = str(definition["aggregation"])
	return result

func _empty_achievement_progress() -> Dictionary:
	var metrics := {}
	var tiers := {}
	for achievement_id in _achievement_definitions:
		var definition: Dictionary = _achievement_definitions[achievement_id]
		metrics[str(definition["metric"])] = 0
		tiers[str(achievement_id)] = 0
	return {"metrics": metrics, "tiers": tiers}

func _migrate_achievement_progress(previous: Variant) -> Dictionary:
	var progress := _empty_achievement_progress()
	if not previous is Dictionary:
		return progress
	var previous_metrics: Dictionary = previous
	var previous_tiers: Dictionary = previous
	if previous.has("metrics") or previous.has("tiers"):
		if not previous.get("metrics") is Dictionary or not previous.get("tiers") is Dictionary:
			return previous
		previous_metrics = previous["metrics"]
		previous_tiers = previous["tiers"]
	for achievement_id in _achievement_definitions:
		var definition: Dictionary = _achievement_definitions[achievement_id]
		var metric_id := str(definition["metric"])
		if previous_metrics.has(metric_id):
			progress["metrics"][metric_id] = previous_metrics[metric_id]
		var legacy_tier_key := "%s_tier" % str(achievement_id)
		if previous_tiers.has(achievement_id):
			progress["tiers"][achievement_id] = previous_tiers[achievement_id]
		elif previous.has(legacy_tier_key):
			progress["tiers"][achievement_id] = previous[legacy_tier_key]
	return progress

func _load_achievement_catalog() -> Dictionary:
	if not FileAccess.file_exists(ACHIEVEMENT_CATALOG_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ACHIEVEMENT_CATALOG_PATH))
	if not parsed is Dictionary or parsed.size() != 2 or int(parsed.get("version", 0)) != 1 or \
			not parsed.get("achievements") is Array or parsed["achievements"].is_empty() or \
			parsed["achievements"].size() > 150:
		return {}
	var definitions: Dictionary = {}
	var metric_aggregations: Dictionary = {}
	for definition in parsed["achievements"]:
		if not definition is Dictionary or definition.size() != 6 or typeof(definition.get("id")) != TYPE_STRING or \
				str(definition["id"]).is_empty() or definitions.has(definition["id"]) or \
				typeof(definition.get("category")) != TYPE_STRING or str(definition["category"]).is_empty() or \
				typeof(definition.get("secret")) != TYPE_BOOL or \
				typeof(definition.get("metric")) != TYPE_STRING or str(definition["metric"]).is_empty() or \
				str(definition.get("aggregation", "")) not in ["sum", "max"] or \
				not definition.get("tiers") is Array or definition["tiers"].size() != 4:
			return {}
		var metric_id := str(definition["metric"])
		var metric_aggregation := str(definition["aggregation"])
		if metric_aggregations.has(metric_id) and metric_aggregations[metric_id] != metric_aggregation:
			return {}
		metric_aggregations[metric_id] = metric_aggregation
		var previous_threshold := 0
		var tier_ids: Dictionary = {}
		for achievement_tier in definition["tiers"]:
			if not achievement_tier is Dictionary or achievement_tier.size() != 3 or \
					typeof(achievement_tier.get("id")) != TYPE_STRING or \
					str(achievement_tier["id"]).is_empty() or \
					tier_ids.has(achievement_tier["id"]) or \
					typeof(achievement_tier.get("threshold")) not in [TYPE_INT, TYPE_FLOAT] or \
					not is_finite(float(achievement_tier["threshold"])) or \
					int(achievement_tier["threshold"]) != float(achievement_tier["threshold"]) or \
					float(achievement_tier["threshold"]) <= previous_threshold or \
					not achievement_tier.get("rewards") is Dictionary:
				return {}
			tier_ids[achievement_tier["id"]] = true
			previous_threshold = int(achievement_tier["threshold"])
			for stat_id in achievement_tier["rewards"]:
				var reward = achievement_tier["rewards"][stat_id]
				if typeof(stat_id) != TYPE_STRING or str(stat_id).is_empty() or \
						typeof(reward) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(reward)):
					return {}
		definitions[definition["id"]] = definition.duplicate(true)
	return definitions

func _achievement_tier_for_metric(definition: Dictionary, metric_value: float) -> int:
	var tier := 0
	for achievement_tier in definition["tiers"]:
		if metric_value >= float(achievement_tier["threshold"]):
			tier += 1
	return tier

func _empty_profile() -> Dictionary:
	return {
		"profile_version": PROFILE_VERSION,
		"resources": {
			"essence": 0, "powder_basic": 0, "powder_refined": 0,
			"powder_pure": 0, "powder_prismatic": 0,
		},
		"equipment_inventory": [],
		"rewarded_survival_runs": [],
		"unlocked_skill_nodes": [],
		"highest_unlocked_difficulty": "easy",
		"achievement_progress": _empty_achievement_progress(),
		"armorless_records": _empty_armorless_records(),
	}

func _empty_armorless_records() -> Dictionary:
	var records := {}
	for difficulty_id in SURVIVAL_DIFFICULTY_SCRIPT.ORDER:
		records[difficulty_id] = {"wave": 0, "survival_time_seconds": 0.0, "kills": 0}
	return records

func _valid_profile(profile: Dictionary) -> bool:
	if profile.get("profile_version") != PROFILE_VERSION or not profile.get("resources") is Dictionary or \
			not profile.get("equipment_inventory") is Array or not profile.get("rewarded_survival_runs") is Array or \
				not profile.get("unlocked_skill_nodes") is Array or \
				typeof(profile.get("highest_unlocked_difficulty")) != TYPE_STRING or \
				profile["highest_unlocked_difficulty"] not in SURVIVAL_DIFFICULTY_SCRIPT.ORDER or \
				not profile.get("achievement_progress") is Dictionary or \
				not profile.get("armorless_records") is Dictionary or \
				profile["armorless_records"].size() != SURVIVAL_DIFFICULTY_SCRIPT.ORDER.size():
		return false
	for difficulty_id in SURVIVAL_DIFFICULTY_SCRIPT.ORDER:
		var record: Variant = profile["armorless_records"].get(difficulty_id)
		if not record is Dictionary or record.size() != 3 or \
			typeof(record.get("wave")) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(record["wave"])) or \
			int(record["wave"]) != float(record["wave"]) or int(record["wave"]) < 0 or \
			typeof(record.get("survival_time_seconds")) not in [TYPE_INT, TYPE_FLOAT] or \
			not is_finite(float(record["survival_time_seconds"])) or float(record["survival_time_seconds"]) < 0.0 or \
			typeof(record.get("kills")) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(record["kills"])) or \
			int(record["kills"]) != float(record["kills"]) or int(record["kills"]) < 0:
			return false
	var resources: Dictionary = profile["resources"]
	for resource in ["essence", "powder_basic", "powder_refined", "powder_pure", "powder_prismatic"]:
		var value = resources.get(resource)
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or value < 0.0:
			return false
	for run_id in profile["rewarded_survival_runs"]:
		if typeof(run_id) != TYPE_STRING or not _valid_run_id(run_id):
			return false
	var achievements: Dictionary = profile["achievement_progress"]
	if not achievements.get("metrics") is Dictionary or not achievements.get("tiers") is Dictionary or \
			achievements["metrics"].size() != _achievement_metric_aggregations().size() or \
			achievements["tiers"].size() != _achievement_definitions.size():
		return false
	for metric_id in _achievement_metric_aggregations():
		var metric_value = achievements["metrics"].get(metric_id, -1)
		if typeof(metric_value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(metric_value)) or float(metric_value) < 0.0:
			return false
	for achievement_id in _achievement_definitions:
		var achievement_tier = achievements["tiers"].get(achievement_id, -1)
		if typeof(achievement_tier) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(achievement_tier)) or \
				int(achievement_tier) != achievement_tier or achievement_tier < 0 or \
				achievement_tier > _achievement_definitions[achievement_id]["tiers"].size():
			return false
	var seen_skill_nodes: Dictionary = {}
	for node_id in profile["unlocked_skill_nodes"]:
		if typeof(node_id) != TYPE_STRING or not _skill_nodes.has(node_id) or seen_skill_nodes.has(node_id):
			return false
		seen_skill_nodes[node_id] = true
	var equipped_slots: Dictionary = {}
	for equipment in profile["equipment_inventory"]:
		if not _valid_equipment(equipment):
			return false
		if equipment["equipped"]:
			if equipped_slots.has(equipment["slot"]):
				return false
			equipped_slots[equipment["slot"]] = true
	return true

func _valid_equipment(equipment: Variant) -> bool:
	if not equipment is Dictionary or equipment.get("source_mode") != "survival" or \
			typeof(equipment.get("instance_id")) != TYPE_STRING or \
			typeof(equipment.get("slot")) != TYPE_STRING or not EQUIPMENT_GENERATOR_SCRIPT.SLOTS.has(equipment["slot"]) or \
			typeof(equipment.get("rarity")) != TYPE_STRING or not EQUIPMENT_GENERATOR_SCRIPT.RARITIES.has(equipment["rarity"]) or \
			typeof(equipment.get("equipped")) != TYPE_BOOL or not equipment.get("stat_lines") is Array:
		return false
	var stat_lines: Array = equipment["stat_lines"]
	if stat_lines.size() != EQUIPMENT_GENERATOR_SCRIPT.STAT_LINE_COUNTS[equipment["rarity"]]:
		return false
	var effect_id = equipment.get("unique_effect_id")
	if typeof(effect_id) != TYPE_STRING or \
		(equipment["rarity"] in ["legendary", "mythic"] and effect_id != "pending_choice" and effect_id not in KNOWN_UNIQUE_EFFECTS) or \
			(equipment["rarity"] not in ["legendary", "mythic"] and not effect_id.is_empty()):
		return false
	var used_stats: Dictionary = {}
	for stat_line in stat_lines:
		if not stat_line is Dictionary or not EQUIPMENT_GENERATOR_SCRIPT.STAT_IDS.has(stat_line.get("stat_id")) or \
				used_stats.has(stat_line["stat_id"]):
			return false
		var percentile = stat_line.get("roll_percentile")
		if typeof(percentile) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(percentile)) or \
				percentile < 0.0 or percentile > 1.0:
			return false
		var enhancement_level = stat_line.get("enhancement_level")
		var fail_streak = stat_line.get("fail_streak")
		if typeof(enhancement_level) not in [TYPE_INT, TYPE_FLOAT] or \
				int(enhancement_level) != enhancement_level or enhancement_level < 0 or enhancement_level > 10 or \
				typeof(fail_streak) not in [TYPE_INT, TYPE_FLOAT] or int(fail_streak) != fail_streak or \
				fail_streak < 0 or fail_streak > 9:
			return false
		used_stats[stat_line["stat_id"]] = true
	return true

func _valid_run_id(run_id: String) -> bool:
	var pattern := RegEx.new()
	pattern.compile(RUN_ID_PATTERN)
	return pattern.search(run_id) != null

func _award_error(code: String) -> Dictionary:
	return {"ok": false, "duplicate": false, "essence": 0, "powder_basic": 0, "equipment": {}, "error": code}
