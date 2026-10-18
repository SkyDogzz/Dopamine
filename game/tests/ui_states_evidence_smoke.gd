extends SceneTree

const OUTPUT_DIR := "res://../docs/art/evidence/2026-10-18/states"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for evidence_id in ["options", "pause", "pause-confirmation", "chest", "run-inventory", "run-result", "armorless-records", "sandbox", "sandbox-lab", "equipment-error", "skill-tree-error"]:
		var scene: Control
		match evidence_id:
			"options":
				scene = load("res://scenes/options_panel.tscn").instantiate()
			"pause":
				scene = load("res://scenes/pause_menu.tscn").instantiate()
			"pause-confirmation":
				scene = load("res://scenes/pause_menu.tscn").instantiate()
			"chest":
				scene = null
			"run-inventory":
				scene = load("res://scenes/run_inventory_panel.tscn").instantiate()
			"run-result":
				scene = null
			"armorless-records":
				scene = load("res://scenes/armorless_records_panel.tscn").instantiate()
			"sandbox":
				scene = load("res://scenes/main.tscn").instantiate()
			"sandbox-lab":
				scene = load("res://scenes/sandbox_lab.tscn").instantiate()
			"equipment-error":
				scene = load("res://scenes/equipment_inventory_panel.tscn").instantiate()
			"skill-tree-error":
				scene = load("res://scenes/skill_tree_panel.tscn").instantiate()
		var capture_root: Node
		if evidence_id in ["chest", "run-result"]:
			var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
			session.skip_starting_weapon_choice = true
			session.spawn_initial_enemy = false
			session.wave_spawning_enabled = false
			root.add_child(session)
			await process_frame
			capture_root = session
			if evidence_id == "chest":
				scene = session.get_node("HUD/ChestOverlay/ChestChoice") as Control
			else:
				var result_overlay: Control = session.get_node("HUD/RunResultOverlay")
				result_overlay.visible = true
				scene = session.get_node("HUD/RunResultOverlay/RunResultPanel") as Control
		elif evidence_id in ["equipment-error", "skill-tree-error"]:
			var save_service = load("res://scripts/save_service.gd").new("user://ui_states_evidence_smoke_context")
			var progression = load("res://scripts/progression_service.gd").new(save_service, "0")
			var hub: Control = load("res://scenes/survival_hub.tscn").instantiate()
			hub.progression_service = progression
			root.add_child(hub)
			await process_frame
			hub.add_child(scene)
			capture_root = hub
		else:
			if scene == null:
				_fail("Could not build evidence scene: %s" % evidence_id)
				return
			capture_root = scene
			root.add_child(scene)
		if scene == null:
			_fail("Could not build evidence scene: %s" % evidence_id)
			return
		await process_frame
		match evidence_id:
			"pause":
				scene.visible = true
				scene.get_node("Center/Panel/Content/ResumeButton").grab_focus()
			"pause-confirmation":
				scene.visible = true
				scene.get_node("ConfirmationOverlay").visible = true
				scene.get_node("ConfirmationOverlay/Center/Panel/Content/CancelButton").grab_focus()
			"chest":
				scene.present([
					{"id": "weapon:visual_probe", "title": "LIGHTNING CONDUCTOR", "description": "CHAIN 4 TARGETS · +18% DAMAGE", "icon": "res://assets/sprites/catalog/weapon_lightning_conductor.png"},
					{"id": "relic:visual_probe", "title": "STORM CORE", "description": "+12% CRITICAL CHANCE", "icon": "res://assets/sprites/catalog/relic_storm_core.png"},
					{"id": "weapon:visual_probe_2", "title": "MINIGUN", "description": "FIRING RATE +22%", "icon": "res://assets/sprites/catalog/weapon_minigun.png"},
				], 3, "VISUAL REVIEW · SAMPLE OFFER", true)
			"run-inventory":
				var weapons: Array[Dictionary] = [{"id": "lightning_conductor", "name": "LIGHTNING CONDUCTOR", "level": 4, "family": "weapon", "description": "CHAIN LIGHTNING · LV 4", "icon": "res://assets/sprites/catalog/weapon_lightning_conductor.png"}]
				var relics: Array[Dictionary] = [{"id": "storm_core", "name": "STORM CORE", "level": 2, "family": "relic", "description": "+8% CRITICAL CHANCE", "icon": "res://assets/sprites/catalog/relic_storm_core.png"}]
				scene.show_items(weapons, relics)
				scene.visible = true
			"run-result":
				scene.show_result(true, 8, 426.0, 913, {"ok": true, "essence": 42, "powder_basic": 3, "equipment": {"rarity": "legendary", "slot": "boots"}}, {}, true)
			"armorless-records":
				scene.present({"easy": {"wave": 14, "survival_time_seconds": 408.0, "kills": 721}})
			"equipment-error":
				scene.present_error()
			"skill-tree-error":
				scene.present({})
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image.get_size() != Vector2i(853, 480):
			_fail("Unexpected viewport while capturing %s: %s" % [evidence_id, image.get_size()])
			return
		var output := ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, evidence_id])
		if image.save_png(output) != OK:
			_fail("Could not save evidence capture: %s" % output)
			return
		print("UI state evidence capture: %s" % output)
		root.remove_child(capture_root)
		capture_root.queue_free()
		await process_frame
	quit()
func _fail(message: String) -> void:
	push_error(message)
	quit(1)
