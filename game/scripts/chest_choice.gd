extends PanelContainer

signal option_selected(option_id: String)

@onready var _options: VBoxContainer = $Content/Options

const FAMILY_COLORS := {
	"weapon": Color("#37E8F5"),
	"relic": Color("#FF75E3"),
}

func _ready() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	var keyboard_accept := event.is_action_pressed("ui_accept")
	if event is InputEventKey:
		keyboard_accept = keyboard_accept or event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
	if not visible or not keyboard_accept:
		return
	var focused := get_viewport().gui_get_focus_owner() as Button
	if focused == null or not _options.is_ancestor_of(focused):
		focused = _options.get_child(0) as Button if _options.get_child_count() > 0 else null
	if focused != null:
		focused.emit_signal("pressed")
		get_viewport().set_input_as_handled()

func present(options: Array, required_count: int = 3, heading: String = "CHEST — CHOOSE ONE") -> bool:
	if required_count < 1 or required_count > 3 or options.size() != required_count:
		return false
	var seen_ids: Dictionary = {}
	for option in options:
		if not option is Dictionary or not option.has_all(["id", "title", "description"]):
			return false
		var option_id := str(option["id"])
		if option_id.is_empty() or seen_ids.has(option_id):
			return false
		seen_ids[option_id] = true
	_clear_options()
	$Content/Title.text = heading
	var heading_upper := heading.to_upper()
	var family := "relic" if heading_upper.contains("RELIC") else "weapon" if heading_upper.contains("WEAPON") else ""
	$Content/Title.add_theme_color_override("font_color", FAMILY_COLORS.get(family, Color("#37E8F5")))
	for index in range(options.size()):
		var option: Dictionary = options[index]
		var button := Button.new()
		button.name = "Choice%d" % index
		# Keep the complete offer on the button while rendering its title and description separately.
		button.text = "%s\n%s" % [str(option["title"]), str(option["description"])]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.tooltip_text = button.text
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
			button.add_theme_color_override(state, Color(1.0, 1.0, 1.0, 0.0))
		button.add_theme_font_size_override("font_size", 8)
		button.custom_minimum_size.y = 60.0
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		button.icon = null
		var content_margin := MarginContainer.new()
		content_margin.name = "ContentMargin"
		content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content_margin.add_theme_constant_override("margin_left", 7)
		content_margin.add_theme_constant_override("margin_top", 4)
		content_margin.add_theme_constant_override("margin_right", 7)
		content_margin.add_theme_constant_override("margin_bottom", 4)
		content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(content_margin)
		var offer_row := HBoxContainer.new()
		offer_row.name = "OfferRow"
		offer_row.add_theme_constant_override("separation", 6)
		offer_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content_margin.add_child(offer_row)
		var icon := TextureRect.new()
		icon.name = "OfferIcon"
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon_path := str(option.get("icon", ""))
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		else:
			icon.visible = false
		offer_row.add_child(icon)
		var offer_details := VBoxContainer.new()
		offer_details.name = "OfferDetails"
		offer_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		offer_details.alignment = BoxContainer.ALIGNMENT_CENTER
		offer_details.add_theme_constant_override("separation", 2)
		offer_details.mouse_filter = Control.MOUSE_FILTER_IGNORE
		offer_row.add_child(offer_details)
		var offer_title := Label.new()
		offer_title.name = "OfferTitle"
		offer_title.text = str(option["title"])
		offer_title.add_theme_color_override("font_color", Color("#F6F7FF"))
		offer_title.add_theme_font_size_override("font_size", 9)
		offer_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		offer_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		offer_details.add_child(offer_title)
		var offer_description := Label.new()
		offer_description.name = "OfferDescription"
		offer_description.text = str(option["description"])
		offer_description.add_theme_color_override("font_color", Color("#A6AEC4"))
		offer_description.add_theme_font_size_override("font_size", 8)
		offer_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		offer_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
		offer_details.add_child(offer_description)
		button.pressed.connect(_choose.bind(str(option["id"])))
		_options.add_child(button)
	visible = true
	(_options.get_child(0) as Button).grab_focus()
	return true

func _choose(option_id: String) -> void:
	visible = false
	option_selected.emit(option_id)

func _clear_options() -> void:
	for child in _options.get_children():
		_options.remove_child(child)
		child.queue_free()
