extends Control

signal close_requested

@onready var _items: VBoxContainer = $Center/Panel/Content/Scroll/Items
@onready var _close_button: Button = $Center/Panel/Content/CloseButton

func _ready() -> void:
	_close_button.pressed.connect(_on_close_pressed)
	_close_button.grab_focus()

func show_items(weapons: Array[Dictionary], relics: Array[Dictionary]) -> void:
	_add_section("WEAPONS")
	_add_items(weapons)
	_add_section("RELICS")
	_add_items(relics)
	if weapons.is_empty() and relics.is_empty():
		_add_label("No weapons or relics equipped.")

func _add_section(title: String) -> void:
	var label := Label.new()
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
		_items.add_child(row)
		var layout := HBoxContainer.new()
		layout.add_theme_constant_override("separation", 6)
		row.add_child(layout)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(18, 18)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_path := str(item.get("icon", ""))
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		layout.add_child(icon)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		layout.add_child(details)
		_add_label("%s  ·  LV %d" % [str(item["name"]), int(item["level"])], details)
		if str(item["family"]) == "weapon":
			_add_label(_evolution_status(item), details)
		_add_label(str(item["description"]), details, true)

func _evolution_status(item: Dictionary) -> String:
	if bool(item.get("evolved", false)):
		return "EVOLVED · %s" % str(item["evolution_id"]).replace("_", " ").to_upper()
	return "EVOLUTION · LV 5 + %s" % str(item.get("required_relic_name", "RELIC")).to_upper()

func _add_label(text: String, parent: Node = null, wrap: bool = false) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	(parent if parent != null else _items).add_child(label)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()

func _on_close_pressed() -> void:
	close_requested.emit()
