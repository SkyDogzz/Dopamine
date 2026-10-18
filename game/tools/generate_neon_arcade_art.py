#!/usr/bin/env python3
"""Draw a fresh Neon Arcade asset set from primitives and the Art Bible palette."""

from __future__ import annotations

import hashlib
import argparse
import json
import math
import pathlib
import re
import struct
import sys
import zlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
PALETTE_FILE = ROOT / "docs/art/palette_master.gpl"
ASSETS = ROOT / "game/assets"
SELECTED_IDS: set[str] = set()
GENERATION_SEED = 0

WEAPONS = [
    "weapon_lightning_conductor", "weapon_inferno_sprayer", "weapon_crimson_daggers",
    "weapon_minigun", "weapon_toxic_cloud", "weapon_sawblades", "weapon_meteor_staff",
    "weapon_prism_laser", "weapon_void_orb", "weapon_frost_nova",
]
EVOLUTIONS = [
    "evolution_lightning_conductor", "evolution_inferno_sprayer", "evolution_crimson_daggers",
    "evolution_minigun", "evolution_toxic_cloud", "evolution_sawblades",
    "evolution_meteor_staff", "evolution_prism_laser", "evolution_void_orb",
    "evolution_frost_nova",
]
EVOLUTION_ROLES = {
    "evolution_lightning_conductor": "infinite_circuit", "evolution_inferno_sprayer": "wildfire",
    "evolution_crimson_daggers": "bloodstorm", "evolution_minigun": "redline",
    "evolution_toxic_cloud": "pandemic", "evolution_sawblades": "razorstorm",
    "evolution_meteor_staff": "starfall", "evolution_prism_laser": "spectrum_collapse",
    "evolution_void_orb": "event_horizon", "evolution_frost_nova": "absolute_zero",
}
RELICS = [
    "relic_storm_core", "relic_infernal_heart", "relic_blood_chalice",
    "relic_overdrive_engine", "relic_plague_mask", "relic_magnetic_coil",
    "relic_celestial_eye", "relic_magnet_heart", "relic_frozen_crown",
    "relic_prism_crystal", "relic_singularity",
]
PROJECTILES = [
    "projectile_lightning", "projectile_inferno", "projectile_crimson", "projectile_enemy",
    "projectile_minigun", "projectile_toxic_cloud", "projectile_sawblades", "projectile_meteor",
    "projectile_starfall_fragment", "projectile_prism_laser", "projectile_prism_secondary",
    "projectile_void_orb", "projectile_frost_nova", "projectile_infinite_circuit",
    "projectile_wildfire", "projectile_bloodstorm", "projectile_event_horizon",
    "projectile_absolute_zero", "projectile_pandemic", "projectile_razorstorm",
    "projectile_starfall", "projectile_spectrum_collapse", "projectile_unique_lightning_burst",
    "projectile_evolution_shockwave",
]
IMPACTS = [
    "impact_spark", "impact_star", "impact_slash", "impact_pop", "impact_ring",
    "impact_burst", "impact_shards", "impact_shock_ring", "impact_angular", "impact_evolved",
]
UI_CATALOG = [
    "equipment_helmet", "equipment_armor", "equipment_gloves", "equipment_boots", "equipment_amulet",
    "equipment_ring", "rarity_normal", "rarity_magic", "rarity_mystic", "rarity_legendary", "rarity_mythic",
    "resource_essence", "resource_powder", "skill_node", "achievement_medal", "run_record",
]
FAMILIES = {"catalog", "projectiles", "vfx", "environment", "boss", "ui", "ui_catalog", "roles"}


def load_palette() -> dict[str, tuple[int, int, int, int]]:
    colors = {}
    for line in PALETTE_FILE.read_text().splitlines():
        m = re.match(r"\s*(\d+)\s+(\d+)\s+(\d+)\s+(.+)$", line)
        if m:
            r, g, b, name = m.groups()
            colors[name.lower().replace(" ", "_")] = (int(r), int(g), int(b), 255)
    if len(colors) != 32:
        raise RuntimeError(f"Expected 32 Art Bible colors, found {len(colors)}")
    return colors


class Canvas:
    def __init__(self, width: int, height: int):
        self.width, self.height = width, height
        self.data = bytearray(width * height * 4)

    def pixel(self, x: int, y: int, color: tuple[int, int, int, int]):
        if 0 <= x < self.width and 0 <= y < self.height:
            i = (y * self.width + x) * 4
            self.data[i:i + 4] = bytes(color)

    def rect(self, x: int, y: int, w: int, h: int, color, outline=None):
        if outline:
            self.rect(x, y, w, 1, outline)
            self.rect(x, y + h - 1, w, 1, outline)
            self.rect(x, y, 1, h, outline)
            self.rect(x + w - 1, y, 1, h, outline)
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.pixel(xx, yy, color)

    def line(self, x0: int, y0: int, x1: int, y1: int, color, width=1):
        dx, dy = abs(x1 - x0), abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx - dy
        while True:
            half = width // 2
            self.rect(x0 - half, y0 - half, width, width, color)
            if x0 == x1 and y0 == y1:
                break
            e2 = err * 2
            if e2 > -dy:
                err -= dy
                x0 += sx
            if e2 < dx:
                err += dx
                y0 += sy

    def disc(self, cx: int, cy: int, radius: int, color):
        r2 = radius * radius
        for y in range(cy - radius, cy + radius + 1):
            for x in range(cx - radius, cx + radius + 1):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r2:
                    self.pixel(x, y, color)

    def ring(self, cx: int, cy: int, outer: int, inner: int, color):
        o2, i2 = outer * outer, inner * inner
        for y in range(cy - outer, cy + outer + 1):
            for x in range(cx - outer, cx + outer + 1):
                d = (x - cx) ** 2 + (y - cy) ** 2
                if i2 <= d <= o2:
                    self.pixel(x, y, color)

    def diamond(self, cx: int, cy: int, radius: int, color):
        for dy in range(-radius, radius + 1):
            span = radius - abs(dy)
            self.rect(cx - span, cy + dy, span * 2 + 1, 1, color)

    def star(self, cx: int, cy: int, radius: int, color, width=1, rays=4):
        for i in range(rays):
            a = (i * 6.283185307179586) / rays
            self.line(cx, cy, round(cx + radius * math.cos(a)),
                      round(cy + radius * math.sin(a)), color, width)


def png_bytes(image: Canvas) -> bytes:
    raw = b"".join(b"\0" + image.data[y * image.width * 4:(y + 1) * image.width * 4]
                   for y in range(image.height))
    def chunk(kind: bytes, data: bytes):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xffffffff)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", image.width, image.height, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def aseprite_bytes(image: Canvas, name: str) -> bytes:
    name_data = name.encode("utf-8")
    layer = struct.pack("<HHHHHHB3sH", 1, 0, 0, 0, 0, 0, 255, b"\0\0\0", len(name_data)) + name_data
    cel = struct.pack("<HhhBHh5sHH", 0, 0, 0, 255, 0, 0, b"\0" * 5, image.width, image.height) + image.data
    chunks = struct.pack("<IH", len(layer) + 6, 0x2004) + layer + struct.pack("<IH", len(cel) + 6, 0x2005) + cel
    frame = struct.pack("<IHHHHI", len(chunks) + 16, 0xF1FA, 2, 100, 0, 0) + chunks
    header = bytearray(128)
    struct.pack_into("<IHHHHHIH", header, 0, 128 + len(frame), 0xA5E0, 1, image.width,
                     image.height, 32, 1, 100)
    header[28] = 0
    struct.pack_into("<HBBhhHH", header, 32, 0, 1, 1, 0, 0, image.width, image.height)
    return bytes(header) + frame


def save(name: str, output: pathlib.Path, source: pathlib.Path, image: Canvas):
    output.parent.mkdir(parents=True, exist_ok=True)
    source.parent.mkdir(parents=True, exist_ok=True)
    png = png_bytes(image)
    ase = aseprite_bytes(image, name)
    output.write_bytes(png)
    source.write_bytes(ase)
    colors = sorted({tuple(image.data[i:i + 4]) for i in range(0, len(image.data), 4)})
    asset_id = name
    if name == "weapon_impacts_pixel":
        asset_id = "weapon_impacts_atlas"
    elif name == "elite_sprinter" or name.startswith("boss_"):
        asset_id = f"{name}_sprite"
    elif name in WEAPONS or name in RELICS:
        asset_id = f"{name}_icon"
    elif name in EVOLUTION_ROLES:
        asset_id = f"weapon_{EVOLUTION_ROLES[name]}_icon"
    metadata = {
        "asset_id": asset_id, "status": "candidate_not_approved", "skill": "dopamine-pixel-art",
        "generator": "game/tools/generate_neon_arcade_art.py", "generator_version": "3",
        "seed": GENERATION_SEED, "seed_policy": "fixed procedural geometry; seed is recorded but not consumed",
        "brief": "Distinct role silhouette pixel art using only docs/art/palette_master.gpl",
        "parameters": {"drawing_method": "deterministic role primitives", "asset_name": name,
                       "palette_source": "docs/art/palette_master.gpl", "seed_consumed": False},
        "dimensions": {"width": image.width, "height": image.height},
        "palette_rgba": [list(color) for color in colors],
        "source_path": str(source.relative_to(ASSETS)), "export_path": str(output.relative_to(ASSETS)),
        "source_sha256": hashlib.sha256(ase).hexdigest(), "export_sha256": hashlib.sha256(png).hexdigest(),
    }
    output.with_suffix(".json").write_text(json.dumps(metadata, indent=2) + "\n")


def colors_for(name: str, palette):
    low = EVOLUTION_ROLES.get(name, name).lower()
    accent = palette["accent_3"] if any(k in low for k in ("blood", "inferno", "wildfire", "crimson")) else \
             palette["yellow_3"] if any(k in low for k in ("star", "meteor", "celestial", "sun", "redline", "overdrive")) else \
             palette["accent_2"] if any(k in low for k in ("toxic", "plague", "pandemic")) else \
             palette["magenta_3"] if any(k in low for k in ("void", "singularity", "horizon", "prism", "storm", "circuit")) else \
             palette["cyan_3"]
    return palette["shadow_1"], palette["shadow_3"], accent, palette["neutral_2"]


def draw_catalog(name: str, palette) -> Canvas:
    c = Canvas(32, 32)
    shadow, edge, accent, light = colors_for(name, palette)
    low = EVOLUTION_ROLES.get(name, name).lower()
    dark = palette["shadow_1"]
    mid = palette["shadow_3"]
    cyan = palette["cyan_3"]
    magenta = palette["magenta_3"]
    yellow = palette["yellow_3"]
    green = palette["accent_2"]
    red = palette["accent_3"]
    evolved = name.startswith("evolution_")

    def bolt(color, width):
        c.line(19, 3, 9, 15, dark, width + 2)
        c.line(9, 15, 18, 15, dark, width + 2)
        c.line(18, 15, 11, 29, dark, width + 2)
        c.line(19, 3, 9, 15, color, width)
        c.line(9, 15, 18, 15, color, width)
        c.line(18, 15, 11, 29, color, width)

    if "storm_core" in low:
        c.ring(16, 16, 12, 9, dark); c.ring(16, 16, 10, 7, cyan)
        c.disc(16, 16, 6, mid); bolt(yellow, 2)
    elif "infinite_circuit" in low:
        c.ring(16, 16, 13, 10, dark); c.ring(16, 16, 11, 9, cyan)
        c.line(6, 16, 11, 16, magenta, 2); c.line(21, 16, 26, 16, magenta, 2)
        bolt(yellow, 2)
    elif "lightning" in low:
        bolt(light, 3)
        for x, y in ((6, 8), (24, 23), (24, 7)):
            c.disc(x, y, 2, yellow if x == 24 else cyan)
    elif "wildfire" in low:
        c.rect(7, 17, 13, 8, dark); c.rect(9, 18, 9, 5, red)
        c.line(19, 19, 25, 7, dark, 5); c.line(19, 19, 25, 7, yellow, 2)
        c.line(21, 20, 29, 12, dark, 4); c.line(21, 20, 29, 12, red, 2)
        c.line(18, 21, 26, 26, dark, 4); c.line(18, 21, 26, 26, yellow, 2)
    elif "inferno" in low or "sprayer" in low:
        c.rect(5, 12, 17, 10, dark); c.rect(7, 14, 13, 6, edge)
        c.rect(3, 15, 5, 4, light); c.rect(10, 22, 5, 6, dark); c.rect(11, 23, 3, 4, red)
        c.line(22, 12, 29, 8, yellow, 3); c.line(22, 16, 30, 16, red, 3); c.line(22, 20, 29, 24, yellow, 3)
    elif "bloodstorm" in low:
        for a, b, color in ((6, 24, red), (10, 27, light), (9, 7, light), (13, 11, red)):
            c.line(a, 24 if a < 8 else 27, a + 13, 8 if a < 8 else 11, dark, 5)
            c.line(a, 24 if a < 8 else 27, a + 13, 8 if a < 8 else 11, color, 2)
        c.pixel(7, 9, red); c.pixel(24, 23, red)
    elif "crimson" in low or "dagger" in low:
        c.line(5, 24, 23, 6, dark, 6); c.line(5, 24, 23, 6, light, 2)
        c.line(3, 22, 10, 27, red, 3); c.line(10, 27, 13, 24, dark, 2)
        c.line(10, 28, 28, 10, dark, 6); c.line(10, 28, 28, 10, red, 2)
        c.line(8, 26, 15, 30, light, 2)
    elif "redline" in low:
        c.rect(6, 12, 19, 9, dark); c.rect(8, 13, 14, 6, edge)
        c.rect(4, 14, 5, 4, light); c.rect(11, 21, 5, 7, dark); c.rect(12, 22, 3, 5, yellow)
        c.line(24, 12, 31, 12, red, 2); c.line(24, 16, 31, 16, yellow, 2); c.line(24, 20, 31, 20, red, 2)
    elif "minigun" in low:
        c.rect(6, 11, 20, 11, dark); c.rect(8, 13, 14, 6, edge)
        c.rect(3, 14, 6, 4, light); c.rect(10, 22, 5, 6, dark); c.rect(11, 23, 3, 4, accent)
        c.rect(22, 12, 8, 2, cyan); c.rect(22, 16, 8, 2, cyan); c.rect(22, 20, 8, 2, cyan)
        c.pixel(12, 14, yellow); c.pixel(17, 14, yellow)
    elif "pandemic" in low:
        for x, y, r in ((8, 17, 5), (15, 12, 6), (23, 17, 5), (15, 21, 4)):
            c.disc(x, y, r + 1, dark); c.disc(x, y, r - 1, green)
        c.disc(15, 16, 2, yellow)
        for x, y in ((5, 7), (26, 8), (27, 25), (4, 24)):
            c.pixel(x, y, green)
    elif "toxic" in low:
        c.disc(9, 18, 6, dark); c.disc(16, 12, 7, dark); c.disc(23, 18, 6, dark)
        c.disc(9, 17, 4, green); c.disc(16, 11, 5, green); c.disc(23, 17, 4, green)
        c.rect(8, 18, 16, 7, mid); c.pixel(12, 18, yellow); c.pixel(20, 18, yellow)
    elif "razorstorm" in low:
        c.star(16, 16, 11, dark, 5, 12); c.ring(16, 16, 8, 5, light)
        c.disc(16, 16, 3, edge); c.disc(16, 16, 1, red)
        c.star(7, 8, 4, red, 2, 8); c.star(25, 24, 4, cyan, 2, 8)
    elif "saw" in low:
        c.star(16, 16, 12, dark, 5, 12); c.ring(16, 16, 8, 5, light)
        c.disc(16, 16, 4, edge); c.disc(16, 16, 2, accent)
    elif "starfall" in low:
        c.star(18, 11, 8, dark, 5, 4); c.star(18, 11, 7, yellow, 2, 4)
        c.line(13, 17, 5, 25, dark, 5); c.line(13, 17, 5, 25, magenta, 2)
        c.line(17, 18, 12, 27, dark, 4); c.line(17, 18, 12, 27, light, 1)
    elif "meteor" in low or "staff" in low:
        c.line(7, 27, 22, 7, dark, 5); c.line(7, 27, 22, 7, edge, 2)
        c.line(8, 25, 21, 8, light, 1); c.star(23, 7, 5, dark, 4, 4)
        c.star(23, 7, 4, yellow, 2, 4); c.pixel(23, 7, light)
    elif "spectrum_collapse" in low:
        c.diamond(12, 16, 9, dark); c.diamond(12, 16, 6, magenta); c.diamond(12, 16, 3, light)
        c.line(19, 16, 30, 16, dark, 5); c.line(20, 16, 30, 16, cyan, 2)
        c.line(18, 13, 27, 7, yellow, 1); c.line(18, 19, 27, 25, red, 1)
    elif "prism_laser" in low or ("prism" in low and "crystal" not in low):
        c.diamond(10, 16, 7, dark); c.diamond(10, 16, 5, light); c.pixel(10, 16, magenta)
        c.line(17, 16, 30, 16, dark, 5); c.line(18, 16, 30, 16, cyan, 2)
        c.line(19, 13, 27, 8, yellow, 1); c.line(19, 19, 27, 24, magenta, 1)
    elif "event_horizon" in low:
        c.disc(16, 16, 7, dark); c.ring(16, 16, 12, 9, magenta)
        c.ring(16, 16, 14, 13, cyan); c.line(4, 16, 7, 16, yellow, 2); c.line(25, 16, 28, 16, yellow, 2)
    elif "void_orb" in low:
        c.ring(16, 16, 12, 9, dark); c.disc(16, 16, 8, magenta); c.disc(16, 16, 5, dark)
        c.pixel(14, 12, light); c.pixel(18, 20, cyan)
    elif "absolute_zero" in low:
        c.star(16, 16, 13, dark, 5, 6); c.star(16, 16, 11, cyan, 2, 6)
        c.star(16, 16, 6, light, 1, 6); c.disc(16, 16, 2, yellow)
    elif "frost_nova" in low:
        c.star(16, 16, 12, dark, 5, 4); c.star(16, 16, 10, cyan, 2, 4)
        c.star(16, 16, 7, light, 1, 8); c.disc(16, 16, 3, yellow)
    elif "frozen_crown" in low:
        c.line(5, 22, 5, 10, dark, 4); c.line(5, 10, 12, 17, dark, 4)
        c.line(12, 17, 17, 7, dark, 4); c.line(17, 7, 27, 21, dark, 4)
        c.line(6, 20, 6, 11, cyan, 2); c.line(6, 11, 12, 17, light, 2)
        c.line(12, 17, 17, 8, cyan, 2); c.line(17, 8, 26, 20, light, 2)
        c.line(5, 22, 27, 22, yellow, 3); c.pixel(17, 8, light)
    elif "prism_crystal" in low:
        c.diamond(16, 16, 12, dark); c.diamond(16, 16, 9, light); c.diamond(16, 16, 5, magenta)
        c.line(16, 5, 16, 27, cyan, 1); c.line(8, 12, 24, 20, yellow, 1); c.line(24, 12, 8, 20, edge, 1)
    elif "celestial_eye" in low:
        c.line(4, 16, 11, 9, dark, 4); c.line(11, 9, 21, 9, dark, 4); c.line(21, 9, 28, 16, dark, 4)
        c.line(28, 16, 21, 23, dark, 4); c.line(21, 23, 11, 23, dark, 4); c.line(11, 23, 4, 16, dark, 4)
        c.line(5, 16, 11, 11, light, 1); c.line(11, 11, 21, 11, cyan, 2); c.line(21, 11, 27, 16, light, 1)
        c.line(27, 16, 21, 21, magenta, 1); c.line(21, 21, 11, 21, light, 1); c.line(11, 21, 5, 16, magenta, 1)
        c.disc(16, 16, 4, yellow); c.disc(16, 16, 2, dark)
    elif "plague_mask" in low:
        c.rect(7, 10, 18, 14, dark); c.rect(9, 12, 14, 10, green)
        c.rect(10, 15, 4, 3, light); c.rect(18, 15, 4, 3, light)
        c.line(12, 21, 16, 18, dark, 2); c.line(16, 18, 20, 21, dark, 2)
        c.pixel(6, 14, magenta); c.pixel(26, 14, magenta)
    elif "blood_chalice" in low:
        c.line(7, 9, 25, 9, dark, 4); c.line(9, 10, 12, 19, dark, 4); c.line(23, 10, 20, 19, dark, 4)
        c.line(9, 10, 12, 18, red, 2); c.line(23, 10, 20, 18, red, 2); c.line(12, 19, 20, 19, light, 2)
        c.rect(14, 20, 4, 5, dark); c.rect(10, 26, 12, 3, edge); c.pixel(16, 13, yellow)
    elif "infernal_heart" in low or "magnet_heart" in low:
        heart = red if "infernal" in low else cyan
        c.disc(11, 13, 5, dark); c.disc(21, 13, 5, dark); c.line(7, 15, 16, 26, dark, 5); c.line(25, 15, 16, 26, dark, 5)
        c.disc(11, 12, 4, heart); c.disc(21, 12, 4, heart); c.line(8, 14, 16, 24, heart, 3); c.line(24, 14, 16, 24, heart, 3)
        c.pixel(15, 13, light); c.pixel(17, 13, yellow if "infernal" in low else magenta)
        if "magnet" in low:
            c.rect(7, 5, 5, 3, magenta); c.rect(20, 5, 5, 3, yellow)
    elif "overdrive_engine" in low:
        c.star(16, 16, 12, dark, 5, 8); c.ring(16, 16, 9, 5, yellow)
        c.disc(16, 16, 4, edge); c.disc(16, 16, 2, cyan)
        for x, y in ((16, 4), (26, 16), (16, 26), (6, 16)):
            c.rect(x - 1, y - 1, 3, 3, light)
    elif "magnetic_coil" in low:
        c.line(9, 6, 9, 17, dark, 6); c.line(9, 17, 16, 25, dark, 6)
        c.line(16, 25, 23, 17, dark, 6); c.line(23, 17, 23, 6, dark, 6)
        c.line(9, 7, 9, 17, cyan, 2); c.line(9, 17, 16, 24, magenta, 2)
        c.line(16, 24, 23, 17, cyan, 2); c.line(23, 17, 23, 7, magenta, 2)
        c.rect(6, 4, 7, 4, yellow); c.rect(20, 4, 7, 4, yellow)
    elif "frozen" in low or "crown" in low:
        c.line(5, 23, 5, 11, dark, 4); c.line(5, 11, 12, 17, dark, 4)
        c.line(12, 17, 17, 8, dark, 4); c.line(17, 8, 27, 22, dark, 4)
        c.line(6, 21, 6, 12, light, 1); c.line(6, 12, 12, 17, cyan, 2)
        c.line(12, 17, 17, 9, light, 1); c.line(17, 9, 26, 21, cyan, 2); c.line(5, 22, 27, 22, yellow, 3)
    elif "singularity" in low:
        c.disc(16, 16, 8, dark); c.ring(16, 16, 12, 9, magenta)
        c.line(5, 7, 13, 14, cyan, 2); c.line(27, 7, 19, 14, cyan, 2)
        c.line(5, 25, 13, 18, cyan, 2); c.line(27, 25, 19, 18, cyan, 2)
        c.pixel(7, 8, yellow); c.pixel(25, 8, light); c.pixel(7, 24, light); c.pixel(25, 24, yellow)
    elif "void" in low or "orb" in low or "horizon" in low:
        c.disc(16, 16, 8, dark); c.ring(16, 16, 12, 9, magenta); c.ring(16, 16, 14, 13, cyan)
        c.pixel(13, 12, light); c.pixel(19, 20, yellow)
    elif "eye" in low:
        c.line(4, 16, 11, 9, dark, 4); c.line(11, 9, 21, 9, dark, 4); c.line(21, 9, 28, 16, dark, 4)
        c.line(28, 16, 21, 23, dark, 4); c.line(21, 23, 11, 23, dark, 4); c.line(11, 23, 4, 16, dark, 4)
        c.line(5, 16, 11, 11, light, 1); c.line(11, 11, 21, 11, accent, 2); c.line(21, 11, 27, 16, light, 1)
        c.disc(16, 16, 4, edge); c.disc(16, 16, 2, yellow)
    elif "heart" in low:
        c.disc(11, 13, 5, dark); c.disc(21, 13, 5, dark); c.line(7, 15, 16, 26, dark, 5); c.line(25, 15, 16, 26, dark, 5)
        c.disc(11, 12, 4, accent); c.disc(21, 12, 4, accent); c.line(8, 14, 16, 24, accent, 3); c.line(24, 14, 16, 24, accent, 3)
        c.pixel(15, 12, light)
    elif "crown" in low:
        c.line(5, 22, 5, 10, dark, 4); c.line(5, 10, 12, 17, dark, 4)
        c.line(12, 17, 17, 7, dark, 4); c.line(17, 7, 27, 21, dark, 4)
        c.line(6, 20, 6, 11, light, 1); c.line(6, 11, 12, 17, accent, 2)
        c.line(12, 17, 17, 8, light, 1); c.line(17, 8, 26, 20, accent, 2); c.line(5, 22, 27, 22, yellow, 3)
    elif "mask" in low:
        c.rect(7, 10, 18, 14, dark); c.rect(9, 12, 14, 10, edge)
        c.rect(10, 14, 4, 3, accent); c.rect(18, 14, 4, 3, accent)
        c.line(12, 20, 16, 18, light, 2); c.line(16, 18, 20, 20, light, 2); c.rect(15, 20, 2, 2, yellow)
    elif "chalice" in low:
        c.line(7, 9, 25, 9, dark, 4); c.line(9, 10, 12, 19, dark, 4); c.line(23, 10, 20, 19, dark, 4)
        c.line(9, 10, 12, 18, accent, 2); c.line(23, 10, 20, 18, accent, 2); c.line(12, 19, 20, 19, light, 2)
        c.rect(14, 20, 4, 5, edge); c.rect(10, 26, 12, 3, light); c.pixel(16, 13, yellow)
    elif "magnet" in low or "coil" in low:
        c.line(9, 7, 9, 17, dark, 6); c.line(9, 17, 16, 25, dark, 6); c.line(16, 25, 23, 17, dark, 6); c.line(23, 17, 23, 7, dark, 6)
        c.line(9, 8, 9, 17, light, 2); c.line(9, 17, 16, 24, accent, 2); c.line(16, 24, 23, 17, light, 2); c.line(23, 17, 23, 8, accent, 2)
        c.rect(6, 5, 7, 4, yellow); c.rect(20, 5, 7, 4, magenta)
    elif "frost" in low or "nova" in low or "zero" in low:
        c.star(16, 16, 12, dark, 5, 6); c.star(16, 16, 10, light, 2, 6)
        c.star(16, 16, 6, accent, 1, 6); c.disc(16, 16, 2, yellow)
    elif "meteor" in low or "star" in low:
        c.star(17, 13, 8, dark, 5, 4); c.star(17, 13, 7, yellow, 2, 4)
        c.line(12, 19, 5, 26, dark, 5); c.line(12, 19, 5, 26, accent, 2)
    elif "laser" in low or "prism" in low or "crystal" in low:
        c.diamond(12, 16, 9, dark); c.diamond(12, 16, 6, light); c.diamond(12, 16, 3, accent)
        c.line(19, 16, 30, 16, dark, 5); c.line(20, 16, 30, 16, cyan, 2)
        c.line(19, 13, 27, 8, yellow, 1); c.line(19, 19, 27, 24, magenta, 1)
    elif "overdrive" in low or "engine" in low:
        c.star(16, 16, 12, dark, 5, 8); c.ring(16, 16, 9, 5, yellow); c.disc(16, 16, 3, edge)
        c.pixel(16, 6, cyan); c.pixel(25, 16, light); c.pixel(16, 25, magenta); c.pixel(7, 16, light)
    else:
        c.star(16, 16, 10, dark, 5, 6); c.star(16, 16, 8, accent, 2, 6); c.disc(16, 16, 3, light)
    if evolved and "lightning" not in low and "circuit" not in low:
        c.pixel(16, 4, yellow)
    return c


def draw_projectile(name: str, palette) -> Canvas:
    c = Canvas(16, 16)
    shadow, edge, accent, light = colors_for(name, palette)
    low = name.lower()
    cx = cy = 8
    if "razor" in low or "saw" in low:
        c.ring(cx, cy, 6, 3, light); c.disc(cx, cy, 2, edge)
        c.star(cx, cy, 7, accent, 1, 4)
    elif "absolute_zero" in low:
        c.star(cx, cy, 7, light, 1, 6); c.line(2, cy, 13, cy, accent, 2)
        c.line(cx, 2, cx, 13, accent, 2); c.disc(cx, cy, 2, edge)
    elif "frost" in low or "zero" in low or "lightning" in low or "shockwave" in low:
        c.star(cx, cy, 7, light, 2, 4); c.star(cx, cy, 4, accent, 1, 8)
        c.disc(cx, cy, 2, edge)
    elif "laser" in low or "prism" in low or "circuit" in low:
        c.diamond(cx, cy, 6, light); c.diamond(cx, cy, 3, accent)
        c.line(1, 8, 5, 8, edge, 1); c.line(11, 8, 15, 8, light, 1)
    elif "orb" in low or "horizon" in low or "singularity" in low or "core" in low:
        c.ring(cx, cy, 7, 4, light); c.disc(cx, cy, 3, edge); c.pixel(6, 5, accent); c.pixel(10, 11, accent)
    elif "toxic" in low or "pandemic" in low:
        for x, y, r in ((5, 8, 3), (9, 6, 3), (10, 10, 3)):
            c.disc(x, y, r, accent)
        c.pixel(8, 7, light); c.pixel(11, 9, light)
    elif "meteor" in low or "starfall" in low or "fragment" in low:
        c.diamond(cx + 1, cy - 1, 4, light); c.diamond(cx + 1, cy - 1, 2, accent)
        c.line(3, 12, 7, 9, edge, 2); c.pixel(2, 14, light)
    elif "inferno" in low or "wildfire" in low or "blood" in low or "crimson" in low:
        c.diamond(cx, cy, 5, accent); c.diamond(cx, cy - 1, 3, light)
        c.line(5, 13, 8, 10, edge, 1); c.pixel(4, 14, light)
    else:
        c.diamond(cx, cy, 5, edge); c.diamond(cx, cy, 3, accent); c.pixel(cx, cy, light)
        c.line(3, 12, 6, 9, shadow, 1)
    return c


def draw_impact(name: str, palette) -> Canvas:
    c = Canvas(64, 64)
    _, edge, accent, light = colors_for(name, palette)
    cx = cy = 32
    low = name.lower()
    if "ring" in low or "pop" in low:
        c.ring(cx, cy, 19 if "shock" in low else 14, 14 if "shock" in low else 10, accent)
        c.ring(cx, cy, 11, 8, light)
        for x, y in ((9, 15), (52, 18), (12, 48), (50, 46)):
            c.rect(x, y, 3, 3, light)
    elif "slash" in low or "angular" in low:
        c.line(12, 50, 43, 15, accent, 8); c.line(17, 48, 47, 14, light, 3)
        c.line(9, 48, 16, 53, edge, 2); c.line(44, 12, 54, 13, light, 2)
    elif "shard" in low or "evolved" in low:
        for x, y, dx, dy in ((32, 7, 0, 16), (54, 24, -13, 8), (48, 53, -10, -12), (14, 51, 9, -12), (8, 20, 14, 9)):
            c.line(x, y, x + dx, y + dy, light if x % 2 else accent, 4)
        c.disc(cx, cy, 6, edge); c.disc(cx, cy, 3, light)
    elif "star" in low or "spark" in low:
        c.star(cx, cy, 25 if "star" in low else 20, light, 4, 4)
        c.star(cx, cy, 13, accent, 2, 8)
        c.pixel(8, 16, light); c.pixel(53, 47, accent)
    elif "burst" in low:
        for a in range(12):
            angle = a * 6.283185307179586 / 12
            radius = 25 if a % 2 == 0 else 18
            x, y = round(cx + math.cos(angle) * radius), round(cy + math.sin(angle) * radius)
            c.line(cx, cy, x, y, light if a % 3 else accent, 3)
        c.disc(cx, cy, 9, edge)
    else:
        c.diamond(cx, cy, 19, accent); c.diamond(cx, cy, 10, edge); c.disc(cx, cy, 5, light)
        c.line(6, 32, 18, 32, light, 2); c.line(46, 32, 58, 32, light, 2)
    return c


def draw_boss_core(palette) -> Canvas:
    c = Canvas(96, 96)
    shadow, edge, accent, light = colors_for("boss_core", palette)
    cx = cy = 48
    c.ring(cx, cy, 39, 34, edge); c.ring(cx, cy, 29, 23, accent)
    c.ring(cx, cy, 18, 12, light); c.disc(cx, cy, 9, shadow)
    for a in range(8):
        angle = a * 6.283185307179586 / 8
        x, y = round(cx + math.cos(angle) * 43), round(cy + math.sin(angle) * 43)
        c.line(round(cx + math.cos(angle) * 33), round(cy + math.sin(angle) * 33), x, y, light, 3)
        c.rect(x - 3, y - 3, 7, 7, accent if a % 2 else edge)
    c.line(30, 48, 66, 48, light, 2); c.line(48, 30, 48, 66, accent, 2)
    for x, y in ((34, 37), (61, 34), (58, 61), (37, 59)):
        c.disc(x, y, 3, light)
    return c


def draw_signal_prism(palette) -> Canvas:
    c = Canvas(32, 32)
    shadow, edge, accent, light = colors_for("signal_prism", palette)
    c.diamond(16, 16, 13, edge)
    c.diamond(16, 16, 10, shadow)
    c.line(16, 4, 16, 27, light, 2)
    c.line(5, 16, 27, 16, accent, 2)
    c.line(8, 8, 24, 24, light, 1)
    c.line(24, 8, 8, 24, accent, 1)
    c.diamond(16, 16, 4, light)
    c.pixel(16, 16, palette["yellow_3"])
    return c


def draw_ui_catalog(icon: str, palette) -> Canvas:
    c = Canvas(32, 32)
    shadow, edge, accent, light = colors_for(icon, palette)
    if icon.startswith("rarity_"):
        accent = {
            "rarity_normal": palette["neutral_2"], "rarity_magic": palette["cyan_3"],
            "rarity_mystic": palette["magenta_3"], "rarity_legendary": palette["yellow_3"],
            "rarity_mythic": palette["accent_3"],
        }[icon]
        c.star(16, 16, 13, edge, 5, 5)
        c.star(16, 16, 9, accent, 3, 5)
        c.disc(16, 16, 3, light)
    elif icon == "equipment_helmet":
        c.rect(6, 9, 20, 13, edge); c.rect(8, 7, 16, 13, shadow)
        c.rect(10, 10, 12, 5, accent); c.rect(9, 16, 14, 2, light)
        c.rect(5, 21, 22, 3, edge)
    elif icon == "equipment_armor":
        c.diamond(16, 16, 13, edge); c.diamond(16, 16, 10, shadow)
        c.rect(9, 8, 14, 15, accent); c.rect(13, 12, 6, 8, light)
        c.rect(6, 10, 5, 7, edge); c.rect(21, 10, 5, 7, edge)
    elif icon == "equipment_gloves":
        for x, y, width, height in ((9, 7, 4, 12), (14, 5, 4, 14), (19, 7, 4, 12), (8, 17, 16, 9)):
            c.rect(x, y, width, height, edge)
        c.rect(10, 18, 12, 6, accent); c.rect(12, 20, 8, 2, light)
    elif icon == "equipment_boots":
        c.rect(8, 6, 8, 15, edge); c.rect(17, 9, 8, 12, edge)
        c.rect(7, 19, 11, 6, accent); c.rect(16, 18, 11, 7, accent)
        c.rect(6, 25, 13, 2, light); c.rect(15, 25, 13, 2, light)
    elif icon == "equipment_amulet":
        c.line(8, 6, 16, 18, edge, 2); c.line(24, 6, 16, 18, edge, 2)
        c.diamond(16, 20, 9, edge); c.diamond(16, 20, 6, accent); c.diamond(16, 20, 3, light)
    elif icon == "equipment_ring":
        c.ring(16, 19, 11, 6, edge); c.ring(16, 19, 8, 5, accent)
        c.diamond(16, 7, 6, edge); c.diamond(16, 7, 3, light)
    elif icon == "resource_essence":
        c.disc(16, 16, 13, edge); c.disc(16, 16, 9, accent); c.star(16, 16, 6, light, 2, 4)
    elif icon == "resource_powder":
        for x, y, radius in ((8, 19, 4), (13, 14, 6), (20, 18, 5), (24, 22, 3)):
            c.disc(x, y, radius, edge); c.disc(x, y, max(1, radius - 2), accent)
        c.pixel(15, 9, light); c.pixel(19, 11, light)
    elif icon == "skill_node":
        c.ring(16, 16, 14, 10, edge); c.ring(16, 16, 9, 6, accent); c.disc(16, 16, 4, light)
        c.line(16, 2, 16, 6, light); c.line(16, 26, 16, 30, light)
    elif icon == "achievement_medal":
        c.star(16, 12, 11, edge, 5, 5); c.star(16, 12, 7, accent, 3, 5)
        c.rect(10, 20, 5, 9, edge); c.rect(17, 20, 5, 9, edge); c.rect(11, 21, 3, 6, light)
    else:  # run record
        c.rect(7, 4, 18, 24, edge); c.rect(9, 6, 14, 20, shadow)
        c.rect(11, 10, 10, 2, accent); c.rect(11, 15, 8, 2, light); c.rect(11, 20, 10, 2, accent)
        c.pixel(22, 26, light)
    return c


def draw_elite_role(palette) -> Canvas:
    c = Canvas(24, 24)
    shadow, edge, accent, light = colors_for("elite_sprinter", palette)
    # Generic elite prototype: readable armored body, separate aura, and a
    # four-point yellow rank mark. No canon identity is implied.
    c.ring(12, 13, 11, 9, accent)
    c.line(8, 18, 6, 21, edge, 2)
    c.line(16, 18, 18, 21, edge, 2)
    c.disc(12, 14, 6, edge)
    c.diamond(12, 13, 4, shadow)
    c.rect(8, 11, 9, 3, light)
    c.rect(10, 12, 5, 1, accent)
    c.star(12, 3, 3, palette["yellow_3"], 1, 4)
    return c


def draw_generic_boss_role(name: str, palette) -> Canvas:
    c = Canvas(96, 96)
    shadow, edge, accent, light = colors_for(name, palette)
    cx = cy = 48
    if name == "boss_pulse_warden":
        # Generic pulse/guard role motif; this makes no canon claim about identity.
        c.ring(cx, cy, 38, 32, edge)
        c.ring(cx, cy, 25, 20, accent)
        c.diamond(cx, cy, 15, light)
        c.diamond(cx, cy, 8, shadow)
        for x, y in ((48, 5), (48, 91), (5, 48), (91, 48)):
            c.disc(x, y, 3, light)
    else:
        c.ring(cx, cy, 40, 34, accent)
        c.ring(cx, cy, 27, 21, edge)
        c.star(cx, cy, 18, light, 3, 8)
        c.disc(cx, cy, 8, shadow)
    return c


def draw_ruins(palette) -> Canvas:
    # Generic, low contrast masonry remains an environment role, not a biome identity.
    c = Canvas(1536, 1536)
    rng = hashlib.sha256(b"neon-arcade-masonry-layout-v2").digest()
    dark, mid, hi = palette["shadow_1"], palette["shadow_2"], palette["shadow_3"]
    cell = 48
    for row in range(32):
        offset = 24 if row % 2 else 0
        for col in range(32):
            v = rng[(row * 32 + col) % len(rng)]
            # A broad open lane keeps combat silhouettes legible.
            px, py = col * cell + offset, row * cell
            if 10 <= col <= 21 and 9 <= row <= 23:
                continue
            if v < 92:
                continue
            w = 22 + (v % 20)
            h = 14 + ((v // 3) % 22)
            color = mid if v < 180 else hi
            c.rect(px, py, w, h, color)
            if v % 5 == 0:
                c.rect(px + 5, py + 5, max(2, w - 10), 2, dark)
    return c


def output_pair(name: str, png: pathlib.Path, source: pathlib.Path, image: Canvas):
    if SELECTED_IDS and name not in SELECTED_IDS:
        return
    save(name, png, source, image)


def generate(families: set[str], palette):
    source_dir = ASSETS / "source/original_procedural"
    if "catalog" in families:
        for name in WEAPONS + EVOLUTIONS + RELICS:
            output_pair(name, ASSETS / "sprites/catalog" / f"{name}.png", source_dir / f"{name}.aseprite", draw_catalog(name, palette))
    if "projectiles" in families:
        for name in PROJECTILES:
            output_pair(name, ASSETS / "sprites/projectiles" / f"{name}.png", source_dir / f"{name}.aseprite", draw_projectile(name, palette))
    if "vfx" in families:
        atlas = Canvas(640, 64)
        for i, name in enumerate(IMPACTS):
            cell = draw_impact(name, palette)
            output_pair(name, ASSETS / "sprites/vfx" / f"{name}.png", source_dir / f"{name}.aseprite", cell)
            for y in range(64):
                start = (y * 64) * 4
                atlas.data[(y * 640 + i * 64) * 4:(y * 640 + (i + 1) * 64) * 4] = cell.data[start:start + 256]
        output_pair("weapon_impacts_pixel", ASSETS / "sprites/weapon_impacts_pixel.png", source_dir / "weapon_impacts_pixel.aseprite", atlas)
    if "environment" in families:
        ground = Canvas(16, 16)
        floor, seam, speck = palette["shadow_2"], palette["shadow_3"], palette["shadow_4"]
        ground.data[:] = bytes(floor) * (16 * 16)
        for x, y, color in ((3, 4, seam), (10, 5, speck), (7, 11, seam), (12, 13, speck)):
            ground.pixel(x, y, color)
        output_pair("survival_ground_tile", ASSETS / "sprites/environment/survival_ground_tile.png", ASSETS / "source/environment/survival_ground_tile.aseprite", ground)
        output_pair("survival_ruins_pixel", ASSETS / "sprites/environment/survival_ruins_pixel.png", source_dir / "survival_ruins_pixel.aseprite", draw_ruins(palette))
    if "boss" in families:
        output_pair("boss_dopamine_core", ASSETS / "sprites/roster/boss_dopamine_core.png", source_dir / "boss_dopamine_core.aseprite", draw_boss_core(palette))
    if "ui" in families:
        output_pair("signal_prism", ASSETS / "icons/ui/signal_prism.png", source_dir / "signal_prism.aseprite", draw_signal_prism(palette))
    if "ui_catalog" in families:
        for icon in UI_CATALOG:
            name = f"ui_{icon}"
            output_pair(name, ASSETS / "icons/catalog" / f"{icon}.png",
                        ASSETS / "source/ui" / f"{icon}.aseprite", draw_ui_catalog(icon, palette))
    if "roles" in families:
        for name in ("elite_sprinter", "boss_pulse_warden"):
            image = draw_elite_role(palette) if name == "elite_sprinter" else draw_generic_boss_role(name, palette)
            output_pair(name, ASSETS / "sprites/roster" / f"{name}.png", source_dir / f"{name}.aseprite", image)


def main():
    global ASSETS, SELECTED_IDS, GENERATION_SEED
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("families", nargs="*", choices=sorted(FAMILIES))
    parser.add_argument("--out-root", type=pathlib.Path, default=ASSETS,
        help="Output root; use build/assets/candidates/pixel-art for staged candidates")
    parser.add_argument("--ids", nargs="+", help="Write only these output asset IDs")
    parser.add_argument("--seed", type=int, default=0, help="Record generation seed (geometry is deterministic)")
    args = parser.parse_args()
    ASSETS = args.out_root.resolve()
    SELECTED_IDS = set(args.ids or [])
    GENERATION_SEED = args.seed
    requested = set(args.families)
    if not requested:
        requested = set(FAMILIES)
    known_ids = set(WEAPONS + EVOLUTIONS + RELICS + PROJECTILES + IMPACTS + [
        "weapon_impacts_pixel", "survival_ground_tile", "survival_ruins_pixel", "boss_dopamine_core",
        "signal_prism", "elite_sprinter", "boss_pulse_warden",
    ])
    known_ids.update(f"ui_{icon}" for icon in UI_CATALOG)
    unknown = SELECTED_IDS - known_ids
    if unknown:
        parser.error(f"unknown asset IDs: {sorted(unknown)}")
    palette = load_palette()
    generate(requested, palette)
    print(f"Generated candidates under {ASSETS} for {', '.join(sorted(requested))} from 32 Art Bible colors; no existing image was loaded")


if __name__ == "__main__":
    main()
