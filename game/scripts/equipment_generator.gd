extends RefCounted

const SLOTS := ["helmet", "armor", "gloves", "boots", "amulet", "ring"]
const RARITIES := ["normal", "magic", "mystic", "legendary", "mythic"]
const NORMAL_RARITY_WEIGHTS := [35.0, 40.0, 20.0, 4.5, 0.5]
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

func generate_survival_item(run_id: String) -> Dictionary:
	var rarity := _roll_normal_rarity()
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
		"instance_id": "survival_%s_equipment" % run_id,
		"slot": SLOTS[_rng.randi_range(0, SLOTS.size() - 1)],
		"rarity": rarity,
		"stat_lines": stat_lines,
		"equipped": false,
		"rolls_calibrated": false,
		"roll_ranges_status": "PROPOSED_ACTIVE",
		"unique_effect_id": "pending_choice" if rarity in ["legendary", "mythic"] else "",
		"source_mode": "survival",
	}

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

func _roll_normal_rarity() -> String:
	var roll := _rng.randf_range(0.0, 100.0)
	var cumulative := 0.0
	for index in range(RARITIES.size()):
		cumulative += NORMAL_RARITY_WEIGHTS[index]
		if roll < cumulative:
			return RARITIES[index]
	return RARITIES.back()
