extends SceneTree

const MUSIC_SCRIPT := preload("res://scripts/adaptive_survival_music.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(is_equal_approx(MUSIC_SCRIPT.target_volume_db_for(1, false), -24.0),
			"wave 1 uses the proposed base level")
	_check(MUSIC_SCRIPT.target_volume_db_for(24, false) > MUSIC_SCRIPT.target_volume_db_for(1, false),
			"music rises with the wave")
	_check(is_equal_approx(MUSIC_SCRIPT.target_volume_db_for(100, false), -20.0),
			"wave rise is capped")
	_check(is_equal_approx(MUSIC_SCRIPT.target_volume_db_for(100, true), -17.0),
			"boss accent is applied above the capped wave level")
	var early_gains: Array[float] = MUSIC_SCRIPT.target_stem_volumes_db_for(1, false)
	var late_gains: Array[float] = MUSIC_SCRIPT.target_stem_volumes_db_for(24, false)
	var boss_gains: Array[float] = MUSIC_SCRIPT.target_stem_volumes_db_for(24, true)
	_check(early_gains.size() == 5 and early_gains[3] < late_gains[3],
			"the arp layer grows with wave progression")
	_check(is_equal_approx(boss_gains[4], linear_to_db(MUSIC_SCRIPT.STEM_GAINS_LINEAR[4])),
			"boss layer is targeted only for boss context")

	var music := Node.new()
	music.set_script(MUSIC_SCRIPT)
	root.add_child(music)
	await process_frame
	var player := music.get_node_or_null("AdaptiveMusicPlayer") as AudioStreamPlayer
	var synchronized := player.stream as AudioStreamSynchronized if player != null else null
	_check(player != null and player.bus == "Music", "the synchronized arrangement routes through the Music bus")
	_check(player != null and player.playing, "the synchronized loop starts in the music player")
	_check(synchronized != null and synchronized.stream_count == 5,
			"the loop contains five synchronized stems")
	if synchronized == null:
		quit(1 if not _passed else 0)
		return
	for index in range(synchronized.stream_count):
		var stream := synchronized.get_sync_stream(index) as AudioStreamWAV
		_check(stream != null and stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_end > 0 and \
				stream.loop_end <= roundi(stream.get_length() * stream.mix_rate),
				"stem %d loops from its seamless boundary" % index)

	music.set_context(12, false, true)
	await create_timer(0.12).timeout
	var position_before_boss := player.get_playback_position() if player != null else 0.0
	var boss_before := synchronized.get_sync_stream_volume(4)
	music.set_context(12, true, true)
	var boss_immediately_after := synchronized.get_sync_stream_volume(4)
	_check(is_equal_approx(boss_before, boss_immediately_after),
			"boss context changes target a layer without an immediate volume jump")
	music._process(0.5)
	var boss_during_fade := synchronized.get_sync_stream_volume(4)
	_check(boss_during_fade > boss_before and boss_during_fade < boss_gains[4],
			"boss layer fades toward its synchronized target")
	_check(player != null and player.volume_db > -60.0 and player.volume_db < -17.0,
			"gameplay fades music toward its wave and boss level")
	await create_timer(0.12).timeout
	var position_during_boss := player.get_playback_position() if player != null else 0.0
	_check(player != null and player.playing and position_during_boss > position_before_boss,
			"boss context changes keep the same loop playing without restarting it")
	var volume_before_pause := player.volume_db if player != null else 0.0
	music.set_context(12, true, false)
	music._process(0.5)
	_check(is_equal_approx(music._target_volume_db, -60.0) and player != null and \
			player.volume_db < volume_before_pause and player.volume_db > -60.0,
			"pause or run end fades music toward silence")
	music.queue_free()
	await process_frame
	quit(1 if not _passed else 0)

var _passed := true

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_passed = false
	push_error("Adaptive survival music smoke failed: %s" % message)
