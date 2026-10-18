#!/usr/bin/env python3
"""Build the auditable asset backlog from the current game contracts."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "docs" / "art" / "ASSET_MANIFEST.json"

WEAPONS = [
	"lightning_conductor", "inferno_sprayer", "crimson_daggers", "minigun",
	"toxic_cloud", "sawblades", "meteor_staff", "prism_laser", "void_orb", "frost_nova",
]
EVOLUTIONS = {
	"lightning_conductor": "infinite_circuit", "inferno_sprayer": "wildfire",
	"crimson_daggers": "bloodstorm", "minigun": "redline", "toxic_cloud": "pandemic",
	"sawblades": "razorstorm", "meteor_staff": "starfall", "prism_laser": "spectrum_collapse",
	"void_orb": "event_horizon", "frost_nova": "absolute_zero",
}
RELICS = [
	"storm_core", "infernal_heart", "blood_chalice", "overdrive_engine", "plague_mask",
	"magnetic_coil", "celestial_eye", "magnet_heart", "frozen_crown", "prism_crystal", "singularity",
]
ENEMIES = ["chaser", "sprinter", "tank", "shooter", "buffer", "exploder", "shielder", "summoner", "summoned"]
PROJECTILES = [
	"lightning", "inferno", "crimson", "enemy", "minigun", "toxic_cloud", "sawblades", "meteor",
	"starfall_fragment", "prism_laser", "prism_secondary", "void_orb", "frost_nova", "infinite_circuit",
	"wildfire", "bloodstorm", "event_horizon", "absolute_zero", "pandemic", "razorstorm", "starfall",
	"spectrum_collapse", "unique_lightning_burst", "evolution_shockwave",
]
SFX = [
	"weapon_shot_01", "weapon_shot_02", "weapon_shot_03", "weapon_shot_04",
	"weapon_zap_01", "weapon_zap_02", "weapon_zap_03", "weapon_zap_04",
	"weapon_sweep_01", "weapon_sweep_02", "weapon_sweep_03",
	"hit_light_01", "hit_light_02", "hit_light_03", "hit_light_04",
	"hit_heavy_01", "hit_heavy_02", "hit_heavy_03",
	"enemy_kill_01", "enemy_kill_02", "enemy_kill_03", "enemy_kill_04",
	"xp_pickup_01", "xp_pickup_02", "xp_pickup_03", "xp_pickup_04",
	"relic_pickup", "chest_open", "chest_reward", "level_up", "boss_telegraph",
	"boss_phase", "boss_defeat", "ui_focus", "ui_confirm", "ui_back", "ui_error", "ui_pause",
]
MUSIC_STEMS = ["rhythm", "bass", "pad", "arp", "boss"]

assets: list[dict[str, object]] = []


def add(asset_id: str, category: str, entity: str, variants: list[str], events: list[str],
		target_format: str, dimensions: list[int] | None, skill: str, destination: str,
		blockers: list[str] | None = None, source: str = "GDD v1.6 + Godot runtime contracts") -> None:
	source_path = {
		"dopamine-pixel-art": "game/assets/source/<category>/<asset_id>.aseprite",
		"dopamine-animation": "game/assets/source/animation/<asset_id>.aseprite",
		"dopamine-sfx": "game/tools/generate_original_audio.py",
		"dopamine-music": "game/tools/generate_original_audio.py",
	}[skill]
	assets.append({
		"asset_id": asset_id,
		"category": category,
		"gameplay_entity_or_system": entity,
		"required_animations_or_variants": variants,
		"required_audio_events": events,
		"target_format_and_dimensions": {"format": target_format, "pixels": dimensions},
		"assigned_generation_skill": skill,
		"godot_destination": destination,
		"authoring_source_or_recipe": source_path,
		"generator_version": None,
		"generation_seed": None,
		"generation_parameters": {},
		"source_sha256": None,
		"export_sha256": None,
		"qa_report_path": None,
		"generation_status": "not_generated",
		"validation_status": "not_run",
		"human_review_status": "pending",
		"integration_status": "not_integrated",
		"blockers": blockers or [],
		"requirement_source": source,
	})


def visual(asset_id: str, category: str, entity: str, size: list[int], destination: str,
		variants: list[str] | None = None, blocker: str | None = None, animated: bool = False) -> None:
	blockers = [blocker] if blocker else []
	add(asset_id, category, entity, variants or [], [], "PNG + editable Aseprite source", size,
		"dopamine-animation" if animated else "dopamine-pixel-art", destination, blockers)


# Existing runtime representation that remains directly supported by the game.
visual("player_idle", "character_animation", "player", [128, 128], "res://assets/sprites/player_idle.png",
	["4 directions × 4 idle frames; row order and timing open"], "hero outfit details are open", animated=True)
visual("player_walk", "character_animation", "player", [128, 128], "res://assets/sprites/player_walk.png",
	["4 directions × 4 walk frames; row order and timing open"], "hero outfit details are open", animated=True)
visual("player_attack", "character_animation", "player", [None, None], "res://assets/sprites/player_attack.png",
	["attack state; frame count, directions and timing unspecified"], "attack presentation is not specified by GDD/Art Bible", animated=True)
visual("player_death", "character_animation", "player", [None, None], "res://assets/sprites/player_death.png",
	["death state; frame count and timing unspecified"], "death animation is not specified by GDD/Art Bible", animated=True)

for enemy in ENEMIES:
	visual(f"enemy_{enemy}_sprite", "enemy_sprite", enemy, [24, 24], f"res://assets/sprites/roster/enemy_{enemy}.png",
		blocker="enemy outfit/identity details and final roster art brief are open")
	for state in ("idle", "move", "attack", "death"):
		visual(f"enemy_{enemy}_{state}", "enemy_animation", enemy, [None, None],
			f"res://assets/sprites/animation/enemy_{enemy}_{state}.png",
			[f"4 direction rows requested; frame count/timing for {state} open"],
			f"{state} animation timing/frame count not specified", animated=True)

for elite in ("elite_sprinter",):
	visual(f"{elite}_sprite", "elite_sprite", elite, [24, 24], f"res://assets/sprites/roster/{elite}.png",
		["distinct aura and symbol"], "elite visual identity details are not specified")
	for state in ("idle", "move", "attack", "death"):
		visual(f"{elite}_{state}", "elite_animation", elite, [None, None],
			f"res://assets/sprites/animation/{elite}_{state}.png", ["4 direction rows requested; frames/timing open"],
			f"{state} animation timing/frame count not specified", animated=True)

for boss in ("pulse_warden", "dopamine_core"):
	visual(f"boss_{boss}_sprite", "boss_sprite", boss, [96, 96], f"res://assets/sprites/roster/boss_{boss}.png",
		blocker="canonical boss identity and patterns are open; only role prototypes permitted")
	for state in ("idle", "move", "attack", "special", "death"):
		visual(f"boss_{boss}_{state}", "boss_animation", boss, [None, None],
			f"res://assets/sprites/animation/boss_{boss}_{state}.png", ["directions, frames and timing open"],
			f"boss identity/patterns and {state} animation timing are open", animated=True)

for weapon, evolution in EVOLUTIONS.items():
	for variant, name in (("base", weapon), ("evolved", evolution)):
		icon_id = f"weapon_{weapon}" if variant == "base" else f"evolution_{weapon}"
		visual(f"weapon_{name}_icon", "weapon_icon", weapon, [32, 32],
			f"res://assets/sprites/catalog/{icon_id}.png", [variant])
		visual(f"weapon_{name}_attack", "weapon_animation", weapon, [None, None],
			f"res://assets/sprites/animation/{name}_attack.png", ["weapon attack loop; frames/timing open"],
			"weapon level/evolution animation timing not specified", animated=True)
	for state in ("fire", "impact"):
		visual(f"weapon_{weapon}_{state}_vfx", "weapon_vfx_animation", weapon, [None, None],
			f"res://assets/sprites/animation/{weapon}_{state}.png", ["base and evolved variants"],
			"specific impact color/intensity and animation timing are open", animated=True)

for relic in RELICS:
	visual(f"relic_{relic}_icon", "relic_icon", relic, [32, 32], f"res://assets/sprites/catalog/relic_{relic}.png")
	visual(f"relic_{relic}_acquisition", "relic_animation", relic, [None, None],
		f"res://assets/sprites/animation/relic_{relic}_acquisition.png", ["acquisition reward animation"],
		"relic reward animation timing/rarity behavior open", animated=True)

for projectile in PROJECTILES:
	visual(f"projectile_{projectile}", "projectile_sprite", projectile, [16, 16],
		f"res://assets/sprites/projectiles/projectile_{projectile}.png", ["base/evolved role variants where applicable"])
	visual(f"projectile_{projectile}_animation", "projectile_animation", projectile, [None, None],
		f"res://assets/sprites/animation/projectile_{projectile}.png", ["animated projectile; frames/timing open"],
		"projectile animation frame count/timing unspecified", animated=True)

visual("chest_closed", "pickup", "survival chest", [32, 32], "res://assets/sprites/rewards/chest_closed.png",
	["closed", "open animation"])
visual("chest_open", "pickup_animation", "survival chest", [None, None], "res://assets/sprites/animation/chest_open.png",
	["open/reward"], "chest opening frame count and timing unspecified", animated=True)
visual("xp_orb", "pickup", "XP pickup", [16, 16], "res://assets/sprites/rewards/xp_orb.png")
visual("xp_orb_collect", "pickup_animation", "XP pickup", [None, None], "res://assets/sprites/animation/xp_orb_collect.png",
	["collect/attract animation"], "pickup animation timing unspecified", animated=True)
visual("survival_ground_tile", "environment_tile", "Survival arena", [16, 16],
	"res://assets/sprites/environment/survival_ground_tile.png", blocker="canonical first biome is open")
visual("survival_ruins_pixel", "environment_prop", "Survival arena", [None, None],
	"res://assets/sprites/environment/survival_ruins_pixel.png", blocker="canonical first biome is open")
visual("title_skyline", "background", "main menu", [640, 360], "res://assets/backgrounds/title_skyline.png")
visual("weapon_impacts_atlas", "impact_vfx_atlas", "weapon hit feedback", [640, 64],
	"res://assets/sprites/weapon_impacts_pixel.png", ["10 cells × 64×64; frames are weapon hit styles"])

for icon in [
	"equipment_helmet", "equipment_armor", "equipment_gloves", "equipment_boots", "equipment_amulet", "equipment_ring",
	"rarity_normal", "rarity_magic", "rarity_mystic", "rarity_legendary", "rarity_mythic",
	"resource_essence", "resource_powder", "skill_node", "achievement_medal", "run_record",
]:
	visual(f"ui_{icon}", "ui_icon", "Godot UI", [32, 32], f"res://assets/icons/catalog/{icon}.png")
visual("signal_prism", "ui_icon", "main menu", [32, 32], "res://assets/icons/ui/signal_prism.png")
for font, size in (("NeonArcadePixel", None), ("NeonArcadeUI", None)):
	add(f"font_{font.lower()}", "font", "Godot UI", [], [], "TTF/OTF", size, "dopamine-pixel-art",
		f"res://assets/fonts/{font}.ttf", ["font family design and glyph coverage/size not locked"])

# SFX IDs from the dedicated skill's current game event contract.
for sound in SFX:
	if sound.startswith("weapon_"):
		entity = "weapon family"
	elif sound.startswith("hit_") or sound.startswith("enemy_kill"):
		entity = "enemy combat feedback"
	elif sound.startswith("xp_"):
		entity = "XP pickup"
	elif sound.startswith("ui_"):
		entity = "UI"
	else:
		entity = sound.replace("_", " ")
	add(f"sfx_{sound}", "sound_effect", entity, ["deterministic variants as applicable"], [sound],
		"WAV PCM16 mono 44.1kHz candidate", None, "dopamine-sfx",
		f"res://assets/audio/original_procedural/sfx/{sound}.wav", source="GDD feedback + sfx_service.gd event map")

# Additional event cues explicitly required by the task but absent from current service IDs.
for sound in ("weapon_family_fire", "weapon_family_impact", "damage_taken", "healing", "explosion", "victory", "defeat"):
	add(f"sfx_{sound}", "sound_effect", sound.replace("_", " "), ["multiple variants where repeated"], [sound],
		"WAV PCM16 candidate", None, "dopamine-sfx", f"res://assets/audio/original_procedural/sfx/{sound}.wav",
		["new event is not yet mapped in runtime"], "user goal audio coverage")

for weapon in WEAPONS:
	for event in ("fire", "impact"):
		sound = f"weapon_{weapon}_{event}"
		add(f"sfx_{sound}", "sound_effect", weapon, ["4 deterministic variations preferred for frequent fire/impact"], [sound],
			"WAV PCM16 candidate", None, "dopamine-sfx", f"res://assets/audio/original_procedural/sfx/{sound}.wav",
			["weapon-specific sound ID is not yet mapped in runtime"], "user goal: distinct firing and impact signatures per weapon")

for cue in ("menu_theme", "survival_adaptive", "boss_intensity", "victory_cue", "defeat_cue"):
	add(f"music_{cue}", "music", cue.replace("_", " "), ["loop seamlessly" if cue in ("menu_theme", "survival_adaptive") else "state transition cue"],
		[cue], "WAV PCM16 stereo/runtime import candidate", None, "dopamine-music",
		f"res://assets/audio/music/{cue}.wav",
		["arrangement/tempo/key/duration are not validated decisions"], source="user goal + adaptive-audio GDD spec")
for stem in MUSIC_STEMS:
	add(f"music_stem_{stem}", "music_stem", "adaptive Survival music", ["same tempo/phase/loop length"], ["wave/boss intensity"],
		"WAV PCM16 candidate", None, "dopamine-music", f"res://assets/audio/original_procedural/music/{stem}.wav",
		["final stem arrangement/gains/formats remain open"], source="adaptive-audio spec [PROPOSÉ]")

ids = [str(asset["asset_id"]) for asset in assets]
if len(ids) != len(set(ids)):
	raise SystemExit("Duplicate asset IDs in manifest definition")

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
OUTPUT.write_text(json.dumps({
	"schema_version": 1,
	"project": "Dopamine Survivor",
	"created_from": ["docs/ART_BIBLE.txt", "docs/gdd/GDD_v1.6.md", "docs/specs/SPEC-asset-pipeline.md", "Godot runtime references"],
	"asset_root_status": "purged; outputs not yet generated",
	"audit_notes": [
		"Unknown dimensions/timing remain null and are not guessed.",
		"Open design blockers remain attached to affected IDs.",
		"The current visual/audio generators write directly into runtime paths and lack ID-scoped staging metadata; they are not safe production interfaces until adapted.",
		"Runtime menu/gameplay/boss transitions need audio review; audacity and ffmpeg are available locally.",
	],
	"assets": assets,
}, indent=2) + "\n")
print(f"Wrote {OUTPUT.relative_to(ROOT)}: {len(assets)} assets ({sum(a['category'] in {'character_animation', 'enemy_animation', 'elite_animation', 'boss_animation', 'weapon_animation', 'weapon_vfx_animation', 'relic_animation', 'projectile_animation', 'pickup_animation'} for a in assets)} animation/VFX records)")
