extends PanelContainer

signal option_selected(option_id: String)

@onready var _options: VBoxContainer = $Content/Options

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
	if required_count < 2 or required_count > 3 or options.size() != required_count:
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
	for index in range(options.size()):
		var option: Dictionary = options[index]
		var button := Button.new()
		button.name = "Choice%d" % index
		button.text = "%s\n%s" % [str(option["title"]), str(option["description"])]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 8)
		button.custom_minimum_size.y = 51.0
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		var icon_path := str(option.get("icon", ""))
		if not icon_path.is_empty():
			button.icon = load(icon_path)
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
