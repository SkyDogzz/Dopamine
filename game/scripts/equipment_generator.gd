extends RefCounted

const SLOTS := ["helmet", "armor", "gloves", "boots", "amulet", "ring"]
const RARITIES := ["normal", "magic", "mystic", "legendary", "mythic"]
const PROPOSED_RARITY_WEIGHTS_BY_DIFFICULTY := {
	"easy": [60.0, 30.0, 9.0, 0.9, 0.1],
	"normal": [35.0, 40.0, 20.0, 4.5, 0.5],
	"hard": [15.0, 30.0, 40.0, 13.0, 2.0],
	"nightmare": [5.0, 15.0, 45.0, 28.0, 7.0],
	"chaos": [0.0, 5.0, 35.0, 40.0, 20.0],
}
const PROPOSED_ARMORLESS_RARITY_WEIGHTS_BY_WAVE := {
	1: [55.0, 35.0, 9.0, 1.0, 0.0],
	6: [25.0, 40.0, 27.0, 7.0, 1.0],
	16: [5.0, 20.0, 45.0, 25.0, 5.0],
	31: [0.0, 5.0, 25.0, 50.0, 20.0],
	51: [0.0, 0.0, 10.0, 55.0, 35.0],
}
const PROPOSED_ARMORLESS_DIFFICULTY_MULTIPLIERS := {
	"easy": 0.80, "normal": 1.0, "hard": 1.15, "nightmare": 1.35, "chaos": 1.60,
}
# A run reaching each six-wave milestone shifts one percentage point from Normal
# into the existing non-Normal distribution. This remains a proposed tuning rule.
const PROPOSED_WAVE_RARITY_SHIFT_PER_SIX_WAVES := 1.0
const STAT_IDS := [
	"damage_pct", "attack_speed_pct", "critical_chance_pct", "critical_damage_pct",
	"max_hp", "move_speed_pct", "kill_healing_pct", "area_pct", "cooldown_reduction_pct",
	"xp_pct", "pickup_radius_pct", "projectile_speed_pct",
]
const PROPOSED_STAT_RANGES := {
	"damage_pct": Vector2(1.0, 5.0), "attack_speed_pct": Vector2(1.0, 4.0),
	"critical_chance_pct": Vector2(0.5, 2.0), "critical_damage_pct": Vector2(5.0, 20.0),
	"max_hp": Vector2(2.0, 8.0), "move_speed_pct": Vector2(1.0, 4.0),
	"kill_healing_pct": Vector2(1.0, 3.0), "area_pct": Vector2(1.0, 4.0),
	"cooldown_reduction_pct": Vector2(0.5, 2.0), "xp_pct": Vector2(1.0, 4.0),
	"pickup_radius_pct": Vector2(2.0, 8.0), "projectile_speed_pct": Vector2(2.0, 8.0),
}
const STAT_LINE_COUNTS := {"normal": 1, "magic": 2, "mystic": 3, "legendary": 3, "mythic": 4}

var _rng := RandomNumberGenerator.new()

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value

func generate_survival_item(run_id: String, difficulty_id: String = "normal", wave_reached: int = 1) -> Dictionary:
	return _generate_item(
		"survival_%s_equipment" % run_id,
		rarity_weights_for(difficulty_id, wave_reached), "survival"
	)

func generate_armorless_draft(run_id: String, difficulty_id: String, wave_reached: int) -> Array[Dictionary]:
	var draft: Array[Dictionary] = []
	var weights := armorless_rarity_weights_for(difficulty_id, wave_reached)
	for index in range(3):
		draft.append(_generate_item(
			"armorless_%s_wave_%d_draft_%d" % [run_id, maxi(1, wave_reached), index],
			weights, "armorless"
	))
	return draft

func _generate_item(instance_id: String, weights: Array[float], source_mode: String) -> Dictionary:
	var rarity := _roll_rarity(weights)
	var available_stats: Array = STAT_IDS.duplicate()
	var stat_lines: Array[Dictionary] = []
	for index in range(STAT_LINE_COUNTS[rarity]):
		var stat_index := _rng.randi_range(0, available_stats.size() - 1)
		stat_lines.append({
			"stat_id": available_stats.pop_at(stat_index),
			"roll_percentile": _rng.randf(),
			"enhancement_level": 0,
			"fail_streak": 0,
		})
	return {
		"instance_id": instance_id,
		"slot": SLOTS[_rng.randi_range(0, SLOTS.size() - 1)],
		"rarity": rarity,
		"stat_lines": stat_lines,
		"equipped": false,
		"rolls_calibrated": false,
		"roll_ranges_status": "PROPOSED_ACTIVE",
		"unique_effect_id": "pending_choice" if rarity in ["legendary", "mythic"] else "",
		"source_mode": source_mode,
	}

static func armorless_rarity_weights_for(difficulty_id: String, wave_reached: int) -> Array[float]:
	var wave := maxi(1, wave_reached)
	var band_start := 1
	var band_starts: Array = PROPOSED_ARMORLESS_RARITY_WEIGHTS_BY_WAVE.keys()
	band_starts.sort()
	for start_wave in band_starts:
		if wave >= int(start_wave):
			band_start = int(start_wave)
	var weights: Array = PROPOSED_ARMORLESS_RARITY_WEIGHTS_BY_WAVE[band_start].duplicate()
	var multiplier := float(PROPOSED_ARMORLESS_DIFFICULTY_MULTIPLIERS.get(difficulty_id, 1.0))
	var total := 0.0
	for index in range(weights.size()):
		weights[index] = float(weights[index]) * pow(multiplier, index)
		total += float(weights[index])
	var normalized: Array[float] = []
	for weight in weights:
		normalized.append(float(weight) * 100.0 / total)
	return normalized

static func stat_value(stat_id: String, percentile: float, enhancement_level: int = 0) -> float:
	if not PROPOSED_STAT_RANGES.has(stat_id):
		return 0.0
	var bounds: Vector2 = PROPOSED_STAT_RANGES[stat_id]
	var roll := clampf(percentile, 0.0, 1.0)
	return lerpf(bounds.x, bounds.y, roll) * (1.0 + 0.08 * clampi(enhancement_level, 0, 10))

static func stat_label(stat_id: String, value: float) -> String:
	if stat_id == "max_hp":
		return "+%.1f HP" % value
	return "+%.1f%%" % value

static func rarity_weights_for(difficulty_id: String, wave_reached: int) -> Array[float]:
	var weights: Array = PROPOSED_RARITY_WEIGHTS_BY_DIFFICULTY.get(
		difficulty_id, PROPOSED_RARITY_WEIGHTS_BY_DIFFICULTY["normal"]
	).duplicate()
	var normal_weight: float = weights[0]
	var non_normal_weight := 100.0 - normal_weight
	if non_normal_weight <= 0.0:
		return weights
	var milestones := maxi(0, clampi(wave_reached, 1, 24) / 6)
	var shift := minf(normal_weight, PROPOSED_WAVE_RARITY_SHIFT_PER_SIX_WAVES * milestones)
	weights[0] = normal_weight - shift
	for index in range(1, weights.size()):
		weights[index] += shift * weights[index] / non_normal_weight
	var typed_weights: Array[float] = []
	for weight in weights:
		typed_weights.append(float(weight))
	return typed_weights

func _roll_rarity(weights: Array[float]) -> String:
	var roll := _rng.randf_range(0.0, 100.0)
	var cumulative := 0.0
	for index in range(RARITIES.size()):
		cumulative += weights[index]
		if roll < cumulative:
			return RARITIES[index]
	return RARITIES.back()
