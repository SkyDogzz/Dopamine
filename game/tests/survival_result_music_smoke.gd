extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_text := FileAccess.get_file_as_string("res://scenes/survival_session.tscn")
	var script_text := FileAccess.get_file_as_string("res://scripts/survival_session.gd")
	if not scene_text.contains("res://assets/audio/music/victory_cue.wav") or \
			not scene_text.contains("res://assets/audio/music/defeat_cue.wav") or \
			not scene_text.contains("bus = &\"Music\""):
		_fail("Run result cue players should be declared with the Music bus and matching WAV resources")
		return
	if not script_text.contains("_play_run_result_music(victory)") or \
			not script_text.contains("var cue := $VictoryCueMusic if victory else $DefeatCueMusic"):
		_fail("Run completion should select victory or defeat music from its result")
		return
	var players: Array[AudioStreamPlayer] = []
	for cue_name in ["victory_cue", "defeat_cue"]:
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		player.stream = load("res://assets/audio/music/%s.wav" % cue_name)
		root.add_child(player)
		player.play()
		if player.stream == null or not player.playing:
			_fail("Music cue %s should load and play" % cue_name)
			return
		players.append(player)
	for player in players:
		player.queue_free()
	await process_frame
	if players.size() != 2:
		_fail("Both run result cues should be locally playable")
		return
	print("Survival result music cue routing passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
