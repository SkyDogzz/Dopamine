extends CenterContainer

signal close_requested

@onready var _items: VBoxContainer = $Panel/Content/Scroll/Items
@onready var _empty_state: Label = $Panel/Content/EmptyState
@onready var _error_state: Label = $Panel/Content/ErrorState
@onready var _close_button: Button = $Panel/Content/CloseButton

func _ready() -> void:
	visible = false
	_close_button.pressed.connect(_close)

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_close()
		get_viewport().set_input_as_handled()

func present(profile: Dictionary) -> void:
	_clear_items()
	_error_state.visible = false
	var inventory: Array = profile.get("equipment_inventory", [])
	_empty_state.visible = inventory.is_empty()
	for equipment in inventory:
		_items.add_child(_create_item_row(equipment))
	visible = true
	_close_button.grab_focus()

func present_error() -> void:
	_clear_items()
	_empty_state.visible = false
	_error_state.visible = true
	visible = true
	_close_button.grab_focus()

func _create_item_row(equipment: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	row.add_child(content)
	var title := Label.new()
	title.text = "%s  •  %s" % [str(equipment.get("rarity", "")).to_upper(), str(equipment.get("slot", "")).to_upper()]
	content.add_child(title)
	var stats: Array[String] = []
	for line in equipment.get("stat_lines", []):
		stats.append("%s — roll %d%%" % [str(line.get("stat_id", "")).replace("_", " ").to_upper(), roundi(float(line.get("roll_percentile", 0.0)) * 100.0)])
	var details := Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.text = "  •  ".join(stats)
	content.add_child(details)
	var status := Label.new()
	status.add_theme_color_override("font_color", Color("#ffd166"))
	status.text = "ROLLS UNCALIBRATED — no gameplay bonus yet"
	if equipment.get("unique_effect_id") == "pending_choice":
		status.text += "\nUnique effect choice pending"
	content.add_child(status)
	return row

func _close() -> void:
	visible = false
	close_requested.emit()

func _clear_items() -> void:
	for child in _items.get_children():
		_items.remove_child(child)
		child.queue_free()
