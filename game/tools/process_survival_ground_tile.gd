extends SceneTree

const OUTPUT := "res://assets/sprites/environment/survival_ground_tile.png"
const SOURCE := "res://assets/source/environment/survival_ground_tile.aseprite"
const PALETTE := ["#10152B", "#1B2340", "#293354"]
const SIZE := 16
const TILE := [
	"................",
	"................",
	"..##............",
	"..##............",
	"...#....##......",
	"........##......",
	"................",
	".....###........",
	".....###........",
	"......#.........",
	"............##..",
	"............##..",
	"................",
	"..##............",
	"..##............",
	"................",
]

func _initialize() -> void:
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in range(SIZE):
		for x in range(SIZE):
			var symbol: String = TILE[y].substr(x, 1)
			var palette_index := 0 if symbol == "." else (1 if symbol == "#" else 2)
			image.set_pixel(x, y, Color(PALETTE[palette_index]))
	_make_seamless(image)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sprites/environment"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/source/environment"))
	if image.save_png(OUTPUT) != OK or not _save_aseprite(image, SOURCE, "survival_ground_tile"):
		push_error("Could not save active 16x16 Survival ground tile and editable source")
		quit(1)
		return
	print("Built seamless low-contrast 16x16 Survival ground tile from three Art Bible colors")
	quit()

func _make_seamless(image: Image) -> void:
	for coordinate in range(SIZE):
		image.set_pixel(SIZE - 1, coordinate, image.get_pixel(0, coordinate))
	for coordinate in range(SIZE):
		image.set_pixel(coordinate, SIZE - 1, image.get_pixel(coordinate, 0))

func _save_aseprite(image: Image, path: String, layer_name: String) -> bool:
	var layer := PackedByteArray()
	for value in [3, 0, 0, 0, 0, 0]: _u16(layer, value)
	layer.append(255)
	layer.append_array([0, 0, 0])
	_string(layer, layer_name)
	var cel := PackedByteArray()
	for value in [0, 0, 0]: _u16(cel, value)
	cel.append(255)
	_u16(cel, 0)
	_u16(cel, 0)
	cel.append_array([0, 0, 0, 0, 0])
	_u16(cel, SIZE)
	_u16(cel, SIZE)
	cel.append_array(image.get_data())
	var chunks := _chunk(0x2004, layer) + _chunk(0x2005, cel)
	var frame := PackedByteArray()
	_u32(frame, chunks.size() + 16)
	_u16(frame, 0xF1FA)
	_u16(frame, 2)
	_u16(frame, 100)
	frame.append_array([0, 0])
	_u32(frame, 0)
	frame.append_array(chunks)
	var file := PackedByteArray()
	file.resize(128)
	file.encode_u32(0, 128 + frame.size())
	file.encode_u16(4, 0xA5E0)
	file.encode_u16(6, 1)
	file.encode_u16(8, SIZE)
	file.encode_u16(10, SIZE)
	file.encode_u16(12, 32)
	file.encode_u32(14, 1)
	file.encode_u16(18, 100)
	file.encode_u8(34, 1)
	file.encode_u8(35, 1)
	file.append_array(frame)
	var output := FileAccess.open(path, FileAccess.WRITE)
	if output == null:
		return false
	output.store_buffer(file)
	return output.get_error() == OK

func _chunk(chunk_type: int, data: PackedByteArray) -> PackedByteArray:
	var chunk := PackedByteArray()
	_u32(chunk, data.size() + 6)
	_u16(chunk, chunk_type)
	chunk.append_array(data)
	return chunk

func _string(target: PackedByteArray, value: String) -> void:
	var bytes := value.to_utf8_buffer()
	_u16(target, bytes.size())
	target.append_array(bytes)

func _u16(target: PackedByteArray, value: int) -> void:
	target.append(value & 255)
	target.append((value >> 8) & 255)

func _u32(target: PackedByteArray, value: int) -> void:
	for shift in [0, 8, 16, 24]: target.append((value >> shift) & 255)
