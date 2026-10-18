---
name: dopamine-sfx
description: Compose and regenerate original 8-bit and synthwave sound effects locally for Dopamine Survivor, with deterministic recipes, metadata, numerical QA, and Godot import support.
---

# Dopamine SFX

Use Python standard library synthesis and local project tools. No paid API, cloud generation, sample library, or remote MCP. The repository's `.agents/skills/procedural-sfx` may be consulted for synthesis/mix design, but its NumPy/SciPy dependencies are optional and must not become required for the project pipeline.

## Workflow

1. Read the GDD audio feedback requirements and inspect existing event IDs/consumers in `game/scripts/sfx_service.gd`.
2. Define each cue by event role, duration, frequency envelope, waveform/noise layers, filter/timbre, amplitude envelope, variation bounds, and stable seed. 8-bit cues may use pulse, triangle, square, noise and stepped pitch; synthwave cues may use detuned oscillators, sweeps, filtered noise and short modulation.
3. Use a stable seed derived from the asset ID by default. Accept explicit seed/parameters and regenerate only selected IDs.
4. Save source recipe, WAV, JSON metadata and hashes. Keep output candidates staged until QA passes and they are explicitly accepted for runtime use.
5. Run `dopamine-asset-qa` for sample rate, channels, PCM encoding, duration, finite samples, clipping, peak/RMS, hash and manifest integrity. Listen to representative cues in context before declaring them artistically accepted.
6. Integrate accepted files in Godot and update event mappings only when required; keep Sandbox and normal progression strictly isolated as required by project architecture.

Numerical QA does not replace listening. Keep GDD/Art Bible proposals marked as proposed until confirmed.
