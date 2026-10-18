#!/usr/bin/env python3
"""Check that the asset backlog is complete and structurally unambiguous."""

import json
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
	print(f"Manifest valid: {len(assets)} unique assets, all required fields and skill assignments present.")


if __name__ == "__main__":
	main()
