---
name: dopamine-pixel-art
description: Generate original Dopamine Survivor pixel art locally and deterministically, following docs/ART_BIBLE.txt, preserving editable sources and per-asset metadata. Use when creating or regenerating sprites, tiles, icons, backgrounds, or VFX.
---

# Dopamine Pixel Art

Work only with local scripts and data. Never call cloud image generation, paid APIs, or external MCP generation services.

## Before generating

1. Read `docs/ART_BIBLE.txt`, `docs/art/INVENTAIRE_ASSETS_UI.md`, and the asset pipeline spec.
2. Keep `[VALIDÉ]`, `[PROPOSÉ]`, and `[À CONFIRMER]` distinct. Do not invent canon for open character outfits, bosses, biomes, elements, or sheet ordering.
3. Read `docs/art/palette_master.gpl`; do not hardcode a competing palette. Use the 32-color master palette and no more than 16 colors per 32x32 sprite. Pixel art is strict, top-down, nearest-neighbor; glow belongs in runtime VFX, not source pixels.
4. Preserve existing files. Generate only the requested asset IDs to a staging directory first.

## Generate and hand off

- Prefer existing project generators in `game/tools/` and extend them with explicit asset selection and seed parameters where needed.
- Keep a human-editable `.aseprite` source, PNG export, and JSON metadata recording stable ID, prompt/brief, dimensions, palette colors, seed, generator/version, source/export paths and hashes.
- Use a stable seed per asset ID unless the user asks for variation. Regeneration must touch only selected IDs.
- Run `dopamine-asset-qa` before import. A passing technical report is not artistic approval; show a contact sheet or preview for review.
- Integrate only accepted assets, update Godot references deliberately, then record the migration/provenance.

## Open sprite-sheet conventions

The Art Bible confirms player 32x32 frames, four directions, four walk and four idle frames, but leaves row order, pivots and timing open. Preserve the existing 4x4 layout for compatible player assets and report assumptions. Ask for a decision only when a new asset depends on an unresolved convention.

## Local project interface

For the procedural static library, run `python3 game/tools/generate_neon_arcade_art.py <families> --ids <asset_id...> --seed <integer> --out-root build/assets/candidates/pixel-art`. Families are `catalog`, `projectiles`, `vfx`, `environment`, `boss`, `ui`, and `roles`. The output root is isolated, IDs limit writes, and each selected PNG is paired with an editable Aseprite document and JSON provenance. The generator uses deterministic geometry; the recorded seed is informational and does not alter pixels. Run `python3 game/tools/validate_dopamine_pixel_candidates.py build/assets/candidates/pixel-art --report build/assets/candidates/pixel-art/qa-report.json` before integration.
