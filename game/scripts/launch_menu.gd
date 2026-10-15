extends Control

signal play_requested

@onready var _play_button: Button = $Content/Card/Columns/Menu/PlayButton

func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_play_button.grab_focus()

func _on_play_pressed() -> void:
	play_requested.emit()
