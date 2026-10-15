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
	print("Survival chest director smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
