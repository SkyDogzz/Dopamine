#!/usr/bin/env python3
"""Validate the generated original audio candidates against their manifests."""

import hashlib
import json
import math
import struct
import wave
import csv
from pathlib import Path


ASSET_ROOT = Path(__file__).resolve().parents[1] / "assets" / "audio" / "original_procedural"
REPO_ROOT = Path(__file__).resolve().parents[2]
EXPECTED_SAMPLE_RATE = 44_100
EXPECTED_CHANNELS = 1
EXPECTED_SAMPLE_WIDTH = 2
MAX_SAMPLE = 32_766
MAX_LOOP_STEP = 32
LEGACY_REGISTER = REPO_ROOT / "docs" / "art" / "ASSET_FILE_REGISTER.csv"


def _load_legacy_hashes() -> set[str]:
	with LEGACY_REGISTER.open(newline="") as register:
		return {row["sha256"] for row in csv.DictReader(register)}


def _read_candidate(manifest_path: Path, entry: dict[str, object], legacy_hashes: set[str]) -> tuple[Path, int, int, int]:
	path = manifest_path.parent / str(entry["file"])
	data = path.read_bytes()
	sha256 = hashlib.sha256(data).hexdigest()
	assert sha256 == entry["sha256"], f"SHA-256 mismatch: {path}"
	assert sha256 not in legacy_hashes, f"new candidate is byte-identical to an audited legacy asset: {path}"
	with wave.open(str(path), "rb") as audio:
		assert audio.getframerate() == EXPECTED_SAMPLE_RATE, f"sample rate: {path}"
		assert audio.getnchannels() == EXPECTED_CHANNELS, f"channels: {path}"
		assert audio.getsampwidth() == EXPECTED_SAMPLE_WIDTH, f"sample width: {path}"
		frame_count = audio.getnframes()
		frames = audio.readframes(frame_count)
	samples = struct.unpack("<" + "h" * frame_count, frames)
	assert samples, f"empty audio: {path}"
	assert all(math.isfinite(sample) for sample in samples), f"non-finite samples: {path}"
	peak = max(abs(sample) for sample in samples)
	assert peak <= MAX_SAMPLE, f"clipped sample: {path}"
	return path, frame_count, samples[0], samples[-1]


def main() -> None:
	legacy_hashes = _load_legacy_hashes()
	root_manifest_path = ASSET_ROOT / "manifest.json"
	root_manifest = json.loads(root_manifest_path.read_text())
	assert root_manifest["sfx_candidate_count"] == 38, "expected all 38 SFX candidates"
	validated = []

	sfx_manifest_path = ASSET_ROOT / "sfx" / "manifest.json"
	sfx_manifest = json.loads(sfx_manifest_path.read_text())
	sfx_entries = sfx_manifest["sounds"]
	assert len(sfx_entries) == 38, "SFX manifest must describe 38 files"
	sfx_hashes = [entry["sha256"] for entry in sfx_entries]
	assert len(set(sfx_hashes)) == 38, "SFX candidate files must be distinct"
	validated.extend(_read_candidate(sfx_manifest_path, entry, legacy_hashes) for entry in sfx_entries)

	music_manifest_path = ASSET_ROOT / "music" / "manifest.json"
	music_manifest = json.loads(music_manifest_path.read_text())
	music_entries = music_manifest["stems"] + [music_manifest["preview_mix"]]
	assert len(music_manifest["stems"]) == 5, "expected five synchronized music stems"
	loop_frames = None
	for entry in music_entries:
		result = _read_candidate(music_manifest_path, entry, legacy_hashes)
		path, frame_count, first_sample, last_sample = result
		assert abs(last_sample - first_sample) <= MAX_LOOP_STEP, f"loop boundary discontinuity: {path}"
		if loop_frames is None:
			loop_frames = frame_count
		else:
			assert frame_count == loop_frames, f"stem length mismatch: {path}"
		validated.append(result)

	print(f"Validated {len(validated)} WAV files: hashes, PCM16 mono 44.1 kHz, finite unclipped samples, distinct SFX, and continuous music loop boundaries.")


if __name__ == "__main__":
	main()
