#!/usr/bin/env python3
"""Fail if any current game asset exactly matches the immutable initial audit."""
import csv
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INITIAL = ROOT / "docs/art/ASSET_FILE_REGISTER.csv"
ASSETS = ROOT / "game/assets"

with INITIAL.open(newline="", encoding="utf-8") as stream:
    old_hashes = {row["sha256"]: row["path"] for row in csv.DictReader(stream)}

matches = []
files = 0
for path in sorted(ASSETS.rglob("*")):
    if not path.is_file() or path.name.endswith(".import"):
        continue
    files += 1
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest in old_hashes:
        matches.append((path.relative_to(ROOT).as_posix(), old_hashes[digest], digest))

if matches:
    for current, initial, digest in matches:
        print(f"REUSED {current} == initial {initial} ({digest})")
    raise SystemExit(f"FAIL: {len(matches)} exact legacy asset hashes remain")
print(f"PASS: {files} current assets have no exact SHA-256 match in the initial 425-file register")
