class_name SurvivalWaveDirector
extends RefCounted

enum State { WAVE, MID_BOSS, FINAL_BOSS, VICTORY }

var wave_duration_seconds := 30.0
var wave := 1
var elapsed_in_wave := 0.0
var state := State.WAVE

func advance(delta_seconds: float) -> bool:
	if state != State.WAVE or delta_seconds < 0.0:
		return false
	elapsed_in_wave += delta_seconds
	if elapsed_in_wave < wave_duration_seconds:
		return false
	elapsed_in_wave = 0.0
	if wave == 11:
		wave = 12
		state = State.MID_BOSS
		return true
	if wave == 23:
		wave = 24
		state = State.FINAL_BOSS
		return true
	wave += 1
	return true

func boss_defeated() -> bool:
	if state == State.MID_BOSS:
		wave = 13
		state = State.WAVE
		return true
	if state == State.FINAL_BOSS:
		state = State.VICTORY
		return true
	return false
