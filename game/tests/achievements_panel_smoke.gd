extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var tiers: Array[Dictionary] = [
		{"id": "bronze", "threshold": 100, "rewards": {"damage_pct": 0.005}},
		{"id": "silver", "threshold": 500, "rewards": {"damage_pct": 0.01}},
		{"id": "gold", "threshold": 1000, "rewards": {"max_hp_pct": 0.02}},
		{"id": "diamond", "threshold": 5000, "rewards": {"move_speed_pct": 0.03}},
	]
	var catalog: Array[Dictionary] = [
		{"id": "exterminator", "category": "combat", "name": "Exterminator", "secret": false, "metric": "total_kills", "tiers": tiers},
		{"id": "hidden", "category": "secrets", "name": "Hidden", "secret": true, "metric": "chaos_victories", "tiers": tiers},
	]
	var panel := load("res://scenes/achievements_panel.tscn").instantiate() as Control
	root.add_child(panel)
	panel.present(catalog, {"achievement_progress": {
		"metrics": {"total_kills": 250, "chaos_victories": 0},
		"tiers": {"exterminator": 1, "hidden": 0},
	}})
	await process_frame
	var entries: VBoxContainer = panel.get_node("Center/Panel/Content/Body/Entries")
	var objective: Label = entries.get_child(0).get_node("AchievementObjective")
	var progress: Label = entries.get_child(0).get_node("AchievementProgress")
	var bar: ProgressBar = entries.get_child(0).get_node("AchievementProgressBar")
	var reward: Label = entries.get_child(0).get_node("AchievementReward")
	if entries.get_child_count() != 2 or not objective.text.contains("ENNEMIS ÉLIMINÉS") or \
		not objective.text.contains("PROCHAIN PALIER ARGENT") or progress.text != "PROGRESSION : 250 / 500" or \
		bar.value != 250.0 or not reward.text.contains("OBTENU · DÉGÂTS +0.50%") or \
		not reward.text.contains("À GAGNER · DÉGÂTS +1.00%"):
		_fail("Achievement cards should explain the objective, numeric progress, and earned/next rewards")
		return
	var hidden: VBoxContainer = entries.get_child(1)
	if hidden.get_node("Heading/AchievementName").text != "SUCCÈS SECRET  ·  À DÉBLOQUER" or \
		not hidden.get_node("AchievementObjective").text.contains("révéler") or \
		hidden.get_node("AchievementProgressBar").visible or not hidden.get_node("AchievementReward").text.is_empty():
		_fail("Undiscovered secret achievements should hide their objective progress and rewards")
		return
	var intro: Label = panel.get_node("Center/Panel/Content/Intro")
	if not intro.text.contains("PALIERS OBTENUS : 1 / 8") or not intro.text.contains("SUCCÈS RÉVÉLÉS : 1 / 2"):
		_fail("Achievement summary should count earned tiers and revealed families")
		return
	print("Achievements panel clarity smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
