# Art assets

The current generated pixel art is a visual prototype for the first playable. The source atlases are kept beside the individual PNGs; `tools/slice_sprite_atlas.gd` trims transparent margins, preserves nearest-neighbor pixel edges, and writes 64×64 sprites/icons.

- `backgrounds/title_skyline.png` is the title-screen city background. It is 640×360 and uses only 30 colors from the validated 32-color Art Bible palette. The generated source is retained at `docs/art/source/title_skyline_generated.png`; `tools/process_title_skyline.gd` resizes and quantizes it reproducibly. This source is a flattened PNG; a layered Aseprite source has not been produced.

- `sprites/`: player, enemy archetypes and bosses, XP, projectiles, chest, and relics. All ten catalog weapons and eleven relics have icons, including the disabled-in-Survival Frost Nova/Frozen Crown pair. Magnet Heart, Overdrive Engine, Magnetic Coil, Celestial Eye, Prism Crystal, Singularity, and Frozen Crown use crisp-edged SVG icons alongside atlas-derived PNGs; Plague Mask also has an SVG relic icon. Minigun, Toxic Cloud, Sawblades, Meteor Staff, Prism Laser, Void Orb, and Frost Nova have separate SVG projectile sprites; Starfall fragments and Spectrum Collapse secondary beams have separate sprite batches.
- `sprites/survival_ground.svg` is the repeating moss-and-stone floor texture for Survival. `survival_ruins.svg` is a transparent overlay of ancient pillars, rune marks, rocks, and ferns; both are decorative and do not affect collisions or gameplay.
- `sprites/weapon_impacts.svg` is a ten-cell, color-coded impact atlas used for brief direct-hit flashes across every catalog weapon family; damage-over-time ticks do not spawn extra flashes.
- `icons/`: equipment slots, resource rewards, rarity markers, plus skill/achievement/run-record placeholders for future UI.

Gameplay visuals use separate textures where the renderer batches by visual type. These assets do not establish or change gameplay rules, balance, or the still-proposed progression contracts.
