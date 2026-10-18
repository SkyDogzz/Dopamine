#!/usr/bin/env python3
"""Refresh current asset hashes and provenance from the integrated manifest and sidecars."""

import csv
import hashlib
import json
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "game/assets"
MANIFEST = ROOT / "docs/art/ASSET_MANIFEST.json"
REGISTER = ROOT / "docs/art/ASSET_FILE_REGISTER_CURRENT.csv"
PROVENANCE = ROOT / "docs/art/PROVENANCE_ASSETS.csv"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def manifest_assets() -> dict[str, dict]:
    data = json.loads(MANIFEST.read_text())
    return {item["integrated_path"]: item for item in data["assets"] if item.get("integrated_path")}


def package_status(rel: str) -> str:
    if rel.endswith(".import") or rel.endswith(".json") or rel.endswith(".aseprite") or rel.endswith(".sfd") or "/source/" in rel or rel.endswith("/README.md"):
        return "excluded by preset: authoring/source metadata"
    if "/sprites/vfx/" in rel and rel.endswith(".png"):
        return "included by all_resources; runtime VFX"
    return "included by all_resources"


def main() -> None:
    manifest = manifest_assets()
    files = sorted(path for path in ASSETS.rglob("*") if path.is_file())
    register_rows = []
    provenance_rows = []
    for path in files:
        rel = path.relative_to(ROOT).as_posix()
        ext = path.suffix.lower()
        asset = manifest.get(rel)
        if ext in (".png", ".wav", ".ogg", ".ttf", ".otf"):
            kind = "audio_export_or_reference" if ext in (".wav", ".ogg") else "font_export" if ext in (".ttf", ".otf") else "visual_export"
            reference = f"manifest:{asset['asset_id']}" if asset else "adjacent generation metadata"
            register_rows.append({"path": rel, "sha256": digest(path), "bytes": str(path.stat().st_size), "kind": kind,
                                  "reference_locations_or_loader": reference,
                                  "reference_status": "manifest_runtime_destination" if asset else "preview_or_supporting_export",
                                  "package_status": package_status(rel)})
            if ext not in (".png", ".wav", ".ogg", ".ttf", ".otf"):
                continue
            sidecar = path.with_suffix(path.suffix + ".json")
            meta = json.loads(sidecar.read_text()) if sidecar.is_file() else {}
            generator = meta.get("generator") or (asset or {}).get("authoring_source_or_recipe", "")
            if not generator or not (ROOT / generator).is_file():
                raise SystemExit(f"No valid local generation source for {rel}: {generator}")
            source_rel = meta.get("source_path", "")
            source = (ASSETS / source_rel) if source_rel else None
            source_path = source.relative_to(ROOT).as_posix() if source and source.is_file() else ""
            if source and not source.is_file():
                raise SystemExit(f"Missing integrated editable source for {rel}: {source}")
            provenance_rows.append({
                "path": rel, "format": ext.removeprefix("."), "sha256": digest(path), "bytes": str(path.stat().st_size),
                "editable_source_candidates": source_path, "package_status": package_status(rel),
                "provenance_rights_status": "Original local procedural generation; no cloud or third-party media used",
                "provenance_reference": generator, "reference_sha256": digest(ROOT / generator),
                "c2pa_validation": "Not applicable: generated locally by repository code", "c2pa_manifest_id": "",
                "generation_script": generator, "rights_basis": "Original code-generated asset using project palette/recipes; no external recordings or imagery",
                "release_action": "Provisional gameplay prototype; art/audio review remains pending where documented",
            })
        else:
            register_rows.append({"path": rel, "sha256": digest(path), "bytes": str(path.stat().st_size),
                                  "kind": "authoring_or_metadata", "reference_locations_or_loader": "",
                                  "reference_status": "authoring_or_audit_metadata", "package_status": package_status(rel)})
    with REGISTER.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=["path", "sha256", "bytes", "kind", "reference_locations_or_loader", "reference_status", "package_status"], lineterminator="\n")
        writer.writeheader(); writer.writerows(register_rows)
    with PROVENANCE.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=["path", "format", "sha256", "bytes", "editable_source_candidates", "package_status", "provenance_rights_status", "provenance_reference", "reference_sha256", "c2pa_validation", "c2pa_manifest_id", "generation_script", "rights_basis", "release_action"], lineterminator="\n")
        writer.writeheader(); writer.writerows(provenance_rows)
    print(json.dumps({"registered_files": len(register_rows), "creative_assets": len(provenance_rows)}, indent=2))


if __name__ == "__main__":
    main()
