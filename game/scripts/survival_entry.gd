extends Node

const SAVE_SERVICE_SCRIPT := preload("res://scripts/save_service.gd")
const PROGRESSION_SERVICE_SCRIPT := preload("res://scripts/progression_service.gd")

func _ready() -> void:
	call_deferred("_open_survival")

func _open_survival() -> void:
	var packed_scene: PackedScene = load("res://scenes/survival_session.tscn")
	var session: Node2D = packed_scene.instantiate()
	session.progression_service = PROGRESSION_SERVICE_SCRIPT.new(SAVE_SERVICE_SCRIPT.new(), "0")
	get_tree().root.add_child(session)
	get_tree().current_scene = session
	queue_free()
