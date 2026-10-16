extends SceneTree

const STATE_SCRIPT := preload("res://scripts/armorless_run_state.gd")

func _initialize() -> void:
	if not _verify_proposed_enhancement_failures():
		return
	var state = STATE_SCRIPT.new()
	state.begin_run()
	var duplicate_slot_offer := _equipment("helmet", "armorless_helmet", false)
	var draft: Array[Dictionary] = [
		duplicate_slot_offer,
		_equipment("helmet", "armorless_helmet_2", true),
		_equipment("boots", "armorless_boots", false),
	]
	if not state.set_draft(draft) or state.current_draft().size() != 3:
		_fail("Armorless should accept exactly three independent equipment offers, including duplicate slots")
		return
	if not state.select_draft_option(1) or state.temporary_equipment().size() != 1 or \
		state.temporary_equipment()[0]["instance_id"] != "armorless_helmet_2":
		_fail("Selecting a draft option should retain only the selected temporary item")
		return
	if not state.current_draft().is_empty() or state.select_draft_option(0):
		_fail("A draft should be consumed exactly once")
		return
	if not state.add_flux(17) or state.flux() != 17 or state.spend_flux(18) or \
		not state.spend_flux(7) or state.flux() != 10:
		_fail("Flux should be temporary and reject spending beyond the run balance")
		return
	if state.award_wave_flux(1) != 7 or state.award_wave_flux(1) != 0 or state.flux() != 17:
		_fail("Armorless wave Flux should use the proposed reward formula and award each wave once")
		return
	var enhancement: Dictionary = state.enhance_equipment("armorless_helmet_2", "damage_pct")
	var enhanced_item: Dictionary = state.temporary_equipment()[0]
	if not enhancement.get("ok", false) or not enhancement.get("success", false) or \
		int(enhanced_item["stat_lines"][0]["enhancement_level"]) != 1 or state.flux() != 12:
		_fail("A temporary enhancement should consume proposed Flux cost and raise the line by one level")
		return
	if not state.set_draft([
		_equipment("helmet", "replacement_helmet", false),
		_equipment("ring", "replacement_ring", false),
		_equipment("boots", "replacement_boots", false),
	]) or not state.select_draft_option(0) or state.temporary_equipment().size() != 1 or \
		state.temporary_equipment()[0]["instance_id"] != "replacement_helmet":
		_fail("Selecting equipment for an occupied slot should replace its previous temporary item")
		return
	state.end_run()
	if state.is_active() or not state.temporary_equipment().is_empty() or state.flux() != 0:
		_fail("Ending an Armorless run should discard its equipment and Flux")
		return
	print("armorless_run_state_smoke: passed temporary draft and cleanup")
	quit(0)

func _verify_proposed_enhancement_failures() -> bool:
	if STATE_SCRIPT.enhancement_cost("normal", 0) != 5 or \
		STATE_SCRIPT.enhancement_cost("normal", 1) != 8 or \
		STATE_SCRIPT.enhancement_cost("mythic", 0) != 13:
		_fail("Armorless enhancement costs should follow the proposed level and rarity formula")
		return false
	var saw_failure := false
	var saw_critical_failure := false
	for seed_value in range(1, 129):
		var state = STATE_SCRIPT.new(seed_value)
		state.begin_run()
		if not state.set_draft([
			_equipment("helmet", "failure_%d_a" % seed_value, false),
			_equipment("armor", "failure_%d_b" % seed_value, false),
			_equipment("boots", "failure_%d_c" % seed_value, false),
		]) or not state.select_draft_option(0):
			_fail("A valid draft should be selectable for enhancement outcome checks")
			return false
		state.add_flux(100)
		var result: Dictionary = state.enhance_equipment("failure_%d_a" % seed_value, "damage_pct")
		if not result.get("ok", false) or state.flux() != 95:
			_fail("Enhancement attempts should consume the proposed cost on success and failure: %s flux=%d" % [str(result), state.flux()])
			return false
		if not result["success"]:
			saw_failure = true
			var line: Dictionary = state.temporary_equipment()[0]["stat_lines"][0]
			if int(line["fail_streak"]) != 1:
				_fail("Failed attempts should increment their temporary pity streak")
				return false
			if result["critical_failure"]:
				saw_critical_failure = true
	if not saw_failure or not saw_critical_failure:
		_fail("Seeded checks should cover ordinary and critical enhancement failure paths")
		return false
	return true

func _equipment(slot: String, instance_id: String, guaranteed_enhancement: bool) -> Dictionary:
	var lines: Array[Dictionary] = [{
		"stat_id": "damage_pct", "enhancement_level": 0,
		"fail_streak": 9 if guaranteed_enhancement else 0, "roll_percentile": 0.5,
	}]
	return {"slot": slot, "instance_id": instance_id, "stat_lines": lines, "rarity": "normal"}

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
