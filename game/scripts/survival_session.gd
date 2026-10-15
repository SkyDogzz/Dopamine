extends Node2D

signal chest_option_chosen(option_id: String)

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const SPRITE_RENDERER_SCRIPT := preload("res://scripts/sprite_batch_renderer.gd")
const CHEST_TEXTURE: Texture2D = preload("res://assets/sprites/chest_closed.png")
const GROUND_TEXTURE: Texture2D = preload("res://assets/sprites/survival_ground.svg")
const RUINS_TEXTURE: Texture2D = preload("res://assets/sprites/survival_ruins.svg")
const WEAPON_IMPACTS_TEXTURE: Texture2D = preload("res://assets/sprites/weapon_impacts.svg")
const WEAPON_IMPACT_TYPES := {
	"lightning_conductor": 0, "infinite_circuit_branch": 0, "unique_lightning_burst": 0,
	"inferno_sprayer": 1, "wildfire_sprayer": 1,
	"crimson_dagger": 2, "bloodstorm_dagger": 2,
	"minigun": 3,
	"toxic_cloud": 4, "pandemic_cloud": 4,
	"sawblades": 5, "razorstorm": 5,
	"meteor_staff": 6, "starfall": 6, "starfall_fragment": 6,
	"prism_laser": 7, "spectrum_collapse": 7, "prism_secondary": 7,
	"void_orb": 8, "event_horizon": 8,
	"frost_nova": 9, "absolute_zero": 9,
}
const WEAPON_IMPACT_LIFETIME := 0.22
const MAX_VISIBLE_WEAPON_IMPACTS := 32
const WEAPON_ICONS := {
	"lightning_conductor": preload("res://assets/sprites/projectile_lightning.png"),
	"inferno_sprayer": preload("res://assets/sprites/projectile_inferno.png"),
	"crimson_daggers": preload("res://assets/sprites/projectile_crimson.png"),
	"minigun": preload("res://assets/sprites/projectile_minigun.svg"),
	"toxic_cloud": preload("res://assets/sprites/projectile_toxic_cloud.svg"),
	"sawblades": preload("res://assets/sprites/projectile_sawblades.svg"),
	"meteor_staff": preload("res://assets/sprites/projectile_meteor.svg"),
	"prism_laser": preload("res://assets/sprites/projectile_prism_laser.svg"),
	"void_orb": preload("res://assets/sprites/projectile_void_orb.svg"),
	"frost_nova": preload("res://assets/sprites/projectile_frost_nova.svg"),
}
const WAVE_DIRECTOR_SCRIPT := preload("res://scripts/survival_wave_director.gd")
const LOADOUT_SCRIPT := preload("res://scripts/survival_loadout.gd")
const CHEST_DIRECTOR_SCRIPT := preload("res://scripts/survival_chest_director.gd")
const WAVE_HP_GROWTH := 1.12
const WAVE_HP_CAP := 12.0

@export var spawn_initial_enemy: bool = true
@export var wave_spawning_enabled: bool = true
@export var skip_starting_weapon_choice: bool = false
@export_group("Prototype wave director — proposed tuning")
@export var wave_duration_seconds: float = 30.0
@export_range(1, 400) var wave_population_cap: int = 80
@export var wave_population_scale: float = 1.0
@export var enemy_spawn_interval: float = 0.5
@export var enemy_spawn_radius: float = 520.0
@export var boss_placeholder_hp: float = 1000.0
@export_group("Prototype loot — proposed rates")
@export var ordinary_chest_drop_chance: float = 0.005
@export var elite_chest_drop_chance: float = 0.15
@export var chest_guarantee_interval_seconds: float = 60.0
@export var chest_collection_radius: float = 36.0
@export_group("Prototype contact damage — proposed tuning")
@export var contact_damage_per_hit: float = 10.0
@export var contact_invulnerability_seconds: float = 0.35
@export var player_contact_radius: float = 10.0
@export var enemy_contact_radius: float = 8.0
@export var enemy_separation_radius: float = 18.0
@export_range(0.0, 1.0) var enemy_separation_weight: float = 0.5
@export_group("Prototype Lightning Conductor — proposed tuning")
@export var weapon_enabled: bool = true
@export var lightning_cooldown: float = 0.5
@export var lightning_damage: float = 12.0
@export var lightning_range: float = 300.0
@export var lightning_projectile_speed: float = 800.0
@export var lightning_projectile_radius: float = 4.0
@export var lightning_projectile_lifetime: float = 2.0
@export_range(1, 5) var lightning_chain_count: int = 2
@export_group("Prototype Inferno Sprayer — proposed tuning")
@export var inferno_cooldown: float = 0.7
@export var inferno_damage: float = 8.0
@export var inferno_range: float = 520.0
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
@export var daggers_range: float = 480.0
@export var daggers_projectile_speed: float = 900.0
@export var daggers_projectile_radius: float = 2.5
@export var daggers_projectile_lifetime: float = 0.8
@export_group("Prototype Minigun — proposed tuning")
@export var minigun_cooldown: float = 0.18
@export var minigun_damage: float = 4.0
@export var minigun_range: float = 620.0
@export_range(0.0, 0.5) var minigun_spread_radians: float = 0.03
@export var minigun_projectile_speed: float = 1100.0
@export var minigun_projectile_radius: float = 3.0
@export var minigun_projectile_lifetime: float = 0.8
@export_range(0.0, 1.0) var overdrive_cadence_per_level: float = 0.04
@export var redline_max_cadence_bonus: float = 0.5
@export var redline_ramp_seconds: float = 5.0
@export_group("Prototype Toxic Cloud — proposed tuning")
@export var toxic_cooldown: float = 1.4
@export var toxic_impact_damage: float = 3.0
@export var toxic_range: float = 560.0
@export var toxic_projectile_speed: float = 430.0
@export var toxic_projectile_radius: float = 4.0
@export var toxic_projectile_lifetime: float = 1.8
@export var toxic_cloud_radius: float = 52.0
@export_range(0.0, 1.0) var toxic_splash_damage_multiplier: float = 0.5
@export var toxic_damage_per_tick: float = 1.5
@export var toxic_tick_interval_seconds: float = 0.5
@export var toxic_status_duration_seconds: float = 2.0
@export_range(0.0, 1.0) var plague_mask_dot_per_level: float = 0.05
@export var pandemic_spread_radius: float = 140.0
@export_range(1, 8) var pandemic_max_spread_targets: int = 3
@export var pandemic_feedback_seconds: float = 0.35
@export_group("Prototype Sawblades — proposed tuning")
@export var sawblades_cooldown: float = 1.8
@export var sawblades_damage: float = 8.0
@export var sawblades_range: float = 520.0
@export var sawblades_projectile_speed: float = 360.0
@export var sawblades_projectile_radius: float = 7.0
@export var sawblades_projectile_lifetime: float = 2.5
@export_range(0.0, 1.0) var magnetic_coil_projectile_speed_per_level: float = 0.04
@export_group("Prototype Meteor Staff — proposed tuning")
@export var meteor_staff_cooldown: float = 2.8
@export var meteor_staff_damage: float = 12.0
@export var meteor_staff_range: float = 620.0
@export var meteor_staff_projectile_speed: float = 300.0
@export var meteor_staff_projectile_radius: float = 8.0
@export var meteor_staff_projectile_lifetime: float = 2.5
@export var meteor_staff_cluster_radius: float = 110.0
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
@export var prism_laser_range: float = 620.0
@export var prism_laser_projectile_speed: float = 1800.0
@export var prism_laser_projectile_radius: float = 1.5
@export var prism_crystal_critical_damage_per_level: float = 0.03
@export_range(0, 4) var spectrum_collapse_secondary_beams: int = 2
@export_group("Prototype Void Orb — proposed tuning")
@export var void_orb_cooldown: float = 2.4
@export var void_orb_damage: float = 7.0
@export var void_orb_range: float = 620.0
@export var void_orb_speed: float = 230.0
@export var void_orb_lifetime: float = 3.0
@export var void_orb_radius: float = 5.0
@export var void_orb_attraction_radius: float = 135.0
@export var void_orb_attraction_speed: float = 85.0
@export_range(0.0, 1.0) var singularity_control_per_level: float = 0.05
@export_group("Prototype Frost Nova — proposed tuning")
@export var frost_nova_cooldown: float = 3.0
@export var frost_nova_damage: float = 8.0
@export var frost_nova_radius: float = 145.0
@export var frost_nova_duration_seconds: float = 0.12
@export var frost_chill_duration_seconds: float = 2.0
@export_range(0.0, 1.0) var frost_chill_speed_multiplier: float = 0.65
@export_range(0.0, 1.0) var frozen_crown_chill_duration_per_level: float = 0.05
@export var frozen_crown_vulnerability_at_level_five: float = 0.25
@export var absolute_zero_shatter_radius: float = 76.0
@export_range(0.0, 2.0) var absolute_zero_shatter_damage_multiplier: float = 0.75
@export_group("Prototype Bloodstorm — proposed tuning")
@export var bloodstorm_bleed_damage_per_tick: float = 2.0
@export var bloodstorm_bleed_interval_seconds: float = 0.5
@export var bloodstorm_bleed_duration_seconds: float = 2.0
@export_group("Prototype relic bonuses — proposed tuning")
@export_range(0.0, 1.0) var storm_core_damage_per_level: float = 0.05
@export_range(0.0, 1.0) var infernal_heart_damage_per_level: float = 0.05
@export_range(0.0, 1.0) var blood_chalice_heal_per_level: float = 0.10
@export_range(0.0, 1.0) var blood_chalice_lifesteal_per_level: float = 0.05
@export_group("Prototype Magnet Heart — proposed tuning")
@export_range(0.0, 1.25, 0.01) var magnet_heart_pickup_radius_per_level: float = 0.25
@export_group("Prototype XP — proposed tuning")
@export var xp_per_enemy: float = 5.0
@export var xp_collection_radius: float = 36.0
@export var xp_base_to_next_level: float = 10.0
@export var xp_growth_per_level: float = 5.0

var simulation: Object
var progression_service: RefCounted
var _sprite_renderer: RefCounted
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
var _boss_spawn_pending := false
var player_level := 1
var player_xp := 0.0
var player_xp_to_next := 10.0
var run_over := false
var _victory_pending := false
var kill_count := 0
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
var _redline_fire_time := 0.0
var _redline_target_id := Vector2i(-1, -1)
var _pandemic_poisoned_targets: Dictionary = {}
var _pandemic_spread_targets: Dictionary = {}
var _pandemic_bursts: Array[Dictionary] = []
var _weapon_impacts: Array[Dictionary] = []
var _starfall_fragments_spawned: Dictionary = {}
var _entities: Array = []
var _pending_xp_orbs: Dictionary = {}
var _chest_director: RefCounted
var _world_chests: Array[Dictionary] = []
var _chest_open := false
var _starting_weapon_choice_open := false
var _contact_invulnerable_until := 0.0
var _pending_lifesteal := 0.0
var _inventory_was_running := false
var _cached_persistent_damage_multiplier := 1.0
var _cached_equipment_bonuses: Dictionary = {}
var _cached_unique_effects: Array[String] = []
var _base_player_move_speed := 240.0
var _next_unique_lightning_time := 0.0
var _evolution_shockwave_triggered := false
var _elite_haste_expires_at := 0.0

@onready var _hp_value: Label = $HUD/RunPanel/RunInfo/HPValue
@onready var _hp_bar: ProgressBar = $HUD/RunPanel/RunInfo/HPBar
@onready var _time_value: Label = $HUD/RunPanel/RunInfo/TimeValue
@onready var _weapon_value: Label = $HUD/RunPanel/RunInfo/WeaponValue
@onready var _weapon_icon: TextureRect = $HUD/RunPanel/RunInfo/WeaponIcon
@onready var _xp_value: Label = $HUD/RunPanel/RunInfo/XPValue
@onready var _xp_bar: ProgressBar = $HUD/RunPanel/RunInfo/XPBar
@onready var _run_state: Label = $HUD/RunPanel/RunInfo/RunState
@onready var _wave_value: Label = $HUD/RunPanel/RunInfo/WaveValue
@onready var _boss_panel: PanelContainer = $HUD/BossPanel
@onready var _boss_value: Label = $HUD/BossPanel/BossInfo/BossValue
@onready var _boss_hp_bar: ProgressBar = $HUD/BossPanel/BossInfo/BossHPBar
@onready var _chest_choice: PanelContainer = $HUD/ChestOverlay/ChestChoice
@onready var _equipment_button: Button = $HUD/EquipmentButton
@onready var _equipment_panel: CenterContainer = $HUD/EquipmentInventoryOverlay
@onready var _skill_tree_button: Button = $HUD/SkillsButton
@onready var _skill_tree_panel: CenterContainer = $HUD/SkillTreeOverlay
@onready var _run_result_overlay: CenterContainer = $HUD/RunResultOverlay
@onready var _run_result: PanelContainer = $HUD/RunResultOverlay/RunResultPanel

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite_renderer = SPRITE_RENDERER_SCRIPT.new()
	_run_id = Crypto.new().generate_random_bytes(16).hex_encode()
	player = PLAYER_SCENE.instantiate()
	player.name = "Player"
	add_child(player)
	player.controls_enabled = false
	loadout = LOADOUT_SCRIPT.new()
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
	_run_result.restart_requested.connect(_restart_run)
	_equipment_button.pressed.connect(_open_equipment_inventory)
	_skill_tree_button.pressed.connect(_open_skill_tree)
	_equipment_panel.close_requested.connect(_close_equipment_inventory)
	_equipment_panel.equipment_state_requested.connect(_set_equipment_state)
	_equipment_panel.enhancement_requested.connect(_enhance_equipment)
	_equipment_panel.unique_effect_requested.connect(_choose_unique_effect)
	_equipment_panel.dismantle_requested.connect(_dismantle_equipment)
	_equipment_panel.progression_service = progression_service
	_skill_tree_panel.close_requested.connect(_close_skill_tree)
	_skill_tree_panel.unlock_requested.connect(_unlock_skill_node)
	_skill_tree_panel.respec_requested.connect(_respec_skill_tree)
	_skill_tree_panel.progression_service = progression_service
	_equipment_button.visible = progression_service != null
	_skill_tree_button.visible = progression_service != null
	player_max_hp = simulation.initial_player_hp()
	_base_player_move_speed = player.move_speed
	if progression_service != null:
		_refresh_persistent_bonuses()
		player_max_hp *= 1.0 + progression_service.skill_bonus("max_hp_pct")
		player_max_hp += _equipment_bonus("max_hp")
	player_hp = player_max_hp
	player_xp_to_next = xp_base_to_next_level
	wave_director = WAVE_DIRECTOR_SCRIPT.new()
	wave_director.wave_duration_seconds = wave_duration_seconds
	_publish_player_target()
	if spawn_initial_enemy and not wave_spawning_enabled:
		simulation.spawn_enemy("chaser", 1, player.global_position + Vector2(140.0, 0.0), Vector2.ZERO)
	if skip_starting_weapon_choice:
		loadout.choose_starting_weapon("lightning_conductor")
		simulation.resume()
	else:
		_starting_weapon_choice_open = true
		_chest_choice.present(loadout.starting_weapon_options(), 2, "CHOOSE YOUR STARTING WEAPON")

func _physics_process(_delta: float) -> void:
	_publish_player_target()

func _process(_delta: float) -> void:
	if simulation == null:
		return
	var state: Dictionary = simulation.snapshot()
	var current_simulation_time: float = float(state["simulation_time"])
	var elapsed_active_time := current_simulation_time - _last_simulation_time
	for index in range(_pandemic_bursts.size() - 1, -1, -1):
		_pandemic_bursts[index]["remaining"] = float(_pandemic_bursts[index]["remaining"]) - elapsed_active_time
		if float(_pandemic_bursts[index]["remaining"]) <= 0.0:
			_pandemic_bursts.remove_at(index)
	for index in range(_weapon_impacts.size() - 1, -1, -1):
		_weapon_impacts[index]["remaining"] = float(_weapon_impacts[index]["remaining"]) - elapsed_active_time
		if float(_weapon_impacts[index]["remaining"]) <= 0.0:
			_weapon_impacts.remove_at(index)
	if elapsed_active_time > 0.0 and not run_over:
		if player_shield > 0.0 and player_active_time >= _shield_expires_at:
			player_shield = 0.0
		_take_player_damage(simulation.health_decay_amount(player_active_time, elapsed_active_time))
		player_active_time += elapsed_active_time
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
				_add_weapon_impact(source_type, Vector2(float(event["position"]["x"]), float(event["position"]["y"])),
						bool(event.get("is_damage_over_time", false)))
				if source_type == "pandemic_cloud":
					_pandemic_poisoned_targets[target_key] = true
				elif source_type == "starfall":
					if not _starfall_fragments_spawned.has(source_key):
						_starfall_fragments_spawned[source_key] = true
						_spawn_starfall_fragments(Vector2(float(event["position"]["x"]), float(event["position"]["y"])),
								damage_target, state["entities"])
				var damage_lifesteal := float(event["amount"]) * float(loadout.relic_level("blood_chalice")) * blood_chalice_lifesteal_per_level
				if bool(event.get("is_damage_over_time", false)):
					damage_lifesteal *= 0.25
				_pending_lifesteal += damage_lifesteal
			"death":
				kill_count += 1
				var dead_target: Dictionary = event["target"]
				if bool(event.get("target_was_chilled", false)) and loadout.weapon_level("frost_nova") >= 5 and loadout.relic_level("frozen_crown") > 0 and str(event.get("source_type", "")) != "absolute_zero":
					var shatter_position := Vector2(float(event["position"]["x"]), float(event["position"]["y"]))
					simulation.spawn_projectile("absolute_zero", shatter_position, Vector2.ZERO,
							frost_nova_damage * absolute_zero_shatter_damage_multiplier,
							_equipment_area(absolute_zero_shatter_radius), frost_nova_duration_seconds,
							2.0, 0.5, 2.0, 0.0, 0.0, 0, 0.0, 0.0, true)
				var dead_key := _entity_key(int(dead_target["index"]), int(dead_target["generation"]))
				if _pandemic_poisoned_targets.has(dead_key) and not _pandemic_spread_targets.has(dead_key):
					_pandemic_spread_targets[dead_key] = true
					_spread_pandemic(Vector2(float(event["position"]["x"]), float(event["position"]["y"])), state["entities"])
				_pandemic_poisoned_targets.erase(dead_key)
				var dead_enemy_type: String = str(event.get("target_type", ""))
				if dead_enemy_type == "elite" and _has_unique_effect("elite_haste"):
					_elite_haste_expires_at = player_active_time + 3.0
					_refresh_player_move_speed()
				if dead_enemy_type == "mid_boss":
					_boss_spawn_pending = false
					wave_director.boss_defeated()
				elif dead_enemy_type == "final_boss":
					_boss_spawn_pending = false
					wave_director.boss_defeated()
					_victory_pending = true
				_roll_enemy_chests(dead_enemy_type, Vector2(
					float(event["position"]["x"]), float(event["position"]["y"])
				))
				if not run_over:
					var healing: float = float(simulation.kill_heal_amount(float(event["threat_level"])))
					healing *= 1.0 + float(loadout.relic_level("blood_chalice")) * blood_chalice_heal_per_level
					healing *= 1.0 + _equipment_bonus("kill_healing_pct") / 100.0
					player_hp = minf(player_max_hp, player_hp + healing)
					simulation.spawn_xp_orb(
						Vector2(float(event["position"]["x"]), float(event["position"]["y"])),
						xp_per_enemy * (1.0 + _equipment_bonus("xp_pct") / 100.0)
					)
			"xp_collected":
				var id: Dictionary = event["target"]
				_pending_xp_orbs.erase(_entity_key(int(id["index"]), int(id["generation"])))
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
	player.controls_enabled = not state["paused"] and not run_over and not _chest_open and not _starting_weapon_choice_open
	_refresh_hud(state)
	queue_redraw()

func _apply_contact_damage(state: Dictionary, current_simulation_time: float) -> void:
	if state["paused"] or run_over or current_simulation_time < _contact_invulnerable_until:
		return
	var contact_distance := player_contact_radius + enemy_contact_radius
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if not components.has("EnemyType") or components.get("IsProjectile", false) or components.get("IsXpOrb", false):
			continue
		var transform: Dictionary = components["Transform2D"]
		var enemy_position := Vector2(float(transform["x"]), float(transform["y"]))
		if player.global_position.distance_squared_to(enemy_position) > contact_distance * contact_distance:
			continue
		_take_player_damage(contact_damage_per_hit)
		_contact_invulnerable_until = current_simulation_time + contact_invulnerability_seconds
		return

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
	var absorbed := minf(player_shield, amount)
	player_shield -= absorbed
	player_hp = maxf(0.0, player_hp - (amount - absorbed))

func _refresh_hud(state: Dictionary) -> void:
	_hp_value.text = "HP  %.1f / %.0f%s" % [
		player_hp, player_max_hp, "  •  SHIELD %.1f" % player_shield if player_shield > 0.0 else "",
	]
	_hp_bar.max_value = player_max_hp
	_hp_bar.value = player_hp
	_xp_value.text = "LV %d  XP %.0f / %.0f" % [player_level, player_xp, player_xp_to_next]
	_xp_bar.max_value = player_xp_to_next
	_xp_bar.value = player_xp
	if wave_director != null:
		_wave_value.text = _wave_status_text()
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
		if weapon_id == "minigun" and loadout.weapon_level(weapon_id) >= 5 and loadout.relic_level("overdrive_engine") > 0:
			label += " REDLINE"
		if weapon_id == "toxic_cloud" and loadout.weapon_level(weapon_id) >= 5 and loadout.relic_level("plague_mask") > 0:
			label += " PANDEMIC"
		if weapon_id == "sawblades" and loadout.weapon_level("sawblades") >= 5 and loadout.relic_level("magnetic_coil") > 0:
			label += " RAZORSTORM"
		if weapon_id == "meteor_staff" and loadout.weapon_level("meteor_staff") >= 5 and loadout.relic_level("celestial_eye") > 0:
			label += " STARFALL"
		equipped_names.append(label)
	_weapon_value.text = "  •  ".join(equipped_names)
	if wave_director != null and wave_director.state == WAVE_DIRECTOR_SCRIPT.State.VICTORY:
		_run_state.text = "VICTORY"
	elif run_over:
		_run_state.text = "RUN OVER"
	elif state["paused"]:
		_run_state.text = "PAUSED"
	else:
		_run_state.text = "IN RUN"

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
		_boss_value.text = "%s  %.0f / %.0f" % ["MID-BOSS" if enemy_type == "mid_boss" else "BOSS", current_hp, maximum_hp]
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
		var pickup_radius_bonus_pct := _equipment_bonus("pickup_radius_pct") + \
				float(loadout.relic_level("magnet_heart")) * magnet_heart_pickup_radius_per_level * 100.0
		var pickup_radius := xp_collection_radius * (1.0 + pickup_radius_bonus_pct / 100.0)
		if player.global_position.distance_squared_to(orb_position) > pickup_radius * pickup_radius:
			continue
		var sequence: int = simulation.collect_xp_orb(int(id["index"]), int(id["generation"]))
		if sequence > 0:
			_pending_xp_orbs[key] = sequence

func _add_xp(amount: float) -> void:
	player_xp += amount
	while player_xp >= player_xp_to_next:
		player_xp -= player_xp_to_next
		player_level += 1
		player_xp_to_next = xp_base_to_next_level + xp_growth_per_level * float(player_level - 1)

func open_chest(options: Array) -> bool:
	if simulation == null or run_over or _chest_open or not _chest_choice.present(options):
		return false
	_chest_open = true
	simulation.pause()
	return true

func open_chest_family(family: String) -> bool:
	return open_chest(loadout.offers(family))

func _on_chest_option_selected(option_id: String) -> void:
	if _starting_weapon_choice_open:
		_starting_weapon_choice_open = false
		if loadout.choose_starting_weapon(option_id.trim_prefix("start:")):
			simulation.resume()
		return
	_chest_open = false
	loadout.apply_offer(option_id)
	chest_option_chosen.emit(option_id)
	simulation.resume()
	_complete_pending_victory()

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
	if progression_service != null:
		reward = progression_service.award_survival_run(_run_id, wave_director.wave, victory, kill_count)
	_run_result.show_result(victory, wave_director.wave, player_active_time, kill_count, reward)

func _open_equipment_inventory() -> void:
	if progression_service == null or run_over or _chest_open or _starting_weapon_choice_open or _equipment_panel.visible:
		return
	_inventory_was_running = not bool(simulation.snapshot()["paused"])
	if _inventory_was_running:
		simulation.pause()
	var result: Dictionary = progression_service.load_profile()
	if result.get("ok", false):
		_equipment_panel.present(result["profile"])
	else:
		_equipment_panel.present_error()

func _open_skill_tree() -> void:
	if progression_service == null or run_over or _chest_open or _starting_weapon_choice_open or \
			_equipment_panel.visible or _skill_tree_panel.visible:
		return
	_inventory_was_running = not bool(simulation.snapshot()["paused"])
	if _inventory_was_running:
		simulation.pause()
	var result: Dictionary = progression_service.load_profile()
	if result.get("ok", false):
		_skill_tree_panel.present(result["profile"])
	else:
		_skill_tree_panel.present_error()

func _close_equipment_inventory() -> void:
	if _inventory_was_running and not run_over:
		simulation.resume()
	_inventory_was_running = false
	_equipment_button.grab_focus()

func _close_skill_tree() -> void:
	_skill_tree_panel.visible = false
	if _inventory_was_running and not run_over:
		simulation.resume()
	_inventory_was_running = false
	_skill_tree_button.grab_focus()

func _unlock_skill_node(node_id: String) -> void:
	var result: Dictionary = progression_service.unlock_skill_node(node_id)
	if result.get("ok", false):
		var health_ratio := player_hp / player_max_hp if player_max_hp > 0.0 else 1.0
		player_max_hp = simulation.initial_player_hp() * (1.0 + progression_service.skill_bonus("max_hp_pct")) + _equipment_bonus("max_hp")
		player_hp = player_max_hp * health_ratio
		_refresh_persistent_bonuses()
		_skill_tree_panel.present(result["profile"])
	else:
		_skill_tree_panel.present_error()

func _respec_skill_tree() -> void:
	var result: Dictionary = progression_service.respec_skill_tree()
	if result.get("ok", false):
		var health_ratio := player_hp / player_max_hp if player_max_hp > 0.0 else 1.0
		player_max_hp = simulation.initial_player_hp() * (1.0 + progression_service.skill_bonus("max_hp_pct")) + _equipment_bonus("max_hp")
		player_hp = player_max_hp * health_ratio
		_refresh_persistent_bonuses()
		_skill_tree_panel.present(result["profile"])
	else:
		_skill_tree_panel.present_error()

func _set_equipment_state(instance_id: String, equipped: bool) -> void:
	if progression_service == null or not _equipment_panel.visible:
		return
	var result: Dictionary = progression_service.set_equipped(instance_id, equipped)
	if result.get("ok", false):
		_refresh_persistent_bonuses()
		var health_ratio := player_hp / player_max_hp if player_max_hp > 0.0 else 1.0
		player_max_hp = simulation.initial_player_hp() * (1.0 + progression_service.skill_bonus("max_hp_pct")) + _equipment_bonus("max_hp")
		player_hp = minf(player_max_hp, player_max_hp * health_ratio)
		_equipment_panel.present(result["profile"])
	else:
		_equipment_panel.present_error()

func _enhance_equipment(instance_id: String, stat_id: String, powder_tier: String) -> void:
	if progression_service == null or not _equipment_panel.visible:
		return
	var result: Dictionary = progression_service.enhance_equipment(instance_id, stat_id, powder_tier)
	if result.get("ok", false):
		_refresh_persistent_bonuses()
		var health_ratio := player_hp / player_max_hp if player_max_hp > 0.0 else 1.0
		player_max_hp = simulation.initial_player_hp() * (1.0 + progression_service.skill_bonus("max_hp_pct")) + _equipment_bonus("max_hp")
		player_hp = minf(player_max_hp, player_max_hp * health_ratio)
		_equipment_panel.present(result["profile"])
		_equipment_panel.show_feedback(
			"ENHANCEMENT SUCCESS" if result["success"] else \
				"CRITICAL FAILURE — LEVEL LOST" if result["critical_failure"] else "ENHANCEMENT FAILED"
		)
	else:
		_equipment_panel.show_feedback("ENHANCEMENT FAILED: %s" % str(result.get("error", "unknown")))

func _choose_unique_effect(instance_id: String, effect_id: String) -> void:
	if progression_service == null or not _equipment_panel.visible:
		return
	var result: Dictionary = progression_service.choose_unique_effect(instance_id, effect_id)
	if result.get("ok", false):
		_refresh_persistent_bonuses()
		_equipment_panel.present(result["profile"])
		_equipment_panel.show_feedback("EFFECT SAVED — PROPOSED BEHAVIOR ACTIVE WHEN EQUIPPED" if effect_id in ["lightning_burst", "overflow_shield", "evolution_shockwave", "elite_haste"] else "EFFECT SAVED — PROTOTYPE ONLY; NO GAMEPLAY EFFECT")
	else:
		_equipment_panel.show_feedback("EFFECT CHOICE FAILED: %s" % str(result.get("error", "unknown")))

func _dismantle_equipment(instance_id: String) -> void:
	if progression_service == null or not _equipment_panel.visible:
		return
	var result: Dictionary = progression_service.dismantle_equipment(instance_id)
	if result.get("ok", false):
		_refresh_persistent_bonuses()
		var health_ratio := player_hp / player_max_hp if player_max_hp > 0.0 else 1.0
		player_max_hp = simulation.initial_player_hp() * (1.0 + progression_service.skill_bonus("max_hp_pct")) + _equipment_bonus("max_hp")
		player_hp = minf(player_max_hp, player_max_hp * health_ratio)
		_equipment_panel.present(result["profile"])
		var reward_parts: PackedStringArray = []
		for resource in result["powder_rewards"]:
			reward_parts.append("+%d %s" % [
				int(result["powder_rewards"][resource]), resource.trim_prefix("powder_").to_upper(),
			])
		var reward_text := ", ".join(reward_parts)
		_equipment_panel.show_feedback("ITEM DISMANTLED — %s" % reward_text)
	else:
		_equipment_panel.show_feedback("DISMANTLE FAILED: %s" % str(result.get("error", "unknown")))

func _restart_run() -> void:
	get_tree().reload_current_scene()

func _roll_enemy_chests(enemy_type: String, position: Vector2) -> void:
	var eligible_families: Array[String] = []
	if loadout.offers("weapon").size() == 3:
		eligible_families.append("weapon")
	if loadout.offers("relic").size() == 3:
		eligible_families.append("relic")
	var is_boss := enemy_type == "mid_boss" or enemy_type == "final_boss"
	var is_elite := enemy_type == "elite"
	for family in _chest_director.roll_drops(player_active_time, eligible_families, is_elite, is_boss):
		_world_chests.append({"family": family, "position": position})

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
		wave_director.advance(delta_seconds)
		if spawn_initial_enemy and player_active_time >= _next_enemy_spawn_time:
			_spawn_wave_enemy()
			_next_enemy_spawn_time = player_active_time + maxf(0.05, enemy_spawn_interval)
	elif wave_director.state == WAVE_DIRECTOR_SCRIPT.State.MID_BOSS:
		_spawn_boss_placeholder("mid_boss")
	elif wave_director.state == WAVE_DIRECTOR_SCRIPT.State.FINAL_BOSS:
		_spawn_boss_placeholder("final_boss")

func _spawn_wave_enemy() -> void:
	var target_population := _wave_population(wave_director.wave)
	var active_enemies := 0
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if not components.get("IsProjectile", false) and not components.get("IsXpOrb", false):
			active_enemies += 1
	if active_enemies >= target_population:
		return
	var angle := randf() * TAU
	var spawn_position := player.global_position + Vector2.from_angle(angle) * enemy_spawn_radius
	var enemy_type := "chaser"
	if wave_director.wave >= 4 and randf() < 0.25:
		enemy_type = "sprinter"
	if wave_director.wave >= 8 and randf() < 0.12:
		enemy_type = "tank"
	if wave_director.wave >= 10 and randf() < 0.15:
		enemy_type = "shooter"
	var hp_multiplier := minf(pow(WAVE_HP_GROWTH, float(wave_director.wave - 1)), WAVE_HP_CAP)
	simulation.spawn_enemy(enemy_type, 1, spawn_position, Vector2.ZERO, hp_multiplier)

func _spawn_boss_placeholder(boss_type: String) -> void:
	if not spawn_initial_enemy or _boss_spawn_pending:
		return
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("EnemyType", "") == boss_type:
			return
	var spawn_position := player.global_position + Vector2.RIGHT.rotated(randf() * TAU) * enemy_spawn_radius
	simulation.spawn(boss_type, 1, spawn_position, boss_placeholder_hp, Vector2.ZERO, 25.0)
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
	return clampi(roundi(float(proposed_population) * wave_population_scale), 1, wave_population_cap)

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
	var chain_count := lightning_chain_count
	if level >= 2:
		chain_count = 3
	if level >= 4:
		chain_count = 5
	var damage_multiplier := (1.25 if level >= 3 else 1.0) * \
			(1.0 + float(loadout.relic_level("storm_core")) * storm_core_damage_per_level) * _persistent_damage_multiplier()
	damage_multiplier *= _roll_equipment_critical_multiplier()
	if level >= 5 and loadout.relic_level("storm_core") > 0:
		_fire_infinite_circuit(active_time, chain_count, damage_multiplier)
		_try_evolution_shockwave(lightning_damage * damage_multiplier)
		return
	var selected_ids: Array[Vector2i] = []
	var max_distance_squared := lightning_range * lightning_range
	for _chain in range(chain_count):
		var best: Dictionary = {}
		var best_distance_squared := max_distance_squared
		for entity in _entities:
			var components: Dictionary = entity["components"]
			if components.get("IsProjectile", false) or components.get("IsXpOrb", false):
				continue
			var id: Dictionary = entity["id"]
			var entity_id := Vector2i(int(id["index"]), int(id["generation"]))
			if selected_ids.has(entity_id):
				continue
			var transform: Dictionary = components["Transform2D"]
			var target := Vector2(float(transform["x"]), float(transform["y"]))
			var distance_squared := player.global_position.distance_squared_to(target)
			if distance_squared < best_distance_squared:
				best_distance_squared = distance_squared
				best = entity
		if best.is_empty():
			break
		var target_transform: Dictionary = best["components"]["Transform2D"]
		var target_position := Vector2(float(target_transform["x"]), float(target_transform["y"]))
		var direction := (target_position - player.global_position).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT
		var sequence: int = simulation.spawn_projectile(
			"lightning_conductor", player.global_position + direction * 14.0,
			direction * _equipment_projectile_speed(lightning_projectile_speed), lightning_damage * damage_multiplier,
			_equipment_area(lightning_projectile_radius), lightning_projectile_lifetime
		)
		if sequence > 0:
			var id: Dictionary = best["id"]
			selected_ids.append(Vector2i(int(id["index"]), int(id["generation"])))
	if not selected_ids.is_empty():
		_try_unique_lightning_burst(lightning_damage * damage_multiplier)
		_try_evolution_shockwave(lightning_damage * damage_multiplier)
		_next_weapon_time = active_time + _effective_weapon_cooldown(lightning_cooldown)

func _fire_infinite_circuit(active_time: float, target_budget: int, damage_multiplier: float) -> void:
	var roots := _nearest_lightning_targets(player.global_position, [], 2)
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
				_equipment_area(lightning_projectile_radius), lightning_projectile_lifetime) <= 0:
			continue
		fired = true
		target_count += 1
		var frontier: Array[Dictionary] = [root_target]
		while not frontier.is_empty() and target_count < target_budget:
			var next_frontier: Array[Dictionary] = []
			var needed_targets := target_budget - target_count
			for parent in frontier:
				var children := _nearest_lightning_targets(parent["position"], used_ids, mini(branch_factor, needed_targets))
				for child in children:
					var target_id: Vector2i = child["id"]
					var direction: Vector2 = (child["position"] - parent["position"]).normalized()
					if direction == Vector2.ZERO:
						direction = Vector2.RIGHT
					if simulation.spawn_projectile("infinite_circuit_branch", child["position"] + direction * 14.0,
							direction * _equipment_projectile_speed(lightning_projectile_speed), lightning_damage * damage_multiplier,
							_equipment_area(lightning_projectile_radius), lightning_projectile_lifetime) <= 0:
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
		_next_weapon_time = active_time + _effective_weapon_cooldown(lightning_cooldown)

func _nearest_lightning_targets(origin: Vector2, excluded_ids: Array[Vector2i], limit: int) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var max_distance_squared := lightning_range * lightning_range
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("IsXpOrb", false):
			continue
		var id: Dictionary = entity["id"]
		var entity_id := Vector2i(int(id["index"]), int(id["generation"]))
		if excluded_ids.has(entity_id):
			continue
		var transform: Dictionary = components["Transform2D"]
		var position := Vector2(float(transform["x"]), float(transform["y"]))
		var distance_squared := origin.distance_squared_to(position)
		if distance_squared < max_distance_squared:
			candidates.append({"id": entity_id, "position": position, "distance_squared": distance_squared})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["distance_squared"] < b["distance_squared"])
	if candidates.size() > limit:
		candidates.resize(limit)
	return candidates

func _fire_inferno_sprayer(active_time: float, paused: bool) -> void:
	if not weapon_enabled or loadout.weapon_level("inferno_sprayer") == 0 or paused or _chest_open or run_over or inferno_cooldown <= 0.0 or active_time < _next_inferno_time:
		return
	var target := _nearest_enemy(inferno_range)
	if target.is_empty():
		return
	var direction: Vector2 = (target["position"] - player.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var level: int = loadout.weapon_level("inferno_sprayer")
	var damage := inferno_damage * (1.0 + 0.15 * float(level - 1))
	damage *= 1.0 + float(loadout.relic_level("infernal_heart")) * infernal_heart_damage_per_level
	damage *= _persistent_damage_multiplier()
	damage *= _roll_equipment_critical_multiplier()
	var projectile_type := "inferno_sprayer"
	var explosion_radius := 0.0
	var explosion_multiplier := 0.0
	if level >= 5 and loadout.relic_level("infernal_heart") > 0:
		projectile_type = "wildfire_sprayer"
		explosion_radius = _equipment_area(wildfire_explosion_radius)
		explosion_multiplier = wildfire_explosion_damage_multiplier
	var projectile_sequence: int = simulation.spawn_status_projectile(projectile_type, player.global_position + direction * 14.0,
			direction * _equipment_projectile_speed(inferno_projectile_speed), damage, _equipment_area(inferno_projectile_radius),
			inferno_projectile_lifetime, inferno_burn_damage_per_tick,
			inferno_burn_interval_seconds, inferno_burn_duration_seconds,
			explosion_radius, explosion_multiplier)
	if projectile_sequence > 0:
		_try_unique_lightning_burst(damage)
		_try_evolution_shockwave(damage)
		_next_inferno_time = active_time + _effective_weapon_cooldown(inferno_cooldown)

func _fire_crimson_daggers(active_time: float, paused: bool) -> void:
	if not weapon_enabled or loadout.weapon_level("crimson_daggers") == 0 or paused or _chest_open or run_over or daggers_cooldown <= 0.0 or active_time < _next_daggers_time:
		return
	var target := _nearest_enemy(daggers_range)
	if target.is_empty():
		return
	var direction: Vector2 = (target["position"] - player.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var level: int = loadout.weapon_level("crimson_daggers")
	var damage := daggers_damage * (1.0 + 0.15 * float(level - 1))
	damage *= _persistent_damage_multiplier()
	damage *= _roll_equipment_critical_multiplier()
	var projectile_type := "crimson_dagger"
	var status_damage := 2.0
	var status_interval := 0.5
	var status_duration := 2.0
	if level >= 5 and loadout.relic_level("blood_chalice") > 0:
		projectile_type = "bloodstorm_dagger"
		status_damage = bloodstorm_bleed_damage_per_tick
		status_interval = bloodstorm_bleed_interval_seconds
		status_duration = bloodstorm_bleed_duration_seconds
	var fired := 0
	for spread in [-0.06, 0.06]:
		var shot_direction: Vector2 = direction.rotated(spread)
		if simulation.spawn_status_projectile(projectile_type, player.global_position + shot_direction * 14.0,
				shot_direction * _equipment_projectile_speed(daggers_projectile_speed), damage, _equipment_area(daggers_projectile_radius),
				daggers_projectile_lifetime, status_damage, status_interval, status_duration) > 0:
			fired += 1
	if fired > 0:
		_try_unique_lightning_burst(damage)
		_try_evolution_shockwave(damage)
		_next_daggers_time = active_time + _effective_weapon_cooldown(daggers_cooldown)

func _fire_minigun(active_time: float, paused: bool) -> void:
	if not weapon_enabled or loadout.weapon_level("minigun") == 0 or paused or _chest_open or run_over or minigun_cooldown <= 0.0:
		return
	var target := _nearest_enemy(minigun_range)
	if target.is_empty():
		_redline_target_id = Vector2i(-1, -1)
		_redline_fire_time = 0.0
		return
	var target_id: Vector2i = target["id"]
	if target_id != _redline_target_id:
		_redline_target_id = target_id
		_redline_fire_time = active_time
	if active_time < _next_minigun_time:
		return
	var level: int = loadout.weapon_level("minigun")
	var damage_multiplier := 1.0 + (0.2 if level >= 2 else 0.0)
	var cadence_multiplier := 1.0 + (0.25 if level >= 3 else 0.0) + (0.25 if level >= 5 else 0.0)
	var damage := minigun_damage * damage_multiplier * _persistent_damage_multiplier() * _roll_equipment_critical_multiplier()
	var direction: Vector2 = (target["position"] - player.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var spread := minigun_spread_radians * (0.85 if level >= 4 else 1.0)
	direction = direction.rotated(randf_range(-spread, spread))
	if simulation.spawn_projectile("minigun", player.global_position + direction * 14.0,
			direction * _equipment_projectile_speed(minigun_projectile_speed), damage,
			_equipment_area(minigun_projectile_radius), minigun_projectile_lifetime) <= 0:
		return
	var overdrive_level: int = loadout.relic_level("overdrive_engine")
	var overdrive_multiplier := 1.0 + float(overdrive_level) * overdrive_cadence_per_level
	if level >= 5 and overdrive_level > 0:
		var ramp := clampf((active_time - _redline_fire_time) / maxf(redline_ramp_seconds, 0.01), 0.0, 1.0)
		cadence_multiplier *= 1.0 + redline_max_cadence_bonus * ramp
	_next_minigun_time = active_time + minigun_cooldown / cadence_multiplier / overdrive_multiplier

func _fire_toxic_cloud(active_time: float, paused: bool) -> void:
	if not weapon_enabled or loadout.weapon_level("toxic_cloud") == 0 or paused or _chest_open or run_over or toxic_cooldown <= 0.0 or active_time < _next_toxic_time:
		return
	var target := _nearest_enemy(toxic_range)
	if target.is_empty():
		return
	var level: int = loadout.weapon_level("toxic_cloud")
	var relic_level: int = loadout.relic_level("plague_mask")
	var dot_multiplier := (1.0 + (0.2 if level >= 2 else 0.0) + (0.25 if level >= 5 else 0.0))
	dot_multiplier *= 1.0 + float(relic_level) * plague_mask_dot_per_level
	var duration := toxic_status_duration_seconds * (1.2 if level >= 4 else 1.0)
	var cloud_radius := _equipment_area(toxic_cloud_radius * (1.2 if level >= 3 else 1.0))
	var direction: Vector2 = (target["position"] - player.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var projectile_type := "toxic_cloud"
	if level >= 5 and relic_level > 0:
		projectile_type = "pandemic_cloud"
	var sequence: int = simulation.spawn_status_projectile(projectile_type,
			player.global_position + direction * 14.0,
		direction * _equipment_projectile_speed(toxic_projectile_speed),
		toxic_impact_damage * _persistent_damage_multiplier() * _roll_equipment_critical_multiplier(),
		_equipment_area(toxic_projectile_radius), toxic_projectile_lifetime,
		toxic_damage_per_tick * dot_multiplier, toxic_tick_interval_seconds, duration,
		cloud_radius, toxic_splash_damage_multiplier)
	if sequence > 0:
		_next_toxic_time = active_time + _effective_weapon_cooldown(toxic_cooldown)

func _fire_sawblades(active_time: float, paused: bool) -> void:
	if not weapon_enabled or loadout.weapon_level("sawblades") == 0 or paused or _chest_open or run_over or sawblades_cooldown <= 0.0 or active_time < _next_sawblades_time:
		return
	var target := _nearest_enemy(sawblades_range)
	if target.is_empty():
		return
	var direction: Vector2 = (target["position"] - player.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var level: int = loadout.weapon_level("sawblades")
	var evolved: bool = level >= 5 and loadout.relic_level("magnetic_coil") > 0
	var damage_multiplier := (1.2 if level >= 2 else 1.0) * (1.25 if level >= 5 else 1.0)
	var ricochets := 1 + (1 if level >= 3 else 0) + (1 if evolved else 0)
	var projectile_speed := sawblades_projectile_speed * (1.2 if level >= 4 else 1.0)
	var sequence: int = simulation.spawn_projectile("razorstorm" if evolved else "sawblades",
			player.global_position + direction * 14.0,
		direction * _equipment_projectile_speed(projectile_speed),
		sawblades_damage * damage_multiplier * _persistent_damage_multiplier() * _roll_equipment_critical_multiplier(),
		_equipment_area(sawblades_projectile_radius), sawblades_projectile_lifetime,
		2.0, 0.5, 2.0, 0.0, 0.0, ricochets)
	if sequence > 0:
		_next_sawblades_time = active_time + _effective_weapon_cooldown(sawblades_cooldown)

func _fire_meteor_staff(active_time: float, paused: bool) -> void:
	if not weapon_enabled or loadout.weapon_level("meteor_staff") == 0 or paused or _chest_open or run_over or meteor_staff_cooldown <= 0.0 or active_time < _next_meteor_time:
		return
	var target := _meteor_cluster_target()
	if target.is_empty():
		return
	var level: int = loadout.weapon_level("meteor_staff")
	var evolved: bool = level >= 5 and loadout.relic_level("celestial_eye") > 0
	var projectile_type := "starfall" if evolved else "meteor_staff"
	var damage_multiplier := (1.2 if level >= 2 else 1.0) * (1.3 if level >= 5 else 1.0)
	var blast_radius := meteor_staff_blast_radius * (1.2 if level >= 3 else 1.0)
	var direction: Vector2 = (target["position"] - player.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var shot_count := 2 if loadout.relic_level("celestial_eye") >= 5 and randf() < celestial_eye_double_impact_chance else 1
	var fired := false
	for _shot in range(shot_count):
		if simulation.spawn_projectile(projectile_type, player.global_position + direction * 14.0,
				direction * _equipment_projectile_speed(meteor_staff_projectile_speed),
				meteor_staff_damage * damage_multiplier * _persistent_damage_multiplier() * _roll_equipment_critical_multiplier(),
				_equipment_area(meteor_staff_projectile_radius), meteor_staff_projectile_lifetime,
				2.0, 0.5, 2.0, _equipment_area(blast_radius), meteor_staff_splash_damage_multiplier) > 0:
			fired = true
	if fired:
		var cooldown_multiplier := 0.85 if level >= 4 else 1.0
		_next_meteor_time = active_time + _effective_weapon_cooldown(meteor_staff_cooldown * cooldown_multiplier)

func _fire_prism_laser(active_time: float, paused: bool) -> void:
	_prism_beams.clear()
	if not weapon_enabled or loadout.weapon_level("prism_laser") == 0 or paused or _chest_open or run_over or prism_laser_cooldown <= 0.0:
		return
	var level: int = loadout.weapon_level("prism_laser")
	var range_multiplier := (1.2 if level >= 3 else 1.0) * (1.15 if level >= 4 else 1.0)
	var laser_range := _equipment_area(prism_laser_range * range_multiplier)
	var target := _nearest_enemy(laser_range)
	if target.is_empty():
		return
	var evolved: bool = level >= 5 and loadout.relic_level("prism_crystal") > 0
	var damage_multiplier := (1.2 if level >= 2 else 1.0) * (1.25 if level >= 5 else 1.0)
	var prism_level: int = loadout.relic_level("prism_crystal")
	var targets: Array[Dictionary] = [target]
	if evolved:
		var excluded: Array[Vector2i] = [target["id"]]
		for _beam in range(spectrum_collapse_secondary_beams):
			var secondary := _nearest_enemy_excluding(laser_range, excluded)
			if secondary.is_empty():
				break
			targets.append(secondary)
			excluded.append(secondary["id"])
	for index in range(targets.size()):
		_prism_beams.append({"from": player.global_position, "to": targets[index]["position"], "secondary": index > 0})
	if active_time < _next_prism_time:
		return
	var critical: float = _roll_equipment_critical_multiplier()
	var fired := false
	for index in range(targets.size()):
		var beam_target: Dictionary = targets[index]
		var direction: Vector2 = (beam_target["position"] - player.global_position).normalized()
		var secondary_beam: bool = index > 0
		var projectile_type := "spectrum_collapse" if evolved and secondary_beam else "prism_laser"
		if simulation.spawn_projectile(projectile_type, player.global_position + direction * 14.0,
				direction * prism_laser_projectile_speed,
				prism_laser_damage * damage_multiplier * _persistent_damage_multiplier() * critical * (0.65 if secondary_beam else 1.0),
				prism_laser_projectile_radius, laser_range / prism_laser_projectile_speed) > 0:
			fired = true
	if critical > 1.0 and prism_level >= 5 and not evolved:
		var secondary := _nearest_enemy_excluding(laser_range, [target["id"]])
		if not secondary.is_empty():
			var direction: Vector2 = (secondary["position"] - player.global_position).normalized()
			if simulation.spawn_projectile("prism_secondary", player.global_position + direction * 14.0,
					direction * prism_laser_projectile_speed, prism_laser_damage * damage_multiplier * critical * 0.5,
					prism_laser_projectile_radius, laser_range / prism_laser_projectile_speed) > 0:
				fired = true
	if fired:
		_next_prism_time = active_time + _effective_weapon_cooldown(prism_laser_cooldown)

func _fire_void_orb(active_time: float, paused: bool) -> void:
	if not weapon_enabled or loadout.weapon_level("void_orb") == 0 or paused or _chest_open or run_over or void_orb_cooldown <= 0.0 or active_time < _next_void_orb_time:
		return
	var target := _nearest_enemy(void_orb_range)
	if target.is_empty():
		return
	var level: int = loadout.weapon_level("void_orb")
	var singularity_level: int = loadout.relic_level("singularity")
	var evolved: bool = level >= 5 and singularity_level > 0
	var direction: Vector2 = (target["position"] - player.global_position).normalized()
	var damage_multiplier := (1.2 if level >= 2 else 1.0) * (1.25 if level >= 5 else 1.0)
	var attraction_radius := void_orb_attraction_radius * (1.2 if level >= 3 else 1.0)
	var lifetime := void_orb_lifetime * (1.15 if level >= 4 else 1.0)
	var attraction_speed := void_orb_attraction_speed * (1.0 + float(level) * singularity_control_per_level)
	if evolved:
		attraction_radius *= 1.5
		attraction_speed *= 1.25
	var projectile_type := "event_horizon" if evolved else "void_orb"
	var sequence: int = simulation.spawn_projectile(projectile_type, player.global_position + direction * 14.0,
			direction * _equipment_projectile_speed(void_orb_speed),
			void_orb_damage * damage_multiplier * _persistent_damage_multiplier() * _roll_equipment_critical_multiplier(),
			_equipment_area(void_orb_radius), lifetime, 2.0, 0.5, 2.0, 0.0, 0.0, 0,
			_equipment_area(attraction_radius), attraction_speed, true)
	if sequence > 0:
		_next_void_orb_time = active_time + _effective_weapon_cooldown(void_orb_cooldown)

func _fire_frost_nova(active_time: float, paused: bool) -> void:
	var level: int = loadout.weapon_level("frost_nova")
	if not weapon_enabled or level == 0 or paused or _chest_open or run_over or frost_nova_cooldown <= 0.0 or active_time < _next_frost_nova_time:
		return
	var evolved: bool = level >= 5 and loadout.relic_level("frozen_crown") > 0
	var radius := _equipment_area(frost_nova_radius * (1.2 if level >= 3 else 1.0))
	var duration := frost_chill_duration_seconds * (1.2 if level >= 4 else 1.0)
	duration *= 1.0 + float(loadout.relic_level("frozen_crown")) * frozen_crown_chill_duration_per_level
	var target_count := 0
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("IsXpOrb", false):
			continue
		var transform: Dictionary = components["Transform2D"]
		var position := Vector2(float(transform["x"]), float(transform["y"]))
		if player.global_position.distance_squared_to(position) <= radius * radius:
			target_count += 1
	if target_count == 0:
		return
	var projectile_type := "absolute_zero" if evolved else "frost_nova"
	var damage := frost_nova_damage * (1.2 if level >= 2 else 1.0) * _persistent_damage_multiplier()
	var vulnerability := 1.0 + frozen_crown_vulnerability_at_level_five if evolved else 1.0
	if simulation.spawn_projectile(projectile_type, player.global_position, Vector2.ZERO, damage,
			radius, frost_nova_duration_seconds, 2.0, 0.5, 2.0, 0.0, 0.0, 0, 0.0, 0.0,
			true, duration, frost_chill_speed_multiplier, vulnerability) > 0:
		_next_frost_nova_time = active_time + _effective_weapon_cooldown(frost_nova_cooldown * (0.8 if level >= 5 else 1.0))

func _nearest_enemy_excluding(max_range: float, excluded: Array[Vector2i]) -> Dictionary:
	var nearest: Dictionary = {}
	var best_distance_squared := max_range * max_range
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("IsXpOrb", false) or float(components.get("Health", {}).get("current", 0.0)) <= 0.0:
			continue
		var id: Dictionary = entity["id"]
		var key := Vector2i(int(id["index"]), int(id["generation"]))
		if excluded.has(key):
			continue
		var transform: Dictionary = components["Transform2D"]
		var point := Vector2(float(transform["x"]), float(transform["y"]))
		var distance_squared := player.global_position.distance_squared_to(point)
		if distance_squared < best_distance_squared:
			best_distance_squared = distance_squared
			nearest = {"position": point, "id": key}
	return nearest

func _meteor_cluster_target() -> Dictionary:
	var anchor := _nearest_enemy(meteor_staff_range)
	if anchor.is_empty():
		return {}
	var anchor_position: Vector2 = anchor["position"]
	var center := anchor_position
	var target_count := 1
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("IsXpOrb", false):
			continue
		if float(components["Health"]["current"]) <= 0.0:
			continue
		var id: Dictionary = entity["id"]
		if Vector2i(int(id["index"]), int(id["generation"])) == anchor["id"]:
			continue
		var transform: Dictionary = components["Transform2D"]
		var position := Vector2(float(transform["x"]), float(transform["y"]))
		if anchor_position.distance_squared_to(position) <= meteor_staff_cluster_radius * meteor_staff_cluster_radius:
			center += position
			target_count += 1
	return {"id": anchor["id"], "position": center / float(target_count)}

func _spawn_starfall_fragments(origin: Vector2, primary_target: Dictionary, entities: Array) -> void:
	var candidates: Array[Dictionary] = []
	var fragment_radius_squared := starfall_fragment_radius * starfall_fragment_radius
	for entity in entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("IsXpOrb", false) or float(components["Health"]["current"]) <= 0.0:
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
		simulation.spawn_projectile("starfall_fragment", origin + direction * 22.0,
				direction * _equipment_projectile_speed(meteor_staff_projectile_speed * 1.25),
				meteor_staff_damage * starfall_fragment_damage_multiplier * _persistent_damage_multiplier() *
						_roll_equipment_critical_multiplier(), _equipment_area(meteor_staff_projectile_radius * 0.65),
					meteor_staff_projectile_lifetime)

func _spread_pandemic(origin: Vector2, entities: Array) -> void:
	var status_damage := toxic_damage_per_tick * (1.0 + (0.2 if loadout.weapon_level("toxic_cloud") >= 2 else 0.0) +
			(0.25 if loadout.weapon_level("toxic_cloud") >= 5 else 0.0))
	status_damage *= 1.0 + float(loadout.relic_level("plague_mask")) * plague_mask_dot_per_level
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
	_pandemic_bursts.append({"position": origin, "remaining": pandemic_feedback_seconds})

func _persistent_damage_multiplier() -> float:
	return _cached_persistent_damage_multiplier

func _refresh_persistent_bonuses() -> void:
	_cached_persistent_damage_multiplier = 1.0
	_cached_equipment_bonuses = {}
	_cached_unique_effects = []
	if progression_service != null:
		_cached_equipment_bonuses = progression_service.equipment_bonuses()
		_cached_unique_effects = progression_service.equipped_unique_effects()
		_cached_persistent_damage_multiplier += progression_service.skill_bonus("damage_pct")
		_cached_persistent_damage_multiplier += progression_service.achievement_bonus("damage_pct")
		_cached_persistent_damage_multiplier += _equipment_bonus("damage_pct") / 100.0
		_refresh_player_move_speed()

func _equipment_bonus(stat_id: String) -> float:
	return float(_cached_equipment_bonuses.get(stat_id, 0.0))

func _refresh_player_move_speed() -> void:
	var haste_multiplier := 1.15 if _has_unique_effect("elite_haste") and player_active_time < _elite_haste_expires_at else 1.0
	player.move_speed = _base_player_move_speed * (1.0 + _equipment_bonus("move_speed_pct") / 100.0) * haste_multiplier

func _effective_weapon_cooldown(base_cooldown: float) -> float:
	var speed_multiplier := 1.0 + _equipment_bonus("attack_speed_pct") / 100.0
	var cooldown_multiplier := maxf(0.1, 1.0 - _equipment_bonus("cooldown_reduction_pct") / 100.0)
	return base_cooldown * cooldown_multiplier / speed_multiplier

func _roll_equipment_critical_multiplier() -> float:
	var chance := clampf(_equipment_bonus("critical_chance_pct"), 0.0, 100.0)
	if randf() * 100.0 < chance:
		return 1.5 + _equipment_bonus("critical_damage_pct") / 100.0 + float(loadout.relic_level("prism_crystal")) * prism_crystal_critical_damage_per_level
	return 1.0

func _equipment_projectile_speed(base_speed: float) -> float:
	var magnetic_coil_bonus := float(loadout.relic_level("magnetic_coil")) * magnetic_coil_projectile_speed_per_level
	return base_speed * (1.0 + _equipment_bonus("projectile_speed_pct") / 100.0 + magnetic_coil_bonus)

func _equipment_area(base_area: float) -> float:
	var celestial_eye_bonus := float(loadout.relic_level("celestial_eye")) * celestial_eye_area_per_level
	return base_area * (1.0 + _equipment_bonus("area_pct") / 100.0 + celestial_eye_bonus)

func _has_unique_effect(effect_id: String) -> bool:
	return _cached_unique_effects.has(effect_id)

func _try_unique_lightning_burst(base_damage: float) -> void:
	if not _has_unique_effect("lightning_burst") or player_active_time < _next_unique_lightning_time or randf() >= 0.1:
		return
	var target := _nearest_enemy(lightning_range)
	if target.is_empty():
		return
	var direction: Vector2 = (target["position"] - player.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	if simulation.spawn_projectile("unique_lightning_burst", player.global_position + direction * 14.0,
			direction * _equipment_projectile_speed(lightning_projectile_speed), base_damage * 0.5,
			_equipment_area(lightning_projectile_radius), lightning_projectile_lifetime) > 0:
		_next_unique_lightning_time = player_active_time + 2.0

func _try_evolution_shockwave(base_damage: float) -> void:
	if _evolution_shockwave_triggered or not _has_unique_effect("evolution_shockwave"):
		return
	var evolved: bool = (loadout.weapon_level("lightning_conductor") >= 5 and loadout.relic_level("storm_core") > 0) or \
			(loadout.weapon_level("inferno_sprayer") >= 5 and loadout.relic_level("infernal_heart") > 0) or \
			(loadout.weapon_level("crimson_daggers") >= 5 and loadout.relic_level("blood_chalice") > 0)
	if not evolved:
		return
	_evolution_shockwave_triggered = true
	var count := 8
	for index in range(count):
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / float(count))
		simulation.spawn_projectile("evolution_shockwave", player.global_position + direction * 14.0,
			direction * 400.0, base_damage, 6.0, 0.3)

func _nearest_enemy(max_range: float) -> Dictionary:
	var nearest: Dictionary = {}
	var best_distance_squared := max_range * max_range
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("IsXpOrb", false):
			continue
		var transform: Dictionary = components["Transform2D"]
		var position := Vector2(float(transform["x"]), float(transform["y"]))
		var distance_squared := player.global_position.distance_squared_to(position)
		if distance_squared < best_distance_squared:
			best_distance_squared = distance_squared
			nearest = {"position": position, "id": Vector2i(int(entity["id"]["index"]), int(entity["id"]["generation"]))}
	return nearest

func _publish_player_target() -> void:
	var target := player.global_position
	if target.distance_squared_to(_last_target) < 0.01:
		return
	_last_target = target
	last_target_sequence = simulation.set_steering_target(
		target, 75.0, enemy_separation_radius, enemy_separation_weight
	)

func _draw() -> void:
	draw_texture_rect(GROUND_TEXTURE, Rect2(-8192.0, -8192.0, 16384.0, 16384.0), true)
	draw_texture_rect(RUINS_TEXTURE, Rect2(-768.0, -768.0, 1536.0, 1536.0), false, Color(1.0, 1.0, 1.0, 0.88))
	_sprite_renderer.draw_batches(self)
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
	for beam in _prism_beams:
		var beam_color := Color(0.55, 0.95, 1.0, 0.78) if bool(beam["secondary"]) else Color(1.0, 0.92, 0.55, 0.9)
		draw_line(beam["from"], beam["to"], beam_color, 5.0 if not beam["secondary"] else 3.0, true)
		draw_line(beam["from"], beam["to"], Color(1.0, 1.0, 1.0, 0.9), 1.5, true)
	for burst in _pandemic_bursts:
		var fade := clampf(float(burst["remaining"]) / maxf(pandemic_feedback_seconds, 0.01), 0.0, 1.0)
		draw_circle(burst["position"], pandemic_spread_radius * (1.0 - fade * 0.35), Color(0.35, 1.0, 0.4, 0.18 * fade))
	for chest in _world_chests:
		draw_texture_rect(CHEST_TEXTURE, Rect2(chest["position"] - Vector2(16.0, 16.0), Vector2(32.0, 32.0)), false)
	for impact in _weapon_impacts:
		var remaining: float = float(impact["remaining"])
		var fade := clampf(remaining / WEAPON_IMPACT_LIFETIME, 0.0, 1.0)
		var scale := 0.7 + 0.5 * (1.0 - fade)
		draw_set_transform(impact["position"], float(impact["rotation"]), Vector2.ONE * scale)
		draw_texture_rect_region(WEAPON_IMPACTS_TEXTURE, Rect2(-32.0, -32.0, 64.0, 64.0),
			Rect2(float(impact["type"]) * 64.0, 0.0, 64.0, 64.0), Color(1.0, 1.0, 1.0, fade))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _add_weapon_impact(source_type: String, position: Vector2, is_damage_over_time: bool) -> void:
	if is_damage_over_time or not WEAPON_IMPACT_TYPES.has(source_type):
		return
	if _weapon_impacts.size() >= MAX_VISIBLE_WEAPON_IMPACTS:
		_weapon_impacts.pop_front()
	_weapon_impacts.append({
		"type": int(WEAPON_IMPACT_TYPES[source_type]),
		"position": position,
		"rotation": randf_range(-0.25, 0.25),
		"remaining": WEAPON_IMPACT_LIFETIME,
	})
