extends Node

const STEM_PATHS := [
	"res://assets/audio/original_procedural/music/rhythm.wav",
	"res://assets/audio/original_procedural/music/bass.wav",
	"res://assets/audio/original_procedural/music/pad.wav",
	"res://assets/audio/original_procedural/music/arp.wav",
	"res://assets/audio/original_procedural/music/boss.wav",
]
const STEM_GAINS_LINEAR := [0.38, 0.34, 0.27, 0.22, 0.20] # [PROPOSÉ] Initial mix from the candidate manifest.
const BASE_VOLUME_DB := -24.0 # [PROPOSÉ] À régler avec le mix en jeu.
const WAVE_RISE_DB := 0.16 # [PROPOSÉ] Progression douce, plafonnée à 4 dB.
const BOSS_ACCENT_DB := 3.0 # [PROPOSÉ] Accent sonore durant les combats de boss.
const MAX_WAVE_RISE_DB := 4.0
const FADE_SPEED_DB_PER_SECOND := 18.0
const STEM_FADE_SPEED_DB_PER_SECOND := 12.0 # [PROPOSÉ] Transition d'orchestration sans redémarrer les stems.
const SILENT_VOLUME_DB := -60.0
const MAX_PROGRESS_WAVE := 24 # [PROPOSÉ] Plafond d'intensité de l'arrangement.
const ARP_START_FACTOR := 0.25 # [PROPOSÉ] Arpège plus discret au début de la run.

var _player: AudioStreamPlayer
var _synchronized_stream: AudioStreamSynchronized
var _target_volume_db := SILENT_VOLUME_DB
var _context_wave := 1
var _context_boss_active := false
var _target_stem_volumes_db: Array[float] = []
var _current_stem_volumes_db: Array[float] = []

func _ready() -> void:
	_synchronized_stream = AudioStreamSynchronized.new()
	_synchronized_stream.stream_count = STEM_PATHS.size()
	var stems: Array[AudioStreamWAV] = []
	for path in STEM_PATHS:
		if not ResourceLoader.exists(path):
			return # Missing music means silence until the complete set is recreated.
		var stem := load(path) as AudioStreamWAV
		if stem == null:
			return
		stems.append(stem)
	for index in range(stems.size()):
		var stem := stems[index]
		stem.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stem.loop_begin = 0
		stem.loop_end = roundi(stem.get_length() * stem.mix_rate)
		_synchronized_stream.set_sync_stream(index, stem)
	_target_stem_volumes_db = target_stem_volumes_db_for(_context_wave, _context_boss_active)
	_current_stem_volumes_db = _target_stem_volumes_db.duplicate()
	for index in range(_current_stem_volumes_db.size()):
		_synchronized_stream.set_sync_stream_volume(index, _current_stem_volumes_db[index])
	_player = AudioStreamPlayer.new()
	_player.name = "AdaptiveMusicPlayer"
	_player.stream = _synchronized_stream
	_player.volume_db = SILENT_VOLUME_DB
	add_child(_player)
	_player.play()

func set_context(wave: int, boss_active: bool, gameplay_active: bool) -> void:
	_context_wave = maxi(1, wave)
	_context_boss_active = boss_active
	_target_volume_db = target_volume_db_for(_context_wave, boss_active) if gameplay_active else SILENT_VOLUME_DB
	_target_stem_volumes_db = target_stem_volumes_db_for(_context_wave, boss_active)

func _process(delta: float) -> void:
	if _player == null or not is_finite(delta) or delta <= 0.0:
		return
	_player.volume_db = move_toward(_player.volume_db, _target_volume_db, FADE_SPEED_DB_PER_SECOND * delta)
	for index in range(_current_stem_volumes_db.size()):
		var next_volume := move_toward(
			_current_stem_volumes_db[index], _target_stem_volumes_db[index], STEM_FADE_SPEED_DB_PER_SECOND * delta
		)
		_current_stem_volumes_db[index] = next_volume
		_synchronized_stream.set_sync_stream_volume(index, next_volume)

static func target_volume_db_for(wave: int, boss_active: bool) -> float:
	var wave_rise := minf(maxi(0, wave - 1) * WAVE_RISE_DB, MAX_WAVE_RISE_DB)
	return BASE_VOLUME_DB + wave_rise + (BOSS_ACCENT_DB if boss_active else 0.0)

static func target_stem_volumes_db_for(wave: int, boss_active: bool) -> Array[float]:
	var progress := clampf(float(maxi(1, wave) - 1) / float(MAX_PROGRESS_WAVE - 1), 0.0, 1.0)
	var arp_factor := lerpf(ARP_START_FACTOR, 1.0, progress)
	var gains: Array[float] = [
		STEM_GAINS_LINEAR[0], STEM_GAINS_LINEAR[1], STEM_GAINS_LINEAR[2],
		STEM_GAINS_LINEAR[3] * arp_factor,
		STEM_GAINS_LINEAR[4] if boss_active else 0.0,
	]
	var volumes: Array[float] = []
	for gain in gains:
		volumes.append(linear_to_db(gain) if gain > 0.0 else SILENT_VOLUME_DB)
	return volumes
