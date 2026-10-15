extends CenterContainer

signal close_requested
signal equipment_state_requested(instance_id: String, equipped: bool)

@onready var _items: VBoxContainer = $Panel/Content/Scroll/Items
@onready var _empty_state: Label = $Panel/Content/EmptyState
@onready var _error_state: Label = $Panel/Content/ErrorState
@onready var _close_button: Button = $Panel/Content/CloseButton

const SLOT_ICONS := {
	"helmet": "res://assets/icons/equipment_helmet.png",
	"armor": "res://assets/icons/equipment_armor.png",
	"gloves": "res://assets/icons/equipment_gloves.png",
	"boots": "res://assets/icons/equipment_boots.png",
	"amulet": "res://assets/icons/equipment_amulet.png",
	"ring": "res://assets/icons/equipment_ring.png",
}
const RARITY_ICONS := {
	"normal": "res://assets/icons/rarity_normal.png",
	"magic": "res://assets/icons/rarity_magic.png",
	"mystic": "res://assets/icons/rarity_mystic.png",
	"legendary": "res://assets/icons/rarity_legendary.png",
	"mythic": "res://assets/icons/rarity_mythic.png",
}

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
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	row.add_child(layout)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var slot := str(equipment.get("slot", ""))
	var rarity := str(equipment.get("rarity", ""))
	var icon_path: String = RARITY_ICONS.get(rarity, SLOT_ICONS.get(slot, ""))
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	layout.add_child(icon)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4)
	layout.add_child(content)
	var title := Label.new()
	title.text = "%s  •  %s" % [rarity.to_upper(), slot.to_upper()]
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
	if equipment.get("equipped", false):
		status.text = "EQUIPPED — rolls uncalibrated; no gameplay bonus yet"
	if equipment.get("unique_effect_id") == "pending_choice":
		status.text += "\nUnique effect choice pending"
	content.add_child(status)
	var equip_button := Button.new()
	var is_equipped := bool(equipment.get("equipped", false))
	equip_button.text = "UNEQUIP" if is_equipped else "EQUIP"
	equip_button.pressed.connect(func() -> void:
		equipment_state_requested.emit(str(equipment.get("instance_id", "")), not is_equipped)
	)
	content.add_child(equip_button)
	return row

func _close() -> void:
	visible = false
	close_requested.emit()

func _clear_items() -> void:
	for child in _items.get_children():
		_items.remove_child(child)
		child.queue_free()
