extends Control

signal play_requested

@onready var _play_button: Button = $Content/Card/Columns/Menu/PlayButton
@onready var _options_button: Button = $Content/Card/Columns/Menu/OptionsButton

var _options_panel: Control

func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_play_button.grab_focus()

func _on_play_pressed() -> void:
	play_requested.emit()

func _on_options_pressed() -> void:
	if _options_panel != null:
		return
	var options_scene: PackedScene = load("res://scenes/options_panel.tscn")
	_options_panel = options_scene.instantiate() as Control
	_options_panel.name = "OptionsPanel"
	_options_panel.close_requested.connect(_on_options_close_requested)
	add_child(_options_panel)

func _on_options_close_requested() -> void:
	_options_panel.queue_free()
	_options_panel = null
	call_deferred("_restore_options_focus")

func _restore_options_focus() -> void:
	if is_instance_valid(_options_button):
		_options_button.grab_focus()
