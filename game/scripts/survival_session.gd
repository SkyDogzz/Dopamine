extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SPAWN_OFFSET := Vector2(140.0, 0.0)

@export var spawn_initial_enemy: bool = true
@export var enemy_separation_radius: float = 18.0
@export_range(0.0, 1.0) var enemy_separation_weight: float = 0.5

var simulation: Object
var player: CharacterBody2D
var last_target_sequence := 0
var _last_target := Vector2(INF, INF)
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
	_entities = state["entities"]
	queue_redraw()

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
			continue
		var transform: Dictionary = components["Transform2D"]
		var position := Vector2(float(transform["x"]), float(transform["y"]))
		draw_circle(position, 8.0, Color("#ff5ca8"))
