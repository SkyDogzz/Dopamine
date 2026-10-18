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
	"weapon_family_fire": ["weapon_family_fire"],
	"weapon_family_impact": ["weapon_family_impact"],
	"damage_taken": ["damage_taken"],
	"healing": ["healing"],
	"explosion": ["explosion"],
	"victory": ["victory"],
	"defeat": ["defeat"],
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
	"weapon_family_fire": 3, "weapon_family_impact": 3,
	"damage_taken": 5, "healing": 4, "explosion": 6, "victory": 10, "defeat": 10,
	"ui_focus": 1, "ui_confirm": 4, "ui_back": 4, "ui_error": 5, "ui_pause": 5,
}
const FAMILY_GAIN_DB := {
	"level_up": -5.0,
}
const MIN_INTERVAL := {
	"weapon_shot": 0.065, "weapon_zap": 0.09, "weapon_sweep": 0.1,
	"hit_light": 0.035, "hit_heavy": 0.08, "enemy_kill": 0.045, "xp_pickup": 0.055,
	"ui_focus": 0.08,
	"damage_taken": 0.4, "healing": 0.65, "explosion": 0.12,
	"weapon_family_fire": 0.065, "weapon_family_impact": 0.035,
}
const SFX_DIR := "res://assets/audio/original_procedural/sfx/"
const WEAPON_IDS := ["lightning_conductor", "inferno_sprayer", "crimson_daggers", "minigun", "toxic_cloud", "sawblades", "meteor_staff", "prism_laser", "void_orb", "frost_nova"]

var _streams: Dictionary = {}
var _named_streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _voice_priorities: Array[int] = []
var _next_variant: Dictionary = {}
var _last_played: Dictionary = {}

func _ready() -> void:
	for sound_family in SOUNDS:
		var family_streams: Array[AudioStream] = []
		for sound_id in SOUNDS[sound_family]:
			var sound_path: String = SFX_DIR + sound_id + ".wav"
			if not ResourceLoader.exists(sound_path):
				continue
			var stream := load(sound_path) as AudioStream
			if stream == null:
				continue
			family_streams.append(stream)
		_streams[sound_family] = family_streams
	var named_sounds := ["victory", "defeat", "damage_taken", "healing", "explosion"]
	for weapon_id in WEAPON_IDS:
		named_sounds.append_array(["weapon_%s_fire" % weapon_id, "weapon_%s_impact" % weapon_id])
	for sound_id in named_sounds:
		var sound_path: String = SFX_DIR + sound_id + ".wav"
		if ResourceLoader.exists(sound_path):
			var stream := load(sound_path) as AudioStream
			if stream != null:
				_named_streams[sound_id] = [stream]
	for index in range(VOICE_COUNT):
		var player := AudioStreamPlayer.new()
		player.name = "Voice%d" % index
		player.bus = "SFX"
		add_child(player)
		player.finished.connect(_on_voice_finished.bind(index))
		_players.append(player)
		_voice_priorities.append(0)

func play(sound_family: String) -> bool:
	return _play_streams(sound_family, _streams.get(sound_family, []))

func play_weapon_fire(weapon_id: String, fallback_family: String) -> bool:
	var sound_id := _weapon_sound_family(weapon_id, "fire", "")
	if not sound_id.is_empty():
		return play_named(sound_id, fallback_family, fallback_family)
	return _play_weapon_family_fallback("weapon_family_fire", fallback_family)

func play_weapon_impact(weapon_id: String, fallback_family: String) -> bool:
	var sound_id := _weapon_sound_family(weapon_id, "impact", "")
	if not sound_id.is_empty():
		return play_named(sound_id, fallback_family, fallback_family)
	return _play_weapon_family_fallback("weapon_family_impact", fallback_family)

func _play_weapon_family_fallback(sound_family: String, fallback_family: String) -> bool:
	var streams: Array = _streams.get(sound_family, [])
	return _play_streams(sound_family, streams, fallback_family) if not streams.is_empty() else play(fallback_family)

func play_named(sound_id: String, fallback_family: String = "", policy_family: String = "") -> bool:
	var streams: Array = _named_streams.get(sound_id, [])
	if not streams.is_empty():
		return _play_streams(sound_id, streams, policy_family if not policy_family.is_empty() else fallback_family)
	return play(fallback_family) if not fallback_family.is_empty() else false

func _weapon_sound_family(weapon_id: String, event: String, fallback_family: String) -> String:
	var sound_id := "weapon_%s_%s" % [weapon_id, event]
	return sound_id if not _named_streams.get(sound_id, []).is_empty() else fallback_family

func _play_streams(sound_family: String, family_streams: Array, policy_family: String = "") -> bool:
	if family_streams.is_empty():
		return false
	var policy := policy_family if not policy_family.is_empty() else sound_family
	var now := Time.get_ticks_msec() / 1000.0
	var min_interval := maxf(float(MIN_INTERVAL.get(sound_family, 0.0)), float(MIN_INTERVAL.get(policy, 0.0)))
	if now - float(_last_played.get(sound_family, -INF)) < min_interval:
		return false
	var priority := int(PRIORITY.get(policy, 0))
	var voice := _available_voice(priority)
	if voice < 0:
		return false
	var variant_index := int(_next_variant.get(sound_family, 0))
	var player := _players[voice]
	player.stream = family_streams[variant_index % family_streams.size()]
	player.volume_db = float(FAMILY_GAIN_DB.get(policy, 0.0))
	player.play()
	_voice_priorities[voice] = priority
	_next_variant[sound_family] = variant_index + 1
	_last_played[sound_family] = now
	if policy != sound_family:
		_last_played[policy] = now
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
