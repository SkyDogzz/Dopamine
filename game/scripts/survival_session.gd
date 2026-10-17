extends Node2D

signal chest_option_chosen(option_id: String)

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const SURVIVAL_TARGETING := preload("res://scripts/survival_targeting.gd")
const SPRITE_RENDERER_SCRIPT := preload("res://scripts/sprite_batch_renderer.gd")
const RUN_STAT_HUB_SCRIPT := preload("res://scripts/run_stat_hub.gd")
const CHEST_TEXTURE: Texture2D = preload("res://assets/sprites/rewards/chest_closed.png")
const CHEST_SPRITE_SIZE := 32.0
const XP_SPRITE_SIZE := 16.0
const PICKUP_SPACING_STEP := 16.0
const PICKUP_SPACING_DIRECTIONS := [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP,
		Vector2(0.707107, 0.707107), Vector2(-0.707107, 0.707107),
		Vector2(-0.707107, -0.707107), Vector2(0.707107, -0.707107)]
const GROUND_TEXTURE: Texture2D = preload("res://assets/sprites/environment/survival_ground_tile.png")
const RUINS_TEXTURE: Texture2D = preload("res://assets/sprites/environment/survival_ruins_pixel.png")
const WEAPON_IMPACTS_TEXTURE: Texture2D = preload("res://assets/sprites/weapon_impacts_pixel.png")
const WEAPON_IMPACT_TYPES := {
	"lightning_conductor": 0, "infinite_circuit_branch": 0, "unique_lightning_burst": 0,
	"inferno_sprayer": 1, "wildfire_sprayer": 1,
	"crimson_dagger": 2, "bloodstorm_dagger": 2,
	"minigun": 3, "redline": 3,
	"toxic_cloud": 4, "pandemic_cloud": 4,
	"sawblades": 5, "razorstorm": 5,
	"meteor_staff": 6, "starfall": 6, "starfall_fragment": 6,
	"prism_laser": 7, "spectrum_collapse": 7, "prism_secondary": 7,
	"void_orb": 8, "event_horizon": 8,
	"gravity_collapse": 8, "overcharge": 0,
	"frost_nova": 9, "absolute_zero": 9, "thermal_shock": 9, "shatter_impact": 9, "shatter_fragment": 9,
}
const WEAPON_IMPACT_SOURCE_IDS := {
	"lightning_conductor": "lightning_conductor", "unique_lightning_burst": "lightning_conductor",
	"infinite_circuit_branch": "lightning_conductor", "inferno_sprayer": "inferno_sprayer",
	"wildfire_sprayer": "inferno_sprayer", "redline": "minigun", "crimson_dagger": "crimson_daggers",
	"bloodstorm_dagger": "crimson_daggers", "minigun": "minigun", "toxic_cloud": "toxic_cloud",
	"pandemic_cloud": "toxic_cloud", "sawblades": "sawblades", "razorstorm": "sawblades",
	"meteor_staff": "meteor_staff", "starfall": "meteor_staff", "starfall_fragment": "meteor_staff",
	"prism_laser": "prism_laser", "spectrum_collapse": "prism_laser", "prism_secondary": "prism_laser",
	"void_orb": "void_orb", "event_horizon": "void_orb", "frost_nova": "frost_nova",
	"gravity_collapse": "void_orb", "overcharge": "lightning_conductor",
	"absolute_zero": "frost_nova", "thermal_shock": "frost_nova", "shatter_impact": "frost_nova",
	"shatter_fragment": "frost_nova",
}
const SHATTER_IMPACT_SOURCE_TYPES := ["crimson_dagger", "bloodstorm_dagger", "minigun", "redline",
		"sawblades", "razorstorm", "meteor_staff", "starfall", "starfall_fragment", "void_orb", "event_horizon"]
const ELECTROPLAGUE_SHOCK_SOURCE_TYPES := ["lightning_primary", "lightning_arc", "lightning_conductor",
		"infinite_circuit_branch", "unique_lightning_burst"]
const OVERCHARGE_SHOCK_DURATION_SECONDS := 1.0
const ELECTROPLAGUE_SPREAD_RADIUS := 60.0
const GRAVITY_COLLAPSE_IMPACT_SOURCE_TYPES := ["lightning_primary", "lightning_arc", "lightning_conductor",
		"unique_lightning_burst", "infinite_circuit_branch", "inferno_sprayer", "wildfire_sprayer",
		"crimson_dagger", "bloodstorm_dagger", "minigun", "redline", "toxic_cloud", "pandemic_cloud",
		"sawblades", "razorstorm", "meteor_staff", "starfall", "starfall_fragment", "prism_laser",
		"spectrum_collapse", "prism_secondary", "frost_nova", "absolute_zero"]
const GRAVITY_COLLAPSE_RADIUS := 60.0
const GRAVITY_COLLAPSE_DAMAGE_MULTIPLIER := 0.5
const WEAPON_IMPACT_LIFETIME := 0.22
const MAX_VISIBLE_WEAPON_IMPACTS := 32
const STATUS_EFFECT_COLORS := {
	"burn": Color("#FFD447"), "poison": Color("#48E69B"), "bleed": Color("#FF7181"),
}
const GENERIC_STATUS_COLOR := Color("#A6AEC4")
const LIGHTNING_ARC_LIFETIME := 0.12
const ENEMY_DEATH_PIXEL_LIFETIME := 0.32
const ENEMY_DEATH_PIXEL_COUNT := 8
const MAX_ENEMY_DEATH_PIXELS := 256
const ENEMY_DEATH_TYPES := ["chaser", "sprinter", "tank", "shooter", "buffer", "exploder", "shielder", "summoner", "summoned", "elite", "mid_boss", "final_boss"]
const ELITE_AFFIX_ACHIEVEMENT_IDS := {
	"Hasted": "hasted", "Armored": "armored", "Regenerating": "regenerating",
	"Volatile": "volatile", "Shielded": "shielded", "Split-on-Death": "split_on_death",
}
const WEAPON_DAMAGE_IDS := ["lightning_conductor", "inferno_sprayer", "crimson_daggers", "minigun", "toxic_cloud", "sawblades", "meteor_staff", "prism_laser", "void_orb", "frost_nova"]
const RELIC_ACHIEVEMENT_IDS := ["storm_core", "infernal_heart", "blood_chalice", "overdrive_engine", "plague_mask", "magnetic_coil", "celestial_eye", "prism_crystal", "singularity", "frozen_crown", "magnet_heart"]
const ENEMY_DEATH_PALETTE := [Color("#D4D9E8"), Color("#37E8F5"), Color("#087FB2"), Color("#F6F7FF")]
const WEAPON_ICONS := {
	"lightning_conductor": preload("res://assets/sprites/catalog/weapon_lightning_conductor.png"),
	"inferno_sprayer": preload("res://assets/sprites/catalog/weapon_inferno_sprayer.png"),
	"crimson_daggers": preload("res://assets/sprites/catalog/weapon_crimson_daggers.png"),
	"minigun": preload("res://assets/sprites/catalog/weapon_minigun.png"),
	"toxic_cloud": preload("res://assets/sprites/catalog/weapon_toxic_cloud.png"),
	"sawblades": preload("res://assets/sprites/catalog/weapon_sawblades.png"),
	"meteor_staff": preload("res://assets/sprites/catalog/weapon_meteor_staff.png"),
	"prism_laser": preload("res://assets/sprites/catalog/weapon_prism_laser.png"),
	"void_orb": preload("res://assets/sprites/catalog/weapon_void_orb.png"),
	"frost_nova": preload("res://assets/sprites/catalog/weapon_frost_nova.png"),
}
const WAVE_DIRECTOR_SCRIPT := preload("res://scripts/survival_wave_director.gd")
const ARMORLESS_RUN_STATE_SCRIPT := preload("res://scripts/armorless_run_state.gd")
const EQUIPMENT_GENERATOR_SCRIPT := preload("res://scripts/equipment_generator.gd")
const LOADOUT_SCRIPT := preload("res://scripts/survival_loadout.gd")
const XP_LEVEL_STAT_ROTATION := [
	"damage_pct", "attack_speed_pct", "critical_chance_pct", "critical_damage_pct",
	"max_hp", "move_speed_pct", "kill_healing_pct", "area_pct",
	"cooldown_reduction_pct", "xp_pct", "pickup_radius_pct", "projectile_speed_pct",
]
const WEAPON_PROGRESSION_IDS := ["lightning_conductor", "inferno_sprayer", "crimson_daggers", "void_orb",
		"frost_nova", "minigun", "meteor_staff", "sawblades", "toxic_cloud", "prism_laser"]
const CHEST_DIRECTOR_SCRIPT := preload("res://scripts/survival_chest_director.gd")
const DIFFICULTY_SCRIPT := preload("res://scripts/survival_difficulty.gd")
const WAVE_HP_GROWTH := 1.12
const WAVE_HP_CAP := 12.0
const MAX_SANDBOX_RNG_LOG_ENTRIES := 256
const SANDBOX_SNAPSHOT_VALUE_TYPES := [
	TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME,
	TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_RECT2, TYPE_RECT2I, TYPE_VECTOR3, TYPE_VECTOR3I,
	TYPE_VECTOR4, TYPE_VECTOR4I, TYPE_COLOR, TYPE_ARRAY, TYPE_DICTIONARY,
	TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY,
	TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_STRING_ARRAY,
	TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_COLOR_ARRAY,
	TYPE_PACKED_VECTOR4_ARRAY,
]

@export var spawn_initial_enemy: bool = true
@export var wave_spawning_enabled: bool = true
@export var skip_starting_weapon_choice: bool = false
var sandbox_diagnostics_enabled := false
var sandbox_rng_seed := 0
var sandbox_health_decay_multiplier := 1.0
@export_group("Prototype wave director — proposed tuning")
@export var wave_duration_seconds: float = 30.0
@export var wave_population_scale: float = 1.0
@export var enemy_spawn_interval: float = 0.5
@export var enemy_spawn_radius: float = 520.0
@export var boss_placeholder_hp: float = 1000.0
@export_group("Prototype Pulse Warden — proposed patterns")
@export_range(0.1, 0.9, 0.01) var pulse_warden_phase_two_health_ratio: float = 0.66
@export_range(0.1, 0.8, 0.01) var pulse_warden_phase_three_health_ratio: float = 0.33
@export var pulse_warden_attack_interval_seconds: float = 3.2
@export var pulse_warden_telegraph_seconds: float = 0.9
@export_range(4, 24) var pulse_warden_radial_projectile_count: int = 12
@export var pulse_warden_projectile_speed: float = 170.0
@export var pulse_warden_projectile_damage: float = 8.0
@export var pulse_warden_projectile_radius: float = 7.0
@export var pulse_warden_projectile_lifetime: float = 4.0
@export var pulse_warden_charge_speed: float = 320.0
@export var pulse_warden_charge_seconds: float = 0.28
@export_group("Prototype Dopamine Core — proposed patterns")
@export_range(0.1, 0.9, 0.01) var final_boss_phase_two_health_ratio: float = 0.66
@export_range(0.1, 0.8, 0.01) var final_boss_phase_three_health_ratio: float = 0.33
@export var final_boss_attack_interval_seconds: float = 2.6
@export var final_boss_telegraph_seconds: float = 0.85
@export var final_boss_ray_width: float = 20.0
@export var final_boss_zone_radius: float = 76.0
@export var final_boss_ray_damage: float = 12.0
@export var final_boss_zone_damage: float = 16.0
@export_range(6, 24) var final_boss_spiral_projectile_count: int = 14
@export var final_boss_spiral_shot_interval_seconds: float = 0.09
@export var final_boss_projectile_speed: float = 185.0
@export var final_boss_projectile_damage: float = 8.0
@export var final_boss_projectile_radius: float = 7.0
@export var final_boss_projectile_lifetime: float = 4.5
@export_group("Prototype elite director — proposed tuning")
@export var elite_spawn_interval_seconds: float = 45.0
@export_range(0.0, 1.0) var elite_spawn_chance: float = 0.35
@export_range(1, 5) var elite_max_active: int = 1
@export_range(1.0, 3.0, 0.05) var chaos_support_spawn_chance_multiplier: float = 1.5
@export_group("Prototype loot — proposed rates")
@export var ordinary_chest_drop_chance: float = 0.005
@export var elite_chest_drop_chance: float = 0.15
@export var chest_guarantee_interval_seconds: float = 60.0
@export var chest_collection_radius: float = 36.0
@export_group("Chest offer weights — proposed")
@export_range(0.1, 5.0, 0.05) var owned_upgrade_offer_weight: float = 1.5
@export_range(0.1, 5.0, 0.05) var matching_relic_offer_weight: float = 2.0
@export_range(0.1, 5.0, 0.05) var matching_weapon_offer_weight: float = 1.5
@export_range(0.1, 5.0, 0.05) var near_evolution_offer_weight: float = 1.25
@export_range(0.1, 5.0, 0.05) var combined_offer_weight_cap: float = 3.0
@export_group("Prototype contact damage — proposed tuning")
@export var contact_damage_per_hit: float = 10.0
@export var body_contact_cooldown_seconds: float = 0.35
@export var player_contact_radius: float = 16.0
@export var enemy_separation_radius: float = 18.0
@export_range(0.0, 1.0) var enemy_separation_weight: float = 0.5
@export_group("Prototype shooter attacks — proposed tuning")
@export var shooter_telegraph_seconds: float = 0.7
@export var shooter_fire_interval_seconds: float = 2.8
@export var shooter_projectile_speed: float = 180.0
@export var shooter_projectile_damage: float = 8.0
@export var shooter_projectile_radius: float = 6.0
@export var shooter_projectile_lifetime: float = 4.0
@export_group("Prototype Exploder attacks — proposed tuning")
@export var exploder_trigger_radius: float = 110.0
@export var exploder_blast_radius: float = 82.0
@export var exploder_fuse_seconds: float = 0.8
@export var exploder_damage: float = 18.0
@export_group("Prototype Summoner attacks — proposed tuning")
@export var summoner_warmup_seconds: float = 1.2
@export var summoner_cooldown_seconds: float = 8.0
@export var summoner_spawn_radius: float = 42.0
@export_range(1, 8) var summoner_max_active_summons: int = 3
@export_range(1, 4) var split_on_death_summon_count: int = 2
@export_group("Prototype Lightning Conductor — proposed tuning")
@export var weapon_enabled: bool = true
@export var lightning_cooldown: float = 0.5
@export var lightning_damage: float = 12.0
@export var lightning_range: float = SURVIVAL_TARGETING.LIGHTNING_RANGE
@export var lightning_projectile_speed: float = 800.0
@export var lightning_projectile_radius: float = 4.0
@export var lightning_projectile_lifetime: float = 2.0
@export_range(1, 5) var lightning_chain_count: int = 2
@export_range(1.0, 1000.0, 1.0) var lightning_chain_range: float = SURVIVAL_TARGETING.LIGHTNING_CLUSTER_RADIUS
@export_range(0.0, 1.0, 0.05) var lightning_chain_damage_multiplier: float = 0.75
@export_group("Prototype Inferno Sprayer — proposed tuning")
@export var inferno_cooldown: float = 0.7
@export var inferno_damage: float = 8.0
@export var inferno_range: float = SURVIVAL_TARGETING.INFERNO_RANGE
@export var inferno_projectile_speed: float = 650.0
@export var inferno_projectile_radius: float = 5.0
@export var inferno_projectile_lifetime: float = 1.2
@export var inferno_burn_damage_per_tick: float = 2.0
@export var inferno_burn_interval_seconds: float = 0.5
@export var inferno_burn_duration_seconds: float = 2.0
@export_group("Prototype Wildfire — proposed tuning")
@export var wildfire_explosion_radius: float = 60.0
@export_range(0.0, 1.0) var wildfire_explosion_damage_multiplier: float = 0.5
@export_group("Prototype Crimson Daggers — proposed tuning")
@export var daggers_cooldown: float = 0.8
@export var daggers_damage: float = 7.0
@export var daggers_range: float = SURVIVAL_TARGETING.DAGGERS_RANGE
@export var daggers_projectile_speed: float = 900.0
@export var daggers_projectile_radius: float = 2.5
@export var daggers_projectile_lifetime: float = 0.8
@export var daggers_orbit_angular_speed: float = 5.0
@export var bloodstorm_orbit_lifetime_seconds: float = 2.4
@export_group("Prototype Minigun — proposed tuning")
@export var minigun_cooldown: float = 0.18
@export var minigun_damage: float = 4.0
@export var minigun_range: float = SURVIVAL_TARGETING.MINIGUN_RANGE
@export_range(0.0, 0.5) var minigun_spread_radians: float = 0.03
@export var minigun_projectile_speed: float = 1100.0
@export var minigun_projectile_radius: float = 3.0
@export var minigun_projectile_lifetime: float = 0.8
@export var redline_max_cadence_bonus: float = 0.5
@export var redline_ramp_seconds: float = 5.0
@export_group("Prototype Toxic Cloud — proposed tuning")
@export var toxic_cooldown: float = 1.4
@export var toxic_impact_damage: float = 3.0
@export var toxic_range: float = SURVIVAL_TARGETING.TOXIC_RANGE
@export var toxic_projectile_speed: float = 430.0
@export var toxic_projectile_radius: float = 4.0
@export var toxic_projectile_lifetime: float = 1.8
@export var toxic_cloud_radius: float = 52.0
@export_range(0.0, 1.0) var toxic_splash_damage_multiplier: float = 0.5
@export var toxic_damage_per_tick: float = 1.5
@export var toxic_tick_interval_seconds: float = 0.5
@export var toxic_status_duration_seconds: float = 2.0
@export var pandemic_spread_radius: float = 140.0
@export_range(1, 8) var pandemic_max_spread_targets: int = 3
@export var pandemic_feedback_seconds: float = 0.35
@export_group("Prototype Sawblades — proposed tuning")
@export var sawblades_cooldown: float = 1.8
@export var sawblades_damage: float = 8.0
@export var sawblades_range: float = SURVIVAL_TARGETING.SAWBLADES_RANGE
@export var sawblades_cluster_radius: float = SURVIVAL_TARGETING.SAWBLADES_CLUSTER_RADIUS # [PROPOSED] helps initial ricochet reach a group.
@export var sawblades_projectile_speed: float = 360.0
@export var sawblades_projectile_radius: float = 7.0
@export var sawblades_projectile_lifetime: float = 2.5
@export_range(0.0, 1.0) var magnetic_coil_projectile_speed_per_level: float = 0.04
@export_group("Prototype Meteor Staff — proposed tuning")
@export var meteor_staff_cooldown: float = 2.8
@export var meteor_staff_damage: float = 12.0
@export var meteor_staff_range: float = SURVIVAL_TARGETING.METEOR_RANGE
@export var meteor_staff_projectile_speed: float = 300.0
@export var meteor_staff_projectile_radius: float = 8.0
@export var meteor_staff_projectile_lifetime: float = 2.5
@export var meteor_staff_cluster_radius: float = SURVIVAL_TARGETING.METEOR_CLUSTER_RADIUS
@export var meteor_staff_blast_radius: float = 82.0
@export_range(0.0, 1.0) var meteor_staff_splash_damage_multiplier: float = 0.55
@export_range(0.0, 1.0) var celestial_eye_area_per_level: float = 0.03
@export_range(0.0, 1.0) var celestial_eye_double_impact_chance: float = 0.12
@export var starfall_fragment_radius: float = 150.0
@export var starfall_fragment_damage_multiplier: float = 0.4
@export_range(0, 8) var starfall_fragment_count: int = 2
@export_group("Prototype Prism Laser — proposed tuning")
@export var prism_laser_cooldown: float = 0.12
@export var prism_laser_damage: float = 3.0
@export var prism_laser_range: float = SURVIVAL_TARGETING.PRISM_RANGE
@export var spectrum_collapse_cluster_radius: float = SURVIVAL_TARGETING.PRISM_CLUSTER_RADIUS # [PROPOSED] groups secondary beams around the primary.
@export var prism_laser_projectile_speed: float = 1800.0
@export var prism_laser_projectile_radius: float = 1.5
@export var prism_crystal_critical_damage_per_level: float = 0.03
@export_range(0, 4) var spectrum_collapse_secondary_beams: int = 2
@export_group("Prototype Void Orb — proposed tuning")
@export var void_orb_cooldown: float = 2.4
@export var void_orb_damage: float = 7.0
@export var void_orb_range: float = SURVIVAL_TARGETING.VOID_ORB_RANGE
@export var void_orb_speed: float = 230.0
@export var void_orb_lifetime: float = 3.0
@export var void_orb_radius: float = 5.0
@export var void_orb_attraction_radius: float = 135.0
@export var void_orb_attraction_speed: float = 85.0
@export_group("Prototype Frost Nova — proposed tuning")
@export var frost_nova_cooldown: float = 3.0
@export var frost_nova_damage: float = 8.0
@export var frost_nova_radius: float = 145.0
@export var frost_nova_duration_seconds: float = 0.12
@export var frost_chill_duration_seconds: float = 2.0
@export_range(0.0, 1.0) var frost_chill_speed_multiplier: float = 0.65
@export var frozen_crown_vulnerability_at_level_five: float = 0.25
@export var absolute_zero_shatter_radius: float = 76.0
@export_range(0.0, 2.0) var absolute_zero_shatter_damage_multiplier: float = 0.75
@export_group("Prototype Shatter — proposed tuning")
@export_range(0.0, 1.0, 0.05) var shatter_fragment_damage_multiplier: float = 0.25
@export_range(0, 8) var shatter_fragment_count: int = 3
@export_range(0.0, 240.0, 1.0) var shatter_fragment_radius: float = 96.0
@export_range(1.0, 2000.0, 1.0) var shatter_fragment_speed: float = 700.0
@export_range(0.1, 5.0, 0.1) var shatter_fragment_lifetime_seconds: float = 0.75
@export_range(0.0, 16.0, 0.5) var shatter_fragment_projectile_radius: float = 3.0
@export_group("Prototype Thermal Shock — proposed tuning")
@export_range(0.0, 2.0, 0.05) var thermal_shock_damage_multiplier: float = 0.5
@export_range(0.0, 10.0, 0.1) var thermal_shock_target_cooldown_seconds: float = 1.0
@export_range(0.0, 64.0, 0.5) var thermal_shock_projectile_radius: float = 6.0
@export_group("Prototype Overcharge — proposed tuning")
@export_range(0.0, 2.0, 0.05) var overcharge_damage_multiplier: float = 0.5
@export_range(0.0, 240.0, 1.0) var overcharge_radius: float = 60.0
@export_range(0.0, 10.0, 0.1) var overcharge_target_cooldown_seconds: float = 1.0
const TOXIC_IGNITION_DAMAGE_MULTIPLIER := 0.5
const TOXIC_IGNITION_RADIUS := 60.0
const TOXIC_IGNITION_TARGET_COOLDOWN_SECONDS := 1.0
@export_group("Prototype Bloodstorm — proposed tuning")
@export var bloodstorm_bleed_damage_per_tick: float = 2.0
@export var bloodstorm_bleed_interval_seconds: float = 0.5
@export var bloodstorm_bleed_duration_seconds: float = 2.0
@export_group("Prototype relic bonuses — proposed tuning")
@export_range(0.0, 1.0) var blood_chalice_heal_per_level: float = 0.10
@export_range(0.1, 120.0, 0.1) var magnet_heart_level_five_pulse_interval_seconds: float = 20.0
@export_range(0.1, 10.0, 0.1) var magnet_heart_level_five_pulse_duration_seconds: float = 1.5
@export_range(1.0, 10.0, 0.1) var magnet_heart_level_five_radius_multiplier: float = 3.0
@export_range(1.0, 2000.0, 1.0) var magnet_heart_level_five_acceleration: float = 600.0
@export_range(1.0, 1000.0, 1.0) var magnet_heart_level_five_max_speed: float = 240.0
@export_group("Prototype XP — proposed tuning")
@export var xp_per_enemy: float = 5.0
@export var xp_collection_radius: float = 36.0
@export var xp_base_to_next_level: float = 10.0
@export var xp_growth_per_level: float = 5.0

var simulation: Object
var progression_service: RefCounted
var mode_id := "survival"
var armorless_run_state: RefCounted
var difficulty_id := "normal"
var _sprite_renderer: RefCounted
var _hp_fill_style: StyleBoxFlat
var _run_state_badge_style: StyleBoxFlat
var _run_id := ""
var player: CharacterBody2D
var loadout: RefCounted
var last_target_sequence := 0
var player_hp := 0.0
var player_max_hp := 0.0
var player_shield := 0.0
var _shield_expires_at := 0.0
var player_active_time := 0.0
var wave_director: RefCounted
var _next_enemy_spawn_time := 0.0
var _next_elite_spawn_time := 0.0
var _boss_spawn_pending := false
var _pulse_warden_attacks: Dictionary = {}
var _dopamine_core_attacks: Dictionary = {}
var player_level := 1
var player_xp := 0.0
var player_xp_to_next := 10.0
var _xp_run_stat_bonuses: Dictionary = {}
var _xp_level_bonus_count := 0
var run_over := false
var _victory_pending := false
var kill_count := 0
var _enemy_kills_by_type: Dictionary = {}
var _elite_affix_kills: Dictionary = {}
var _weapon_damage_by_id: Dictionary = {}
var _weapon_kills_by_id: Dictionary = {}
var _sandbox_damage_by_source: Dictionary = {}
var _sandbox_rng := RandomNumberGenerator.new()
var _sandbox_rng_log: Array[Dictionary] = []
var _last_target := Vector2(INF, INF)
var _last_simulation_time := 0.0
var _last_combat_event_sequence := 0
var _next_weapon_time := 0.0
var _next_inferno_time := 0.0
var _next_daggers_time := 0.0
var _next_minigun_time := 0.0
var _next_toxic_time := 0.0
var _next_sawblades_time := 0.0
var _next_meteor_time := 0.0
var _next_prism_time := 0.0
var _next_void_orb_time := 0.0
var _next_frost_nova_time := 0.0
var _prism_beams: Array[Dictionary] = []
var _prism_beam_endpoints: Array[Vector2] = []
var _last_prism_active_time := 0.0
var _lightning_chain_states: Dictionary = {}
var _lightning_arcs: Array[Dictionary] = []
var _next_lightning_chain_id := 0
var _redline_fire_time := 0.0
var _minigun_target_id := Vector2i(-1, -1)
var _pandemic_poisoned_targets: Dictionary = {}
var _pandemic_spread_targets: Dictionary = {}
var _pandemic_bursts: Array[Dictionary] = []
var _thermal_shock_next_at: Dictionary = {}
var _toxic_ignition_next_at: Dictionary = {}
var _overcharge_shock_expires_at: Dictionary = {}
var _overcharge_next_at: Dictionary = {}
var _weapon_impacts: Array[Dictionary] = []
var _enemy_death_pixels: Array[Dictionary] = []
var _starfall_fragments_spawned: Dictionary = {}
var _entities: Array = []
var _pending_xp_orbs: Dictionary = {}
var _magnet_heart_impulse_expires_at := 0.0
var _magnet_heart_next_pulse_at := -1.0
var _reserved_xp_drop_positions: Array[Vector2] = []
var _chest_director: RefCounted
var _world_chests: Array[Dictionary] = []
var _chest_open := false
var _active_chest_options: Array = []
var _active_chest_heading := "CHEST — CHOOSE ONE"
var _first_reward_chest_opened := false
var _free_first_chest_reroll_used := false
var _free_first_chest_reroll_available := false
var _starting_weapon_choice_open := false
var _manually_paused := false
var _contact_damage_until: Dictionary = {}
var _pending_lifesteal := 0.0
var _cached_persistent_damage_multiplier := 1.0
var _cached_skill_move_speed_pct := 0.0
var _cached_skill_critical_chance_pct := 0.0
var _last_attack_critical_hit := false
var _cached_equipment_bonuses: Dictionary = {}
var _cached_skill_stat_bonuses: Dictionary = {}
var _cached_achievement_stat_bonuses: Dictionary = {}
var _cached_unique_effects: Array[String] = []
var _base_player_move_speed := 240.0
var _next_unique_lightning_time := 0.0
var _evolution_shockwave_triggered := false
var _elite_haste_expires_at := 0.0
var _shooter_attacks: Dictionary = {}
var _exploder_attacks: Dictionary = {}
var _summoner_attacks: Dictionary = {}
var _pending_summon_sequences: Dictionary = {}
var _item_level_feedback_expires_at := 0.0
var _weapon_progression: Dictionary = {}
var _weapon_progression_valid := false
var _armorless_equipment_generator: RefCounted
var _pending_armorless_draft_waves: Array[int] = []

@onready var _hp_value: Label = $HUD/RunPanel/RunInfo/StatusRow/HPRow/HPValue
@onready var _hp_bar: ProgressBar = $HUD/RunPanel/RunInfo/StatusRow/HPRow/HPBar
@onready var _time_value: Label = $HUD/MetaPanel/MetaRow/TimeValue
@onready var _weapon_value: Label = $HUD/RunPanel/RunInfo/LoadoutRow/LoadoutLabel
@onready var _weapon_icon: TextureRect = $HUD/RunPanel/RunInfo/LoadoutRow/WeaponIcon
@onready var _xp_value: Label = $HUD/RunPanel/RunInfo/StatusRow/XPRow/XPValue
@onready var _xp_bar: ProgressBar = $HUD/RunPanel/RunInfo/StatusRow/XPRow/XPBar
@onready var _run_state: Label = $HUD/MetaPanel/MetaRow/RunStateBadge/RunState
@onready var _wave_value: Label = $HUD/MetaPanel/MetaRow/WaveValue
@onready var _difficulty_value: Label = $HUD/MetaPanel/MetaRow/DifficultyValue
@onready var _boss_panel: PanelContainer = $HUD/BossPanel
@onready var _boss_value: Label = $HUD/BossPanel/BossInfo/BossValue
@onready var _boss_hp_bar: ProgressBar = $HUD/BossPanel/BossInfo/BossHPBar
@onready var _item_level_feedback: PanelContainer = $HUD/ItemLevelFeedback
@onready var _item_level_feedback_label: Label = $HUD/ItemLevelFeedback/FeedbackLabel
@onready var _chest_choice: PanelContainer = $HUD/ChestOverlay/ChestChoice
@onready var _run_result_overlay: CenterContainer = $HUD/RunResultOverlay
@onready var _run_result: PanelContainer = $HUD/RunResultOverlay/RunResultPanel
@onready var _pause_overlay: Control = $HUD/PauseOverlay
@onready var _pause_speed_select: OptionButton = $HUD/PauseOverlay/Center/Panel/Content/SpeedSelect
@onready var _pause_health_lock_button: CheckButton = $HUD/PauseOverlay/Center/Panel/Content/HealthLockButton
@onready var _pause_auto_select_chest_button: CheckButton = $HUD/PauseOverlay/Center/Panel/Content/AutoSelectChestButton
@onready var _pause_resume_button: Button = $HUD/PauseOverlay/Center/Panel/Content/ResumeButton
@onready var _pause_options_button: Button = $HUD/PauseOverlay/Center/Panel/Content/OptionsButton
@onready var _pause_inventory_button: Button = $HUD/PauseOverlay/Center/Panel/Content/InventoryButton
@onready var _settings_service: SettingsService = get_node_or_null("/root/Settings") as SettingsService
@onready var _pause_abandon_button: Button = $HUD/PauseOverlay/Center/Panel/Content/AbandonButton
@onready var _abandon_confirmation: Control = $HUD/PauseOverlay/ConfirmationOverlay
@onready var _abandon_cancel_button: Button = $HUD/PauseOverlay/ConfirmationOverlay/Center/Panel/Content/CancelButton
@onready var _abandon_confirm_button: Button = $HUD/PauseOverlay/ConfirmationOverlay/Center/Panel/Content/ConfirmButton

var _options_overlay: Control
var _inventory_overlay: Control
var _run_stat_hub: Control
var _run_stat_hub_dirty := true
var _next_run_stat_hub_refresh_at := 0.0
var _health_locked := false
var _auto_select_first_chest := false

func _ready() -> void:
	if _settings_service != null:
		_settings_service.settings_changed.connect(_on_settings_changed)
	if sandbox_diagnostics_enabled:
		_sandbox_rng.seed = sandbox_rng_seed
	Engine.time_scale = 1.0
	_weapon_progression = _load_weapon_progression()
	if not _weapon_progression_valid:
		set_process(false)
		set_physics_process(false)
		return
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_style_run_hud()
	_run_stat_hub = RUN_STAT_HUB_SCRIPT.new()
	_run_stat_hub.name = "RunStatHub"
	$HUD.add_child(_run_stat_hub)
	_sprite_renderer = SPRITE_RENDERER_SCRIPT.new()
	_run_id = Crypto.new().generate_random_bytes(16).hex_encode()
	if mode_id == "armorless":
		armorless_run_state = ARMORLESS_RUN_STATE_SCRIPT.new(hash(_run_id))
		armorless_run_state.begin_run()
		_armorless_equipment_generator = EQUIPMENT_GENERATOR_SCRIPT.new(hash(_run_id) ^ 0xA24B)
	player = PLAYER_SCENE.instantiate()
	player.name = "Player"
	add_child(player)
	player.controls_enabled = false
	loadout = LOADOUT_SCRIPT.new()
	if progression_service != null and progression_service.has_method("unlocked_weapon_ids") and \
			progression_service.has_method("unlocked_relic_ids"):
		var unlocked_weapons: Array[String] = progression_service.unlocked_weapon_ids()
		var unlocked_relics: Array[String] = progression_service.unlocked_relic_ids()
		if unlocked_weapons.size() >= 2 and unlocked_relics.size() >= 2:
			loadout.set_unlocked_content(unlocked_weapons, unlocked_relics)
		else:
			push_error("Progression profile has no valid unlocked weapon/relic choices")
			set_process(false)
			set_physics_process(false)
			return
	loadout.offer_weights = {
		"owned_upgrade": owned_upgrade_offer_weight,
		"matching_relic": matching_relic_offer_weight,
		"matching_weapon": matching_weapon_offer_weight,
		"near_evolution": near_evolution_offer_weight,
		"combined_cap": combined_offer_weight_cap,
	}
	_chest_director = CHEST_DIRECTOR_SCRIPT.new()
	_chest_director.ordinary_drop_chance = ordinary_chest_drop_chance
	_chest_director.elite_drop_chance = elite_chest_drop_chance
	_chest_director.guarantee_interval_seconds = chest_guarantee_interval_seconds
	simulation = ClassDB.instantiate("CombatSimulation")
	if simulation == null:
		push_error("CombatSimulation GDExtension class is unavailable")
		set_physics_process(false)
		return
	_chest_choice.option_selected.connect(_on_chest_option_selected)
	_chest_choice.reroll_requested.connect(_reroll_first_chest)
	_run_result.restart_requested.connect(_restart_run)
	_run_result.quit_requested.connect(_quit_after_run)
	_pause_resume_button.pressed.connect(_resume_manually_paused_run)
	_pause_speed_select.item_selected.connect(_on_pause_speed_selected)
	_pause_health_lock_button.toggled.connect(_on_pause_health_lock_toggled)
	_pause_auto_select_chest_button.toggled.connect(_on_pause_auto_select_chest_toggled)
	_pause_options_button.pressed.connect(_open_pause_options)
	_pause_inventory_button.pressed.connect(_open_run_inventory)
	_pause_abandon_button.pressed.connect(_open_abandon_confirmation)
	_abandon_cancel_button.pressed.connect(_close_abandon_confirmation)
	_abandon_confirm_button.pressed.connect(_confirm_abandon_run)
	player_max_hp = simulation.initial_player_hp()
	_base_player_move_speed = player.move_speed
	if progression_service != null:
		_refresh_persistent_bonuses()
		player_max_hp *= 1.0 + progression_service.skill_bonus("max_hp_pct")
		if mode_id != "armorless":
			player_max_hp += _equipment_bonus("max_hp")
	player_hp = player_max_hp
	player_xp_to_next = xp_base_to_next_level
	wave_director = WAVE_DIRECTOR_SCRIPT.new(mode_id == "armorless")
	wave_director.wave_duration_seconds = wave_duration_seconds
	_next_elite_spawn_time = maxf(0.0, elite_spawn_interval_seconds)
	_publish_player_target()
	if spawn_initial_enemy and not wave_spawning_enabled:
		simulation.spawn_enemy("chaser", 1, player.global_position + Vector2(140.0, 0.0), Vector2.ZERO,
			float(DIFFICULTY_SCRIPT.DATA.get(difficulty_id, DIFFICULTY_SCRIPT.DATA["normal"])["enemy_hp"]))
	if skip_starting_weapon_choice:
		loadout.choose_starting_weapon("lightning_conductor")
		simulation.resume()
	else:
		_starting_weapon_choice_open = true
		_chest_choice.present(loadout.starting_weapon_options(), 2, "CHOOSE YOUR STARTING WEAPON")

func _load_weapon_progression() -> Dictionary:
	var file := FileAccess.open("res://data/weapon_progression.json", FileAccess.READ)
	if file == null:
		push_error("Weapon progression config is missing")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("version", 0)) != 1 or not parsed.get("weapons") is Dictionary:
		push_error("Weapon progression config has an invalid root or version")
		return {}
	var weapons: Dictionary = parsed["weapons"]
	if weapons.size() != WEAPON_PROGRESSION_IDS.size():
		push_error("Weapon progression config must define all ten weapons")
		return {}
	for weapon_id in WEAPON_PROGRESSION_IDS:
		if not weapons.has(weapon_id):
			push_error("Weapon progression config is missing %s" % weapon_id)
			return {}
	for weapon_id in weapons:
		if not weapons[weapon_id] is Dictionary:
			push_error("Weapon progression effects must be objects: %s" % weapon_id)
			return {}
		for effect_id in weapons[weapon_id]:
			var milestones: Variant = weapons[weapon_id][effect_id]
			if not milestones is Dictionary or milestones.is_empty():
				push_error("Weapon progression milestones must be non-empty objects: %s/%s" % [weapon_id, effect_id])
				return {}
			for level_key in milestones:
				var value: Variant = milestones[level_key]
				var integer_effect := str(effect_id) in ["projectile_count", "chain_count_add", "ricochet_add"]
				if int(level_key) < 1 or int(level_key) > LOADOUT_SCRIPT.MAX_LEVEL or \
					typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or float(value) <= 0.0 or \
					(integer_effect and not is_equal_approx(float(value), float(int(value)))):
					push_error("Weapon progression milestone is invalid: %s/%s/%s" % [weapon_id, effect_id, level_key])
					return {}
	_weapon_progression_valid = true
	return weapons

func _weapon_level_multiplier(weapon_id: String, effect_id: String, level: int) -> float:
	var milestones: Dictionary = _weapon_progression.get(weapon_id, {}).get(effect_id, {})
	var multiplier := 1.0
	for level_key in milestones:
		if level >= int(level_key):
			multiplier *= float(milestones[level_key])
	return multiplier

func _weapon_level_value(weapon_id: String, effect_id: String, level: int, fallback: float) -> float:
	var milestones: Dictionary = _weapon_progression.get(weapon_id, {}).get(effect_id, {})
	var value := fallback
	var best_level := 0
	for level_key in milestones:
		var milestone_level := int(level_key)
		if milestone_level <= level and milestone_level > best_level:
			best_level = milestone_level
			value = float(milestones[level_key])
	return value

func _weapon_level_addition(weapon_id: String, effect_id: String, level: int) -> int:
	var milestones: Dictionary = _weapon_progression.get(weapon_id, {}).get(effect_id, {})
	var value := 0
	for level_key in milestones:
		if level >= int(level_key):
			value += int(milestones[level_key])
	return value

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _on_pause_speed_selected(index: int) -> void:
	if not _manually_paused or simulation == null:
		return
	var multiplier: float = [0.25, 0.5, 1.0, 2.0, 4.0][index]
	Engine.time_scale = multiplier
	simulation.set_speed(multiplier)

func _on_pause_health_lock_toggled(enabled: bool) -> void:
	if not _manually_paused:
		_pause_health_lock_button.set_pressed_no_signal(_health_locked)
		return
	_health_locked = enabled

func _on_pause_auto_select_chest_toggled(enabled: bool) -> void:
	if not _manually_paused:
		_pause_auto_select_chest_button.set_pressed_no_signal(_auto_select_first_chest)
		return
	_auto_select_first_chest = enabled

func _physics_process(_delta: float) -> void:
	_publish_player_target()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		if simulation == null or run_over or _chest_open or _starting_weapon_choice_open or _manually_paused:
			return
		_run_stat_hub.toggle_detail()
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	if _run_stat_hub != null and _run_stat_hub.detail_open:
		_run_stat_hub.set_detail_open(false)
		get_viewport().set_input_as_handled()
		return
	if simulation == null or run_over or _chest_open or _starting_weapon_choice_open:
		return
	if _abandon_confirmation.visible:
		_close_abandon_confirmation()
	elif _manually_paused:
		_resume_manually_paused_run()
	elif not bool(simulation.snapshot()["paused"]):
		_manually_paused = true
		simulation.pause()
		_pause_overlay.show()
		_pause_resume_button.grab_focus()
	else:
		return
	get_viewport().set_input_as_handled()

func _resume_manually_paused_run() -> void:
	if not _manually_paused or simulation == null or run_over:
		return
	_manually_paused = false
	_pause_overlay.hide()
	Sfx.play("ui_pause")
	simulation.resume()

func _open_pause_options() -> void:
	if not _manually_paused or _options_overlay != null:
		return
	var options_scene: PackedScene = load("res://scenes/options_panel.tscn")
	_options_overlay = options_scene.instantiate() as Control
	_options_overlay.name = "OptionsPanel"
	_options_overlay.close_requested.connect(_close_pause_options)
	$HUD.add_child(_options_overlay)

func _close_pause_options() -> void:
	if _options_overlay == null:
		return
	_options_overlay.queue_free()
	_options_overlay = null
	call_deferred("_restore_pause_options_focus")

func _restore_pause_options_focus() -> void:
	if _manually_paused and is_instance_valid(_pause_options_button):
		_pause_options_button.grab_focus()

func _open_run_inventory() -> void:
	if not _manually_paused or _inventory_overlay != null:
		return
	var inventory_scene: PackedScene = load("res://scenes/run_inventory_panel.tscn")
	_inventory_overlay = inventory_scene.instantiate() as Control
	_inventory_overlay.name = "RunInventoryPanel"
	_inventory_overlay.close_requested.connect(_close_run_inventory)
	_inventory_overlay.armorless_enhancement_requested.connect(_enhance_armorless_equipment)
	$HUD.add_child(_inventory_overlay)
	_refresh_run_inventory()

func _enhance_armorless_equipment(instance_id: String, stat_id: String) -> void:
	if not _manually_paused or mode_id != "armorless" or armorless_run_state == null or _inventory_overlay == null:
		return
	var previous_max_hp_bonus := _equipment_bonus("max_hp")
	var result: Dictionary = armorless_run_state.enhance_equipment(instance_id, stat_id)
	if result.get("ok", false):
		player_max_hp += (_equipment_bonus("max_hp") - previous_max_hp_bonus) * (1.0 + _xp_run_stat_bonus("max_hp") / 100.0)
		player_hp = minf(player_hp, player_max_hp)
		_refresh_persistent_bonuses()
	var message := ""
	if result.get("ok", false):
		message = "ENHANCEMENT SUCCESS" if result["success"] else \
			"CRITICAL FAILURE — LEVEL LOST" if result["critical_failure"] else "ENHANCEMENT FAILED"
	else:
		message = "NOT ENOUGH FLUX  ·  %d REQUIRED" % int(result.get("cost", 0)) \
			if result.get("error", "") == "insufficient_flux" else "UPGRADE UNAVAILABLE"
	_refresh_run_inventory(message, not result.get("ok", false))
	_inventory_overlay.focus_enhancement(instance_id, stat_id)

func _refresh_run_inventory(feedback: String = "", is_error: bool = false) -> void:
	if _inventory_overlay == null:
		return
	if mode_id == "armorless" and armorless_run_state != null:
		_inventory_overlay.show_items(
			loadout.owned_item_details("weapon"), loadout.owned_item_details("relic"),
			armorless_run_state.temporary_equipment(), armorless_run_state.flux()
		)
	else:
		_inventory_overlay.show_items(loadout.owned_item_details("weapon"), loadout.owned_item_details("relic"))
	if not feedback.is_empty():
		_inventory_overlay.show_feedback(feedback, is_error)

func _close_run_inventory() -> void:
	if _inventory_overlay == null:
		return
	_inventory_overlay.queue_free()
	_inventory_overlay = null
	call_deferred("_restore_run_inventory_focus")

func _restore_run_inventory_focus() -> void:
	if _manually_paused and is_instance_valid(_pause_inventory_button):
		_pause_inventory_button.grab_focus()

func _open_abandon_confirmation() -> void:
	if not _manually_paused:
		return
	_abandon_confirmation.show()
	_abandon_cancel_button.grab_focus()

func _close_abandon_confirmation() -> void:
	_abandon_confirmation.hide()
	if _manually_paused:
		_pause_abandon_button.grab_focus()

func _confirm_abandon_run() -> void:
	if not _manually_paused or simulation == null:
		return
	simulation.pause()
	if mode_id == "armorless" and armorless_run_state != null:
		armorless_run_state.end_run()
		_pending_armorless_draft_waves.clear()
	_manually_paused = false
	run_over = true
	var error := get_tree().change_scene_to_file("res://scenes/launch_menu.tscn")
	if error != OK:
		run_over = false
		_manually_paused = true
		push_error("Could not return to launch menu after abandoning the run: %s" % error_string(error))

func _process(_delta: float) -> void:
	if simulation == null:
		return
	if mode_id == "armorless" and not run_over and not _manually_paused and \
			not _chest_open and not _pending_armorless_draft_waves.is_empty():
		_open_next_armorless_draft()
		return
	var state: Dictionary = simulation.snapshot()
	var current_simulation_time: float = float(state["simulation_time"])
	var elapsed_active_time := current_simulation_time - _last_simulation_time
	for chain_id in _lightning_chain_states.keys():
		if current_simulation_time > float(_lightning_chain_states[chain_id]["expires_at"]):
			_lightning_chain_states.erase(chain_id)
	for target_key in _thermal_shock_next_at.keys():
		if current_simulation_time >= float(_thermal_shock_next_at[target_key]):
			_thermal_shock_next_at.erase(target_key)
	for target_key in _overcharge_shock_expires_at.keys():
		if current_simulation_time >= float(_overcharge_shock_expires_at[target_key]):
			_overcharge_shock_expires_at.erase(target_key)
	for target_key in _overcharge_next_at.keys():
		if current_simulation_time >= float(_overcharge_next_at[target_key]):
			_overcharge_next_at.erase(target_key)
	for index in range(_pandemic_bursts.size() - 1, -1, -1):
		_pandemic_bursts[index]["remaining"] = float(_pandemic_bursts[index]["remaining"]) - elapsed_active_time
		if float(_pandemic_bursts[index]["remaining"]) <= 0.0:
			_pandemic_bursts.remove_at(index)
	for index in range(_weapon_impacts.size() - 1, -1, -1):
		_weapon_impacts[index]["remaining"] = float(_weapon_impacts[index]["remaining"]) - elapsed_active_time
		if float(_weapon_impacts[index]["remaining"]) <= 0.0:
			_weapon_impacts.remove_at(index)
	for index in range(_enemy_death_pixels.size() - 1, -1, -1):
		_enemy_death_pixels[index]["remaining"] = float(_enemy_death_pixels[index]["remaining"]) - elapsed_active_time
		_enemy_death_pixels[index]["position"] += _enemy_death_pixels[index]["velocity"] * elapsed_active_time
		if float(_enemy_death_pixels[index]["remaining"]) <= 0.0:
			_enemy_death_pixels.remove_at(index)
	for index in range(_lightning_arcs.size() - 1, -1, -1):
		_lightning_arcs[index]["remaining"] = float(_lightning_arcs[index]["remaining"]) - elapsed_active_time
		if float(_lightning_arcs[index]["remaining"]) <= 0.0:
			_lightning_arcs.remove_at(index)
	if elapsed_active_time > 0.0 and not run_over:
		if player_shield > 0.0 and player_active_time >= _shield_expires_at:
			player_shield = 0.0
		_take_player_damage(_player_health_decay_amount(player_active_time, elapsed_active_time))
		player_active_time += elapsed_active_time
	_update_magnet_heart_pulse(state, elapsed_active_time)
	_refresh_player_move_speed()
	_last_simulation_time = current_simulation_time
	var latest_event_sequence := _last_combat_event_sequence
	for event in state["events"]:
		var sequence: int = int(event["sequence"])
		if sequence <= _last_combat_event_sequence:
			continue
		latest_event_sequence = sequence
		match event["type"]:
			"damage":
				var damage_source: Dictionary = event["source"]
				var damage_target: Dictionary = event["target"]
				var source_key := _entity_key(int(damage_source["index"]), int(damage_source["generation"]))
				var target_key := _entity_key(int(damage_target["index"]), int(damage_target["generation"]))
				var source_type: String = str(event.get("source_type", ""))
				_record_weapon_damage(source_type, float(event["amount"]))
				if not bool(event.get("is_damage_over_time", false)):
					var target_type := str(event.get("target_type", ""))
					Sfx.play("hit_heavy" if target_type in ["mid_boss", "final_boss"] else "hit_light")
				_advance_lightning_chain(event, state["entities"], current_simulation_time)
				_try_thermal_shock(event, state["entities"], current_simulation_time)
				_try_toxic_ignition(event, current_simulation_time)
				_try_electroplague(event, state["entities"])
				_try_gravity_collapse(event, state["entities"])
				_try_overcharge(event, current_simulation_time)
				_try_hemorrhage(event)
				_try_shatter(event, state["entities"])
				_add_weapon_impact(source_type, Vector2(float(event["position"]["x"]), float(event["position"]["y"])),
						bool(event.get("is_damage_over_time", false)))
				if source_type == "pandemic_cloud":
					_pandemic_poisoned_targets[target_key] = true
				elif source_type == "starfall":
					if not _starfall_fragments_spawned.has(source_key):
						_starfall_fragments_spawned[source_key] = true
						_spawn_starfall_fragments(Vector2(float(event["position"]["x"]), float(event["position"]["y"])),
								damage_target, state["entities"])
				var damage_lifesteal: float = float(event["amount"]) * (loadout.global_relic_bonus("lifesteal_pct") + _equipment_bonus("lifesteal_pct")) / 100.0
				if bool(event.get("is_damage_over_time", false)):
					damage_lifesteal *= 0.25
				_pending_lifesteal += damage_lifesteal
			"death":
				kill_count += 1
				var dead_target: Dictionary = event["target"]
				var dead_enemy_type: String = str(event.get("target_type", ""))
				var dead_enemy_affix: String = str(event.get("target_affix", ""))
				_record_enemy_kill(dead_enemy_type, dead_enemy_affix)
				_record_weapon_kill(str(event.get("source_type", "")))
				var death_position := Vector2(float(event["position"]["x"]), float(event["position"]["y"]))
				Sfx.play("boss_defeat" if dead_enemy_type in ["mid_boss", "final_boss"] else "enemy_kill")
				_add_enemy_death_pixels(dead_enemy_type, death_position)
				if dead_enemy_type == "elite" and dead_enemy_affix.split("+").has("Split-on-Death"):
					_spawn_split_summons(death_position, state)
				if bool(event.get("target_was_chilled", false)) and loadout.is_evolved("frost_nova") and str(event.get("source_type", "")) != "absolute_zero":
					simulation.spawn_projectile("absolute_zero", death_position, Vector2.ZERO,
							frost_nova_damage * absolute_zero_shatter_damage_multiplier * _weapon_combo_damage_multiplier("frost_nova") * _persistent_damage_multiplier(),
							_equipment_area(absolute_zero_shatter_radius), frost_nova_duration_seconds,
							2.0, 0.5, 2.0, 0.0, 0.0, 0, 0.0, 0.0, true)
				var dead_key := _entity_key(int(dead_target["index"]), int(dead_target["generation"]))
				if _pandemic_poisoned_targets.has(dead_key) and not _pandemic_spread_targets.has(dead_key):
					_pandemic_spread_targets[dead_key] = true
					_spread_pandemic(death_position, state["entities"])
				_pandemic_poisoned_targets.erase(dead_key)
				if dead_enemy_type == "elite" and _has_unique_effect("elite_haste"):
					_elite_haste_expires_at = player_active_time + 3.0
					_refresh_player_move_speed()
					_show_effect_feedback("ELITE HASTE  ·  +15% MOVE")
				if dead_enemy_type == "mid_boss":
					_boss_spawn_pending = false
					wave_director.boss_defeated()
				elif dead_enemy_type == "final_boss":
					_boss_spawn_pending = false
					wave_director.boss_defeated()
					_victory_pending = true
				_roll_enemy_chests(dead_enemy_type, death_position)
				if not run_over:
					var healing: float = _equipment_kill_healing(float(simulation.kill_heal_amount(float(event["threat_level"]))))
					player_hp = minf(player_max_hp, player_hp + healing)
					_spawn_xp_drop(
						death_position,
						_equipment_xp_value(xp_per_enemy)
					)
			"xp_collected":
				var id: Dictionary = event["target"]
				_pending_xp_orbs.erase(_entity_key(int(id["index"]), int(id["generation"])))
				_remove_reserved_xp_position(Vector2(float(event["position"]["x"]), float(event["position"]["y"])))
				Sfx.play("xp_pickup")
				_add_xp(float(event["amount"]))
	_apply_pending_lifesteal(elapsed_active_time)
	if latest_event_sequence > _last_combat_event_sequence:
		_last_combat_event_sequence = latest_event_sequence
		simulation.acknowledge_events(latest_event_sequence)
	var active_projectiles: Dictionary = {}
	for entity in state["entities"]:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false):
			var id: Dictionary = entity["id"]
			active_projectiles[_entity_key(int(id["index"]), int(id["generation"]))] = true
	for projectile_key in _starfall_fragments_spawned.keys():
		if not active_projectiles.has(projectile_key):
			_starfall_fragments_spawned.erase(projectile_key)
	_entities = state["entities"]
	_sprite_renderer.set_entities(_entities)
	_advance_wave_director(elapsed_active_time, state["paused"])
	_apply_contact_damage(state, current_simulation_time)
	_update_shooter_attacks(current_simulation_time, bool(state["paused"]))
	_update_exploder_attacks(current_simulation_time, bool(state["paused"]))
	_update_summoner_attacks(current_simulation_time, bool(state["paused"]))
	_update_pulse_warden_attacks(current_simulation_time, bool(state["paused"]))
	_update_dopamine_core_attacks(current_simulation_time, bool(state["paused"]))
	_collect_nearby_xp_orbs(state)
	_collect_nearby_chests(state)
	_complete_pending_victory()
	_fire_lightning_conductor(current_simulation_time, state["paused"])
	_fire_inferno_sprayer(current_simulation_time, state["paused"])
	_fire_crimson_daggers(current_simulation_time, state["paused"])
	_fire_minigun(current_simulation_time, state["paused"])
	_fire_toxic_cloud(current_simulation_time, state["paused"])
	_fire_sawblades(current_simulation_time, state["paused"])
	_fire_meteor_staff(current_simulation_time, state["paused"])
	_fire_prism_laser(current_simulation_time, state["paused"])
	_fire_void_orb(current_simulation_time, state["paused"])
	_fire_frost_nova(current_simulation_time, state["paused"])
	if player_hp <= 0.0 and not run_over:
		_finish_run(false)
	if mode_id == "armorless" and not run_over and not _manually_paused and \
			not _pending_armorless_draft_waves.is_empty():
		_open_next_armorless_draft()
	player.controls_enabled = not state["paused"] and not run_over and not _chest_open and not _starting_weapon_choice_open
	_refresh_hud(state)
	queue_redraw()

func _apply_contact_damage(state: Dictionary, current_simulation_time: float) -> void:
	if state["paused"] or run_over:
		return
	var active_contact_ids := {}
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or not components.has("EnemyType") or components.get("IsXpOrb", false):
			continue
		var id: Dictionary = entity.get("id", {})
		active_contact_ids[_entity_key(int(id.get("index", -1)), int(id.get("generation", 0)))] = true
	for enemy_key in _contact_damage_until.keys():
		if not active_contact_ids.has(enemy_key):
			_contact_damage_until.erase(enemy_key)
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false):
			if str(components.get("EnemyType", "")) != "enemy_projectile":
				continue
			var projectile_transform: Dictionary = components["Transform2D"]
			var projectile_position := Vector2(float(projectile_transform["x"]), float(projectile_transform["y"]))
			var projectile: Dictionary = components.get("Projectile", {})
			var projectile_distance := player_contact_radius + float(projectile.get("radius", 0.0))
			if player.global_position.distance_squared_to(projectile_position) > projectile_distance * projectile_distance:
				continue
			_take_enemy_damage(float(projectile.get("damage", shooter_projectile_damage)))
			var projectile_id: Dictionary = entity["id"]
			simulation.despawn(int(projectile_id["index"]), int(projectile_id["generation"]))
			return
		if not components.has("EnemyType") or components.get("IsXpOrb", false):
			continue
		var transform: Dictionary = components["Transform2D"]
		var enemy_position := Vector2(float(transform["x"]), float(transform["y"]))
		var contact_distance := player_contact_radius + float(components.get("CollisionRadius", 12.0))
		if player.global_position.distance_squared_to(enemy_position) > contact_distance * contact_distance:
			continue
		var id: Dictionary = entity.get("id", {})
		var enemy_key := _entity_key(int(id.get("index", -1)), int(id.get("generation", 0)))
		if current_simulation_time < float(_contact_damage_until.get(enemy_key, -INF)):
			continue
		_take_enemy_damage(contact_damage_per_hit)
		_contact_damage_until[enemy_key] = current_simulation_time + body_contact_cooldown_seconds

func _update_shooter_attacks(current_simulation_time: float, paused: bool) -> void:
	if paused or run_over:
		return
	var active_shooters: Dictionary = {}
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("EnemyType", "") != "shooter":
			continue
		var id: Dictionary = entity["id"]
		var key := _entity_key(int(id["index"]), int(id["generation"]))
		active_shooters[key] = true
		var transform: Dictionary = components["Transform2D"]
		var origin := Vector2(float(transform["x"]), float(transform["y"]))
		if not _shooter_attacks.has(key):
			_shooter_attacks[key] = {
				"phase": "telegraph",
				"aim": player.global_position,
				"fire_at": current_simulation_time + shooter_telegraph_seconds,
				"origin": origin,
			}
		var attack: Dictionary = _shooter_attacks[key]
		attack["origin"] = origin
		if str(attack["phase"]) == "telegraph":
			if current_simulation_time < float(attack["fire_at"]):
				continue
			var aim: Vector2 = attack["aim"]
			var direction := (aim - origin).normalized()
			if direction == Vector2.ZERO:
				direction = Vector2.RIGHT
			simulation.spawn_projectile("enemy_projectile", origin, direction * shooter_projectile_speed,
					shooter_projectile_damage, shooter_projectile_radius, shooter_projectile_lifetime)
			attack["phase"] = "waiting"
			attack["fire_at"] = current_simulation_time + shooter_fire_interval_seconds
		elif current_simulation_time >= float(attack["fire_at"]):
			attack["phase"] = "telegraph"
			attack["aim"] = player.global_position
			attack["fire_at"] = current_simulation_time + shooter_telegraph_seconds
	for shooter_key in _shooter_attacks.keys():
		if not active_shooters.has(shooter_key):
			_shooter_attacks.erase(shooter_key)

func _update_exploder_attacks(current_simulation_time: float, paused: bool) -> void:
	if paused or run_over:
		return
	var active_exploders: Dictionary = {}
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("EnemyType", "") != "exploder":
			continue
		var id: Dictionary = entity["id"]
		var key := _entity_key(int(id["index"]), int(id["generation"]))
		active_exploders[key] = true
		if _exploder_attacks.has(key) and str(_exploder_attacks[key].get("phase", "")) == "detonated":
			continue
		var transform: Dictionary = components["Transform2D"]
		var origin := Vector2(float(transform["x"]), float(transform["y"]))
		var exploder_contact_radius := float(components.get("CollisionRadius", 12.0))
		if not _exploder_attacks.has(key):
			var trigger_distance := player_contact_radius + exploder_contact_radius + exploder_trigger_radius
			if player.global_position.distance_squared_to(origin) > trigger_distance * trigger_distance:
				continue
			_exploder_attacks[key] = {"origin": origin, "detonate_at": current_simulation_time + maxf(0.05, exploder_fuse_seconds)}
		var attack: Dictionary = _exploder_attacks[key]
		attack["origin"] = origin
		if current_simulation_time < float(attack["detonate_at"]):
			continue
		var blast_origin: Vector2 = attack["origin"]
		var blast_distance := player_contact_radius + exploder_blast_radius
		if player.global_position.distance_squared_to(blast_origin) <= blast_distance * blast_distance:
			_take_enemy_damage(exploder_damage)
		simulation.despawn(int(id["index"]), int(id["generation"]))
		attack["phase"] = "detonated"
		kill_count += 1
		_record_enemy_kill("exploder")
		_roll_enemy_chests("exploder", blast_origin)
		if not run_over:
			var healing: float = _equipment_kill_healing(float(simulation.kill_heal_amount(float(components.get("ThreatLevel", 2.0)))))
			player_hp = minf(player_max_hp, player_hp + healing)
			_spawn_xp_drop(blast_origin, _equipment_xp_value(xp_per_enemy))
	for exploder_key in _exploder_attacks.keys():
		if not active_exploders.has(exploder_key):
			_exploder_attacks.erase(exploder_key)

func _update_summoner_attacks(current_simulation_time: float, paused: bool) -> void:
	if paused or run_over:
		return
	var active_summoners: Dictionary = {}
	var active_summons := 0
	var state: Dictionary = simulation.snapshot()
	for sequence in _pending_summon_sequences.keys():
		if int(state["last_sequence"]) >= int(sequence):
			_pending_summon_sequences.erase(sequence)
	for entity in state["entities"]:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("IsXpOrb", false):
			continue
		if str(components.get("EnemyType", "")) == "summoned":
			active_summons += 1
	var free_summon_slots := maxi(0, summoner_max_active_summons - active_summons - _pending_summon_sequences.size())
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("EnemyType", "") != "summoner":
			continue
		var id: Dictionary = entity["id"]
		var key := _entity_key(int(id["index"]), int(id["generation"]))
		active_summoners[key] = true
		var transform: Dictionary = components["Transform2D"]
		var origin := Vector2(float(transform["x"]), float(transform["y"]))
		if not _summoner_attacks.has(key):
			var spawn_position := origin + Vector2.from_angle(_random_float("summoner_spawn_angle") * TAU) * summoner_spawn_radius
			_summoner_attacks[key] = {
				"origin": origin,
				"spawn_position": spawn_position,
				"summon_at": current_simulation_time + maxf(0.05, summoner_warmup_seconds),
			}
		var attack: Dictionary = _summoner_attacks[key]
		attack["origin"] = origin
		if current_simulation_time < float(attack["summon_at"]) or free_summon_slots <= 0:
			continue
		var sequence: int = simulation.spawn_enemy(
			"summoned", 1, attack["spawn_position"], Vector2.ZERO, _enemy_hp_multiplier(wave_director.wave)
		)
		if sequence <= 0:
			continue
		_pending_summon_sequences[sequence] = true
		free_summon_slots -= 1
		attack["summon_at"] = current_simulation_time + maxf(0.05, summoner_cooldown_seconds)
		attack["spawn_position"] = origin + Vector2.from_angle(_random_float("summoner_next_spawn_angle") * TAU) * summoner_spawn_radius
	for summoner_key in _summoner_attacks.keys():
		if not active_summoners.has(summoner_key):
			_summoner_attacks.erase(summoner_key)

func _update_pulse_warden_attacks(current_simulation_time: float, paused: bool) -> void:
	if paused or run_over:
		return
	var active_wardens: Dictionary = {}
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("EnemyType", "") != "mid_boss":
			continue
		var id: Dictionary = entity["id"]
		var key := _entity_key(int(id["index"]), int(id["generation"]))
		active_wardens[key] = true
		var health: Dictionary = components["Health"]
		var health_ratio := float(health["current"]) / maxf(1.0, float(health["maximum"]))
		var phase := 3 if health_ratio <= pulse_warden_phase_three_health_ratio else \
				2 if health_ratio <= pulse_warden_phase_two_health_ratio else 1
		var transform: Dictionary = components["Transform2D"]
		var origin := Vector2(float(transform["x"]), float(transform["y"]))
		if not _pulse_warden_attacks.has(key):
			_pulse_warden_attacks[key] = {"entity_id": id, "phase": phase, "pattern_index": 0,
				"normal_attack_count": 0, "chaos_followup_pending": false,
				"chaos_followup_count": 0, "is_chaos_followup": false,
				"stage": "waiting", "next_attack_at": current_simulation_time + pulse_warden_attack_interval_seconds}
		var attack: Dictionary = _pulse_warden_attacks[key]
		attack["origin"] = origin
		attack["entity_id"] = id
		if int(attack["phase"]) != phase:
			Sfx.play("boss_phase")
			attack["phase"] = phase
			attack["pattern_index"] = 0
			attack["normal_attack_count"] = 0
			attack["chaos_followup_pending"] = false
			attack["chaos_followup_count"] = 0
			attack["is_chaos_followup"] = false
			attack["stage"] = "waiting"
			attack["next_attack_at"] = current_simulation_time + maxf(0.1, pulse_warden_telegraph_seconds)
		if str(attack["stage"]) == "charging":
			if current_simulation_time < float(attack["charge_end_at"]):
				continue
			_finish_boss_attack(attack, current_simulation_time, pulse_warden_attack_interval_seconds,
					pulse_warden_telegraph_seconds)
			_last_target = Vector2(INF, INF)
		elif str(attack["stage"]) == "telegraph":
			if current_simulation_time < float(attack["fire_at"]):
				continue
			_fire_pulse_warden_attack(attack)
			if str(attack["stage"]) == "charging":
				continue
			_finish_boss_attack(attack, current_simulation_time, pulse_warden_attack_interval_seconds,
					pulse_warden_telegraph_seconds)
		elif current_simulation_time >= float(attack["next_attack_at"]):
			var pattern_index: int = int(attack["pattern_index"])
			if _schedule_chaos_attack_pattern(attack, ["radial", "aimed", "charge"]):
				pass
			elif phase == 1:
				attack["pattern"] = "radial"
			elif phase == 2:
				attack["pattern"] = "aimed" if pattern_index % 2 == 0 else "charge"
			else:
				attack["pattern"] = "radial" if pattern_index % 2 == 0 else "charge"
			attack["aim"] = player.global_position
			attack["fire_at"] = current_simulation_time + maxf(0.1, pulse_warden_telegraph_seconds)
			attack["stage"] = "telegraph"
			Sfx.play("boss_telegraph")
	for key in _pulse_warden_attacks.keys():
		if not active_wardens.has(key):
			_pulse_warden_attacks.erase(key)

func _schedule_chaos_attack_pattern(attack: Dictionary, patterns: Array) -> bool:
	if difficulty_id != "chaos":
		attack["is_chaos_followup"] = false
		return false
	var is_followup := bool(attack.get("chaos_followup_pending", false))
	var previous_pattern_index := patterns.find(str(attack.get("last_attack_pattern", "")))
	attack["pattern"] = patterns[(previous_pattern_index + 1) % patterns.size()]
	if is_followup:
		attack["chaos_followup_count"] = int(attack.get("chaos_followup_count", 0)) + 1
		attack["chaos_followup_pending"] = false
	attack["is_chaos_followup"] = is_followup
	return true

func _finish_boss_attack(attack: Dictionary, current_simulation_time: float,
		attack_interval: float, telegraph_duration: float) -> void:
	var was_chaos_followup := bool(attack.get("is_chaos_followup", false))
	attack["stage"] = "waiting"
	attack["is_chaos_followup"] = false
	attack["last_attack_pattern"] = str(attack.get("pattern", ""))
	if was_chaos_followup:
		attack["next_attack_at"] = current_simulation_time + maxf(0.1, attack_interval)
		return
	attack["last_normal_pattern"] = str(attack.get("pattern", ""))
	attack["pattern_index"] = int(attack["pattern_index"]) + 1
	attack["normal_attack_count"] = int(attack.get("normal_attack_count", 0)) + 1
	var should_chain := difficulty_id == "chaos" and int(attack["normal_attack_count"]) % 2 == 0
	attack["chaos_followup_pending"] = should_chain
	var delay := telegraph_duration if should_chain else attack_interval
	attack["next_attack_at"] = current_simulation_time + maxf(0.1, delay)

func _fire_pulse_warden_attack(attack: Dictionary) -> void:
	var origin: Vector2 = attack["origin"]
	var pattern: String = str(attack["pattern"])
	if pattern == "radial":
		var count := maxi(4, pulse_warden_radial_projectile_count)
		for index in range(count):
			var direction := Vector2.from_angle(TAU * float(index) / float(count))
			simulation.spawn_projectile("enemy_projectile", origin, direction * pulse_warden_projectile_speed,
					pulse_warden_projectile_damage, pulse_warden_projectile_radius, pulse_warden_projectile_lifetime)
	elif pattern == "charge":
		var aim: Vector2 = attack["aim"]
		var direction := (aim - origin).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT
		var entity_id: Dictionary = attack["entity_id"]
		var sequence: int = simulation.dash_entity(
			int(entity_id["index"]), int(entity_id["generation"]),
			direction * pulse_warden_charge_speed, pulse_warden_charge_seconds
		)
		if sequence > 0:
			attack["stage"] = "charging"
			attack["charge_end_at"] = float(attack["fire_at"]) + pulse_warden_charge_seconds
	else:
		var aim: Vector2 = attack["aim"]
		var direction := (aim - origin).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT
		var spread_count := 3 if int(attack["phase"]) >= 2 else 1
		for index in range(spread_count):
			var offset := float(index) - float(spread_count - 1) * 0.5
			var shot_direction := direction.rotated(offset * 0.18)
			simulation.spawn_projectile("enemy_projectile", origin, shot_direction * pulse_warden_projectile_speed,
					pulse_warden_projectile_damage, pulse_warden_projectile_radius, pulse_warden_projectile_lifetime)
	if int(attack["phase"]) >= 2:
		_spawn_boss_summon(origin)

func _update_dopamine_core_attacks(current_simulation_time: float, paused: bool) -> void:
	if paused or run_over:
		return
	var active_cores: Dictionary = {}
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("EnemyType", "") != "final_boss":
			continue
		var id: Dictionary = entity["id"]
		var key := _entity_key(int(id["index"]), int(id["generation"]))
		active_cores[key] = true
		var health: Dictionary = components["Health"]
		var health_ratio := float(health["current"]) / maxf(1.0, float(health["maximum"]))
		var phase := 3 if health_ratio <= final_boss_phase_three_health_ratio else \
				2 if health_ratio <= final_boss_phase_two_health_ratio else 1
		var transform: Dictionary = components["Transform2D"]
		var origin := Vector2(float(transform["x"]), float(transform["y"]))
		if not _dopamine_core_attacks.has(key):
			_dopamine_core_attacks[key] = {"phase": phase, "pattern_index": 0,
				"normal_attack_count": 0, "chaos_followup_pending": false,
				"chaos_followup_count": 0, "is_chaos_followup": false,
				"stage": "waiting", "next_attack_at": current_simulation_time + final_boss_attack_interval_seconds}
		var attack: Dictionary = _dopamine_core_attacks[key]
		attack["origin"] = origin
		if int(attack["phase"]) != phase:
			Sfx.play("boss_phase")
			attack["phase"] = phase
			attack["pattern_index"] = 0
			attack["normal_attack_count"] = 0
			attack["chaos_followup_pending"] = false
			attack["chaos_followup_count"] = 0
			attack["is_chaos_followup"] = false
			attack["stage"] = "waiting"
			attack["next_attack_at"] = current_simulation_time + maxf(0.1, final_boss_telegraph_seconds)
		if str(attack["stage"]) == "spiral":
			if current_simulation_time >= float(attack["spiral_next_at"]):
				var count := maxi(6, final_boss_spiral_projectile_count)
				var shot_index: int = int(attack["spiral_shot_index"])
				var angle := float(attack["pattern_index"]) * 0.24 + float(shot_index) * 0.42
				var direction := Vector2.from_angle(angle)
				simulation.spawn_projectile("enemy_projectile", origin, direction * final_boss_projectile_speed,
						final_boss_projectile_damage, final_boss_projectile_radius, final_boss_projectile_lifetime)
				shot_index += 1
				attack["spiral_shot_index"] = shot_index
				if shot_index >= count:
					_finish_boss_attack(attack, current_simulation_time, final_boss_attack_interval_seconds,
							final_boss_telegraph_seconds)
				else:
					attack["spiral_next_at"] = current_simulation_time + maxf(0.02, final_boss_spiral_shot_interval_seconds)
		elif str(attack["stage"]) == "telegraph":
			if current_simulation_time < float(attack["fire_at"]):
				continue
			_fire_dopamine_core_attack(attack)
			if str(attack["stage"]) != "spiral":
				_finish_boss_attack(attack, current_simulation_time, final_boss_attack_interval_seconds,
						final_boss_telegraph_seconds)
		elif current_simulation_time >= float(attack["next_attack_at"]):
			var pattern_index: int = int(attack["pattern_index"])
			var pattern := "ray" if pattern_index % 2 == 0 else "zone"
			if _schedule_chaos_attack_pattern(attack, ["ray", "zone", "spiral", "combined"]):
				pattern = str(attack["pattern"])
			elif phase == 2:
				pattern = "spiral"
			elif phase == 3:
				pattern = "combined"
			attack["pattern"] = pattern
			attack["aim"] = player.global_position
			attack["fire_at"] = current_simulation_time + maxf(0.1, final_boss_telegraph_seconds)
			attack["stage"] = "telegraph"
			Sfx.play("boss_telegraph")
	for key in _dopamine_core_attacks.keys():
		if not active_cores.has(key):
			_dopamine_core_attacks.erase(key)

func _fire_dopamine_core_attack(attack: Dictionary) -> void:
	var origin: Vector2 = attack["origin"]
	var aim: Vector2 = attack["aim"]
	var pattern: String = str(attack["pattern"])
	if pattern == "spiral" or pattern == "combined":
		attack["stage"] = "spiral"
		attack["spiral_shot_index"] = 0
		attack["spiral_next_at"] = float(attack["fire_at"])
		_spawn_boss_summon(origin)
	if pattern == "ray" and _player_inside_final_boss_ray(origin, aim):
		_take_enemy_damage(final_boss_ray_damage)
	elif pattern == "zone" and player.global_position.distance_to(aim) <= final_boss_zone_radius + player_contact_radius:
		_take_enemy_damage(final_boss_zone_damage)
	elif pattern == "combined" and (_player_inside_final_boss_ray(origin, aim) or
			player.global_position.distance_to(aim) <= final_boss_zone_radius):
		_take_enemy_damage(maxf(final_boss_ray_damage, final_boss_zone_damage))

func _player_inside_final_boss_ray(origin: Vector2, aim: Vector2) -> bool:
	var closest_point := Geometry2D.get_closest_point_to_segment(player.global_position, origin, aim)
	return player.global_position.distance_to(closest_point) <= final_boss_ray_width + player_contact_radius

func _spawn_boss_summon(origin: Vector2) -> void:
	var active_summons := _pending_summon_sequences.size()
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if not components.get("IsProjectile", false) and components.get("EnemyType", "") == "summoned":
			active_summons += 1
	if active_summons >= summoner_max_active_summons:
		return
	var spawn_position := origin + Vector2.from_angle(_random_float("boss_summon_angle") * TAU) * summoner_spawn_radius
	var sequence: int = simulation.spawn_enemy(
		"summoned", 1, spawn_position, Vector2.ZERO, _enemy_hp_multiplier(wave_director.wave)
	)
	if sequence > 0:
		_pending_summon_sequences[sequence] = true

func _spawn_split_summons(origin: Vector2, state: Dictionary) -> void:
	for sequence in _pending_summon_sequences.keys():
		if int(state["last_sequence"]) >= int(sequence):
			_pending_summon_sequences.erase(sequence)
	var active_summons := _pending_summon_sequences.size()
	for entity in state["entities"]:
		var components: Dictionary = entity["components"]
		if not components.get("IsProjectile", false) and components.get("EnemyType", "") == "summoned":
			active_summons += 1
	var children := mini(maxi(0, split_on_death_summon_count),
			maxi(0, summoner_max_active_summons - active_summons))
	for index in range(children):
		var direction := Vector2.from_angle(TAU * float(index) / float(children))
		var hp_multiplier := _enemy_hp_multiplier(wave_director.wave) if wave_director != null else 1.0
		var sequence: int = simulation.spawn_enemy(
			"summoned", 1, origin + direction * 18.0, direction, hp_multiplier
		)
		if sequence > 0:
			_pending_summon_sequences[sequence] = true

func _apply_pending_lifesteal(elapsed_active_time: float) -> void:
	if elapsed_active_time <= 0.0 or _pending_lifesteal <= 0.0 or run_over:
		return
	var normal_healing_limit := 10.0 * elapsed_active_time
	var healing := minf(_pending_lifesteal, normal_healing_limit)
	healing += maxf(0.0, _pending_lifesteal - normal_healing_limit) * 0.25
	_pending_lifesteal = 0.0
	var applied_healing := minf(healing, player_max_hp - player_hp)
	player_hp += applied_healing
	if _has_unique_effect("overflow_shield") and healing > applied_healing:
		player_shield = minf(player_max_hp * 0.1, player_shield + (healing - applied_healing) * 0.5)
		_shield_expires_at = player_active_time + 5.0

func _take_player_damage(amount: float) -> void:
	if _health_locked:
		return
	var absorbed := minf(player_shield, amount)
	player_shield -= absorbed
	player_hp = maxf(0.0, player_hp - (amount - absorbed))

func _player_health_decay_amount(active_time_seconds: float, delta_seconds: float) -> float:
	var amount: float = simulation.health_decay_amount(active_time_seconds, delta_seconds)
	if sandbox_diagnostics_enabled:
		var multiplier := sandbox_health_decay_multiplier if is_finite(sandbox_health_decay_multiplier) else 1.0
		amount *= clampf(multiplier, 0.0, 10.0)
	return amount

func _take_enemy_damage(amount: float) -> void:
	var factors: Dictionary = DIFFICULTY_SCRIPT.DATA.get(difficulty_id, DIFFICULTY_SCRIPT.DATA["normal"])
	_take_player_damage(amount * float(factors["enemy_damage"]))

func _refresh_hud(state: Dictionary) -> void:
	if _item_level_feedback.visible and float(state.get("simulation_time", 0.0)) >= _item_level_feedback_expires_at:
		_item_level_feedback.hide()
	_hp_value.text = "HP  %.1f / %.0f%s" % [
		player_hp, player_max_hp, "  •  SHIELD %.1f" % player_shield if player_shield > 0.0 else "",
	]
	_hp_bar.max_value = player_max_hp
	_hp_bar.value = player_hp
	var hp_ratio := player_hp / player_max_hp if player_max_hp > 0.0 else 0.0
	_hp_fill_style.bg_color = Color("#48E69B") if hp_ratio > 0.6 else Color("#FFD447") if hp_ratio > 0.3 else Color("#FF7181")
	_hp_value.add_theme_color_override("font_color", _hp_fill_style.bg_color)
	_xp_value.text = "LV %d  XP %.0f / %.0f" % [player_level, player_xp, player_xp_to_next]
	_xp_bar.max_value = player_xp_to_next
	_xp_bar.value = player_xp
	if wave_director != null:
		_wave_value.text = _wave_status_text()
	_difficulty_value.text = difficulty_id.to_upper()
	_refresh_boss_hud()
	var total_seconds := int(floor(player_active_time))
	_time_value.text = "%02d:%02d" % [total_seconds / 60, total_seconds % 60]
	var equipped_names: Array[String] = []
	var short_names := {"lightning_conductor": "LC", "inferno_sprayer": "IS", "crimson_daggers": "CD", "minigun": "MG"}
	short_names["toxic_cloud"] = "TC"
	short_names["sawblades"] = "SB"
	short_names["meteor_staff"] = "MS"
	var owned_weapons: Array[String] = loadout.owned_weapons()
	_weapon_icon.texture = WEAPON_ICONS.get(owned_weapons[0]) if not owned_weapons.is_empty() else null
	for weapon_id in owned_weapons:
		var label := "%s Lv%d" % [short_names.get(weapon_id, weapon_id), loadout.weapon_level(weapon_id)]
		if loadout.is_evolved(weapon_id):
			label += " EVO"
		equipped_names.append(label)
	_weapon_value.text = "  •  ".join(equipped_names)
	if wave_director != null and wave_director.state == WAVE_DIRECTOR_SCRIPT.State.VICTORY:
		_set_run_status("VICTORY", Color("#48E69B"))
	elif run_over:
		_set_run_status("RUN OVER", Color("#FF7181"))
	elif state["paused"]:
		_set_run_status("PAUSED · ESC" if _manually_paused else "PAUSED", Color("#FFD447"))
	else:
		_set_run_status("IN RUN", Color("#48E69B"))
	if _run_stat_hub != null and (_run_stat_hub_dirty or \
			(_run_stat_hub.detail_open and player_active_time >= _next_run_stat_hub_refresh_at)):
		_run_stat_hub.update_stats(_run_stat_breakdown(), "XP LEVEL %d  ·  RUN BONUSES %d" % [player_level, _xp_level_bonus_count])
		_run_stat_hub_dirty = false
		_next_run_stat_hub_refresh_at = player_active_time + 0.25

func _run_stat_breakdown() -> Dictionary:
	var stat_ids := [
		"damage_pct", "move_speed_pct", "attack_speed_pct", "cooldown_reduction_pct",
		"critical_chance_pct", "critical_damage_pct", "max_hp", "area_pct", "projectile_speed_pct",
		"xp_pct", "pickup_radius_pct", "kill_healing_pct", "lifesteal_pct",
	]
	var stats := {}
	for stat_id in stat_ids:
		var run_value: float = (loadout.global_relic_bonus(stat_id) if loadout != null else 0.0) + _xp_run_stat_bonus(stat_id)
		var equipment_value: float = _equipment_bonus(stat_id)
		var achievement_value := float(_cached_achievement_stat_bonuses.get(stat_id, 0.0))
		var skill_value := float(_cached_skill_stat_bonuses.get(stat_id, 0.0))
		var base_value := 0.0
		var total_value: float = run_value + equipment_value + achievement_value + skill_value
		var total_text := "%+.1f%%" % total_value
		var compact := "%+.1f%%" % total_value
		var source_text := _percentage_source_text(run_value, equipment_value, achievement_value, skill_value)
		var label := str(stat_id).trim_suffix("_pct").replace("_", " ").to_upper()
		match stat_id:
			"damage_pct":
				var damage_multiplier: float = (1.0 + skill_value / 100.0 + achievement_value / 100.0 + equipment_value / 100.0) * (1.0 + run_value / 100.0)
				total_value = damage_multiplier * 100.0
				total_text = "%.1f%%" % total_value
				compact = total_text
				label = "DAMAGE"
			"move_speed_pct":
				if _has_unique_effect("elite_haste") and player_active_time < _elite_haste_expires_at:
					run_value += 15.0
					source_text["run"] = "%+.1f%%" % run_value
				total_value = player.move_speed if is_instance_valid(player) else _base_player_move_speed
				total_text = "%.0f px/s" % total_value
				compact = "%.0f" % total_value
				label = "MOVE SPEED"
			"critical_chance_pct":
				total_value = _critical_chance()
				total_text = "%.1f%%" % total_value
				compact = total_text
				label = "CRIT CHANCE"
			"critical_damage_pct":
				base_value = 150.0
				total_value += base_value
				total_text = "%.0f%%" % total_value
				compact = total_text
				label = "CRIT DAMAGE"
			"max_hp":
				skill_value = float(_cached_skill_stat_bonuses.get("max_hp_pct", 0.0)) * 100.0
				base_value = simulation.initial_player_hp() if simulation != null else 100.0
				total_value = player_max_hp if player_max_hp > 0.0 else base_value * (1.0 + skill_value / 100.0) + equipment_value
				total_text = "%.0f HP" % total_value
				compact = total_text
				label = "MAX HP"
				source_text = _percentage_source_text(run_value, 0.0, achievement_value, skill_value)
				source_text["equipment"] = "%+.0f HP" % equipment_value
			"xp_pct":
				base_value = 100.0
				total_value += base_value
				total_text = "%.1f%%" % total_value
				label = "XP GAIN"
			"pickup_radius_pct":
				base_value = xp_collection_radius
				var current_radius := _xp_pickup_radius(_last_simulation_time)
				total_value = current_radius
				if base_value > 0.0:
					run_value = (current_radius / base_value - 1.0) * 100.0 - equipment_value
					source_text = _percentage_source_text(run_value, equipment_value, achievement_value, skill_value)
				total_text = "%.0f px" % total_value
				label = "XP PICKUP RADIUS"
			"cooldown_reduction_pct":
				total_value = minf(total_value, 90.0)
				total_text = "%+.1f%%" % total_value
				label = "COOLDOWN REDUCTION"
			"attack_speed_pct": label = "ATTACK SPEED"
			"area_pct": label = "AREA"
			"projectile_speed_pct": label = "PROJECTILE SPEED"
			"kill_healing_pct":
				if loadout != null:
					run_value += float(loadout.relic_level("blood_chalice")) * blood_chalice_heal_per_level * 100.0
				total_value = ((1.0 + run_value / 100.0) * (1.0 + equipment_value / 100.0) - 1.0) * 100.0
				total_text = "%+.1f%%" % total_value
				compact = total_text
				label = "KILL HEALING"
				source_text = _percentage_source_text(run_value, equipment_value, achievement_value, skill_value)
			"lifesteal_pct": label = "LIFESTEAL"
		stats[stat_id] = {
			"label": label, "base": base_value, "run": run_value, "equipment": equipment_value,
			"achievements": achievement_value, "skill_tree": skill_value,
			"total": total_value, "total_text": total_text, "compact": compact,
			"source_text": source_text,
		}
	return stats

func _percentage_source_text(run_value: float, equipment_value: float, achievement_value: float, skill_value: float) -> Dictionary:
	return {
		"run": "%+.1f%%" % run_value,
		"equipment": "%+.1f%%" % equipment_value,
		"achievements": "%+.1f%%" % achievement_value,
		"skill_tree": "%+.1f%%" % skill_value,
	}

func _set_run_status(text: String, color: Color) -> void:
	_run_state.text = text
	_run_state.add_theme_color_override("font_color", color)
	_run_state_badge_style.border_color = color

func _style_run_hud() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#10152B")
	panel_style.border_color = Color("#293354")
	panel_style.set_border_width_all(1)
	panel_style.border_width_left = 3
	panel_style.border_color = Color("#37E8F5")
	panel_style.set_corner_radius_all(0)
	panel_style.content_margin_left = 5.0
	panel_style.content_margin_top = 2.0
	panel_style.content_margin_right = 5.0
	panel_style.content_margin_bottom = 2.0
	$HUD/RunPanel.add_theme_stylebox_override("panel", panel_style)
	var meta_style := panel_style.duplicate() as StyleBoxFlat
	meta_style.border_color = Color("#C25BFF")
	meta_style.border_width_left = 1
	$HUD/MetaPanel.add_theme_stylebox_override("panel", meta_style)
	_run_state_badge_style = StyleBoxFlat.new()
	_run_state_badge_style.bg_color = Color("#10152B")
	_run_state_badge_style.border_color = Color("#48E69B")
	_run_state_badge_style.set_border_width_all(1)
	_run_state_badge_style.set_corner_radius_all(0)
	_run_state_badge_style.content_margin_left = 3.0
	_run_state_badge_style.content_margin_top = 1.0
	_run_state_badge_style.content_margin_right = 3.0
	_run_state_badge_style.content_margin_bottom = 1.0
	$HUD/MetaPanel/MetaRow/RunStateBadge.add_theme_stylebox_override("panel", _run_state_badge_style)
	var bar_background := StyleBoxFlat.new()
	bar_background.bg_color = Color("#293354")
	bar_background.set_corner_radius_all(0)
	_hp_bar.add_theme_stylebox_override("background", bar_background)
	_xp_bar.add_theme_stylebox_override("background", bar_background)
	_hp_fill_style = StyleBoxFlat.new()
	_hp_fill_style.bg_color = Color("#48E69B")
	_hp_fill_style.set_corner_radius_all(0)
	_hp_bar.add_theme_stylebox_override("fill", _hp_fill_style)
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = Color("#37E8F5")
	xp_fill.set_corner_radius_all(0)
	_xp_bar.add_theme_stylebox_override("fill", xp_fill)

func _refresh_boss_hud() -> void:
	_boss_panel.visible = false
	for entity in _entities:
		var components: Dictionary = entity["components"]
		var enemy_type: String = components.get("EnemyType", "")
		if enemy_type != "mid_boss" and enemy_type != "final_boss":
			continue
		var health: Dictionary = components["Health"]
		var current_hp := float(health["current"])
		var maximum_hp := float(health["maximum"])
		var boss_label := "FINAL BOSS"
		if enemy_type == "mid_boss":
			var health_ratio := current_hp / maxf(1.0, maximum_hp)
			var phase := 3 if health_ratio <= pulse_warden_phase_three_health_ratio else \
					2 if health_ratio <= pulse_warden_phase_two_health_ratio else 1
			boss_label = "PULSE WARDEN  •  PHASE %d" % phase
		else:
			var health_ratio := current_hp / maxf(1.0, maximum_hp)
			var phase := 3 if health_ratio <= final_boss_phase_three_health_ratio else \
					2 if health_ratio <= final_boss_phase_two_health_ratio else 1
			boss_label = "DOPAMINE CORE  •  PHASE %d" % phase
		_boss_value.text = "%s  %.0f / %.0f" % [boss_label, current_hp, maximum_hp]
		_boss_hp_bar.max_value = maximum_hp
		_boss_hp_bar.value = current_hp
		_boss_panel.visible = true
		return

func _collect_nearby_xp_orbs(state: Dictionary) -> void:
	if state["paused"] or run_over:
		return
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if not components.get("IsXpOrb", false):
			continue
		var id: Dictionary = entity["id"]
		var key := _entity_key(int(id["index"]), int(id["generation"]))
		if _pending_xp_orbs.has(key):
			if int(state["last_sequence"]) < int(_pending_xp_orbs[key]):
				continue
			_pending_xp_orbs.erase(key)
		var transform: Dictionary = components["Transform2D"]
		var orb_position := Vector2(float(transform["x"]), float(transform["y"]))
		var pickup_radius := _xp_pickup_radius(float(state["simulation_time"]))
		if player.global_position.distance_squared_to(orb_position) > pickup_radius * pickup_radius:
			continue
		var sequence: int = simulation.collect_xp_orb(int(id["index"]), int(id["generation"]))
		if sequence > 0:
			_pending_xp_orbs[key] = sequence

func _xp_pickup_radius(current_simulation_time: float) -> float:
	var pickup_radius_bonus_pct: float = _equipment_bonus("pickup_radius_pct") + loadout.global_relic_bonus("pickup_radius_pct") + _xp_run_stat_bonus("pickup_radius_pct")
	return xp_collection_radius * (1.0 + pickup_radius_bonus_pct / 100.0)

func _update_magnet_heart_pulse(state: Dictionary, elapsed_active_time: float) -> void:
	if loadout.relic_level("magnet_heart") < loadout.MAX_LEVEL or run_over:
		if _magnet_heart_impulse_expires_at > 0.0:
			simulation.stop_xp_orb_attraction()
		_magnet_heart_impulse_expires_at = 0.0
		_magnet_heart_next_pulse_at = -1.0
		return
	if not is_finite(magnet_heart_level_five_pulse_interval_seconds) or \
			magnet_heart_level_five_pulse_interval_seconds <= 0.0 or \
			not is_finite(magnet_heart_level_five_pulse_duration_seconds) or \
			magnet_heart_level_five_pulse_duration_seconds <= 0.0:
		if _magnet_heart_impulse_expires_at > 0.0:
			simulation.stop_xp_orb_attraction()
		_magnet_heart_impulse_expires_at = 0.0
		_magnet_heart_next_pulse_at = -1.0
		return
	if bool(state["paused"]):
		return
	var simulation_time := float(state["simulation_time"])
	if _magnet_heart_next_pulse_at < 0.0:
		_magnet_heart_next_pulse_at = simulation_time + magnet_heart_level_five_pulse_interval_seconds
	if _magnet_heart_impulse_expires_at > 0.0 and simulation_time >= _magnet_heart_impulse_expires_at:
		simulation.stop_xp_orb_attraction()
		_magnet_heart_impulse_expires_at = 0.0
	while simulation_time >= _magnet_heart_next_pulse_at:
		_magnet_heart_next_pulse_at += magnet_heart_level_five_pulse_interval_seconds
		if _magnet_heart_impulse_expires_at <= 0.0:
			_magnet_heart_impulse_expires_at = simulation_time + magnet_heart_level_five_pulse_duration_seconds
	if _magnet_heart_impulse_expires_at > simulation_time and elapsed_active_time > 0.0:
		simulation.attract_xp_orbs(player.global_position,
			xp_collection_radius * maxf(1.0, magnet_heart_level_five_radius_multiplier),
			magnet_heart_level_five_acceleration, magnet_heart_level_five_max_speed, elapsed_active_time)

func _add_xp(amount: float) -> void:
	player_xp += amount
	var leveled_up := false
	while player_xp >= player_xp_to_next:
		player_xp -= player_xp_to_next
		player_level += 1
		player_xp_to_next = xp_base_to_next_level + xp_growth_per_level * float(player_level - 1)
		_apply_xp_level_stat_bonus()
		leveled_up = true
	if leveled_up:
		_run_stat_hub_dirty = true

func _apply_xp_level_stat_bonus() -> void:
	var stat_id: String = XP_LEVEL_STAT_ROTATION[_xp_level_bonus_count % XP_LEVEL_STAT_ROTATION.size()]
	var previous_value := float(_xp_run_stat_bonuses.get(stat_id, 0.0))
	_xp_run_stat_bonuses[stat_id] = previous_value + 1.0
	_xp_level_bonus_count += 1
	if stat_id == "max_hp":
		var health_ratio := player_hp / player_max_hp if player_max_hp > 0.0 else 1.0
		player_max_hp *= 1.01
		player_hp = player_max_hp * health_ratio
	elif stat_id == "move_speed_pct":
		_refresh_player_move_speed()

func _xp_run_stat_bonus(stat_id: String) -> float:
	var bonus_count := float(_xp_run_stat_bonuses.get(stat_id, 0.0))
	if stat_id == "max_hp":
		return (pow(1.01, bonus_count) - 1.0) * 100.0
	return bonus_count

func open_chest(options: Array) -> bool:
	var family := ""
	if not options.is_empty() and options[0] is Dictionary:
		var offer_id := str(options[0].get("id", ""))
		var separator := offer_id.find(":")
		if separator > 0:
			family = offer_id.left(separator)
		if family == "evolution":
			family = "weapon"
	return _open_chest(options, _chest_heading(family))

func open_chest_family(family: String) -> bool:
	return _open_chest(loadout.offers(family), _chest_heading(family))

func _chest_heading(family: String) -> String:
	if family == "weapon":
		return "WEAPON CHEST — CHOOSE ONE"
	if family == "relic":
		return "RELIC CHEST — CHOOSE ONE"
	return "CHEST — CHOOSE ONE"

func _open_chest(options: Array, heading: String) -> bool:
	if simulation == null or run_over or _chest_open:
		return false
	if _run_stat_hub != null:
		_run_stat_hub.set_detail_open(false)
	var heading_upper := heading.to_upper()
	var family := "weapon" if heading_upper.contains("WEAPON") else "relic" if heading_upper.contains("RELIC") else ""
	var reroll_available := not _first_reward_chest_opened and _has_unique_effect("free_first_chest_reroll") and \
		family in ["weapon", "relic"]
	if reroll_available:
		var excluded_ids: Array[String] = []
		for option in options:
			excluded_ids.append(str(option.get("id", "")))
		reroll_available = loadout.offers(family, excluded_ids, options.size()).size() == options.size()
	if not _chest_choice.present(options, options.size(), heading, reroll_available):
		return false
	if not _starting_weapon_choice_open:
		Sfx.play("chest_open")
	_chest_open = true
	_active_chest_options = options.duplicate(true)
	_active_chest_heading = heading
	if not _starting_weapon_choice_open:
		_first_reward_chest_opened = true
		_free_first_chest_reroll_available = reroll_available
	simulation.pause()
	if _auto_select_first_chest:
		_chest_choice.call_deferred("choose_first_option")
	return true

func _on_chest_option_selected(option_id: String) -> void:
	if _starting_weapon_choice_open:
		if loadout.choose_starting_weapon(option_id.trim_prefix("start:")):
			Sfx.play("chest_reward")
			_starting_weapon_choice_open = false
			simulation.resume()
		else:
			Sfx.play("ui_error")
			_chest_choice.present(loadout.starting_weapon_options(), 2, "CHOOSE YOUR STARTING WEAPON")
		return
	if _chest_open and _active_chest_heading.begins_with("ARMORLESS DRAFT"):
		_choose_armorless_draft_option(option_id)
		return
	if _chest_open and not _is_active_chest_option(option_id):
		Sfx.play("ui_error")
		_chest_choice.present(_active_chest_options, _active_chest_options.size(), _active_chest_heading,
				_free_first_chest_reroll_available)
		return
	var offer_parts := option_id.split(":", false, 1)
	var item_family := str(offer_parts[0]) if offer_parts.size() == 2 else ""
	var item_id := str(offer_parts[1]) if offer_parts.size() == 2 else ""
	var previous_item_level := _loadout_item_level(item_family, item_id)
	var previous_magnet_heart_level: int = loadout.relic_level("magnet_heart")
	var applied: bool = loadout.apply_offer(option_id)
	if not applied:
		Sfx.play("ui_error")
		if _chest_open:
			_chest_choice.present(_active_chest_options, _active_chest_options.size(), _active_chest_heading,
					_free_first_chest_reroll_available)
		return
	_chest_open = false
	_run_stat_hub_dirty = true
	_active_chest_options.clear()
	_free_first_chest_reroll_available = false
	Sfx.play("relic_pickup" if item_family == "relic" else "chest_reward")
	if previous_item_level >= 0:
		_show_item_level_feedback(item_family, item_id, previous_item_level)
	if option_id == "relic:magnet_heart" and previous_magnet_heart_level < loadout.MAX_LEVEL and \
			loadout.relic_level("magnet_heart") >= loadout.MAX_LEVEL and \
			is_finite(magnet_heart_level_five_pulse_interval_seconds) and magnet_heart_level_five_pulse_interval_seconds > 0.0:
		_magnet_heart_next_pulse_at = float(simulation.snapshot()["simulation_time"]) + magnet_heart_level_five_pulse_interval_seconds
	chest_option_chosen.emit(option_id)
	simulation.resume()
	_complete_pending_victory()

func _is_active_chest_option(option_id: String) -> bool:
	for option in _active_chest_options:
		if str(option.get("id", "")) == option_id:
			return true
	return false

func _choose_armorless_draft_option(option_id: String) -> void:
	if not _is_active_chest_option(option_id) or armorless_run_state == null:
		_chest_choice.present(_active_chest_options, _active_chest_options.size(), _active_chest_heading)
		return
	var previous_max_hp_bonus := _equipment_bonus("max_hp")
	var selected_index := -1
	for index in range(_active_chest_options.size()):
		if str(_active_chest_options[index]["id"]) == option_id:
			selected_index = index
			break
	if not armorless_run_state.select_draft_option(selected_index):
		_chest_choice.present(_active_chest_options, _active_chest_options.size(), _active_chest_heading)
		return
	player_max_hp += (_equipment_bonus("max_hp") - previous_max_hp_bonus) * (1.0 + _xp_run_stat_bonus("max_hp") / 100.0)
	player_hp = minf(player_hp, player_max_hp)
	_refresh_persistent_bonuses()
	_chest_open = false
	_active_chest_options.clear()
	_active_chest_heading = "CHEST — CHOOSE ONE"
	chest_option_chosen.emit(option_id)
	simulation.resume()

func _open_next_armorless_draft() -> void:
	if _pending_armorless_draft_waves.is_empty() or armorless_run_state == null or run_over:
		return
	var completed_wave: int = _pending_armorless_draft_waves.pop_front()
	if armorless_run_state.award_wave_flux(completed_wave) <= 0:
		push_error("Armorless Flux reward was rejected for completed wave %d" % completed_wave)
		return
	var equipment: Array[Dictionary] = _armorless_equipment_generator.generate_armorless_draft(
		_run_id, difficulty_id, completed_wave
	)
	if not armorless_run_state.set_draft(equipment):
		push_error("Armorless equipment draft was rejected for completed wave %d" % completed_wave)
		return
	var options: Array[Dictionary] = []
	for item in equipment:
		options.append(_armorless_equipment_offer(item))
	var heading := "ARMORLESS DRAFT  ·  WAVE %d  ·  %d FLUX" % [completed_wave, armorless_run_state.flux()]
	if not _chest_choice.present(options, options.size(), heading):
		push_error("Armorless equipment draft could not be displayed")
		return
	_chest_open = true
	_active_chest_options = options
	_active_chest_heading = heading
	simulation.pause()
	if _auto_select_first_chest:
		_chest_choice.call_deferred("choose_first_option")

func _armorless_equipment_offer(item: Dictionary) -> Dictionary:
	var title := "%s · %s" % [str(item["rarity"]).to_upper(), str(item["slot"]).to_upper()]
	var description := "TEMPORARY EQUIPMENT\n"
	for line in item["stat_lines"]:
		var stat_id := str(line["stat_id"])
		var value := EQUIPMENT_GENERATOR_SCRIPT.stat_value(
			stat_id, float(line["roll_percentile"]), int(line["enhancement_level"])
		)
		description += "%s\n" % EQUIPMENT_GENERATOR_SCRIPT.stat_label(stat_id, value)
	return {
		"id": "armorless:%s" % str(item["instance_id"]),
		"title": title,
		"description": description.strip_edges(),
		"icon": "res://assets/icons/catalog/equipment_%s.png" % str(item["slot"]),
	}

func _reroll_first_chest() -> void:
	if not _chest_open or not _free_first_chest_reroll_available or _free_first_chest_reroll_used:
		return
	var excluded_ids: Array[String] = []
	for option in _active_chest_options:
		excluded_ids.append(str(option.get("id", "")))
	var heading_upper := _active_chest_heading.to_upper()
	var family := "weapon" if heading_upper.contains("WEAPON") else "relic" if heading_upper.contains("RELIC") else ""
	var rerolled_options: Array[Dictionary] = loadout.offers(family, excluded_ids, _active_chest_options.size())
	_free_first_chest_reroll_available = false
	if rerolled_options.size() != _active_chest_options.size():
		_chest_choice.present(_active_chest_options, _active_chest_options.size(), _active_chest_heading)
		return
	_free_first_chest_reroll_used = true
	_active_chest_options = rerolled_options
	_chest_choice.present(_active_chest_options, _active_chest_options.size(), _active_chest_heading)

func _loadout_item_level(family: String, item_id: String) -> int:
	if family == "weapon":
		return loadout.weapon_level(item_id)
	if family == "relic":
		return loadout.relic_level(item_id)
	return -1

func _show_item_level_feedback(family: String, item_id: String, previous_level: int) -> void:
	var level := _loadout_item_level(family, item_id)
	if level <= previous_level:
		return
	var item_name := item_id.replace("_", " ").to_upper()
	for item in loadout.owned_item_details(family):
		if str(item.get("id", "")) == item_id:
			item_name = str(item.get("name", item_name)).to_upper()
			break
	var action := "ACQUIRED" if previous_level == 0 else "LEVEL UP"
	_item_level_feedback_label.text = "%s  ·  %s  ·  LV %d" % [action, item_name, level]
	_item_level_feedback_label.add_theme_color_override("font_color",
			Color("#37E8F5") if previous_level == 0 else Color("#48E69B"))
	_item_level_feedback.show()
	_item_level_feedback_expires_at = float(simulation.snapshot().get("simulation_time", 0.0)) + 1.75

func _show_effect_feedback(message: String) -> void:
	_item_level_feedback_label.text = message
	_item_level_feedback_label.add_theme_color_override("font_color", Color("#FFD447"))
	_item_level_feedback.show()
	_item_level_feedback_expires_at = float(simulation.snapshot().get("simulation_time", 0.0)) + 1.75

func _complete_pending_victory() -> void:
	if _victory_pending and not _chest_open and _world_chests.is_empty():
		_victory_pending = false
		_finish_run(true)

func _finish_run(victory: bool) -> void:
	if run_over:
		return
	run_over = true
	simulation.pause()
	_run_result_overlay.visible = true
	var reward := {}
	var armorless_record := {}
	if mode_id == "armorless" and armorless_run_state != null:
		if progression_service != null and progression_service.can_save_profile() and \
			progression_service.has_method("record_armorless_result"):
			armorless_record = progression_service.record_armorless_result(
				difficulty_id, wave_director.wave, player_active_time, kill_count
			)
		if progression_service != null and progression_service.can_save_profile() and \
			progression_service.has_method("award_armorless_run"):
			reward = progression_service.award_armorless_run(
				_run_id, wave_director.wave, kill_count, difficulty_id, _run_achievement_metrics()
			)
		armorless_run_state.end_run()
		_pending_armorless_draft_waves.clear()
	elif progression_service != null and progression_service.can_save_profile():
		reward = progression_service.award_survival_run(
			_run_id, wave_director.wave, victory, kill_count, difficulty_id, _run_achievement_metrics()
		)
	_run_result.show_result(victory, wave_director.wave, player_active_time, kill_count, reward, armorless_record)

func _run_achievement_metrics() -> Dictionary:
	var evolved_weapons := 0
	for weapon_id in loadout.owned_weapons():
		if loadout.is_evolved(weapon_id):
			evolved_weapons += 1
	var run_metrics := {
		"max_weapon_loadout": loadout.owned_weapons().size(),
		"max_relic_loadout": loadout.owned_relics().size(),
		"evolutions_in_run": evolved_weapons,
	}
	for enemy_type in ENEMY_DEATH_TYPES:
		run_metrics["enemy_kills_%s" % enemy_type] = int(_enemy_kills_by_type.get(enemy_type, 0))
	for weapon_id in WEAPON_DAMAGE_IDS:
		run_metrics["weapon_damage_%s" % weapon_id] = float(_weapon_damage_by_id.get(weapon_id, 0.0))
		run_metrics["weapon_kills_%s" % weapon_id] = int(_weapon_kills_by_id.get(weapon_id, 0))
		run_metrics["max_weapon_level_%s" % weapon_id] = loadout.weapon_level(weapon_id)
		run_metrics["evolutions_%s" % weapon_id] = 1 if loadout.is_evolved(weapon_id) else 0
	for affix_id in ELITE_AFFIX_ACHIEVEMENT_IDS.values():
		run_metrics["elite_affix_kills_%s" % affix_id] = int(_elite_affix_kills.get(affix_id, 0))
	for relic_id in RELIC_ACHIEVEMENT_IDS:
		run_metrics["max_relic_level_%s" % relic_id] = loadout.relic_level(relic_id)
	return run_metrics

func _record_enemy_kill(enemy_type: String, affix: String = "") -> void:
	if enemy_type in ENEMY_DEATH_TYPES:
		_enemy_kills_by_type[enemy_type] = int(_enemy_kills_by_type.get(enemy_type, 0)) + 1
	if enemy_type == "elite":
		for affix_id in affix.split("+"):
			if ELITE_AFFIX_ACHIEVEMENT_IDS.has(affix_id):
				var metric_id: String = ELITE_AFFIX_ACHIEVEMENT_IDS[affix_id]
				_elite_affix_kills[metric_id] = int(_elite_affix_kills.get(metric_id, 0)) + 1

func _record_weapon_damage(source_type: String, amount: float) -> void:
	if not is_finite(amount) or amount <= 0.0:
		return
	var weapon_id := _weapon_id_for_source_type(source_type)
	if weapon_id in WEAPON_DAMAGE_IDS:
		_weapon_damage_by_id[weapon_id] = float(_weapon_damage_by_id.get(weapon_id, 0.0)) + amount
		if sandbox_diagnostics_enabled:
			var source_id := source_type.get_slice(":", 0)
			_sandbox_damage_by_source[source_id] = float(_sandbox_damage_by_source.get(source_id, 0.0)) + amount

func _record_weapon_kill(source_type: String) -> void:
	var weapon_id := _weapon_id_for_source_type(source_type)
	if weapon_id in WEAPON_DAMAGE_IDS:
		_weapon_kills_by_id[weapon_id] = int(_weapon_kills_by_id.get(weapon_id, 0)) + 1

func _weapon_id_for_source_type(source_type: String) -> String:
	var normalized_source := source_type.get_slice(":", 0)
	var weapon_id := str(WEAPON_IMPACT_SOURCE_IDS.get(normalized_source, ""))
	if normalized_source in ["lightning_primary", "lightning_arc"]:
		weapon_id = "lightning_conductor"
	return weapon_id

func _restart_run() -> void:
	var replacement: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	replacement.progression_service = progression_service
	replacement.difficulty_id = difficulty_id
	replacement.mode_id = mode_id
	get_tree().root.add_child(replacement)
	get_tree().current_scene = replacement
	queue_free()

func _quit_after_run() -> void:
	if not run_over:
		return
	var error := get_tree().change_scene_to_file("res://scenes/launch_menu.tscn")
	if error != OK:
		push_error("Could not return to launch menu after the run: %s" % error_string(error))

func _roll_enemy_chests(enemy_type: String, position: Vector2) -> void:
	var eligible_families: Array[String] = []
	if not loadout.offers("weapon").is_empty():
		eligible_families.append("weapon")
	if not loadout.offers("relic").is_empty():
		eligible_families.append("relic")
	var is_boss := enemy_type == "mid_boss" or enemy_type == "final_boss"
	var is_elite := enemy_type == "elite"
	for family in _chest_director.roll_drops(player_active_time, eligible_families, is_elite, is_boss):
		_world_chests.append({"family": family, "position": _find_chest_drop_position(position)})

func _spawn_xp_drop(position: Vector2, xp_value: float) -> int:
	var drop_position := _find_xp_drop_position(position)
	var entity_id: int = simulation.spawn_xp_orb(drop_position, xp_value)
	if entity_id > 0:
		_reserved_xp_drop_positions.append(drop_position)
	return entity_id

func _find_xp_drop_position(origin: Vector2) -> Vector2:
	var chest_positions: Array[Vector2] = []
	for chest in _world_chests:
		chest_positions.append(chest["position"])
	return _find_spaced_drop_position(origin, false, chest_positions, _active_xp_drop_positions())

func _find_chest_drop_position(origin: Vector2) -> Vector2:
	var chest_positions: Array[Vector2] = []
	for chest in _world_chests:
		chest_positions.append(chest["position"])
	return _find_spaced_drop_position(origin, true, chest_positions, _active_xp_drop_positions())

func _find_spaced_drop_position(origin: Vector2, is_chest: bool,
		chest_positions: Array[Vector2], xp_positions: Array[Vector2]) -> Vector2:
	for ring in range(0, 17):
		for direction in PICKUP_SPACING_DIRECTIONS:
			var candidate: Vector2 = origin if ring == 0 else origin + direction * PICKUP_SPACING_STEP * ring
			var blocked := false
			for chest_position in chest_positions:
				if is_chest and candidate.distance_squared_to(chest_position) < PICKUP_SPACING_STEP * PICKUP_SPACING_STEP:
					blocked = true
					break
				if not is_chest and _pickup_sprites_overlap(candidate, XP_SPRITE_SIZE, chest_position, CHEST_SPRITE_SIZE):
					blocked = true
					break
			if blocked:
				continue
			for xp_position in xp_positions:
				if is_chest and _pickup_sprites_overlap(candidate, CHEST_SPRITE_SIZE, xp_position, XP_SPRITE_SIZE):
					blocked = true
					break
			if not blocked:
				return candidate
	return origin + Vector2(CHEST_SPRITE_SIZE + XP_SPRITE_SIZE, 0.0)

func _pickup_sprites_overlap(first: Vector2, first_size: float, second: Vector2, second_size: float) -> bool:
	var half_size_sum := (first_size + second_size) * 0.5
	return absf(first.x - second.x) < half_size_sum and absf(first.y - second.y) < half_size_sum

func _active_xp_drop_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if simulation == null:
		return positions
	for entity in simulation.snapshot().get("entities", []):
		var components: Dictionary = entity.get("components", {})
		if not components.get("IsXpOrb", false):
			continue
		var transform: Dictionary = components.get("Transform2D", {})
		var active_position := Vector2(float(transform.get("x", 0.0)), float(transform.get("y", 0.0)))
		positions.append(active_position)
		_remove_reserved_xp_position(active_position)
	for reserved_position in _reserved_xp_drop_positions:
		if not positions.has(reserved_position):
			positions.append(reserved_position)
	return positions

func _remove_reserved_xp_position(position: Vector2) -> void:
	for index in range(_reserved_xp_drop_positions.size() - 1, -1, -1):
		if _reserved_xp_drop_positions[index].distance_squared_to(position) <= 1.0:
			_reserved_xp_drop_positions.remove_at(index)

func _collect_nearby_chests(state: Dictionary) -> void:
	if state["paused"] or run_over or _chest_open:
		return
	for index in range(_world_chests.size()):
		var chest: Dictionary = _world_chests[index]
		if player.global_position.distance_squared_to(chest["position"]) > chest_collection_radius * chest_collection_radius:
			continue
		if open_chest_family(str(chest["family"])):
			_world_chests.remove_at(index)
			return

func _advance_wave_director(delta_seconds: float, paused: bool) -> void:
	if paused or run_over or wave_director == null or not wave_spawning_enabled:
		return
	if wave_director.state == WAVE_DIRECTOR_SCRIPT.State.WAVE:
		var previous_wave: int = wave_director.wave
		var previous_state: int = wave_director.state
		wave_director.advance(delta_seconds)
		if mode_id == "armorless":
			for completed_wave in range(previous_wave, wave_director.wave):
				_pending_armorless_draft_waves.append(completed_wave)
			if previous_state == WAVE_DIRECTOR_SCRIPT.State.WAVE and \
				wave_director.state == WAVE_DIRECTOR_SCRIPT.State.MID_BOSS:
				_pending_armorless_draft_waves.append(wave_director.wave)
			if not _pending_armorless_draft_waves.is_empty():
				return
		if spawn_initial_enemy and player_active_time >= _next_enemy_spawn_time:
			_spawn_wave_enemy()
			_next_enemy_spawn_time = player_active_time + _wave_enemy_spawn_interval()
		_try_spawn_elite()
	elif wave_director.state == WAVE_DIRECTOR_SCRIPT.State.MID_BOSS:
		_spawn_boss_placeholder("mid_boss")
	elif wave_director.state == WAVE_DIRECTOR_SCRIPT.State.FINAL_BOSS:
		_spawn_boss_placeholder("final_boss")

func _spawn_wave_enemy() -> void:
	var angle := _random_float("wave_enemy_spawn_angle") * TAU
	var spawn_position := player.global_position + Vector2.from_angle(angle) * enemy_spawn_radius
	var enemy_type := "chaser"
	if wave_director.wave >= 4 and _random_float("wave_enemy_sprinter_roll") < 0.25:
		enemy_type = "sprinter"
	if wave_director.wave >= 8 and _random_float("wave_enemy_tank_roll") < 0.12:
		enemy_type = "tank"
	if wave_director.wave >= 10 and _random_float("wave_enemy_shooter_roll") < 0.15:
		enemy_type = "shooter"
	if wave_director.wave >= 6 and _random_float("wave_enemy_buffer_roll") < _support_enemy_spawn_chance(0.10):
		enemy_type = "buffer"
	if wave_director.wave >= 8 and _random_float("wave_enemy_exploder_roll") < 0.12:
		enemy_type = "exploder"
	if wave_director.wave >= 10 and _random_float("wave_enemy_shielder_roll") < _support_enemy_spawn_chance(0.10):
		enemy_type = "shielder"
	if wave_director.wave >= 12 and _random_float("wave_enemy_summoner_roll") < _support_enemy_spawn_chance(0.08):
		enemy_type = "summoner"
	var hp_multiplier := _enemy_hp_multiplier(wave_director.wave)
	simulation.spawn_enemy(enemy_type, 1, spawn_position, Vector2.ZERO, hp_multiplier)

func _support_enemy_spawn_chance(base_chance: float) -> float:
	if difficulty_id != "chaos":
		return base_chance
	return clampf(base_chance * chaos_support_spawn_chance_multiplier, 0.0, 1.0)

func _try_spawn_elite() -> void:
	if wave_director == null or wave_director.state != WAVE_DIRECTOR_SCRIPT.State.WAVE or \
			player_active_time < _next_elite_spawn_time or elite_max_active <= 0:
		return
	var active_enemies := 0
	var active_elites := 0
	var active_threat := 0.0
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("IsXpOrb", false):
			continue
		active_enemies += 1
		active_threat += float(components.get("ThreatLevel", 1.0))
		if components.get("EnemyType", "") == "elite":
			active_elites += 1
	if active_elites >= elite_max_active or active_enemies >= maxi(0, _wave_population(wave_director.wave) - 1):
		return
	var wave_threat_budget := float(_wave_population(wave_director.wave))
	if active_threat + 3.0 > wave_threat_budget:
		return
	_next_elite_spawn_time = player_active_time + maxf(0.05, elite_spawn_interval_seconds)
	if _random_float("elite_spawn_roll") > clampf(elite_spawn_chance, 0.0, 1.0):
		return
	var spawn_position := player.global_position + Vector2.from_angle(_random_float("elite_spawn_angle") * TAU) * enemy_spawn_radius
	var hp_multiplier := _enemy_hp_multiplier(wave_director.wave)
	var second_affix_roll := _random_float("chaos_second_elite_affix_roll") if difficulty_id == "chaos" else 0.0
	var affixes := _elite_affixes_for_rolls(_random_float("elite_affix_roll"), second_affix_roll)
	simulation.spawn_enemy("elite", 1, spawn_position, Vector2.ZERO, hp_multiplier, "+".join(affixes))

func _elite_affixes_for_rolls(first_roll: float, second_roll: float) -> PackedStringArray:
	var affixes := PackedStringArray([_elite_affix_for_roll(first_roll)])
	if difficulty_id != "chaos":
		return affixes
	var second_affix := _elite_affix_for_roll(second_roll)
	if second_affix == affixes[0]:
		var affix_order := ["Hasted", "Armored", "Regenerating", "Volatile", "Shielded", "Split-on-Death"]
		second_affix = affix_order[(affix_order.find(second_affix) + 1) % affix_order.size()]
	affixes.append(second_affix)
	return affixes

func _elite_affix_for_roll(roll: float) -> String:
	if roll < 1.0 / 6.0:
		return "Hasted"
	if roll < 2.0 / 6.0:
		return "Armored"
	if roll < 3.0 / 6.0:
		return "Regenerating"
	if roll < 4.0 / 6.0:
		return "Volatile"
	if roll < 5.0 / 6.0:
		return "Shielded"
	return "Split-on-Death"

func _spawn_boss_placeholder(boss_type: String) -> void:
	if not spawn_initial_enemy or _boss_spawn_pending:
		return
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("EnemyType", "") == boss_type:
			return
	var spawn_position := player.global_position + Vector2.RIGHT.rotated(_random_float("boss_spawn_angle") * TAU) * enemy_spawn_radius
	var enemy_hp_factor: float = DIFFICULTY_SCRIPT.DATA.get(difficulty_id, DIFFICULTY_SCRIPT.DATA["normal"])["enemy_hp"]
	simulation.spawn(boss_type, 1, spawn_position, boss_placeholder_hp * enemy_hp_factor, Vector2.ZERO, 25.0)
	_boss_spawn_pending = true

func debug_advance_wave() -> void:
	if wave_director == null or run_over:
		return
	if wave_director.state == WAVE_DIRECTOR_SCRIPT.State.WAVE:
		wave_director.elapsed_in_wave = wave_duration_seconds
		wave_director.advance(0.0)
		if wave_director.state == WAVE_DIRECTOR_SCRIPT.State.MID_BOSS:
			_spawn_boss_placeholder("mid_boss")
		elif wave_director.state == WAVE_DIRECTOR_SCRIPT.State.FINAL_BOSS:
			_spawn_boss_placeholder("final_boss")
	elif wave_director.state == WAVE_DIRECTOR_SCRIPT.State.MID_BOSS:
		_kill_boss_placeholder("mid_boss")
	elif wave_director.state == WAVE_DIRECTOR_SCRIPT.State.FINAL_BOSS:
		_kill_boss_placeholder("final_boss")

func _kill_boss_placeholder(boss_type: String) -> void:
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("EnemyType", "") == boss_type:
			var id: Dictionary = entity["id"]
			simulation.despawn(int(id["index"]), int(id["generation"]))
			_boss_spawn_pending = false
			wave_director.boss_defeated()
			if wave_director.state == WAVE_DIRECTOR_SCRIPT.State.VICTORY:
				_finish_run(true)
			return

func _wave_population(wave_number: int) -> int:
	var progress := float(wave_number - 1) / 23.0
	var proposed_population := roundi(10.0 + 390.0 * pow(progress, 1.5))
	var density_factor: float = DIFFICULTY_SCRIPT.DATA.get(difficulty_id, DIFFICULTY_SCRIPT.DATA["normal"])["density"]
	return maxi(1, roundi(float(proposed_population) * wave_population_scale * density_factor))

func _wave_enemy_spawn_interval() -> float:
	var base_interval := maxf(0.05, enemy_spawn_interval)
	var density_factor: float = DIFFICULTY_SCRIPT.DATA.get(difficulty_id, DIFFICULTY_SCRIPT.DATA["normal"])["density"]
	var spawn_scale := wave_population_scale * density_factor
	if not is_finite(spawn_scale) or spawn_scale <= 0.0:
		return base_interval
	return maxf(0.05, base_interval / spawn_scale)

func _enemy_hp_multiplier(wave_number: int) -> float:
	var wave_factor := minf(pow(WAVE_HP_GROWTH, float(wave_number - 1)), WAVE_HP_CAP)
	var difficulty_factor: float = DIFFICULTY_SCRIPT.DATA.get(difficulty_id, DIFFICULTY_SCRIPT.DATA["normal"])["enemy_hp"]
	return wave_factor * difficulty_factor

func _wave_status_text() -> String:
	match wave_director.state:
		WAVE_DIRECTOR_SCRIPT.State.MID_BOSS:
			return "WAVE 12  •  MID-BOSS"
		WAVE_DIRECTOR_SCRIPT.State.FINAL_BOSS:
			return "WAVE 24  •  FINAL BOSS"
		WAVE_DIRECTOR_SCRIPT.State.VICTORY:
			return "VICTORY"
		_:
			return "WAVE %02d  •  %02d s" % [wave_director.wave, ceili(wave_duration_seconds - wave_director.elapsed_in_wave)]

func _entity_key(index: int, generation: int) -> String:
	return "%d:%d" % [index, generation]

func _fire_lightning_conductor(active_time: float, paused: bool) -> void:
	if not weapon_enabled or loadout.weapon_level("lightning_conductor") == 0 or paused or _chest_open or run_over or lightning_cooldown <= 0.0 or active_time < _next_weapon_time:
		return
	var level: int = loadout.weapon_level("lightning_conductor")
	var chain_count := lightning_chain_count + _weapon_level_addition("lightning_conductor", "chain_count_add", level)
	var damage_multiplier := _weapon_level_multiplier("lightning_conductor", "damage_multiplier", level)
	damage_multiplier *= _weapon_combo_damage_multiplier("lightning_conductor") * _persistent_damage_multiplier()
	damage_multiplier *= _roll_equipment_critical_multiplier()
	var cooldown := lightning_cooldown * _weapon_level_multiplier("lightning_conductor", "cooldown_multiplier", level)
	if loadout.is_evolved("lightning_conductor"):
		_fire_infinite_circuit(active_time, chain_count, damage_multiplier, cooldown)
		_try_evolution_shockwave(lightning_damage * damage_multiplier)
		return
	var targets := _lightning_initial_targets(1)
	if targets.is_empty():
		return
	var target: Dictionary = targets[0]
	var direction: Vector2 = (target["position"] - player.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	_next_lightning_chain_id += 1
	var chain_id := str(_next_lightning_chain_id)
	_lightning_chain_states[chain_id] = {
		"visited_ids": [],
		"reserved_ids": [target["id"]],
		"remaining": chain_count - 1,
		"next_damage": lightning_damage * damage_multiplier * lightning_chain_damage_multiplier,
		"critical_hit": _last_attack_critical_hit,
		"expires_at": active_time + lightning_projectile_lifetime,
	}
	var projectile_sequence: int = simulation.spawn_projectile(
		"lightning_primary:%s" % chain_id, player.global_position + direction * 14.0,
		direction * _equipment_projectile_speed(lightning_projectile_speed), lightning_damage * damage_multiplier,
		_equipment_area(lightning_projectile_radius), lightning_projectile_lifetime,
		2.0, 0.5, 2.0, 0.0, 0.0, 0, 0.0, 0.0, false, 0.0, 1.0, 1.0, 0.0, 0, 1,
		_last_attack_critical_hit
	)
	if projectile_sequence <= 0:
		_lightning_chain_states.erase(chain_id)
		return
	_try_unique_lightning_burst(lightning_damage * damage_multiplier)
	_try_evolution_shockwave(lightning_damage * damage_multiplier)
	_next_weapon_time = active_time + _effective_weapon_cooldown(cooldown)

func _try_thermal_shock(event: Dictionary, entities: Array, active_time: float) -> int:
	if bool(event.get("is_damage_over_time", false)) or float(event.get("amount", 0.0)) <= 0.0:
		return 0
	var source_type := str(event.get("source_type", ""))
	var burn_hits_chilled := source_type in ["inferno_sprayer", "wildfire_sprayer"] and \
			bool(event.get("target_was_chilled", false))
	var chill_hits_burning := source_type in ["frost_nova", "absolute_zero"]
	if not burn_hits_chilled and not chill_hits_burning:
		return 0
	if float(event.get("remaining_health", 0.0)) <= 0.0:
		return 0
	var target_id: Dictionary = event.get("target", {})
	if target_id.is_empty():
		return 0
	var target_key := _entity_key(int(target_id.get("index", -1)), int(target_id.get("generation", -1)))
	if active_time < float(_thermal_shock_next_at.get(target_key, 0.0)):
		return 0
	if chill_hits_burning:
		var has_burn := false
		for entity in entities:
			var id: Dictionary = entity.get("id", {})
			if _entity_key(int(id.get("index", -2)), int(id.get("generation", -2))) != target_key:
				continue
			var components: Dictionary = entity.get("components", {})
			var effects: Array = components.get("DamageOverTimeEffects", [components.get("DamageOverTime", {})])
			for effect in effects:
				has_burn = has_burn or str(effect.get("status_type", "")) == "burn"
			has_burn = float(components.get("Health", {}).get("current", 0.0)) > 0.0 and has_burn
			break
		if not has_burn:
			return 0
	var position: Dictionary = event.get("position", {})
	if position.is_empty():
		return 0
	var sequence: int = simulation.spawn_projectile("thermal_shock",
			Vector2(float(position.get("x", 0.0)), float(position.get("y", 0.0))), Vector2.ZERO,
			float(event["amount"]) * thermal_shock_damage_multiplier,
			thermal_shock_projectile_radius, 0.15)
	if sequence > 0:
		_thermal_shock_next_at[target_key] = active_time + thermal_shock_target_cooldown_seconds
	return sequence

func _try_shatter(event: Dictionary, entities: Array) -> int:
	if bool(event.get("is_damage_over_time", false)) or not bool(event.get("target_was_chilled", false)) or \
			float(event.get("amount", 0.0)) <= 0.0:
		return 0
	if not SHATTER_IMPACT_SOURCE_TYPES.has(str(event.get("source_type", ""))):
		return 0
	var reaction_budget := int(event.get("reaction_budget", 1))
	if reaction_budget <= 0:
		return 0
	var target_id: Dictionary = event.get("target", {})
	var position: Dictionary = event.get("position", {})
	if target_id.is_empty() or position.is_empty():
		return 0
	var origin := Vector2(float(position.get("x", 0.0)), float(position.get("y", 0.0)))
	var primary_id := Vector2i(int(target_id.get("index", -1)), int(target_id.get("generation", -1)))
	var candidates: Array[Dictionary] = []
	var radius_squared := shatter_fragment_radius * shatter_fragment_radius
	var bonus_radius := shatter_fragment_projectile_radius
	for entity in entities:
		var components: Dictionary = entity.get("components", {})
		var id: Dictionary = entity.get("id", {})
		var entity_id := Vector2i(int(id.get("index", -2)), int(id.get("generation", -2)))
		if entity_id == primary_id:
			bonus_radius = maxf(bonus_radius, float(components.get("CollisionRadius", 0.0)))
			continue
		if not _is_targetable_enemy(components):
			continue
		var transform: Dictionary = components.get("Transform2D", {})
		var candidate_position := Vector2(float(transform.get("x", 0.0)), float(transform.get("y", 0.0)))
		var distance_squared := origin.distance_squared_to(candidate_position)
		if distance_squared <= radius_squared:
			candidates.append({"position": candidate_position, "distance_squared": distance_squared})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["distance_squared"] < b["distance_squared"])
	var reaction_chain_id := int(event.get("reaction_chain_id", 0))
	if reaction_chain_id <= 0:
		reaction_chain_id = int(event.get("sequence", 0))
	var spawned := 0
	if float(event.get("remaining_health", 0.0)) > 0.0 and simulation.spawn_projectile(
			"shatter_impact", origin, Vector2.ZERO,
			float(event["amount"]) * shatter_fragment_damage_multiplier,
			bonus_radius, shatter_fragment_lifetime_seconds,
			0.0, 0.0, 0.0, 0.0, 0.0, 0, 0.0, 0.0, false,
			0.0, 1.0, 1.0, 0.0, reaction_chain_id, reaction_budget - 1) > 0:
		spawned += 1
	for index in range(mini(shatter_fragment_count, candidates.size())):
		var target_position: Vector2 = candidates[index]["position"]
		var direction := (target_position - origin).normalized()
		if direction == Vector2.ZERO:
			continue
		var sequence: int = simulation.spawn_projectile("shatter_fragment", origin + direction * 24.0,
				direction * _equipment_projectile_speed(shatter_fragment_speed),
				float(event["amount"]) * shatter_fragment_damage_multiplier,
				_equipment_area(shatter_fragment_projectile_radius), shatter_fragment_lifetime_seconds,
				0.0, 0.0, 0.0, 0.0, 0.0, 0, 0.0, 0.0, false,
				0.0, 1.0, 1.0, 0.0, reaction_chain_id, reaction_budget - 1)
		if sequence > 0:
			spawned += 1
	return spawned

func _try_toxic_ignition(event: Dictionary, active_time: float) -> int:
	if bool(event.get("is_damage_over_time", false)) or float(event.get("amount", 0.0)) <= 0.0 or \
			float(event.get("remaining_health", 0.0)) <= 0.0 or int(event.get("reaction_budget", 1)) <= 0:
		return 0
	var source_type := str(event.get("source_type", ""))
	var applies_burn := source_type in ["inferno_sprayer", "wildfire_sprayer"]
	var applies_poison := source_type in ["toxic_cloud", "pandemic_cloud"]
	if not applies_burn and not applies_poison:
		return 0
	if (applies_burn and not bool(event.get("target_had_poison", false))) or \
			(applies_poison and not bool(event.get("target_had_burn", false))):
		return 0
	var target_id: Dictionary = event.get("target", {})
	var position: Dictionary = event.get("position", {})
	if target_id.is_empty() or position.is_empty():
		return 0
	var target_key := _entity_key(int(target_id.get("index", -1)), int(target_id.get("generation", -1)))
	if active_time < float(_toxic_ignition_next_at.get(target_key, 0.0)):
		return 0
	var reaction_chain_id := int(event.get("reaction_chain_id", 0))
	if reaction_chain_id <= 0:
		reaction_chain_id = int(event.get("sequence", 0))
	if reaction_chain_id <= 0:
		return 0
	var sequence: int = simulation.spawn_projectile("toxic_ignition",
			Vector2(float(position.get("x", 0.0)), float(position.get("y", 0.0))), Vector2.ZERO,
			float(event["amount"]) * TOXIC_IGNITION_DAMAGE_MULTIPLIER,
			0.0, 0.15, 0.0, 0.0, 0.0, TOXIC_IGNITION_RADIUS, 1.0,
			0, 0.0, 0.0, false, 0.0, 1.0, 1.0, 0.0, reaction_chain_id,
			int(event.get("reaction_budget", 1)) - 1)
	if sequence > 0:
		_toxic_ignition_next_at[target_key] = active_time + TOXIC_IGNITION_TARGET_COOLDOWN_SECONDS
	return sequence

func _try_electroplague(event: Dictionary, entities: Array) -> int:
	if bool(event.get("is_damage_over_time", false)) or not bool(event.get("target_had_poison", false)) or \
			float(event.get("amount", 0.0)) <= 0.0:
		return 0
	var source_type := str(event.get("source_type", "")).get_slice(":", 0)
	if not ELECTROPLAGUE_SHOCK_SOURCE_TYPES.has(source_type):
		return 0
	var target_id: Dictionary = event.get("target", {})
	var origin_data: Dictionary = event.get("position", {})
	if target_id.is_empty() or origin_data.is_empty():
		return 0
	var source_key := Vector2i(int(target_id.get("index", -1)), int(target_id.get("generation", -1)))
	var poison: Dictionary = {}
	for entity in entities:
		var id: Dictionary = entity.get("id", {})
		if Vector2i(int(id.get("index", -2)), int(id.get("generation", -2))) != source_key:
			continue
		var components: Dictionary = entity.get("components", {})
		for status in components.get("DamageOverTimeEffects", [components.get("DamageOverTime", {})]):
			if str(status.get("status_type", "")) == "poison":
				poison = status
				break
		break
	if poison.is_empty() or float(poison.get("remaining_seconds", 0.0)) <= 0.0:
		return 0
	var origin := Vector2(float(origin_data["x"]), float(origin_data["y"]))
	var radius_squared := (ELECTROPLAGUE_SPREAD_RADIUS + 0.01) * (ELECTROPLAGUE_SPREAD_RADIUS + 0.01)
	var spread_count := 0
	for entity in entities:
		var id: Dictionary = entity.get("id", {})
		if Vector2i(int(id.get("index", -2)), int(id.get("generation", -2))) == source_key:
			continue
		var components: Dictionary = entity.get("components", {})
		if not _is_targetable_enemy(components):
			continue
		var already_poisoned := false
		for status in components.get("DamageOverTimeEffects", [components.get("DamageOverTime", {})]):
			already_poisoned = already_poisoned or str(status.get("status_type", "")) == "poison"
		if already_poisoned:
			continue
		var transform: Dictionary = components.get("Transform2D", {})
		var candidate := Vector2(float(transform.get("x", 0.0)), float(transform.get("y", 0.0)))
		if origin.distance_squared_to(candidate) > radius_squared:
			continue
		if simulation.apply_damage_over_time(int(id["index"]), int(id["generation"]),
				float(poison["damage_per_tick"]), float(poison["interval_seconds"]),
				float(poison["remaining_seconds"]), "poison") > 0:
			spread_count += 1
	return spread_count

func _try_gravity_collapse(event: Dictionary, entities: Array) -> int:
	if bool(event.get("is_damage_over_time", false)) or float(event.get("amount", 0.0)) <= 0.0 or \
			float(event.get("remaining_health", 0.0)) <= 0.0 or int(event.get("reaction_budget", 1)) <= 0:
		return 0
	if not GRAVITY_COLLAPSE_IMPACT_SOURCE_TYPES.has(str(event.get("source_type", ""))):
		return 0
	var target_id: Dictionary = event.get("target", {})
	var position: Dictionary = event.get("position", {})
	if target_id.is_empty() or position.is_empty():
		return 0
	var target_key := Vector2i(int(target_id.get("index", -1)), int(target_id.get("generation", -1)))
	var origin := Vector2(float(position.get("x", 0.0)), float(position.get("y", 0.0)))
	var target_found := false
	var target_is_gravitated := false
	for entity in entities:
		var components: Dictionary = entity.get("components", {})
		var id: Dictionary = entity.get("id", {})
		if Vector2i(int(id.get("index", -2)), int(id.get("generation", -2))) == target_key:
			if not _is_targetable_enemy(components):
				return 0
			target_found = true
			continue
		if not bool(components.get("IsProjectile", false)) or \
				str(components.get("EnemyType", "")) not in ["void_orb", "event_horizon"]:
			continue
		var field_radius := float(components.get("Projectile", {}).get("attraction_radius", 0.0))
		if field_radius <= 0.0:
			continue
		var transform: Dictionary = components.get("Transform2D", {})
		var field_position := Vector2(float(transform.get("x", 0.0)), float(transform.get("y", 0.0)))
		if origin.distance_squared_to(field_position) <= field_radius * field_radius:
			target_is_gravitated = true
			break
	if not target_found or not target_is_gravitated:
		return 0
	var reaction_chain_id := int(event.get("reaction_chain_id", 0))
	if reaction_chain_id <= 0:
		reaction_chain_id = int(event.get("sequence", 0))
	if reaction_chain_id <= 0:
		return 0
	return simulation.spawn_projectile("gravity_collapse", origin, Vector2.ZERO,
			float(event["amount"]) * GRAVITY_COLLAPSE_DAMAGE_MULTIPLIER,
			0.0, 0.15, 0.0, 0.0, 0.0, GRAVITY_COLLAPSE_RADIUS, 1.0,
			0, 0.0, 0.0, false, 0.0, 1.0, 1.0, 0.0, reaction_chain_id, 0)

func _try_hemorrhage(event: Dictionary) -> int:
	if bool(event.get("is_damage_over_time", false)) or not bool(event.get("critical_hit", false)) or \
			not bool(event.get("target_had_bleed", false)) or float(event.get("amount", 0.0)) <= 0.0:
		return 0
	var target: Dictionary = event.get("target", {})
	if target.is_empty():
		return 0
	return simulation.tick_damage_over_time(int(target.get("index", -1)),
			int(target.get("generation", -1)), "bleed")

func _try_overcharge(event: Dictionary, active_time: float) -> int:
	var source_type := str(event.get("source_type", "")).get_slice(":", 0)
	if bool(event.get("is_damage_over_time", false)) or not ELECTROPLAGUE_SHOCK_SOURCE_TYPES.has(source_type) or \
			float(event.get("amount", 0.0)) <= 0.0 or float(event.get("remaining_health", 0.0)) <= 0.0:
		return 0
	var target_id: Dictionary = event.get("target", {})
	var position: Dictionary = event.get("position", {})
	if target_id.is_empty() or position.is_empty():
		return 0
	var target_key := _entity_key(int(target_id.get("index", -1)), int(target_id.get("generation", -1)))
	var was_shocked := active_time < float(_overcharge_shock_expires_at.get(target_key, 0.0))
	_overcharge_shock_expires_at[target_key] = active_time + OVERCHARGE_SHOCK_DURATION_SECONDS
	if not was_shocked or active_time < float(_overcharge_next_at.get(target_key, 0.0)) or \
			int(event.get("reaction_budget", 1)) <= 0:
		return 0
	var reaction_chain_id := int(event.get("reaction_chain_id", 0))
	if reaction_chain_id <= 0:
		reaction_chain_id = int(event.get("sequence", 0))
	if reaction_chain_id <= 0:
		return 0
	var sequence: int = simulation.spawn_projectile("overcharge",
			Vector2(float(position["x"]), float(position["y"])), Vector2.ZERO,
			float(event["amount"]) * overcharge_damage_multiplier,
			0.0, 0.15, 0.0, 0.0, 0.0, overcharge_radius, 1.0,
			0, 0.0, 0.0, false, 0.0, 1.0, 1.0, 0.0, reaction_chain_id,
			int(event.get("reaction_budget", 1)) - 1)
	if sequence > 0:
		_overcharge_next_at[target_key] = active_time + overcharge_target_cooldown_seconds
	return sequence

func _advance_lightning_chain(event: Dictionary, entities: Array, active_time: float) -> void:
	var source_parts := str(event.get("source_type", "")).split(":", false, 1)
	if source_parts.size() != 2 or not ["lightning_primary", "lightning_arc"].has(source_parts[0]):
		return
	var chain_id: String = source_parts[1]
	if not _lightning_chain_states.has(chain_id):
		return
	var chain: Dictionary = _lightning_chain_states[chain_id]
	if active_time > float(chain["expires_at"]):
		_lightning_chain_states.erase(chain_id)
		return
	var target: Dictionary = event["target"]
	var target_id := Vector2i(int(target["index"]), int(target["generation"]))
	var visited_ids: Array = chain["visited_ids"]
	chain["reserved_ids"].erase(target_id)
	if visited_ids.has(target_id):
		return
	visited_ids.append(target_id)
	if int(chain["remaining"]) <= 0 or float(chain["next_damage"]) <= 0.0:
		_lightning_chain_states.erase(chain_id)
		return
	var excluded_ids: Array[Vector2i] = []
	for visited_id in visited_ids:
		excluded_ids.append(visited_id)
	for reserved_id in chain["reserved_ids"]:
		excluded_ids.append(reserved_id)
	var origin := Vector2(float(event["position"]["x"]), float(event["position"]["y"]))
	var next_targets := _nearest_lightning_targets(origin, excluded_ids, 1, lightning_chain_range, entities)
	if next_targets.is_empty():
		_lightning_chain_states.erase(chain_id)
		return
	var next_target: Dictionary = next_targets[0]
	var direction: Vector2 = (next_target["position"] - origin).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var arc_offset := minf(4.0, origin.distance_to(next_target["position"]) * 0.25)
	var arc_origin := origin + direction * arc_offset
	var damage := float(chain["next_damage"])
	var sequence: int = simulation.spawn_projectile("lightning_arc:%s" % chain_id, arc_origin,
		direction * _equipment_projectile_speed(lightning_projectile_speed), damage,
		_equipment_area(lightning_projectile_radius), lightning_projectile_lifetime,
		2.0, 0.5, 2.0, 0.0, 0.0, 0, 0.0, 0.0, false, 0.0, 1.0, 1.0, 0.0, 0, 1,
		bool(chain.get("critical_hit", false)))
	if sequence <= 0:
		_lightning_chain_states.erase(chain_id)
		return
	chain["reserved_ids"].append(next_target["id"])
	chain["remaining"] = int(chain["remaining"]) - 1
	chain["next_damage"] = damage * lightning_chain_damage_multiplier
	chain["expires_at"] = active_time + lightning_projectile_lifetime
	_add_lightning_arc(arc_origin, next_target["position"])

func _add_lightning_arc(from: Vector2, to: Vector2) -> void:
	var perpendicular := (to - from).orthogonal().normalized()
	var points := PackedVector2Array()
	points.append(from)
	points.append(from.lerp(to, 0.34) + perpendicular * _random_float_range(-10.0, 10.0, "lightning_arc_jitter"))
	points.append(from.lerp(to, 0.68) + perpendicular * _random_float_range(-10.0, 10.0, "lightning_arc_jitter"))
	points.append(to)
	if not _visual_effects_reduced():
		_lightning_arcs.append({"points": points, "remaining": LIGHTNING_ARC_LIFETIME})

func _fire_infinite_circuit(active_time: float, target_budget: int, damage_multiplier: float, cooldown: float) -> void:
	var roots := _lightning_initial_targets(2)
	var used_ids: Array[Vector2i] = []
	var fired := false
	var branch_factor := 2 # GDD prototype value; tuning remains proposed.
	var target_count := 0
	for root_target in roots:
		if target_count >= target_budget:
			break
		var root_id: Vector2i = root_target["id"]
		used_ids.append(root_id)
		var root_position: Vector2 = root_target["position"]
		var root_direction := (root_position - player.global_position).normalized()
		if root_direction == Vector2.ZERO:
			root_direction = Vector2.RIGHT
		if simulation.spawn_projectile("lightning_conductor", player.global_position + root_direction * 14.0,
				root_direction * _equipment_projectile_speed(lightning_projectile_speed), lightning_damage * damage_multiplier,
				_equipment_area(lightning_projectile_radius), lightning_projectile_lifetime,
				2.0, 0.5, 2.0, 0.0, 0.0, 0, 0.0, 0.0, false, 0.0, 1.0, 1.0, 0.0, 0, 1,
				_last_attack_critical_hit) <= 0:
			continue
		fired = true
		target_count += 1
		var frontier: Array[Dictionary] = [root_target]
		while not frontier.is_empty() and target_count < target_budget:
			var next_frontier: Array[Dictionary] = []
			var needed_targets := target_budget - target_count
			for parent in frontier:
				var children := _nearest_lightning_targets(parent["position"], used_ids, mini(branch_factor, needed_targets))
				var parent_position: Vector2 = parent["position"]
				for child in children:
					var target_id: Vector2i = child["id"]
					var direction: Vector2 = (child["position"] - parent_position).normalized()
					if direction == Vector2.ZERO:
						direction = Vector2.RIGHT
					var branch_offset := minf(4.0, parent_position.distance_to(child["position"]) * 0.25)
					if simulation.spawn_projectile("infinite_circuit_branch", parent_position + direction * branch_offset,
							direction * _equipment_projectile_speed(lightning_projectile_speed), lightning_damage * damage_multiplier,
							_equipment_area(lightning_projectile_radius), lightning_projectile_lifetime,
							2.0, 0.5, 2.0, 0.0, 0.0, 0, 0.0, 0.0, false, 0.0, 1.0, 1.0, 0.0, 0, 1,
							_last_attack_critical_hit) <= 0:
						continue
					used_ids.append(child["id"])
					next_frontier.append(child)
					target_count += 1
					fired = true
					if target_count >= target_budget:
						break
				if target_count >= target_budget:
					break
			frontier = next_frontier
	if fired:
		_try_unique_lightning_burst(lightning_damage * damage_multiplier)
		_next_weapon_time = active_time + _effective_weapon_cooldown(cooldown)

func _nearest_lightning_targets(origin: Vector2, excluded_ids: Array[Vector2i], limit: int,
		max_range: float = -1.0, entities: Variant = null) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var range_limit := SURVIVAL_TARGETING.visible_range(lightning_range) if max_range < 0.0 else SURVIVAL_TARGETING.visible_range(max_range)
	var max_distance_squared := range_limit * range_limit
	var search_entities: Array = _entities if entities == null else entities
	for entity in search_entities:
		var components: Dictionary = entity["components"]
		if not _is_targetable_enemy(components):
			continue
		var id: Dictionary = entity["id"]
		var entity_id := Vector2i(int(id["index"]), int(id["generation"]))
		if excluded_ids.has(entity_id):
			continue
		var transform: Dictionary = components["Transform2D"]
		var position := Vector2(float(transform["x"]), float(transform["y"]))
		var distance_squared := origin.distance_squared_to(position)
		if distance_squared < max_distance_squared and SURVIVAL_TARGETING.is_inside_visible_radius(player.global_position, position):
			candidates.append({"id": entity_id, "position": position, "distance_squared": distance_squared})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["distance_squared"] < b["distance_squared"])
	if candidates.size() > limit:
		candidates.resize(limit)
	return candidates

func _lightning_initial_targets(limit: int) -> Array[Dictionary]:
	if limit <= 0:
		return []
	var primary := SURVIVAL_TARGETING.select_dense_cluster_target(
		_entities, player.global_position, SURVIVAL_TARGETING.visible_range(lightning_range),
		SURVIVAL_TARGETING.visible_range(lightning_chain_range))
	if primary.is_empty():
		return []
	var targets: Array[Dictionary] = [primary]
	if limit == 1:
		return targets
	var excluded: Array[Vector2i] = [primary["id"]]
	var remaining := _nearest_lightning_targets(primary["position"], excluded, limit - 1, lightning_chain_range)
	targets.append_array(remaining)
	return targets

func _fire_inferno_sprayer(active_time: float, paused: bool) -> void:
	if not weapon_enabled or loadout.weapon_level("inferno_sprayer") == 0 or paused or _chest_open or run_over or inferno_cooldown <= 0.0 or active_time < _next_inferno_time:
		return
	var level: int = loadout.weapon_level("inferno_sprayer")
	var targeting_range := SURVIVAL_TARGETING.weapon_range(inferno_range, _weapon_level_multiplier("inferno_sprayer", "range_multiplier", level))
	var target := _highest_threat_enemy(targeting_range)
	if target.is_empty():
		return
	var direction: Vector2 = (target["position"] - player.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var damage := inferno_damage * _weapon_level_multiplier("inferno_sprayer", "damage_multiplier", level)
	damage *= _weapon_combo_damage_multiplier("inferno_sprayer")
	damage *= _persistent_damage_multiplier()
	damage *= _roll_equipment_critical_multiplier()
	var projectile_radius := inferno_projectile_radius * _weapon_level_multiplier("inferno_sprayer", "jet_width_multiplier", level)
	var burn_damage := inferno_burn_damage_per_tick * _weapon_level_multiplier("inferno_sprayer", "burn_damage_multiplier", level)
	var projectile_type := "inferno_sprayer"
	var explosion_radius := 0.0
	var explosion_multiplier := 0.0
	if loadout.is_evolved("inferno_sprayer"):
		projectile_type = "wildfire_sprayer"
		explosion_radius = _equipment_area(wildfire_explosion_radius)
		explosion_multiplier = wildfire_explosion_damage_multiplier
	var projectile_sequence: int = simulation.spawn_status_projectile(projectile_type, player.global_position + direction * 14.0,
			direction * _equipment_projectile_speed(inferno_projectile_speed), damage, _equipment_area(projectile_radius),
			inferno_projectile_lifetime, burn_damage * _weapon_combo_damage_multiplier("inferno_sprayer") * _persistent_damage_multiplier(),
			inferno_burn_interval_seconds, inferno_burn_duration_seconds,
			explosion_radius, explosion_multiplier, 0, 0.0, 0.0, false, 0.0, 1.0, 1.0, 0.0, 0, 1,
			_last_attack_critical_hit)
	if projectile_sequence > 0:
		Sfx.play("weapon_shot")
		_try_unique_lightning_burst(damage)
		_try_evolution_shockwave(damage)
		_next_inferno_time = active_time + _effective_weapon_cooldown(inferno_cooldown)

func _fire_crimson_daggers(active_time: float, paused: bool) -> void:
	if not weapon_enabled or loadout.weapon_level("crimson_daggers") == 0 or paused or _chest_open or run_over or daggers_cooldown <= 0.0 or active_time < _next_daggers_time:
		return
	var target := _lowest_health_enemy(SURVIVAL_TARGETING.visible_range(daggers_range))
	if target.is_empty():
		return
	var direction: Vector2 = (target["position"] - player.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var level: int = loadout.weapon_level("crimson_daggers")
	var damage := daggers_damage * _weapon_level_multiplier("crimson_daggers", "damage_multiplier", level)
	damage *= _persistent_damage_multiplier()
	damage *= _roll_equipment_critical_multiplier()
	var projectile_type := "crimson_dagger"
	var status_damage := 2.0
	var status_interval := 0.5
	var status_duration := 2.0
	var projectile_lifetime := daggers_projectile_lifetime
	damage *= _weapon_combo_damage_multiplier("crimson_daggers")
	if loadout.is_evolved("crimson_daggers"):
		projectile_type = "bloodstorm_dagger"
		status_damage = bloodstorm_bleed_damage_per_tick
		status_interval = bloodstorm_bleed_interval_seconds
		status_duration = bloodstorm_bleed_duration_seconds
		projectile_lifetime = maxf(projectile_lifetime, bloodstorm_orbit_lifetime_seconds)
	var fired := 0
	var dagger_count := int(_weapon_level_value("crimson_daggers", "projectile_count", level, 2.0))
	var max_spread := 0.06 if dagger_count == 2 else 0.08
	var spreads: Array[float] = []
	for index in range(dagger_count):
		spreads.append(0.0 if dagger_count == 1 else lerpf(-max_spread, max_spread, float(index) / float(dagger_count - 1)))
	var orbit_speed := 5.0 * _weapon_level_multiplier("crimson_daggers", "orbit_speed_multiplier", level)
	for spread in spreads:
		var shot_direction: Vector2 = direction.rotated(spread)
		if simulation.spawn_status_projectile(projectile_type, player.global_position + shot_direction * 14.0,
				shot_direction * _equipment_projectile_speed(daggers_projectile_speed), damage, _equipment_area(daggers_projectile_radius),
				projectile_lifetime, status_damage * _persistent_damage_multiplier() * _weapon_combo_damage_multiplier("crimson_daggers"),
				status_interval, status_duration, 0.0, 0.0, 0, 0.0, 0.0, true, 0.0, 1.0, 1.0, orbit_speed,
				0, 1, _last_attack_critical_hit) > 0:
			fired += 1
	if fired > 0:
		Sfx.play("weapon_sweep")
		_try_unique_lightning_burst(damage)
		_try_evolution_shockwave(damage)
		_next_daggers_time = active_time + _effective_weapon_cooldown(daggers_cooldown)

func _fire_minigun(active_time: float, paused: bool) -> void:
	if not weapon_enabled or loadout.weapon_level("minigun") == 0 or paused or _chest_open or run_over or minigun_cooldown <= 0.0:
		return
	var weapon_range := SURVIVAL_TARGETING.visible_range(minigun_range)
	var target := _enemy_by_id_in_range(_minigun_target_id, weapon_range)
	if target.is_empty():
		target = _nearest_enemy(weapon_range)
	if target.is_empty():
		_minigun_target_id = Vector2i(-1, -1)
		_redline_fire_time = 0.0
		return
	var target_id: Vector2i = target["id"]
	if target_id != _minigun_target_id:
		_minigun_target_id = target_id
		_redline_fire_time = active_time
	if active_time < _next_minigun_time:
		return
	var level: int = loadout.weapon_level("minigun")
	var damage_multiplier := _weapon_level_multiplier("minigun", "damage_multiplier", level)
	var cadence_multiplier := _weapon_level_multiplier("minigun", "cadence_multiplier", level)
	var combo_multiplier := _weapon_combo_damage_multiplier("minigun")
	var damage := minigun_damage * damage_multiplier * combo_multiplier * _persistent_damage_multiplier() * _roll_equipment_critical_multiplier()
	var direction: Vector2 = (target["position"] - player.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var spread := minigun_spread_radians * _weapon_level_multiplier("minigun", "spread_multiplier", level)
	direction = direction.rotated(_random_float_range(-spread, spread, "minigun_spread"))
	var projectile_type := "redline" if loadout.is_evolved("minigun") else "minigun"
	if simulation.spawn_projectile(projectile_type, player.global_position + direction * 14.0,
			direction * _equipment_projectile_speed(minigun_projectile_speed), damage,
			_equipment_area(minigun_projectile_radius), minigun_projectile_lifetime,
			2.0, 0.5, 2.0, 0.0, 0.0, 0, 0.0, 0.0, false, 0.0, 1.0, 1.0, 0.0, 0, 1,
			_last_attack_critical_hit) <= 0:
		return
	Sfx.play("weapon_shot")
	if loadout.is_evolved("minigun"):
		var ramp := clampf((active_time - _redline_fire_time) / maxf(redline_ramp_seconds, 0.01), 0.0, 1.0)
		cadence_multiplier *= 1.0 + redline_max_cadence_bonus * ramp
	_next_minigun_time = active_time + _effective_weapon_cooldown(minigun_cooldown) / cadence_multiplier

func _fire_toxic_cloud(active_time: float, paused: bool) -> void:
	if not weapon_enabled or loadout.weapon_level("toxic_cloud") == 0 or paused or _chest_open or run_over or toxic_cooldown <= 0.0 or active_time < _next_toxic_time:
		return
	var target := _highest_health_enemy(SURVIVAL_TARGETING.visible_range(toxic_range))
	if target.is_empty():
		return
	var level: int = loadout.weapon_level("toxic_cloud")
	var dot_multiplier := _weapon_level_multiplier("toxic_cloud", "poison_damage_multiplier", level)
	dot_multiplier *= _weapon_combo_damage_multiplier("toxic_cloud")
	var duration := toxic_status_duration_seconds * _weapon_level_multiplier("toxic_cloud", "status_duration_multiplier", level)
	var cloud_radius := _equipment_area(toxic_cloud_radius * _weapon_level_multiplier("toxic_cloud", "cloud_radius_multiplier", level))
	var direction: Vector2 = (target["position"] - player.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var projectile_type := "toxic_cloud"
	if loadout.is_evolved("toxic_cloud"):
		projectile_type = "pandemic_cloud"
	var sequence: int = simulation.spawn_status_projectile(projectile_type,
			player.global_position + direction * 14.0,
		direction * _equipment_projectile_speed(toxic_projectile_speed),
		toxic_impact_damage * _weapon_combo_damage_multiplier("toxic_cloud") * _persistent_damage_multiplier() * _roll_equipment_critical_multiplier(),
		_equipment_area(toxic_projectile_radius), toxic_projectile_lifetime,
		toxic_damage_per_tick * dot_multiplier * _persistent_damage_multiplier(), toxic_tick_interval_seconds, duration,
		cloud_radius, toxic_splash_damage_multiplier, 0, 0.0, 0.0, false, 0.0, 1.0, 1.0, 0.0, 0, 1,
		_last_attack_critical_hit)
	if sequence > 0:
		Sfx.play("weapon_zap")
		_next_toxic_time = active_time + _effective_weapon_cooldown(toxic_cooldown)

func _fire_sawblades(active_time: float, paused: bool) -> void:
	if not weapon_enabled or loadout.weapon_level("sawblades") == 0 or paused or _chest_open or run_over or sawblades_cooldown <= 0.0 or active_time < _next_sawblades_time:
		return
	var target := _sawblades_cluster_target()
	if target.is_empty():
		return
	var direction: Vector2 = (target["position"] - player.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var level: int = loadout.weapon_level("sawblades")
	var evolved: bool = loadout.is_evolved("sawblades")
	var damage_multiplier := _weapon_level_multiplier("sawblades", "damage_multiplier", level)
	var ricochets := 1 + _weapon_level_addition("sawblades", "ricochet_add", level) + (1 if evolved else 0)
	var projectile_speed := sawblades_projectile_speed * _weapon_level_multiplier("sawblades", "projectile_speed_multiplier", level)
	var sequence: int = simulation.spawn_projectile("razorstorm" if evolved else "sawblades",
			player.global_position + direction * 14.0,
		direction * _equipment_projectile_speed(projectile_speed),
		sawblades_damage * damage_multiplier * _weapon_combo_damage_multiplier("sawblades") * _persistent_damage_multiplier() * _roll_equipment_critical_multiplier(),
		_equipment_area(sawblades_projectile_radius), sawblades_projectile_lifetime,
		2.0, 0.5, 2.0, 0.0, 0.0, ricochets, 0.0, 0.0, false, 0.0, 1.0, 1.0, 0.0, 0, 1,
		_last_attack_critical_hit)
	if sequence > 0:
		Sfx.play("weapon_sweep")
		_next_sawblades_time = active_time + _effective_weapon_cooldown(sawblades_cooldown)

func _fire_meteor_staff(active_time: float, paused: bool) -> void:
	if not weapon_enabled or loadout.weapon_level("meteor_staff") == 0 or paused or _chest_open or run_over or meteor_staff_cooldown <= 0.0 or active_time < _next_meteor_time:
		return
	var target := _meteor_cluster_target()
	if target.is_empty():
		return
	var level: int = loadout.weapon_level("meteor_staff")
	var evolved: bool = loadout.is_evolved("meteor_staff")
	var projectile_type := "starfall" if evolved else "meteor_staff"
	var damage_multiplier := _weapon_level_multiplier("meteor_staff", "damage_multiplier", level)
	var blast_radius := meteor_staff_blast_radius * _weapon_level_multiplier("meteor_staff", "explosion_radius_multiplier", level)
	var direction: Vector2 = (target["position"] - player.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var shot_count := 2 if evolved and _random_float("meteor_double_impact_roll") < celestial_eye_double_impact_chance else 1
	var fired := false
	for _shot in range(shot_count):
		if simulation.spawn_projectile(projectile_type, player.global_position + direction * 14.0,
				direction * _equipment_projectile_speed(meteor_staff_projectile_speed),
				meteor_staff_damage * damage_multiplier * _weapon_combo_damage_multiplier("meteor_staff") * _persistent_damage_multiplier() * _roll_equipment_critical_multiplier(),
				_equipment_area(meteor_staff_projectile_radius), meteor_staff_projectile_lifetime,
				2.0, 0.5, 2.0, _equipment_area(blast_radius), meteor_staff_splash_damage_multiplier,
				0, 0.0, 0.0, false, 0.0, 1.0, 1.0, 0.0, 0, 1, _last_attack_critical_hit) > 0:
			fired = true
	if fired:
		Sfx.play("weapon_shot")
		var cooldown_multiplier := _weapon_level_multiplier("meteor_staff", "cooldown_multiplier", level)
		_next_meteor_time = active_time + _effective_weapon_cooldown(meteor_staff_cooldown * cooldown_multiplier)

func _fire_prism_laser(active_time: float, paused: bool) -> void:
	_prism_beams.clear()
	if not weapon_enabled or loadout.weapon_level("prism_laser") == 0 or paused or _chest_open or run_over or prism_laser_cooldown <= 0.0:
		return
	var level: int = loadout.weapon_level("prism_laser")
	var range_multiplier := _weapon_level_multiplier("prism_laser", "range_multiplier", level)
	var area_multiplier: float = 1.0 + (_equipment_bonus("area_pct") + loadout.global_relic_bonus("area_pct") + _xp_run_stat_bonus("area_pct")) / 100.0
	var laser_range := SURVIVAL_TARGETING.weapon_range(prism_laser_range, range_multiplier, area_multiplier)
	var target := _prism_cluster_target(laser_range)
	if target.is_empty():
		_prism_beam_endpoints.clear()
		_last_prism_active_time = active_time
		return
	var evolved: bool = loadout.is_evolved("prism_laser")
	var damage_multiplier := _weapon_level_multiplier("prism_laser", "damage_multiplier", level)
	damage_multiplier *= _weapon_combo_damage_multiplier("prism_laser")
	var targets: Array[Dictionary] = [target]
	if evolved:
		var excluded: Array[Vector2i] = [target["id"]]
		for _beam in range(spectrum_collapse_secondary_beams):
			var secondary := _nearest_enemy_excluding(target["position"],
				SURVIVAL_TARGETING.visible_range(spectrum_collapse_cluster_radius), excluded)
			if secondary.is_empty():
				break
			targets.append(secondary)
			excluded.append(secondary["id"])
	var tracking_delta := maxf(active_time - _last_prism_active_time, 0.0)
	_last_prism_active_time = active_time
	for index in range(targets.size()):
		var target_position: Vector2 = targets[index]["position"]
		if index >= _prism_beam_endpoints.size():
			_prism_beam_endpoints.append(target_position)
		else:
			_prism_beam_endpoints[index] = _prism_beam_endpoints[index].move_toward(
				target_position, prism_laser_projectile_speed * _weapon_level_multiplier("prism_laser", "beam_tracking_speed_multiplier", level) * tracking_delta)
		_prism_beams.append({"from": player.global_position, "to": _prism_beam_endpoints[index], "secondary": index > 0})
	_prism_beam_endpoints.resize(targets.size())
	if active_time < _next_prism_time:
		return
	var critical: float = _roll_equipment_critical_multiplier()
	var fired := false
	for index in range(targets.size()):
		var beam_target: Dictionary = targets[index]
		var direction: Vector2 = (beam_target["position"] - player.global_position).normalized()
		var secondary_beam: bool = index > 0
		var projectile_type := "spectrum_collapse" if evolved and secondary_beam else "prism_laser"
		var prism_sequence: int = simulation.spawn_projectile(projectile_type, player.global_position + direction * 14.0,
				direction * prism_laser_projectile_speed,
				prism_laser_damage * damage_multiplier * _persistent_damage_multiplier() * critical * (0.65 if secondary_beam else 1.0),
				prism_laser_projectile_radius, laser_range / prism_laser_projectile_speed,
				2.0, 0.5, 2.0, 0.0, 0.0, 0, 0.0, 0.0, false, 0.0, 1.0, 1.0, 0.0, 0, 1,
				_last_attack_critical_hit)
		if prism_sequence > 0:
			fired = true
	if fired:
		Sfx.play("weapon_zap")
		_next_prism_time = active_time + _effective_weapon_cooldown(prism_laser_cooldown)

func _fire_void_orb(active_time: float, paused: bool) -> void:
	if not weapon_enabled or loadout.weapon_level("void_orb") == 0 or paused or _chest_open or run_over or void_orb_cooldown <= 0.0 or active_time < _next_void_orb_time:
		return
	var target := _farthest_enemy(SURVIVAL_TARGETING.visible_range(void_orb_range))
	if target.is_empty():
		return
	var level: int = loadout.weapon_level("void_orb")
	var evolved: bool = loadout.is_evolved("void_orb")
	var direction: Vector2 = (target["position"] - player.global_position).normalized()
	var damage_multiplier := _weapon_level_multiplier("void_orb", "damage_multiplier", level) * _weapon_combo_damage_multiplier("void_orb")
	var attraction_radius := void_orb_attraction_radius * _weapon_level_multiplier("void_orb", "attraction_radius_multiplier", level)
	var lifetime := void_orb_lifetime * _weapon_level_multiplier("void_orb", "projectile_lifetime_multiplier", level)
	var attraction_speed := void_orb_attraction_speed * _weapon_level_multiplier("void_orb", "attraction_force_multiplier", level)
	if evolved:
		attraction_radius *= 1.5
		attraction_speed *= 1.25
	var projectile_type := "event_horizon" if evolved else "void_orb"
	var sequence: int = simulation.spawn_projectile(projectile_type, player.global_position + direction * 14.0,
			direction * _equipment_projectile_speed(void_orb_speed),
			void_orb_damage * damage_multiplier * _persistent_damage_multiplier() * _roll_equipment_critical_multiplier(),
			_equipment_area(void_orb_radius), lifetime, 2.0, 0.5, 2.0, 0.0, 0.0, 0,
			_equipment_area(attraction_radius), attraction_speed, true, 0.0, 1.0, 1.0, 0.0, 0, 1,
			_last_attack_critical_hit)
	if sequence > 0:
		Sfx.play("weapon_zap")
		_next_void_orb_time = active_time + _effective_weapon_cooldown(void_orb_cooldown)

func _fire_frost_nova(active_time: float, paused: bool) -> void:
	var level: int = loadout.weapon_level("frost_nova")
	if not weapon_enabled or level == 0 or paused or _chest_open or run_over or frost_nova_cooldown <= 0.0 or active_time < _next_frost_nova_time:
		return
	var evolved: bool = loadout.is_evolved("frost_nova")
	var area_multiplier: float = 1.0 + (_equipment_bonus("area_pct") + loadout.global_relic_bonus("area_pct") + _xp_run_stat_bonus("area_pct")) / 100.0
	var radius := SURVIVAL_TARGETING.weapon_range(frost_nova_radius,
		_weapon_level_multiplier("frost_nova", "area_multiplier", level), area_multiplier)
	var duration := frost_chill_duration_seconds * _weapon_level_multiplier("frost_nova", "chill_duration_multiplier", level)
	var target_count := 0
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if not _is_targetable_enemy(components):
			continue
		var transform: Dictionary = components["Transform2D"]
		var position := Vector2(float(transform["x"]), float(transform["y"]))
		if player.global_position.distance_squared_to(position) <= radius * radius:
			target_count += 1
	if target_count == 0:
		return
	var projectile_type := "absolute_zero" if evolved else "frost_nova"
	var damage := frost_nova_damage * _weapon_level_multiplier("frost_nova", "damage_multiplier", level) * _weapon_combo_damage_multiplier("frost_nova") * _persistent_damage_multiplier()
	var vulnerability := 1.0 + frozen_crown_vulnerability_at_level_five if evolved else 1.0
	if simulation.spawn_projectile(projectile_type, player.global_position, Vector2.ZERO, damage,
			radius, frost_nova_duration_seconds, 2.0, 0.5, 2.0, 0.0, 0.0, 0, 0.0, 0.0,
			true, duration, frost_chill_speed_multiplier, vulnerability) > 0:
		Sfx.play("weapon_zap")
		_next_frost_nova_time = active_time + _effective_weapon_cooldown(frost_nova_cooldown * _weapon_level_multiplier("frost_nova", "cooldown_multiplier", level))

func _nearest_enemy_excluding(origin: Vector2, max_range: float, excluded: Array[Vector2i]) -> Dictionary:
	var nearest: Dictionary = {}
	var best_distance_squared := max_range * max_range
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if not _is_targetable_enemy(components):
			continue
		var id: Dictionary = entity["id"]
		var key := Vector2i(int(id["index"]), int(id["generation"]))
		if excluded.has(key):
			continue
		var transform: Dictionary = components["Transform2D"]
		var point := Vector2(float(transform["x"]), float(transform["y"]))
		var distance_squared := origin.distance_squared_to(point)
		if distance_squared < best_distance_squared and SURVIVAL_TARGETING.is_inside_visible_radius(player.global_position, point):
			best_distance_squared = distance_squared
			nearest = {"position": point, "id": key}
	return nearest

func _prism_cluster_target(max_range: float) -> Dictionary:
	return SURVIVAL_TARGETING.select_dense_cluster_target(
		_entities, player.global_position, minf(max_range, SURVIVAL_TARGETING.VISIBLE_TARGET_RADIUS),
		SURVIVAL_TARGETING.visible_range(spectrum_collapse_cluster_radius), false, "highest_health")

func _meteor_cluster_target() -> Dictionary:
	return SURVIVAL_TARGETING.select_cluster_centroid(
		_entities, player.global_position, SURVIVAL_TARGETING.visible_range(meteor_staff_range),
		SURVIVAL_TARGETING.visible_range(meteor_staff_cluster_radius))

func _sawblades_cluster_target() -> Dictionary:
	return SURVIVAL_TARGETING.select_dense_cluster_target(
		_entities, player.global_position, SURVIVAL_TARGETING.visible_range(sawblades_range),
		SURVIVAL_TARGETING.visible_range(sawblades_cluster_radius), true)

func _spawn_starfall_fragments(origin: Vector2, primary_target: Dictionary, entities: Array) -> void:
	var candidates: Array[Dictionary] = []
	var fragment_radius_squared := starfall_fragment_radius * starfall_fragment_radius
	for entity in entities:
		var components: Dictionary = entity["components"]
		if not _is_targetable_enemy(components):
			continue
		var id: Dictionary = entity["id"]
		if int(id["index"]) == int(primary_target["index"]) and int(id["generation"]) == int(primary_target["generation"]):
			continue
		var transform: Dictionary = components["Transform2D"]
		var position := Vector2(float(transform["x"]), float(transform["y"]))
		var distance_squared := origin.distance_squared_to(position)
		if distance_squared <= fragment_radius_squared:
			candidates.append({"position": position, "distance_squared": distance_squared})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["distance_squared"] < b["distance_squared"])
	var fragment_count := mini(maxi(starfall_fragment_count, 0), candidates.size())
	for index in range(fragment_count):
		var direction: Vector2 = (candidates[index]["position"] - origin).normalized()
		if direction == Vector2.ZERO:
			continue
		var critical_damage := _roll_equipment_critical_multiplier()
		simulation.spawn_projectile("starfall_fragment", origin + direction * 22.0,
				direction * _equipment_projectile_speed(meteor_staff_projectile_speed * 1.25),
				meteor_staff_damage * starfall_fragment_damage_multiplier * _weapon_combo_damage_multiplier("meteor_staff") * _persistent_damage_multiplier() *
						critical_damage, _equipment_area(meteor_staff_projectile_radius * 0.65),
				meteor_staff_projectile_lifetime,
				2.0, 0.5, 2.0, 0.0, 0.0, 0, 0.0, 0.0, false, 0.0, 1.0, 1.0, 0.0, 0, 1,
				_last_attack_critical_hit)

func _spread_pandemic(origin: Vector2, entities: Array) -> void:
	var status_damage := toxic_damage_per_tick * (1.0 + (0.2 if loadout.weapon_level("toxic_cloud") >= 2 else 0.0) +
			(0.25 if loadout.weapon_level("toxic_cloud") >= 5 else 0.0))
	status_damage *= _weapon_combo_damage_multiplier("toxic_cloud") * _persistent_damage_multiplier()
	var status_duration := toxic_status_duration_seconds * (1.2 if loadout.weapon_level("toxic_cloud") >= 4 else 1.0)
	var affected := 0
	for entity in entities:
		if affected >= pandemic_max_spread_targets:
			break
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("IsXpOrb", false):
			continue
		var health: Dictionary = components["Health"]
		if float(health["current"]) <= 0.0:
			continue
		var transform: Dictionary = components["Transform2D"]
		var position := Vector2(float(transform["x"]), float(transform["y"]))
		if origin.distance_squared_to(position) > pandemic_spread_radius * pandemic_spread_radius:
			continue
		var id: Dictionary = entity["id"]
		if simulation.apply_damage_over_time(int(id["index"]), int(id["generation"]),
				status_damage, toxic_tick_interval_seconds, status_duration) > 0:
			affected += 1
	if not _visual_effects_reduced():
		_pandemic_bursts.append({"position": origin, "remaining": pandemic_feedback_seconds})

func _persistent_damage_multiplier() -> float:
	return _cached_persistent_damage_multiplier * (1.0 + (loadout.global_relic_bonus("damage_pct") + _xp_run_stat_bonus("damage_pct")) / 100.0)

func _weapon_combo_damage_multiplier(weapon_id: String) -> float:
	return 1.25 if loadout.is_evolved(weapon_id) else 1.0

func _refresh_persistent_bonuses() -> void:
	_run_stat_hub_dirty = true
	_cached_persistent_damage_multiplier = 1.0
	_cached_skill_move_speed_pct = 0.0
	_cached_skill_critical_chance_pct = 0.0
	_cached_equipment_bonuses = {}
	_cached_skill_stat_bonuses = {}
	_cached_achievement_stat_bonuses = {}
	_cached_unique_effects = []
	if progression_service != null:
		if mode_id != "armorless":
			_cached_equipment_bonuses = progression_service.equipment_bonuses()
			_cached_unique_effects = progression_service.equipped_unique_effects()
		var skill_damage_bonus: float = progression_service.skill_bonus("damage_pct")
		var skill_move_speed_bonus: float = progression_service.skill_bonus("move_speed_pct")
		var skill_critical_chance_bonus: float = progression_service.skill_bonus("critical_chance_pct")
		var skill_max_hp_bonus: float = progression_service.skill_bonus("max_hp_pct")
		var achievement_damage_bonus: float = progression_service.achievement_bonus("damage_pct")
		_cached_persistent_damage_multiplier += skill_damage_bonus
		_cached_skill_move_speed_pct = skill_move_speed_bonus
		_cached_skill_critical_chance_pct = skill_critical_chance_bonus
		_cached_persistent_damage_multiplier += achievement_damage_bonus
		_cached_persistent_damage_multiplier += _equipment_bonus("damage_pct") / 100.0
		_cached_skill_stat_bonuses = {
			"damage_pct": skill_damage_bonus * 100.0,
			"move_speed_pct": skill_move_speed_bonus * 100.0,
			"critical_chance_pct": skill_critical_chance_bonus,
			"max_hp_pct": skill_max_hp_bonus,
		}
		_cached_achievement_stat_bonuses["damage_pct"] = achievement_damage_bonus * 100.0
	var capacity_bonus := 1 if _has_unique_effect("expanded_loadout") else 0
	loadout.set_slot_capacity_bonus(capacity_bonus, capacity_bonus)
	_refresh_player_move_speed()

func _equipment_bonus(stat_id: String) -> float:
	var bonus := float(_cached_equipment_bonuses.get(stat_id, 0.0))
	if mode_id != "armorless" or armorless_run_state == null:
		return bonus
	for equipment in armorless_run_state.temporary_equipment():
		for line in equipment.get("stat_lines", []):
			if str(line.get("stat_id", "")) == stat_id:
				bonus += EQUIPMENT_GENERATOR_SCRIPT.stat_value(
					stat_id, float(line.get("roll_percentile", 0.0)), int(line.get("enhancement_level", 0))
				)
	return bonus

func _equipment_kill_healing(base_healing: float) -> float:
	var blood_chalice_bonus: float = loadout.relic_level("blood_chalice") * blood_chalice_heal_per_level * 100.0
	return base_healing * (1.0 + (_equipment_bonus("kill_healing_pct") + blood_chalice_bonus + _xp_run_stat_bonus("kill_healing_pct")) / 100.0)

func _equipment_xp_value(base_xp: float) -> float:
	return base_xp * (1.0 + (_equipment_bonus("xp_pct") + _xp_run_stat_bonus("xp_pct")) / 100.0)

func _refresh_player_move_speed() -> void:
	var haste_multiplier := 1.15 if _has_unique_effect("elite_haste") and player_active_time < _elite_haste_expires_at else 1.0
	var next_speed := _base_player_move_speed * (1.0 + (_equipment_bonus("move_speed_pct") + _xp_run_stat_bonus("move_speed_pct")) / 100.0 + _cached_skill_move_speed_pct) * haste_multiplier
	if not is_equal_approx(player.move_speed, next_speed):
		_run_stat_hub_dirty = true
	player.move_speed = next_speed

func _effective_weapon_cooldown(base_cooldown: float) -> float:
	var speed_multiplier: float = 1.0 + (_equipment_bonus("attack_speed_pct") + loadout.global_relic_bonus("attack_speed_pct") + _xp_run_stat_bonus("attack_speed_pct")) / 100.0
	var cooldown_multiplier: float = maxf(0.1, 1.0 - (_equipment_bonus("cooldown_reduction_pct") + loadout.global_relic_bonus("cooldown_reduction_pct") + _xp_run_stat_bonus("cooldown_reduction_pct")) / 100.0)
	return base_cooldown * cooldown_multiplier / speed_multiplier

func capture_sandbox_snapshot_state() -> Dictionary:
	if not sandbox_diagnostics_enabled or mode_id != "survival" or progression_service != null or \
			player == null or loadout == null or wave_director == null or _chest_director == null or \
			_chest_open or _starting_weapon_choice_open or run_over:
		return {}
	return {
		"script_fields": _sandbox_snapshot_script_fields(),
		"rng_seed": _sandbox_rng.seed,
		"rng_state": _sandbox_rng.state,
		"player_position": player.global_position,
		"player_velocity": player.velocity,
		"last_target": {
			"valid": _last_target.is_finite(),
			"position": _last_target if _last_target.is_finite() else Vector2.ZERO,
		},
		"wave_director": {
			"wave": wave_director.wave,
			"elapsed_in_wave": wave_director.elapsed_in_wave,
			"state": wave_director.state,
			"wave_duration_seconds": wave_director.wave_duration_seconds,
			"endless_armorless": wave_director.endless_armorless,
		},
		"loadout": {
			"weapon_slot_limit": loadout._weapon_slot_limit,
			"relic_slot_limit": loadout._relic_slot_limit,
			"rng_state": loadout._rng.state,
			"offer_weights": loadout.offer_weights.duplicate(true),
		},
		"chest_director": {
			"last_drop_time": _chest_director._last_drop_time.duplicate(true),
			"rng_state": _chest_director._rng.state,
		},
	}

func can_restore_sandbox_snapshot_state(snapshot: Variant) -> bool:
	if not snapshot is Dictionary or snapshot.size() != 9 or \
			not snapshot.has("script_fields") or not snapshot.has("rng_seed") or \
			not snapshot.has("rng_state") or not snapshot.has("player_position") or \
			not snapshot.has("player_velocity") or not snapshot.has("last_target") or \
			not snapshot.has("wave_director") or \
			not snapshot.has("loadout") or not snapshot.has("chest_director"):
		return false
	var fields: Variant = snapshot["script_fields"]
	var current_fields := _sandbox_snapshot_script_fields()
	if not fields is Dictionary or fields.size() != current_fields.size():
		return false
	for field in current_fields:
		if not fields.has(field) or typeof(fields[field]) != typeof(current_fields[field]) or \
				not _sandbox_snapshot_value_supported(fields[field]):
			return false
	if typeof(snapshot["rng_seed"]) != TYPE_INT or typeof(snapshot["rng_state"]) != TYPE_INT or \
			not snapshot["player_position"] is Vector2 or not snapshot["player_position"].is_finite() or \
			not snapshot["player_velocity"] is Vector2 or not snapshot["player_velocity"].is_finite():
		return false
	var last_target: Variant = snapshot["last_target"]
	if not last_target is Dictionary or last_target.size() != 2 or \
			typeof(last_target.get("valid", null)) != TYPE_BOOL or \
			not last_target.get("position", null) is Vector2 or not last_target["position"].is_finite():
		return false
	var director: Variant = snapshot["wave_director"]
	if not director is Dictionary or director.size() != 5 or \
			typeof(director.get("wave", null)) != TYPE_INT or int(director["wave"]) < 1 or \
			typeof(director.get("state", null)) != TYPE_INT or int(director["state"]) < 0 or int(director["state"]) > 3 or \
			typeof(director.get("endless_armorless", null)) != TYPE_BOOL or \
			typeof(director.get("elapsed_in_wave", null)) not in [TYPE_INT, TYPE_FLOAT] or \
			typeof(director.get("wave_duration_seconds", null)) not in [TYPE_INT, TYPE_FLOAT] or \
			not is_finite(float(director["elapsed_in_wave"])) or float(director["elapsed_in_wave"]) < 0.0 or \
			not is_finite(float(director["wave_duration_seconds"])) or float(director["wave_duration_seconds"]) <= 0.0:
		return false
	var loadout_state: Variant = snapshot["loadout"]
	if not loadout_state is Dictionary or loadout_state.size() != 4 or \
			typeof(loadout_state.get("weapon_slot_limit", null)) != TYPE_INT or \
			typeof(loadout_state.get("relic_slot_limit", null)) != TYPE_INT or \
			typeof(loadout_state.get("rng_state", null)) != TYPE_INT or \
			not loadout_state.get("offer_weights", null) is Dictionary or \
			not _sandbox_snapshot_value_supported(loadout_state["offer_weights"]):
		return false
	var chest_state: Variant = snapshot["chest_director"]
	if not chest_state is Dictionary or chest_state.size() != 2 or \
			typeof(chest_state.get("rng_state", null)) != TYPE_INT or \
			not chest_state.get("last_drop_time", null) is Dictionary or \
			not _sandbox_snapshot_value_supported(chest_state["last_drop_time"]):
		return false
	return true

func restore_sandbox_snapshot_state(snapshot: Dictionary) -> bool:
	if not can_restore_sandbox_snapshot_state(snapshot):
		return false
	for field in snapshot["script_fields"]:
		var value: Variant = snapshot["script_fields"][field]
		set(field, value.duplicate(true) if value is Array or value is Dictionary else value)
	_sandbox_rng.seed = int(snapshot["rng_seed"])
	_sandbox_rng.state = int(snapshot["rng_state"])
	player.global_position = snapshot["player_position"]
	player.velocity = snapshot["player_velocity"]
	var last_target: Dictionary = snapshot["last_target"]
	_last_target = last_target["position"] if bool(last_target["valid"]) else Vector2(INF, INF)
	var director: Dictionary = snapshot["wave_director"]
	wave_director.wave = int(director["wave"])
	wave_director.elapsed_in_wave = float(director["elapsed_in_wave"])
	wave_director.state = int(director["state"])
	wave_director.wave_duration_seconds = float(director["wave_duration_seconds"])
	wave_director.endless_armorless = bool(director["endless_armorless"])
	var loadout_state: Dictionary = snapshot["loadout"]
	loadout._weapon_slot_limit = int(loadout_state["weapon_slot_limit"])
	loadout._relic_slot_limit = int(loadout_state["relic_slot_limit"])
	loadout._rng.state = int(loadout_state["rng_state"])
	loadout.offer_weights = loadout_state["offer_weights"].duplicate(true)
	var chest_state: Dictionary = snapshot["chest_director"]
	_chest_director._last_drop_time = chest_state["last_drop_time"].duplicate(true)
	_chest_director._rng.state = int(chest_state["rng_state"])
	_refresh_player_move_speed()
	_refresh_hud(simulation.snapshot())
	return true

func _sandbox_snapshot_script_fields() -> Dictionary:
	var fields: Dictionary = {}
	for property in get_property_list():
		if (int(property.get("usage", 0)) & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue
		var field := str(property.get("name", ""))
		var value: Variant = get(field)
		if _sandbox_snapshot_value_supported(value):
			fields[field] = value.duplicate(true) if value is Array or value is Dictionary else value
	return fields

func _sandbox_snapshot_value_supported(value: Variant, depth: int = 0) -> bool:
	if depth > 32 or typeof(value) not in SANDBOX_SNAPSHOT_VALUE_TYPES:
		return false
	if typeof(value) == TYPE_FLOAT and not is_finite(value):
		return false
	if value is Vector2 and not value.is_finite():
		return false
	if value is Array:
		for item in value:
			if not _sandbox_snapshot_value_supported(item, depth + 1):
				return false
	elif value is Dictionary:
		for key in value:
			if not _sandbox_snapshot_value_supported(key, depth + 1) or \
					not _sandbox_snapshot_value_supported(value[key], depth + 1):
				return false
	return true

func _random_float(purpose: String) -> float:
	var value: float = _sandbox_rng.randf() if sandbox_diagnostics_enabled else randf()
	if sandbox_diagnostics_enabled:
		_sandbox_rng_log.append({"time": _last_simulation_time, "purpose": purpose, "value": value})
		if _sandbox_rng_log.size() > MAX_SANDBOX_RNG_LOG_ENTRIES:
			_sandbox_rng_log.pop_front()
	return value

func _random_float_range(from: float, to: float, purpose: String) -> float:
	return lerpf(from, to, _random_float(purpose))

func _roll_equipment_critical_multiplier() -> float:
	var chance := _critical_chance()
	if _random_float("critical_hit_roll") * 100.0 < chance:
		_last_attack_critical_hit = true
		return 1.5 + (_equipment_bonus("critical_damage_pct") + loadout.global_relic_bonus("critical_damage_pct") + _xp_run_stat_bonus("critical_damage_pct")) / 100.0
	_last_attack_critical_hit = false
	return 1.0

func _critical_chance() -> float:
	return clampf(_equipment_bonus("critical_chance_pct") + _cached_skill_critical_chance_pct + _xp_run_stat_bonus("critical_chance_pct"), 0.0, 100.0)

func _equipment_projectile_speed(base_speed: float) -> float:
	return base_speed * (1.0 + (_equipment_bonus("projectile_speed_pct") + loadout.global_relic_bonus("projectile_speed_pct") + _xp_run_stat_bonus("projectile_speed_pct")) / 100.0)

func _equipment_area(base_area: float) -> float:
	return base_area * (1.0 + (_equipment_bonus("area_pct") + loadout.global_relic_bonus("area_pct") + _xp_run_stat_bonus("area_pct")) / 100.0)

func _has_unique_effect(effect_id: String) -> bool:
	return _cached_unique_effects.has(effect_id)

func _try_unique_lightning_burst(base_damage: float) -> void:
	if not _has_unique_effect("lightning_burst") or player_active_time < _next_unique_lightning_time or _random_float("unique_lightning_burst_roll") >= 0.1:
		return
	var target := _nearest_enemy(SURVIVAL_TARGETING.visible_range(lightning_range))
	if target.is_empty():
		return
	var direction: Vector2 = (target["position"] - player.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	if simulation.spawn_projectile("unique_lightning_burst", player.global_position + direction * 14.0,
			direction * _equipment_projectile_speed(lightning_projectile_speed), base_damage * 0.5,
			_equipment_area(lightning_projectile_radius), lightning_projectile_lifetime) > 0:
		_next_unique_lightning_time = player_active_time + 2.0
		_show_effect_feedback("LIGHTNING BURST")

func _try_evolution_shockwave(base_damage: float) -> void:
	if _evolution_shockwave_triggered or not _has_unique_effect("evolution_shockwave"):
		return
	if not loadout.has_any_evolved_weapon():
		return
	_evolution_shockwave_triggered = true
	_show_effect_feedback("EVOLUTION SHOCKWAVE")
	var count := 8
	for index in range(count):
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / float(count))
		simulation.spawn_projectile("evolution_shockwave", player.global_position + direction * 14.0,
			direction * 400.0, base_damage, 6.0, 0.3)

func _nearest_enemy(max_range: float) -> Dictionary:
	return SURVIVAL_TARGETING.select_enemy(_entities, player.global_position, max_range, "nearest")

func _farthest_enemy(max_range: float) -> Dictionary:
	return SURVIVAL_TARGETING.select_enemy(_entities, player.global_position, max_range, "farthest")

func _highest_threat_enemy(max_range: float) -> Dictionary:
	return SURVIVAL_TARGETING.select_enemy(_entities, player.global_position, max_range, "highest_threat")

func _highest_health_enemy(max_range: float) -> Dictionary:
	return SURVIVAL_TARGETING.select_enemy(_entities, player.global_position, max_range, "highest_health")

func _lowest_health_enemy(max_range: float) -> Dictionary:
	return SURVIVAL_TARGETING.select_enemy(_entities, player.global_position, max_range, "lowest_health")

func _enemy_by_id_in_range(target_id: Vector2i, max_range: float) -> Dictionary:
	var max_distance_squared := max_range * max_range
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if not _is_targetable_enemy(components):
			continue
		var id: Dictionary = entity["id"]
		if Vector2i(int(id["index"]), int(id["generation"])) != target_id:
			continue
		var transform: Dictionary = components["Transform2D"]
		var position := Vector2(float(transform["x"]), float(transform["y"]))
		if player.global_position.distance_squared_to(position) < max_distance_squared:
			return {"position": position, "id": target_id}
	return {}

func _is_targetable_enemy(components: Dictionary) -> bool:
	if components.get("IsProjectile", false) or components.get("IsXpOrb", false):
		return false
	if not components.has("Health"):
		return true
	var health: Variant = components["Health"]
	return health is Dictionary and float(health.get("current", 0.0)) > 0.0

func _publish_player_target() -> void:
	var target := player.global_position
	if target.distance_squared_to(_last_target) < 0.01:
		return
	_last_target = target
	last_target_sequence = simulation.set_steering_target(
		target, 75.0, enemy_separation_radius, enemy_separation_weight
	)

func _draw() -> void:
	var reduced_effects := _visual_effects_reduced()
	draw_texture_rect(GROUND_TEXTURE, Rect2(-8192.0, -8192.0, 16384.0, 16384.0), true)
	draw_texture_rect(RUINS_TEXTURE, Rect2(-768.0, -768.0, 1536.0, 1536.0), false, Color(1.0, 1.0, 1.0, 0.88))
	if _last_simulation_time < _magnet_heart_impulse_expires_at:
		var impulse_radius := xp_collection_radius * maxf(1.0, magnet_heart_level_five_radius_multiplier)
		draw_arc(player.global_position, impulse_radius, 0.0, TAU, 64, Color(0.22, 0.9, 1.0, 0.42), 1.5, true)
	if not reduced_effects:
		_sprite_renderer.draw_projectile_trails(self)
	_sprite_renderer.draw_batches(self)
	_sprite_renderer.draw_enemy_feedback(self, _entities)
	for attack in _shooter_attacks.values():
		if str(attack["phase"]) != "telegraph":
			continue
		var time_left := clampf(float(attack["fire_at"]) - _last_simulation_time, 0.0, shooter_telegraph_seconds)
		var alpha := 1.0 - time_left / maxf(shooter_telegraph_seconds, 0.01)
		draw_line(attack["origin"], attack["aim"], Color(1.0, 0.2, 0.28, 0.18 + alpha * 0.5), 2.0, true)
		draw_arc(attack["aim"], 14.0 + alpha * 5.0, 0.0, TAU, 32,
				Color(1.0, 0.2, 0.28, 0.45 + alpha * 0.5), 2.0, true)
	for attack in _exploder_attacks.values():
		if str(attack.get("phase", "")) == "detonated":
			continue
		var time_left := clampf(float(attack["detonate_at"]) - _last_simulation_time, 0.0, exploder_fuse_seconds)
		var alpha := 1.0 - time_left / maxf(exploder_fuse_seconds, 0.01)
		var origin: Vector2 = attack["origin"]
		draw_circle(origin, exploder_blast_radius, Color(1.0, 0.17, 0.08, 0.06 + alpha * 0.14))
		draw_arc(origin, exploder_blast_radius, 0.0, TAU, 48,
				Color(1.0, 0.24, 0.08, 0.4 + alpha * 0.5), 2.0 + alpha * 2.0, true)
		draw_arc(origin, 16.0 + alpha * 8.0, 0.0, TAU, 32,
				Color(1.0, 0.72, 0.25, 0.5 + alpha * 0.45), 2.0, true)
	for attack in _summoner_attacks.values():
		var time_left := clampf(float(attack["summon_at"]) - _last_simulation_time, 0.0, summoner_warmup_seconds)
		var alpha := 1.0 - time_left / maxf(summoner_warmup_seconds, 0.01)
		var spawn_position: Vector2 = attack["spawn_position"]
		draw_circle(spawn_position, 12.0, Color(0.7, 0.45, 1.0, 0.12 + alpha * 0.16))
		draw_arc(spawn_position, 14.0 + alpha * 4.0, 0.0, TAU, 32,
				Color(0.76, 0.58, 1.0, 0.45 + alpha * 0.5), 2.0, true)
	for attack in _pulse_warden_attacks.values():
		if str(attack.get("stage", "")) != "telegraph":
			continue
		var time_left := clampf(float(attack["fire_at"]) - _last_simulation_time, 0.0, pulse_warden_telegraph_seconds)
		var alpha := 1.0 - time_left / maxf(pulse_warden_telegraph_seconds, 0.01)
		var origin: Vector2 = attack["origin"]
		if str(attack["pattern"]) == "radial":
			draw_circle(origin, 32.0 + alpha * 48.0, Color(1.0, 0.28, 0.2, 0.04 + alpha * 0.08))
			draw_arc(origin, 32.0 + alpha * 48.0, 0.0, TAU, 48,
					Color(1.0, 0.4, 0.26, 0.35 + alpha * 0.55), 2.0, true)
		elif str(attack["pattern"]) == "charge":
			var aim: Vector2 = attack["aim"]
			draw_line(origin, aim, Color(1.0, 0.82, 0.25, 0.28 + alpha * 0.62), 8.0 + alpha * 4.0, true)
			draw_line(origin, aim, Color(1.0, 0.98, 0.72, 0.35 + alpha * 0.55), 2.0, true)
			draw_arc(aim, 20.0 + alpha * 6.0, 0.0, TAU, 32,
					Color(1.0, 0.82, 0.25, 0.4 + alpha * 0.5), 2.0, true)
		else:
			var aim: Vector2 = attack["aim"]
			draw_line(origin, aim, Color(1.0, 0.3, 0.24, 0.2 + alpha * 0.55), 3.0, true)
			draw_arc(aim, 16.0 + alpha * 4.0, 0.0, TAU, 32,
					Color(1.0, 0.43, 0.25, 0.4 + alpha * 0.5), 2.0, true)
	for attack in _dopamine_core_attacks.values():
		if str(attack.get("stage", "")) != "telegraph":
			continue
		var time_left := clampf(float(attack["fire_at"]) - _last_simulation_time, 0.0, final_boss_telegraph_seconds)
		var alpha := 1.0 - time_left / maxf(final_boss_telegraph_seconds, 0.01)
		var origin: Vector2 = attack["origin"]
		var aim: Vector2 = attack["aim"]
		var pattern: String = str(attack["pattern"])
		var danger_color := Color(0.82, 0.32, 1.0, 0.22 + alpha * 0.55)
		if pattern == "ray" or pattern == "combined":
			draw_line(origin, aim, danger_color, 3.0 + alpha * 2.0, true)
			draw_arc(aim, final_boss_ray_width, 0.0, TAU, 32, danger_color, 2.0, true)
		if pattern == "zone" or pattern == "combined":
			draw_circle(aim, final_boss_zone_radius, Color(0.75, 0.25, 1.0, 0.06 + alpha * 0.12))
			draw_arc(aim, final_boss_zone_radius, 0.0, TAU, 48, danger_color, 2.0 + alpha, true)
		if pattern == "spiral" or pattern == "combined":
			var ring_radius := 34.0 + alpha * 36.0
			draw_circle(origin, ring_radius, Color(0.68, 0.25, 1.0, 0.04 + alpha * 0.08))
			draw_arc(origin, ring_radius, 0.0, TAU, 48, danger_color, 2.0, true)
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if not components.get("IsProjectile", false) or not ["void_orb", "event_horizon"].has(str(components.get("EnemyType", ""))):
			continue
		var projectile: Dictionary = components.get("Projectile", {})
		var radius := float(projectile.get("attraction_radius", 0.0))
		if radius > 0.0:
			var transform: Dictionary = components["Transform2D"]
			var center := Vector2(float(transform["x"]), float(transform["y"]))
			var ring_color := Color(0.75, 0.46, 1.0, 0.22) if str(components["EnemyType"]) == "event_horizon" else Color(0.48, 0.3, 0.9, 0.14)
			draw_arc(center, radius, 0.0, TAU, 48, ring_color, 1.5, true)
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) and ["frost_nova", "absolute_zero"].has(str(components.get("EnemyType", ""))):
			var projectile: Dictionary = components.get("Projectile", {})
			var transform: Dictionary = components["Transform2D"]
			var center := Vector2(float(transform["x"]), float(transform["y"]))
			var radius := float(projectile.get("radius", 0.0))
			var alpha := clampf(float(projectile.get("remaining_seconds", 0.0)) / maxf(frost_nova_duration_seconds, 0.01), 0.0, 1.0)
			draw_circle(center, radius, Color(0.45, 0.83, 1.0, 0.10 * alpha))
			draw_arc(center, radius, 0.0, TAU, 64, Color(0.72, 0.95, 1.0, 0.8 * alpha), 3.0, true)
		elif components.has("Chill"):
			var transform: Dictionary = components["Transform2D"]
			var center := Vector2(float(transform["x"]), float(transform["y"]))
			draw_arc(center, 12.0, 0.0, TAU, 24, Color(0.55, 0.85, 1.0, 0.65), 2.0, true)
		if (components.has("DamageOverTime") or components.has("DamageOverTimeEffects")) and not components.get("IsProjectile", false):
			var status_transform: Dictionary = components["Transform2D"]
			var status_center := Vector2(float(status_transform["x"]), float(status_transform["y"]))
			var statuses: Array = components.get("DamageOverTimeEffects", [components.get("DamageOverTime", {})])
			for status_index in statuses.size():
				var status: Dictionary = statuses[status_index]
				var status_color := _status_effect_color(str(status.get("status_type", "generic")))
				draw_arc(status_center, 14.0 + float(status_index) * 3.0, 0.0, TAU, 24, status_color, 2.0, true)
		if not components.get("IsProjectile", false):
			var entity_id: Dictionary = entity.get("id", {})
			var shock_key := _entity_key(int(entity_id.get("index", -1)), int(entity_id.get("generation", -1)))
			if _last_simulation_time < float(_overcharge_shock_expires_at.get(shock_key, 0.0)):
				var shock_transform: Dictionary = components["Transform2D"]
				var shock_center := Vector2(float(shock_transform["x"]), float(shock_transform["y"]))
				draw_arc(shock_center, 19.0, 0.0, TAU, 24, Color(0.28, 0.83, 1.0, 0.9), 2.0, true)
	for beam in _prism_beams:
		var beam_color := Color(0.55, 0.95, 1.0, 0.78) if bool(beam["secondary"]) else Color(1.0, 0.92, 0.55, 0.9)
		draw_line(beam["from"], beam["to"], beam_color, 5.0 if not beam["secondary"] else 3.0, true)
		draw_line(beam["from"], beam["to"], Color(1.0, 1.0, 1.0, 0.9), 1.5, true)
	if not reduced_effects:
		for arc in _lightning_arcs:
			var fade: float = clampf(float(arc["remaining"]) / LIGHTNING_ARC_LIFETIME, 0.0, 1.0)
			draw_polyline(arc["points"], Color(0.2, 0.9, 1.0, 0.85 * fade), 4.0, true)
			draw_polyline(arc["points"], Color(1.0, 1.0, 1.0, 0.95 * fade), 1.3, true)
		for burst in _pandemic_bursts:
			var fade := clampf(float(burst["remaining"]) / maxf(pandemic_feedback_seconds, 0.01), 0.0, 1.0)
			draw_circle(burst["position"], pandemic_spread_radius * (1.0 - fade * 0.35), Color(0.35, 1.0, 0.4, 0.18 * fade))
	for chest in _world_chests:
		draw_texture_rect(CHEST_TEXTURE, Rect2(chest["position"] - Vector2.ONE * CHEST_SPRITE_SIZE * 0.5,
			Vector2.ONE * CHEST_SPRITE_SIZE), false)
	if not reduced_effects:
		for impact in _weapon_impacts:
			var remaining: float = float(impact["remaining"])
			var fade := clampf(remaining / WEAPON_IMPACT_LIFETIME, 0.0, 1.0)
			var scale := 0.7 + 0.5 * (1.0 - fade)
			draw_set_transform(impact["position"], float(impact["rotation"]),
					Vector2.ONE * scale * _weapon_impact_level_scale(int(impact.get("level", 1))))
			draw_texture_rect_region(WEAPON_IMPACTS_TEXTURE, Rect2(-32.0, -32.0, 64.0, 64.0),
				Rect2(float(impact["type"]) * 64.0, 0.0, 64.0, 64.0), Color(1.0, 1.0, 1.0, fade))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for pixel in _enemy_death_pixels:
			var fade := clampf(float(pixel["remaining"]) / ENEMY_DEATH_PIXEL_LIFETIME, 0.0, 1.0)
			var pixel_size := float(pixel["size"])
			var particle_color: Color = pixel["color"]
			particle_color.a *= fade
			draw_rect(Rect2(pixel["position"] - Vector2.ONE * pixel_size * 0.5, Vector2.ONE * pixel_size), particle_color)

func _add_enemy_death_pixels(enemy_type: String, position: Vector2) -> void:
	if _visual_effects_reduced() or not ENEMY_DEATH_TYPES.has(enemy_type):
		return
	for index in range(ENEMY_DEATH_PIXEL_COUNT):
		var speed := 24.0 + float(index % 3) * 12.0
		_enemy_death_pixels.append({
			"position": position,
			"velocity": Vector2.RIGHT.rotated(TAU * float(index) / ENEMY_DEATH_PIXEL_COUNT) * speed,
			"size": 2.0 if index % 2 == 0 else 3.0,
			"color": ENEMY_DEATH_PALETTE[index % ENEMY_DEATH_PALETTE.size()],
			"remaining": ENEMY_DEATH_PIXEL_LIFETIME,
		})
	while _enemy_death_pixels.size() > MAX_ENEMY_DEATH_PIXELS:
		_enemy_death_pixels.pop_front()

func _add_weapon_impact(source_type: String, position: Vector2, is_damage_over_time: bool) -> void:
	var impact_type := source_type.get_slice(":", 0)
	if impact_type in ["lightning_primary", "lightning_arc"]:
		impact_type = "lightning_conductor"
	if is_damage_over_time or not WEAPON_IMPACT_TYPES.has(impact_type):
		return
	var rotation := _random_float_range(-0.25, 0.25, "enemy_death_particle_rotation")
	if _visual_effects_reduced():
		return
	if _weapon_impacts.size() >= MAX_VISIBLE_WEAPON_IMPACTS:
		_weapon_impacts.pop_front()
	var weapon_id: String = WEAPON_IMPACT_SOURCE_IDS.get(impact_type, "")
	var level: int = loadout.weapon_level(weapon_id) if not weapon_id.is_empty() else 1
	_weapon_impacts.append({
		"type": int(WEAPON_IMPACT_TYPES[impact_type]),
		"position": position,
		"rotation": rotation,
		"level": level,
		"remaining": WEAPON_IMPACT_LIFETIME,
	})

func _weapon_impact_level_scale(level: int) -> float:
	return 1.0 + 0.06 * float(clampi(level - 1, 0, 4)) # [PROPOSED] visual-only emphasis per weapon level.

func _visual_effects_reduced() -> bool:
	return _settings_service != null and _settings_service.reduced_visual_effects_enabled

func _on_settings_changed() -> void:
	if _visual_effects_reduced():
		_weapon_impacts.clear()
		_enemy_death_pixels.clear()
		_lightning_arcs.clear()
		_pandemic_bursts.clear()
	queue_redraw()

func _status_effect_color(status_type: String) -> Color:
	return STATUS_EFFECT_COLORS.get(status_type, GENERIC_STATUS_COLOR)
