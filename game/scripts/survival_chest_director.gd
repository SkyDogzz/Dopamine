extends RefCounted

var ordinary_drop_chance := 0.005
var elite_drop_chance := 0.15
var guarantee_interval_seconds := 60.0
var _last_drop_time := {"weapon": 0.0, "relic": 0.0}
var _rng := RandomNumberGenerator.new()

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value

func roll_drops(active_time: float, eligible_families: Array, elite: bool = false, boss: bool = false) -> Array[String]:
	var drops: Array[String] = []
	if not is_finite(active_time) or active_time < 0.0:
		return drops
	var chance := elite_drop_chance if elite else ordinary_drop_chance
	chance = clampf(chance, 0.0, 1.0)
	for family in ["weapon", "relic"]:
		if not eligible_families.has(family):
			continue
		var guaranteed := guarantee_interval_seconds > 0.0 and active_time - float(_last_drop_time[family]) >= guarantee_interval_seconds
		if boss or guaranteed or _rng.randf() < chance:
			drops.append(family)
			_last_drop_time[family] = active_time
	return drops
