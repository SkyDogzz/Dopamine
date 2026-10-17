extends SceneTree

func _initialize() -> void:
	var director_script = load("res://scripts/survival_chest_director.gd")
	var director = director_script.new(1234)
	director.ordinary_drop_chance = 0.0
	director.elite_drop_chance = 0.0
	var eligible := ["weapon", "relic", "weapon", "invalid"]
	if not director.roll_drops(59.9, eligible).is_empty():
		_fail("Ordinary drops should respect the configured zero chance before the safety interval")
		return
	var guaranteed: Array = director.roll_drops(60.0, eligible)
	if guaranteed != ["weapon", "relic"]:
		_fail("The safety interval should drop each eligible family once")
		return
	if not director.roll_drops(119.9, eligible).is_empty():
		_fail("A family should not be guaranteed again before another interval")
		return
	if director.roll_drops(120.0, eligible) != ["weapon", "relic"]:
		_fail("The safety interval should repeat after another minute without drops")
		return
	var boss_director = director_script.new(42)
	if boss_director.roll_drops(1.0, eligible, false, true) != ["weapon", "relic"]:
		_fail("A boss should guarantee one chest of every eligible family")
		return
	var elite_director = director_script.new(43)
	elite_director.elite_drop_chance = 1.0
	if elite_director.roll_drops(1.0, eligible, true) != ["weapon", "relic"]:
		_fail("An elite should use the configured elite drop chance")
		return
	var ordinary_sample = director_script.new(44017)
	ordinary_sample.guarantee_interval_seconds = 0.0
	if not is_equal_approx(ordinary_sample.ordinary_drop_chance, 0.0075):
		_fail("The validated ordinary family drop chance should default to 0.75%")
		return
	var ordinary_weapon_drops := 0
	var ordinary_relic_drops := 0
	var sample_count := 40000
	for index in range(sample_count):
		var drops: Array = ordinary_sample.roll_drops(float(index) / 1000.0, ["weapon", "relic"])
		ordinary_weapon_drops += int(drops.has("weapon"))
		ordinary_relic_drops += int(drops.has("relic"))
	if ordinary_weapon_drops not in range(220, 381) or ordinary_relic_drops not in range(220, 381):
		_fail("Ordinary family drops should statistically follow the configured 0.75% chance: %d/%d" % [
			ordinary_weapon_drops, ordinary_relic_drops,
		])
		return
	var elite_sample = director_script.new(44018)
	elite_sample.guarantee_interval_seconds = 0.0
	if not is_equal_approx(elite_sample.elite_drop_chance, 0.30):
		_fail("The validated elite family drop chance should default to 30%")
		return
	var elite_weapon_drops := 0
	var elite_relic_drops := 0
	var elite_double_drops := 0
	for index in range(sample_count):
		var drops: Array = elite_sample.roll_drops(float(index) / 1000.0, ["weapon", "relic"], true)
		elite_weapon_drops += int(drops.has("weapon"))
		elite_relic_drops += int(drops.has("relic"))
		elite_double_drops += int(drops.has("weapon") and drops.has("relic"))
	if elite_weapon_drops not in range(11400, 12601) or elite_relic_drops not in range(11400, 12601) or \
			elite_double_drops not in range(3300, 3901):
		_fail("Elite family drops should follow independent configured 30% chances: %d/%d/%d" % [
			elite_weapon_drops, elite_relic_drops, elite_double_drops,
		])
		return
	print("Chest drop samples: ordinary=%d/%d, elite=%d/%d, elite_both=%d/%d" % [
		ordinary_weapon_drops, ordinary_relic_drops, elite_weapon_drops, elite_relic_drops,
		elite_double_drops, sample_count,
	])
	print("Survival chest director smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
