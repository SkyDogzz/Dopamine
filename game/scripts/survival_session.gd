extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SPAWN_OFFSET := Vector2(140.0, 0.0)

@export var spawn_initial_enemy: bool = true
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

var simulation: Object
var player: CharacterBody2D
var last_target_sequence := 0
var player_hp := 0.0
var player_active_time := 0.0
var run_over := false
var _last_target := Vector2(INF, INF)
var _last_simulation_time := 0.0
var _last_combat_event_sequence := 0
var _next_weapon_time := 0.0
var _entities: Array = []

func _ready() -> void:
	player = PLAYER_SCENE.instantiate()
	player.name = "Player"
	add_child(player)
	simulation = ClassDB.instantiate("CombatSimulation")
	if simulation == null:
		push_error("CombatSimulation GDExtension class is unavailable")
		set_physics_process(false)
		return
	player_hp = simulation.initial_player_hp()
	_publish_player_target()
	if spawn_initial_enemy:
		simulation.spawn_enemy("chaser", 1, ENEMY_SPAWN_OFFSET, Vector2.ZERO)
	simulation.resume()

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
		if event["type"] == "death" and not run_over:
			var healing: float = float(simulation.kill_heal_amount(float(event["threat_level"])))
			player_hp = minf(float(simulation.initial_player_hp()), player_hp + healing)
	if latest_event_sequence > _last_combat_event_sequence:
		_last_combat_event_sequence = latest_event_sequence
		simulation.acknowledge_events(latest_event_sequence)
	_entities = state["entities"]
	_fire_lightning_conductor(current_simulation_time, state["paused"])
	if player_hp <= 0.0 and not run_over:
		run_over = true
		simulation.pause()
	queue_redraw()

func _fire_lightning_conductor(active_time: float, paused: bool) -> void:
	if not weapon_enabled or paused or run_over or lightning_cooldown <= 0.0 or active_time < _next_weapon_time:
		return
	var selected_ids: Array[Vector2i] = []
	var max_distance_squared := lightning_range * lightning_range
	for _chain in range(lightning_chain_count):
		var best: Dictionary = {}
		var best_distance_squared := max_distance_squared
		for entity in _entities:
			var components: Dictionary = entity["components"]
			if components.get("IsProjectile", false):
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
			direction * lightning_projectile_speed, lightning_damage,
			lightning_projectile_radius, lightning_projectile_lifetime
		)
		if sequence > 0:
			var id: Dictionary = best["id"]
			selected_ids.append(Vector2i(int(id["index"]), int(id["generation"])))
	if not selected_ids.is_empty():
		_next_weapon_time = active_time + lightning_cooldown

func _publish_player_target() -> void:
	var target := player.global_position
	if target.distance_squared_to(_last_target) < 0.01:
		return
	_last_target = target
	last_target_sequence = simulation.set_steering_target(
		target, 75.0, enemy_separation_radius, enemy_separation_weight
	)

func _draw() -> void:
	for entity in _entities:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false):
			var projectile_transform: Dictionary = components["Transform2D"]
			draw_circle(Vector2(float(projectile_transform["x"]), float(projectile_transform["y"])), 3.0, Color("#ffd166"))
			continue
		var transform: Dictionary = components["Transform2D"]
		var position := Vector2(float(transform["x"]), float(transform["y"]))
		draw_circle(position, 8.0, Color("#ff5ca8"))
