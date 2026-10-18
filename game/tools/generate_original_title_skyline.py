#!/usr/bin/env python3
"""Create the original 640x360 Neon Arcade title skyline from the master palette."""

import random
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PALETTE_PATH = ROOT / "docs" / "art" / "palette_master.gpl"
OUTPUT = ROOT / "game" / "assets" / "backgrounds" / "title_skyline.png"
WIDTH = 640
HEIGHT = 360


def _load_palette() -> list[tuple[int, int, int]]:
	colors = []
	for line in PALETTE_PATH.read_text().splitlines():
		parts = line.split()
		if len(parts) >= 4 and all(part.isdigit() for part in parts[:3]):
			colors.append(tuple(int(value) for value in parts[:3]))
	assert len(colors) == 32, f"expected 32 palette colors in {PALETTE_PATH}"
	return colors


def _write_png(path: Path, pixels: bytearray, palette: list[tuple[int, int, int]]) -> None:
	def chunk(tag: bytes, data: bytes) -> bytes:
		return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

	rows = b"".join(b"\x00" + pixels[y * WIDTH:(y + 1) * WIDTH] for y in range(HEIGHT))
	palette_bytes = bytes(channel for color in palette for channel in color)
	content = b"\x89PNG\r\n\x1a\n"
	content += chunk(b"IHDR", struct.pack(">IIBBBBB", WIDTH, HEIGHT, 8, 3, 0, 0, 0))
	content += chunk(b"PLTE", palette_bytes)
	content += chunk(b"IDAT", zlib.compress(rows, level=9))
	content += chunk(b"IEND", b"")
	path.parent.mkdir(parents=True, exist_ok=True)
	path.write_bytes(content)


def _set(pixels: bytearray, x: int, y: int, color: int) -> None:
	if 0 <= x < WIDTH and 0 <= y < HEIGHT:
		pixels[y * WIDTH + x] = color


def _rect(pixels: bytearray, x: int, y: int, width: int, height: int, color: int) -> None:
	for row in range(max(0, y), min(HEIGHT, y + height)):
		start = row * WIDTH + max(0, x)
		end = row * WIDTH + min(WIDTH, x + width)
		if start < end:
			pixels[start:end] = bytes([color]) * (end - start)


def _building(pixels: bytearray, rng: random.Random, x: int, width: int, top: int,
		bottom: int, lit_rate: int, roof_color: int, wall_color: int) -> None:
	_rect(pixels, x, top, width, bottom - top, wall_color)
	_rect(pixels, x, top, width, 1, roof_color)
	_rect(pixels, x, top, 1, bottom - top, roof_color)
	_rect(pixels, x + width - 1, top, 1, bottom - top, roof_color)
	if rng.randrange(3) == 0:
		antenna_x = x + rng.randrange(3, max(4, width - 2))
		_rect(pixels, antenna_x, top - 7, 1, 7, roof_color)
		_set(pixels, antenna_x, top - 8, 19 if x >= 240 else 3)
	for window_y in range(top + 8, bottom - 5, 10):
		for window_x in range(x + 5, x + width - 3, 8):
			if rng.randrange(100) < lit_rate:
				color = rng.choice((17, 18, 20, 21, 22, 25, 26, 28))
				if x < 192:
					color = 3 if color not in (25, 26) else 24
				_rect(pixels, window_x, window_y, 2, 4, color)


def main() -> None:
	palette = _load_palette()
	pixels = bytearray([0]) * (WIDTH * HEIGHT)
	# Discrete night-sky bands use only validated palette colors.
	_rect(pixels, 0, 0, WIDTH, 68, 0)
	_rect(pixels, 0, 68, WIDTH, 78, 1)
	_rect(pixels, 0, 146, WIDTH, 64, 2)
	_rect(pixels, 0, 210, WIDTH, 150, 1)
	rng = random.Random(640360)
	for _ in range(55):
		x = rng.randrange(190, WIDTH)
		y = rng.randrange(14, 145)
		_set(pixels, x, y, rng.choice((3, 4, 5, 18)))

	# Distant block silhouettes establish the skyline without a named biome.
	x = 174
	while x < WIDTH:
		width = rng.randrange(18, 44)
		top = rng.randrange(118, 189)
		_building(pixels, rng, x, width, top, 270, 9, 2, 1)
		x += width - rng.randrange(1, 5)

	# Foreground towers frame a quiet left menu area and concentrate neon on the right.
	for x, width, top in [(0, 54, 231), (48, 42, 206), (87, 35, 243), (119, 42, 220),
			(194, 48, 186), (238, 39, 213), (274, 53, 177), (322, 42, 226),
			(361, 49, 196), (406, 37, 232), (440, 55, 171), (491, 43, 211),
			(530, 52, 184), (579, 61, 218)]:
		_building(pixels, rng, x, width, top, 322, 5 if x < 192 else 18,
				3 if x < 192 else 4, 1 if x < 192 else 2)

	# A low, dark street ledge keeps the skyline legible behind title controls.
	_rect(pixels, 0, 322, WIDTH, 38, 0)
	_rect(pixels, 192, 322, WIDTH - 192, 1, 3)
	_rect(pixels, 210, 338, 300, 1, 2)
	_rect(pixels, 237, 348, 242, 1, 2)
	_write_png(OUTPUT, pixels, palette)
	print(f"Wrote original title skyline: {OUTPUT} ({WIDTH}x{HEIGHT}, indexed PNG using the master palette)")


if __name__ == "__main__":
	main()
