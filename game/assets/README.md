# Art assets

The current generated pixel art is a visual prototype for the first playable. The source atlases are kept beside the individual PNGs; `tools/slice_sprite_atlas.gd` trims transparent margins, preserves nearest-neighbor pixel edges, and writes 64×64 sprites/icons.

- `sprites/`: player, enemy archetypes and bosses, XP, projectiles, chest, and relics. Magnet Heart, Overdrive Engine, and Magnetic Coil use crisp-edged SVG icons alongside the atlas-derived PNGs; Minigun, Toxic Cloud, and Sawblades have separate SVG projectile sprites, and Plague Mask has an SVG relic icon.
- `icons/`: equipment slots, resource rewards, rarity markers, plus skill/achievement/run-record placeholders for future UI.

Gameplay visuals use separate textures where the renderer batches by visual type. These assets do not establish or change gameplay rules, balance, or the still-proposed progression contracts.
