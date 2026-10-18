#!/usr/bin/env python3
"""Generate original, deterministic arcade audio using only Python's stdlib."""

import hashlib
import argparse
import json
import math
import random
import struct
import wave
from array import array
from pathlib import Path


SAMPLE_RATE = 44_100
MUSIC_BPM = 124
MUSIC_BARS = 8
BEAT_SECONDS = 60.0 / MUSIC_BPM
BAR_SECONDS = BEAT_SECONDS * 4.0
MUSIC_SAMPLE_COUNT = round(SAMPLE_RATE * BAR_SECONDS * MUSIC_BARS)
DEFAULT_OUTPUT_DIR = Path(__file__).resolve().parents[2] / "build" / "assets" / "candidates" / "audio"
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
SFX_IDS += ["weapon_family_fire", "weapon_family_impact", "damage_taken", "healing",
	"explosion", "victory", "defeat"]
WEAPON_IDS = ["lightning_conductor", "inferno_sprayer", "crimson_daggers", "minigun",
	"toxic_cloud", "sawblades", "meteor_staff", "prism_laser", "void_orb", "frost_nova"]
for weapon in WEAPON_IDS:
	for event in ("fire", "impact"):
		base_id = f"weapon_{weapon}_{event}"
		SFX_IDS.append(base_id)
		SFX_IDS.extend(f"{base_id}_{variant:02d}" for variant in range(2, 5))


def _sfx_family(sound_id: str) -> str:
	if sound_id in {"weapon_family_fire", "victory"}:
		return "weapon_zap" if sound_id == "weapon_family_fire" else "boss_defeat"
	if sound_id == "weapon_family_impact":
		return "hit_light"
	if sound_id in {"damage_taken", "explosion", "defeat"}:
		return "hit_heavy" if sound_id != "defeat" else "boss_phase"
	if sound_id == "healing":
		return "relic_pickup"
	for weapon in WEAPON_IDS:
		if sound_id.startswith(f"weapon_{weapon}_"):
			family = {"lightning_conductor": "weapon_zap", "inferno_sprayer": "weapon_sweep",
				"crimson_daggers": "weapon_sweep", "minigun": "weapon_shot",
				"toxic_cloud": "weapon_sweep", "sawblades": "weapon_sweep",
				"meteor_staff": "weapon_shot", "prism_laser": "weapon_zap",
				"void_orb": "weapon_zap", "frost_nova": "weapon_sweep"}[weapon]
			return family if "_fire" in sound_id else "hit_light"
	last_part = sound_id.rsplit("_", 1)[-1]
	return sound_id.rsplit("_", 1)[0] if last_part.isdigit() else sound_id


def _render_sfx(sound_id: str, seed: int | None = None) -> list[float]:
	"""Synthesize a role-specific arcade sound with an event-dependent contour."""
	family = _sfx_family(sound_id)
	if seed is None:
		seed = int.from_bytes(hashlib.sha256(sound_id.encode("utf-8")).digest()[:4], "little")
	rng = random.Random(seed)
	profiles = {
		"weapon_shot": (0.105, 420.0, 0.82, -0.18, "shot"), "weapon_zap": (0.16, 690.0, 0.38, 0.78, "zap"),
		"weapon_sweep": (0.21, 310.0, 0.25, 0.62, "sweep"), "hit_light": (0.09, 980.0, 0.78, -0.55, "hit"),
		"hit_heavy": (0.23, 94.0, 0.88, -0.28, "impact"), "enemy_kill": (0.15, 520.0, 0.18, 0.52, "shard"),
		"xp_pickup": (0.14, 1040.0, 0.05, 0.94, "coin"), "relic_pickup": (0.46, 390.0, 0.08, 0.48, "chime"),
		"chest_open": (0.42, 160.0, 0.42, 0.31, "riser"), "chest_reward": (0.36, 720.0, 0.06, 0.55, "chime"),
		"level_up": (0.64, 560.0, 0.02, 0.82, "arpeggio"), "boss_telegraph": (0.48, 210.0, 0.18, 0.83, "alarm"),
		"boss_phase": (0.76, 135.0, 0.55, -0.12, "impact"), "boss_defeat": (0.95, 260.0, 0.06, 0.74, "fanfare"),
		"ui_focus": (0.045, 1240.0, 0.01, 0.0, "blip"), "ui_confirm": (0.13, 660.0, 0.02, 0.72, "chime"),
		"ui_back": (0.12, 470.0, 0.02, -0.62, "blip"), "ui_error": (0.17, 180.0, 0.16, -0.58, "buzzer"),
		"ui_pause": (0.24, 350.0, 0.03, -0.45, "sweep"),
	}
	duration, base_frequency, noise_amount, pitch_sweep, contour = profiles[family]
	weapon_profiles = {
		"lightning_conductor": (1250.0, "zap", 0.68), "inferno_sprayer": (240.0, "flame", 0.92),
		"crimson_daggers": (520.0, "slash", 0.88), "minigun": (180.0, "shot", 0.72),
		"toxic_cloud": (320.0, "bubbly", 0.8), "sawblades": (145.0, "grind", 0.75),
		"meteor_staff": (110.0, "whoosh", 0.65), "prism_laser": (1800.0, "laser", 0.92),
		"void_orb": (75.0, "void", 0.85), "frost_nova": (840.0, "crystal", 0.72),
	}
	for weapon, (frequency, shape, noise) in weapon_profiles.items():
		if sound_id.startswith(f"weapon_{weapon}_"):
			base_frequency, contour = frequency, shape
			noise_amount = noise if "_fire" in sound_id else min(0.95, noise + 0.12)
			break
	count = round(SAMPLE_RATE * duration)
	transient = [rng.uniform(-1.0, 1.0) for _ in range(round(SAMPLE_RATE * 0.032))]
	pitch_variant = 1.0 + rng.uniform(-0.045, 0.045)
	phase = rng.uniform(0.0, math.tau)
	samples: list[float] = []
	for index in range(count):
		time = index / SAMPLE_RATE
		normalized_time = time / duration
		frequency = base_frequency * pitch_variant * max(0.18, 1.0 + pitch_sweep * normalized_time)
		attack = min(1.0, time / 0.0025)
		decay = math.exp(-time * (3.0 / duration))
		if contour in {"alarm", "riser", "whoosh"}:
			decay *= min(1.0, normalized_time * 3.0 + 0.08)
		envelope = attack * decay
		if contour in {"chime", "coin", "crystal", "arpeggio", "fanfare"}:
			semitone = 1.0 if contour in {"coin", "chime"} else 1.5
			frequency *= 1.0 + semitone * min(1.0, normalized_time * 1.4)
		carrier = math.sin(math.tau * frequency * time + phase)
		body = carrier + 0.24 * math.sin(math.tau * frequency * 2.0 * time + phase * 0.7)
		if contour in {"grind", "flame", "bubbly", "void", "impact", "shot"}:
			body += 0.38 * math.sin(math.tau * frequency * 0.5 * time + phase * 1.2)
		if contour in {"zap", "laser", "alarm"}:
			body += 0.28 * math.sin(math.tau * frequency * (2.0 + 0.3 * math.sin(time * 31.0)) * time)
		transient_sample = transient[index] if index < len(transient) else 0.0
		transient_sample *= math.exp(-time * 240.0)
		pulse_rate = 3.0 if contour in {"bubbly", "grind", "alarm"} else 1.0
		pulse = 0.72 + 0.28 * math.sin(math.pi * pulse_rate * normalized_time) ** 2
		if contour == "slash":
			body *= math.sin(math.pi * min(0.999, normalized_time))
		elif contour == "buzzer":
			body *= 0.65 + 0.35 * math.sin(math.tau * 27.0 * time)
		samples.append((body * (1.0 - noise_amount * 0.30) + transient_sample * noise_amount) * envelope * pulse)
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


def _write_preview(path: Path, sound_ids: list[str]) -> None:
	players = "\n".join(
		f'<article><h2>{sound_id}</h2><audio controls preload="none" src="sfx/{sound_id}.wav"></audio></article>'
		for sound_id in sound_ids
	)
	path.write_text(
		'<!doctype html><meta charset="utf-8"><title>Dopamine Survivor audio candidates</title>\n'
		'<style>body{max-width:42rem;margin:3rem auto;padding:0 1rem;background:#090d19;color:#e7efff;'
		'font:16px system-ui,sans-serif}h1{color:#37e8f5}article{border:1px solid #39486b;padding:1rem;margin:1rem 0}'
		'small{color:#a6aec4}</style><body><h1>Original procedural audio · candidates</h1>'
		'<p>Mono PCM16 · 44.1 kHz · generated by game/tools/generate_original_audio.py.</p>'
		'<p><small>Staged candidate batch; not approved or reviewed in a game run.</small></p>'
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


def _render_music_stems(seed: int = 90210) -> dict[str, array]:
	"""Render an eight-bar, phase-aligned synthwave EDM loop with graduated layers."""
	stems = {name: array("f", [0.0]) * MUSIC_SAMPLE_COUNT
		for name in ["rhythm", "bass", "pad", "arp", "boss"]}
	# D minor / Bb / F / C, returning through D minor and resolving on A major.
	chords = [
		(73.42, (146.83, 174.61, 220.0)), (58.27, (116.54, 146.83, 174.61)),
		(87.31, (174.61, 220.0, 261.63)), (65.41, (130.81, 164.81, 196.0)),
		(73.42, (146.83, 174.61, 220.0)), (58.27, (116.54, 146.83, 174.61)),
		(65.41, (130.81, 164.81, 196.0)), (55.0, (110.0, 138.59, 164.81)),
	]
	rhythm_rng = random.Random(seed)
	for beat in range(MUSIC_BARS * 4):
		start = beat * BEAT_SECONDS
		bar_beat = beat % 4
		if bar_beat in (0, 2):
			_add_tone(stems["rhythm"], start, 0.29, 52.0, 0.76, 14.0, -24.0, 0.45)
			_add_noise(stems["rhythm"], start, 0.085, 0.20, 95.0, rhythm_rng)
		if bar_beat in (1, 3):
			_add_noise(stems["rhythm"], start, 0.14, 0.29, 23.0, rhythm_rng)
		for offbeat in (0.0, 0.5):
			if offbeat == 0.5 or bar_beat in (1, 3):
				_add_noise(stems["rhythm"], start + BEAT_SECONDS * offbeat, 0.022, 0.095, 115.0, rhythm_rng)
	for bar in range(MUSIC_BARS):
		root, chord = chords[bar]
		bar_start = bar * BAR_SECONDS
		# Slow filter-like breathing in the pad is realized with overlapping octaves.
		for note_index, note in enumerate(chord):
			_add_tone(stems["pad"], bar_start, BAR_SECONDS, note, (0.075, 0.055, 0.042)[note_index], 0.10)
			_add_tone(stems["pad"], bar_start, BAR_SECONDS, note * 2.0, 0.018, 0.18)
		for step in range(16):
			start = bar_start + step * BEAT_SECONDS * 0.5
			bass_note = root if step in (0, 3, 6, 8, 11, 14) else root * 1.5
			_add_tone(stems["bass"], start, BEAT_SECONDS * 0.39, bass_note, 0.42, 5.5, 0.0, 0.34)
			if step % 2 == 0 or step in (3, 11, 15):
				arp_note = chord[(step // 2 + bar) % len(chord)] * (2.0 if step % 4 else 4.0)
				_add_tone(stems["arp"], start, BEAT_SECONDS * 0.28, arp_note, 0.105, 10.0, 0.0, 0.30)
			if step in (0, 7, 8, 15):
				_add_tone(stems["boss"], start, BEAT_SECONDS * 0.48, root * (1.0 if step in (0, 8) else 2.0), 0.20, 3.0, -5.0, 0.42)
		if bar in (3, 7):
			_add_noise(stems["boss"], bar_start + BAR_SECONDS - 0.18, 0.16, 0.12, 7.0, rhythm_rng)
	for stem in stems.values():
		_make_loop_seamless(stem)
	return stems


def _mix_stems(stems: dict[str, array], gains: dict[str, float]) -> array:
	count = len(next(iter(stems.values())))
	mix = array("f", [0.0]) * count
	for name, stem in stems.items():
		for index, sample in enumerate(stem):
			mix[index] += sample * gains[name]
	peak = max(abs(sample) for sample in mix)
	if peak > 0.82:
		mix = array("f", (sample * 0.82 / peak for sample in mix))
	return mix


def _render_music_cue(cue: str) -> array:
	"""Render a distinctly melodic, layered win/defeat synthwave stinger."""
	if cue == "victory_cue":
		notes, segment, sub = [293.66, 349.23, 440.0, 587.33, 698.46, 880.0], 0.22, 146.83
	else:
		notes, segment, sub = [440.0, 349.23, 293.66, 220.0, 164.81], 0.26, 82.41
	samples = array("f", [0.0]) * round(SAMPLE_RATE * (segment * (len(notes) - 1) + 0.72))
	_add_tone(samples, 0.0, len(samples) / SAMPLE_RATE, sub, 0.16, 0.9, 0.0, 0.24)
	for index, frequency in enumerate(notes):
		start = index * segment
		duration = 0.31 if index == len(notes) - 1 else segment * 0.92
		_add_tone(samples, start, duration, frequency, 0.30, 2.4, 0.0, 0.31)
		_add_tone(samples, start, duration, frequency * 2.0, 0.075, 3.2, 0.0, 0.18)
	for index in range(round(SAMPLE_RATE * 0.035)):
		gain = index / (SAMPLE_RATE * 0.035)
		samples[index] *= gain
	peak = max(abs(sample) for sample in samples)
	return array("f", (sample * min(1.0, 0.52 / peak) for sample in samples))


def _metadata(asset_id: str, kind: str, seed: int, metric: dict) -> dict:
	source_path = Path(__file__).resolve()
	return {
		"asset_id": asset_id, "kind": kind, "status": "candidate_not_approved",
		"skill": "dopamine-sfx" if kind == "sfx" else "dopamine-music",
		"generator": "game/tools/generate_original_audio.py", "generator_version": "5",
		"source_sha256": hashlib.sha256(source_path.read_bytes()).hexdigest(),
		"seed": seed,
		"parameters": {"sample_rate_hz": SAMPLE_RATE, "channels": 1, "encoding": "PCM16 WAV",
			"method": "event-contoured oscillator, transient, and role-specific synthesis v2" if kind == "sfx"
			else "124 BPM eight-bar layered synthwave EDM with phase-aligned stems"},
		"export": metric,
	}


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--kind", choices=("sfx", "music", "all"), default="all")
	parser.add_argument("--ids", nargs="+", help="Generate only selected SFX IDs")
	parser.add_argument("--seed", type=int, help="Explicit seed; otherwise stable ID seed is used")
	parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUTPUT_DIR,
		help="Output root; use build/staging until candidates are accepted")
	args = parser.parse_args()
	output_dir = args.out_dir.resolve()
	output_dir.mkdir(parents=True, exist_ok=True)
	results: dict[str, object] = {"output_dir": str(output_dir), "sfx": [], "music": []}
	if args.kind in ("sfx", "all"):
		ids = args.ids or SFX_IDS
		unknown = set(ids) - set(SFX_IDS)
		if unknown:
			parser.error(f"unknown SFX IDs: {sorted(unknown)}")
		sfx_directory = output_dir / "sfx"
		sfx_directory.mkdir(parents=True, exist_ok=True)
		for sound_id in ids:
			stable_seed = int.from_bytes(hashlib.sha256(sound_id.encode("utf-8")).digest()[:4], "little")
			seed = args.seed if args.seed is not None else stable_seed
			metric = _write_wave(sfx_directory / f"{sound_id}.wav", _render_sfx(sound_id, seed))
			metadata = _metadata(f"sfx_{sound_id}", "sfx", seed, metric)
			if any(sound_id == f"weapon_{weapon}_{event}" or sound_id.startswith(f"weapon_{weapon}_{event}_")
					for weapon in WEAPON_IDS for event in ("fire", "impact")):
				suffix = sound_id.rsplit("_", 1)[-1]
				variant_index = int(suffix) if suffix.isdigit() else 1
				metadata["parameters"].update({"variation_index": variant_index, "variation_count": 4})
			(sfx_directory / f"{sound_id}.json").write_text(json.dumps(
				metadata, indent=2) + "\n")
			results["sfx"].append(metric)
		(sfx_directory / "manifest.json").write_text(json.dumps({
			"status": "candidate_not_approved", "method": "role-specific oscillator/noise layers with analytic envelopes",
			"assets": results["sfx"],
		}, indent=2) + "\n")
	if args.kind in ("music", "all"):
		if args.ids:
			parser.error("--ids selects SFX only; music emits its synchronized stem set")
		music_directory = output_dir / "music"
		music_directory.mkdir(parents=True, exist_ok=True)
		seed = args.seed if args.seed is not None else 90210
		stems = _render_music_stems(seed)
		mix_gains = {"rhythm": 0.38, "bass": 0.34, "pad": 0.27, "arp": 0.22, "boss": 0.20}
		for name, stem in stems.items():
			metric = _write_wave(music_directory / f"{name}.wav", stem)
			metadata = _metadata(f"music_stem_{name}", "music", seed, metric)
			metadata.update({"tempo_bpm": MUSIC_BPM, "meter": "4/4", "bars": MUSIC_BARS,
				"loop_start_sample": 0, "loop_end_sample": MUSIC_SAMPLE_COUNT,
				"mix_gain_linear_proposed": mix_gains[name]})
			(music_directory / f"{name}.json").write_text(json.dumps(metadata, indent=2) + "\n")
			results["music"].append(metric)
		mixes = {
			"menu_theme": {"rhythm": 0.20, "bass": 0.22, "pad": 0.38, "arp": 0.12, "boss": 0.04},
			"survival_adaptive": mix_gains,
			"boss_intensity": {"rhythm": 0.42, "bass": 0.38, "pad": 0.18, "arp": 0.30, "boss": 0.50},
		}
		cue_directory = music_directory / "cues"
		cue_directory.mkdir(parents=True, exist_ok=True)
		cue_metrics = []
		for cue, gains in mixes.items():
			mix = _mix_stems(stems, gains)
			metric = _write_wave(cue_directory / f"{cue}.wav", mix)
			metadata_id = {
				"menu_theme": "music_menu_theme",
				"survival_adaptive": "music_preview_survival_adaptive",
				"boss_intensity": "music_preview_boss_intensity",
			}[cue]
			metadata = _metadata(metadata_id, "music", seed, metric)
			metadata.update({"tempo_bpm": MUSIC_BPM, "meter": "4/4", "bars": MUSIC_BARS,
				"loop": True, "loop_start_sample": 0, "loop_end_sample": MUSIC_SAMPLE_COUNT,
				"mix_gains_linear_proposed": gains})
			(cue_directory / f"{cue}.json").write_text(json.dumps(metadata, indent=2) + "\n")
			cue_metrics.append({**metric, "file": f"cues/{metric['file']}", "loop": True})
			if cue == "survival_adaptive":
				preview_mix = mix
		for cue in ("victory_cue", "defeat_cue"):
			mix = _render_music_cue(cue)
			metric = _write_wave(cue_directory / f"{cue}.wav", mix)
			metadata = _metadata(f"music_{cue}", "music", seed, metric)
			metadata.update({"loop": False, "notes_hz": [293.66, 369.99, 440.0, 587.33]
				if cue == "victory_cue" else [440.0, 349.23, 261.63, 220.0], "note_seconds": 0.32})
			(cue_directory / f"{cue}.json").write_text(json.dumps(metadata, indent=2) + "\n")
			cue_metrics.append({**metric, "file": f"cues/{metric['file']}", "loop": False})
		preview_metrics = _write_wave(music_directory / "preview_mix.wav", preview_mix)
		(music_directory / "manifest.json").write_text(json.dumps({
			"status": "candidate_not_approved", "generator": "game/tools/generate_original_audio.py",
			"generator_version": "4", "seed": seed, "tempo_bpm": MUSIC_BPM, "bars": MUSIC_BARS,
			"duration_seconds": round(MUSIC_SAMPLE_COUNT / SAMPLE_RATE, 6), "meter": "4/4",
			"key_center": "D minor (proposed)", "loop_start_sample": 0, "loop_end_sample": MUSIC_SAMPLE_COUNT,
			"mix_gains_linear_proposed": mix_gains, "stems": results["music"],
			"cues": cue_metrics, "preview_mix": preview_metrics,
		}, indent=2) + "\n")
		staged_sfx = sorted(path.stem for path in (output_dir / "sfx").glob("*.wav"))
		_write_preview(output_dir / "preview.html", staged_sfx)
	print(json.dumps(results, indent=2))


if __name__ == "__main__":
	main()
