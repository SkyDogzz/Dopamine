#!/usr/bin/env python3
"""Render an audition excerpt with the same loop, gain and fade rules as the runtime music controller."""

import math
import struct
import wave
from array import array
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
AUDIO = ROOT / "game/assets/audio/original_procedural"
OUTPUT = ROOT / "docs/art/evidence/2026-10-18/adaptive-music-transition.wav"
RATE = 44_100
FPS = 60
DURATION = 30
NAMES = ["rhythm", "bass", "pad", "arp", "boss"]
BASE_GAINS = [0.38, 0.34, 0.27, 0.22, 0.20]
EVENTS = [(0.0, 1, False), (5.0, 8, False), (10.0, 18, False), (15.0, 24, True), (24.0, 24, False)]
SFX = [(4.4, "weapon_shot_02"), (9.1, "weapon_zap_03"), (10.7, "xp_pickup_02"),
	(14.4, "boss_telegraph"), (19.4, "boss_phase"), (25.0, "boss_defeat"), (26.2, "weapon_shot_01")]


def db(value: float) -> float:
	return 10 ** (value / 20)


def target_stems(wave_number: int, boss: bool) -> list[float]:
	progress = min(1.0, max(0.0, (max(1, wave_number) - 1) / 23.0))
	arpeggio = 0.25 + 0.75 * progress
	gains = [BASE_GAINS[0], BASE_GAINS[1], BASE_GAINS[2], BASE_GAINS[3] * arpeggio,
		BASE_GAINS[4] if boss else 0.0]
	return [20 * math.log10(gain) if gain else -60.0 for gain in gains]


def target_master(wave_number: int, boss: bool) -> float:
	return -24 + min(max(0, wave_number - 1) * 0.16, 4.0) + (3.0 if boss else 0.0)


def read_mono(path: Path) -> array:
	with wave.open(str(path), "rb") as source:
		assert source.getnchannels() == 1 and source.getsampwidth() == 2 and source.getframerate() == RATE
		result = array("h")
		result.frombytes(source.readframes(source.getnframes()))
		if struct.pack("=H", 1) != struct.pack("<H", 1):
			result.byteswap()
		return result


def main() -> None:
	stems = [read_mono(AUDIO / "music" / f"{name}.wav") for name in NAMES]
	sfx = {name: read_mono(AUDIO / "sfx" / f"{name}.wav") for _, name in SFX}
	frames = DURATION * FPS
	samples_per_frame = RATE // FPS
	master_db = -60.0
	stem_db = target_stems(1, False)
	target_db = stem_db.copy()
	master_target = -60.0
	event_i = 0
	output: list[float] = []
	for frame in range(frames):
		time = frame / FPS
		while event_i + 1 < len(EVENTS) and time >= EVENTS[event_i + 1][0]:
			event_i += 1
		_, wave_number, boss = EVENTS[event_i]
		target_db = target_stems(wave_number, boss)
		master_target = target_master(wave_number, boss)
		master_db = math.copysign(min(abs(master_target - master_db), 18.0 / FPS), master_target - master_db) + master_db
		stem_db = [current + math.copysign(min(abs(target - current), 12.0 / FPS), target - current)
			for current, target in zip(stem_db, target_db)]
		start = frame * samples_per_frame
		for offset in range(samples_per_frame):
			mix = 0.0
			for stem, gain_db in zip(stems, stem_db):
				mix += stem[(start + offset) % len(stem)] / 32768.0 * db(gain_db)
			output.append(mix * db(master_db))
	for time, name in SFX:
		start = round(time * RATE)
		for offset, sample in enumerate(sfx[name]):
			if start + offset < len(output):
				output[start + offset] += sample / 32768.0 * 0.5
	peak = max(abs(sample) for sample in output)
	# A single audition-only master gain preserves every internal balance and transition.
	gain = min(0.85 / peak, 4.0)
	OUTPUT.parent.mkdir(parents=True, exist_ok=True)
	with wave.open(str(OUTPUT), "wb") as target:
		target.setnchannels(2)
		target.setsampwidth(2)
		target.setframerate(RATE)
		target.writeframes(b"".join(struct.pack("<hh", max(-32768, min(32767, round(value * gain * 32767))),
			max(-32768, min(32767, round(value * gain * 32767)))) for value in output))
	print(f"Wrote {OUTPUT.relative_to(ROOT)} ({DURATION}s, 44.1kHz stereo, audition peak {20*math.log10(peak*gain):.2f} dBFS)")


if __name__ == "__main__":
	main()
