#!/usr/bin/env python3
"""Create local visual contact sheets and a browsable review page for staged candidates."""

import html
import json
import struct
import zlib
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build/assets/candidates/review"
import sys
sys.path.insert(0, str(ROOT / "game/tools"))
from validate_dopamine_animation_candidates import decode_png


def png(width, height, pixels):
    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xffffffff)
    raw = b"".join(b"\0" + bytes(channel for p in pixels[y*width:(y+1)*width] for channel in p)
                    for y in range(height))
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")


def sheet(title, records, target, cell=96, columns=8):
    label_h = 18
    rows = (len(records) + columns - 1) // columns
    width, height = columns*cell, rows*(cell+label_h)
    bg = (13, 15, 34, 255)
    pixels = [bg] * (width*height)
    for i, (name, path) in enumerate(records):
        w, h, src = decode_png(path)
        scale = min((cell-8)/w, (cell-8)/h)
        sw, sh = max(1, round(w*scale)), max(1, round(h*scale))
        ox = (i % columns)*cell + (cell-sw)//2
        oy = (i // columns)*(cell+label_h) + (cell-sh)//2
        for y in range(sh):
            for x in range(sw):
                p = src[min(h-1,int(y/scale))*w+min(w-1,int(x/scale))]
                if p[3]: pixels[(oy+y)*width+ox+x] = p
        # Simple dark caption strip; labels are kept in adjacent JSON for full detail.
        y0=(i//columns)*(cell+label_h)+cell
        for y in range(y0,y0+label_h):
            for x in range((i%columns)*cell,(i%columns+1)*cell): pixels[y*width+x]=(27,35,64,255)
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(png(width,height,pixels))
    return {"title":title,"path":str(target.relative_to(OUT)),"items":[{"id":n,"source":str(p.relative_to(ROOT))} for n,p in records]}


def main():
    manifest = json.loads((ROOT / "docs/art/ASSET_MANIFEST.json").read_text())
    assets = manifest["assets"]
    OUT.mkdir(parents=True, exist_ok=True)
    static_groups = {
        "Catalog icons": {"weapon_icon", "relic_icon", "ui_icon"},
        "Character sprites": {"enemy_sprite", "elite_sprite", "boss_sprite"},
        "Combat sprites": {"projectile_sprite", "impact_vfx", "impact_vfx_atlas"},
        "World art": {"environment_tile", "environment_prop", "background"},
        "Rewards": {"pickup"},
    }
    animation_groups = {
        "Characters": {"character_animation", "enemy_animation", "elite_animation", "boss_animation"},
        "Weapons": {"weapon_animation", "weapon_vfx_animation"},
        "Projectiles": {"projectile_animation"},
        "Rewards": {"relic_animation", "pickup_animation"},
    }
    sheets = []
    static_galleries = []
    for title, categories in static_groups.items():
        records = [(a, ROOT / a["integrated_path"]) for a in assets
                   if a["category"] in categories and a.get("integrated_path")]
        records = [(asset, path) for asset, path in records
                   if path.is_file() and path.suffix.lower() == ".png"]
        if records:
            slug = title.lower().replace(" ", "-")
            sheets.append(sheet(title, [(asset["asset_id"], path) for asset, path in records],
                                OUT / f"{slug}-contact-sheet.png", columns=8))
            cards = []
            for asset, path in records:
                image_url = html.escape(os.path.relpath(path, OUT))
                source_path = ROOT / str(asset.get("integrated_source_path", ""))
                source_url = html.escape(os.path.relpath(source_path, OUT)) if source_path.is_file() else ""
                params = html.escape(json.dumps(asset.get("generation_parameters", {}), ensure_ascii=False))
                source_link = f'<a href="{source_url}">editable source</a>' if source_url else "source unavailable"
                cards.append(
                    f'<article class="static-card"><a href="{image_url}"><img src="{image_url}" '
                    f'alt="{html.escape(asset["asset_id"])}"></a><h3>{html.escape(asset["asset_id"])}</h3>'
                    f'<p>{html.escape(asset["category"])} · {html.escape(asset["assigned_generation_skill"])}</p>'
                    f'<p>{source_link} · seed {html.escape(str(asset.get("generation_seed")))}</p>'
                    f'<details><summary>Generation parameters</summary><code>{params}</code></details></article>'
                )
            static_galleries.append(
                f'<section><h2>{html.escape(title)} ({len(cards)})</h2>'
                f'<p>Each preview is labeled with its stable manifest ID and links to its full-size PNG.</p>'
                f'<div class="static-grid">{"".join(cards)}</div></section>'
            )

    animations = []
    previews = []
    for title, categories in animation_groups.items():
        records = [(a["asset_id"], ROOT / a["integrated_path"]) for a in assets
                   if a["category"] in categories and a.get("integrated_path")]
        records = [(name, path) for name, path in records if path.is_file() and path.suffix.lower() == ".png"]
        if records:
            slug = title.lower()
            sheets.append(sheet(f"{title} animation sheets", records,
                                OUT / f"{slug}-animation-contact-sheet.png", columns=8))
        for asset in assets:
            if asset["category"] not in categories or not asset.get("integrated_path"):
                continue
            image_path = ROOT / asset["integrated_path"]
            metadata_path = Path(str(image_path) + ".json")
            if not image_path.is_file() or not metadata_path.is_file():
                continue
            metadata = json.loads(metadata_path.read_text())
            frame_width, frame_height = metadata["frame_size"]
            columns, rows = metadata["grid"]
            fps = float(metadata.get("fps_proposed", asset.get("generation_parameters", {}).get("fps_proposed", 8)))
            fps = max(fps, 0.1)
            scale = max(1, min(4, 512 // max(frame_width, frame_height)))
            animation_id = asset["asset_id"]
            safe_id = "".join(c if c.isalnum() or c == "_" else "_" for c in animation_id)
            image_url = html.escape(os.path.relpath(image_path, OUT))
            names = metadata.get("directions", [])
            row_cards = []
            for row in range(rows):
                label = names[row] if row < len(names) else f"row {row + 1}"
                keyframe = f"{safe_id}_row_{row}"
                row_cards.append(
                    f'<div><small>{html.escape(str(label))}</small><div class="sprite-preview" '
                    f'style="width:{frame_width*scale}px;height:{frame_height*scale}px;'
                    f'background-image:url(\'{image_url}\');background-size:{frame_width*columns*scale}px '
                    f'{frame_height*rows*scale}px;background-position-y:-{row*frame_height*scale}px;'
                    f'animation:{keyframe} {columns/fps:.4f}s steps({columns}) infinite"></div></div>'
                )
                previews.append(f'@keyframes {keyframe} {{ from {{ background-position-x:0 }} '
                                f'to {{ background-position-x:-{frame_width*columns*scale}px }} }}')
            seed = asset.get("generation_seed")
            params = html.escape(json.dumps(asset.get("generation_parameters", {}), ensure_ascii=False))
            source_path = ROOT / str(asset.get("integrated_source_path", ""))
            source = html.escape(os.path.relpath(source_path, OUT)) if source_path.is_file() else "missing"
            skill = html.escape(str(asset.get("assigned_generation_skill", "")))
            generator = html.escape(str(metadata.get("generator", asset.get("authoring_source_or_recipe", ""))))
            qa = html.escape(str(asset.get("validation_status", "missing")))
            animations.append(
                f'<article class="animation-card"><h3>{html.escape(animation_id)}</h3>'
                f'<div class="rows">{"".join(row_cards)}</div>'
                f'<details><summary>{skill} · seed {html.escape(str(seed))} · QA {qa}</summary>'
                f'<p>Generator: {generator}</p><p>Source: <a href="{source}">{source}</a></p>'
                f'<code>{params}</code></details></article>'
            )

    audio_assets = [a for a in assets if a["category"] in {"sound_effect", "music", "music_stem"}]
    font_assets = [a for a in assets if a["category"] == "font" and a.get("integrated_path")]
    inventory = {"count": len(audio_assets), "files": []}
    audio_html = []
    for asset in audio_assets:
        path = ROOT / asset.get("integrated_path", "")
        if not path.is_file():
            continue
        duration = None
        channels = rate = None
        try:
            import wave
            with wave.open(str(path)) as wav:
                duration = round(wav.getnframes() / wav.getframerate(), 3)
                channels, rate = wav.getnchannels(), wav.getframerate()
        except (wave.Error, OSError):
            pass
        record = {
            "id": asset["asset_id"], "category": asset["category"],
            "path": str(path.relative_to(ROOT)), "source": asset.get("integrated_source_path"),
            "skill": asset.get("assigned_generation_skill"),
            "generator_or_recipe": asset.get("authoring_source_or_recipe"),
            "seed": asset.get("generation_seed"), "parameters": asset.get("generation_parameters"),
            "validation_status": asset.get("validation_status"),
            "duration_seconds": duration, "channels": channels, "sample_rate": rate,
        }
        inventory["files"].append(record)
        audio_html.append(
            f'<li><b>{html.escape(asset["asset_id"])}</b> · {html.escape(asset["category"])} · '
            f'{duration if duration is not None else "unknown"} s '
            f'<audio controls preload="none" src="{html.escape(os.path.relpath(path, OUT))}"></audio></li>'
        )
    assert len(animations) == sum(a["category"] in set().union(*animation_groups.values()) for a in assets)
    assert len(inventory["files"]) == len(audio_assets)
    (OUT / "audio-inventory.json").write_text(json.dumps(inventory, ensure_ascii=False, indent=2) + "\n")
    (OUT / "contact-sheets.json").write_text(json.dumps(sheets, ensure_ascii=False, indent=2) + "\n")
    sheet_html = "".join(
        f'<section><h2>{html.escape(item["title"])}</h2><p>{len(item["items"])} assets · '
        f'<a href="{html.escape(item["path"])}">Contact sheet PNG</a></p>'
        f'<img src="{html.escape(item["path"])}"></section>' for item in sheets
    )
    font_samples = []
    for asset in font_assets:
        path = ROOT / asset["integrated_path"]
        if not path.is_file():
            continue
        family = html.escape(asset["asset_id"])
        url = html.escape(os.path.relpath(path, OUT))
        font_samples.append("<style>@font-face{font-family:%s;src:url('%s')}</style>" % (family, url))
        font_samples.append('<p style="font-family:%s;font-size:28px">%s · NEON SURVIVOR 0123456789</p>' %
                            (family, family))
    page = (
        '<!doctype html><meta charset="utf-8"><title>Dopamine asset review</title>'
        '<style>body{font:16px system-ui;background:#080b18;color:#eee;margin:2rem}'
        'section,.animation-card,.static-card{background:#10152b;padding:1rem;margin:1rem 0;border:1px solid #293354}'
        'img{max-width:100%;image-rendering:pixelated}.static-grid{display:grid;'
        'grid-template-columns:repeat(auto-fill,minmax(170px,1fr));gap:.75rem}.static-card{margin:0;'
        'overflow-wrap:anywhere}.static-card img{width:100%;height:150px;object-fit:contain;background:#080b18}'
        '.static-card h3{font-size:1rem;margin:.45rem 0}.static-card p{font-size:.82rem;margin:.3rem 0}'
        '.rows{display:flex;gap:2rem;flex-wrap:wrap;align-items:center}'
        '.sprite-preview{image-rendering:pixelated;background-repeat:no-repeat}.animation-grid{display:grid;'
        'grid-template-columns:repeat(auto-fill,minmax(340px,1fr));gap:1rem}code{white-space:pre-wrap;overflow-wrap:anywhere}'
        'audio{vertical-align:middle}li{padding:.45rem}</style>'
        '<h1>Dopamine Survivor · integrated local asset library</h1>'
        f'<p><strong>Provisional production batch.</strong> Technical QA status is not artistic approval. '
        'The approved scope permits provisional hero/world/boss concepts; unresolved canon and all owner '
        'visual/audio acceptance remain pending. Use each manifest ID when reporting a correction.</p>'
        f'<p>Manifest assets: {len(assets)} · animation previews: {len(animations)} · '
        f'audio players: {len(inventory["files"])}. Technical QA status is shown per asset; '
        'visual/audio owner review remains pending where marked.</p>'
        + sheet_html + "".join(static_galleries) + '<section><h2>All animation previews</h2><div class="animation-grid">'
        + "".join(animations) + '</div></section>'
        + '<section><h2>Font previews</h2>'
        + "".join(font_samples) + '</section>'
        + f'<section><h2>Audio inventory ({len(inventory["files"])})</h2><ul>{"".join(audio_html)}</ul></section>'
        + '<style>' + "".join(previews) + '</style>'
    )
    (OUT / "index.html").write_text(page)
    print(f"Wrote {len(sheets)} contact sheets, {len(animations)} animated previews and "
          f"{len(inventory['files'])} integrated audio entries to {OUT}")


if __name__ == "__main__":
    main()
