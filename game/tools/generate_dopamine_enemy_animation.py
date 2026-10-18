#!/usr/bin/env python3
"""Generate a staged role-based chaser and identity-locked animation sample."""

import argparse
import hashlib
import json
import struct
import zlib
from pathlib import Path

import generate_original_roster as roster
from generate_neon_arcade_art import Canvas, aseprite_bytes

ROOT = Path(__file__).resolve().parents[2]
DIRECTIONS = ("down", "left", "right", "up")
ANIMATIONS = {"idle": (4, 4), "move": (8, 4), "attack": (10, 4), "death": (10, 4)}


def rgba_pixels(role: str) -> tuple[list[tuple[int, int, int, int]], set[tuple[int, int, int, int]]]:
    palette, lookup = roster.read_palette()
    names = {index: name for name, index in lookup.items()}
    sprite = roster.draw(role)
    pixels = []
    for y in range(24):
        for x in range(24):
            name = sprite.pixels[(y * 32) // 24][(x * 32) // 24]
            if name is None:
                pixels.append((0, 0, 0, 0))
            else:
                index = lookup[name]
                pixels.append(tuple(palette[index]) + (255,))
    return pixels, set(pixel for pixel in pixels if pixel[3])


def rotate(source: list[tuple[int, int, int, int]], turns: int) -> list[tuple[int, int, int, int]]:
    result = source
    for _ in range(turns):
        result = [result[(23 - x) * 24 + y] for y in range(24) for x in range(24)]
    return result


def pose(base: list[tuple[int, int, int, int]], animation: str, frame: int) -> list[tuple[int, int, int, int]]:
    out = [(0, 0, 0, 0)] * (24 * 24)
    bob = (0, -1, 0, 1)[frame]
    if animation == "idle":
        for y in range(24):
            dy = bob if y < 19 else 0
            for x in range(24):
                out[(y + dy) * 24 + x] = base[y * 24 + x]
        if frame == 2:
            magenta = roster.P["magenta"]
            out[12 * 24 + 12] = tuple(int(magenta[i:i + 2], 16) for i in (0, 2, 4)) + (255,)
    elif animation == "move":
        body_bob = (0, -1, 1, 0)[frame]
        for y in range(24):
            for x in range(24):
                foot_lift = -2 if y >= 19 and ((frame == 1 and x < 12) or (frame == 3 and x >= 12)) else 0
                target_y = y + (body_bob if y < 19 else foot_lift)
                if 0 <= target_y < 24:
                    out[target_y * 24 + x] = base[y * 24 + x]
        if frame in (1, 3):
            # A small palette-locked stride accent makes the alternating step legible
            # even on abstract enemy silhouettes with no separated feet.
            accent = roster.P["bright"]
            x = 9 if frame == 1 else 14
            out[22 * 24 + x] = tuple(int(accent[i:i + 2], 16) for i in (0, 2, 4)) + (255,)
    elif animation == "attack":
        scale = (1.0, 0.82, 1.18, 1.0)[frame]
        shift = (0, 0, -2, 0)[frame]
        for y in range(24):
            for x in range(24):
                color = base[y * 24 + x]
                if color[3]:
                    target_x = round((x - 11.5) * scale + 11.5 + shift)
                    if 0 <= target_x < 24:
                        out[y * 24 + target_x] = color
        if frame == 2:
            for x in (7, 16):
                out[10 * 24 + x] = (255, 241, 154, 255)
        elif frame == 3:
            accent = roster.P["violet"]
            out[12 * 24 + 4] = tuple(int(accent[i:i + 2], 16) for i in (0, 2, 4)) + (255,)
    else:
        scale = (1.0, 0.84, 0.60, 0.32)[frame]
        y_shift = (0, 2, 5, 8)[frame]
        for y in range(24):
            for x in range(24):
                color = base[y * 24 + x]
                if color[3]:
                    target_x = round((x - 11.5) * scale + 11.5)
                    target_y = round((y - 17) * scale + 17 + y_shift)
                    if 0 <= target_x < 24 and 0 <= target_y < 24:
                        out[target_y * 24 + target_x] = color
    return out


def png_bytes(width: int, height: int, pixels: list[tuple[int, int, int, int]]) -> bytes:
    def chunk(kind: bytes, body: bytes) -> bytes:
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)
    raw = b"".join(b"\0" + bytes(channel for pixel in pixels[y * width:(y + 1) * width] for channel in pixel)
                    for y in range(height))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def write_asset(root: Path, asset_id: str, pixels: list[tuple[int, int, int, int]], width: int, height: int,
                details: dict, seed: int) -> None:
    png = png_bytes(width, height, pixels)
    image = Canvas(width, height)
    image.data[:] = bytes(channel for pixel in pixels for channel in pixel)
    ase = aseprite_bytes(image, asset_id)
    export = root / "sprites" / "enemies" / f"{asset_id}.png"
    source = root / "source" / "animation" / f"{asset_id}.aseprite"
    export.parent.mkdir(parents=True, exist_ok=True)
    source.parent.mkdir(parents=True, exist_ok=True)
    export.write_bytes(png)
    source.write_bytes(ase)
    metadata = {**details, "asset_id": asset_id, "status": "candidate_not_approved", "skill": "dopamine-animation",
                "generator": "game/tools/generate_dopamine_enemy_animation.py", "generator_version": "2",
                "seed": seed, "seed_policy": "fixed role primitives; seed recorded but not consumed",
                "parameters": details, "dimensions": [width, height],
                "source_path": str(source.relative_to(root)), "export_path": str(export.relative_to(root)),
                "source_sha256": hashlib.sha256(ase).hexdigest(),
                "export_sha256": hashlib.sha256(png).hexdigest()}
    export.with_suffix(".json").write_text(json.dumps(metadata, indent=2) + "\n")


def generate_role(root: Path, role: str, seed: int) -> None:
    base, colors = rgba_pixels(role)
    static_id = f"enemy_{role}_sprite"
    write_asset(root, static_id, base, 24, 24,
                {"identity_source": "shared original roster role primitive", "palette_colors": [list(c) for c in sorted(colors)]}, seed)
    for animation, (fps, frame_count) in ANIMATIONS.items():
        sheet = [(0, 0, 0, 0)] * (24 * 4 * 24 * frame_count)
        for row, turns in enumerate((0, 3, 1, 2)):
            oriented = rotate(base, turns)
            for column in range(frame_count):
                frame = pose(oriented, animation, column)
                for y in range(24):
                    start = (row * 24 + y) * (24 * frame_count) + column * 24
                    sheet[start:start + 24] = frame[y * 24:(y + 1) * 24]
        asset_id = f"enemy_{role}_{animation}"
        details = {"identity_source": static_id, "frame_size": [24, 24], "grid": [frame_count, 4],
                   "directions": list(DIRECTIONS), "fps_proposed": fps,
                   "frame_duration_seconds_proposed": 1 / fps, "pivot": [12, 12],
                   "conventions": "non-canonical sample; four directions and four frames per row are provisional"}
        write_asset(root, asset_id, sheet, 24 * frame_count, 24 * 4, details, seed)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--roles", nargs="+", choices=roster.ROLES, default=roster.ROLES)
    parser.add_argument("--out-root", type=Path, default=ROOT / "build/assets/candidates/enemy-animation")
    parser.add_argument("--seed", type=int, default=5319)
    args = parser.parse_args()
    for role in args.roles:
        role_seed = int.from_bytes(hashlib.sha256(f"{args.seed}:enemy_{role}".encode()).digest()[:4], "little")
        generate_role(args.out_root, role, role_seed)
    print(f"Staged {len(args.roles)} enemy roles with identity-locked sprites and animation sets")


if __name__ == "__main__":
    main()
