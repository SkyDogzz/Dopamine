extends SceneTree

class FakeProgression:
	extends RefCounted
	var awarded_runs := 0
	func can_save_profile() -> bool: return true
	func skill_bonus(stat_id: String) -> float: return 0.10 if stat_id == "max_hp_pct" else 0.05
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
	print("survival_armorless_mode_smoke: passed progression isolation and mode setup")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
