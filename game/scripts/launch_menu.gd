extends Control

signal play_requested

@onready var _play_button: Button = $Content/Card/Columns/Menu/PlayButton
@onready var _options_button: Button = $Content/Card/Columns/Menu/OptionsButton
@onready var _quit_button: Button = $Content/Card/Columns/Menu/QuitButton
@onready var _sandbox_button: Button = $Content/Card/Columns/Menu/SandboxButton

var _options_panel: Control

func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	play_requested.connect(_open_survival_hub)
	_options_button.pressed.connect(_on_options_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_sandbox_button.pressed.connect(_on_sandbox_pressed)
	_play_button.grab_focus()

func _on_play_pressed() -> void:
	play_requested.emit()

func _open_survival_hub() -> void:
	var error := get_tree().change_scene_to_file("res://scenes/survival_hub.tscn")
	if error != OK:
		push_error("Could not open Survival hub: %s" % error_string(error))

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_sandbox_pressed() -> void:
	var error := get_tree().change_scene_to_file("res://scenes/main.tscn")
	if error != OK:
		push_error("Could not open developer Sandbox: %s" % error_string(error))

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
