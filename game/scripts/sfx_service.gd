extends Node

const VOICE_COUNT := 8
const SOUNDS := {
	"weapon_shot": ["weapon_shot_01", "weapon_shot_02", "weapon_shot_03", "weapon_shot_04"],
	"weapon_zap": ["weapon_zap_01", "weapon_zap_02", "weapon_zap_03", "weapon_zap_04"],
	"weapon_sweep": ["weapon_sweep_01", "weapon_sweep_02", "weapon_sweep_03"],
	"hit_light": ["hit_light_01", "hit_light_02", "hit_light_03", "hit_light_04"],
	"hit_heavy": ["hit_heavy_01", "hit_heavy_02", "hit_heavy_03"],
	"enemy_kill": ["enemy_kill_01", "enemy_kill_02", "enemy_kill_03", "enemy_kill_04"],
	"xp_pickup": ["xp_pickup_01", "xp_pickup_02", "xp_pickup_03", "xp_pickup_04"],
	"relic_pickup": ["relic_pickup"],
	"chest_open": ["chest_open"],
	"chest_reward": ["chest_reward"],
	"level_up": ["level_up"],
	"boss_telegraph": ["boss_telegraph"],
	"boss_phase": ["boss_phase"],
	"boss_defeat": ["boss_defeat"],
	"ui_focus": ["ui_focus"],
	"ui_confirm": ["ui_confirm"],
	"ui_back": ["ui_back"],
	"ui_error": ["ui_error"],
	"ui_pause": ["ui_pause"],
}
const PRIORITY := {
	"weapon_shot": 3, "weapon_zap": 4, "weapon_sweep": 3,
	"hit_light": 2, "hit_heavy": 5, "enemy_kill": 2, "xp_pickup": 1,
	"relic_pickup": 7, "chest_open": 5, "chest_reward": 6, "level_up": 8,
	"boss_telegraph": 10, "boss_phase": 9, "boss_defeat": 9,
	"ui_focus": 1, "ui_confirm": 4, "ui_back": 4, "ui_error": 5, "ui_pause": 5,
}
const FAMILY_GAIN_DB := {
	"level_up": -5.0,
}
const MIN_INTERVAL := {
	"weapon_shot": 0.065, "weapon_zap": 0.09, "weapon_sweep": 0.1,
	"hit_light": 0.035, "hit_heavy": 0.08, "enemy_kill": 0.045, "xp_pickup": 0.055,
	"ui_focus": 0.08,
}
const SFX_DIR := "res://assets/audio/original_procedural/sfx/"

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _voice_priorities: Array[int] = []
var _next_variant: Dictionary = {}
var _last_played: Dictionary = {}

func _ready() -> void:
	for sound_family in SOUNDS:
		var family_streams: Array[AudioStream] = []
		for sound_id in SOUNDS[sound_family]:
			var stream := load(SFX_DIR + sound_id + ".wav") as AudioStream
			if stream == null:
				push_error("Could not load SFX: %s" % sound_id)
				continue
			family_streams.append(stream)
		_streams[sound_family] = family_streams
	for index in range(VOICE_COUNT):
		var player := AudioStreamPlayer.new()
		player.name = "Voice%d" % index
		add_child(player)
		player.finished.connect(_on_voice_finished.bind(index))
		_players.append(player)
		_voice_priorities.append(0)

func play(sound_family: String) -> bool:
	var family_streams: Array = _streams.get(sound_family, [])
	if family_streams.is_empty():
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(sound_family, -INF)) < float(MIN_INTERVAL.get(sound_family, 0.0)):
		return false
	var priority := int(PRIORITY.get(sound_family, 0))
	var voice := _available_voice(priority)
	if voice < 0:
		return false
	var variant_index := int(_next_variant.get(sound_family, 0))
	var player := _players[voice]
	player.stream = family_streams[variant_index % family_streams.size()]
	player.volume_db = float(FAMILY_GAIN_DB.get(sound_family, 0.0))
	player.play()
	_voice_priorities[voice] = priority
	_next_variant[sound_family] = variant_index + 1
	_last_played[sound_family] = now
	return true

func _available_voice(priority: int) -> int:
	for index in range(_players.size()):
		if not _players[index].playing:
			return index
	var lowest_priority := 2147483647
	var lowest_voice := -1
	for index in range(_players.size()):
		if _voice_priorities[index] < lowest_priority:
			lowest_priority = _voice_priorities[index]
			lowest_voice = index
	return lowest_voice if priority > lowest_priority else -1

func _on_voice_finished(index: int) -> void:
	_voice_priorities[index] = 0
