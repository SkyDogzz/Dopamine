---
name: dopamine-animation
description: Create consistent local pixel-art animation sheets for Dopamine Survivor while preserving character identity, palette, frame geometry, and editable sources. Use for player, enemy, boss, and VFX animation work.
---

# Dopamine Animation

Use local deterministic Python or LibreSprite CLI only; no cloud generation or paid services.

## Identity lock

- Read the Art Bible and the current accepted source for the character before drawing frames.
- Treat a character's silhouette, outline, head/visor shape, outfit blocks, signature marks, and palette as locked features. Animate pose, limbs, and allowed secondary motion around that model; do not redraw identity independently per frame.
- Build frames from shared geometry/palette/model primitives or edit a canonical base frame. Reuse stable seed and parameters for regeneration.
- Keep source `.aseprite`, export PNG, and metadata with frame size, grid, directions, frame names/durations, pivot, seed and source/export hashes.

## Rules and limits

- Preserve the Art Bible's strict pixel edges and palette limits; glow is runtime VFX only.
- Player is 32x32 with four directions and four idle/walk frames. Do not silently change the existing compatible 4x4 sheet layout.
- Direction row order, pivots, animation timing, asymmetrical mirroring, and non-player frame counts remain open where not explicitly specified. Record assumptions instead of presenting them as validated decisions.
- Validate dimensions, frame-grid alignment, alpha, palette, identity markers, and frame-to-frame bounds with `dopamine-asset-qa` before Godot import.
- Generate and integrate only the requested animation IDs. Keep unrelated art untouched.
