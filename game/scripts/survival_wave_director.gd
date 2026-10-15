class_name SurvivalWaveDirector
extends RefCounted

enum State { WAVE, MID_BOSS, FINAL_BOSS, VICTORY }

var wave_duration_seconds := 30.0
var wave := 1
var elapsed_in_wave := 0.0
var state := State.WAVE

func advance(delta_seconds: float) -> bool:
	if state != State.WAVE or not is_finite(delta_seconds) or delta_seconds < 0.0 or \
			not is_finite(wave_duration_seconds) or wave_duration_seconds <= 0.0:
		return false
	elapsed_in_wave += delta_seconds
	var advanced := false
	while state == State.WAVE and elapsed_in_wave >= wave_duration_seconds:
		elapsed_in_wave -= wave_duration_seconds
		advanced = true
		if wave == 12:
			state = State.MID_BOSS
			elapsed_in_wave = 0.0
			break
		if wave == 24:
			state = State.FINAL_BOSS
			elapsed_in_wave = 0.0
			break
		wave += 1
	return advanced

func boss_defeated() -> bool:
	if state == State.MID_BOSS:
		wave = 13
		state = State.WAVE
		return true
	if state == State.FINAL_BOSS:
		state = State.VICTORY
		return true
	return false
