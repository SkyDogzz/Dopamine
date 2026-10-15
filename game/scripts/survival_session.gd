extends Node2D

signal chest_option_chosen(option_id: String)

const PLAYER_SCENE := preload("res://scenes/player.tscn")
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
@export var enemy_spawn_interval: float = 1.0
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
@export var lightning_range: float = 600.0
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
@export_group("Prototype Crimson Daggers — proposed tuning")
@export var daggers_cooldown: float = 0.8
@export var daggers_damage: float = 7.0
@export var daggers_range: float = 480.0
@export var daggers_projectile_speed: float = 900.0
@export var daggers_projectile_radius: float = 2.5
@export var daggers_projectile_lifetime: float = 0.8
@export_group("Prototype relic bonuses — proposed tuning")
@export_range(0.0, 1.0) var storm_core_damage_per_level: float = 0.05
@export_range(0.0, 1.0) var infernal_heart_damage_per_level: float = 0.05
@export_range(0.0, 1.0) var blood_chalice_heal_per_level: float = 0.10
@export_range(0.0, 1.0) var blood_chalice_lifesteal_per_level: float = 0.05
@export_group("Prototype XP — proposed tuning")
@export var xp_per_enemy: float = 5.0
@export var xp_collection_radius: float = 36.0
@export var xp_base_to_next_level: float = 10.0
@export var xp_growth_per_level: float = 5.0

var simulation: Object
var player: CharacterBody2D
var loadout: RefCounted
var last_target_sequence := 0
var player_hp := 0.0
var player_max_hp := 0.0
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
var _entities: Array = []
var _pending_xp_orbs: Dictionary = {}
var _chest_director: RefCounted
var _world_chests: Array[Dictionary] = []
var _chest_open := false
var _starting_weapon_choice_open := false
var _contact_invulnerable_until := 0.0
var _pending_lifesteal := 0.0

@onready var _hp_value: Label = $HUD/RunPanel/RunInfo/HPValue
@onready var _hp_bar: ProgressBar = $HUD/RunPanel/RunInfo/HPBar
@onready var _time_value: Label = $HUD/RunPanel/RunInfo/TimeValue
@onready var _weapon_value: Label = $HUD/RunPanel/RunInfo/WeaponValue
@onready var _xp_value: Label = $HUD/RunPanel/RunInfo/XPValue
@onready var _xp_bar: ProgressBar = $HUD/RunPanel/RunInfo/XPBar
@onready var _run_state: Label = $HUD/RunPanel/RunInfo/RunState
@onready var _wave_value: Label = $HUD/RunPanel/RunInfo/WaveValue
@onready var _boss_panel: PanelContainer = $HUD/BossPanel
@onready var _boss_value: Label = $HUD/BossPanel/BossInfo/BossValue
@onready var _boss_hp_bar: ProgressBar = $HUD/BossPanel/BossInfo/BossHPBar
@onready var _chest_choice: PanelContainer = $HUD/ChestOverlay/ChestChoice
@onready var _run_result_overlay: CenterContainer = $HUD/RunResultOverlay
@onready var _run_result: PanelContainer = $HUD/RunResultOverlay/RunResultPanel

func _ready() -> void:
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
	player_max_hp = simulation.initial_player_hp()
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
	if elapsed_active_time > 0.0 and not run_over:
		player_hp = maxf(0.0, player_hp - simulation.health_decay_amount(player_active_time, elapsed_active_time))
		player_active_time += elapsed_active_time
	_last_simulation_time = current_simulation_time
	var latest_event_sequence := _last_combat_event_sequence
	for event in state["events"]:
		var sequence: int = int(event["sequence"])
		if sequence <= _last_combat_event_sequence:
			continue
		latest_event_sequence = sequence
		match event["type"]:
			"damage":
				var damage_lifesteal := float(event["amount"]) * float(loadout.relic_level("blood_chalice")) * blood_chalice_lifesteal_per_level
				if bool(event.get("is_damage_over_time", false)):
					damage_lifesteal *= 0.25
				_pending_lifesteal += damage_lifesteal
			"death":
				kill_count += 1
				var dead_enemy_type: String = str(event.get("target_type", ""))
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
					player_hp = minf(player_max_hp, player_hp + healing)
					simulation.spawn_xp_orb(
						Vector2(float(event["position"]["x"]), float(event["position"]["y"])), xp_per_enemy
					)
			"xp_collected":
				var id: Dictionary = event["target"]
				_pending_xp_orbs.erase(_entity_key(int(id["index"]), int(id["generation"])))
				_add_xp(float(event["amount"]))
	_apply_pending_lifesteal(elapsed_active_time)
	if latest_event_sequence > _last_combat_event_sequence:
		_last_combat_event_sequence = latest_event_sequence
		simulation.acknowledge_events(latest_event_sequence)
	_entities = state["entities"]
	_advance_wave_director(elapsed_active_time, state["paused"])
	_apply_contact_damage(state, current_simulation_time)
	_collect_nearby_xp_orbs(state)
	_collect_nearby_chests(state)
	_complete_pending_victory()
	_fire_lightning_conductor(current_simulation_time, state["paused"])
	_fire_inferno_sprayer(current_simulation_time, state["paused"])
	_fire_crimson_daggers(current_simulation_time, state["paused"])
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
		player_hp = maxf(0.0, player_hp - contact_damage_per_hit)
		_contact_invulnerable_until = current_simulation_time + contact_invulnerability_seconds
		return

func _apply_pending_lifesteal(elapsed_active_time: float) -> void:
	if elapsed_active_time <= 0.0 or _pending_lifesteal <= 0.0 or run_over:
		return
	var normal_healing_limit := 10.0 * elapsed_active_time
	var healing := minf(_pending_lifesteal, normal_healing_limit)
	healing += maxf(0.0, _pending_lifesteal - normal_healing_limit) * 0.25
	_pending_lifesteal = 0.0
	player_hp = minf(player_max_hp, player_hp + healing)

func _refresh_hud(state: Dictionary) -> void:
	_hp_value.text = "HP  %.1f / %.0f" % [player_hp, player_max_hp]
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
	var short_names := {"lightning_conductor": "LC", "inferno_sprayer": "IS", "crimson_daggers": "CD"}
	for weapon_id in loadout.owned_weapons():
		equipped_names.append("%s Lv%d" % [short_names.get(weapon_id, weapon_id), loadout.weapon_level(weapon_id)])
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
		if player.global_position.distance_squared_to(orb_position) > xp_collection_radius * xp_collection_radius:
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
	_run_result.show_result(victory, wave_director.wave, player_active_time, kill_count)

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
	var profile_hp := {"chaser": 20.0, "sprinter": 12.0, "tank": 80.0, "shooter": 25.0}
	var hp: float = profile_hp[enemy_type] * hp_multiplier
	simulation.spawn(enemy_type, 1, spawn_position, hp, Vector2.ZERO, 1.0)

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
	var damage_multiplier := (1.25 if level >= 3 else 1.0) * (1.0 + float(loadout.relic_level("storm_core")) * storm_core_damage_per_level)
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
			direction * lightning_projectile_speed, lightning_damage * damage_multiplier,
			lightning_projectile_radius, lightning_projectile_lifetime
		)
		if sequence > 0:
			var id: Dictionary = best["id"]
			selected_ids.append(Vector2i(int(id["index"]), int(id["generation"])))
	if not selected_ids.is_empty():
		_next_weapon_time = active_time + lightning_cooldown

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
	var projectile_sequence: int = simulation.spawn_projectile("inferno_sprayer", player.global_position + direction * 14.0,
			direction * inferno_projectile_speed, damage, inferno_projectile_radius,
			inferno_projectile_lifetime, inferno_burn_damage_per_tick,
			inferno_burn_interval_seconds, inferno_burn_duration_seconds)
	if projectile_sequence > 0:
		_next_inferno_time = active_time + inferno_cooldown

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
	var fired := 0
	for spread in [-0.06, 0.06]:
		var shot_direction: Vector2 = direction.rotated(spread)
		if simulation.spawn_projectile("crimson_dagger", player.global_position + shot_direction * 14.0,
				shot_direction * daggers_projectile_speed, damage, daggers_projectile_radius,
				daggers_projectile_lifetime) > 0:
			fired += 1
	if fired > 0:
		_next_daggers_time = active_time + daggers_cooldown

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
			nearest = {"position": position}
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
	for chest in _world_chests:
		var chest_color := Color("#61e7ff") if chest["family"] == "weapon" else Color("#c7a4ff")
		draw_rect(Rect2(chest["position"] - Vector2(7.0, 7.0), Vector2(14.0, 14.0)), chest_color)
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false):
			var projectile_transform: Dictionary = components["Transform2D"]
			var projectile_type: String = components.get("EnemyType", "")
			var projectile_color := Color("#ffd166")
			if projectile_type == "inferno_sprayer":
				projectile_color = Color("#ff7547")
			elif projectile_type == "crimson_dagger":
				projectile_color = Color("#ff3155")
			draw_circle(Vector2(float(projectile_transform["x"]), float(projectile_transform["y"])), 3.0, projectile_color)
			continue
		if components.get("IsXpOrb", false):
			var orb_transform: Dictionary = components["Transform2D"]
			draw_circle(Vector2(float(orb_transform["x"]), float(orb_transform["y"])), 4.0, Color("#b19cff"))
			continue
		var transform: Dictionary = components["Transform2D"]
		var position := Vector2(float(transform["x"]), float(transform["y"]))
		var enemy_type: String = components.get("EnemyType", "chaser")
		var radius := 8.0
		var color := Color("#ff5ca8")
		if enemy_type == "mid_boss" or enemy_type == "final_boss":
			radius = 20.0
			color = Color("#ff7b54") if enemy_type == "mid_boss" else Color("#ff304f")
		draw_circle(position, radius, color)
