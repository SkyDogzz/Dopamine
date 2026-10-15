extends PanelContainer

signal restart_requested

@onready var _title: Label = $Content/Title
@onready var _summary: Label = $Content/Summary

func _ready() -> void:
	$Content/RestartButton.pressed.connect(_on_restart_pressed)
	visible = false

func show_result(victory: bool, wave_number: int, active_seconds: float, kills: int) -> void:
	_title.text = "VICTORY" if victory else "RUN OVER"
	_title.add_theme_color_override("font_color", Color("#66f2bd") if victory else Color("#ff658a"))
	var total_seconds := int(floor(active_seconds))
	_summary.text = "WAVE %02d  •  %02d:%02d  •  %d KILLS" % [wave_number, total_seconds / 60, total_seconds % 60, kills]
	visible = true

func _on_restart_pressed() -> void:
	restart_requested.emit()
