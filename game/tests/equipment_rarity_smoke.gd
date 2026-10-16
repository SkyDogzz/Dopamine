extends SceneTree

const GENERATOR := preload("res://scripts/equipment_generator.gd")
const SAMPLE_COUNT := 20000

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for difficulty_id in GENERATOR.PROPOSED_RARITY_WEIGHTS_BY_DIFFICULTY:
		for wave_reached in [1, 24]:
			if not _distribution_matches(difficulty_id, wave_reached):
				quit(1)
				return
	print("Equipment rarity distribution smoke passed")
	quit()

func _distribution_matches(difficulty_id: String, wave_reached: int) -> bool:
	var generator = GENERATOR.new(987654)
	var counts := {}
	for rarity in GENERATOR.RARITIES:
		counts[rarity] = 0
	for index in range(SAMPLE_COUNT):
		var item: Dictionary = generator.generate_survival_item(
			"rarity_%s_%s_%s" % [difficulty_id, wave_reached, index], difficulty_id, wave_reached
		)
		counts[item["rarity"]] += 1
	var weights: Array[float] = GENERATOR.rarity_weights_for(difficulty_id, wave_reached)
	for rarity_index in range(GENERATOR.RARITIES.size()):
		var rarity: String = GENERATOR.RARITIES[rarity_index]
		var probability := weights[rarity_index] / 100.0
		var expected := SAMPLE_COUNT * probability
		var standard_deviation := sqrt(SAMPLE_COUNT * probability * (1.0 - probability))
		if absf(float(counts[rarity]) - expected) > 5.0 * standard_deviation + 2.0:
			push_error("Seeded %s wave %d distribution outside tolerance for %s" % [difficulty_id, wave_reached, rarity])
			return false
	return true
