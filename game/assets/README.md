# Art assets

The current generated pixel art is a visual prototype for the first playable. The source atlases are kept beside the individual PNGs; `tools/slice_sprite_atlas.gd` trims transparent margins, preserves nearest-neighbor pixel edges, and writes 64×64 sprites/icons.

- `sprites/`: player, enemy archetypes and bosses, XP, projectiles, chest, and relics. Magnet Heart, Overdrive Engine, Magnetic Coil, Celestial Eye, Prism Crystal, and Singularity use crisp-edged SVG icons alongside the atlas-derived PNGs; Plague Mask also has an SVG relic icon. Minigun, Toxic Cloud, Sawblades, Meteor Staff, Prism Laser, and Void Orb have separate SVG projectile sprites; Starfall fragments and Spectrum Collapse secondary beams have separate sprite batches.
- `sprites/survival_ground.svg` is the repeating moss-and-stone floor texture for Survival. `survival_ruins.svg` is a transparent overlay of ancient pillars, rune marks, rocks, and ferns; both are decorative and do not affect collisions or gameplay.
- `icons/`: equipment slots, resource rewards, rarity markers, plus skill/achievement/run-record placeholders for future UI.

Gameplay visuals use separate textures where the renderer batches by visual type. These assets do not establish or change gameplay rules, balance, or the still-proposed progression contracts.
