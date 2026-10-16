extends SceneTree

class FakeProgression:
	extends RefCounted
	var awarded_runs := 0
	func can_save_profile() -> bool: return true
	func skill_bonus(stat_id: String) -> float:
		return 0.10 if stat_id == "max_hp_pct" else 0.02 if stat_id == "move_speed_pct" else \
			1.0 if stat_id == "critical_chance_pct" else 0.05
	func achievement_bonus(_stat_id: String) -> float: return 0.03
	func equipment_bonuses() -> Dictionary: return {"max_hp": 25.0, "damage_pct": 20.0}
	func equipped_unique_effects() -> Array[String]: return ["expanded_loadout"]
	func award_survival_run(_run_id: String, _wave: int, _victory: bool, _kills: int, _difficulty: String) -> Dictionary:
		awarded_runs += 1
		return {"ok": true}

func _initialize() -> void:
	var progression := FakeProgression.new()
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.mode_id = "armorless"
	session.progression_service = progression
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.skip_starting_weapon_choice = true
	root.add_child(session)
	await process_frame
	var expected_hp: float = session.simulation.initial_player_hp() * 1.10
	if not is_equal_approx(session.player_max_hp, expected_hp) or \
		not session._cached_equipment_bonuses.is_empty() or not session._cached_unique_effects.is_empty():
		_fail("Armorless should keep skill bonuses active while suppressing permanent equipment and unique effects")
		return
	if not is_equal_approx(session._cached_persistent_damage_multiplier, 1.08) or \
		not is_equal_approx(session.player.move_speed, 240.0 * 1.02) or \
		not is_equal_approx(session._critical_chance(), 1.0) or \
		not session.wave_director.endless_armorless or session.armorless_run_state == null or \
		not session.armorless_run_state.is_active():
		_fail("Armorless should preserve skill and achievement bonuses and initialize its endless run state")
		return
	session._finish_run(false)
	if progression.awarded_runs != 0 or session.armorless_run_state.is_active():
		_fail("Armorless must not award unvalidated permanent rewards and must clear its temporary state")
		return
	session.queue_free()
	await process_frame
	var draft_session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	draft_session.mode_id = "armorless"
	draft_session.progression_service = progression
	draft_session.wave_duration_seconds = 0.05
	draft_session.spawn_initial_enemy = false
	draft_session.skip_starting_weapon_choice = true
	draft_session.contact_damage_per_hit = 0.0
	root.add_child(draft_session)
	await process_frame
	var draft_deadline := Time.get_ticks_msec() + 2000
	while not draft_session._chest_open and Time.get_ticks_msec() < draft_deadline:
		await process_frame
	if not draft_session._chest_open or draft_session._active_chest_options.size() != 3 or \
		draft_session.armorless_run_state.flux() != 7 or not draft_session.simulation.snapshot()["paused"]:
		_fail("Completing an Armorless wave should grant Flux and pause for three temporary equipment options")
		return
	draft_session.wave_director.wave_duration_seconds = 30.0
	var draft_options: VBoxContainer = draft_session.get_node("HUD/ChestOverlay/ChestChoice/Content/Options")
	var first_option := draft_options.get_child(0) as Button
	var offer_icon := first_option.get_node("ContentMargin/OfferRow/OfferIcon") as TextureRect if first_option != null else null
	if first_option == null or not first_option.text.contains("TEMPORARY EQUIPMENT") or \
		offer_icon == null or offer_icon.texture == null:
		_fail("Armorless offers should explain that their equipment is temporary")
		return
	first_option.pressed.emit()
	if draft_session._chest_open or draft_session.armorless_run_state.temporary_equipment().size() != 1 or \
		progression.awarded_runs != 0:
		_fail("Choosing an Armorless option should equip it only for the run without awarding permanent progress")
		return
	var chosen_equipment: Dictionary = draft_session.armorless_run_state.temporary_equipment()[0]
	for line in chosen_equipment["stat_lines"]:
		var stat_id := str(line["stat_id"])
		var value: float = load("res://scripts/equipment_generator.gd").stat_value(
			stat_id, float(line["roll_percentile"]), int(line["enhancement_level"])
		)
		if not is_equal_approx(draft_session._equipment_bonus(stat_id), value):
			_fail("Selected Armorless equipment stats should affect run combat values")
			return
	draft_session.armorless_run_state.add_flux(100)
	draft_session._manually_paused = true
	draft_session.simulation.pause()
	draft_session.get_node("HUD/PauseOverlay").show()
	draft_session._open_run_inventory()
	await process_frame
	var inventory: Control = draft_session.get_node("HUD/RunInventoryPanel")
	var upgrade_button := _find_button_with_text(inventory, "UPGRADE  ·")
	if upgrade_button == null or upgrade_button.disabled:
		_fail("Armorless run inventory should expose a focused enhancement action when Flux covers its cost")
		return
	var flux_before_upgrade: int = draft_session.armorless_run_state.flux()
	var upgraded_line: Dictionary = chosen_equipment["stat_lines"][0]
	var upgrade_cost: int = draft_session.armorless_run_state.enhancement_cost(
		str(chosen_equipment["rarity"]), int(upgraded_line["enhancement_level"])
	)
	upgrade_button.pressed.emit()
	var feedback: String = inventory.get_node("Center/Panel/Content/Feedback").text
	if draft_session.armorless_run_state.flux() != flux_before_upgrade - upgrade_cost or \
		feedback.is_empty() or not draft_session.simulation.snapshot()["paused"]:
		_fail("Enhancing a temporary stat from pause should spend Flux, report the result and keep simulation frozen")
		return
	var focused_button := root.gui_get_focus_owner() as Button
	if focused_button == null or not focused_button.name.begins_with("Upgrade_"):
		_fail("After an enhancement result, focus should return to that stat's upgrade control")
		return
	draft_session._finish_run(false)
	if not draft_session.armorless_run_state.temporary_equipment().is_empty():
		_fail("Armorless equipment should be discarded when the run ends")
		return
	draft_session.queue_free()
	await process_frame
	print("survival_armorless_mode_smoke: passed progression isolation and mode setup")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _find_button_with_text(root_node: Node, text_fragment: String) -> Button:
	if root_node is Button and str(root_node.text).contains(text_fragment):
		return root_node as Button
	for child in root_node.get_children():
		var found := _find_button_with_text(child, text_fragment)
		if found != null:
			return found
	return null
