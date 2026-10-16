extends SceneTree

class ProfileStub:
	extends RefCounted
	func load_profile() -> Dictionary:
		return {"ok": true, "profile": {"highest_unlocked_difficulty": "easy"}}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for size in [Vector2i(960, 600), Vector2i(1280, 800), Vector2i(1600, 900)]:
		var viewport := SubViewport.new()
		viewport.size = size
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var hub: Control = load("res://scenes/survival_hub.tscn").instantiate()
		hub.progression_service = ProfileStub.new()
		viewport.add_child(hub)
		await process_frame
		await process_frame
		var bounds := Rect2(Vector2.ZERO, Vector2(size))
		var content := (hub.get_node("Content") as Control).get_global_rect()
		var left := (hub.get_node("Content/Main/DifficultyCard") as Control).get_global_rect()
		var right := (hub.get_node("Content/Main/PreparationCard") as Control).get_global_rect()
		var launch := (hub.get_node("Content/Main/PreparationCard/Body/LaunchButton") as Control).get_global_rect()
		if not bounds.encloses(content) or not bounds.encloses(left) or not bounds.encloses(right) or \
			not bounds.encloses(launch) or left.intersects(right):
			_fail("Hub layout should fit and keep columns separate at %s: left=%s right=%s launch=%s" % [size, left, right, launch])
			return
		viewport.queue_free()
		await process_frame
	print("Survival hub fits 960x600, 1280x800 and 1600x900 viewports")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
