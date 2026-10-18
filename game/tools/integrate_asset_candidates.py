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


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ids", nargs="+", required=True, help="Exact manifest asset IDs to integrate")
    parser.add_argument("--dry-run", action="store_true", help="Validate scope and show files without copying")
    args = parser.parse_args()
    manifest = json.loads(MANIFEST.read_text())
    by_id = {item["asset_id"]: item for item in manifest["assets"]}
    unknown = sorted(set(args.ids) - set(by_id))
    if unknown:
        parser.error(f"unknown asset IDs: {unknown}")
    selected = [by_id[asset_id] for asset_id in args.ids]
    errors = []
    plan = []
    destinations = set()
    for item in selected:
        if item["validation_status"] != "passed":
            errors.append(f"{item['asset_id']}: validation_status is not passed")
        if not args.dry_run and item.get("human_review_status") != "accepted":
            errors.append(f"{item['asset_id']}: requires human_review_status=accepted in the manifest")
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
        if target.exists() and sha256(target) != actual_hash:
            errors.append(f"{item['asset_id']}: target exists with different bytes; refusing overwrite: {target}")
        source = ROOT / item["candidate_source_path"] if item.get("candidate_source_path") else None
        meta_path = src.with_suffix(".json")
        metadata = json.loads(meta_path.read_text()) if meta_path.exists() else {}
        sidecar_target = target.with_suffix(target.suffix + ".json")
        if sidecar_target.exists() and meta_path.exists() and sha256(sidecar_target) != sha256(meta_path):
            errors.append(f"{item['asset_id']}: sidecar exists with different bytes; refusing overwrite: {sidecar_target}")
        source_target = ROOT / "game/assets/source/accepted" / f"{item['asset_id']}{source.suffix}" if source else None
        if source_target and source_target.exists() and source and sha256(source_target) != sha256(source):
            errors.append(f"{item['asset_id']}: authoring source exists with different bytes; refusing overwrite: {source_target}")
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
        if not target.exists():
            shutil.copy2(src, target)
        sidecar = target.with_suffix(target.suffix + ".json")
        if metadata_path.is_file():
            shutil.copy2(metadata_path, sidecar)
        if source and source.is_file():
            source_target.parent.mkdir(parents=True, exist_ok=True)
            if not source_target.exists():
                shutil.copy2(source, source_target)
        if sprite_frames:
            if not resource_target.exists():
                resource_target.write_text(sprite_frames)
            item["godot_animation_resource"] = str(resource_target.relative_to(ROOT))
        item["integration_status"] = "integrated"
        item["integrated_path"] = str(target.relative_to(ROOT))
    MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
