class_name SurvivalWaveDirector
extends RefCounted

enum State { WAVE, MID_BOSS, FINAL_BOSS, VICTORY }
enum WavePhase { RISING, PRESSURE, CALM }

var wave_duration_seconds := 30.0
var wave := 1
var elapsed_in_wave := 0.0
var state := State.WAVE
var endless_armorless := false
var endless_standard := false

const BASE_WAVE_DURATION_SECONDS := 30.0
const RISING_DURATION_SECONDS := 5.0

func phase() -> WavePhase:
	if state != State.WAVE:
		return WavePhase.PRESSURE
	var scale := wave_duration_seconds / BASE_WAVE_DURATION_SECONDS
	var rising_end := RISING_DURATION_SECONDS * scale
	var calm_duration := (5.0 if wave <= 4 else 3.0 if wave <= 12 else 2.0) * scale
	if elapsed_in_wave < rising_end:
		return WavePhase.RISING
	if elapsed_in_wave >= wave_duration_seconds - calm_duration:
		return WavePhase.CALM
	return WavePhase.PRESSURE

func phase_name() -> String:
	return WavePhase.keys()[phase()]

func phase_remaining_seconds() -> float:
	var scale := wave_duration_seconds / BASE_WAVE_DURATION_SECONDS
	var phase_end := wave_duration_seconds
	match phase():
		WavePhase.RISING:
			phase_end = RISING_DURATION_SECONDS * scale
		WavePhase.PRESSURE:
			phase_end = wave_duration_seconds - (5.0 if wave <= 4 else 3.0 if wave <= 12 else 2.0) * scale
	return maxf(0.0, phase_end - elapsed_in_wave)

func spawn_rate_multiplier() -> float:
	match phase():
		WavePhase.RISING:
			var rising_duration := RISING_DURATION_SECONDS * wave_duration_seconds / BASE_WAVE_DURATION_SECONDS
			return lerpf(0.5, 1.0, clampf(elapsed_in_wave / rising_duration, 0.0, 1.0))
		WavePhase.CALM:
			return 0.5
	return 1.0

func composition_name() -> String:
	if state != State.WAVE or wave < 4:
		return ""
	var available := ["HUNT", "PURSUIT"]
	if wave >= 8:
		available.append("BLAST")
	if wave >= 10:
		available.append("CROSSFIRE")
	if wave >= 12:
		available.append("NEST")
	return available[(wave - 4) % available.size()]

func _init(is_endless_armorless: bool = false, is_endless_standard: bool = false) -> void:
	endless_armorless = is_endless_armorless
	endless_standard = is_endless_standard

func advance(delta_seconds: float) -> bool:
	if state != State.WAVE or not is_finite(delta_seconds) or delta_seconds < 0.0 or \
			not is_finite(wave_duration_seconds) or wave_duration_seconds <= 0.0:
		return false
	elapsed_in_wave += delta_seconds
	var advanced := false
	while state == State.WAVE and elapsed_in_wave >= wave_duration_seconds:
		elapsed_in_wave -= wave_duration_seconds
		advanced = true
		if wave % 12 == 0 and (endless_armorless or endless_standard or wave != 24):
			state = State.MID_BOSS
			elapsed_in_wave = 0.0
			break
		if wave == 24:
			state = State.MID_BOSS if endless_armorless or endless_standard else State.FINAL_BOSS
			elapsed_in_wave = 0.0
			break
		wave += 1
	return advanced

func boss_defeated() -> bool:
	if state == State.MID_BOSS:
		wave += 1
		state = State.WAVE
		return true
	if state == State.FINAL_BOSS:
		state = State.VICTORY
		return true
	return false
