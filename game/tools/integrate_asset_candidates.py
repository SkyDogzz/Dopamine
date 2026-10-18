#!/usr/bin/env python3
"""Copy explicitly accepted, QA-passed candidate IDs into their exact Godot destinations."""

import argparse
import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "docs/art/ASSET_MANIFEST.json"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def make_sprite_frames(meta: dict, texture_path: str) -> str | None:
    grid, frame_size = meta.get("grid"), meta.get("frame_size")
    if not grid or not frame_size:
        return None
    columns, rows = grid
    fw, fh = frame_size
    directions = meta.get("directions", ["forward"] * rows)
    fps = float(meta.get("fps_proposed", 8))
    animation = meta.get("asset_id", "animation")
    loop = animation.endswith(("_idle", "_walk", "_move")) or "projectile" in animation
    frames = []
    for row in range(rows):
        name = f"{animation}_{directions[row]}" if rows > 1 else animation
        frame_list = [f'{{"duration": 1.0, "texture": ExtResource("1_texture"), "region": Rect2({col*fw}, {row*fh}, {fw}, {fh})}}' for col in range(columns)]
        frames.append(f'{{"frames": [{", ".join(frame_list)}], "loop": {str(loop).lower()}, "name": &{json.dumps(name)}, "speed": {fps}}}')
    return ("[gd_resource type=\"SpriteFrames\" load_steps=2 format=3]\n\n"
            f'[ext_resource type="Texture2D" path={json.dumps(texture_path)} id="1_texture"]\n\n'
            "[resource]\n" + f"animations = [{', '.join(frames)}]\n")


def source_destination(source: Path | None, asset_id: str = "") -> Path | None:
    if source is None:
        return None
    parts = source.relative_to(ROOT).parts
    try:
        marker = parts.index("source")
    except ValueError:
        return ROOT / "game/assets/source/accepted" / source.name
    relative = Path(*parts[marker + 1:])
    if relative.parts[:1] == ("animation",) and source.stem != Path(asset_id).stem:
        relative = relative.with_name(Path(asset_id).name + relative.suffix)
    return ROOT / "game/assets/source" / relative


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ids", nargs="+", required=True, help="Exact manifest asset IDs to integrate")
    parser.add_argument("--replace-ids", nargs="*", default=[],
                        help="IDs authorized for regeneration; existing targets must prove the same managed ID/path")
    parser.add_argument("--dry-run", action="store_true", help="Validate scope and show files without copying")
    args = parser.parse_args()
    if not set(args.replace_ids) <= set(args.ids):
        parser.error("--replace-ids must be a subset of --ids")
    manifest = json.loads(MANIFEST.read_text())
    by_id = {item["asset_id"]: item for item in manifest["assets"]}
    unknown = sorted(set(args.ids) - set(by_id))
    if unknown:
        parser.error(f"unknown asset IDs: {unknown}")
    selected = [by_id[asset_id] for asset_id in args.ids]
    errors = []
    plan = []
    destinations = set()
    source_destinations = set()
    for item in selected:
        if item["validation_status"] != "passed":
            errors.append(f"{item['asset_id']}: validation_status is not passed")
        if not args.dry_run and item.get("acceptance_status") not in ("accepted", "accepted_for_provisional_production"):
            errors.append(f"{item['asset_id']}: requires explicit acceptance_status in the manifest")
        src = ROOT / item.get("candidate_export_path", "")
        if not src.is_file():
            errors.append(f"{item['asset_id']}: candidate export missing: {src}")
            continue
        actual_hash = sha256(src)
        if item.get("export_sha256") and actual_hash != item["export_sha256"]:
            errors.append(f"{item['asset_id']}: candidate export hash differs from QA record")
        destination = item["godot_destination"]
        if not destination.startswith("res://"):
            errors.append(f"{item['asset_id']}: unsupported Godot destination {destination}")
            continue
        target = ROOT / "game" / destination.removeprefix("res://")
        if target in destinations:
            errors.append(f"{item['asset_id']}: destination collision at {target}")
        destinations.add(target)
        source = ROOT / item["candidate_source_path"] if item.get("candidate_source_path") else None
        if source is not None and not source.is_file():
            errors.append(f"{item['asset_id']}: authoring source missing: {source}")
        if source is not None and item.get("source_sha256") and sha256(source) != item["source_sha256"]:
            errors.append(f"{item['asset_id']}: authoring source hash differs from QA record")
        meta_path = src.with_suffix(".json")
        metadata = json.loads(meta_path.read_text()) if meta_path.exists() else {}
        sidecar_target = target.with_suffix(target.suffix + ".json")
        source_target = source_destination(source, item["asset_id"])
        replace_authorized = item["asset_id"] in args.replace_ids
        if target.exists() and sha256(target) != actual_hash:
            try:
                current_metadata = json.loads(sidecar_target.read_text())
            except (OSError, json.JSONDecodeError):
                current_metadata = {}
            managed_target = (
                current_metadata.get("asset_id") == item["asset_id"]
                and current_metadata.get("integrated_export_path") == str(target.relative_to(ROOT))
            )
            if not replace_authorized or not managed_target:
                errors.append(f"{item['asset_id']}: target differs and is not explicitly authorized as the same managed asset: {target}")
        if sidecar_target.exists() and meta_path.exists() and sha256(sidecar_target) != sha256(meta_path):
            try:
                existing_sidecar = json.loads(sidecar_target.read_text())
            except (OSError, json.JSONDecodeError):
                existing_sidecar = {}
            managed_sidecar = (
                existing_sidecar.get("candidate_export_path") == str(src.relative_to(ROOT))
                and existing_sidecar.get("integrated_export_path") == str(target.relative_to(ROOT))
            )
            same_managed_asset = (
                existing_sidecar.get("asset_id") == item["asset_id"]
                and existing_sidecar.get("integrated_export_path") == str(target.relative_to(ROOT))
            )
            managed_sidecar = managed_sidecar or (replace_authorized and same_managed_asset)
            if not managed_sidecar:
                errors.append(f"{item['asset_id']}: sidecar exists with different bytes and is not managed for this candidate; refusing overwrite: {sidecar_target}")
        if source_target and source_target in source_destinations:
            errors.append(f"{item['asset_id']}: authoring source destination collision at {source_target}")
        if source_target:
            source_destinations.add(source_target)
        if source_target and source_target.exists() and source and sha256(source_target) != sha256(source):
            try:
                current_metadata = json.loads(sidecar_target.read_text())
            except (OSError, json.JSONDecodeError):
                current_metadata = {}
            managed_source = (
                current_metadata.get("asset_id") == item["asset_id"]
                and (current_metadata.get("integrated_source_path") == str(source_target.relative_to(ROOT))
                     or current_metadata.get("source_path") == str(source_target.relative_to(ROOT / "game/assets")))
            )
            if not replace_authorized or not managed_source:
                errors.append(f"{item['asset_id']}: source differs and is not explicitly authorized as the same managed asset: {source_target}")
        sprite_frames = make_sprite_frames(metadata, destination)
        resource_target = target.with_suffix(".tres") if sprite_frames else None
        if resource_target and resource_target.exists() and resource_target.read_text() != sprite_frames:
            errors.append(f"{item['asset_id']}: animation resource exists with different bytes; refusing overwrite: {resource_target}")
        plan.append((item, src, target, source, actual_hash, metadata, source_target, sprite_frames, resource_target, meta_path))
    if errors:
        raise SystemExit("Integration refused:\n- " + "\n- ".join(errors))
    print(json.dumps({"mode": "dry_run" if args.dry_run else "copy", "count": len(plan),
                      "files": [{"asset_id": item["asset_id"], "candidate": str(src.relative_to(ROOT)),
                                 "destination": str(target.relative_to(ROOT)), "sha256": digest,
                                 "source": str(source.relative_to(ROOT)) if source and source.is_file() else None}
                                for item, src, target, source, digest, _metadata, _source_target, _frames, _resource_target, _meta_path in plan]}, indent=2))
    if args.dry_run:
        return
    for item, src, target, source, digest, metadata, source_target, sprite_frames, resource_target, metadata_path in plan:
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists() or sha256(target) != digest:
            shutil.copy2(src, target)
        sidecar = target.with_suffix(target.suffix + ".json")
        if metadata_path.is_file():
            accepted_metadata = metadata.copy()
            accepted_metadata["status"] = "provisionally_integrated"
            accepted_metadata["acceptance_status"] = item.get("acceptance_status")
            accepted_metadata["acceptance_basis"] = item.get("acceptance_basis", "")
            accepted_metadata["human_review_status"] = item.get("human_review_status", "pending")
            accepted_metadata["candidate_export_path"] = str(src.relative_to(ROOT))
            accepted_metadata["integrated_export_path"] = str(target.relative_to(ROOT))
            accepted_metadata["export_path"] = str(target.relative_to(ROOT / "game/assets"))
            if source_target:
                accepted_metadata["source_path"] = str(source_target.relative_to(ROOT / "game/assets"))
            sidecar.write_text(json.dumps(accepted_metadata, indent=2, ensure_ascii=False) + "\n")
        if source and source.is_file():
            source_target.parent.mkdir(parents=True, exist_ok=True)
            if not source_target.exists() or sha256(source_target) != sha256(source):
                shutil.copy2(source, source_target)
        if sprite_frames:
            if not resource_target.exists():
                resource_target.write_text(sprite_frames)
            item["godot_animation_resource"] = str(resource_target.relative_to(ROOT))
        item["integration_status"] = "integrated"
        item["integrated_path"] = str(target.relative_to(ROOT))
        if source_target:
            item["integrated_source_path"] = str(source_target.relative_to(ROOT))
    MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
