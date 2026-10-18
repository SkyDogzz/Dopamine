#!/usr/bin/env python3
"""Run local numeric and provenance QA on staged Dopamine audio candidates."""

import argparse
import hashlib
import json
import math
import struct
import wave
from pathlib import Path

EXPECTED_RATE = 44_100
EXPECTED_CHANNELS = 1
EXPECTED_WIDTH = 2
MAX_SAMPLE = 32_766
MAX_LOOP_STEP = 32


def read_wav(path: Path) -> tuple[int, list[int]]:
    with wave.open(str(path), "rb") as stream:
        assert stream.getframerate() == EXPECTED_RATE, f"sample rate mismatch: {path}"
        assert stream.getnchannels() == EXPECTED_CHANNELS, f"channel mismatch: {path}"
        assert stream.getsampwidth() == EXPECTED_WIDTH, f"encoding is not PCM16: {path}"
        count = stream.getnframes()
        raw = stream.readframes(count)
    samples = list(struct.unpack("<" + "h" * count, raw))
    assert samples, f"empty WAV: {path}"
    assert all(math.isfinite(float(sample)) for sample in samples), f"non-finite samples: {path}"
    assert max(map(abs, samples)) <= MAX_SAMPLE, f"clipping: {path}"
    assert any(samples), f"silence: {path}"
    return count, samples


def validate(root: Path) -> dict:
    report = {"status": "passed", "root": str(root), "sample_rate_hz": EXPECTED_RATE,
              "encoding": "PCM16 mono", "files": [], "errors": []}
    for subdir in (root / "sfx", root / "music"):
        manifest_path = subdir / "manifest.json"
        if not manifest_path.exists():
            continue
        manifest = json.loads(manifest_path.read_text())
        entries = manifest.get("assets") if subdir.name == "sfx" else manifest.get("stems", []) + manifest.get("cues", [])
        stem_lengths = set()
        for entry in entries:
            path = subdir / entry["file"] if subdir.name == "sfx" or "/" in entry["file"] else subdir / entry["file"]
            count, samples = read_wav(path)
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            assert digest == entry["sha256"], f"manifest hash mismatch: {path}"
            metadata_path = path.with_suffix(".json")
            metadata = json.loads(metadata_path.read_text())
            assert metadata["export"]["sha256"] == digest, f"metadata hash mismatch: {metadata_path}"
            assert metadata["seed"] is not None, f"missing seed: {metadata_path}"
            record = {"path": str(path), "sha256": digest, "frames": count,
                      "duration_seconds": round(count / EXPECTED_RATE, 6),
                      "peak_dbfs": round(20 * math.log10(max(map(abs, samples)) / 32768), 3)}
            if subdir.name == "music":
                if metadata.get("loop", True):
                    assert abs(samples[-1] - samples[0]) <= MAX_LOOP_STEP, f"loop discontinuity: {path}"
                    assert metadata["loop_start_sample"] == 0, f"bad loop start: {metadata_path}"
                    assert metadata["loop_end_sample"] == count, f"bad loop end: {metadata_path}"
                if path.parent == subdir:
                    stem_lengths.add(count)
            report["files"].append(record)
        if subdir.name == "music":
            assert len(stem_lengths) <= 1, "music stem lengths differ"
            preview = subdir / "preview_mix.wav"
            if preview.exists():
                count, samples = read_wav(preview)
                assert abs(samples[-1] - samples[0]) <= MAX_LOOP_STEP, f"loop discontinuity: {preview}"
                report["files"].append({"path": str(preview), "frames": count,
                                       "sha256": hashlib.sha256(preview.read_bytes()).hexdigest()})
    assert report["files"], "no candidate files found"
    return report


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path, help="Staged audio output root")
    parser.add_argument("--report", type=Path, help="Write JSON QA report")
    args = parser.parse_args()
    result = validate(args.root.resolve())
    encoded = json.dumps(result, indent=2)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(encoded + "\n")
    print(encoded)


if __name__ == "__main__":
    main()
