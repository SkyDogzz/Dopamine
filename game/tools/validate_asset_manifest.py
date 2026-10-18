#!/usr/bin/env python3
"""Check that the asset backlog is complete and structurally unambiguous."""

import json
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "docs" / "art" / "ASSET_MANIFEST.json"
REQUIRED = {
	"asset_id", "category", "gameplay_entity_or_system", "required_animations_or_variants",
	"required_audio_events", "target_format_and_dimensions", "assigned_generation_skill",
	"godot_destination", "authoring_source_or_recipe", "generator_version", "generation_seed",
	"generation_parameters", "source_sha256", "export_sha256", "qa_report_path",
	"generation_status", "validation_status", "human_review_status", "integration_status", "blockers",
}
SKILLS = {"dopamine-pixel-art", "dopamine-animation", "dopamine-sfx", "dopamine-music"}


def main() -> None:
	manifest = json.loads(MANIFEST.read_text())
	assets = manifest.get("assets")
	assert isinstance(assets, list) and assets, "manifest must contain an asset list"
	ids = [asset.get("asset_id") for asset in assets]
	assert all(isinstance(asset_id, str) and asset_id for asset_id in ids), "every asset needs a stable ID"
	assert len(ids) == len(set(ids)), "duplicate asset IDs"
	for asset in assets:
		missing = REQUIRED - asset.keys()
		assert not missing, f"{asset.get('asset_id')}: missing fields {sorted(missing)}"
		assert asset["assigned_generation_skill"] in SKILLS, f"{asset['asset_id']}: invalid skill"
		assert asset["generation_status"] in {"not_generated", "candidate", "generated", "blocked"}
		assert asset["validation_status"] in {"not_run", "passed", "failed", "blocked"}
		assert isinstance(asset["target_format_and_dimensions"], dict)
		assert isinstance(asset["generation_parameters"], dict)
		assert asset["generation_status"] == "candidate", f"{asset['asset_id']}: unexpected generation status"
		assert asset["validation_status"] == "passed", f"{asset['asset_id']}: asset has not passed QA"
		assert asset["integration_status"] == "integrated", f"{asset['asset_id']}: not integrated"
		integrated_path = asset.get("integrated_path")
		assert isinstance(integrated_path, str) and integrated_path, f"{asset['asset_id']}: missing integrated path"
		destination = asset["godot_destination"]
		assert destination.startswith("res://"), f"{asset['asset_id']}: invalid Godot URI {destination!r}"
		assert destination == "res://" + integrated_path.removeprefix("game/"), (
			f"{asset['asset_id']}: Godot URI and integrated path disagree"
		)
		source_script = asset["authoring_source_or_recipe"].split(";", 1)[0].strip()
		generator_path = ROOT / source_script
		assert generator_path.is_file(), f"{asset['asset_id']}: missing generator {source_script}"
		export_path = ROOT / integrated_path
		assert export_path.is_file(), f"{asset['asset_id']}: missing integrated export {integrated_path}"
		export_hash = hashlib.sha256(export_path.read_bytes()).hexdigest()
		assert export_hash == asset["export_sha256"], f"{asset['asset_id']}: stale export_sha256"
		source_path = asset.get("integrated_source_path")
		if source_path:
			source_file = ROOT / source_path
			assert source_file.is_file(), f"{asset['asset_id']}: missing editable source {source_path}"
		else:
			# Audio is reproducible from the generator and per-asset parameters; its source hash
			# records that generator rather than a separate binary project file.
			source_file = generator_path
		source_hash = hashlib.sha256(source_file.read_bytes()).hexdigest()
		assert source_hash == asset["source_sha256"], f"{asset['asset_id']}: stale source_sha256"
	print(f"Manifest valid: {len(assets)} unique assets; source/export hashes, Godot paths, generators, QA and integration verified.")


if __name__ == "__main__":
	main()
