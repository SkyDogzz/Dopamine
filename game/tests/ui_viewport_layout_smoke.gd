extends SceneTree

class ProfileStub:
	extends RefCounted
	func load_profile() -> Dictionary:
		return {"ok": true, "profile": {"highest_unlocked_difficulty": "easy"}}

const SCENES := {
	"launch": "res://scenes/launch_menu.tscn",
	"options": "res://scenes/options_panel.tscn",
	"hub": "res://scenes/survival_hub.tscn",
	"equipment": "res://scenes/equipment_inventory_panel.tscn",
	"skills": "res://scenes/skill_tree_panel.tscn",
	"chest": "res://scenes/chest_choice.tscn",
	"pause": "res://scenes/pause_menu.tscn",
	"run_inventory": "res://scenes/run_inventory_panel.tscn",
	"result": "res://scenes/run_result_panel.tscn",
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for size in [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		for key in SCENES:
			var viewport := SubViewport.new()
			viewport.size = size
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			root.add_child(viewport)
			var scene: Control = load(SCENES[key]).instantiate()
			if key == "hub":
				scene.progression_service = ProfileStub.new()
			viewport.add_child(scene)
			if key == "equipment" or key == "skills":
				scene.call("present", {})
			elif key == "chest":
				scene.call("present", [
					{"id": "weapon:test", "title": "Test weapon", "description": "A sample upgrade"},
					{"id": "relic:test", "title": "Test relic", "description": "A sample relic"},
			])
			elif key == "run_inventory":
				var weapons: Array[Dictionary] = []
				var relics: Array[Dictionary] = []
				scene.call("show_items", weapons, relics)
			elif key == "pause":
				scene.get_node("Center/Panel").visible = true
			await process_frame
			await process_frame
			var bounds := Rect2(Vector2.ZERO, Vector2(size))
			for control in _visible_controls(scene):
				if control.size == Vector2.ZERO:
					continue
				if not bounds.encloses(control.get_global_rect()):
					_fail("%s control '%s' outside %s: %s" % [key, control.name, size, control.get_global_rect()])
					return
			viewport.remove_child(scene)
			scene.free()
			viewport.queue_free()
			await process_frame
	print("All active UI controls fit 640x360, 1280x720 and 1920x1080 viewports")
	quit()

func _visible_controls(root_control: Node) -> Array[Control]:
	var found: Array[Control] = []
	if root_control is Control and root_control.is_visible_in_tree():
		found.append(root_control)
	if root_control is ScrollContainer:
		return found
	for child in root_control.get_children():
		found.append_array(_visible_controls(child))
	return found

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
