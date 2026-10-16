extends Control

const BG := Color("#10152B")
const TEXT := Color("#F6F7FF")
const MUTED := Color("#A5AEC3")
const CYAN := Color("#37E8F5")
const MAGENTA := Color("#E879F9")
const YELLOW := Color("#FFD447")
const GREEN := Color("#48E69B")

var detail_open := false
var _compact_values: Label
var _detail_panel: PanelContainer
var _detail_content: VBoxContainer
var _detail_scroll: ScrollContainer
var _xp_status: Label
var _close_button: Button
var _last_stats: Dictionary = {}
var _last_xp_status := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_compact_panel()
	_build_detail_panel()

func set_detail_open(open: bool) -> void:
	detail_open = open
	_detail_panel.visible = open
	if open:
		_close_button.grab_focus()

func toggle_detail() -> void:
	set_detail_open(not detail_open)

func update_stats(stats: Dictionary, xp_status: String) -> void:
	if not is_instance_valid(_compact_values):
		return
	var damage: Dictionary = stats.get("damage_pct", {})
	var move_speed: Dictionary = stats.get("move_speed_pct", {})
	var crit: Dictionary = stats.get("critical_chance_pct", {})
	_compact_values.text = "DMG %s   SPD %s   CRIT %s" % [
		str(damage.get("compact", "100%")),
		str(move_speed.get("compact", "240")),
		str(crit.get("compact", "0%")),
	]
	_xp_status.text = xp_status
	if stats == _last_stats and xp_status == _last_xp_status:
		return
	_last_stats = stats.duplicate(true)
	_last_xp_status = xp_status
	for child in _detail_content.get_children():
		child.queue_free()
	for stat_id in stats:
		var stat: Dictionary = stats[stat_id]
		_detail_content.add_child(_stat_row(stat))

func _build_compact_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "Compact"
	panel.position = Vector2(8.0, 56.0)
	panel.custom_minimum_size = Vector2(214.0, 25.0)
	panel.add_theme_stylebox_override("panel", _panel_style(CYAN))
	add_child(panel)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 1)
	panel.add_child(content)
	var heading := _label("RUN STATS  ·  TAB", 8, CYAN)
	content.add_child(heading)
	_compact_values = _label("DMG 100%   SPD 240   CRIT 0%", 8, TEXT)
	content.add_child(_compact_values)

func _build_detail_panel() -> void:
	_detail_panel = PanelContainer.new()
	_detail_panel.name = "Detail"
	_detail_panel.position = Vector2(8.0, 56.0)
	_detail_panel.custom_minimum_size = Vector2(260.0, 270.0)
	_detail_panel.size = Vector2(260.0, 270.0)
	_detail_panel.add_theme_stylebox_override("panel", _panel_style(CYAN))
	_detail_panel.visible = false
	_detail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_detail_panel)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 4)
	_detail_panel.add_child(content)
	var header := HBoxContainer.new()
	header.name = "Header"
	content.add_child(header)
	var title := _label("RUN STATISTICS", 10, CYAN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_close_button = Button.new()
	_close_button.name = "CloseButton"
	_close_button.text = "CLOSE  [TAB]"
	_close_button.focus_mode = Control.FOCUS_ALL
	_close_button.custom_minimum_size = Vector2(78, 20)
	_close_button.add_theme_font_size_override("font_size", 8)
	_close_button.add_theme_color_override("font_color", TEXT)
	_close_button.add_theme_color_override("font_focus_color", CYAN)
	_close_button.pressed.connect(func() -> void: set_detail_open(false))
	header.add_child(_close_button)
	_xp_status = _label("XP LEVEL 1  ·  RUN BONUSES 0", 8, YELLOW)
	_xp_status.name = "XPStatus"
	content.add_child(_xp_status)
	var source_legend := _label("RUN/XP     GEAR     ACH     TREE", 7, MUTED)
	content.add_child(source_legend)
	_detail_scroll = ScrollContainer.new()
	_detail_scroll.name = "StatsScroll"
	_detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_scroll.focus_mode = Control.FOCUS_ALL
	_detail_scroll.focus_neighbor_top = _detail_panel.get_path_to(_close_button)
	_detail_scroll.add_theme_stylebox_override("focus", _focus_style())
	_detail_scroll.gui_input.connect(_scroll_detail)
	content.add_child(_detail_scroll)
	_close_button.focus_neighbor_bottom = _detail_panel.get_path_to(_detail_scroll)
	_detail_content = VBoxContainer.new()
	_detail_content.add_theme_constant_override("separation", 3)
	_detail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_scroll.add_child(_detail_content)

func _stat_row(stat: Dictionary) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	var headline := HBoxContainer.new()
	column.add_child(headline)
	var name := _label(str(stat.get("label", "STAT")), 8, TEXT)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	headline.add_child(name)
	headline.add_child(_label(str(stat.get("total_text", "—")), 8, CYAN))
	var contributions := HBoxContainer.new()
	contributions.add_theme_constant_override("separation", 7)
	column.add_child(contributions)
	for source in ["run", "equipment", "achievements", "skill_tree"]:
		var source_value := float(stat.get(source, 0.0))
		if is_zero_approx(source_value):
			continue
		var source_name: String = {"run": "R/XP", "equipment": "G", "achievements": "A", "skill_tree": "T"}[source]
		var source_color: Color = {"run": CYAN, "equipment": MAGENTA, "achievements": YELLOW, "skill_tree": GREEN}[source]
		contributions.add_child(_label("%s %s" % [source_name, str(stat.get("source_text", {}).get(source, "0"))], 7, source_color))
	return column

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _scroll_detail(event: InputEvent) -> void:
	var scroll_amount := 0
	if event.is_action_pressed("ui_down"):
		scroll_amount = 24
	elif event.is_action_pressed("ui_up"):
		scroll_amount = -24
	elif event.is_action_pressed("ui_page_down"):
		scroll_amount = 100
	elif event.is_action_pressed("ui_page_up"):
		scroll_amount = -100
	if scroll_amount != 0:
		_detail_scroll.scroll_vertical = clampi(
			_detail_scroll.scroll_vertical + scroll_amount,
			0,
			maxi(0, int(_detail_content.size.y - _detail_scroll.size.y))
		)
		_detail_scroll.accept_event()

func _focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = CYAN
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	return style

func _panel_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BG
	style.border_color = accent
	style.set_border_width_all(1)
	style.border_width_left = 2
	style.set_corner_radius_all(0)
	style.content_margin_left = 5.0
	style.content_margin_top = 3.0
	style.content_margin_right = 5.0
	style.content_margin_bottom = 3.0
	return style
