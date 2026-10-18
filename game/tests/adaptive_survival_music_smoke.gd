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

	var music := Node.new()
	music.set_script(MUSIC_SCRIPT)
	root.add_child(music)
	await process_frame
	var player := music.get_node_or_null("AdaptiveMusicPlayer") as AudioStreamPlayer
	_check(player != null and player.playing, "the loop starts in the music player")
	_check(player != null and player.stream is AudioStreamOggVorbis and player.stream.loop,
			"the bundled OGG stream loops")
	music.set_context(12, false, true)
	await create_timer(0.1).timeout
	var position_before_boss := player.get_playback_position() if player != null else 0.0
	music.set_context(12, true, true)
	music._process(0.5)
	_check(player != null and player.volume_db > -60.0 and player.volume_db < -17.0,
			"gameplay fades music toward its wave and boss level")
	await create_timer(0.1).timeout
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
