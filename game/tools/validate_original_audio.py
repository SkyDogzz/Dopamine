#!/usr/bin/env python3
"""Validate the integrated original audio library against its current manifest."""

import csv
import hashlib
import json
import math
import struct
import wave
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
MANIFEST = REPO_ROOT / "docs" / "art" / "ASSET_MANIFEST.json"
LEGACY_REGISTER = REPO_ROOT / "docs" / "art" / "ASSET_FILE_REGISTER.csv"
EXPECTED_SAMPLE_RATE = 44_100
EXPECTED_CHANNELS = 1
EXPECTED_SAMPLE_WIDTH = 2
MAX_SAMPLE = 32_766
MAX_LOOP_STEP = 32


def _legacy_hashes() -> set[str]:
	with LEGACY_REGISTER.open(newline="") as register:
		return {row["sha256"] for row in csv.DictReader(register)}


def main() -> None:
	manifest = json.loads(MANIFEST.read_text())
	legacy_hashes = _legacy_hashes()
	assets = [
		asset for asset in manifest["assets"]
		if asset.get("category") in {"sound_effect", "music", "music_stem"}
	]
	assert assets, "manifest contains no integrated audio assets"

	validated: list[dict[str, object]] = []
	sfx_hashes: set[str] = set()
	stem_lengths: set[int] = set()
	for asset in assets:
		path = REPO_ROOT / str(asset["integrated_path"])
		metadata_path = path.with_suffix(path.suffix + ".json")
		metadata = json.loads(metadata_path.read_text())
		data = path.read_bytes()
		sha256 = hashlib.sha256(data).hexdigest()
		assert sha256 == asset["export_sha256"], f"manifest hash mismatch: {path}"
		assert metadata["asset_id"] == asset["asset_id"], f"metadata ID mismatch: {metadata_path}"
		assert sha256 == metadata["export"]["sha256"], f"metadata hash mismatch: {metadata_path}"
		assert sha256 not in legacy_hashes, f"legacy audio hash reused: {path}"

		with wave.open(str(path), "rb") as audio:
			assert audio.getframerate() == EXPECTED_SAMPLE_RATE, f"sample rate: {path}"
			assert audio.getnchannels() == EXPECTED_CHANNELS, f"channel count: {path}"
			assert audio.getsampwidth() == EXPECTED_SAMPLE_WIDTH, f"sample width: {path}"
			frame_count = audio.getnframes()
			raw_samples = audio.readframes(frame_count)
		samples = struct.unpack("<" + "h" * frame_count, raw_samples)
		assert samples, f"empty audio: {path}"
		assert any(samples), f"silent audio: {path}"
		assert all(math.isfinite(sample) for sample in samples), f"non-finite sample: {path}"
		peak = max(map(abs, samples))
		assert peak <= MAX_SAMPLE, f"clipped sample: {path}"

		if asset["category"] == "sound_effect":
			duration = frame_count / EXPECTED_SAMPLE_RATE
			half_sample = 0.5 / EXPECTED_SAMPLE_RATE
			assert 0.045 - half_sample <= duration <= 0.95 + half_sample, \
				f"SFX duration out of documented range: {path}"
			assert sha256 not in sfx_hashes, f"duplicate SFX content: {path}"
			sfx_hashes.add(sha256)
		elif asset["category"] == "music_stem":
			stem_lengths.add(frame_count)

		if asset["category"] in {"music", "music_stem"} and metadata.get("loop", True):
			assert abs(samples[-1] - samples[0]) <= MAX_LOOP_STEP, f"loop discontinuity: {path}"
			assert metadata.get("loop_start_sample") == 0, f"bad loop start: {metadata_path}"
			assert metadata.get("loop_end_sample") == frame_count, f"bad loop end: {metadata_path}"
		validated.append({
			"asset_id": asset["asset_id"],
			"category": asset["category"],
			"frames": frame_count,
			"duration_seconds": frame_count / EXPECTED_SAMPLE_RATE,
			"peak": peak,
		})

	assert len(stem_lengths) == 1, "the five synchronized music stems must have equal lengths"
	sfx_count = sum(record["category"] == "sound_effect" for record in validated)
	stem_count = sum(record["category"] == "music_stem" for record in validated)
	music_count = sum(record["category"] == "music" for record in validated)
	assert (sfx_count, stem_count, music_count) == (125, 5, 3), "audio manifest coverage is incomplete"
	print(
		f"Validated {len(validated)} integrated audio assets: {sfx_count} distinct SFX, "
		f"{stem_count} equal-length synchronized stems, and {music_count} music cues; "
		"manifest/metadata hashes, PCM16 mono 44.1 kHz, non-empty unclipped samples, "
		"documented SFX duration range, and loop boundaries pass. Listening review remains separate."
	)


if __name__ == "__main__":
	main()
