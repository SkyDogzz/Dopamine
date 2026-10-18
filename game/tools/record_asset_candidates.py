#!/usr/bin/env python3
"""Record technically QA-passed staged candidate metadata in the asset manifest."""

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "docs/art/ASSET_MANIFEST.json"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--visual-root", type=Path)
    parser.add_argument("--audio-root", type=Path)
    parser.add_argument("--animation-root", type=Path)
    parser.add_argument("--visual-report", type=Path)
    parser.add_argument("--audio-report", type=Path)
    parser.add_argument("--animation-report", type=Path)
    parser.add_argument("--other-root", type=Path, action="append", default=[])
    parser.add_argument("--other-report", type=Path, action="append", default=[])
    args = parser.parse_args()
    manifest = json.loads(MANIFEST.read_text())
    by_id = {asset["asset_id"]: asset for asset in manifest["assets"]}
    recorded = []
    inputs = [(args.visual_root, args.visual_report), (args.audio_root, args.audio_report),
              (args.animation_root, args.animation_report)] + list(zip(args.other_root, args.other_report + [None] * max(0, len(args.other_root)-len(args.other_report))))
    for root, report_override in inputs:
        if root is None:
            continue
        root = root.resolve()
        report_path = report_override.resolve() if report_override else root / "qa-report.json"
        report = json.loads(report_path.read_text())
        assert report["status"] == "passed", f"QA did not pass: {report_path}"
        records = report.get("assets", report.get("animations", report.get("files", [])))
        for record in records:
            if "asset_id" in record:
                asset_id = record["asset_id"]
                if asset_id not in by_id and f"{asset_id}_icon" in by_id:
                    asset_id = f"{asset_id}_icon"
                image_field = record.get("png", record.get("export"))
                detail_path = Path(image_field).with_suffix(".json") if image_field else None
            else:
                filename = Path(record["path"]).name
                if filename == "preview_mix.wav":
                    continue
                stem = Path(filename).stem
                parent = Path(record["path"]).parts[-2]
                asset_id = stem if stem.startswith(("sfx_", "music_")) else f"sfx_{stem}" \
                    if parent == "sfx" else f"music_{stem}" if parent == "cues" else f"music_stem_{stem}"
                detail_path = Path(record["path"]).with_suffix(".json")
            if asset_id not in by_id:
                aliases = {"chest_closed":"chest_closed", "xp_orb":"xp_orb", "title_skyline":"title_skyline", "font_neonarcadepixel":"font_neonarcadepixel", "font_neonarcadeui":"font_neonarcadeui"}
                asset_id = aliases.get(asset_id, asset_id)
            if asset_id not in by_id:
                continue
            if detail_path is None:
                detail_path = Path(record.get("export", record.get("path", ""))).with_suffix(".json")
            if not detail_path.is_absolute() and not detail_path.exists():
                detail_path = root / detail_path
            metadata = json.loads(detail_path.read_text())
            asset = by_id[asset_id]
            asset["generation_status"] = "candidate"
            asset["validation_status"] = "passed"
            asset["human_review_status"] = "pending"
            asset["integration_status"] = "not_integrated"
            asset["authoring_source_or_recipe"] = metadata.get("generator", asset["authoring_source_or_recipe"])
            asset["generator_version"] = metadata.get("generator_version", "1")
            asset["generation_seed"] = metadata.get("seed", 0)
            asset["generation_parameters"] = metadata.get("parameters", metadata.get("dimensions", {}))
            asset["source_sha256"] = metadata.get("source_sha256")
            asset["export_sha256"] = metadata.get("export_sha256") or metadata.get("export", {}).get("sha256")
            exported = record.get("png", record.get("export", record.get("path")))
            if exported:
                export_path = Path(exported)
                if not export_path.is_absolute():
                    export_path = ROOT / export_path
                asset["candidate_export_path"] = str(export_path.resolve().relative_to(ROOT))
            source_name = metadata.get("source_path")
            if source_name:
                source_path = Path(source_name)
                if not source_path.is_absolute():
                    source_path = root / source_path
                try:
                    asset["candidate_source_path"] = str(source_path.resolve().relative_to(ROOT))
                except ValueError:
                    asset["candidate_source_path"] = str(source_path)
            asset["qa_report_path"] = str(report_path.relative_to(ROOT))
            recorded.append(asset_id)
    MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    print(json.dumps({"recorded_candidate_ids": sorted(set(recorded)), "count": len(set(recorded))}, indent=2))


if __name__ == "__main__":
    main()
