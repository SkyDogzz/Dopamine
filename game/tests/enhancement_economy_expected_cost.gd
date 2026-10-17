extends SceneTree

const PROGRESSION := preload("res://scripts/progression_service.gd")
const POWDER_TIERS := ["basic", "refined", "pure", "prismatic"]
const RARITIES := ["normal", "magic", "mystic", "legendary", "mythic"]
const LEVELS_PER_LINE := 10
const FAIL_STREAKS := 10

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var progression: RefCounted = PROGRESSION.new(null, "survey")
	print("# Exact absorbing Markov-chain expectation; level 0 to 10; fail-streak pity retained.")
	print("powder_tier,rarity,expected_attempts,expected_powder,expected_levels_lost_to_critical_failures")
	for powder_tier in POWDER_TIERS:
		for rarity in RARITIES:
			var outcomes := _expected_outcomes(progression, powder_tier, rarity)
			if outcomes.is_empty():
				push_error("Could not solve enhancement expectation for %s/%s" % [powder_tier, rarity])
				quit(1)
				return
			print("%s,%s,%.3f,%.2f,%.3f" % [
				powder_tier, rarity, outcomes[0], outcomes[1], outcomes[2],
			])
	quit(0)

func _expected_outcomes(progression: RefCounted, powder_tier: String, rarity: String) -> PackedFloat64Array:
	var state_count := LEVELS_PER_LINE * FAIL_STREAKS
	var augmented_width := state_count + 3
	var matrix: Array[PackedFloat64Array] = []
	var base_chance: float = PROGRESSION.PROPOSED_SUCCESS_CHANCE[powder_tier]
	var critical_chance: float = PROGRESSION.PROPOSED_CRITICAL_FAILURE_CHANCE[powder_tier] / 100.0
	for level in range(LEVELS_PER_LINE):
		for fail_streak in range(FAIL_STREAKS):
			var row := PackedFloat64Array()
			row.resize(augmented_width)
			var state_index := _state_index(level, fail_streak)
			row[state_index] = 1.0
			row[state_count] = 1.0
			row[state_count + 1] = float(progression.enhancement_cost(rarity, level))
			var success_chance := 1.0 if fail_streak >= 9 else maxf(0.0, base_chance - 3.0 * level) / 100.0
			var failure_chance := 1.0 - success_chance
			var expected_level_loss := failure_chance * critical_chance if level > 0 else 0.0
			row[state_count + 2] = expected_level_loss
			if fail_streak < 9:
				_subtract_transition(row, level + 1, 0, success_chance)
				_subtract_transition(row, maxi(0, level - 1), fail_streak + 1,
					failure_chance * critical_chance)
				_subtract_transition(row, level, fail_streak + 1,
					failure_chance * (1.0 - critical_chance))
			else:
				_subtract_transition(row, level + 1, 0, 1.0)
			matrix.append(row)
	return _solve_augmented_system(matrix, state_count, augmented_width)

func _subtract_transition(row: PackedFloat64Array, level: int, fail_streak: int, probability: float) -> void:
	if level < LEVELS_PER_LINE and probability > 0.0:
		var index := _state_index(level, fail_streak)
		row[index] -= probability

func _state_index(level: int, fail_streak: int) -> int:
	return level * FAIL_STREAKS + fail_streak

func _solve_augmented_system(matrix: Array[PackedFloat64Array], size: int, width: int) -> PackedFloat64Array:
	for column in range(size):
		var pivot_index := column
		for candidate in range(column + 1, size):
			if absf(matrix[candidate][column]) > absf(matrix[pivot_index][column]):
				pivot_index = candidate
		if absf(matrix[pivot_index][column]) < 1e-12:
			return PackedFloat64Array()
		var temporary := matrix[column]
		matrix[column] = matrix[pivot_index]
		matrix[pivot_index] = temporary
		var pivot := matrix[column]
		var divisor: float = pivot[column]
		for item in range(column, width):
			pivot[item] /= divisor
		for row_index in range(size):
			if row_index == column:
				continue
			var row := matrix[row_index]
			var factor: float = row[column]
			if absf(factor) < 1e-12:
				continue
			for item in range(column, width):
				row[item] -= factor * pivot[item]
	var result := PackedFloat64Array()
	result.resize(3)
	for index in range(3):
		result[index] = matrix[0][size + index]
	return result
