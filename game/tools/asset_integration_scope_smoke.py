#!/usr/bin/env python3
"""Exercise the asset integrator's ID-scoped replacement guard in a temp repo."""

import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="dopamine-asset-scope-") as temp:
        root = Path(temp)
        (root / "game/tools").mkdir(parents=True)
        (root / "docs/art").mkdir(parents=True)
        integrator = Path(__file__).with_name("integrate_asset_candidates.py")
        (root / "game/tools/integrate_asset_candidates.py").write_bytes(integrator.read_bytes())

        candidate = root / "build/assets/candidates/scope-test/sprites/test.png"
        candidate_source = root / "build/assets/candidates/scope-test/source/animation/test.aseprite"
        target = root / "game/assets/sprites/test.png"
        source_target = root / "game/assets/source/animation/test.aseprite"
        candidate.parent.mkdir(parents=True)
        candidate_source.parent.mkdir(parents=True)
        target.parent.mkdir(parents=True)
        source_target.parent.mkdir(parents=True)
        candidate.write_bytes(b"new export")
        candidate_source.write_bytes(b"new editable source")
        target.write_bytes(b"old export")
        source_target.write_bytes(b"old editable source")

        export_rel = "build/assets/candidates/scope-test/sprites/test.png"
        source_rel = "build/assets/candidates/scope-test/source/animation/test.aseprite"
        dest_rel = "game/assets/sprites/test.png"
        metadata = {
            "asset_id": "test_asset", "source_path": "source/animation/test.aseprite",
            "export_path": "sprites/test.png", "candidate_export_path": export_rel,
            "integrated_export_path": dest_rel,
        }
        (candidate.with_suffix(".json")).write_text(json.dumps(metadata))
        (target.with_suffix(".png.json")).write_text(json.dumps(metadata))
        manifest = {
            "assets": [{
                "asset_id": "test_asset", "validation_status": "passed",
                "acceptance_status": "accepted_for_provisional_production",
                "acceptance_basis": "isolated scope smoke", "human_review_status": "pending",
                "candidate_export_path": export_rel, "candidate_source_path": source_rel,
                "godot_destination": "res://assets/sprites/test.png",
                "export_sha256": digest(candidate.read_bytes()),
                "source_sha256": digest(candidate_source.read_bytes()),
            }]
        }
        manifest_path = root / "docs/art/ASSET_MANIFEST.json"
        manifest_path.write_text(json.dumps(manifest))

        command = [sys.executable, str(root / "game/tools/integrate_asset_candidates.py"),
                   "--ids", "test_asset", "--dry-run"]
        refused = subprocess.run(command, capture_output=True, text=True)
        assert refused.returncode != 0 and "not explicitly authorized" in refused.stderr

        allowed = subprocess.run(command + ["--replace-ids", "test_asset"], capture_output=True, text=True)
        assert allowed.returncode == 0, allowed.stderr
        assert target.read_bytes() == b"old export"
        assert source_target.read_bytes() == b"old editable source"
        assert json.loads(manifest_path.read_text())["assets"][0]["export_sha256"] == digest(candidate.read_bytes())

        metadata["asset_id"] = "unrelated_asset"
        target.with_suffix(".png.json").write_text(json.dumps(metadata))
        wrong_owner = subprocess.run(command + ["--replace-ids", "test_asset"], capture_output=True, text=True)
        assert wrong_owner.returncode != 0 and "not explicitly authorized" in wrong_owner.stderr

    print("Asset integration scope smoke passed")


if __name__ == "__main__":
    main()
