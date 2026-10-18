#!/usr/bin/env python3
"""Verify hashes and editable/generative sources for every current creative asset."""
import csv
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REGISTER = ROOT / "docs/art/ASSET_FILE_REGISTER_CURRENT.csv"
PROVENANCE = ROOT / "docs/art/PROVENANCE_ASSETS.csv"
INITIAL = ROOT / "docs/art/ASSET_FILE_REGISTER.csv"
MIGRATIONS = ROOT / "docs/art/ASSET_MIGRATIONS.csv"
RETIREMENTS = ROOT / "docs/art/ASSET_RETIREMENTS.csv"
CREATIVE_SUFFIXES = {".png", ".svg", ".ttf", ".wav", ".ogg"}
AUDIT_SUFFIXES = CREATIVE_SUFFIXES | {".aseprite", ".sfd"}

with REGISTER.open(newline="", encoding="utf-8") as stream:
    asset_rows = list(csv.DictReader(stream))
assets = {row["path"]: row for row in asset_rows}
with PROVENANCE.open(newline="", encoding="utf-8") as stream:
    provenance = {row["path"]: row for row in csv.DictReader(stream)}
with INITIAL.open(newline="", encoding="utf-8") as stream:
    initial = list(csv.DictReader(stream))
with MIGRATIONS.open(newline="", encoding="utf-8") as stream:
    migrations = {(row["legacy_runtime_path"], row["legacy_runtime_sha256"]) for row in csv.DictReader(stream)}
with RETIREMENTS.open(newline="", encoding="utf-8") as stream:
    retirements = {(row["path"], row["sha256"]) for row in csv.DictReader(stream)}

errors = []
checked = 0
for relpath, row in assets.items():
    registered_path = ROOT / relpath
    if not registered_path.is_file():
        errors.append(f"missing current registry path: {relpath}")
    else:
        registered_bytes = registered_path.read_bytes()
        if hashlib.sha256(registered_bytes).hexdigest() != row["sha256"] or len(registered_bytes) != int(row["bytes"]):
            errors.append(f"stale current registry hash/size: {relpath}")
    path = ROOT / relpath
    if path.suffix.lower() not in CREATIVE_SUFFIXES:
        continue
    if not path.is_file():
        errors.append(f"missing registered asset: {relpath}")
        continue
    record = provenance.get(relpath)
    if record is None:
        errors.append(f"missing provenance row: {relpath}")
        continue
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if record["sha256"] != digest or row["sha256"] != digest:
        errors.append(f"stale SHA-256: {relpath}")
    generator = record["generation_script"]
    if not generator or not (ROOT / generator).is_file():
        errors.append(f"missing production source: {relpath} ({generator})")
    reference = record["provenance_reference"]
    reference_hash = record["reference_sha256"]
    if reference:
        reference_path = ROOT / reference
        if not reference_path.is_file():
            errors.append(f"missing provenance reference {reference} for {relpath}")
        elif reference_hash and hashlib.sha256(reference_path.read_bytes()).hexdigest() != reference_hash:
            errors.append(f"stale provenance reference hash {reference} for {relpath}")
    for candidate in record["editable_source_candidates"].split("; "):
        if not candidate:
            continue
        candidate_path = ROOT / candidate
        if not candidate_path.is_file():
            errors.append(f"missing source/provenance input {candidate} for {relpath}")
            continue
        if candidate.startswith("game/assets/"):
            source_row = assets.get(candidate)
            if source_row is None:
                errors.append(f"editable asset source is absent from current registry: {candidate}")
            else:
                source_bytes = candidate_path.read_bytes()
                if hashlib.sha256(source_bytes).hexdigest() != source_row["sha256"] or len(source_bytes) != int(source_row["bytes"]):
                    errors.append(f"stale source registry hash/size: {candidate}")
    checked += 1

historical_checked = 0
for old in initial:
    relpath = old["path"]
    if Path(relpath).suffix.lower() not in AUDIT_SUFFIXES:
        continue
    historical_checked += 1
    live_path = ROOT / relpath
    if live_path.is_file():
        live_hash = hashlib.sha256(live_path.read_bytes()).hexdigest()
        if live_hash != old["sha256"] and (relpath, old["sha256"]) not in migrations and (relpath, old["sha256"]) not in retirements:
            errors.append(f"missing migration/retirement record for changed initial asset: {relpath}")
    elif (relpath, old["sha256"]) not in retirements:
        errors.append(f"missing retirement record for absent initial asset: {relpath}")

if errors:
    print("\n".join(errors))
    raise SystemExit(f"FAIL: {len(errors)} asset provenance errors across {checked} current and {historical_checked} initial creative assets")
print(f"PASS: {checked} current creative assets match hashes and sources; {historical_checked} initial creative assets have migration or retirement records")
