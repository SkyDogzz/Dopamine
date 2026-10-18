#!/usr/bin/env python3
"""Draw a fresh Neon Arcade asset set from primitives and the Art Bible palette."""

from __future__ import annotations

import hashlib
import math
import pathlib
import re
import struct
import sys
import zlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
PALETTE_FILE = ROOT / "docs/art/palette_master.gpl"
ASSETS = ROOT / "game/assets"

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
FAMILIES = {"catalog", "projectiles", "vfx", "environment", "boss", "ui", "roles"}


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
    output.write_bytes(png_bytes(image))
    source.write_bytes(aseprite_bytes(image, name))


def colors_for(name: str, palette):
    low = EVOLUTION_ROLES.get(name, name).lower()
    accent = palette["accent_3"] if any(k in low for k in ("blood", "inferno", "wildfire", "crimson")) else \
             palette["yellow_3"] if any(k in low for k in ("star", "meteor", "celestial", "sun")) else \
             palette["accent_2"] if any(k in low for k in ("toxic", "plague", "pandemic")) else \
             palette["magenta_3"] if any(k in low for k in ("void", "singularity", "horizon", "prism")) else \
             palette["cyan_3"]
    return palette["shadow_1"], palette["shadow_3"], accent, palette["neutral_2"]


def draw_catalog(name: str, palette) -> Canvas:
    c = Canvas(32, 32)
    shadow, edge, accent, light = colors_for(name, palette)
    low = EVOLUTION_ROLES.get(name, name).lower()
    cx = cy = 16
    # Each category uses a new centered badge silhouette with a role-specific mark.
    c.diamond(cx, cy, 14, edge)
    c.diamond(cx, cy, 11, shadow)
    c.diamond(cx, cy, 8, accent)
    c.diamond(cx, cy, 5, edge)
    c.diamond(cx, cy, 3, light)
    if "dagger" in low or "razor" in low:
        c.line(7, 22, 20, 9, light, 3); c.line(12, 26, 25, 13, accent, 3)
        c.line(5, 19, 10, 24, edge, 2); c.line(15, 23, 23, 15, shadow, 1)
    elif "staff" in low or "scepter" in low:
        c.line(9, 25, 23, 7, light, 3); c.disc(23, 7, 4, accent); c.disc(23, 7, 2, light)
    elif "minigun" in low or "overdrive" in low or "circuit" in low or "coil" in low:
        c.rect(8, 13, 16, 8, edge); c.rect(6, 14, 4, 6, light)
        for y in (14, 17, 20): c.rect(22, y, 6, 2, accent)
        c.line(10, 11, 10, 23, light, 1)
    elif "laser" in low or "prism" in low:
        c.diamond(13, 16, 7, light); c.line(18, 16, 29, 16, accent, 2)
        c.line(19, 13, 28, 8, light, 1); c.line(19, 19, 28, 24, light, 1)
    elif "orb" in low or "core" in low or "heart" in low or "horizon" in low or "singularity" in low:
        c.ring(16, 16, 9, 5, light); c.disc(16, 16, 4, edge); c.disc(16, 16, 2, shadow)
        c.line(5, 16, 9, 16, accent, 2); c.line(23, 16, 27, 16, accent, 2)
    elif "crown" in low or "mask" in low or "helmet" in low:
        c.line(7, 21, 7, 11, light, 2); c.line(7, 11, 13, 17, accent, 2)
        c.line(13, 17, 18, 9, light, 2); c.line(18, 9, 25, 20, accent, 2)
        c.line(7, 22, 25, 22, light, 2)
    elif "chalice" in low or "bottle" in low or "sprayer" in low:
        c.line(9, 9, 23, 9, light, 2); c.line(10, 10, 12, 21, accent, 2)
        c.line(22, 10, 20, 21, accent, 2); c.line(12, 21, 20, 21, light, 2)
        c.rect(14, 22, 4, 5, edge); c.rect(10, 27, 12, 2, light)
    elif "saw" in low or "gear" in low:
        c.ring(16, 16, 9, 5, light); c.disc(16, 16, 3, edge)
        for x, y in ((16, 5), (16, 27), (5, 16), (27, 16), (8, 8), (24, 24)):
            c.rect(x - 1, y - 1, 3, 3, accent)
    elif "magnet" in low:
        c.line(10, 8, 10, 18, light, 3); c.line(10, 18, 16, 25, accent, 3)
        c.line(16, 25, 22, 18, light, 3); c.line(22, 18, 22, 8, accent, 3)
        c.rect(7, 6, 6, 4, edge); c.rect(19, 6, 6, 4, edge)
    elif "eye" in low:
        c.line(6, 16, 12, 10, light, 2); c.line(12, 10, 20, 10, light, 2)
        c.line(20, 10, 26, 16, light, 2); c.line(26, 16, 20, 22, accent, 2)
        c.line(20, 22, 12, 22, accent, 2); c.line(12, 22, 6, 16, accent, 2)
        c.disc(16, 16, 4, edge); c.disc(16, 16, 2, light)
    elif "absolute_zero" in low:
        c.star(16, 16, 11, light, 2, 6)
        c.line(6, 6, 26, 26, accent, 2); c.line(26, 6, 6, 26, accent, 2)
        c.diamond(16, 16, 3, edge)
    elif "nova" in low or "frost" in low or "zero" in low:
        c.star(16, 16, 11, light, 2, 4); c.star(16, 16, 7, accent, 1, 8)
    elif "meteor" in low or "starfall" in low:
        c.star(17, 14, 8, light, 2, 4); c.line(9, 19, 4, 25, accent, 2); c.line(13, 20, 10, 27, edge, 1)
    elif "toxic" in low or "plague" in low or "pandemic" in low:
        c.disc(11, 17, 5, light); c.disc(17, 12, 6, accent); c.disc(22, 18, 5, edge)
        c.rect(10, 18, 12, 5, shadow); c.line(13, 17, 13, 21, light, 1); c.line(19, 16, 19, 21, light, 1)
    else:
        c.star(16, 16, 10, light, 2, 6); c.disc(16, 16, 3, accent)
    # Four offset status pixels make the new family legible at thumbnail size.
    token = hashlib.sha256(name.encode()).digest()
    for i in range(3):
        x, y = 4 + token[i] % 4, 5 + token[i + 3] % 5
        c.pixel(x, y, light)
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


def draw_elite_role(palette) -> Canvas:
    c = Canvas(24, 24)
    shadow, edge, accent, light = colors_for("elite_sprinter", palette)
    c.line(5, 18, 15, 8, edge, 5)
    c.line(9, 20, 20, 9, accent, 4)
    c.line(4, 11, 9, 6, light, 2)
    c.line(3, 17, 7, 13, light, 1)
    c.pixel(17, 5, shadow)
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
    if "roles" in families:
        for name in ("elite_sprinter", "boss_pulse_warden"):
            image = draw_elite_role(palette) if name == "elite_sprinter" else draw_generic_boss_role(name, palette)
            output_pair(name, ASSETS / "sprites/roster" / f"{name}.png", source_dir / f"{name}.aseprite", image)


def main():
    requested = set(sys.argv[1:])
    if not requested:
        requested = set(FAMILIES)
    if requested - FAMILIES:
        raise SystemExit(f"Unknown family: {', '.join(sorted(requested - FAMILIES))}")
    palette = load_palette()
    generate(requested, palette)
    print(f"Generated {', '.join(sorted(requested))} from 32 Art Bible colors; no existing image was loaded")


if __name__ == "__main__":
    main()
