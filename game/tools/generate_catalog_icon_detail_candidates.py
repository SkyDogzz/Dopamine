#!/usr/bin/env python3
"""Stage the owner-requested detailed v2 pass for the 48 catalog-sheet icons."""
from __future__ import annotations
import argparse
import json
import pathlib
import generate_neon_arcade_art as base

ROOT = pathlib.Path(__file__).resolve().parents[2]
Canvas = base.Canvas
EVOLUTION_ROLES = base.EVOLUTION_ROLES
colors_for = base.colors_for
_original_draw_catalog = base.draw_catalog
_original_draw_ui_catalog = base.draw_ui_catalog
_original_draw_signal_prism = base.draw_signal_prism

def add_catalog_detail(name: str, c: Canvas, palette) -> None:
    """Add small readable construction details without changing each icon's silhouette."""
    low = EVOLUTION_ROLES.get(name, name).lower()
    ink, shade = palette["shadow_1"], palette["shadow_4"]
    accent = colors_for(name, palette)[2]
    mid, shine = palette["shadow_5"], palette["neutral_1"]
    cyan, magenta = palette["cyan_4"], palette["magenta_4"]
    yellow, red, green = palette["yellow_4"], palette["accent_4"], palette["accent_2"]

    if any(word in low for word in ("lightning", "circuit", "storm_core")):
        c.line(4, 8, 8, 8, cyan); c.line(8, 8, 8, 11, cyan)
        c.line(24, 21, 27, 21, magenta); c.line(27, 18, 27, 21, magenta)
        c.pixel(8, 7, shine); c.pixel(24, 22, yellow)
        if "core" in low or "circuit" in low:
            c.rect(13, 5, 2, 2, shine); c.rect(18, 25, 2, 2, shine)
            c.pixel(7, 16, yellow); c.pixel(25, 15, cyan)
    elif any(word in low for word in ("inferno", "sprayer", "wildfire")):
        c.rect(10, 11, 7, 2, shade); c.rect(11, 12, 5, 1, mid)
        c.rect(6, 13, 1, 4, shine); c.rect(18, 14, 2, 3, yellow)
        c.pixel(9, 16, cyan); c.pixel(13, 16, shine)
        if "wildfire" in low:
            c.line(25, 6, 27, 3, yellow); c.line(28, 13, 30, 11, red)
            c.pixel(24, 25, yellow); c.pixel(16, 20, shine)
        else:
            c.rect(13, 23, 2, 3, shade); c.pixel(12, 24, red)
    elif any(word in low for word in ("crimson", "dagger", "bloodstorm", "blood_chalice")):
        c.line(7, 22, 10, 19, shine); c.line(12, 26, 15, 23, yellow)
        c.pixel(9, 24, red); c.pixel(23, 8, shine)
        if "chalice" in low:
            c.line(8, 12, 5, 16, yellow); c.line(24, 12, 27, 16, yellow)
            c.pixel(13, 14, red); c.pixel(18, 14, red); c.rect(15, 23, 2, 2, shine)
        else:
            c.pixel(4, 19, red); c.pixel(27, 25, red)
    elif any(word in low for word in ("minigun", "redline")):
        for x in (24, 27, 30):
            c.pixel(x, 13, ink); c.pixel(x, 17, ink); c.pixel(x, 21, ink)
        c.rect(9, 11, 7, 1, mid); c.rect(10, 20, 5, 1, shade)
        c.pixel(7, 13, shine); c.pixel(7, 18, yellow)
        if "redline" in low:
            c.line(8, 10, 20, 10, red); c.line(8, 21, 20, 21, yellow)
            c.pixel(17, 14, shine); c.pixel(17, 18, shine)
    elif any(word in low for word in ("toxic", "pandemic", "plague", "mask")):
        c.pixel(10, 10, yellow); c.pixel(21, 10, yellow)
        c.line(13, 20, 16, 22, ink); c.line(16, 22, 19, 20, ink)
        c.pixel(8, 14, shine); c.pixel(23, 14, shine)
        if "mask" in low or "pandemic" in low:
            c.rect(11, 23, 3, 2, shade); c.rect(18, 23, 3, 2, shade)
            c.line(7, 18, 5, 20, green); c.line(25, 18, 27, 20, green)
        else:
            c.pixel(5, 13, green); c.pixel(27, 14, green)
            c.pixel(7, 24, yellow); c.pixel(25, 24, yellow)
    elif any(word in low for word in ("saw", "razor")):
        c.disc(16, 16, 2, yellow); c.pixel(16, 13, ink); c.pixel(16, 19, ink)
        c.pixel(13, 16, ink); c.pixel(19, 16, ink)
        for x, y in ((8, 8), (24, 8), (8, 24), (24, 24)):
            c.pixel(x, y, shine if (x + y) % 2 else cyan)
    elif any(word in low for word in ("meteor", "starfall", "celestial", "staff")):
        c.line(8, 25, 11, 22, shade); c.line(11, 21, 14, 18, mid)
        c.pixel(20, 7, shine); c.pixel(24, 10, yellow)
        if "celestial" in low:
            c.pixel(13, 14, shine); c.pixel(19, 14, shine)
            c.line(13, 19, 19, 19, magenta)
        else:
            c.line(19, 11, 22, 8, shine); c.pixel(5, 25, yellow)
    elif any(word in low for word in ("prism", "spectrum", "crystal")):
        c.line(8, 10, 12, 14, cyan); c.line(12, 14, 12, 19, shine)
        c.line(12, 19, 8, 23, magenta); c.line(12, 14, 16, 12, yellow)
        c.pixel(17, 16, shine); c.pixel(24, 16, yellow)
        if "spectrum" in low:
            c.pixel(22, 9, red); c.pixel(25, 12, yellow)
            c.pixel(22, 22, cyan); c.pixel(25, 19, magenta)
    elif any(word in low for word in ("void", "orb", "horizon", "singularity")):
        c.pixel(11, 9, yellow); c.pixel(21, 8, shine)
        c.pixel(8, 18, cyan); c.pixel(24, 20, magenta)
        c.line(6, 11, 9, 13, shade); c.line(23, 18, 26, 16, shade)
        if "horizon" in low or "singularity" in low:
            c.pixel(12, 15, shine); c.pixel(20, 17, yellow)
            c.line(10, 23, 13, 21, cyan); c.line(19, 11, 22, 9, magenta)
    elif any(word in low for word in ("frost", "nova", "zero", "frozen", "crown")):
        for x, y in ((16, 4), (16, 27), (4, 16), (27, 16)):
            c.pixel(x, y, shine)
        c.line(9, 9, 11, 11, cyan); c.line(21, 21, 23, 23, cyan)
        c.pixel(13, 15, yellow); c.pixel(19, 17, shine)
        if "crown" in low:
            c.rect(10, 23, 2, 2, magenta); c.rect(21, 23, 2, 2, magenta)
            c.pixel(16, 11, shine)
    elif "overdrive" in low or "engine" in low:
        c.rect(13, 8, 2, 3, shade); c.rect(17, 8, 2, 3, shade)
        c.rect(13, 21, 2, 3, shade); c.rect(17, 21, 2, 3, shade)
        c.pixel(10, 10, shine); c.pixel(22, 10, yellow)
        c.pixel(10, 22, cyan); c.pixel(22, 22, magenta)
    elif "magnet" in low or "coil" in low:
        for y in (10, 13, 16):
            c.line(10, y, 12, y, yellow); c.line(20, y, 22, y, cyan)
        c.rect(7, 5, 2, 2, shine); c.rect(23, 5, 2, 2, shine)
        c.pixel(16, 24, magenta)
    elif "eye" in low:
        c.pixel(10, 13, shine); c.pixel(22, 13, shine)
        c.line(14, 9, 18, 9, yellow); c.line(14, 23, 18, 23, magenta)
        c.pixel(16, 14, ink); c.pixel(16, 18, ink)
    elif "heart" in low:
        c.line(10, 12, 12, 10, shine); c.line(20, 10, 22, 12, yellow)
        c.line(16, 16, 16, 22, red if "infernal" in low else cyan)
        c.pixel(13, 17, shine); c.pixel(19, 17, shine)
    else:
        c.pixel(10, 10, shine); c.pixel(22, 10, yellow)
        c.line(10, 22, 13, 25, shade); c.line(22, 22, 19, 25, mid)

    # Larger in-silhouette details make each 32px symbol read as a built object,
    # not a flat glyph; all marks are kept inside the existing role silhouette.
    if any(word in low for word in ("sprayer", "minigun", "redline")):
        c.rect(9, 12, 9, 2, mid); c.rect(10, 13, 6, 1, shine)
        c.rect(9, 18, 7, 2, shade); c.pixel(11, 19, cyan); c.pixel(14, 19, yellow)
        c.rect(20, 13, 2, 6, shade); c.pixel(21, 14, shine); c.pixel(21, 18, shine)
    elif any(word in low for word in ("crimson", "dagger", "bloodstorm")):
        c.line(8, 23, 10, 21, shade, 2); c.line(10, 21, 12, 19, mid)
        c.pixel(8, 25, yellow); c.pixel(11, 26, shine)
        c.line(20, 9, 22, 7, shine); c.pixel(24, 6, yellow)
        if "bloodstorm" in low:
            c.disc(16, 16, 3, shade); c.disc(16, 16, 1, yellow)
            c.pixel(16, 11, shine); c.pixel(16, 21, shine)
    elif any(word in low for word in ("saw", "razor")):
        c.ring(16, 16, 6, 4, shade)
        for x, y, color in ((16, 8, shine), (23, 12, cyan), (22, 21, yellow),
                            (10, 21, shine), (9, 12, magenta)):
            c.pixel(x, y, color)
        c.pixel(15, 15, ink); c.pixel(17, 17, ink)
    elif "meteor_staff" in name:
        c.line(8, 24, 11, 21, shade); c.line(11, 20, 14, 17, mid)
        c.line(14, 16, 17, 13, shade); c.line(18, 11, 21, 8, mid)
        c.pixel(10, 22, yellow); c.pixel(13, 18, cyan); c.pixel(17, 14, shine)
    elif any(word in low for word in ("prism_laser", "spectrum_collapse")):
        c.rect(17, 14, 4, 4, shade); c.pixel(18, 15, shine)
        c.line(22, 14, 27, 10, cyan); c.line(22, 16, 29, 16, yellow)
        c.line(22, 18, 27, 22, magenta); c.pixel(28, 15, shine)
    elif any(word in low for word in ("storm_core", "infinite_circuit")):
        c.rect(12, 7, 3, 2, shade); c.rect(17, 23, 3, 2, shade)
        c.line(8, 10, 10, 12, mid); c.line(24, 20, 26, 22, mid)
        c.pixel(9, 11, shine); c.pixel(25, 21, yellow)
    elif "infernal_heart" in low or "magnet_heart" in low:
        c.line(11, 13, 13, 15, shade); c.line(21, 13, 19, 15, shade)
        c.line(13, 18, 15, 20, red if "infernal" in low else cyan)
        c.line(19, 18, 17, 20, red if "infernal" in low else cyan)
        c.pixel(16, 12, shine); c.pixel(16, 23, yellow)
    elif "blood_chalice" in low:
        c.rect(11, 13, 2, 3, red); c.rect(19, 13, 2, 3, red)
        c.line(13, 17, 19, 17, yellow); c.rect(15, 21, 2, 4, mid)
        c.line(11, 27, 14, 27, shine); c.line(18, 27, 21, 27, shine)
    elif "plague_mask" in low:
        c.rect(10, 16, 4, 4, shade); c.rect(18, 16, 4, 4, shade)
        c.rect(11, 17, 2, 2, cyan); c.rect(19, 17, 2, 2, yellow)
        c.line(14, 21, 18, 21, ink); c.pixel(16, 22, shine)
        c.line(8, 13, 5, 11, green); c.line(24, 13, 27, 11, green)
    elif "magnetic_coil" in low:
        for y in (10, 13, 16, 19):
            c.rect(8, y, 3, 1, yellow); c.rect(21, y, 3, 1, cyan)
        c.rect(6, 5, 2, 3, shade); c.rect(24, 5, 2, 3, shade)
        c.pixel(7, 5, shine); c.pixel(25, 5, shine)
    elif "celestial_eye" in low:
        c.disc(16, 16, 5, shade); c.disc(16, 16, 3, accent)
        c.disc(16, 16, 1, ink); c.pixel(14, 14, shine); c.pixel(18, 18, yellow)
        c.line(10, 9, 13, 11, mid); c.line(19, 21, 22, 23, mid)
    elif "overdrive_engine" in low:
        c.ring(16, 16, 5, 3, shade); c.disc(16, 16, 2, yellow)
        for x, y in ((9, 9), (23, 9), (9, 23), (23, 23)):
            c.rect(x, y, 2, 2, cyan if x == y else magenta)
        c.pixel(16, 8, shine); c.pixel(16, 24, shine)
    elif "frozen_crown" in low:
        c.diamond(12, 15, 3, cyan); c.diamond(17, 10, 3, shine); c.diamond(22, 16, 3, cyan)
        c.pixel(12, 15, yellow); c.pixel(17, 10, yellow); c.pixel(22, 16, yellow)
        c.line(8, 24, 24, 24, shade)
    elif "prism_crystal" in low:
        c.line(16, 5, 11, 14, cyan); c.line(16, 5, 21, 14, magenta)
        c.line(11, 14, 16, 26, shine); c.line(21, 14, 16, 26, yellow)
        c.line(11, 14, 21, 14, shade); c.pixel(17, 12, shine)
    elif "singularity" in low or "event_horizon" in low or "void_orb" in low:
        c.disc(16, 16, 5, ink); c.ring(16, 16, 8, 6, shade)
        c.line(8, 12, 12, 14, cyan); c.line(20, 18, 24, 20, magenta)
        c.pixel(10, 10, yellow); c.pixel(22, 23, shine)

    # Two inset edge glints add material depth while keeping the background clear.
    c.pixel(7, 7, shine)
    c.pixel(24, 24, mid)
    apply_palette_bevel(c, palette)

def apply_palette_bevel(c: Canvas, palette) -> None:
    """Shade broad palette-color facets with one consistent top-left light source."""
    pairs = (
        ("shadow_3", "shadow_4", "shadow_2"),
        ("shadow_4", "shadow_5", "shadow_3"),
        ("shadow_5", "shadow_6", "shadow_4"),
        ("neutral_2", "neutral_1", "shadow_8"),
        ("neutral_3", "neutral_5", "shadow_1"),
        ("neutral_4", "neutral_6", "neutral_3"),
        ("cyan_2", "cyan_3", "cyan_1"),
        ("cyan_3", "cyan_4", "cyan_2"),
        ("magenta_2", "magenta_3", "magenta_1"),
        ("magenta_3", "magenta_4", "magenta_2"),
        ("yellow_2", "yellow_3", "yellow_1"),
        ("yellow_3", "yellow_4", "yellow_2"),
        ("accent_2", "accent_4", "accent_1"),
        ("accent_3", "accent_4", "accent_2"),
    )
    source = [tuple(c.data[i:i + 4]) for i in range(0, len(c.data), 4)]
    result = source.copy()
    w, h = c.width, c.height
    colors = set(source)
    counts = {color: source.count(color) for color in colors}
    variants = {}
    # Reserve room for the mandatory 16-color cap, preferring broad fill areas.
    for base, light, dark in sorted(pairs, key=lambda pair: counts.get(palette[pair[0]], 0), reverse=True):
        color, hi, lo = palette[base], palette[light], palette[dark]
        if color not in colors:
            continue
        additions = [variant for variant in (hi, lo) if variant not in colors]
        if len(colors) + len(additions) > 16:
            additions = additions[:max(0, 16 - len(colors))]
        if len(additions) == 2:
            variants[color] = (hi, lo)
        elif len(additions) == 1:
            variants[color] = (hi, color) if hi in additions else (color, lo)
        colors.update(additions)
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            i = y * w + x
            color = source[i]
            variant = variants.get(color)
            if not variant:
                continue
            left, right = source[i - 1] == color, source[i + 1] == color
            up, down = source[i - w] == color, source[i + w] == color
            if (left or up) and (right or down):
                continue
            if (right or down) and not (left or up):
                result[i] = variant[0]
            elif (left or up) and not (right or down):
                result[i] = variant[1]
    c.data[:] = bytes(channel for color in result for channel in color)

def add_ui_detail(icon: str, c: Canvas, palette) -> None:
    """Add small construction marks to 32px UI symbols without adding labels."""
    ink, shade = palette["shadow_1"], palette["shadow_4"]
    mid, shine = palette["shadow_5"], palette["neutral_1"]
    cyan, magenta = palette["cyan_4"], palette["magenta_4"]
    yellow, green = palette["yellow_4"], palette["accent_2"]
    if icon.startswith("rarity_"):
        for x, y in ((16, 3), (27, 12), (23, 25), (9, 25), (5, 12)):
            c.pixel(x, y, shine if icon.endswith(("legendary", "mythic")) else yellow)
        c.line(12, 15, 16, 11, ink); c.line(16, 11, 20, 15, ink)
        c.pixel(16, 17, shine)
    elif icon == "equipment_helmet":
        c.line(10, 8, 14, 8, mid); c.line(18, 8, 22, 8, mid)
        c.pixel(7, 11, shine); c.pixel(24, 11, yellow)
        c.line(11, 19, 20, 19, shade); c.pixel(12, 13, cyan); c.pixel(19, 13, cyan)
    elif icon == "equipment_armor":
        c.line(11, 9, 11, 20, shade); c.line(21, 9, 21, 20, shade)
        c.pixel(8, 11, shine); c.pixel(23, 11, yellow)
        c.line(13, 10, 16, 13, cyan); c.line(19, 10, 16, 13, magenta)
    elif icon == "equipment_gloves":
        for x in (10, 15, 20): c.pixel(x, 9, shine)
        c.line(10, 21, 21, 21, shade); c.pixel(9, 18, yellow); c.pixel(22, 18, cyan)
    elif icon == "equipment_boots":
        c.line(9, 13, 14, 13, shine); c.line(18, 15, 23, 15, shine)
        c.line(9, 22, 16, 22, shade); c.line(17, 22, 25, 22, shade)
        c.pixel(13, 17, yellow); c.pixel(21, 19, cyan)
    elif icon in ("equipment_amulet", "equipment_ring"):
        c.line(13, 15, 16, 12, shine); c.line(16, 12, 19, 15, cyan)
        c.pixel(16, 19, yellow); c.pixel(12, 22, magenta)
    elif icon == "resource_essence":
        for x, y in ((8, 14), (24, 14), (12, 23), (20, 23)):
            c.pixel(x, y, shine)
        c.line(11, 10, 14, 8, cyan); c.line(18, 8, 21, 10, yellow)
    elif icon == "resource_powder":
        c.pixel(8, 15, shine); c.pixel(15, 8, yellow); c.pixel(22, 13, cyan)
        c.pixel(12, 22, magenta); c.pixel(22, 23, shine)
    elif icon == "skill_node":
        c.line(7, 16, 11, 16, shine); c.line(21, 16, 25, 16, shine)
        c.line(16, 7, 16, 10, yellow); c.line(16, 22, 16, 25, cyan)
        c.pixel(11, 11, magenta); c.pixel(21, 21, magenta)
    elif icon == "achievement_medal":
        c.line(11, 22, 13, 25, cyan); c.line(21, 22, 19, 25, magenta)
        c.pixel(13, 11, shine); c.pixel(19, 11, yellow); c.pixel(16, 16, shine)
    else:  # run record
        c.rect(12, 10, 2, 2, yellow); c.rect(17, 10, 2, 2, cyan)
        c.rect(12, 15, 2, 2, magenta); c.rect(17, 15, 2, 2, shine)
        c.line(12, 22, 20, 22, shade); c.pixel(22, 5, yellow)
    apply_palette_bevel(c, palette)

def draw_catalog(name, palette):
    image = _original_draw_catalog(name, palette)
    add_catalog_detail(name, image, palette)
    return image


def draw_ui_catalog(name, palette):
    image = _original_draw_ui_catalog(name, palette)
    add_ui_detail(name, image, palette)
    apply_palette_bevel(image, palette)
    return image


def draw_signal_prism(palette):
    image = _original_draw_signal_prism(palette)
    image.line(16, 6, 12, 13, palette["cyan_4"])
    image.line(16, 6, 20, 13, palette["magenta_4"])
    image.line(7, 16, 13, 13, palette["yellow_4"])
    image.line(25, 16, 19, 13, palette["cyan_4"])
    image.pixel(11, 20, palette["neutral_1"])
    image.pixel(21, 20, palette["neutral_1"])
    apply_palette_bevel(image, palette)
    return image


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("families", nargs="*", choices=("catalog", "ui_catalog", "ui"))
    parser.add_argument("--ids", nargs="+", help="Limit to stable asset IDs from ASSET_MANIFEST.json")
    parser.add_argument("--seed", type=int, default=4801)
    parser.add_argument("--out-root", type=pathlib.Path, default=ROOT / "build/assets/candidates/catalog-icons-detail-v2")
    args = parser.parse_args()
    manifest=json.loads((ROOT / "docs/art/ASSET_MANIFEST.json").read_text())
    id_to_name={}
    for asset in manifest["assets"]:
        if asset["category"] not in {"weapon_icon", "relic_icon", "ui_icon"}:
            continue
        stem=pathlib.Path(asset["integrated_path"]).stem
        if asset["category"] == "ui_icon":
            name=stem if asset["integrated_path"].startswith("game/assets/icons/ui/") else "ui_"+stem
        else:
            name=stem
        id_to_name[asset["asset_id"]]=name
    ids=set(args.ids or id_to_name)
    unknown=ids-set(id_to_name)
    if unknown:
        parser.error(f"unknown catalog icon IDs: {sorted(unknown)}")
    base.ASSETS=args.out_root.resolve()
    base.SELECTED_IDS={id_to_name[asset_id] for asset_id in ids}
    base.GENERATION_SEED=args.seed
    base.draw_catalog=draw_catalog
    base.draw_ui_catalog=draw_ui_catalog
    base.draw_signal_prism=draw_signal_prism
    families=set(args.families or ("catalog", "ui_catalog", "ui"))
    base.generate(families,base.load_palette())
    for path in base.ASSETS.rglob("*.json"):
        if path.name == "qa-report.json":
            continue
        metadata=json.loads(path.read_text())
        if metadata.get("asset_id") not in ids:
            continue
        metadata["generator"]="game/tools/generate_catalog_icon_detail_candidates.py"
        metadata["generator_version"]="4"
        metadata["brief"]="Owner-requested detailed catalog icon pass; readable layered pixel art using only the Art Bible master palette"
        metadata["parameters"]["detail_pass"]="catalog_icon_detail_v1"
        path.write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+"\n")
    print(f"Staged {len(ids)} detailed icon candidates; active game assets were not modified")

if __name__ == "__main__":
    main()
