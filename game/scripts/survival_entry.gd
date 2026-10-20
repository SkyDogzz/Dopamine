extends Node

var progression_service: RefCounted
var difficulty_id := "normal"
var mode_id := "survival"
var overstimulation_intensity_enabled := false

func _ready() -> void:
	call_deferred("_open_survival")

func _open_survival() -> void:
	var packed_scene: PackedScene = load("res://scenes/survival_session.tscn")
	var session: Node2D = packed_scene.instantiate()
	session.progression_service = progression_service
	session.difficulty_id = difficulty_id
	session.mode_id = mode_id
	session.overstimulation_intensity_enabled = overstimulation_intensity_enabled
	get_tree().root.add_child(session)
	get_tree().current_scene = session
	queue_free()
