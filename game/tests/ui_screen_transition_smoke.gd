extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var transitions := root.get_node_or_null("UITransitions")
	if transitions == null or not transitions.has_method("change_scene_to_file"):
		_fail("The shared UI transition service should be available")
		return
	var settings := root.get_node_or_null("Settings")
	if settings == null:
		_fail("The settings service should be available to UI transitions")
		return
	var starting_scene: Control = load("res://scenes/launch_menu.tscn").instantiate()
	root.add_child(starting_scene)
	current_scene = starting_scene
	await process_frame

	settings.set_reduced_visual_effects_enabled(false)
	var started_at := Time.get_ticks_msec()
	var scene_error: Error = await transitions.change_scene_to_file("res://scenes/survival_hub.tscn")
	var transition_elapsed := Time.get_ticks_msec() - started_at
	if scene_error != OK or current_scene == null or current_scene.scene_file_path != "res://scenes/survival_hub.tscn":
		_fail("The transition should open the requested launch screen")
		return
	if transition_elapsed < 70 or transition_elapsed >= 1000 or transitions.is_transitioning:
		_fail("The pixel wipe should finish its 120 ms transition before returning (elapsed %d ms)" % transition_elapsed)
		return

	settings.set_reduced_visual_effects_enabled(true)
	started_at = Time.get_ticks_msec()
	var reduced_effects_target := Control.new()
	reduced_effects_target.name = "ReducedEffectsTarget"
	await transitions.change_scene_to_node(reduced_effects_target)
	transition_elapsed = Time.get_ticks_msec() - started_at
	if current_scene != reduced_effects_target:
		_fail("Reduced effects should still open the requested screen")
		return
	if transition_elapsed >= 100 or transitions.is_transitioning:
		_fail("Reduced visual effects should skip the decorative transition")
		return

	print("UI screen transition and reduced-effects smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
