extends SceneTree

const GENERATOR_SCRIPT := preload("res://scripts/equipment_generator.gd")

func _initialize() -> void:
	var normal_weights: Array[float] = GENERATOR_SCRIPT.armorless_rarity_weights_for("normal", 1)
	var expected := [55.0, 35.0, 9.0, 1.0, 0.0]
	for index in range(expected.size()):
		if not is_equal_approx(normal_weights[index], expected[index]):
			_fail("Armorless wave 1 Normal weights should match the proposed GDD table")
			return
	var easy_weights: Array[float] = GENERATOR_SCRIPT.armorless_rarity_weights_for("easy", 8)
	if not is_equal_approx(_sum(easy_weights), 100.0) or \
		GENERATOR_SCRIPT.armorless_rarity_weights_for("normal", 20)[0] != 5.0:
		_fail("Armorless difficulty weights should normalize and use the matching wave band")
		return
	var generator = GENERATOR_SCRIPT.new(19273)
	var draft: Array[Dictionary] = generator.generate_armorless_draft("run_fixture", "normal", 8)
	if draft.size() != 3:
		_fail("Armorless should generate three independent equipment proposals")
		return
	var ids: Dictionary = {}
	for item in draft:
		if str(item.get("source_mode", "")) != "armorless" or \
			str(item.get("slot", "")) not in GENERATOR_SCRIPT.SLOTS or \
			ids.has(str(item.get("instance_id", ""))) or \
			item.get("stat_lines", []).size() != GENERATOR_SCRIPT.STAT_LINE_COUNTS[item["rarity"]]:
			_fail("Generated Armorless proposals should be independent temporary equipment records")
			return
		ids[item["instance_id"]] = true
	var next_wave_draft: Array[Dictionary] = generator.generate_armorless_draft("run_fixture", "normal", 9)
	if next_wave_draft[0]["instance_id"] == draft[0]["instance_id"]:
		_fail("Equipment instance IDs should be unique between Armorless waves in one run")
		return
	print("armorless_equipment_generator_smoke: passed proposed rarity weighting and three-item draft")
	quit(0)

func _sum(values: Array[float]) -> float:
	var total := 0.0
	for value in values:
		total += value
	return total

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
