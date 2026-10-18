#!/usr/bin/env python3
"""Generate original, deterministic arcade audio using only Python's stdlib."""

import hashlib
import json
import math
import random
import struct
import wave
from array import array
from pathlib import Path


SAMPLE_RATE = 44_100
MUSIC_BPM = 115
MUSIC_BARS = 4
BEAT_SECONDS = 60.0 / MUSIC_BPM
BAR_SECONDS = BEAT_SECONDS * 4.0
MUSIC_SAMPLE_COUNT = round(SAMPLE_RATE * BAR_SECONDS * MUSIC_BARS)
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "audio" / "original_procedural"
SFX_IDS = [
	"weapon_shot_01", "weapon_shot_02", "weapon_shot_03", "weapon_shot_04",
	"weapon_zap_01", "weapon_zap_02", "weapon_zap_03", "weapon_zap_04",
	"weapon_sweep_01", "weapon_sweep_02", "weapon_sweep_03",
	"hit_light_01", "hit_light_02", "hit_light_03", "hit_light_04",
	"hit_heavy_01", "hit_heavy_02", "hit_heavy_03",
	"enemy_kill_01", "enemy_kill_02", "enemy_kill_03", "enemy_kill_04",
	"xp_pickup_01", "xp_pickup_02", "xp_pickup_03", "xp_pickup_04",
	"relic_pickup", "chest_open", "chest_reward", "level_up",
	"boss_telegraph", "boss_phase", "boss_defeat",
	"ui_focus", "ui_confirm", "ui_back", "ui_error", "ui_pause",
]


def _render_sfx(sound_id: str) -> list[float]:
	"""Synthesize a new short effect from event role and stable ID-derived seed."""
	family = sound_id.rsplit("_", 1)[0] if sound_id.rsplit("_", 1)[-1].isdigit() else sound_id
	seed = int.from_bytes(hashlib.sha256(sound_id.encode("utf-8")).digest()[:4], "little")
	rng = random.Random(seed)
	profiles = {
		"weapon_shot": (0.105, 520.0, 0.75, 0.04), "weapon_zap": (0.14, 760.0, 0.5, 0.13),
		"weapon_sweep": (0.20, 290.0, 0.28, 0.28), "hit_light": (0.095, 940.0, 0.65, 0.08),
		"hit_heavy": (0.22, 125.0, 0.9, 0.08), "enemy_kill": (0.16, 370.0, 0.34, 0.25),
		"xp_pickup": (0.13, 830.0, 0.12, 0.18), "relic_pickup": (0.48, 440.0, 0.12, 0.23),
		"chest_open": (0.38, 190.0, 0.38, 0.16), "chest_reward": (0.32, 590.0, 0.12, 0.19),
		"level_up": (0.62, 500.0, 0.08, 0.3), "boss_telegraph": (0.36, 510.0, 0.16, 0.32),
		"boss_phase": (0.72, 220.0, 0.4, 0.2), "boss_defeat": (0.95, 330.0, 0.16, 0.34),
		"ui_focus": (0.045, 1150.0, 0.04, 0.08), "ui_confirm": (0.13, 680.0, 0.06, 0.2),
		"ui_back": (0.12, 420.0, 0.06, -0.16), "ui_error": (0.15, 260.0, 0.09, -0.12),
		"ui_pause": (0.21, 470.0, 0.12, 0.16),
	}
	duration, base_frequency, noise_amount, pitch_sweep = profiles[family]
	count = round(SAMPLE_RATE * duration)
	transient = [rng.uniform(-1.0, 1.0) for _ in range(round(SAMPLE_RATE * 0.018))]
	pitch_variant = 1.0 + rng.uniform(-0.045, 0.045)
	phase = rng.uniform(0.0, math.tau)
	samples: list[float] = []
	for index in range(count):
		time = index / SAMPLE_RATE
		normalized_time = time / duration
		frequency = base_frequency * pitch_variant * (1.0 + pitch_sweep * normalized_time)
		envelope = min(1.0, time / 0.003) * math.exp(-time * (4.2 / duration))
		body = math.sin(math.tau * frequency * time + phase)
		body += 0.31 * math.sin(math.tau * frequency * 1.618 * time + phase * 0.7)
		body += 0.12 * math.sin(math.tau * frequency * 2.414 * time)
		transient_sample = transient[index] if index < len(transient) else 0.0
		transient_sample *= math.exp(-time * 340.0)
		pulse = 0.78 + 0.22 * math.sin(math.pi * 5.0 * normalized_time) ** 2
		samples.append((body * (1.0 - noise_amount * 0.35) + transient_sample * noise_amount) * envelope * pulse)
	fade_samples = round(SAMPLE_RATE * min(0.008, duration * 0.08))
	for index in range(fade_samples):
		samples[-fade_samples + index] *= 1.0 - (index + 1) / fade_samples
	peak = max(abs(sample) for sample in samples)
	return [sample * (0.72 / peak) for sample in samples]


def _write_wave(path: Path, samples: list[float]) -> dict[str, float | int | str]:
	peak = max(abs(sample) for sample in samples)
	rms = math.sqrt(sum(sample * sample for sample in samples) / len(samples))
	with wave.open(str(path), "wb") as output:
		output.setnchannels(1)
		output.setsampwidth(2)
		output.setframerate(SAMPLE_RATE)
		output.writeframes(b"".join(struct.pack("<h", round(sample * 32767)) for sample in samples))
	return {
		"file": path.name,
		"sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
		"sample_rate_hz": SAMPLE_RATE,
		"channels": 1,
		"duration_seconds": round(len(samples) / SAMPLE_RATE, 6),
		"peak_dbfs": round(20.0 * math.log10(peak), 3),
		"rms_dbfs": round(20.0 * math.log10(rms), 3),
		"crest_factor_db": round(20.0 * math.log10(peak / rms), 3),
	}


def _write_preview(path: Path) -> None:
	players = "\n".join(
		f'<article><h2>{sound_id}</h2><audio controls preload="none" src="sfx/{sound_id}.wav"></audio></article>'
		for sound_id in SFX_IDS
	)
	path.write_text(
		'<!doctype html><meta charset="utf-8"><title>Dopamine Survivor audio candidates</title>\n'
		'<style>body{max-width:42rem;margin:3rem auto;padding:0 1rem;background:#090d19;color:#e7efff;'
		'font:16px system-ui,sans-serif}h1{color:#37e8f5}article{border:1px solid #39486b;padding:1rem;margin:1rem 0}'
		'small{color:#a6aec4}</style><body><h1>Original procedural audio · candidates</h1>'
		'<p>Mono PCM16 · 44.1 kHz · generated by game/tools/generate_original_audio.py.</p>'
		'<p><small>Not approved, mixed or reviewed in a game run yet.</small></p>'
		'<article><h2>Synthwave EDM loop · 115 BPM</h2>'
		'<p>Four bars · D minor (proposed) · synchronized candidate stems.</p>'
		'<audio controls preload="none" src="music/preview_mix.wav"></audio></article>'
		+ players + '</body>\n'
	)


def _add_tone(stem: array, start: float, duration: float, frequency: float,
		amplitude: float, decay: float = 0.0, glide: float = 0.0, harmonic: float = 0.0) -> None:
	first = max(0, round(start * SAMPLE_RATE))
	last = min(len(stem), round((start + duration) * SAMPLE_RATE))
	phase = 0.0
	for sample_index in range(first, last):
		time = sample_index / SAMPLE_RATE - start
		envelope = min(1.0, time / 0.004) * math.exp(-time * decay)
		current_frequency = frequency + glide * (time / duration)
		phase += math.tau * current_frequency / SAMPLE_RATE
		value = math.sin(phase) + harmonic * math.sin(phase * 2.0)
		stem[sample_index] += value * amplitude * envelope


def _add_noise(stem: array, start: float, duration: float, amplitude: float,
		decay: float, rng: random.Random) -> None:
	first = max(0, round(start * SAMPLE_RATE))
	last = min(len(stem), round((start + duration) * SAMPLE_RATE))
	for sample_index in range(first, last):
		time = sample_index / SAMPLE_RATE - start
		envelope = min(1.0, time / 0.001) * math.exp(-time * decay)
		stem[sample_index] += rng.uniform(-1.0, 1.0) * amplitude * envelope


def _make_loop_seamless(stem: array) -> None:
	"""Fade both edges to zero over 12 ms so the loop boundary is continuous."""
	fade_count = round(SAMPLE_RATE * 0.012)
	for offset in range(fade_count):
		gain = offset / fade_count
		stem[offset] *= gain
		stem[len(stem) - fade_count + offset] *= 1.0 - gain


def _render_music_stems() -> dict[str, array]:
	"""Render a four-bar minor-key EDM loop with phase-aligned intensity stems."""
	stems = {name: array("f", [0.0]) * MUSIC_SAMPLE_COUNT
		for name in ["rhythm", "bass", "pad", "arp", "boss"]}
	chords = [
		(73.416, (146.832, 174.614, 220.000)),
		(58.270, (116.541, 146.832, 174.614)),
		(87.307, (174.614, 220.000, 261.626)),
		(65.406, (130.813, 164.814, 196.000)),
	]
	rhythm_rng = random.Random(90210)
	for beat in range(MUSIC_BARS * 4):
		start = beat * BEAT_SECONDS
		_add_tone(stems["rhythm"], start, 0.25, 75.0, 0.72, 16.0, -42.0, 0.18)
		if beat % 4 in (1, 3):
			_add_noise(stems["rhythm"], start, 0.17, 0.34, 24.0, rhythm_rng)
		else:
			_add_noise(stems["rhythm"], start + BEAT_SECONDS * 0.5, 0.045, 0.12, 68.0, rhythm_rng)
		_add_noise(stems["rhythm"], start + BEAT_SECONDS * 0.5, 0.035, 0.11, 80.0, rhythm_rng)
	for bar in range(MUSIC_BARS):
		root, chord = chords[bar]
		bar_start = bar * BAR_SECONDS
		_add_tone(stems["pad"], bar_start, BAR_SECONDS, chord[0], 0.12, 0.12)
		_add_tone(stems["pad"], bar_start, BAR_SECONDS, chord[1], 0.10, 0.12)
		_add_tone(stems["pad"], bar_start, BAR_SECONDS, chord[2], 0.09, 0.12)
		for step in range(8):
			start = bar_start + step * BEAT_SECONDS * 0.5
			bass_note = root if step in (0, 3, 4, 7) else root * 1.5
			_add_tone(stems["bass"], start, BEAT_SECONDS * 0.39, bass_note, 0.38, 5.0, 0.0, 0.2)
			arp_note = chord[(step + bar) % len(chord)] * (2.0 if step % 4 else 4.0)
			_add_tone(stems["arp"], start, BEAT_SECONDS * 0.34, arp_note, 0.14, 8.0, 0.0, 0.22)
			if step in (2, 6):
				_add_tone(stems["boss"], start, BEAT_SECONDS * 0.42, arp_note * 0.5, 0.12, 5.5, 0.0, 0.12)
		if bar in (1, 3):
			_add_noise(stems["boss"], bar_start + BAR_SECONDS - 0.12, 0.11, 0.18, 8.0, rhythm_rng)
	for stem in stems.values():
		_make_loop_seamless(stem)
	return stems


def main() -> None:
	OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
	sfx_directory = OUTPUT_DIR / "sfx"
	sfx_directory.mkdir(exist_ok=True)
	sfx_metrics = [_write_wave(sfx_directory / f"{sound_id}.wav", _render_sfx(sound_id)) for sound_id in SFX_IDS]
	(sfx_directory / "manifest.json").write_text(json.dumps({
		"status": "original procedural SFX integrated in game; not yet ear-reviewed in context",
		"source": "game/tools/generate_original_audio.py",
		"method": "deterministic oscillators, ID-seeded noise transients, analytic envelopes",
		"sounds": sfx_metrics,
	}, indent=2) + "\n")
	_write_preview(OUTPUT_DIR / "preview.html")
	music_directory = OUTPUT_DIR / "music"
	music_directory.mkdir(exist_ok=True)
	stems = _render_music_stems()
	music_metrics = []
	preview_mix = array("f", [0.0]) * MUSIC_SAMPLE_COUNT
	mix_gains = {"rhythm": 0.38, "bass": 0.34, "pad": 0.27, "arp": 0.22, "boss": 0.20}
	for name, stem in stems.items():
		music_metrics.append(_write_wave(music_directory / f"{name}.wav", stem))
		gain = mix_gains[name]
		for index, sample in enumerate(stem):
			preview_mix[index] += sample * gain
	preview_peak = max(abs(sample) for sample in preview_mix)
	if preview_peak > 0.82:
		preview_gain = 0.82 / preview_peak
		preview_mix = array("f", (sample * preview_gain for sample in preview_mix))
	preview_metrics = _write_wave(music_directory / "preview_mix.wav", preview_mix)
	(music_directory / "manifest.json").write_text(json.dumps({
		"status": "original procedural loop candidate; not integrated or ear-reviewed in game",
		"source": "game/tools/generate_original_audio.py",
		"tempo_bpm": MUSIC_BPM,
		"bars": MUSIC_BARS,
		"duration_seconds": round(MUSIC_SAMPLE_COUNT / SAMPLE_RATE, 6),
		"meter": "4/4",
		"key_center": "D minor (proposed)",
		"mix_gains_linear_proposed": mix_gains,
		"stems": music_metrics,
		"preview_mix": preview_metrics,
	}, indent=2) + "\n")
	(OUTPUT_DIR / "manifest.json").write_text(json.dumps({
		"status": "original procedural audio candidates; not yet ear-reviewed in game",
		"source": "game/tools/generate_original_audio.py",
		"method": "deterministic oscillators, ID-seeded noise transients, analytic envelopes; five synchronized loop stems",
		"sfx_candidate_count": len(sfx_metrics),
		"music_manifest": "music/manifest.json",
	}, indent=2) + "\n")
	print(json.dumps({"sfx_count": len(sfx_metrics), "music_stems": len(music_metrics)}, indent=2))


if __name__ == "__main__":
	main()
