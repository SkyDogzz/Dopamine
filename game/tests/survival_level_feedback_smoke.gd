extends SceneTree

const IMPACT_SOURCES := {
	"lightning_conductor": "lightning_primary:smoke", "inferno_sprayer": "inferno_sprayer",
	"crimson_daggers": "crimson_dagger", "minigun": "minigun", "toxic_cloud": "toxic_cloud",
	"sawblades": "sawblades", "meteor_staff": "meteor_staff", "prism_laser": "prism_laser",
	"void_orb": "void_orb", "frost_nova": "frost_nova",
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	root.add_child(session)
	await process_frame
	session._on_chest_option_selected("weapon:minigun")
	var feedback: PanelContainer = session.get_node("HUD/ItemLevelFeedback")
	var label: Label = session.get_node("HUD/ItemLevelFeedback/FeedbackLabel")
	if not feedback.visible or not label.text.contains("ACQUIRED") or not label.text.contains("MINIGUN") or not label.text.ends_with("LV 1"):
		_fail("New weapons should show a visible level 1 acquisition notice")
		return
	for expected_level in range(2, 6):
		session._on_chest_option_selected("weapon:minigun")
		if not feedback.visible or not label.text.contains("LEVEL UP") or not label.text.ends_with("LV %d" % expected_level):
			_fail("Weapon level %d should appear in the run HUD feedback" % expected_level)
			return
	for weapon_id in IMPACT_SOURCES:
		var previous_impact_scale := 0.0
		for expected_level in range(1, 6):
			session.loadout._weapon_levels[weapon_id] = expected_level
			session._weapon_impacts.clear()
			session._add_weapon_impact(IMPACT_SOURCES[weapon_id], Vector2.ZERO, false)
			var impact: Dictionary = session._weapon_impacts.back()
			var impact_scale: float = session._weapon_impact_level_scale(int(impact.get("level", 0)))
			if int(impact.get("level", 0)) != expected_level or impact_scale <= previous_impact_scale:
				_fail("%s level %d should produce a stronger weapon-specific impact visual" % [weapon_id, expected_level])
				return
			previous_impact_scale = impact_scale
	session._on_chest_option_selected("relic:overdrive_engine")
	if not feedback.visible or not label.text.contains("ACQUIRED") or not label.text.contains("OVERDRIVE ENGINE") or not label.text.ends_with("LV 1"):
		_fail("New relics should show a visible level 1 acquisition notice")
		return
	for expected_level in range(2, 6):
		session._on_chest_option_selected("relic:overdrive_engine")
		if not feedback.visible or not label.text.contains("LEVEL UP") or not label.text.contains("OVERDRIVE ENGINE") or not label.text.ends_with("LV %d" % expected_level):
			_fail("Relic level %d should appear in the run HUD feedback" % expected_level)
			return
	var expires_at: float = session._item_level_feedback_expires_at
	session._refresh_hud({"paused": true, "simulation_time": expires_at - 0.1})
	if not feedback.visible:
		_fail("Level feedback should remain visible while simulation time is paused")
		return
	for size in [Vector2i(640, 360), Vector2i(1280, 800), Vector2i(1920, 1080)]:
		root.size = size
		await process_frame
		var bounds := Rect2(Vector2.ZERO, session.get_viewport().get_visible_rect().size)
		if not bounds.encloses(feedback.get_global_rect()) or not feedback.get_global_rect().encloses(label.get_global_rect()):
			_fail("Level feedback should remain readable inside viewport %s" % size)
			return
	session._refresh_hud({"paused": false, "simulation_time": expires_at + 0.01})
	if feedback.visible:
		_fail("Level feedback should disappear after its simulation-time duration")
		return
	session.queue_free()
	await process_frame
	print("Survival level feedback smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
