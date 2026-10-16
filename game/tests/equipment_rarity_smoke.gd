extends SceneTree

const GENERATOR := preload("res://scripts/equipment_generator.gd")
const PROGRESSION := preload("res://scripts/progression_service.gd")
const SAVE_SERVICE := preload("res://scripts/save_service.gd")
const SAMPLE_COUNT := 20000

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for difficulty_id in GENERATOR.PROPOSED_RARITY_WEIGHTS_BY_DIFFICULTY:
		for wave_reached in [1, 24]:
			if not _distribution_matches(difficulty_id, wave_reached):
				quit(1)
				return
	var baseline: Array[float] = GENERATOR.rarity_weights_for("easy", 1)
	var early_loss: Array[float] = GENERATOR.rarity_weights_for("easy", 1, true)
	var later_loss: Array[float] = GENERATOR.rarity_weights_for("easy", 3, true)
	var recovered: Array[float] = GENERATOR.rarity_weights_for("easy", 6, true)
	var early_victory: Array[float] = GENERATOR.rarity_weights_for("easy", 1, false)
	var wave_six_baseline: Array[float] = GENERATOR.rarity_weights_for("easy", 6, false)
	if not _weights_sum_to_100(early_loss) or not _weights_sum_to_100(later_loss) or \
			_rare_weight(early_loss) >= _rare_weight(later_loss) or \
			_rare_weight(later_loss) >= _rare_weight(baseline) or \
			recovered != wave_six_baseline or early_victory != baseline:
		_fail("Early defeat should reduce higher rarity weights progressively, without penalizing victory")
		return
	if not _distribution_matches("easy", 1, true):
		quit(1)
		return
	if not _service_uses_outcome_context():
		quit(1)
		return
	print("Equipment rarity distribution smoke passed")
	quit()

func _distribution_matches(difficulty_id: String, wave_reached: int, early_death: bool = false) -> bool:
	var generator = GENERATOR.new(987654)
	var counts := {}
	for rarity in GENERATOR.RARITIES:
		counts[rarity] = 0
	for index in range(SAMPLE_COUNT):
		var item: Dictionary = generator.generate_survival_item(
			"rarity_%s_%s_%s" % [difficulty_id, wave_reached, index], difficulty_id, wave_reached, early_death
		)
		counts[item["rarity"]] += 1
	var weights: Array[float] = GENERATOR.rarity_weights_for(difficulty_id, wave_reached, early_death)
	for rarity_index in range(GENERATOR.RARITIES.size()):
		var rarity: String = GENERATOR.RARITIES[rarity_index]
		var probability := weights[rarity_index] / 100.0
		var expected := SAMPLE_COUNT * probability
		var standard_deviation := sqrt(SAMPLE_COUNT * probability * (1.0 - probability))
		if absf(float(counts[rarity]) - expected) > 5.0 * standard_deviation + 2.0:
			push_error("Seeded %s wave %d distribution outside tolerance for %s" % [difficulty_id, wave_reached, rarity])
			return false
	return true

func _rare_weight(weights: Array[float]) -> float:
	return weights[2] + weights[3] + weights[4]

func _weights_sum_to_100(weights: Array[float]) -> bool:
	var total := 0.0
	for weight in weights:
		if not is_finite(weight) or weight < 0.0:
			return false
		total += weight
	return is_equal_approx(total, 100.0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _service_uses_outcome_context() -> bool:
	for outcome in ["defeat", "victory"]:
		var directory := ProjectSettings.globalize_path("user://equipment_rarity_service_smoke/%s" % outcome)
		DirAccess.make_dir_recursive_absolute(directory)
		for file_name in DirAccess.get_files_at(directory):
			DirAccess.remove_absolute(directory.path_join(file_name))
		var service = PROGRESSION.new(SAVE_SERVICE.new(directory), "0")
		if not service.load_profile().get("ok", false):
			push_error("Could not create isolated progression fixture for %s" % outcome)
			return false
		var seed_value := 7781
		service._equipment_generator = GENERATOR.new(seed_value)
		var expects_early_penalty: bool = outcome == "defeat"
		var expected: Dictionary = GENERATOR.new(seed_value).generate_survival_item(
			"expected", "easy", 1, expects_early_penalty
		)
		var reward: Dictionary = service.award_survival_run("%s_run" % outcome, 1, outcome == "victory", 0, "easy")
		if not reward.get("ok", false):
			push_error("Progression service should award %s fixture: %s" % [outcome, reward])
			return false
		var equipment: Array = service.load_profile()["profile"]["equipment_inventory"]
		if equipment.size() != 1 or equipment[0]["rarity"] != expected["rarity"]:
			push_error("Progression should pass the correct early-death context for %s" % outcome)
			return false
	return true
