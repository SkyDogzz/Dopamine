extends Control

signal play_requested

@onready var _play_button: Button = $Content/Columns/MenuPanel/Menu/PlayButton
@onready var _options_button: Button = $Content/Columns/MenuPanel/Menu/OptionsButton
@onready var _quit_button: Button = $Content/Columns/MenuPanel/Menu/QuitButton
@onready var _sandbox_button: Button = $Content/Columns/MenuPanel/Menu/SandboxButton
@onready var _sandbox_lab_button: Button = $Content/Columns/MenuPanel/Menu/SandboxLabButton
@onready var _menu_music: AudioStreamPlayer = $MenuMusic

var _options_panel: Control
var _options_panel_closing := false

func _ready() -> void:
	var menu_stream := _menu_music.stream as AudioStreamWAV
	if menu_stream != null:
		menu_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		menu_stream.loop_begin = 0
		menu_stream.loop_end = roundi(menu_stream.get_length() * menu_stream.mix_rate)
	_menu_music.play()
	_play_button.pressed.connect(_on_play_pressed)
	play_requested.connect(_open_survival_hub)
	_options_button.pressed.connect(_on_options_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_sandbox_button.pressed.connect(_on_sandbox_pressed)
	_sandbox_lab_button.pressed.connect(_on_sandbox_lab_pressed)
	_play_button.grab_focus()

func _on_play_pressed() -> void:
	play_requested.emit()

func _open_survival_hub() -> void:
	var error := await UITransitions.change_scene_to_file("res://scenes/survival_hub.tscn")
	if error != OK:
		push_error("Could not open Survival hub: %s" % error_string(error))

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_sandbox_pressed() -> void:
	var error := await UITransitions.change_scene_to_file("res://scenes/main.tscn")
	if error != OK:
		push_error("Could not open developer Sandbox: %s" % error_string(error))

func _on_sandbox_lab_pressed() -> void:
	var error := await UITransitions.change_scene_to_file("res://scenes/sandbox_lab.tscn")
	if error != OK:
		push_error("Could not open Sandbox Lab: %s" % error_string(error))

func _on_options_pressed() -> void:
	if _options_panel != null or _options_panel_closing:
		return
	var options_scene: PackedScene = load("res://scenes/options_panel.tscn")
	_options_panel = options_scene.instantiate() as Control
	_options_panel.name = "OptionsPanel"
	_options_panel.close_requested.connect(_on_options_close_requested)
	add_child(_options_panel)
	UITransitions.show_panel(_options_panel)

func _on_options_close_requested() -> void:
	var closing_panel := _options_panel
	_options_panel = null
	_options_panel_closing = true
	_options_button.grab_focus()
	await UITransitions.hide_panel(closing_panel)
	closing_panel.queue_free()
	_options_panel_closing = false
