extends Node

const BLOCK_WIPE_SHADER := preload("res://shaders/ui_block_wipe.gdshader")
const TRANSITION_DURATION := 0.12
const WIPE_COLOR := Color("#080B18")

var is_transitioning := false
var _progress := 0.0
var _wipe: ColorRect
var _material: ShaderMaterial

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 127
	_wipe = ColorRect.new()
	_wipe.name = "BlockWipe"
	_wipe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wipe.color = Color.WHITE
	_wipe.mouse_filter = Control.MOUSE_FILTER_STOP
	_wipe.visible = false
	_material = ShaderMaterial.new()
	_material.shader = BLOCK_WIPE_SHADER
	_material.set_shader_parameter("wipe_color", WIPE_COLOR)
	_wipe.material = _material
	layer.add_child(_wipe)
	add_child(layer)

func _input(_event: InputEvent) -> void:
	if is_transitioning:
		get_viewport().set_input_as_handled()

func change_scene_to_file(path: String) -> Error:
	if not ResourceLoader.exists(path):
		return ERR_CANT_OPEN
	return await _transition(func() -> Error:
		return get_tree().change_scene_to_file(path)
	)

func change_scene_to_node(scene: Node) -> Error:
	if scene == null:
		return ERR_INVALID_PARAMETER
	return await _transition(func() -> Error:
		return get_tree().change_scene_to_node(scene)
	)

func _transition(change_scene: Callable) -> Error:
	if is_transitioning:
		return ERR_BUSY
	is_transitioning = true
	var effects_reduced: bool = Settings.reduced_visual_effects_enabled
	if not effects_reduced:
		_wipe.visible = true
		await _animate_to(1.0, TRANSITION_DURATION * 0.5)

	var scene_changed: Signal = get_tree().scene_changed
	var error: Error = change_scene.call()
	if error == OK:
		await scene_changed
		if not effects_reduced:
			await _animate_to(0.0, TRANSITION_DURATION * 0.5)

	_wipe.visible = false
	_set_progress(0.0)
	is_transitioning = false
	return error

func _animate_to(target: float, duration: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_ignore_time_scale()
	tween.tween_method(_set_progress, _progress, target, duration).set_trans(Tween.TRANS_LINEAR)
	await tween.finished

func _set_progress(value: float) -> void:
	_progress = value
	_material.set_shader_parameter("progress", value)
