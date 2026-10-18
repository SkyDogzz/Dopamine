extends SceneTree

const FONT_PATHS := [
	"res://assets/fonts/NeonArcadePixel.ttf",
	"res://assets/fonts/NeonArcadeUI.ttf",
]
const SOURCE_PATHS := [
	"res://assets/source/fonts/NeonArcadePixel.sfd",
	"res://assets/source/fonts/NeonArcadeUI.sfd",
]
const REQUIRED_GLYPHS := "SURVIVAL ÉQUIPEMENT DÉGÂTS • +12% ← ↑ → ↓ ◆ ✓"

func _initialize() -> void:
	for path in FONT_PATHS:
		var font := load(path) as FontFile
		if font == null:
			_fail("Could not load original font: %s" % path)
			return
		print("font metrics %s: height8=%s ascent8=%s descent8=%s" % [path, font.get_height(8), font.get_ascent(8), font.get_descent(8)])
		for character in REQUIRED_GLYPHS:
			if font.get_glyph_index(16, character.unicode_at(0), 0) == 0:
				_fail("Font %s is missing glyph %s" % [path, character])
				return
	for path in SOURCE_PATHS:
		var source := FileAccess.open(path, FileAccess.READ)
		if source == null or source.get_length() < 10000 or not source.get_as_text().begins_with("SplineFontDB:"):
			_fail("Missing editable FontForge source: %s" % path)
			return
	var theme := load("res://themes/dopamine_ui.tres") as Theme
	if theme == null or theme.get_font("font", "Label").resource_path != FONT_PATHS[1] or \
			theme.get_font("font", "PixelHeading").resource_path != FONT_PATHS[0]:
		_fail("The UI theme should route body and PixelHeading to the original fonts")
		return
	print("Original pixel/UI fonts, glyph coverage, editable sources and Theme routing passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
