extends CenterContainer

signal close_requested
signal equipment_state_requested(instance_id: String, equipped: bool)
signal enhancement_requested(instance_id: String, stat_id: String, powder_tier: String)
signal unique_effect_requested(instance_id: String, effect_id: String)
signal unique_effect_reroll_requested(instance_id: String, effect_id: String)
signal dismantle_requested(instance_id: String)
signal sell_requested(instance_id: String)

@onready var _items: VBoxContainer = $Panel/Content/Columns/RightColumn/Scroll/Items
@onready var _empty_state: Label = $Panel/Content/Columns/RightColumn/Scroll/Items/EmptyState
@onready var _error_state: Label = $Panel/Content/Columns/RightColumn/Scroll/Items/ErrorState
@onready var _close_button: Button = $Panel/Content/CloseButton
@onready var _resources: Label = $Panel/Content/Header/Resources
@onready var _feedback: Label = $Panel/Content/Feedback
@onready var _compare_title: Label = $Panel/Content/Columns/RightColumn/Compare/Comparison/CompareTitle
@onready var _compare_body: Label = $Panel/Content/Columns/RightColumn/Compare/Comparison/CompareBody
@onready var _item_title: Label = $Panel/Content/Columns/RightColumn/ItemHeader/ItemTitle
@onready var _management_button: Button = $Panel/Content/Columns/RightColumn/ItemHeader/ManagementButton
@onready var _portrait: TextureRect = $Panel/Content/Columns/Loadout/Body/Character/Portrait
@onready var _slots: VBoxContainer = $Panel/Content/Columns/Loadout/Body/Slots

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
const SLOTS := ["helmet", "armor", "gloves", "boots", "amulet", "ring"]
const SLOT_NAMES := {"helmet": "HELMET", "armor": "ARMOR", "gloves": "GLOVES", "boots": "BOOTS", "amulet": "AMULET", "ring": "RING"}
const STAT_NAMES := {
	"damage_pct": "DAMAGE", "attack_speed_pct": "ATTACK SPEED", "critical_chance_pct": "CRIT CHANCE",
	"critical_damage_pct": "CRIT DAMAGE", "max_hp": "MAX HP", "move_speed_pct": "MOVE SPEED",
	"kill_healing_pct": "KILL HEALING", "area_pct": "AREA", "cooldown_reduction_pct": "COOLDOWN",
	"xp_pct": "XP GAIN", "pickup_radius_pct": "PICKUP RADIUS", "projectile_speed_pct": "PROJECTILE SPEED",
}
const UNIQUE_EFFECTS := [
	"lightning_burst", "overflow_shield", "evolution_shockwave",
	"elite_haste", "free_first_chest_reroll", "expanded_loadout", "revive_once",
]
const DISMANTLE_POWDER := {
	"normal": "1 BASIC", "magic": "3 BASIC", "mystic": "1 REFINED",
	"legendary": "3 REFINED", "mythic": "1 PURE",
}
const SELL_ESSENCE: Dictionary = PROGRESSION_SERVICE_SCRIPT.PROPOSED_SELL_ESSENCE

var _sell_confirmation: Control
var _sell_description: Label
var _pending_sell_instance_id := ""
var _profile: Dictionary = {}
var _selected_slot := "helmet"
var _selected_instance_id := ""
var _management_mode := false
var _slot_buttons: Dictionary = {}

func _ready() -> void:
	visible = false
	_close_button.pressed.connect(_close)
	_management_button.pressed.connect(_toggle_management_mode)
	for index in range(SLOTS.size()):
		var button := _slots.get_child(index) as Button
		var slot: String = SLOTS[index]
		_slot_buttons[slot] = button
		button.pressed.connect(func() -> void: _select_slot(slot))
	_sell_confirmation = load("res://scenes/sell_confirmation.tscn").instantiate()
	_sell_description = _sell_confirmation.get_node("Center/Panel/Content/Description")
	_sell_confirmation.get_node("Center/Panel/Content/Actions/CancelButton").pressed.connect(_cancel_sell)
	_sell_confirmation.get_node("Center/Panel/Content/Actions/SellButton").pressed.connect(_confirm_sell)
	add_child(_sell_confirmation)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if _sell_confirmation.visible:
			_cancel_sell()
			get_viewport().set_input_as_handled()
			return
		_close()
		get_viewport().set_input_as_handled()

func present(profile: Dictionary) -> void:
	_clear_items()
	_error_state.visible = false
	_feedback.visible = false
	_profile = profile.duplicate(true)
	_selected_instance_id = ""
	_management_mode = false
	_selected_slot = "helmet"
	var inventory: Array = profile.get("equipment_inventory", [])
	for equipment in inventory:
		if bool(equipment.get("equipped", false)):
			_selected_slot = str(equipment.get("slot", "helmet"))
			break
	var resources: Dictionary = profile.get("resources", {})
	_resources.text = "ESSENCE %d" % int(resources.get("essence", 0))
	_portrait.texture = (load(SLOT_ICONS["armor"]) as Texture2D if ResourceLoader.exists(SLOT_ICONS["armor"]) else null)
	_refresh_slots()
	_rebuild_inventory(inventory, resources)
	visible = true
	(_slot_buttons[_selected_slot] as Button).grab_focus()

func present_error() -> void:
	_clear_items()
	_profile.clear()
	_empty_state.visible = false
	_error_state.visible = true
	visible = true
	_close_button.grab_focus()

func show_feedback(message: String) -> void:
	_feedback.text = message
	_feedback.visible = true

func selected_slot() -> String:
	return _selected_slot

func set_selected_slot(slot: String) -> void:
	if slot in SLOTS:
		_select_slot(slot)

func inventory_item_count() -> int:
	var count := 0
	for child in _items.get_children():
		if child is Control and child.name.begins_with("Equipment_"):
			count += 1
	return count

func _select_slot(slot: String) -> void:
	_selected_slot = slot
	_selected_instance_id = ""
	_refresh_slots()
	_rebuild_inventory(_profile.get("equipment_inventory", []), _profile.get("resources", {}))

func _refresh_slots() -> void:
	for slot in SLOTS:
		var equipped: Dictionary = {}
		for equipment in _profile.get("equipment_inventory", []):
			if equipment.get("slot", "") == slot and equipment.get("equipped", false):
				equipped = equipment
				break
		var button: Button = _slot_buttons[slot]
		button.text = "%s  ·  %s" % [SLOT_NAMES[slot], str(equipped.get("rarity", "EMPTY")).to_upper()]
		button.button_pressed = slot == _selected_slot
		button.toggle_mode = true
		button.tooltip_text = str(equipped.get("instance_id", "No item equipped"))

func _rebuild_inventory(inventory: Array, resources: Dictionary) -> void:
	_clear_items()
	var compatible: Array[Dictionary] = []
	for equipment in inventory:
		if str(equipment.get("slot", "")) == _selected_slot:
			compatible.append(equipment)
	_empty_state.visible = compatible.is_empty()
	_item_title.text = "%s  ·  %d ITEM%s" % [SLOT_NAMES[_selected_slot], compatible.size(), "" if compatible.size() == 1 else "S"]
	for equipment in compatible:
		_items.add_child(_create_item_row(equipment, resources))
	if compatible.is_empty():
		_compare_title.text = "BONUS PREVIEW  ·  NO CHANGE"
		_compare_body.text = "No item fits this slot."
	else:
		_update_comparison(false)
	if not _management_mode and not _selected_instance_id.is_empty():
		_update_comparison()

func _update_comparison(add_action: bool = true) -> void:
	var current: Dictionary = {}
	var candidate: Dictionary = {}
	for equipment in _profile.get("equipment_inventory", []):
		if equipment.get("slot", "") != _selected_slot:
			continue
		if equipment.get("equipped", false):
			current = equipment
		if equipment.get("instance_id", "") == _selected_instance_id:
			candidate = equipment
	var before := _equipment_totals(_profile.get("equipment_inventory", []), _selected_slot, "")
	var after := _equipment_totals(_profile.get("equipment_inventory", []), _selected_slot, _selected_instance_id)
	if _selected_instance_id.is_empty() or candidate.is_empty():
		after = before
	var lines := PackedStringArray()
	var stat_ids: Array = EQUIPMENT_GENERATOR_SCRIPT.STAT_IDS
	for stat_id in stat_ids:
		var old_value := float(before.get(stat_id, 0.0))
		var new_value := float(after.get(stat_id, 0.0))
		if is_zero_approx(old_value) and is_zero_approx(new_value):
			continue
		var delta := new_value - old_value
		lines.append("%s  %.1f → %.1f  (%+.1f)" % [STAT_NAMES.get(stat_id, str(stat_id).to_upper()), old_value, new_value, delta])
	_compare_title.text = "BEFORE → AFTER  ·  %s" % SLOT_NAMES[_selected_slot]
	_compare_body.text = "\n".join(lines) if not lines.is_empty() else \
		("EQUIPPED ITEM SELECTED  ·  NO CHANGE" if not current.is_empty() and current.get("instance_id", "") == _selected_instance_id else "NO EQUIPPED BONUS  →  NO CHANGE")
	if not add_action:
		return
	for child in _items.get_children():
		if child is Button and (child as Button).name == "EquipAction":
			_items.remove_child(child)
			child.queue_free()
	var action := Button.new()
	action.name = "EquipAction"
	var remove_equipped: bool = not current.is_empty() and current.get("instance_id", "") == _selected_instance_id
	if remove_equipped:
		action.text = "REMOVE EQUIPPED ITEM"
		action.disabled = false
	elif candidate.is_empty():
		action.text = "SELECT AN ITEM TO EQUIP"
		action.disabled = true
	else:
		action.text = "EQUIPPED" if current.get("instance_id", "") == _selected_instance_id else "EQUIP SELECTED ITEM"
		action.disabled = current.get("instance_id", "") == _selected_instance_id
	var action_instance_id := str(current.get("instance_id", "")) if remove_equipped else _selected_instance_id
	var action_equipped: bool = not remove_equipped
	action.pressed.connect(func() -> void: equipment_state_requested.emit(action_instance_id, action_equipped))
	_items.add_child(action)

func _equipment_totals(inventory: Array, replaced_slot: String, candidate_id: String) -> Dictionary:
	var totals: Dictionary = {}
	for stat_id in EQUIPMENT_GENERATOR_SCRIPT.STAT_IDS:
		totals[stat_id] = 0.0
	for equipment in inventory:
		var active := bool(equipment.get("equipped", false))
		if str(equipment.get("slot", "")) == replaced_slot:
			active = not candidate_id.is_empty() and str(equipment.get("instance_id", "")) == candidate_id
		if not active:
			continue
		for line in equipment.get("stat_lines", []):
			var stat_id := str(line.get("stat_id", ""))
			totals[stat_id] += EQUIPMENT_GENERATOR_SCRIPT.stat_value(stat_id, float(line.get("roll_percentile", 0.0)), int(line.get("enhancement_level", 0)))
	return totals

func _toggle_management_mode() -> void:
	_management_mode = not _management_mode
	_management_button.text = "LOADOUT" if _management_mode else "DETAILS"
	_rebuild_inventory(_profile.get("equipment_inventory", []), _profile.get("resources", {}))

func _create_item_row(equipment: Dictionary, resources: Dictionary) -> Control:
	if not _management_mode:
		return _create_loadout_item_row(equipment)
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
		icon.texture = (load(icon_path) as Texture2D if ResourceLoader.exists(icon_path) else null)
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
	var unique_effect_id := str(equipment.get("unique_effect_id", ""))
	var reroll_cost: Dictionary = PROGRESSION_SERVICE_SCRIPT.UNIQUE_EFFECT_REROLL_COSTS.get(rarity, {})
	if unique_effect_id == "pending_choice" or (not reroll_cost.is_empty() and not unique_effect_id.is_empty()):
		var effect_row := HBoxContainer.new()
		var effect_choice := OptionButton.new()
		for effect_id in UNIQUE_EFFECTS:
			if unique_effect_id != "pending_choice" and effect_id == unique_effect_id:
				continue
			effect_choice.add_item(effect_id.replace("_", " ").to_upper())
			effect_choice.set_item_metadata(effect_choice.item_count - 1, effect_id)
		effect_row.add_child(effect_choice)
		var effect_action := Button.new()
		if unique_effect_id == "pending_choice":
			effect_action.text = "CHOOSE EFFECT"
			effect_action.pressed.connect(func() -> void:
				unique_effect_requested.emit(
					str(equipment.get("instance_id", "")),
					str(effect_choice.get_item_metadata(effect_choice.selected))
				)
			)
		else:
			var powder_tier := str(reroll_cost["powder_tier"])
			var powder_amount := int(reroll_cost["amount"])
			effect_action.text = "REROLL  •  %d %s" % [powder_amount, powder_tier.to_upper()]
			effect_action.tooltip_text = "Choose a different unique effect for %d %s Powder." % [
				powder_amount, powder_tier.capitalize(),
			]
			effect_action.disabled = int(resources.get("powder_%s" % powder_tier, 0)) < powder_amount
			effect_action.pressed.connect(func() -> void:
				unique_effect_reroll_requested.emit(
					str(equipment.get("instance_id", "")),
					str(effect_choice.get_item_metadata(effect_choice.selected))
				)
			)
		effect_row.add_child(effect_action)
		content.add_child(effect_row)
	var equip_button := Button.new()
	equip_button.name = "EquipmentStateAction"
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
		_sell_description.text = "SELL THIS %s ITEM FOR %d ESSENCE?\nTHIS CANNOT BE UNDONE." % [rarity.to_upper(), sell_value]
		_sell_confirmation.visible = true
		_sell_confirmation.get_node("Center/Panel/Content/Actions/CancelButton").grab_focus()
	)
	content.add_child(sell_button)
	return row

func _create_loadout_item_row(equipment: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.name = "Equipment_%s" % str(equipment.get("instance_id", "item"))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#10172B")
	style.border_color = RARITY_COLORS.get(str(equipment.get("rarity", "normal")), Color("#A6AEC4"))
	style.border_width_left = 3
	style.content_margin_left = 5.0
	style.content_margin_top = 3.0
	style.content_margin_right = 5.0
	style.content_margin_bottom = 3.0
	row.add_theme_stylebox_override("panel", style)
	var line := HBoxContainer.new()
	line.name = "ItemRow"
	line.add_theme_constant_override("separation", 4)
	row.add_child(line)
	var summary := Label.new()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.text = "%s  ·  %s%s" % [str(equipment.get("rarity", "")).to_upper(), SLOT_NAMES[_selected_slot], "  ·  EQUIPPED" if equipment.get("equipped", false) else ""]
	summary.add_theme_font_size_override("font_size", 7)
	line.add_child(summary)
	var preview := Button.new()
	preview.name = "Preview"
	preview.text = "PREVIEW"
	preview.focus_mode = Control.FOCUS_ALL
	preview.pressed.connect(func() -> void:
		_selected_instance_id = str(equipment.get("instance_id", ""))
		_update_comparison()
		_rebuild_inventory(_profile.get("equipment_inventory", []), _profile.get("resources", {}))
	)
	line.add_child(preview)
	return row

func _close() -> void:
	_sell_confirmation.visible = false
	_pending_sell_instance_id = ""
	visible = false
	close_requested.emit()

func _cancel_sell() -> void:
	_sell_confirmation.visible = false
	_pending_sell_instance_id = ""
	_management_button.grab_focus()

func _confirm_sell() -> void:
	if _pending_sell_instance_id.is_empty():
		return
	var instance_id := _pending_sell_instance_id
	_pending_sell_instance_id = ""
	_sell_confirmation.visible = false
	sell_requested.emit(instance_id)

func _clear_items() -> void:
	for child in _items.get_children():
		if child in [_empty_state, _error_state]:
			continue
		_items.remove_child(child)
		child.queue_free()
