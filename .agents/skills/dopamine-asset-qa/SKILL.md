---
name: dopamine-asset-qa
description: Validate Dopamine Survivor generated visual and audio assets against the Art Bible, provenance requirements, file metadata, Godot importability, and targeted regeneration boundaries before acceptance.
---

# Dopamine Asset QA

Use local Python, Godot headless and available local CLIs only. Do not modify generated assets during QA.

## Visual checks

- Verify PNG decoding, expected dimensions, alpha/transparency, nearest-neighbor pixel geometry, no unintended antialias colors, and palette membership against `docs/art/palette_master.gpl`.
- Enforce at most 16 distinct colors for each 32x32 sprite. Check player sheet frame geometry against the documented compatible 4x4 layout. Validate other sheet conventions only when specified; report open conventions.
- Require editable Aseprite source and JSON metadata with generator/version, stable ID, seed, parameters, paths and hashes.
- Check animation frame bounds and identity markers for drift, but report visual acceptance separately.

## Audio checks

- Verify WAV readability, PCM encoding, sample rate/channels, duration, finite samples, clipping, peak/RMS and manifest hashes.
- For loops, check equal stem lengths, defined loop points and boundary continuity. Numeric checks do not replace listening.

## Import and scope

- Validate candidate assets before copying to active runtime paths. Use Godot headless import on a temporary copy/staging project where practical; never overwrite unrelated `.import` or asset files.
- Confirm every referenced runtime path exists after acceptance and that no unrelated asset hash changed during regeneration.
- Return a per-asset pass/fail report with exact paths and reasons. Never silently waive palette, licensing, provenance, or open-design issues. A passing report is not artistic/user approval.
