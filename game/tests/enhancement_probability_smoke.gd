extends SceneTree

const PROGRESSION := preload("res://scripts/progression_service.gd")
const POWDER_TIERS := ["basic", "refined", "pure", "prismatic"]
const TRIALS_PER_LEVEL := 20000
const CRITICAL_FAILURE_TRIALS := 100000

func _initialize() -> void:
	var service: RefCounted = PROGRESSION.new(null, "probability-smoke")
	for tier_index in range(POWDER_TIERS.size()):
		var tier: String = POWDER_TIERS[tier_index]
		for level in range(10):
			service._rng.seed = 1000 + tier_index * 100 + level
			var successes := 0
			for _trial in range(TRIALS_PER_LEVEL):
				var outcome: Dictionary = service._roll_enhancement(level, tier, 0)
				successes += int(outcome["success"])
			var expected_success := maxf(0.0, PROGRESSION.PROPOSED_SUCCESS_CHANCE[tier] - 3.0 * level) / 100.0
			var success_tolerance := 5.0 * sqrt(expected_success * (1.0 - expected_success) / TRIALS_PER_LEVEL)
			if absf(float(successes) / TRIALS_PER_LEVEL - expected_success) > success_tolerance:
				push_error("%s +%d rolls missed proposed success probability: %d/%d" % [
					tier, level, successes, TRIALS_PER_LEVEL,
				])
				quit(1)
				return
		service._rng.seed = 42
		var pity: Dictionary = service._roll_enhancement(0, tier, 9)
		if not pity["success"] or pity["critical_failure"]:
			push_error("The tenth consecutive failed attempt must guarantee a clean success")
			quit(1)
			return
	for tier_index in range(POWDER_TIERS.size()):
		var tier: String = POWDER_TIERS[tier_index]
		service._rng.seed = 9000 + tier_index
		var critical_failures := 0
		for _trial in range(CRITICAL_FAILURE_TRIALS):
			critical_failures += int(service._roll_critical_failure(tier))
		var expected_chance: float = PROGRESSION.PROPOSED_CRITICAL_FAILURE_CHANCE[tier] / 100.0
		var measured_chance := float(critical_failures) / CRITICAL_FAILURE_TRIALS
		var five_sigma := 5.0 * sqrt(expected_chance * (1.0 - expected_chance) / CRITICAL_FAILURE_TRIALS)
		if absf(measured_chance - expected_chance) > five_sigma:
			push_error("%s critical failures missed the proposed conditional rate: %d/%d" % [
				tier, critical_failures, CRITICAL_FAILURE_TRIALS,
			])
			quit(1)
			return
	print("enhancement_probability_smoke: passed 800000 success rolls, 400000 conditional critical rolls and pity")
	quit(0)
