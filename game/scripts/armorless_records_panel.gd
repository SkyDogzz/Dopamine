extends CenterContainer

signal close_requested

const DIFFICULTY_SCRIPT := preload("res://scripts/survival_difficulty.gd")

@onready var _records: VBoxContainer = $Panel/Content/RecordsScroll/Records
@onready var _close_button: Button = $Panel/Content/CloseButton

func _ready() -> void:
	visible = false
	_close_button.pressed.connect(func() -> void: close_requested.emit())

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		get_viewport().set_input_as_handled()

func present(records: Dictionary) -> void:
	for child in _records.get_children():
		_records.remove_child(child)
		child.queue_free()
	for difficulty_id in DIFFICULTY_SCRIPT.ORDER:
		var record: Dictionary = records.get(difficulty_id, {})
		var summary := "AUCUN RECORD"
		if int(record.get("wave", 0)) > 0:
			var seconds := int(floor(float(record.get("survival_time_seconds", 0.0))))
			summary = "VAGUE %d  ·  %02d:%02d  ·  %d KILLS" % [
				int(record["wave"]), seconds / 60, seconds % 60, int(record["kills"]),
			]
		var row := Label.new()
		row.name = difficulty_id.to_upper()
		row.custom_minimum_size = Vector2(0, 22)
		row.add_theme_font_size_override("font_size", 8)
		row.add_theme_color_override("font_color", Color("#E4E8F5"))
		row.text = "%s   ·   %s" % [difficulty_id.to_upper(), summary]
		row.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.clip_text = true
		_records.add_child(row)
	visible = true
	_close_button.grab_focus()
