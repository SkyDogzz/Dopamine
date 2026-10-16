extends Node

const HOVER_SCALE := Vector2(1.04, 1.04)
const NORMAL_SCALE := Vector2.ONE

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is Button:
		_attach_button.call_deferred(node)

func _attach_button(button: Button) -> void:
	if not is_instance_valid(button) or button.has_meta("ui_feedback_attached"):
		return
	button.set_meta("ui_feedback_attached", true)
	button.mouse_entered.connect(_set_hover.bind(button, true))
	button.mouse_exited.connect(_set_hover.bind(button, false))
	button.focus_entered.connect(_on_focus_entered)
	button.button_down.connect(_set_pressed.bind(button, true))
	button.button_up.connect(_set_pressed.bind(button, false))
	_center_pivot.call_deferred(button)

func _center_pivot(button: Button) -> void:
	if is_instance_valid(button):
		button.pivot_offset = button.size * 0.5

func _set_hover(button: Button, hovered: bool) -> void:
	if not is_instance_valid(button):
		return
	if hovered:
		Sfx.play("ui_focus")
	var tween := button.create_tween()
	tween.tween_property(button, "scale", HOVER_SCALE if hovered else NORMAL_SCALE, 0.06)

func _set_pressed(button: Button, pressed: bool) -> void:
	if not is_instance_valid(button):
		return
	if pressed:
		Sfx.play("ui_confirm")
	var offset_active := bool(button.get_meta("ui_pressed_offset", false))
	if pressed and not offset_active:
		button.position.y += 2.0
		button.set_meta("ui_pressed_offset", true)
	elif not pressed and offset_active:
		button.position.y -= 2.0
		button.set_meta("ui_pressed_offset", false)

func _on_focus_entered() -> void:
	Sfx.play("ui_focus")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Sfx.play("ui_back")
