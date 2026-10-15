extends SceneTree

const SERVICE_PATH := "res://scripts/settings_service.gd"
const CONFIG_PATH := "user://ui_settings_smoke/settings.cfg"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ResourceLoader.exists(SERVICE_PATH):
		_fail("Settings service script is missing")
		return
	var settings_script: Script = load(SERVICE_PATH)
	if settings_script == null:
		_fail("Settings service script could not be loaded")
		return
	var config_absolute_path := ProjectSettings.globalize_path(CONFIG_PATH)
	DirAccess.make_dir_recursive_absolute(config_absolute_path.get_base_dir())
	if FileAccess.file_exists(CONFIG_PATH):
		DirAccess.remove_absolute(config_absolute_path)

	var settings = settings_script.new(CONFIG_PATH)
	root.add_child(settings)
	await process_frame
	if not settings.has_method("set_fullscreen_enabled") or not settings.has_method("set_master_volume_percent"):
		_fail("Settings service should expose the two bounded setters")
		return
	if settings.get("fullscreen_enabled") != false or settings.get("master_volume_percent") != 100.0:
		_fail("Missing preferences should use windowed and 100 percent volume defaults")
		return

	settings.set_fullscreen_enabled(true)
	settings.set_master_volume_percent(-10.0)
	if settings.get("master_volume_percent") != 0.0:
		_fail("Volume setter should clamp below zero")
		return
	settings.set_master_volume_percent(150.0)
	if settings.get("master_volume_percent") != 100.0:
		_fail("Volume setter should clamp above one hundred")
		return
	settings.set_master_volume_percent(INF)
	if settings.get("master_volume_percent") != 100.0:
		_fail("Non-finite volume should fall back to the default")
		return
	settings.set_master_volume_percent(0.0)
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus < 0 or not is_finite(AudioServer.get_bus_volume_db(master_bus)) or not is_equal_approx(AudioServer.get_bus_volume_db(master_bus), -80.0):
		_fail("Zero volume should map to a finite Master bus level")
		return
	settings.set_master_volume_percent(63.0)
	await process_frame
	var restored = settings_script.new(CONFIG_PATH)
	root.add_child(restored)
	await process_frame
	if restored.get("fullscreen_enabled") != true or restored.get("master_volume_percent") != 63.0:
		_fail("Settings should persist and reload both supported preferences")
		return

	var invalid_config := ConfigFile.new()
	invalid_config.set_value("settings", "fullscreen_enabled", "invalid")
	invalid_config.set_value("settings", "master_volume_percent", 1000.0)
	if invalid_config.save(CONFIG_PATH) != OK:
		_fail("Smoke could not write its isolated invalid settings fixture")
		return
	var invalid = settings_script.new(CONFIG_PATH)
	root.add_child(invalid)
	await process_frame
	if invalid.get("fullscreen_enabled") != false or invalid.get("master_volume_percent") != 100.0:
		_fail("Invalid preferences should fall back to safe defaults")
		return

	print("Settings service defaults, validation and persistence passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
