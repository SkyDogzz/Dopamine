---
name: dopamine-music
description: Generate deterministic, loopable local synthwave/EDM music for Dopamine Survivor, retaining stems, source parameters, seeds, metadata and Godot integration details.
---

# Dopamine Music

Generate all music locally with Python standard library synthesis or installed local CLI tools. Never use paid APIs, cloud music generation, or remote MCPs.

## Workflow

- Read the GDD's adaptive EDM/synthwave requirement and `game/scripts/adaptive_survival_music.gd` before changing runtime behavior.
- Prefer synchronized stems rendered from one tempo, meter, bar count and sample timeline so Godot can change intensity without restarting the loop.
- Save deterministic source code/recipe, per-stem parameters, seed, tempo, meter, bars, loop points, sample rate, format, mix gains, hashes and QA report.
- Make loop boundaries continuous and stems equal in length; provide a preview mix without discarding stems.
- Regenerate only requested stems/assets. Keep candidates separate until technical QA and user listening acceptance.
- Run `dopamine-asset-qa`; check duration, sample format, clipping, equal lengths, loop-boundary discontinuity and manifest hashes. Then verify import/playback in Godot and review transitions in context.

Existing timing, key, gains and intensity behavior marked `[PROPOSÉ]` remain proposals until approved. Keep Sandbox audio and normal progression isolated.
