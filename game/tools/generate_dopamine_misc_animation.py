#!/usr/bin/env python3
"""Make deterministic role-based animation candidates from staged pixel-art sources."""

import argparse
import hashlib
import json
import math
import re
import struct
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "game/tools"))
from generate_neon_arcade_art import Canvas, aseprite_bytes, draw_catalog, draw_impact, draw_projectile, load_palette


def png_bytes(width, height, pixels):
    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xffffffff)
    raw = b"".join(b"\0" + bytes(channel for p in pixels[y*width:(y+1)*width] for channel in p)
                    for y in range(height))
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")


def get_pixels(canvas):
    return [tuple(canvas.data[i:i+4]) for i in range(0, len(canvas.data), 4)]


def animate(base, w, h, effect, frame):
    out = [(0,0,0,0)] * (w*h)
    dx = (0, -1, 0, 1)[frame]
    for y in range(h):
        for x in range(w):
            p = base[y*w+x]
            if p[3] == 0: continue
            nx, ny = x, y
            if effect in ("pulse", "weapon"):
                scale = (0.90, 1.0, 1.12, 1.0)[frame]
                nx = round((x-(w-1)/2)*scale+(w-1)/2)
                ny = round((y-(h-1)/2)*scale+(h-1)/2)
            elif effect == "orbit":
                nx = round((x-(w-1)/2)*math.cos(frame*math.pi/2)-(y-(h-1)/2)*math.sin(frame*math.pi/2)+(w-1)/2)
                ny = round((x-(w-1)/2)*math.sin(frame*math.pi/2)+(y-(h-1)/2)*math.cos(frame*math.pi/2)+(h-1)/2)
            elif effect == "reveal":
                if frame < 3 and (x+y+frame*3) % 4 != 0: continue
                ny += (3-frame) * 2
            elif effect == "burst":
                scale = (0.5, 0.85, 1.15, 1.35)[frame]
                nx = round((x-(w-1)/2)*scale+(w-1)/2)
                ny = round((y-(h-1)/2)*scale+(h-1)/2)
            else:
                ny += dx
            if 0 <= nx < w and 0 <= ny < h:
                out[ny*w+nx] = p
    # Small palette-derived pulse guarantees useful frame changes even for a symmetric static source.
    visible = [p for p in base if p[3]]
    accent = max(visible, key=lambda p: (p[0] + p[1] + p[2], p)) if visible else (255,255,255,255)
    cx, cy = w//2, h//2
    marker = ((cx-2, cy), (cx, cy-2), (cx+2, cy), (cx, cy+2))[frame]
    mx, my = marker
    if 0 <= mx < w and 0 <= my < h:
        out[my*w+mx] = accent
    for j in range(frame + 1):
        out[((my+3+j*2) % h)*w + ((mx+5+j*3) % w)] = accent
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--manifest", type=Path, default=ROOT/"docs/art/ASSET_MANIFEST.json")
    p.add_argument("--static-root", type=Path, default=ROOT/"build/assets/candidates/pixel-art-complete")
    p.add_argument("--out-root", type=Path, default=ROOT/"build/assets/candidates/misc-animation")
    p.add_argument("--ids", nargs="+")
    p.add_argument("--seed", type=int, default=20261018)
    args = p.parse_args()
    records=json.loads(args.manifest.read_text())["assets"]
    wanted=set(args.ids or [])
    palettes=load_palette()
    output=[]
    for item in records:
        aid=item["asset_id"]
        if item["assigned_generation_skill"] != "dopamine-animation" or item["generation_status"] != "not_generated": continue
        if wanted and aid not in wanted: continue
        cat=item["category"]
        base_id, effect = None, "pulse"
        if cat == "boss_animation":
            role="boss_pulse_warden" if "warden" in aid else "boss_dopamine_core"
            base_id, effect = role, "burst" if "special" in aid else "pulse"
        elif cat == "elite_animation": base_id, effect = "elite_sprinter", "pulse"
        elif cat == "weapon_animation":
            name=aid.removesuffix("_attack")
            aliases={"infinite_circuit":"lightning_conductor","wildfire":"inferno_sprayer","bloodstorm":"crimson_daggers","redline":"minigun","pandemic":"toxic_cloud","razorstorm":"sawblades","starfall":"meteor_staff","spectrum_collapse":"prism_laser","event_horizon":"void_orb","absolute_zero":"frost_nova"}
            base_id=next((f"weapon_{base}" for evo,base in aliases.items() if name.endswith(evo)),name)
            effect = "weapon"
        elif cat == "weapon_vfx_animation":
            weapon=aid.removeprefix("weapon_").removesuffix("_fire_vfx").removesuffix("_impact_vfx")
            kind="impact" if "impact" in aid else "fire"
            base_id=f"weapon_{weapon}_{'impact' if kind=='impact' else 'fire'}_vfx"
            # VFX icon prototype sourced from its weapon projectile or impact primitive.
            effect="burst" if kind=="impact" else "burst"
        elif cat == "projectile_animation":
            name=aid.removesuffix("_animation")
            base_id, effect=name, "orbit"
        elif cat == "relic_animation":
            base_id=aid.removesuffix("_acquisition")+"_icon"
            effect="reveal"
        elif cat == "pickup_animation":
            base_id=aid
            effect="reveal"
        else: continue
        w=h=32
        if cat in ("boss_animation", "elite_animation"): w=h=32
        if cat == "pickup_animation":
            reward_id="chest_closed" if base_id=="chest_open" else "xp_orb" if base_id=="xp_orb_collect" else base_id
            src=ROOT/"build/assets/candidates/rewards/sprites/rewards"/(reward_id+".png")
        elif cat == "weapon_vfx_animation":
            key="impact_spark" if "impact" in aid else "projectile_"+weapon.replace("_conductor", "")
            candidates=[args.static_root/"sprites/vfx"/(key+".png"), args.static_root/"sprites/projectiles"/(key+".png")]
            src=next((c for c in candidates if c.exists()), candidates[0])
        elif cat == "projectile_animation": src=args.static_root/"sprites/projectiles"/(base_id+".png")
        elif cat == "relic_animation": src=args.static_root/"sprites/catalog"/(base_id.removesuffix("_icon")+".png")
        elif cat == "weapon_animation": src=args.static_root/"sprites/catalog"/(base_id+".png")
        else: src=args.static_root/"sprites/roster"/(base_id+".png")
        # Roster sprite candidates are in the roles directory in staged static art.
        if not src.exists() and cat in ("boss_animation", "elite_animation"):
            src=args.static_root/"sprites/roster"/(base_id+".png")
        # Most static aliases differ; choose candidate by filename search, never silently invent a fallback.
        if not src.exists():
            matches=list(args.static_root.rglob(base_id+".png"))
            if not matches and cat=="weapon_vfx_animation": matches=list(args.static_root.rglob(("impact_spark" if "impact" in aid else "projectile_lightning")+".png"))
            if not matches and cat=="pickup_animation": matches=list((ROOT/"build/assets/candidates/rewards").rglob(base_id+".png"))
            if not matches: raise FileNotFoundError(f"no static visual source for {aid}: {src}")
            src=matches[0]
        # Read through the shared pixel-art decoder to normalize indexed/RGBA sources.
        from validate_dopamine_animation_candidates import decode_png
        sw,sh,pixels=decode_png(src)
        # Fit a centered square cel into the stable 32x32 frame while retaining the source silhouette.
        scale=min(32/sw,32/sh)
        nw,nh=max(1,round(sw*scale)),max(1,round(sh*scale))
        rgba=[(0,0,0,0)]*1024
        for y in range(nh):
            for x in range(nw): rgba[(y+(32-nh)//2)*32+x+(32-nw)//2]=pixels[min(sh-1,int(y/scale))*sw+min(sw-1,int(x/scale))]
        frames=[]
        for f in range(4):
            frame=animate(rgba,32,32,effect,f)
            if not any(q[3] for q in frame): frame=rgba[:]
            frames.extend(frame)
        sheet=Canvas(128,32); sheet.data[:]=bytes(c for q in frames for c in q)
        out_png=args.out_root/"sprites/animation"/(aid+".png")
        out_src=args.out_root/"source/animation"/(aid+".aseprite")
        out_png.parent.mkdir(parents=True,exist_ok=True); out_src.parent.mkdir(parents=True,exist_ok=True)
        png=png_bytes(128,32,frames); ase=aseprite_bytes(sheet,aid)
        out_png.write_bytes(png); out_src.write_bytes(ase)
        meta={"asset_id":aid,"status":"candidate_not_approved","skill":"dopamine-animation","generator":"game/tools/generate_dopamine_misc_animation.py","generator_version":"1","seed":args.seed,"seed_policy":"fixed geometry and staged source; seed recorded but not consumed","identity_source":str(src.relative_to(ROOT)),"frame_size":[32,32],"grid":[4,1],"directions":["forward"],"fps_proposed":12 if "vfx" in cat or cat in ("projectile_animation","pickup_animation") else 8,"frame_duration_seconds_proposed":1/12 if "vfx" in cat or cat in ("projectile_animation","pickup_animation") else 1/8,"pivot":[16,16],"parameters":{"effect":effect,"category":cat,"source_path":str(src.relative_to(ROOT))},"source_path":str(out_src.relative_to(args.out_root)),"export_path":str(out_png.relative_to(args.out_root)),"source_sha256":hashlib.sha256(ase).hexdigest(),"export_sha256":hashlib.sha256(png).hexdigest()}
        out_png.with_suffix(".json").write_text(json.dumps(meta,indent=2)+"\n")
        output.append(aid)
    print(json.dumps({"generated":output,"count":len(output)},indent=2))

if __name__=="__main__": main()
