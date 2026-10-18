extends SceneTree

const SERVICE_SCRIPT := preload("res://scripts/sfx_service.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var service := Node.new()
	service.set_script(SERVICE_SCRIPT)
	root.add_child(service)
	await process_frame
	if not service._named_streams.is_empty():
		for sound_id in ["weapon_lightning_conductor_fire", "weapon_lightning_conductor_impact", "damage_taken", "healing", "explosion", "victory", "defeat"]:
			if not service._named_streams.has(sound_id):
				_fail("Integrated named SFX should load %s" % sound_id)
				return
	service._named_streams["weapon_lightning_conductor_fire"] = [AudioStreamWAV.new()]
	service._streams["weapon_zap"] = [AudioStreamWAV.new()]
	if service._weapon_sound_family("lightning_conductor", "fire", "weapon_zap") != "weapon_lightning_conductor_fire":
		_fail("Available per-weapon fire should override the generic family")
		return
	service._named_streams["weapon_lightning_conductor_impact"] = []
	if service._weapon_sound_family("lightning_conductor", "impact", "hit_light") != "hit_light":
		_fail("Missing per-weapon impact should fall back to the existing hit family")
		return
	if service._weapon_sound_family("unknown", "fire", "weapon_shot") != "weapon_shot":
		_fail("Unknown weapon IDs should retain the generic fallback")
		return
	print("Specific weapon SFX selection smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
