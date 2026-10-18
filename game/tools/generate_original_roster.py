#!/usr/bin/env python3
"""Draw original role-readable common enemy sprites from pixel primitives."""

from __future__ import annotations

import struct
import zlib
import hashlib
import json
import argparse
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PALETTE_PATH = ROOT / "docs/art/palette_master.gpl"
ROSTER_DIR = ROOT / "game/assets/sprites/roster"
SIZE = 32
EXPORT_SIZE = 24
P = {
	"ink": "10152B", "deep": "1B2340", "edge": "293354", "plum": "59476F",
	"cyan": "075A80", "glint": "37E8F5", "bright": "FFF19A", "violet": "7623A8",
	"magenta": "E13ACB", "amber": "FFD447", "white": "F6F7FF", "accent": "48E69B",
}
ROLES = ["chaser", "sprinter", "tank", "shooter", "buffer", "exploder", "shielder", "summoner", "summoned"]


class Sprite:
	def __init__(self) -> None:
		self.pixels = [[None for _ in range(SIZE)] for _ in range(SIZE)]

	def rect(self, x: int, y: int, w: int, h: int, color: str) -> None:
		for py in range(max(0, y), min(SIZE, y + h)):
			for px in range(max(0, x), min(SIZE, x + w)):
				self.pixels[py][px] = color

	def ellipse(self, x: int, y: int, w: int, h: int, color: str) -> None:
		for py in range(max(0, y), min(SIZE, y + h)):
			for px in range(max(0, x), min(SIZE, x + w)):
				dx = (px - x + 0.5) / w * 2 - 1
				dy = (py - y + 0.5) / h * 2 - 1
				if dx * dx + dy * dy <= 1:
					self.pixels[py][px] = color

	def line(self, x0: int, y0: int, x1: int, y1: int, color: str, width: int = 1) -> None:
		dx, dy = abs(x1 - x0), abs(y1 - y0)
		sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
		err = dx - dy
		while True:
			self.rect(x0 - width // 2, y0 - width // 2, width, width, color)
			if x0 == x1 and y0 == y1:
				break
			e2 = 2 * err
			if e2 > -dy:
				err -= dy
				x0 += sx
			if e2 < dx:
				err += dx
				y0 += sy

	def diamond(self, cx: int, cy: int, radius: int, color: str) -> None:
		for y in range(-radius, radius + 1):
			self.rect(cx - (radius - abs(y)), cy + y, (radius - abs(y)) * 2 + 1, 1, color)

	def to_png(self, path: Path, palette: list[tuple[int, int, int]], lookup: dict[str, int]) -> None:
		rows = bytearray()
		for y in range(EXPORT_SIZE):
			rows.append(0)
			for x in range(EXPORT_SIZE):
				color = self.pixels[y * SIZE // EXPORT_SIZE][x * SIZE // EXPORT_SIZE]
				rows.append(0 if color is None else lookup[color])
		def chunk(tag: bytes, data: bytes) -> bytes:
			return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
		plte = bytes(value for color in palette for value in color)
		png = b"\x89PNG\r\n\x1a\n"
		png += chunk(b"IHDR", struct.pack(">IIBBBBB", EXPORT_SIZE, EXPORT_SIZE, 8, 3, 0, 0, 0))
		png += chunk(b"PLTE", plte) + chunk(b"tRNS", bytes([0] + [255] * 31))
		png += chunk(b"IDAT", zlib.compress(bytes(rows), 9)) + chunk(b"IEND", b"")
		path.write_bytes(png)


def read_palette() -> tuple[list[tuple[int, int, int]], dict[str, int]]:
	palette, lookup = [], {}
	for line in PALETTE_PATH.read_text().splitlines():
		fields = line.split()
		if len(fields) >= 4 and all(v.isdigit() for v in fields[:3]):
			color = tuple(map(int, fields[:3]))
			lookup["".join(f"{v:02X}" for v in color)] = len(palette)
			palette.append(color)
	assert len(palette) == 32
	assert set(P.values()) <= lookup.keys()
	return palette, lookup


def draw(role: str) -> Sprite:
	s = Sprite()
	ink, deep, edge, plum = P["ink"], P["deep"], P["edge"], P["plum"]
	cyan, glint, bright, violet = P["cyan"], P["glint"], P["bright"], P["violet"]
	magenta, amber, white, accent = P["magenta"], P["amber"], P["white"], P["accent"]
	# Role silhouettes share the night outline, face point, and ground shadow only.
	s.ellipse(8, 24, 16, 5, deep)
	if role == "tank":
		s.rect(5, 11, 22, 12, ink); s.rect(7, 8, 18, 16, edge)
		s.rect(9, 7, 14, 4, plum); s.rect(10, 11, 12, 9, cyan)
		s.rect(12, 13, 8, 4, glint); s.rect(14, 14, 5, 2, white)
		s.rect(3, 14, 5, 4, ink); s.rect(24, 14, 5, 4, ink)
		s.rect(5, 21, 7, 4, ink); s.rect(20, 21, 7, 4, ink)
		s.rect(6, 22, 5, 2, amber); s.rect(21, 22, 5, 2, amber)
		s.rect(14, 4, 4, 4, amber)
	elif role == "sprinter":
		s.line(16, 4, 16, 8, ink, 5); s.ellipse(9, 6, 14, 11, ink); s.ellipse(10, 7, 12, 9, cyan)
		s.diamond(16, 17, 7, ink); s.diamond(16, 17, 5, glint); s.rect(14, 15, 4, 3, white)
		s.line(11, 21, 5, 27, ink, 4); s.line(21, 21, 27, 27, ink, 4)
		s.line(11, 21, 6, 26, violet, 2); s.line(21, 21, 26, 26, violet, 2)
	elif role == "shooter":
		s.ellipse(7, 8, 16, 17, ink); s.ellipse(9, 9, 12, 13, deep); s.rect(11, 11, 8, 7, cyan)
		s.rect(12, 12, 6, 3, glint); s.rect(14, 13, 3, 1, white)
		s.rect(18, 13, 9, 4, ink); s.rect(24, 14, 7, 2, plum); s.rect(28, 14, 4, 2, amber)
		s.rect(6, 14, 4, 5, violet); s.rect(11, 22, 8, 3, edge)
	elif role == "buffer":
		s.ellipse(7, 9, 18, 16, ink); s.ellipse(9, 10, 14, 13, deep); s.diamond(16, 15, 6, violet)
		s.diamond(16, 15, 3, white); s.rect(14, 14, 4, 2, accent)
		for x, y in ((6, 10), (22, 10), (5, 20), (23, 20)):
			s.line(16, 16, x, y, cyan, 2); s.rect(x - 1, y - 1, 3, 3, bright)
	elif role == "exploder":
		s.diamond(16, 16, 11, ink); s.diamond(16, 16, 8, magenta); s.diamond(16, 16, 5, amber)
		s.rect(14, 14, 5, 5, white); s.line(8, 9, 5, 5, amber, 2); s.line(24, 9, 27, 5, amber, 2)
		s.line(8, 23, 4, 27, magenta, 2); s.line(24, 23, 28, 27, magenta, 2)
	elif role == "shielder":
		s.ellipse(7, 8, 18, 17, ink); s.ellipse(9, 9, 14, 13, deep); s.rect(12, 12, 8, 4, cyan)
		s.line(5, 7, 3, 16, violet, 3); s.line(3, 16, 6, 25, violet, 3)
		s.line(27, 7, 29, 16, violet, 3); s.line(29, 16, 26, 25, violet, 3)
		s.rect(4, 16, 4, 3, white); s.rect(24, 16, 4, 3, white); s.rect(14, 14, 4, 2, bright)
	elif role == "summoner":
		s.ellipse(8, 9, 16, 16, ink); s.ellipse(10, 10, 12, 12, plum); s.rect(13, 12, 6, 4, violet)
		s.diamond(16, 16, 3, bright); s.rect(15, 15, 3, 2, white)
		for x, y in ((5, 7), (24, 7), (5, 24), (24, 24)):
			s.ellipse(x, y, 4, 4, cyan); s.rect(x + 1, y + 1, 2, 1, white)
			s.line(16, 16, x + 2, y + 2, violet, 1)
	elif role == "summoned":
		s.diamond(16, 15, 9, ink); s.diamond(16, 15, 6, violet); s.diamond(16, 15, 3, cyan)
		s.rect(15, 13, 3, 3, white); s.rect(7, 17, 4, 3, ink); s.rect(21, 17, 4, 3, ink)
		s.line(12, 22, 8, 26, violet, 2); s.line(20, 22, 24, 26, violet, 2)
	else:  # chaser, broad simple body and paired forward eyes.
		s.ellipse(6, 7, 20, 19, ink); s.ellipse(8, 8, 16, 15, cyan); s.rect(9, 19, 14, 4, deep)
		s.rect(10, 12, 5, 4, bright); s.rect(17, 12, 5, 4, bright); s.rect(12, 14, 2, 2, ink); s.rect(18, 14, 2, 2, ink)
		s.rect(4, 17, 4, 4, violet); s.rect(24, 17, 4, 4, violet)
	# Same simple underside glint for all silhouettes; no pre-rendered glow.
	s.rect(13, 25, 6, 1, glint)
	return s


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--out-root", type=Path, default=ROOT / "build/assets/candidates/roster")
	parser.add_argument("--seed", type=int, default=0)
	args = parser.parse_args()
	output = args.out_root / "sprites/roster"
	source_dir = args.out_root / "source/roster"
	output.mkdir(parents=True, exist_ok=True)
	source_dir.mkdir(parents=True, exist_ok=True)
	palette, lookup = read_palette()
	for role in ROLES:
		sprite = draw(role)
		path = output / f"enemy_{role}.png"
		sprite.to_png(path, palette, lookup)
		from generate_neon_arcade_art import Canvas, aseprite_bytes
		canvas = Canvas(32, 32)
		for y in range(32):
			for x in range(32):
				color = sprite.pixels[y][x]
				if color:
					rgb = tuple(int(color[i:i+2],16) for i in (0,2,4))
					canvas.pixel(x,y,rgb+(255,))
		source = source_dir / f"enemy_{role}.aseprite"
		ase = aseprite_bytes(canvas, f"enemy_{role}")
		source.write_bytes(ase)
		meta = {"asset_id":f"enemy_{role}_sprite","status":"candidate_not_approved","skill":"dopamine-pixel-art","generator":"game/tools/generate_original_roster.py","generator_version":"2","seed":args.seed,"seed_policy":"role primitives are deterministic; seed recorded but not consumed","dimensions":{"width":24,"height":24},"source_path":str(source.relative_to(args.out_root)),"export_path":str(path.relative_to(args.out_root)),"source_sha256":hashlib.sha256(ase).hexdigest(),"export_sha256":hashlib.sha256(path.read_bytes()).hexdigest()}
		path.with_suffix(".json").write_text(json.dumps(meta,indent=2)+"\n")
	print(f"Wrote {len(ROLES)} staged original 24x24 roster sprites from {PALETTE_PATH}")


if __name__ == "__main__":
	main()
