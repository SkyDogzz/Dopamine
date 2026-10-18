#!/usr/bin/env python3
"""Check that the asset backlog is complete and structurally unambiguous."""

import json
import hashlib
import re
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
	validate_audio_coverage(assets)
	print(f"Manifest valid: {len(assets)} unique assets; source/export hashes, Godot paths, generators, QA and integration verified.")


def validate_audio_coverage(assets: list[dict]) -> None:
	sfx_source = (ROOT / "game/scripts/sfx_service.gd").read_text()
	sounds_block = sfx_source.split("const SOUNDS := {", 1)[1].split("const PRIORITY := {", 1)[0]
	expected_sfx = {
		name for values in re.findall(r'"[^"\n]+": \[([^\]]*)\]', sounds_block)
		for name in re.findall(r'"([^"\n]+)"', values)
	}
	weapon_block = re.search(r"const WEAPON_IDS := \[(.*?)\]", sfx_source, re.S)
	assert weapon_block, "SfxService must declare its weapon sound IDs"
	weapon_ids = re.findall(r'"([^"\n]+)"', weapon_block.group(1))
	expected_sfx.update({f"weapon_{weapon}_{event}" for weapon in weapon_ids for event in ("fire", "impact")})
	expected_sfx.update({"victory", "defeat", "damage_taken", "healing", "explosion"})
	manifest_sfx = {asset["asset_id"].removeprefix("sfx_") for asset in assets if asset["category"] == "sound_effect"}
	assert manifest_sfx == expected_sfx, (
		f"SFX coverage mismatch; missing={sorted(expected_sfx - manifest_sfx)}, "
		f"orphaned={sorted(manifest_sfx - expected_sfx)}"
	)
	for asset in assets:
		if asset["category"] not in {"sound_effect", "music", "music_stem"}:
			continue
		metadata_path = ROOT / (asset["integrated_path"] + ".json")
		assert metadata_path.is_file(), f"{asset['asset_id']}: missing integrated audio metadata"
		metadata = json.loads(metadata_path.read_text())
		assert metadata.get("asset_id") == asset["asset_id"], f"{asset['asset_id']}: audio sidecar ID mismatch"
		assert metadata.get("source_sha256") == asset["source_sha256"], f"{asset['asset_id']}: audio source hash mismatch"
		assert metadata.get("generator_version") == asset["generator_version"], f"{asset['asset_id']}: audio generator version mismatch"
		assert metadata.get("skill") == asset["assigned_generation_skill"], f"{asset['asset_id']}: audio skill mismatch"
		assert metadata.get("export", {}).get("sha256") == asset["export_sha256"], f"{asset['asset_id']}: audio sidecar export hash mismatch"
	runtime_sources = []
	for path in (ROOT / "game").rglob("*"):
		if not path.is_file() or path.suffix not in {".gd", ".tscn", ".tres", ".godot", ".cfg"}:
			continue
		if any(part in {"assets", "tests", "tools"} for part in path.relative_to(ROOT / "game").parts):
			continue
		runtime_sources.append(path.read_text(errors="replace"))
	runtime_text = "\n".join(runtime_sources)
	for asset in assets:
		if asset["category"] not in {"music", "music_stem"}:
			continue
		resource_path = "res://" + asset["integrated_path"].removeprefix("game/")
		assert resource_path in runtime_text, f"{asset['asset_id']}: music asset has no runtime consumer"


if __name__ == "__main__":
	main()
