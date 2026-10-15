extends Control

signal close_requested

@onready var _fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _volume_value: Label = %VolumeValue
@onready var _back_button: Button = %BackButton
@onready var _settings: SettingsService = get_node("/root/Settings")

var _syncing_controls := false

func _ready() -> void:
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	_volume_slider.value_changed.connect(_on_volume_changed)
	_back_button.pressed.connect(_on_back_pressed)
	_settings.settings_changed.connect(_sync_from_settings)
	_sync_from_settings()
	_fullscreen_toggle.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		get_viewport().set_input_as_handled()

func _on_fullscreen_toggled(enabled: bool) -> void:
	if not _syncing_controls:
		_settings.set_fullscreen_enabled(enabled)

func _on_volume_changed(value: float) -> void:
	_volume_value.text = "%d%%" % roundi(value)
	if not _syncing_controls:
		_settings.set_master_volume_percent(value)

func _on_back_pressed() -> void:
	close_requested.emit()

func _sync_from_settings() -> void:
	_syncing_controls = true
	_fullscreen_toggle.button_pressed = _settings.fullscreen_enabled
	_volume_slider.value = _settings.master_volume_percent
	_volume_value.text = "%d%%" % roundi(_settings.master_volume_percent)
	_syncing_controls = false
