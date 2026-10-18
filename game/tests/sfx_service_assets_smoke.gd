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
	for family in families:
		var streams: Array = families[family]
		if streams.is_empty():
			_fail("SFX family %s has no streams" % str(family))
			return
		for stream in streams:
			stream_count += 1
			if not stream is AudioStreamWAV or not stream.resource_path.contains("/audio/original_procedural/sfx/"):
				_fail("SFX family %s must load an original procedural WAV" % str(family))
				return
	if stream_count != 38:
		_fail("Expected all 38 original procedural SFX, got %d" % stream_count)
		return
	if not service.play("boss_telegraph") or service.play("unknown_family"):
		_fail("Known SFX should play and unknown families should fail without a broken path")
		return
	var telegraph_voice := false
	for player in service._players:
		if player.playing and player.stream.resource_path.ends_with("/boss_telegraph.wav"):
			telegraph_voice = true
	if not telegraph_voice:
		_fail("Boss telegraph should use its dedicated priority family cue")
		return
	service.queue_free()
	await process_frame
	print("Original procedural SFX service smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
