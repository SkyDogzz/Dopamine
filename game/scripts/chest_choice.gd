extends PanelContainer

signal option_selected(option_id: String)

@onready var _options: VBoxContainer = $Content/Options

func _ready() -> void:
	visible = false

func present(options: Array) -> bool:
	if options.size() != 3:
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
	for index in range(options.size()):
		var option: Dictionary = options[index]
		var button := Button.new()
		button.name = "Choice%d" % index
		button.text = "%s\n%s" % [str(option["title"]), str(option["description"])]
		button.custom_minimum_size.y = 72.0
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_choose.bind(str(option["id"])))
		_options.add_child(button)
	visible = true
	return true

func _choose(option_id: String) -> void:
	visible = false
	option_selected.emit(option_id)

func _clear_options() -> void:
	for child in _options.get_children():
		_options.remove_child(child)
		child.queue_free()
