#!/usr/bin/env python3
"""Draw original Survival chest and XP pickup sprites from palette primitives."""

import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PALETTE_FILE = ROOT / "docs/art/palette_master.gpl"
OUTPUT_DIR = ROOT / "game/assets/sprites/rewards"
PALETTE_SUBSET = [
	"080B18", "10152B", "1B2340", "293354", "59476F", "075A80", "087FB2", "0EB8D4",
	"37E8F5", "7623A8", "E13ACB", "FFD447", "FFF19A", "D4D9E8", "F6F7FF",
]


class Canvas:
	def __init__(self, size: int, palette: dict[str, int]) -> None:
		self.size = size
		self.pixels = bytearray(size * size)
		self.palette = palette

	def rect(self, x: int, y: int, width: int, height: int, color: str) -> None:
		for py in range(max(0, y), min(self.size, y + height)):
			left, right = max(0, x), min(self.size, x + width)
			if left < right:
				start = py * self.size + left
				self.pixels[start:start + right - left] = bytes([self.palette[color]]) * (right - left)

	def ellipse(self, x: int, y: int, width: int, height: int, color: str) -> None:
		for py in range(y, y + height):
			for px in range(x, x + width):
				dx = (px - x + 0.5) * 2 / width - 1
				dy = (py - y + 0.5) * 2 / height - 1
				if dx * dx + dy * dy <= 1:
					self.rect(px, py, 1, 1, color)

	def diamond(self, cx: int, cy: int, radius: int, color: str) -> None:
		for dy in range(-radius, radius + 1):
			span = radius - abs(dy)
			self.rect(cx - span, cy + dy, span * 2 + 1, 1, color)

	def save(self, path: Path, palette: list[tuple[int, int, int]]) -> None:
		rows = b"".join(b"\0" + self.pixels[y * self.size:(y + 1) * self.size] for y in range(self.size))
		def chunk(kind: bytes, data: bytes) -> bytes:
			return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
		data = b"\x89PNG\r\n\x1a\n"
		data += chunk(b"IHDR", struct.pack(">IIBBBBB", self.size, self.size, 8, 3, 0, 0, 0))
		data += chunk(b"PLTE", bytes(c for rgb in palette for c in rgb))
		data += chunk(b"tRNS", b"\0" + b"\xff" * (len(palette) - 1))
		data += chunk(b"IDAT", zlib.compress(rows, 9)) + chunk(b"IEND", b"")
		path.write_bytes(data)


def palette_data() -> tuple[list[tuple[int, int, int]], dict[str, int]]:
	colors = []
	index = {}
	for line in PALETTE_FILE.read_text().splitlines():
		fields = line.split()
		if len(fields) >= 4 and all(value.isdigit() for value in fields[:3]):
			rgb = tuple(map(int, fields[:3]))
			hex_color = "".join(f"{value:02X}" for value in rgb)
			index[hex_color] = len(colors)
			colors.append(rgb)
	assert len(colors) == 32
	assert set(PALETTE_SUBSET) <= index.keys()
	return colors, {color: index[color] for color in PALETTE_SUBSET}


def draw_chest(palette: dict[str, int]) -> Canvas:
	c = Canvas(32, palette)
	# Low, wide silhouette with a readable lid seam, metal corners, and lock.
	c.rect(5, 12, 22, 15, "10152B")
	c.rect(7, 9, 18, 5, "10152B")
	c.rect(9, 6, 14, 4, "10152B")
	c.rect(7, 12, 18, 12, "7623A8")
	c.rect(8, 13, 16, 9, "E13ACB")
	c.rect(9, 10, 14, 3, "FFD447")
	c.rect(11, 7, 10, 3, "FFF19A")
	c.rect(9, 15, 14, 2, "FFD447")
	c.rect(7, 22, 18, 3, "10152B")
	c.rect(6, 13, 3, 9, "37E8F5")
	c.rect(23, 13, 3, 9, "37E8F5")
	c.rect(14, 15, 4, 7, "10152B")
	c.rect(15, 16, 2, 3, "FFF19A")
	c.rect(14, 20, 4, 2, "FFD447")
	c.rect(10, 26, 4, 2, "59476F")
	c.rect(18, 26, 4, 2, "59476F")
	return c


def draw_xp(palette: dict[str, int]) -> Canvas:
	c = Canvas(16, palette)
	# Compact faceted orb; its outline stays distinct from the renderer's collection ring.
	c.ellipse(2, 1, 12, 14, "10152B")
	c.ellipse(3, 2, 10, 12, "075A80")
	c.diamond(8, 8, 5, "0EB8D4")
	c.diamond(8, 8, 3, "37E8F5")
	c.rect(7, 4, 3, 2, "FFF19A")
	c.rect(5, 7, 2, 2, "D4D9E8")
	c.rect(10, 10, 2, 2, "087FB2")
	c.rect(6, 13, 4, 1, "7623A8")
	return c


def main() -> None:
	colors, lookup = palette_data()
	OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
	draw_chest(lookup).save(OUTPUT_DIR / "chest_closed.png", colors)
	draw_xp(lookup).save(OUTPUT_DIR / "xp_orb.png", colors)
	print("Wrote original indexed chest and XP orb sprites from the Art Bible palette")


if __name__ == "__main__":
	main()
