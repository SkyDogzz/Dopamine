extends Node

const TRACK: AudioStreamOggVorbis = preload("res://assets/audio/music/space_city_bpm115.ogg")
const BASE_VOLUME_DB := -24.0 # [PROPOSÉ] À régler avec le mix en jeu.
const WAVE_RISE_DB := 0.16 # [PROPOSÉ] Progression douce, plafonnée à 4 dB.
const BOSS_ACCENT_DB := 3.0 # [PROPOSÉ] Accent sonore durant les combats de boss.
const MAX_WAVE_RISE_DB := 4.0
const FADE_SPEED_DB_PER_SECOND := 18.0
const SILENT_VOLUME_DB := -60.0

var _player: AudioStreamPlayer
var _target_volume_db := SILENT_VOLUME_DB

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "AdaptiveMusicPlayer"
	_player.stream = TRACK
	_player.stream.loop = true
	_player.volume_db = SILENT_VOLUME_DB
	add_child(_player)
	_player.play()

func set_context(wave: int, boss_active: bool, gameplay_active: bool) -> void:
	_target_volume_db = target_volume_db_for(wave, boss_active) if gameplay_active else SILENT_VOLUME_DB

func _process(delta: float) -> void:
	if _player == null or not is_finite(delta) or delta <= 0.0:
		return
	_player.volume_db = move_toward(_player.volume_db, _target_volume_db, FADE_SPEED_DB_PER_SECOND * delta)

static func target_volume_db_for(wave: int, boss_active: bool) -> float:
	var wave_rise := minf(maxi(0, wave - 1) * WAVE_RISE_DB, MAX_WAVE_RISE_DB)
	return BASE_VOLUME_DB + wave_rise + (BOSS_ACCENT_DB if boss_active else 0.0)
