extends SceneTree

const STATE_SCRIPT := preload("res://scripts/armorless_run_state.gd")

func _initialize() -> void:
	var state = STATE_SCRIPT.new()
	state.begin_run()
	var duplicate_slot_offer := _equipment("helmet", "armorless_helmet")
	var draft: Array[Dictionary] = [
		duplicate_slot_offer,
		_equipment("helmet", "armorless_helmet_2"),
		_equipment("boots", "armorless_boots"),
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
	state.end_run()
	if state.is_active() or not state.temporary_equipment().is_empty() or state.flux() != 0:
		_fail("Ending an Armorless run should discard its equipment and Flux")
		return
	print("armorless_run_state_smoke: passed temporary draft and cleanup")
	quit(0)

func _equipment(slot: String, instance_id: String) -> Dictionary:
	return {"slot": slot, "instance_id": instance_id, "stat_lines": [], "rarity": "normal"}

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
