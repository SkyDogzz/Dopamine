extends SceneTree

const PROGRESSION := preload("res://scripts/progression_service.gd")
const POWDER_TIERS := ["basic", "refined", "pure", "prismatic"]
const TRIALS_PER_LEVEL := 20000
const ABSOLUTE_TOLERANCE := 0.01

func _initialize() -> void:
	var service: RefCounted = PROGRESSION.new(null, "probability-smoke")
	for tier_index in range(POWDER_TIERS.size()):
		var tier: String = POWDER_TIERS[tier_index]
		for level in range(10):
			service._rng.seed = 1000 + tier_index * 100 + level
			var successes := 0
			var critical_failures := 0
			for _trial in range(TRIALS_PER_LEVEL):
				var outcome: Dictionary = service._roll_enhancement(level, tier, 0)
				successes += int(outcome["success"])
				critical_failures += int(outcome["critical_failure"])
			var expected_success := maxf(0.0, PROGRESSION.PROPOSED_SUCCESS_CHANCE[tier] - 3.0 * level) / 100.0
			var expected_critical: float = (1.0 - expected_success) * \
				PROGRESSION.PROPOSED_CRITICAL_FAILURE_CHANCE[tier] / 100.0
			if absf(float(successes) / TRIALS_PER_LEVEL - expected_success) > ABSOLUTE_TOLERANCE or \
				absf(float(critical_failures) / TRIALS_PER_LEVEL - expected_critical) > ABSOLUTE_TOLERANCE:
				push_error("%s +%d rolls missed proposed success/critical-failure probabilities: %d/%d, %d/%d" % [
					tier, level, successes, TRIALS_PER_LEVEL, critical_failures, TRIALS_PER_LEVEL,
				])
				quit(1)
				return
		service._rng.seed = 42
		var pity: Dictionary = service._roll_enhancement(0, tier, 9)
		if not pity["success"] or pity["critical_failure"]:
			push_error("The tenth consecutive failed attempt must guarantee a clean success")
			quit(1)
			return
	print("enhancement_probability_smoke: passed 800000 seeded rolls against proposed tables and pity")
	quit(0)
