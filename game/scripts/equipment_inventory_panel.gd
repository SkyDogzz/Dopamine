extends CenterContainer

signal close_requested
signal equipment_state_requested(instance_id: String, equipped: bool)
signal enhancement_requested(instance_id: String, stat_id: String, powder_tier: String)
signal unique_effect_requested(instance_id: String, effect_id: String)
signal dismantle_requested(instance_id: String)
signal sell_requested(instance_id: String)

@onready var _items: VBoxContainer = $Panel/Content/Scroll/Items
@onready var _empty_state: Label = $Panel/Content/Scroll/Items/EmptyState
@onready var _error_state: Label = $Panel/Content/Scroll/Items/ErrorState
@onready var _close_button: Button = $Panel/Content/CloseButton
@onready var _resources: Label = $Panel/Content/Resources
@onready var _feedback: Label = $Panel/Content/Feedback

var progression_service: RefCounted

const SLOT_ICONS := {
	"helmet": "res://assets/icons/catalog/equipment_helmet.png",
	"armor": "res://assets/icons/catalog/equipment_armor.png",
	"gloves": "res://assets/icons/catalog/equipment_gloves.png",
	"boots": "res://assets/icons/catalog/equipment_boots.png",
	"amulet": "res://assets/icons/catalog/equipment_amulet.png",
	"ring": "res://assets/icons/catalog/equipment_ring.png",
}
const RARITY_ICONS := {
	"normal": "res://assets/icons/catalog/rarity_normal.png",
	"magic": "res://assets/icons/catalog/rarity_magic.png",
	"mystic": "res://assets/icons/catalog/rarity_mystic.png",
	"legendary": "res://assets/icons/catalog/rarity_legendary.png",
	"mythic": "res://assets/icons/catalog/rarity_mythic.png",
}
const RARITY_COLORS := {
	"normal": Color("#A6AEC4"),
	"magic": Color("#57DDF5"),
	"mystic": Color("#C67BFF"),
	"legendary": Color("#FFD447"),
	"mythic": Color("#FF75E3"),
}
const POWDER_TIERS := ["basic", "refined", "pure", "prismatic"]
const PROGRESSION_SERVICE_SCRIPT := preload("res://scripts/progression_service.gd")
const EQUIPMENT_GENERATOR_SCRIPT := preload("res://scripts/equipment_generator.gd")
const UNIQUE_EFFECTS := [
	"lightning_burst", "overflow_shield", "evolution_shockwave",
	"elite_haste", "free_first_chest_reroll", "expanded_loadout", "revive_once",
]
const DISMANTLE_POWDER := {
	"normal": "1 BASIC", "magic": "3 BASIC", "mystic": "1 REFINED",
	"legendary": "3 REFINED", "mythic": "1 PURE",
}
const SELL_ESSENCE: Dictionary = PROGRESSION_SERVICE_SCRIPT.PROPOSED_SELL_ESSENCE

var _sell_confirmation: ConfirmationDialog
var _pending_sell_instance_id := ""

func _ready() -> void:
	visible = false
	_close_button.pressed.connect(_close)
	_sell_confirmation = ConfirmationDialog.new()
	_sell_confirmation.name = "SellConfirmation"
	_sell_confirmation.title = "SELL EQUIPMENT?"
	_sell_confirmation.ok_button_text = "SELL"
	_sell_confirmation.confirmed.connect(func() -> void:
		sell_requested.emit(_pending_sell_instance_id)
		_pending_sell_instance_id = ""
	)
	add_child(_sell_confirmation)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
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
	row.name = "Equipment_%s" % str(equipment.get("instance_id", "item"))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color("#10172B")
	row_style.border_color = Color("#39486B")
	row_style.border_width_top = 1
	row_style.border_width_right = 1
	row_style.border_width_bottom = 1
	row_style.border_width_left = 3
	row_style.border_color = RARITY_COLORS.get(str(equipment.get("rarity", "normal")), Color("#A6AEC4"))
	row_style.content_margin_left = 6.0
	row_style.content_margin_top = 5.0
	row_style.content_margin_right = 6.0
	row_style.content_margin_bottom = 5.0
	row.add_theme_stylebox_override("panel", row_style)
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 5)
	row.add_child(layout)
	var slot := str(equipment.get("slot", ""))
	var rarity := str(equipment.get("rarity", ""))
	var badges := HBoxContainer.new()
	badges.add_theme_constant_override("separation", 2)
	for badge_data in [
		["SlotIcon", SLOT_ICONS.get(slot, ""), slot.replace("_", " ").capitalize()],
		["RarityIcon", RARITY_ICONS.get(rarity, ""), rarity.capitalize()],
	]:
		var icon_path: String = badge_data[1]
		if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
			continue
		var icon := TextureRect.new()
		icon.name = badge_data[0]
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.texture = load(icon_path)
		icon.tooltip_text = badge_data[2]
		badges.add_child(icon)
	layout.add_child(badges)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 2)
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
		powder_choice.custom_minimum_size.x = 58
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
	status.add_theme_color_override("font_color", Color("#FFD447"))
	status.text = "PROPOSED STAT ROLLS — experimental balance"
	if equipment.get("equipped", false):
		status.text = "EQUIPPED — proposed stat rolls active"
	if equipment.get("unique_effect_id") == "pending_choice":
		status.text += "\nUnique effect choice pending"
	elif str(equipment.get("unique_effect_id", "")) != "":
		var effect_id := str(equipment["unique_effect_id"])
		var effect_status := "VALIDATED ACTIVE" if equipment.get("equipped", false) and effect_id == "revive_once" else \
				"PROPOSED ACTIVE" if equipment.get("equipped", false) and effect_id in [
			"lightning_burst", "overflow_shield", "evolution_shockwave", "elite_haste", "free_first_chest_reroll", "expanded_loadout",
		] else "NO GAMEPLAY EFFECT YET"
		status.text += "\nUNIQUE: %s — %s" % [effect_id.replace("_", " ").to_upper(), effect_status]
		if effect_id == "expanded_loadout" and equipment.get("equipped", false):
			status.text += "\nPROPOSED: +1 WEAPON +1 RELIC SLOT (MAX 6)"
		elif effect_id == "revive_once" and equipment.get("equipped", false):
			status.text += "\nONE REVIVE PER RUN IN SURVIVAL / ENDLESS"
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
	equip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_button.add_theme_color_override("font_color", Color("#37E8F5"))
	equip_button.add_theme_color_override("font_hover_color", Color("#37E8F5"))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 4)
	content.add_child(actions)
	equip_button.pressed.connect(func() -> void:
		equipment_state_requested.emit(str(equipment.get("instance_id", "")), not is_equipped)
	)
	actions.add_child(equip_button)
	var dismantle_button := Button.new()
	var dismantle_yield: String = DISMANTLE_POWDER[rarity]
	dismantle_button.text = "DISMANTLE  •  %s" % dismantle_yield
	dismantle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dismantle_button.add_theme_color_override("font_color", Color("#FF7181"))
	dismantle_button.add_theme_color_override("font_hover_color", Color("#FF7181"))
	dismantle_button.tooltip_text = "Proposed prototype dismantle yield: %s POWDER; economy remains open for calibration." % dismantle_yield
	dismantle_button.pressed.connect(func() -> void:
		dismantle_requested.emit(str(equipment.get("instance_id", "")))
	)
	actions.add_child(dismantle_button)
	var sell_value: int = SELL_ESSENCE[rarity]
	var sell_button := Button.new()
	sell_button.text = "SELL  •  %d ESSENCE" % sell_value
	sell_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_button.add_theme_color_override("font_color", Color("#FFD447"))
	sell_button.add_theme_color_override("font_hover_color", Color("#FFD447"))
	sell_button.tooltip_text = "Proposed sale value; selling removes this equipment and does not refund its enhancements."
	sell_button.pressed.connect(func() -> void:
		_pending_sell_instance_id = str(equipment.get("instance_id", ""))
		_sell_confirmation.dialog_text = "Sell this %s item for %d Essence? This cannot be undone." % [rarity, sell_value]
		_sell_confirmation.popup_centered()
	)
	content.add_child(sell_button)
	return row

func _close() -> void:
	visible = false
	close_requested.emit()

func _clear_items() -> void:
	for child in _items.get_children():
		if child in [_empty_state, _error_state]:
			continue
		_items.remove_child(child)
		child.queue_free()
