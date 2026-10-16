# Dopamine Survivor procedural SFX

This is a standalone, listenable first-pass sound library in the **Neon Arcade** direction. It contains 38 deterministic 44.1 kHz mono PCM16 WAVs, editable Bfxr parameter recipes, a machine-readable manifest, and an HTML audition gallery. No existing audio was replaced, and these sounds are not wired into gameplay yet.

Open [`preview.html`](preview.html) in a browser to audition and compare the effects. The browser can play the WAV files directly; no package installation is needed for listening.

## Contents

- `*.wav` — rendered effects
- [`recipes.json`](recipes.json) — source parameters, event names, variation families, and role loudness targets
- [`manifest.json`](manifest.json) — file list, editable parameters, durations, measured RMS and peak levels, and proposed mixing guidance
- [`preview.html`](preview.html) — grouped HTML audio players for every take
- [`build_sfx_library.py`](../../../tools/build_sfx_library.py) and [`render_bfxr2.js`](../../../tools/render_bfxr2.js) — deterministic renderer and role-based RMS normalizer

Frequent combat and progression events have 3–4 takes. Each family has different pitch/envelope settings; variants are selected explicitly, rather than relying on unseeded random output. Recipe roles set distinct loudness targets so repeated light sounds remain quieter than major rewards and boss cues. The renderer caps sample peaks at −3 dBFS, applies a 6 ms end fade, and does not compress.

## Edit and rerender

The build script uses Node.js and Python's standard library. To regenerate, install the upstream CLI in a separate checkout (the renderer was evaluated with MIT-licensed [`osiriswd/bfxr2-cli`](https://github.com/osiriswd/bfxr2-cli), source commit `73cfde24a3c25c84a3f3c141e7f2a4b3d80c6b64`):

```sh
git clone https://github.com/osiriswd/bfxr2-cli.git /path/to/bfxr2-cli
cd /path/to/bfxr2-cli && npm install
cd /path/to/dopamine
BFXR2_CLI=/path/to/bfxr2-cli/cli.js python3 game/tools/build_sfx_library.py
```

Change a sound's `params` or `target_rms_dbfs` in `recipes.json`. The renderer uses the Bfxr2 engine with a seeded random source. (The upstream CLI's `--seed` option does not seed its `--params-file` path, so `game/tools/render_bfxr2.js` wraps the engine and supplies deterministic randomness.) The seed is derived from the recipe's position in the file, so the same recipe list and source checkout reproduce the same WAV bytes. The default build refuses to replace any output. After editing recipes, pass `--replace` to update only the named library WAVs, manifest, and gallery:

```sh
BFXR2_CLI=/path/to/bfxr2-cli/cli.js python3 game/tools/build_sfx_library.py --replace
```

Keep recipe ordering stable if exact seed-to-file mapping matters. The generator uses explicit Bfxr parameter files; it does not use randomize or mutate mode.

## Bfxr2 evaluation and limits

The Bfxr2 engine successfully rendered all 38 sounds from parameter files in a few seconds. Its strengths here are compact recipes and a retro game tone. The upstream CLI has a seed-handling bug in parameter-file mode; the included wrapper supplies seeded randomness so outputs remain stable. Bfxr's parameterized synth is intentionally stylized; it offers less direct control over independent attack/body/tail layers, precise filter response, and stereo placement than a lower-level DSP recipe. This first pass therefore uses conservative low-pass settings and short effects. The gallery is the listening review: ear-tuning and in-game mix validation are still needed.

## Mix guidance

The [manifest](manifest.json) marks concurrency guidance **PROPOSÉ** pending in-game tuning. In dense combat, choose one variation per event and coalesce or drop repeated weapon, light hit, kill, and XP voices. Preserve priority for boss telegraphs and major UI/reward cues. Avoid triggering every projectile sound when many attacks overlap.
