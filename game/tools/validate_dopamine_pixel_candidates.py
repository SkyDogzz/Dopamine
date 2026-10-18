#!/usr/bin/env python3
"""Validate staged static pixel-art outputs against the Art Bible palette."""

import argparse
import hashlib
import json
import struct
import zlib
from pathlib import Path

from validate_dopamine_animation_candidates import decode_png

ROOT = Path(__file__).resolve().parents[2]
PALETTE = ROOT / "docs/art/palette_master.gpl"


def png_pixels(path: Path) -> tuple[int, int, set[tuple[int, int, int, int]]]:
    width, height, pixels = decode_png(path)
    return width, height, set(pixels)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    palette = set()
    for line in PALETTE.read_text().splitlines():
        parts = line.split()
        if len(parts) >= 4 and all(value.isdigit() for value in parts[:3]):
            palette.add(tuple(map(int, parts[:3])) + (255,))
    report = {"status": "passed", "root": str(args.root.resolve()), "assets": []}
    for metadata_path in sorted(path for path in args.root.rglob("*.json") if path.name != "qa-report.json"):
        metadata = json.loads(metadata_path.read_text())
        if metadata.get("parameters", {}).get("format") == "TrueType":
            export_path = args.root / metadata["export_path"]
            source_path = args.root / metadata["source_path"]
            font_data = export_path.read_bytes()
            assert font_data[:4] in (b"\x00\x01\x00\x00", b"OTTO"), f"invalid TrueType/OpenType font: {export_path}"
            assert hashlib.sha256(font_data).hexdigest() == metadata["export_sha256"], f"font hash mismatch: {export_path}"
            assert hashlib.sha256(source_path.read_bytes()).hexdigest() == metadata["source_sha256"], f"font source hash mismatch: {source_path}"
            report["assets"].append({"asset_id": metadata["asset_id"], "export": str(export_path),
                                     "source": str(source_path), "font_pass": True, "hashes_pass": True})
            continue
        png_path = metadata_path.with_suffix(".png")
        source_path = args.root / metadata["source_path"]
        width, height, colors = png_pixels(png_path)
        opaque_colors = {color for color in colors if color[3] != 0}
        assert all(color[3] == 0 for color in colors if color[3] != 255), f"unexpected partial transparency: {png_path}"
        assert opaque_colors <= palette, f"colors outside Art Bible palette: {png_path}"
        assert hashlib.sha256(png_path.read_bytes()).hexdigest() == metadata["export_sha256"], f"PNG hash mismatch: {png_path}"
        assert hashlib.sha256(source_path.read_bytes()).hexdigest() == metadata["source_sha256"], f"source hash mismatch: {source_path}"
        assert source_path.read_bytes()[4:6] == struct.pack("<H", 0xA5E0), f"not an Aseprite document: {source_path}"
        color_limit = 16 if (width, height) == (32, 32) else len(palette)
        assert len(opaque_colors) <= color_limit, f"color limit exceeded ({len(opaque_colors)}): {png_path}"
        report["assets"].append({"asset_id": metadata["asset_id"], "png": str(png_path),
                                 "source": str(source_path), "dimensions": [width, height],
                                 "colors": len(opaque_colors), "palette_pass": True, "hashes_pass": True})
    assert report["assets"], "no metadata records found"
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
