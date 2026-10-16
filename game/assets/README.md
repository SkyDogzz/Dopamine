# Art assets

The current generated pixel art is a visual prototype for the first playable. The source atlases are kept beside the individual PNGs; `tools/slice_sprite_atlas.gd` trims transparent margins, preserves nearest-neighbor pixel edges, and writes 64×64 sprites/icons.

- The first visual pilot replaces `sprites/player_cyan.png` (32×32), `sprites/enemy_chaser.png` (24×24), and `sprites/projectile_lightning.png` (16×16). Editable single-layer Aseprite files and the generated reference image are in `source/pilot/`; `tools/build_pilot_asset_batch.gd` reproduces the palette-limited PNG exports. The pilot source contains no animation frames.
- A generated 16×16 ground candidate was excluded from the run after the rendered pilot showed a distracting repeated pattern. `survival_ground.svg` remains active until a quieter tile is ready.

- `backgrounds/title_skyline.png` is the title-screen city background. It is 640×360 and uses only 30 colors from the validated 32-color Art Bible palette. The generated source is retained at `docs/art/source/title_skyline_generated.png`; `tools/process_title_skyline.gd` resizes and quantizes it reproducibly. This source is a flattened PNG; a layered Aseprite source has not been produced.

- `sprites/catalog/`: dedicated 32×32 icons for all ten weapons, their ten evolved forms, and all eleven relics, including the currently disabled-in-Survival Frost Nova/Frozen Crown pair. The PNGs use at most 16 colors and are wired into choices and run inventory. Their generated reference sheets and editable single-layer Aseprite sources are under `source/catalog_weapons/` and `source/catalog_relics/`; `tools/build_catalog_icon_assets.gd` rebuilds the exports.
- `icons/catalog/`: a matching 16-icon set for six equipment slots, five rarity markers, two resources, skill node, achievement medal, and run record. Equipment, rarity, and reward displays use these exports; the medal/record icons are assets only and do not add those features.
- `sprites/`: player, enemy archetypes and bosses, XP, projectiles, chest, and legacy relic artwork. The catalog icons above are the active presentation icons; older projectile sprites remain separate for combat rendering. Minigun, Toxic Cloud, Sawblades, Meteor Staff, Prism Laser, Void Orb, and Frost Nova have separate SVG projectile sprites; Starfall fragments and Spectrum Collapse secondary beams have separate sprite batches.
- `sprites/survival_ground.svg` is the repeating moss-and-stone floor texture for Survival. `survival_ruins.svg` is a transparent overlay of ancient pillars, rune marks, rocks, and ferns; both are decorative and do not affect collisions or gameplay.
- `sprites/weapon_impacts.svg` is a ten-cell, color-coded impact atlas used for brief direct-hit flashes across every catalog weapon family; damage-over-time ticks do not spawn extra flashes.
- `icons/`: equipment slots, resource rewards, rarity markers, plus skill/achievement/run-record placeholders for future UI.

Gameplay visuals use separate textures where the renderer batches by visual type. These assets do not establish or change gameplay rules, balance, or the still-proposed progression contracts.
