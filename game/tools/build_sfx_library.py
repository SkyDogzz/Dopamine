#!/usr/bin/env python3
"""Render Dopamine Survivor's recipe-driven WAV library with bfxr2-cli."""

from __future__ import annotations

import argparse
import json
import math
import os
import shutil
import struct
import subprocess
import sys
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIBRARY = ROOT / "assets/audio/sfx"
RECIPE_FILE = LIBRARY / "recipes.json"
SAMPLE_RATE = 44100
PEAK_LIMIT = 10 ** (-3 / 20)


def db(value: float) -> float:
    return 20 * math.log10(max(value, 1e-12))


def read_samples(path: Path) -> tuple[wave._wave_params, list[int]]:
    with wave.open(str(path), "rb") as wav:
        params = wav.getparams()
        if params.nchannels != 1 or params.sampwidth != 2 or params.framerate != SAMPLE_RATE:
            raise ValueError(f"Expected 44.1 kHz mono PCM16: {path}")
        raw = wav.readframes(params.nframes)
    return params, list(struct.unpack("<" + "h" * (len(raw) // 2), raw))


def write_samples(path: Path, params: wave._wave_params, samples: list[int]) -> None:
    with wave.open(str(path), "wb") as wav:
        wav.setparams(params)
        wav.writeframes(struct.pack("<" + "h" * len(samples), *samples))


def normalize(path: Path, target_dbfs: float) -> dict:
    params, original = read_samples(path)
    floats = [sample / 32768 for sample in original]
    rms = math.sqrt(sum(sample * sample for sample in floats) / len(floats))
    peak = max(map(abs, floats), default=0)
    if rms < 1e-7 or peak < 1e-7:
        raise ValueError(f"Silent or near-silent render: {path}")

    requested = 10 ** (target_dbfs / 20) / rms
    gain = min(requested, PEAK_LIMIT / peak)
    # Fade the very end to avoid a hard stop; Bfxr's envelope remains the sound's main shape.
    fade = min(round(SAMPLE_RATE * 0.006), len(floats))
    for index in range(fade):
        floats[-fade + index] *= (fade - index - 1) / max(fade, 1)
    output = [max(-32768, min(32767, round(sample * gain * 32767))) for sample in floats]
    write_samples(path, params, output)
    measured = [sample / 32768 for sample in output]
    out_rms = math.sqrt(sum(sample * sample for sample in measured) / len(measured))
    out_peak = max(map(abs, measured), default=0)
    return {
        "duration_seconds": round(len(output) / SAMPLE_RATE, 3),
        "rms_dbfs": round(db(out_rms), 2),
        "peak_dbfs": round(db(out_peak), 2),
        "crest_factor_db": round(db(out_peak / max(out_rms, 1e-12)), 2),
    }


def find_cli() -> Path:
    configured = os.environ.get("BFXR2_CLI")
    if configured:
        path = Path(configured).expanduser().resolve()
        if not path.is_file():
            raise SystemExit(f"BFXR2_CLI does not point to a file: {path}")
        return path
    command = shutil.which("bfxr2-cli")
    if command:
        return Path(command)
    raise SystemExit(
        "bfxr2-cli was not found. Clone https://github.com/osiriswd/bfxr2-cli, "
        "run npm install there, then set BFXR2_CLI=/path/to/cli.js."
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--replace", action="store_true", help="replace WAVs and generated manifest/gallery in this library")
    args = parser.parse_args()
    cli = find_cli()
    library = json.loads(RECIPE_FILE.read_text(encoding="utf-8"))
    recipes = library["recipes"]
    expected = {f"{recipe['id']}.wav" for recipe in recipes}
    expected |= {"manifest.json", "preview.html"}
    collisions = sorted(name for name in expected if (LIBRARY / name).exists())
    if collisions and not args.replace:
        raise SystemExit("Refusing to overwrite existing files: " + ", ".join(collisions) + ". Use --replace for this generated library only.")

    LIBRARY.mkdir(parents=True, exist_ok=True)
    manifest = {
        "title": "Dopamine Survivor — Neon Arcade SFX",
        "version": 1,
        "format": "44.1 kHz, mono, PCM16 WAV",
        "renderer": "bfxr2-cli (Bfxr synth), deterministic explicit parameter recipes and seeds",
        "normalization": "Role-specific RMS target; sample peak capped at -3 dBFS; 6 ms end fade; no compression.",
        "mixing_guidance": {
            "repeated_events": "Randomly select among numbered variants; avoid firing every voice for every projectile when multiple attacks overlap.",
            "concurrency": "Coalesce or drop low-priority repeated hit, kill, XP, and weapon voices under dense combat. Keep boss telegraphs and player-facing UI/reward cues audible.",
            "priority_order": ["boss telegraph", "UI / major reward", "heavy impact", "weapon", "light hit / kill / XP"],
            "recommendation_status": "PROPOSÉ — integration and in-game tuning remain open."
        },
        "sounds": []
    }

    for index, recipe in enumerate(recipes):
        output = LIBRARY / f"{recipe['id']}.wav"
        params_file = LIBRARY / f".{recipe['id']}.params.tmp.json"
        params_file.write_text(json.dumps(recipe["params"], separators=(",", ":")), encoding="utf-8")
        try:
            subprocess.run([
                "node", str(ROOT / "tools/render_bfxr2.js"), "--bfxr2-root", str(cli.parent),
                "--params-file", str(params_file), "--output", str(output),
                "--sample-rate", str(SAMPLE_RATE), "--bit-depth", "16", "--seed", str(20261016 + index)
            ], check=True, stdout=subprocess.DEVNULL)
        finally:
            params_file.unlink(missing_ok=True)
        metrics = normalize(output, recipe["target_rms_dbfs"])
        manifest["sounds"].append({
            "id": recipe["id"], "event": recipe["event"], "family": recipe["family"],
            "role": recipe["role"], "file": output.name, "recipe": recipe["params"],
            "target_rms_dbfs": recipe["target_rms_dbfs"], **metrics
        })
        print(f"{recipe['id']}: {metrics['duration_seconds']:.3f}s, RMS {metrics['rms_dbfs']:.2f} dBFS, peak {metrics['peak_dbfs']:.2f} dBFS")

    (LIBRARY / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    write_gallery(manifest)
    print(f"Rendered {len(recipes)} sounds to {LIBRARY}")


def write_gallery(manifest: dict) -> None:
    rows = []
    groups = {}
    for sound in manifest["sounds"]:
        groups.setdefault(sound["family"], []).append(sound)
    for family, sounds in groups.items():
        rows.append(f'<section><h2>{sounds[0]["event"]} <small>{len(sounds)} take{"s" if len(sounds) != 1 else ""}</small></h2><div class="grid">')
        for sound in sounds:
            rows.append(
                f'<article><b>{sound["id"]}</b><audio controls preload="none" src="{sound["file"]}"></audio>'
                f'<small>{sound["duration_seconds"]:.2f}s · RMS {sound["rms_dbfs"]:.1f} dBFS · peak {sound["peak_dbfs"]:.1f} dBFS</small></article>'
            )
        rows.append("</div></section>")
    html = """<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Dopamine Survivor — SFX Library</title><style>
:root{color-scheme:dark;--bg:#080b18;--panel:#10152b;--line:#293354;--cyan:#37e8f5;--pink:#ff75e3;--text:#f6f7ff;--muted:#a5aec3}
*{box-sizing:border-box}body{margin:0;background:radial-gradient(ellipse at top,#1b2340,var(--bg) 55%);color:var(--text);font:16px/1.5 system-ui,sans-serif;padding:32px;max-width:1200px;margin:auto}
h1{font-size:clamp(1.8rem,4vw,3rem);margin:0;color:var(--cyan);letter-spacing:.03em}header{border-bottom:1px solid var(--line);padding-bottom:22px;margin-bottom:26px}header p,.note{color:var(--muted)}section{margin:26px 0}h2{font-size:1.15rem;color:var(--pink);margin:0 0 12px}h2 small{color:var(--muted);font-weight:400}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:10px}article{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:12px}article b{display:block;font-size:.9rem}audio{display:block;width:100%;height:34px;margin:8px 0}article small{display:block;color:var(--muted);font-variant-numeric:tabular-nums}.note{padding:12px;background:#10152b;border-left:3px solid var(--cyan);font-size:.9rem}
</style></head><body><header><h1>DOPAMINE SURVIVOR</h1><p>Procedural Neon Arcade SFX · listen, compare takes, and audition in context.</p><p class="note">All controls start paused. Use one player at a time for fair comparison. In dense combat, coalesce or drop repeated weapon, hit, kill and XP sounds so boss telegraphs and reward cues stay clear.</p></header>
""" + "\n".join(rows) + "\n</body></html>\n"
    (LIBRARY / "preview.html").write_text(html, encoding="utf-8")


if __name__ == "__main__":
    main()
