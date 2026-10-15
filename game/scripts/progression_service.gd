extends RefCounted

const PROFILE_VERSION := 5
const POWDER_TIERS := ["basic", "refined", "pure", "prismatic"]
const ENHANCEMENT_BASE_COSTS := [10, 15, 22, 32, 46, 65, 90, 125, 175, 250]
const RARITY_COST_MULTIPLIERS := {"normal": 1.0, "magic": 1.5, "mystic": 2.0, "legendary": 3.0, "mythic": 4.0}
const PROPOSED_SUCCESS_CHANCE := {"basic": 50.0, "refined": 70.0, "pure": 85.0, "prismatic": 95.0}
const PROPOSED_CRITICAL_FAILURE_CHANCE := {"basic": 10.0, "refined": 5.0, "pure": 2.0, "prismatic": 0.5}
const PROPOSED_UNIQUE_EFFECTS := [
	"lightning_burst", "overflow_shield", "evolution_shockwave",
	"elite_haste", "free_first_chest_reroll", "revive_knockback",
]
const PROPOSED_DISMANTLE_REWARDS := {
	"normal": {"powder_basic": 1}, "magic": {"powder_basic": 3},
	"mystic": {"powder_refined": 1}, "legendary": {"powder_refined": 3},
	"mythic": {"powder_pure": 1},
}
const PROTOTYPE_SKILL_NODES := {
	"vitality_starter": {"essence_cost": 50, "max_hp_pct": 0.05, "prerequisites": [], "status": "PROPOSED", "depth": 3},
	"focused_training": {"essence_cost": 80, "damage_pct": 0.03, "prerequisites": ["vitality_starter"], "status": "PROPOSED", "depth": 6},
}
const SKILL_CATEGORIES := {
	"core_stats": 30, "weapon_unlocks": 8, "relic_unlocks": 8,
	"weapon_mastery": 20, "relic_mastery": 20, "utilities": 14, "bridges": 20,
}
const ACHIEVEMENT_CATEGORIES := {
	"combat": 25, "survival": 15, "weapons": 20, "relics_evolutions": 15,
	"equipment": 15, "difficulty_bosses": 15, "progression": 10, "secrets": 5,
}
const PROPOSED_EXTERMINATOR_THRESHOLDS := [100, 1000, 10000, 100000]
const PROPOSED_EXTERMINATOR_DAMAGE_BONUSES := [0.0005, 0.001, 0.0015, 0.002]
const RUN_ID_PATTERN := "^[A-Za-z0-9_-]{1,128}$"
const EQUIPMENT_GENERATOR_SCRIPT := preload("res://scripts/equipment_generator.gd")

var _save_service: RefCounted
var _slot_id: String
var _equipment_generator: RefCounted
var _rng := RandomNumberGenerator.new()

func _init(save_service: RefCounted, slot_id: String = "0") -> void:
	_save_service = save_service
	_slot_id = slot_id
	_equipment_generator = EQUIPMENT_GENERATOR_SCRIPT.new()
	_rng.randomize()

func award_survival_run(run_id: String, wave_reached: int, victory: bool, kills: int = 0) -> Dictionary:
	if _save_service == null or not _valid_run_id(run_id):
		return _award_error("invalid_run")
	var profile_result := load_profile()
	if not profile_result.get("ok", false):
		return _award_error(str(profile_result.get("error", "load_failed")))
	var profile: Dictionary = profile_result["profile"]
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
	var equipment: Dictionary = _equipment_generator.generate_survival_item(run_id)
	profile["equipment_inventory"].append(equipment)
	var achievements: Dictionary = profile["achievement_progress"]
	var previous_tier := int(achievements["exterminator_tier"])
	achievements["total_kills"] = int(achievements["total_kills"]) + maxi(0, kills)
	var current_tier := 0
	for threshold in PROPOSED_EXTERMINATOR_THRESHOLDS:
		if int(achievements["total_kills"]) >= threshold:
			current_tier += 1
	achievements["exterminator_tier"] = current_tier
	profile["achievement_progress"] = achievements
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
		"new_achievement_tiers": current_tier - previous_tier,
	}

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
	profile["unlocked_skill_nodes"] = profile.get("unlocked_skill_nodes", [])
	profile["achievement_progress"] = profile.get("achievement_progress", {
		"total_kills": 0, "exterminator_tier": 0,
	})
	if not _valid_profile(profile):
		return {"ok": false, "error": "invalid_profile"}
	if migrated and not _save_service.save_slot(_slot_id, profile):
		return {"ok": false, "error": "save_failed"}
	return {"ok": true, "profile": profile.duplicate(true)}

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

func unlock_skill_node(node_id: String) -> Dictionary:
	if not PROTOTYPE_SKILL_NODES.has(node_id):
		return {"ok": false, "error": "unknown_skill_node"}
	var result := load_profile()
	if not result.get("ok", false):
		return {"ok": false, "error": str(result.get("error", "load_failed"))}
	var profile: Dictionary = result["profile"]
	if node_id in profile["unlocked_skill_nodes"]:
		return {"ok": false, "error": "skill_node_already_unlocked"}
	for prerequisite in PROTOTYPE_SKILL_NODES[node_id]["prerequisites"]:
		if prerequisite not in profile["unlocked_skill_nodes"]:
			return {"ok": false, "error": "skill_prerequisite_locked"}
	var cost := int(PROTOTYPE_SKILL_NODES[node_id]["essence_cost"])
	if int(profile["resources"]["essence"]) < cost:
		return {"ok": false, "error": "insufficient_essence"}
	profile["resources"]["essence"] -= cost
	profile["unlocked_skill_nodes"].append(node_id)
	if not _save_service.save_slot(_slot_id, profile):
		return {"ok": false, "error": "save_failed"}
	return {"ok": true, "profile": profile.duplicate(true)}

func respec_skill_tree() -> Dictionary:
	var result := load_profile()
	if not result.get("ok", false):
		return {"ok": false, "error": str(result.get("error", "load_failed"))}
	var profile: Dictionary = result["profile"]
	for node_id in profile["unlocked_skill_nodes"]:
		if PROTOTYPE_SKILL_NODES.has(node_id):
			profile["resources"]["essence"] += int(PROTOTYPE_SKILL_NODES[node_id]["essence_cost"])
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
		if PROTOTYPE_SKILL_NODES.has(node_id):
			bonus += float(PROTOTYPE_SKILL_NODES[node_id].get(stat_id, 0.0))
	return bonus

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

func proposed_skill_catalog() -> Array[Dictionary]:
	var nodes: Array[Dictionary] = []
	for category in SKILL_CATEGORIES:
		for index in range(SKILL_CATEGORIES[category]):
			var node_id := "%s_%02d" % [category, index + 1]
			var depth := 1 + index % 10
			nodes.append({
				"id": node_id, "category": category, "depth": depth,
				"essence_cost": 20 + 10 * depth + (80 if category in ["weapon_unlocks", "relic_unlocks"] else 0),
				"prerequisites": [], "status": "PROPOSED_CONTENT_PLACEHOLDER",
			})
	return nodes

func proposed_achievement_catalog() -> Array[Dictionary]:
	var achievements: Array[Dictionary] = []
	for category in ACHIEVEMENT_CATEGORIES:
		for index in range(ACHIEVEMENT_CATEGORIES[category]):
			achievements.append({
				"id": "%s_%02d" % [category, index + 1], "category": category,
				"tiers": PROPOSED_EXTERMINATOR_THRESHOLDS.duplicate(),
				"status": "PROPOSED_CONTENT_PLACEHOLDER",
			})
	return achievements

func achievement_bonus(stat_id: String) -> float:
	if stat_id != "damage_pct":
		return 0.0
	var result := load_profile()
	if not result.get("ok", false):
		return 0.0
	var tier := int(result["profile"]["achievement_progress"]["exterminator_tier"])
	var bonus := 0.0
	for index in range(mini(tier, PROPOSED_EXTERMINATOR_DAMAGE_BONUSES.size())):
		bonus += PROPOSED_EXTERMINATOR_DAMAGE_BONUSES[index]
	return bonus

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
		"achievement_progress": {"total_kills": 0, "exterminator_tier": 0},
	}

func _valid_profile(profile: Dictionary) -> bool:
	if profile.get("profile_version") != PROFILE_VERSION or not profile.get("resources") is Dictionary or \
			not profile.get("equipment_inventory") is Array or not profile.get("rewarded_survival_runs") is Array or \
				not profile.get("unlocked_skill_nodes") is Array or not profile.get("achievement_progress") is Dictionary:
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
	var total_kills = achievements.get("total_kills", -1)
	var achievement_tier = achievements.get("exterminator_tier", -1)
	if typeof(total_kills) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(total_kills)) or \
			int(total_kills) != total_kills or total_kills < 0 or \
			typeof(achievement_tier) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(achievement_tier)) or \
			int(achievement_tier) != achievement_tier or achievement_tier < 0 or \
			achievement_tier > PROPOSED_EXTERMINATOR_THRESHOLDS.size():
		return false
	var seen_skill_nodes: Dictionary = {}
	for node_id in profile["unlocked_skill_nodes"]:
		if typeof(node_id) != TYPE_STRING or not PROTOTYPE_SKILL_NODES.has(node_id) or seen_skill_nodes.has(node_id):
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
		(equipment["rarity"] in ["legendary", "mythic"] and effect_id != "pending_choice" and effect_id not in PROPOSED_UNIQUE_EFFECTS) or \
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
		var enhancement_level = stat_line.get("enhancement_level")
		var fail_streak = stat_line.get("fail_streak")
		if typeof(enhancement_level) not in [TYPE_INT, TYPE_FLOAT] or \
				int(enhancement_level) != enhancement_level or enhancement_level < 0 or enhancement_level > 10 or \
				typeof(fail_streak) not in [TYPE_INT, TYPE_FLOAT] or int(fail_streak) != fail_streak or fail_streak < 0:
			return false
		used_stats[stat_line["stat_id"]] = true
	return true

func _valid_run_id(run_id: String) -> bool:
	var pattern := RegEx.new()
	pattern.compile(RUN_ID_PATTERN)
	return pattern.search(run_id) != null

func _award_error(code: String) -> Dictionary:
	return {"ok": false, "duplicate": false, "essence": 0, "powder_basic": 0, "equipment": {}, "error": code}
