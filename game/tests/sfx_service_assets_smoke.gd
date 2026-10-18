extends SceneTree

const SERVICE_SCRIPT := preload("res://scripts/sfx_service.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var service := Node.new()
	service.set_script(SERVICE_SCRIPT)
	root.add_child(service)
	await process_frame
	var families: Dictionary = service._streams
	if families.size() != 19:
		_fail("All existing SFX event families should remain mapped")
		return
	var stream_count := 0
	var empty_families := 0
	for family in families:
		var streams: Array = families[family]
		if streams.is_empty():
			empty_families += 1
		for stream in streams:
			stream_count += 1
			if not stream is AudioStreamWAV or not stream.resource_path.contains("/audio/original_procedural/sfx/"):
				_fail("SFX family %s must load an original procedural WAV" % str(family))
				return
	if stream_count == 0:
		if empty_families != families.size() or service.play("boss_telegraph") or service.play("unknown_family"):
			_fail("An empty asset root should remain silent and reject unknown SFX families")
			return
	elif stream_count != 38 and empty_families == 0:
		_fail("Expected all 38 original procedural SFX, got %d" % stream_count)
		return
	var telegraph_streams: Array = families["boss_telegraph"]
	if not telegraph_streams.is_empty() and not telegraph_streams[0].resource_path.ends_with("/boss_telegraph.wav"):
		_fail("Boss telegraph should load its dedicated priority family cue")
		return
	if service.play("unknown_family"):
		_fail("Unknown SFX families should fail without a broken path")
		return
	service._streams.clear()
	service._named_streams.clear()
	service.queue_free()
	await process_frame
	print("Original procedural SFX service smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
