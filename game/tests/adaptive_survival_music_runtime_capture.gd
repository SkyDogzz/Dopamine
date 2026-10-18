extends SceneTree

const MUSIC_SCRIPT := preload("res://scripts/adaptive_survival_music.gd")
const OUTPUT_PATH := "res://../docs/art/evidence/2026-10-18/adaptive-music-runtime-capture.wav"

var _events: Array[Dictionary] = []
var _capture_started_usec := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus < 0:
		push_error("Master audio bus is unavailable")
		quit(1)
		return
	var recorder := AudioEffectRecord.new()
	AudioServer.add_bus_effect(master_bus, recorder)
	recorder.set_recording_active(true)
	_capture_started_usec = Time.get_ticks_usec()

	var music := Node.new()
	music.set_script(MUSIC_SCRIPT)
	root.add_child(music)
	await process_frame
	await _stage(music, "wave-1 gameplay", 1, false, true, 1.4)
	_play_sfx("weapon_shot")
	await _stage(music, "wave-8 gameplay", 8, false, true, 1.7)
	_play_sfx("xp_pickup")
	await _stage(music, "wave-16 gameplay", 16, false, true, 1.7)
	_play_sfx("boss_telegraph")
	await _stage(music, "wave-24 boss", 24, true, true, 2.2)
	_play_sfx("boss_phase")
	await _stage(music, "boss phase", 24, true, true, 1.7)
	_play_sfx("ui_pause")
	await _stage(music, "paused", 24, true, false, 1.2)
	await _stage(music, "resumed", 24, true, true, 1.0)
	_play_sfx("boss_defeat")
	await _stage(music, "run end", 24, false, false, 1.4)

	recorder.set_recording_active(false)
	var recording := recorder.get_recording()
	if recording == null or recording.data.is_empty():
		push_error("Godot did not record audio from the Master bus")
		AudioServer.remove_bus_effect(master_bus, AudioServer.get_bus_effect_count(master_bus) - 1)
		quit(1)
		return
	var output_absolute := ProjectSettings.globalize_path(OUTPUT_PATH)
	var output_dir := output_absolute.get_base_dir()
	var mkdir_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
		push_error("Could not create evidence directory: %s" % error_string(mkdir_error))
		quit(1)
		return
	var save_error := recording.save_to_wav(output_absolute)
	AudioServer.remove_bus_effect(master_bus, AudioServer.get_bus_effect_count(master_bus) - 1)
	music.queue_free()
	if save_error != OK:
		push_error("Could not save runtime audio recording: %s" % error_string(save_error))
		quit(1)
		return
	print("Master bus capture: %s | %.2f s | %d Hz | %s | %d bytes" % [
		output_absolute, recording.get_length(), recording.mix_rate,
		"stereo" if recording.stereo else "mono", recording.data.size()
	])
	for event in _events:
		print("AUDIO_EVENT %.3f %s" % [float(event.time), str(event.name)])
	quit()

func _stage(music: Node, label: String, wave: int, boss: bool, gameplay: bool, seconds: float) -> void:
	music.set_context(wave, boss, gameplay)
	_mark(label)
	await create_timer(seconds).timeout

func _play_sfx(family: String) -> void:
	var sfx := root.get_node_or_null("Sfx")
	if sfx == null or not sfx.play(family):
		push_error("Could not play runtime SFX family: %s" % family)
	else:
		_mark("SFX " + family)

func _mark(label: String) -> void:
	_events.append({"time": float(Time.get_ticks_usec() - _capture_started_usec) / 1000000.0, "name": label})
