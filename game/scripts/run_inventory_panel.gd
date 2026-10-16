extends Control

signal close_requested

const FOCUS_COLOR := Color("#FFD447")
@onready var _items: VBoxContainer = $Center/Panel/Content/Scroll/Items
@onready var _scroll: ScrollContainer = $Center/Panel/Content/Scroll
@onready var _close_button: Button = $Center/Panel/Content/CloseButton
@onready var _counts: Label = $Center/Panel/Content/Counts
var _focused_item_style: StyleBoxFlat

func _ready() -> void:
	_scroll.focus_mode = Control.FOCUS_ALL
	_scroll.draw_focus_border = true
	_scroll.follow_focus = true
	_focused_item_style = _items.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	_focused_item_style.border_color = FOCUS_COLOR
	_focused_item_style.set_border_width_all(1)
	_close_button.pressed.connect(_on_close_pressed)
	_close_button.grab_focus()

func show_items(weapons: Array[Dictionary], relics: Array[Dictionary]) -> void:
	_counts.text = "WEAPONS %d  •  RELICS %d" % [weapons.size(), relics.size()]
	_add_section("WEAPONS")
	_add_items(weapons)
	_add_section("RELICS")
	_add_items(relics)
	if weapons.is_empty() and relics.is_empty():
		_add_label("No weapons or relics equipped.")
	for child in _items.get_children():
		if child is Control and child.focus_mode != Control.FOCUS_NONE:
			child.grab_focus()
			return
	_close_button.grab_focus()

func _add_section(title: String) -> void:
	var label := Label.new()
	label.theme_type_variation = "PixelHeading"
	label.text = title
	label.add_theme_color_override("font_color", Color("#37E8F5"))
	label.add_theme_font_size_override("font_size", 8)
	_items.add_child(label)

func _add_items(items: Array[Dictionary]) -> void:
	if items.is_empty():
		_add_label("None equipped.")
		return
	for item in items:
		var row := PanelContainer.new()
		row.name = "ItemRow_%s" % str(item["id"])
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.focus_mode = Control.FOCUS_ALL
		row.focus_entered.connect(_show_item_focus.bind(row))
		row.focus_exited.connect(_clear_item_focus.bind(row))
		_items.add_child(row)
		var layout := HBoxContainer.new()
		layout.add_theme_constant_override("separation", 6)
		row.add_child(layout)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(24, 24)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var icon_path := str(item.get("icon", ""))
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		layout.add_child(icon)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		layout.add_child(details)
		var title := Label.new()
		title.text = "%s  ·  LV %d" % [str(item["name"]), int(item["level"])]
		title.add_theme_color_override("font_color", Color("#F6F7FF"))
		title.add_theme_font_size_override("font_size", 9)
		details.add_child(title)
		if str(item["family"]) == "weapon":
			var evolution := Label.new()
			evolution.text = _evolution_status(item)
			evolution.add_theme_color_override(
				"font_color", Color("#FF75E3") if bool(item.get("evolved", false)) else Color("#A6AEC4")
			)
			evolution.add_theme_font_size_override("font_size", 8)
			details.add_child(evolution)
		var description := Label.new()
		description.text = str(item["description"])
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_color_override("font_color", Color("#A6AEC4"))
		description.add_theme_font_size_override("font_size", 8)
		details.add_child(description)

func _evolution_status(item: Dictionary) -> String:
	if bool(item.get("evolved", false)):
		return "EVOLVED · %s" % str(item["evolution_id"]).replace("_", " ").to_upper()
	return "EVOLUTION · LV 5 + %s" % str(item.get("required_relic_name", "RELIC")).to_upper()

func _add_label(text: String, parent: Node = null, wrap: bool = false) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	(parent if parent != null else _items).add_child(label)

func _show_item_focus(row: PanelContainer) -> void:
	row.add_theme_stylebox_override("panel", _focused_item_style)

func _clear_item_focus(row: PanelContainer) -> void:
	row.remove_theme_stylebox_override("panel")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()

func _on_close_pressed() -> void:
	close_requested.emit()
