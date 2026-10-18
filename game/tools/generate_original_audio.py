#!/usr/bin/env python3
"""Generate original, deterministic arcade audio using only Python's stdlib."""

import hashlib
import json
import math
import random
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 44_100
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


def _render_boss_telegraph(seed: int = 731) -> list[float]:
	"""A 360 ms rising dual-tone pulse with a short deterministic noise attack."""
	rng = random.Random(seed)
	duration = 0.36
	count = round(SAMPLE_RATE * duration)
	noise = [rng.uniform(-1.0, 1.0) for _ in range(round(SAMPLE_RATE * 0.012))]
	samples: list[float] = []
	for index in range(count):
		time = index / SAMPLE_RATE
		attack = min(1.0, time / 0.004)
		decay = math.exp(-time * 2.3)
		pulse = 0.72 + 0.28 * math.sin(2.0 * math.pi * 7.0 * time) ** 2
		frequency = 510.0 + 680.0 * (time / duration)
		body = math.sin(2.0 * math.pi * frequency * time)
		body += 0.34 * math.sin(2.0 * math.pi * (frequency * 1.497) * time + 0.2)
		transient = noise[index] * math.exp(-time * 480.0) if index < len(noise) else 0.0
		samples.append((body * 0.42 + transient * 0.15) * attack * decay * pulse)
	# Short fade avoids a discontinuity at the end of the generated buffer.
	fade_samples = round(SAMPLE_RATE * 0.008)
	for index in range(fade_samples):
		samples[-fade_samples + index] *= 1.0 - (index + 1) / fade_samples
	peak = max(abs(sample) for sample in samples)
	return [sample * (0.72 / peak) for sample in samples]


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
		+ players + '</body>\n'
	)


def main() -> None:
	OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
	metrics = _write_wave(OUTPUT_DIR / "boss_telegraph.wav", _render_boss_telegraph())
	sfx_directory = OUTPUT_DIR / "sfx"
	sfx_directory.mkdir(exist_ok=True)
	sfx_metrics = [_write_wave(sfx_directory / f"{sound_id}.wav", _render_sfx(sound_id)) for sound_id in SFX_IDS]
	(sfx_directory / "manifest.json").write_text(json.dumps({
		"status": "original procedural candidates; not integrated or ear-reviewed in game",
		"source": "game/tools/generate_original_audio.py",
		"method": "deterministic oscillators, ID-seeded noise transients, analytic envelopes",
		"sounds": sfx_metrics,
	}, indent=2) + "\n")
	_write_preview(OUTPUT_DIR / "preview.html")
	(OUTPUT_DIR / "manifest.json").write_text(json.dumps({
		"status": "prototype; not yet integrated or ear-reviewed in game",
		"source": "game/tools/generate_original_audio.py",
		"method": "deterministic sine oscillators, seeded white-noise transient, analytic envelopes",
		"sounds": [metrics],
		"sfx_candidate_count": len(sfx_metrics),
	}, indent=2) + "\n")
	print(json.dumps({"prototype": metrics, "sfx_count": len(sfx_metrics)}, indent=2))


if __name__ == "__main__":
	main()
