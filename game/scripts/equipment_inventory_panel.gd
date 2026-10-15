extends CenterContainer

signal close_requested
signal equipment_state_requested(instance_id: String, equipped: bool)
signal enhancement_requested(instance_id: String, stat_id: String, powder_tier: String)
signal unique_effect_requested(instance_id: String, effect_id: String)
signal dismantle_requested(instance_id: String)

@onready var _items: VBoxContainer = $Panel/Content/Scroll/Items
@onready var _empty_state: Label = $Panel/Content/EmptyState
@onready var _error_state: Label = $Panel/Content/ErrorState
@onready var _close_button: Button = $Panel/Content/CloseButton
@onready var _resources: Label = $Panel/Content/Resources
@onready var _feedback: Label = $Panel/Content/Feedback

var progression_service: RefCounted

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
const POWDER_TIERS := ["basic", "refined", "pure", "prismatic"]
const EQUIPMENT_GENERATOR_SCRIPT := preload("res://scripts/equipment_generator.gd")
const UNIQUE_EFFECTS := [
	"lightning_burst", "overflow_shield", "evolution_shockwave",
	"elite_haste", "free_first_chest_reroll", "revive_knockback",
]
const DISMANTLE_POWDER := {
	"normal": "1 BASIC", "magic": "3 BASIC", "mystic": "1 REFINED",
	"legendary": "3 REFINED", "mythic": "1 PURE",
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
	_feedback.visible = false
	var inventory: Array = profile.get("equipment_inventory", [])
	var resources: Dictionary = profile.get("resources", {})
	_resources.text = "ESSENCE %d  •  BASIC %d  •  REFINED %d  •  PURE %d  •  PRISMATIC %d" % [
		int(resources.get("essence", 0)), int(resources.get("powder_basic", 0)),
		int(resources.get("powder_refined", 0)), int(resources.get("powder_pure", 0)),
		int(resources.get("powder_prismatic", 0)),
	]
	_empty_state.visible = inventory.is_empty()
	for equipment in inventory:
		_items.add_child(_create_item_row(equipment, resources))
	visible = true
	_close_button.grab_focus()

func present_error() -> void:
	_clear_items()
	_empty_state.visible = false
	_error_state.visible = true
	visible = true
	_close_button.grab_focus()

func show_feedback(message: String) -> void:
	_feedback.text = message
	_feedback.visible = true

func _create_item_row(equipment: Dictionary, resources: Dictionary) -> Control:
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
	for line in equipment.get("stat_lines", []):
		var enhancement_row := HBoxContainer.new()
		content.add_child(enhancement_row)
		var details := Label.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.text = "%s — %s  +%d/10" % [
			str(line.get("stat_id", "")).replace("_", " ").to_upper(),
			EQUIPMENT_GENERATOR_SCRIPT.stat_label(str(line.get("stat_id", "")),
				EQUIPMENT_GENERATOR_SCRIPT.stat_value(str(line.get("stat_id", "")),
					float(line.get("roll_percentile", 0.0)), int(line.get("enhancement_level", 0)))),
			int(line.get("enhancement_level", 0)),
		]
		enhancement_row.add_child(details)
		var powder_choice := OptionButton.new()
		powder_choice.custom_minimum_size.x = 115
		for tier_index in range(POWDER_TIERS.size()):
			powder_choice.add_item(POWDER_TIERS[tier_index].to_upper())
			powder_choice.set_item_metadata(tier_index, POWDER_TIERS[tier_index])
		enhancement_row.add_child(powder_choice)
		var enhance_button := Button.new()
		enhance_button.text = "ENHANCE"
		var level := int(line.get("enhancement_level", 0))
		var update_enabled := func(_index: int = 0) -> void:
			var selected_tier: String = str(powder_choice.get_item_metadata(powder_choice.selected))
			var powder_key := "powder_%s" % selected_tier
			enhance_button.disabled = level >= 10 or progression_service == null or \
					int(resources.get(powder_key, 0)) < progression_service.enhancement_cost(rarity, level)
		powder_choice.item_selected.connect(update_enabled)
		update_enabled.call()
		enhance_button.pressed.connect(func() -> void:
			enhancement_requested.emit(
				str(equipment.get("instance_id", "")), str(line.get("stat_id", "")),
				str(powder_choice.get_item_metadata(powder_choice.selected))
			)
		)
		enhancement_row.add_child(enhance_button)
	var status := Label.new()
	status.add_theme_color_override("font_color", Color("#ffd166"))
	status.text = "PROPOSED STAT ROLLS — experimental balance"
	if equipment.get("equipped", false):
		status.text = "EQUIPPED — proposed stat rolls active"
	if equipment.get("unique_effect_id") == "pending_choice":
		status.text += "\nUnique effect choice pending"
	elif str(equipment.get("unique_effect_id", "")) != "":
		status.text += "\nUNIQUE: %s — prototype only, no gameplay effect" % str(equipment["unique_effect_id"]).to_upper()
	content.add_child(status)
	if equipment.get("unique_effect_id") == "pending_choice":
		var effect_row := HBoxContainer.new()
		var effect_choice := OptionButton.new()
		for effect_id in UNIQUE_EFFECTS:
			effect_choice.add_item(effect_id.replace("_", " ").to_upper())
			effect_choice.set_item_metadata(effect_choice.item_count - 1, effect_id)
		effect_row.add_child(effect_choice)
		var choose_effect := Button.new()
		choose_effect.text = "CHOOSE EFFECT"
		choose_effect.pressed.connect(func() -> void:
			unique_effect_requested.emit(
				str(equipment.get("instance_id", "")),
				str(effect_choice.get_item_metadata(effect_choice.selected))
			)
		)
		effect_row.add_child(choose_effect)
		content.add_child(effect_row)
	var equip_button := Button.new()
	var is_equipped := bool(equipment.get("equipped", false))
	equip_button.text = "UNEQUIP" if is_equipped else "EQUIP"
	equip_button.pressed.connect(func() -> void:
		equipment_state_requested.emit(str(equipment.get("instance_id", "")), not is_equipped)
	)
	content.add_child(equip_button)
	var dismantle_button := Button.new()
	dismantle_button.text = "DISMANTLE  •  %s POWDER" % DISMANTLE_POWDER[rarity]
	dismantle_button.tooltip_text = "Proposed prototype dismantle yield; economy remains open for calibration."
	dismantle_button.pressed.connect(func() -> void:
		dismantle_requested.emit(str(equipment.get("instance_id", "")))
	)
	content.add_child(dismantle_button)
	return row

func _close() -> void:
	visible = false
	close_requested.emit()

func _clear_items() -> void:
	for child in _items.get_children():
		_items.remove_child(child)
		child.queue_free()
