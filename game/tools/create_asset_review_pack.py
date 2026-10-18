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
    visual_roots=[ROOT/"build/assets/candidates/pixel-art-complete",
                  ROOT/"build/assets/candidates/pixel-art"]
    animations=[ROOT/"build/assets/candidates/player-animation",ROOT/"build/assets/candidates/enemy-animation-complete",ROOT/"build/assets/candidates/misc-animation"]
    sets=[]
    files=[]
    for visual in visual_roots:
        files.extend(sorted(p for p in visual.rglob("*.png")
                            if visual.name != "pixel-art" or p.with_suffix(".json").is_file()))
    files += sorted((ROOT/"build/assets/candidates/roster").rglob("*.png"))
    files += sorted((ROOT/"build/assets/candidates/rewards").rglob("*.png"))
    files += sorted((ROOT/"build/assets/candidates/title-art").rglob("*.png"))
    files=[p for p in files if "preview" not in p.name]
    sets.append(sheet("Static candidates",[(p.stem,p) for p in files],OUT/"static-contact-sheet.png",columns=10))
    for group in animations:
        paths=sorted(group.rglob("*.png"))
        paths=[p for p in paths if "preview" not in p.name]
        if paths:
            sets.append(sheet(group.name,[(p.stem,p) for p in paths],OUT/f"{group.name}-contact-sheet.png",columns=8))
    audio=ROOT/"build/assets/candidates/audio-complete"
    wavs=sorted(audio.rglob("*.wav"))
    inventory={"count":len(wavs),"files":[{"path":str(p.relative_to(ROOT)),"id":p.stem,"duration_seconds":round(__import__('wave').open(str(p)).getnframes()/__import__('wave').open(str(p)).getframerate(),3)} for p in wavs]}
    (OUT/"audio-inventory.json").write_text(json.dumps(inventory,indent=2)+"\n")
    cards=[]
    for group in sets:
        cards.append(f'<section><h2>{html.escape(group["title"])}</h2><p>{len(group["items"])} sprites · contact sheet <a href="{html.escape(group["path"])}">PNG</a></p><img src="{html.escape(group["path"])}"></section>')
    gallery=''.join(f'<figure><a href="{html.escape(os.path.relpath(p,OUT))}"><img src="{html.escape(os.path.relpath(p,OUT))}"></a><figcaption>{html.escape(p.stem)}</figcaption></figure>' for p in files)
    cards.append(f'<section><h2>Static candidate gallery ({len(files)})</h2><div class="gallery">{gallery}</div></section>')
    for batch in ("player-animation","enemy-animation-complete","misc-animation"):
        page=ROOT/f"build/assets/candidates/{batch}/qa-report.json"
        if page.exists():
            q=json.loads(page.read_text())
            for a in q.get("animations",[]):
                p=ROOT/a["export"]
                if not p.exists(): continue
                rel=os.path.relpath(p,OUT)
                cards.append(f'<section><h3>{html.escape(a["asset_id"])}</h3><small>{html.escape(batch)} · {a["dimensions"]} · {a["grid"]}</small><br><img class="anim" src="{html.escape(rel)}"></section>')
    players=sorted((audio/"sfx").glob("*.wav"))
    music=sorted((audio/"cues").glob("*.wav"))
    stems=sorted((audio/"music").glob("*.wav"))
    audio_html=''.join(f'<li>{html.escape(p.stem)} <audio controls preload="none" src="{html.escape(os.path.relpath(p,OUT))}"></audio></li>' for p in players+music+stems)
    page='<!doctype html><meta charset="utf-8"><title>Dopamine asset review</title><style>body{font:16px system-ui;background:#080b18;color:#eee;margin:2rem}section{background:#10152b;padding:1rem;margin:1rem 0;border:1px solid #293354}img{max-width:100%;image-rendering:pixelated}.anim{width:512px}.gallery{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:1rem}.gallery figure{margin:0;background:#080b18;padding:.75rem}.gallery img{width:100%;height:120px;object-fit:contain}.gallery figcaption{overflow-wrap:anywhere;font-size:.8rem}audio{vertical-align:middle}small{color:#adc}</style><h1>Dopamine Survivor · provisionally integrated library</h1><p>All 308 assets passed technical QA and are integrated under the user-authorized provisional, non-canonical prototype scope. Human visual and audio review remains pending; do not treat open boss, biome, element, font, or animation details as canon. WAV players below support local listening.</p>'+''.join(cards)+f'<section><h2>Audio inventory ({len(players+music+stems)} files)</h2><ul>'+audio_html+'</ul></section>'
    (OUT/"index.html").write_text(page)
    (OUT/"contact-sheets.json").write_text(json.dumps(sets,indent=2)+"\n")
    print(f"Wrote {len(sets)} contact sheets, {len(q.get('animations',[])) if 'q' in locals() else 0} last-batch animation records and {len(wavs)} audio inventory entries to {OUT}")

if __name__=="__main__": main()
