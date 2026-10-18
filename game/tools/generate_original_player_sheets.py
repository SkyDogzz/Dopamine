#!/usr/bin/env python3
"""Draw original 4x4 pixel-art player animation sheets from the master palette."""

import json
import argparse
import hashlib
import struct
import zlib
from pathlib import Path

from generate_neon_arcade_art import Canvas as RgbaCanvas, aseprite_bytes


ROOT = Path(__file__).resolve().parents[2]
PALETTE_PATH = ROOT / "docs" / "art" / "palette_master.gpl"
FRAME_SIZE = 32
SHEET_SIZE = FRAME_SIZE * 4
DEFAULT_SHEET_ROOT = ROOT / "game" / "assets" / "sprites"
ALLOWED_COLORS = {
	"080B18", "10152B", "1B2340", "293354", "37314F", "59476F", "075A80", "087FB2",
	"0EB8D4", "37E8F5", "7623A8", "826999", "AD91BB", "E13ACB", "FFD447", "FFF19A",
}


def _read_palette() -> tuple[list[tuple[int, int, int]], dict[str, int]]:
	palette = []
	indices = {}
	for line in PALETTE_PATH.read_text().splitlines():
		parts = line.split()
		if len(parts) >= 4 and all(part.isdigit() for part in parts[:3]):
			color = tuple(int(value) for value in parts[:3])
			index = len(palette)
			palette.append(color)
			hex_color = "".join(f"{channel:02X}" for channel in color)
			indices[hex_color] = index
	assert len(palette) == 32, "master palette must contain exactly 32 colors"
	assert ALLOWED_COLORS <= indices.keys(), "player palette subset must match the Art Bible palette"
	return palette, {color: indices[color] for color in ALLOWED_COLORS}


class Canvas:
	def __init__(self, palette_index: dict[str, int], width: int = SHEET_SIZE,
			height: int = SHEET_SIZE) -> None:
		self.width = width
		self.height = height
		self.pixels = bytearray(width * height)
		self.palette_index = palette_index

	def rect(self, x: int, y: int, width: int, height: int, color: str) -> None:
		index = self.palette_index[color]
		for row in range(max(0, y), min(self.height, y + height)):
			left = max(0, x)
			right = min(self.width, x + width)
			if left < right:
				start = row * self.width + left
				self.pixels[start:start + right - left] = bytes([index]) * (right - left)

	def point(self, x: int, y: int, color: str) -> None:
		self.rect(x, y, 1, 1, color)

	def shape(self, x: int, y: int, rows: list[tuple[int, int]], color: str) -> None:
		for offset, (left, right) in enumerate(rows):
			self.rect(x + left, y + offset, right - left + 1, 1, color)


def _rotate_frame(source: Canvas, quarter_turns: int) -> Canvas:
	"""Rotate the canonical down-facing model without redrawing its identity."""
	result = Canvas(source.palette_index, source.width, source.height)
	for y in range(source.height):
		for x in range(source.width):
			new_x, new_y = x, y
			for _ in range(quarter_turns % 4):
				new_x, new_y = new_y, source.width - 1 - new_x
			result.pixels[new_y * result.width + new_x] = source.pixels[y * source.width + x]
	return result


def _draw_frame(canvas: Canvas, origin_x: int, origin_y: int, direction: int,
		frame: int, walking: bool) -> None:
	step_cycle = [-2, -1, 2, 1] if walking else [0, 0, 0, 0]
	step = step_cycle[frame]
	breath = 0 if walking else (0, -1, 1, 0)[frame]
	outline = "10152B"
	shadow = "1B2340"
	suit = "37314F"
	armor = "087FB2"
	cyan = "0EB8D4"
	bright = "37E8F5"
	magenta = "E13ACB"
	light = "FFD447"

	# One-pixel-edged shadow and stride silhouette.
	canvas.shape(origin_x + 5, origin_y + 26, [(6, 20), (3, 23), (1, 25), (0, 26), (1, 25)], shadow)
	if direction in (0, 3):
		left_leg_y = 22 + step
		right_leg_y = 22 - step
		canvas.rect(origin_x + 10, origin_y + left_leg_y, 5, 6, outline)
		canvas.rect(origin_x + 17, origin_y + right_leg_y, 5, 6, outline)
		canvas.rect(origin_x + 11, origin_y + left_leg_y, 3, 4, suit)
		canvas.rect(origin_x + 18, origin_y + right_leg_y, 3, 4, suit)
		canvas.rect(origin_x + 11, origin_y + left_leg_y + 4, 4, 2, armor)
		canvas.rect(origin_x + 17, origin_y + right_leg_y + 4, 4, 2, armor)
	else:
		front_leg_y = 23 + step
		back_leg_y = 23 - step
		canvas.rect(origin_x + 12, origin_y + front_leg_y, 5, 6, outline)
		canvas.rect(origin_x + 16, origin_y + back_leg_y, 5, 6, outline)
		canvas.rect(origin_x + 13, origin_y + front_leg_y, 3, 4, suit)
		canvas.rect(origin_x + 17, origin_y + back_leg_y, 3, 4, suit)
		canvas.rect(origin_x + 12, origin_y + front_leg_y + 4, 5, 2, armor)
		canvas.rect(origin_x + 16, origin_y + back_leg_y + 4, 5, 2, armor)

	# Chibi pilot torso: dark outline, compact suit and bright shoulder plates.
	canvas.shape(origin_x + 6, origin_y + 14 + breath, [(5, 18), (3, 20), (2, 21), (2, 21), (3, 20), (4, 19), (5, 18)], outline)
	canvas.shape(origin_x + 7, origin_y + 14 + breath, [(5, 18), (4, 19), (3, 20), (3, 20), (4, 19), (5, 18)], suit)
	canvas.rect(origin_x + 9, origin_y + 15 + breath, 3, 3, armor)
	canvas.rect(origin_x + 19, origin_y + 15 + breath, 3, 3, armor)
	canvas.rect(origin_x + 10, origin_y + 16 + breath, 2, 2, cyan)
	canvas.rect(origin_x + 19, origin_y + 16 + breath, 2, 2, cyan)
	canvas.rect(origin_x + 13, origin_y + 17 + breath, 5, 4, armor)
	canvas.rect(origin_x + 14, origin_y + 18 + breath, 3, 2, cyan)
	canvas.point(origin_x + 15, origin_y + 18 + breath, bright if frame % 2 == 0 else cyan)
	canvas.rect(origin_x + 14, origin_y + 21 + breath, 3, 2, outline)
	canvas.rect(origin_x + 13, origin_y + 22 + breath, 5, 1, magenta)

	# Direction-neutral helmet shell with a clear visor orientation.
	head_rows = [(12, 19), (9, 22), (7, 24), (6, 25), (6, 25), (7, 24), (8, 23), (10, 21), (12, 19)]
	head_y = origin_y + 4 + breath
	canvas.shape(origin_x + 1, head_y, head_rows, outline)
	canvas.shape(origin_x + 2, head_y + 1, head_rows[1:-1], armor)
	canvas.rect(origin_x + 10, head_y + 1, 12, 2, cyan)
	canvas.rect(origin_x + 9, head_y + 3, 14, 1, cyan)
	canvas.rect(origin_x + 10, head_y + 7, 12, 1, armor)

	if direction == 0:  # Down: forward visor.
		canvas.rect(origin_x + 8, head_y + 4, 16, 4, outline)
		canvas.rect(origin_x + 10, head_y + 5, 12, 1, cyan if (not walking and frame == 3) else bright)
		canvas.rect(origin_x + 11, head_y + 7, 10, 1, cyan)
		canvas.point(origin_x + 8, head_y + 5, magenta)
		canvas.point(origin_x + 23, head_y + 5, light)
	elif direction == 3:  # Up: rear panel instead of a face.
		canvas.rect(origin_x + 9, head_y + 4, 14, 4, armor)
		canvas.rect(origin_x + 12, head_y + 4, 8, 4, cyan)
		canvas.rect(origin_x + 14, head_y + 5, 4, 2, bright)
		canvas.rect(origin_x + 10, head_y + 8, 12, 1, outline)
	else:  # Side rows turn the visor to the matching edge.
		canvas.rect(origin_x + 8, head_y + 4, 16, 4, outline)
		if direction == 1:
			canvas.rect(origin_x + 8, head_y + 5, 4, 2, bright)
			canvas.rect(origin_x + 9, head_y + 7, 4, 1, cyan)
			canvas.point(origin_x + 8, head_y + 4, magenta)
		else:
			canvas.rect(origin_x + 20, head_y + 5, 4, 2, bright)
			canvas.rect(origin_x + 19, head_y + 7, 4, 1, cyan)
			canvas.point(origin_x + 23, head_y + 4, light)
		canvas.rect(origin_x + 12, head_y + 8, 8, 1, armor)

	# Small ear plates and a fixed cyan badge keep the silhouette readable at native size.
	canvas.rect(origin_x + 5, head_y + 4, 2, 3, outline)
	canvas.rect(origin_x + 25, head_y + 4, 2, 3, outline)
	canvas.point(origin_x + 6, head_y + 5, magenta)
	canvas.point(origin_x + 25, head_y + 5, light)


def _proposed_player_state(canvas: Canvas, direction: int, frame: int, animation: str,
		palette_index: dict[str, int]) -> None:
	if animation == "attack":
		magenta, cyan, bright = ("E13ACB", "0EB8D4", "37E8F5")
		length = (0, 2, 5, 2)[frame]
		if not length:
			return
		if direction == 0:
			canvas.rect(14, 27, 4, min(length, 5), magenta)
			canvas.point(12, 27, cyan); canvas.point(19, 28, bright)
		elif direction == 1:
			canvas.rect(1, 14, min(length + 2, 5), 4, magenta)
			canvas.point(5, 12, cyan); canvas.point(4, 19, bright)
		elif direction == 2:
			canvas.rect(26 - min(length, 4), 14, min(length + 2, 5), 4, magenta)
			canvas.point(26, 12, cyan); canvas.point(27, 19, bright)
		else:
			canvas.rect(14, 1, 4, min(length + 1, 5), magenta)
			canvas.point(12, 5, cyan); canvas.point(19, 4, bright)
	elif animation == "death":
		transparent = palette_index["080B18"]
		for y in range(FRAME_SIZE):
			for x in range(FRAME_SIZE):
				index = y * FRAME_SIZE + x
				if canvas.pixels[index] == transparent:
					continue
				if frame == 1 and (x + 2 * y + direction) % 7 == 0:
					canvas.pixels[index] = transparent
				elif frame == 2 and (x + y + direction) % 3 != 0:
					canvas.pixels[index] = transparent
				elif frame == 3 and not (12 <= x <= 19 and 12 <= y <= 19):
					canvas.pixels[index] = transparent
		if frame == 3:
			magenta = "E13ACB"
			for offset in range(3):
				canvas.rect(16 - offset, 16 + offset, 2 * offset + 1, 1, magenta)
				canvas.rect(16 - offset, 16 - offset, 2 * offset + 1, 1, magenta)


def _write_png(path: Path, pixels: bytearray, palette: list[tuple[int, int, int]]) -> None:
	def chunk(tag: bytes, payload: bytes) -> bytes:
		return struct.pack(">I", len(payload)) + tag + payload + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)

	rows = b"".join(b"\x00" + pixels[y * SHEET_SIZE:(y + 1) * SHEET_SIZE] for y in range(SHEET_SIZE))
	palette_data = bytes(channel for color in palette for channel in color)
	content = b"\x89PNG\r\n\x1a\n"
	content += chunk(b"IHDR", struct.pack(">IIBBBBB", SHEET_SIZE, SHEET_SIZE, 8, 3, 0, 0, 0))
	content += chunk(b"PLTE", palette_data)
	content += chunk(b"tRNS", b"\x00")
	content += chunk(b"IDAT", zlib.compress(rows, level=9))
	content += chunk(b"IEND", b"")
	path.write_bytes(content)


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--out-root", type=Path, default=ROOT / "build/assets/candidates/animation")
	parser.add_argument("--animations", nargs="+", choices=("idle", "walk", "attack", "death"), default=("idle", "walk"))
	parser.add_argument("--seed", type=int, default=0, help="Recorded for provenance; geometry is deterministic")
	args = parser.parse_args()
	palette, palette_index = _read_palette()
	for animation in ("idle", "walk", "attack", "death"):
		if animation not in args.animations:
			continue
		walking = animation == "walk"
		canvas = Canvas(palette_index)
		for row in range(4):
			for column in range(4):
				frame = Canvas(palette_index, FRAME_SIZE, FRAME_SIZE)
				_draw_frame(frame, 0, 0, 0, column, walking)
				# Rows follow down/left/right/up and rotate the full locked model.
				frame = _rotate_frame(frame, (0, 1, 3, 2)[row])
				_proposed_player_state(frame, row, column, animation, palette_index)
				for y in range(FRAME_SIZE):
					source = y * frame.width
					target = (row * FRAME_SIZE + y) * SHEET_SIZE + column * FRAME_SIZE
					canvas.pixels[target:target + FRAME_SIZE] = frame.pixels[source:source + FRAME_SIZE]
		path = args.out_root / "sprites" / "player" / f"player_{animation}.png"
		path.parent.mkdir(parents=True, exist_ok=True)
		_write_png(path, canvas.pixels, palette)
		rgba = RgbaCanvas(SHEET_SIZE, SHEET_SIZE)
		for index, palette_index_value in enumerate(canvas.pixels):
			color = palette[palette_index_value]
			alpha = 0 if palette_index_value == 0 else 255
			rgba.data[index * 4:index * 4 + 4] = bytes((*color, alpha))
		source_group = "pilot" if animation in ("idle", "walk") else "animation"
		source = args.out_root / "source" / source_group / f"player_{animation}.aseprite"
		source.parent.mkdir(parents=True, exist_ok=True)
		source_bytes = aseprite_bytes(rgba, f"player_{animation}")
		source.write_bytes(source_bytes)
		png_hash = hashlib.sha256(path.read_bytes()).hexdigest()
		source_hash = hashlib.sha256(source_bytes).hexdigest()
		metadata = {
			"asset_id": f"player_{animation}", "status": "candidate_not_approved",
			"skill": "dopamine-animation", "generator": "game/tools/generate_original_player_sheets.py",
			"generator_version": "3", "seed": args.seed,
			"seed_policy": "fixed procedural geometry; seed recorded but not consumed",
			"brief": "User-approved provisional midnight-blue/cyan armor, cyan visor, magenta/yellow accents",
			"frame_size": [FRAME_SIZE, FRAME_SIZE], "grid": [4, 4],
			"directions": ["down", "left", "right", "up"],
			"frame_order": "columns are sequential frames per direction row",
			"frame_duration_seconds_proposed": 1 / {"idle": 3, "walk": 8, "attack": 10, "death": 10}[animation],
			"fps_proposed": {"idle": 3, "walk": 8, "attack": 10, "death": 10}[animation], "pivot": [16, 16],
			"source_representation": "editable single-layer Aseprite sprite sheet; one sheet per animation",
			"source_path": str(source.relative_to(args.out_root)), "export_path": str(path.relative_to(args.out_root)),
			"source_sha256": source_hash, "export_sha256": png_hash,
		}
		path.with_suffix(".json").write_text(json.dumps(metadata, indent=2) + "\n")
	print(f"Wrote staged player sheets: {', '.join(args.animations)}; 4x4 frames, 32x32, Art Bible indexed palette")


if __name__ == "__main__":
	main()
