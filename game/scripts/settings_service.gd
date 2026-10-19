class_name SettingsService
extends Node

signal settings_changed

const CONFIG_PATH := "user://settings.cfg"
const CONFIG_SECTION := "settings"
const DEFAULT_FULLSCREEN_ENABLED := false
const DEFAULT_MASTER_VOLUME_PERCENT := 100.0
const DEFAULT_REDUCED_VISUAL_EFFECTS_ENABLED := false
const SILENT_VOLUME_DB := -80.0

var fullscreen_enabled: bool:
	get:
		return _fullscreen_enabled

var master_volume_percent: float:
	get:
		return _master_volume_percent

var reduced_visual_effects_enabled: bool:
	get:
		return _reduced_visual_effects_enabled

var _fullscreen_enabled := DEFAULT_FULLSCREEN_ENABLED
var _master_volume_percent := DEFAULT_MASTER_VOLUME_PERCENT
var _reduced_visual_effects_enabled := DEFAULT_REDUCED_VISUAL_EFFECTS_ENABLED

var _config_path: String

func _init(config_path: String = CONFIG_PATH) -> void:
	_config_path = config_path

func _ready() -> void:
	_load_settings()
	_apply_settings()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		set_fullscreen_enabled(not _fullscreen_enabled)
		get_viewport().set_input_as_handled()

func set_fullscreen_enabled(enabled: bool) -> void:
	_fullscreen_enabled = enabled
	_apply_fullscreen()
	_save_settings()
	settings_changed.emit()

func set_master_volume_percent(value: float) -> void:
	_master_volume_percent = clampf(value, 0.0, 100.0) if is_finite(value) else DEFAULT_MASTER_VOLUME_PERCENT
	_apply_master_volume()
	_save_settings()
	settings_changed.emit()

func set_reduced_visual_effects_enabled(enabled: bool) -> void:
	_reduced_visual_effects_enabled = enabled
	_save_settings()
	settings_changed.emit()

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(_config_path) != OK:
		_set_defaults()
		return

	var stored_fullscreen: Variant = config.get_value(CONFIG_SECTION, "fullscreen_enabled", DEFAULT_FULLSCREEN_ENABLED)
	var stored_volume: Variant = config.get_value(CONFIG_SECTION, "master_volume_percent", DEFAULT_MASTER_VOLUME_PERCENT)
	var stored_reduced_visual_effects: Variant = config.get_value(
		CONFIG_SECTION, "reduced_visual_effects_enabled", DEFAULT_REDUCED_VISUAL_EFFECTS_ENABLED)
	_fullscreen_enabled = stored_fullscreen if typeof(stored_fullscreen) == TYPE_BOOL else DEFAULT_FULLSCREEN_ENABLED
	_reduced_visual_effects_enabled = stored_reduced_visual_effects if typeof(stored_reduced_visual_effects) == TYPE_BOOL else DEFAULT_REDUCED_VISUAL_EFFECTS_ENABLED
	if typeof(stored_volume) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(stored_volume)) and float(stored_volume) >= 0.0 and float(stored_volume) <= 100.0:
		_master_volume_percent = float(stored_volume)
	else:
		_master_volume_percent = DEFAULT_MASTER_VOLUME_PERCENT

func _set_defaults() -> void:
	_fullscreen_enabled = DEFAULT_FULLSCREEN_ENABLED
	_master_volume_percent = DEFAULT_MASTER_VOLUME_PERCENT
	_reduced_visual_effects_enabled = DEFAULT_REDUCED_VISUAL_EFFECTS_ENABLED

func _apply_settings() -> void:
	_apply_fullscreen()
	_apply_master_volume()

func _apply_fullscreen() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if _fullscreen_enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func _apply_master_volume() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus < 0:
		return
	var volume_db := SILENT_VOLUME_DB if _master_volume_percent <= 0.0 else linear_to_db(_master_volume_percent / 100.0)
	AudioServer.set_bus_volume_db(master_bus, volume_db)

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(CONFIG_SECTION, "fullscreen_enabled", _fullscreen_enabled)
	config.set_value(CONFIG_SECTION, "master_volume_percent", _master_volume_percent)
	config.set_value(CONFIG_SECTION, "reduced_visual_effects_enabled", _reduced_visual_effects_enabled)
	var absolute_path := ProjectSettings.globalize_path(_config_path)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		push_error("Could not create settings directory: %s" % error_string(directory_error))
		return
	var save_error := config.save(_config_path)
	if save_error != OK:
		push_error("Could not save settings: %s" % error_string(save_error))
