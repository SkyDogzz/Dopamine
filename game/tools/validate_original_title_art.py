#!/usr/bin/env python3
"""Validate the original title skyline candidate and its palette/source."""

import csv
import hashlib
import json
import re
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PALETTE = ROOT / "docs" / "art" / "palette_master.gpl"
ART_BIBLE = ROOT / "docs" / "ART_BIBLE.txt"
PNG = ROOT / "game" / "assets" / "backgrounds" / "title_skyline.png"
ASEPRITE = ROOT / "game" / "assets" / "source" / "backgrounds" / "title_skyline.aseprite"
MANIFEST = ROOT / "docs" / "art" / "title_skyline_migration.json"
GENERATOR = ROOT / "game" / "tools" / "generate_original_title_skyline.py"
REGISTER = ROOT / "docs" / "art" / "ASSET_FILE_REGISTER.csv"


def _gpl_colors() -> list[tuple[int, int, int]]:
	colors = []
	for line in PALETTE.read_text().splitlines():
		parts = line.split()
		if len(parts) >= 4 and all(part.isdigit() for part in parts[:3]):
			colors.append(tuple(int(value) for value in parts[:3]))
	return colors


def _bible_colors() -> list[tuple[int, int, int]]:
	text = ART_BIBLE.read_text()
	section = re.search(r"12\.1 PALETTE MAÎTRE.*?\n(.*?)\n12\.2", text, re.S)
	assert section, "Art Bible palette section was not found"
	return [
		tuple(int(color[1 + index:1 + index + 2], 16) for index in (0, 2, 4))
		for color in re.findall(r"#[0-9A-Fa-f]{6}", section.group(1))
	]


def _png_palette_and_indices() -> tuple[tuple[int, int], list[tuple[int, int, int]], set[int]]:
	data = PNG.read_bytes()
	assert data.startswith(b"\x89PNG\r\n\x1a\n"), "invalid PNG signature"
	offset = 8
	palette = b""
	compressed = bytearray()
	width = height = bit_depth = color_type = 0
	while offset < len(data):
		length = struct.unpack(">I", data[offset:offset + 4])[0]
		tag = data[offset + 4:offset + 8]
		payload = data[offset + 8:offset + 8 + length]
		if tag == b"IHDR":
			width, height, bit_depth, color_type, compression, filtering, interlace = struct.unpack(">IIBBBBB", payload)
			assert (bit_depth, color_type, compression, filtering, interlace) == (8, 3, 0, 0, 0), "expected non-interlaced indexed PNG"
		elif tag == b"PLTE":
			palette = payload
		elif tag == b"IDAT":
			compressed.extend(payload)
		offset += 12 + length
	indices = set()
	rows = zlib.decompress(compressed)
	for y in range(height):
		start = y * (width + 1)
		assert rows[start] == 0, "expected unfiltered indexed pixel row"
		indices.update(rows[start + 1:start + 1 + width])
	colors = [tuple(palette[index:index + 3]) for index in range(0, len(palette), 3)]
	return (width, height), colors, indices


def main() -> None:
	bible_colors = _bible_colors()
	gpl_colors = _gpl_colors()
	assert len(bible_colors) == len(gpl_colors) == 32, "expected exactly 32 palette colors"
	assert gpl_colors == bible_colors, "GPL palette differs from the Art Bible order/values"
	dimensions, png_colors, indices = _png_palette_and_indices()
	assert dimensions == (640, 360), f"unexpected image dimensions: {dimensions}"
	assert png_colors == gpl_colors, "PNG palette differs from the master palette"
	assert len(indices) <= 32 and all(index < len(png_colors) for index in indices), "invalid used palette index"
	ase = ASEPRITE.read_bytes()
	assert struct.unpack_from("<H", ase, 4)[0] == 0xA5E0, "invalid Aseprite source header"
	assert struct.unpack_from("<HHH", ase, 8) == (640, 360, 8), "Aseprite source must be indexed 640x360"
	manifest = json.loads(MANIFEST.read_text())
	assert manifest["status"].startswith("[PROPOSÉ]") and "active" in manifest["status"]
	assert manifest["replacement_runtime"]["sha256"] == hashlib.sha256(PNG.read_bytes()).hexdigest(), "PNG manifest hash mismatch"
	assert manifest["replacement_editable_source"]["sha256"] == hashlib.sha256(ase).hexdigest(), "Aseprite manifest hash mismatch"
	assert manifest["generator"]["sha256"] == hashlib.sha256(GENERATOR.read_bytes()).hexdigest(), "generator manifest hash mismatch"
	with REGISTER.open(newline="") as register:
		old_hashes = {row["sha256"] for row in csv.DictReader(register)}
	assert hashlib.sha256(PNG.read_bytes()).hexdigest() not in old_hashes, "PNG duplicates a registered legacy asset"
	assert hashlib.sha256(ASEPRITE.read_bytes()).hexdigest() not in old_hashes, "Aseprite source duplicates a registered legacy asset"
	print(f"Validated active {PNG.name}: 640x360 indexed art, exact 32-color Bible palette, editable indexed Aseprite source, no legacy hash match ({len(indices)} colors used).")


if __name__ == "__main__":
	main()
