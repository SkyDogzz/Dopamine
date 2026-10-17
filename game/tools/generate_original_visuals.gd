extends SceneTree

## Builds small original pixel motifs from primitives in this repository.
## No reference image or external artwork is loaded by this tool.

const REGISTRY := "res://../docs/art/PROVENANCE_ASSETS.csv"
const OUT_ROOT := "res://assets"
const SOURCE_ROOT := "res://assets/source/original_procedural"
const PALETTE := ["#080B18", "#10152B", "#1B2340", "#075A80", "#087FB2", "#0EB8D4", "#37E8F5", "#7623A8", "#A52DCA", "#E13ACB", "#FF75E3", "#A85B19", "#E69825", "#FFD447", "#FFF19A", "#F6F7FF"]
const TILE := ["#080B18", "#10152B", "#1B2340", "#293354", "#075A80", "#087FB2"]

func _initialize() -> void:
	var file := FileAccess.open(REGISTRY, FileAccess.READ)
	if file == null:
		push_error("Cannot read asset provenance registry")
		quit(1)
		return
	var lines := file.get_as_text().split("\n", false)
	var replaced := 0
	var impact_paths: Array[String] = []
	for index in range(1, lines.size()):
		var fields := _csv_row(lines[index])
		if fields.size() < 14 or not (fields[9].contains("Invalid") or fields[11] == "game/tools/generate_original_visuals.gd") or not fields[5].begins_with("Inclus"):
			continue
		var path: String = fields[0]
		if not path.ends_with(".png"):
			continue
		if path.ends_with("/weapon_impacts_pixel.png"):
			impact_paths.append(path)
			continue
		if not _build(path):
			quit(1)
			return
		replaced += 1
	if not impact_paths.is_empty() and not _build_impact_atlas(impact_paths[0]):
		quit(1)
		return
	if not impact_paths.is_empty(): replaced += 1
	print("Generated %d original assets from repository primitives" % replaced)
	quit()

func _build(path: String) -> bool:
	var name := path.get_file().get_basename()
	var size := 32
	if name == "survival_ruins_pixel": size = 1536
	elif name == "boss_dopamine_core": size = 96
	elif name.begins_with("projectile_"): size = 16
	elif name.begins_with("impact_") or name == "weapon_impacts_pixel": size = 64
	var base_size := 256 if size == 1536 else size
	var image := Image.create(base_size, base_size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	if size == 1536:
		_draw_ruins(image)
	else:
		_draw_motif(image, name)
	if size == 1536:
		image.resize(size, size, Image.INTERPOLATE_NEAREST)
	var absolute := ProjectSettings.globalize_path("res://" + path.trim_prefix("game/"))
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	if image.save_png(absolute) != OK:
		push_error("Could not save %s" % path)
		return false
	var source_path := "%s/%s.aseprite" % [SOURCE_ROOT, name]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SOURCE_ROOT))
	return _save_aseprite(image, ProjectSettings.globalize_path(source_path), name)

func _build_impact_atlas(path: String) -> bool:
	var atlas := Image.create(640, 64, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	var names := ["impact_spark", "impact_star", "impact_slash", "impact_pop", "impact_ring", "impact_burst", "impact_shards", "impact_shock_ring", "impact_angular", "impact_evolved"]
	for index in range(names.size()):
		var image := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/vfx/%s.png" % names[index]))
		if image == null or image.get_size() != Vector2i(64, 64): return false
		atlas.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(index * 64, 0))
	var absolute := ProjectSettings.globalize_path("res://" + path.trim_prefix("game/"))
	return atlas.save_png(absolute) == OK and _save_aseprite(atlas, ProjectSettings.globalize_path("%s/weapon_impacts_pixel.aseprite" % SOURCE_ROOT), "weapon_impacts_pixel")

func _draw_motif(image: Image, name: String) -> void:
	var n := image.get_width()
	var unit := maxi(1, n / 32)
	var seed := absi(name.hash())
	var c0 := _color(1 + seed % 2)
	var c1 := _color(3 + seed % 4)
	var c2 := _color(5 + seed % 3)
	var c3 := _color(7 + seed % 5)
	var white := _color(15)
	var cx := n / 2
	var cy := n / 2
	var radius := 5 * unit
	if not _has_semantic_shape(name):
		# Fallback emblem for any future asset without a dedicated motif.
		for y in range(n):
			for x in range(n):
				var dx := absi(x - cx)
				var dy := absi(y - cy)
				var d := maxi(dx, dy) + mini(dx, dy) / 2
				if d <= radius + unit:
					image.set_pixel(x, y, c0 if d > radius - unit else c1)
				if d <= radius - 2 * unit:
					image.set_pixel(x, y, c2)
		match seed % 6:
			0: _line(image, cx, cy - 11 * unit, cx, cy + 11 * unit, unit, white)
			1: _diamond(image, cx, cy, 8 * unit, c3)
			2: _line(image, cx - 8 * unit, cy + 7 * unit, cx + 8 * unit, cy - 7 * unit, 2 * unit, white)
			3: _line(image, cx - 8 * unit, cy, cx + 8 * unit, cy, 2 * unit, white)
			4: _diamond(image, cx, cy, 9 * unit, c3)
			5: _line(image, cx - 8 * unit, cy - 6 * unit, cx + 8 * unit, cy + 6 * unit, 2 * unit, white)
	_draw_semantic(image, name, unit, c1, c2, c3, white)
	if name.begins_with("impact_"):
		_pixel(image, cx - 11 * unit, cy - 8 * unit, c3)
		_pixel(image, cx + 11 * unit, cy + 8 * unit, white)
		_pixel(image, cx - 10 * unit, cy + 9 * unit, c2)
	if name == "boss_dopamine_core":
		# Framed, layered core with a dark eye and asymmetric energy fins.
		_circle(image, cx, cy, 13 * unit, c1)
		_circle(image, cx, cy, 10 * unit, c3)
		_circle(image, cx, cy, 7 * unit, c0)
		_circle(image, cx, cy, 4 * unit, c2)
		_circle(image, cx, cy, 2 * unit, white)
		for angle in range(8):
			var a := TAU * float(angle) / 8.0
			_line(image, cx + roundi(cos(a) * 11 * unit), cy + roundi(sin(a) * 11 * unit), cx + roundi(cos(a) * 15 * unit), cy + roundi(sin(a) * 15 * unit), unit, c3 if angle % 2 == 0 else c2)

func _has_semantic_shape(name: String) -> bool:
	if name.begins_with("impact_"):
		return true
	for token in ["lightning", "conductor", "storm", "shock", "inferno", "fire", "wildfire", "dagger", "crimson", "slash", "blade", "minigun", "bullet", "enemy", "toxic", "plague", "pandemic", "cloud", "meteor", "starfall", "comet", "frost", "nova", "absolute_zero", "prism", "signal", "eye", "chalice", "cup", "crown", "magnet", "coil", "orb", "singularity", "core", "heart", "staff", "prism_laser", "event_horizon", "infinite_circuit", "overdrive_engine", "spectrum_collapse", "shockwave", "bloodstorm"]:
		if name.contains(token):
			return true
	return false

func _draw_semantic(image: Image, name: String, unit: int, shadow: Color, mid: Color, accent: Color, light: Color) -> void:
	var cx := image.get_width() / 2
	var cy := image.get_height() / 2
	var s := maxi(unit, 1)
	if name.contains("prism_laser") or name == "weapon_prism_laser":
		_rect(image, cx - 11*s, cy - 3*s, 22*s, 6*s, accent)
		_rect(image, cx - 11*s, cy - s, 22*s, 2*s, light)
		_diamond(image, cx + 8*s, cy, 5*s, light)
	elif name.contains("event_horizon") or name.contains("singularity"):
		_circle(image, cx, cy, 10*s, accent)
		_circle(image, cx, cy, 7*s, shadow)
		_circle(image, cx + 2*s, cy - 2*s, 3*s, mid)
		for angle in range(4):
			var a := TAU * angle / 4.0
			_line(image, cx + roundi(cos(a)*11*s), cy + roundi(sin(a)*11*s), cx + roundi(cos(a)*14*s), cy + roundi(sin(a)*14*s), s, light)
	elif name.contains("infinite_circuit") or name.contains("overdrive_engine"):
		_rect(image, cx - 8*s, cy - 8*s, 16*s, 16*s, accent)
		_rect(image, cx - 5*s, cy - 5*s, 10*s, 10*s, shadow)
		for offset in [-3, 3]:
			_line(image, cx - 11*s, cy + offset*s, cx - 8*s, cy + offset*s, s, light)
			_line(image, cx + 8*s, cy + offset*s, cx + 11*s, cy + offset*s, s, light)
		_circle(image, cx, cy, 3*s, light)
	elif name.contains("spectrum_collapse") or name.contains("shockwave") or name.contains("evolution_shockwave"):
		for radius_value in [4, 8, 12]:
			for angle in range(8):
				var a := TAU * angle / 8.0
				_pixel(image, cx + roundi(cos(a)*radius_value*s), cy + roundi(sin(a)*radius_value*s), light if angle % 2 == 0 else accent, s)
	elif name.contains("plague_mask"):
		_diamond(image, cx, cy - 2*s, 8*s, accent)
		_rect(image, cx - 4*s, cy - 3*s, 3*s, 3*s, light)
		_rect(image, cx + 2*s, cy - 3*s, 3*s, 3*s, light)
		_line(image, cx, cy + 2*s, cx - 2*s, cy + 8*s, 2*s, mid)
		_line(image, cx, cy + 2*s, cx + 2*s, cy + 8*s, 2*s, mid)
	elif name.contains("magnet_heart"):
		_diamond(image, cx - 4*s, cy - 3*s, 6*s, accent)
		_diamond(image, cx + 4*s, cy - 3*s, 6*s, accent)
		_diamond(image, cx, cy + 3*s, 8*s, accent)
		_pixel(image, cx, cy, light, 3*s)
	elif name.contains("storm_core"):
		_circle(image, cx, cy, 10*s, accent)
		_circle(image, cx, cy, 7*s, shadow)
		_line(image, cx, cy - 10*s, cx, cy + 10*s, 2*s, light)
		_line(image, cx - 10*s, cy, cx + 10*s, cy, 2*s, mid)
	elif name.contains("bloodstorm"):
		_diamond(image, cx, cy, 8*s, accent)
		_line(image, cx, cy - 4*s, cx, cy + 8*s, 2*s, light)
		for offset in [-9, 9]: _pixel(image, cx + offset*s, cy + 5*s, accent, 2*s)
	elif name == "projectile_razorstorm":
		_circle(image, cx, cy, 5*s, accent)
		_circle(image, cx, cy, 2*s, shadow)
		for angle in range(4):
			var a := TAU * float(angle) / 4.0 + PI / 4.0
			var tip := Vector2i(cx + roundi(cos(a) * 12*s), cy + roundi(sin(a) * 12*s))
			var base := Vector2i(cx + roundi(cos(a) * 3*s), cy + roundi(sin(a) * 3*s))
			_line(image, base.x, base.y, tip.x, tip.y, 2*s, light)
			_pixel(image, tip.x, tip.y, mid, 2*s)
	elif name == "evolution_frost_nova":
		_circle(image, cx, cy, 11*s, accent)
		_circle(image, cx, cy, 7*s, shadow)
		_diamond(image, cx, cy, 6*s, light)
		for side in [-1, 1]:
			_line(image, cx + side*8*s, cy - 9*s, cx + side*5*s, cy - 5*s, s, light)
			_line(image, cx + side*5*s, cy - 5*s, cx + side*11*s, cy - 5*s, s, mid)
	elif name == "projectile_absolute_zero":
		_diamond(image, cx, cy, 10*s, accent)
		_diamond(image, cx, cy, 6*s, shadow)
		_pixel(image, cx, cy, light, 2*s)
		for side in [-1, 1]:
			_line(image, cx - 10*s, cy + side*10*s, cx - 6*s, cy + side*6*s, s, light)
			_line(image, cx + 10*s, cy - side*10*s, cx + 6*s, cy - side*6*s, s, light)
	elif name.contains("lightning") or name.contains("conductor") or name.contains("storm") or name.contains("shock"):
		_line(image, cx + 3*s, cy - 12*s, cx - 4*s, cy - 2*s, 3*s, light)
		_line(image, cx - 4*s, cy - 2*s, cx + 2*s, cy - 2*s, 3*s, accent)
		_line(image, cx + 2*s, cy - 2*s, cx - 3*s, cy + 11*s, 3*s, light)
	elif name.contains("inferno") or name.contains("fire") or name.contains("wildfire"):
		_diamond(image, cx, cy + 2*s, 9*s, accent)
		_diamond(image, cx, cy + 3*s, 5*s, light)
		_line(image, cx, cy + 5*s, cx - 2*s, cy - 7*s, 3*s, mid)
		_line(image, cx - 2*s, cy - 7*s, cx + 2*s, cy - 12*s, 2*s, light)
	elif name.contains("dagger") or name.contains("crimson") or name.contains("slash") or name.contains("blade"):
		_line(image, cx - 9*s, cy + 8*s, cx + 8*s, cy - 9*s, 3*s, light)
		_line(image, cx - 11*s, cy + 4*s, cx - 4*s, cy + 11*s, 2*s, accent)
		if name.contains("saw") or name.contains("razor"):
			for i in range(8):
				var a := TAU * i / 8.0
				_line(image, cx + roundi(cos(a)*7*s), cy + roundi(sin(a)*7*s), cx + roundi(cos(a)*12*s), cy + roundi(sin(a)*12*s), s, light)
	elif name.contains("minigun") or name.contains("bullet") or name.contains("enemy"):
		_rect(image, cx - 8*s, cy - 3*s, 16*s, 6*s, mid)
		_rect(image, cx + 2*s, cy - 2*s, 10*s, 4*s, light)
		_rect(image, cx - 5*s, cy + 3*s, 5*s, 5*s, accent)
	elif name.contains("toxic") or name.contains("plague") or name.contains("pandemic") or name.contains("cloud"):
		_circle(image, cx - 5*s, cy + 2*s, 5*s, mid)
		_circle(image, cx + 1*s, cy - 2*s, 7*s, accent)
		_circle(image, cx + 7*s, cy + 3*s, 4*s, mid)
		_circle(image, cx + 1*s, cy + 1*s, 2*s, light)
	elif name.contains("meteor") or name.contains("starfall") or name.contains("comet"):
		_diamond(image, cx + 2*s, cy + 1*s, 7*s, accent)
		_line(image, cx - 4*s, cy + 7*s, cx - 11*s, cy + 12*s, 2*s, light)
		_pixel(image, cx + 2*s, cy - 2*s, light, 3*s)
	elif name.contains("frost") or name.contains("nova") or name.contains("absolute_zero"):
		for a in range(6):
			var angle := TAU * a / 6.0
			_line(image, cx, cy, cx + roundi(cos(angle)*11*s), cy + roundi(sin(angle)*11*s), 2*s, light)
			_pixel(image, cx + roundi(cos(angle)*7*s), cy + roundi(sin(angle)*7*s), accent, 2*s)
	elif name.contains("eye") or name.contains("prism") or name.contains("signal"):
		_diamond(image, cx, cy, 10*s, accent)
		_diamond(image, cx, cy, 6*s, light)
		_circle(image, cx, cy, 3*s, shadow)
		_pixel(image, cx, cy, light, 2*s)
	elif name.contains("chalice") or name.contains("cup"):
		_line(image, cx - 8*s, cy - 8*s, cx + 8*s, cy - 8*s, 2*s, light)
		_line(image, cx - 7*s, cy - 7*s, cx - 4*s, cy + 2*s, 2*s, accent)
		_line(image, cx + 7*s, cy - 7*s, cx + 4*s, cy + 2*s, 2*s, accent)
		_line(image, cx - 4*s, cy + 2*s, cx + 4*s, cy + 2*s, 2*s, light)
		_line(image, cx, cy + 2*s, cx, cy + 8*s, 2*s, mid)
		_line(image, cx - 5*s, cy + 9*s, cx + 5*s, cy + 9*s, 2*s, light)
	elif name.contains("crown"):
		_line(image, cx - 9*s, cy + 6*s, cx + 9*s, cy + 6*s, 2*s, light)
		_line(image, cx - 8*s, cy + 4*s, cx - 7*s, cy - 7*s, 2*s, accent)
		_line(image, cx - 7*s, cy - 7*s, cx, cy, 2*s, light)
		_line(image, cx, cy, cx + 7*s, cy - 7*s, 2*s, light)
		_line(image, cx + 7*s, cy - 7*s, cx + 8*s, cy + 4*s, 2*s, accent)
	elif name.contains("magnet") or name.contains("coil"):
		_line(image, cx - 8*s, cy - 8*s, cx - 8*s, cy + 2*s, 3*s, light)
		_line(image, cx - 8*s, cy + 2*s, cx, cy + 10*s, 3*s, accent)
		_line(image, cx, cy + 10*s, cx + 8*s, cy + 2*s, 3*s, light)
		_line(image, cx + 8*s, cy + 2*s, cx + 8*s, cy - 8*s, 3*s, accent)
	elif name.contains("orb") or name.contains("singularity") or name.contains("core") or name.contains("heart"):
		_circle(image, cx, cy, 9*s, accent)
		_circle(image, cx, cy, 5*s, shadow)
		_circle(image, cx - 2*s, cy - 2*s, 2*s, light)
	elif name.contains("staff"):
		_line(image, cx - 5*s, cy + 11*s, cx + 4*s, cy - 9*s, 3*s, light)
		_circle(image, cx + 5*s, cy - 10*s, 4*s, accent)
	elif name.begins_with("impact_"):
		for a in range(8):
			var angle := TAU * a / 8.0
			var inner := 3*s if name.contains("ring") else 5*s
			var outer := 12*s if name.contains("burst") or name.contains("star") else 9*s
			_line(image, cx + roundi(cos(angle)*inner), cy + roundi(sin(angle)*inner), cx + roundi(cos(angle)*outer), cy + roundi(sin(angle)*outer), 2*s, light if a % 2 == 0 else accent)

func _circle(image: Image, cx: int, cy: int, radius: int, color: Color) -> void:
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x*x + y*y <= radius*radius: _pixel(image, cx+x, cy+y, color)

func _rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for yy in range(y, y+height):
		for xx in range(x, x+width): _pixel(image, xx, yy, color)

func _draw_ruins(image: Image) -> void:
	var w := image.get_width()
	var h := image.get_height()
	image.fill(Color.TRANSPARENT)
	# Dark, sparse masonry silhouettes sit above the arena floor without hiding it.
	for i in range(30):
		var x := (i * 67 + i * i * 13) % w
		var y := (i * 113 + i * i * 7) % h
		var width := 3 + (i * 7 % 12)
		var height := 2 + (i * 5 % 7)
		var color := _color(1 + i % 3)
		for yy in range(y, mini(y + height, h)):
			for xx in range(x, mini(x + width, w)):
				if ((xx + yy + i) % 4) != 0:
					image.set_pixel(xx, yy, color)
		# A broken side wall and a few detached stones add a readable ruin edge.
		var edge_x := mini(x + width, w - 1)
		for yy in range(y, mini(y + height + 3, h)):
			if (yy + i) % 3 != 0:
				image.set_pixel(edge_x, yy, color)

func _line(image: Image, x0: int, y0: int, x1: int, y1: int, thickness: int, color: Color) -> void:
	var steps := maxi(absi(x1 - x0), absi(y1 - y0))
	for i in range(steps + 1):
		var t := float(i) / maxi(1, steps)
		_pixel(image, roundi(lerpf(x0, x1, t)), roundi(lerpf(y0, y1, t)), color, thickness)

func _diamond(image: Image, cx: int, cy: int, radius: int, color: Color) -> void:
	for y in range(-radius, radius + 1):
		var width := radius - absi(y)
		for x in range(-width, width + 1):
			_pixel(image, cx + x, cy + y, color)

func _pixel(image: Image, x: int, y: int, color: Color, size: int = 1) -> void:
	for yy in range(y - size / 2, y - size / 2 + size):
		for xx in range(x - size / 2, x - size / 2 + size):
			if xx >= 0 and yy >= 0 and xx < image.get_width() and yy < image.get_height():
				image.set_pixel(xx, yy, color)

func _color(index: int) -> Color:
	return Color(PALETTE[index % PALETTE.size()])

func _csv_row(line: String) -> PackedStringArray:
	var result := PackedStringArray()
	var value := ""
	var quoted := false
	var i := 0
	while i < line.length():
		var ch := line[i]
		if ch == '"':
			if quoted and i + 1 < line.length() and line[i + 1] == '"':
				value += '"'; i += 1
			else: quoted = not quoted
		elif ch == ',' and not quoted:
			result.append(value); value = ""
		else: value += ch
		i += 1
	result.append(value)
	return result

func _save_aseprite(image: Image, path: String, layer_name: String) -> bool:
	var layer := PackedByteArray()
	for value in [3, 0, 0, 0, 0, 0]: _u16(layer, value)
	layer.append(255); layer.append_array([0, 0, 0]); _string(layer, layer_name)
	var cel := PackedByteArray()
	for value in [0, 0, 0]: _u16(cel, value)
	cel.append(255); _u16(cel, 0); _u16(cel, 0); cel.append_array([0, 0, 0, 0, 0])
	_u16(cel, image.get_width()); _u16(cel, image.get_height()); cel.append_array(image.get_data())
	var chunks := _chunk(0x2004, layer) + _chunk(0x2005, cel)
	var frame := PackedByteArray()
	_u32(frame, chunks.size() + 16); _u16(frame, 0xF1FA); _u16(frame, 2); _u16(frame, 100)
	frame.append_array([0, 0]); _u32(frame, 0); frame.append_array(chunks)
	var data := PackedByteArray(); data.resize(128)
	data.encode_u32(0, 128 + frame.size()); data.encode_u16(4, 0xA5E0); data.encode_u16(6, 1)
	data.encode_u16(8, image.get_width()); data.encode_u16(10, image.get_height()); data.encode_u16(12, 32)
	data.encode_u32(14, 1); data.encode_u16(18, 100); data.encode_u8(34, 1); data.encode_u8(35, 1)
	data.append_array(frame)
	var output := FileAccess.open(path, FileAccess.WRITE)
	if output == null: return false
	output.store_buffer(data)
	return output.get_error() == OK

func _chunk(kind: int, bytes: PackedByteArray) -> PackedByteArray:
	var result := PackedByteArray(); _u32(result, bytes.size() + 6); _u16(result, kind); result.append_array(bytes); return result

func _string(target: PackedByteArray, value: String) -> void:
	var bytes := value.to_utf8_buffer(); _u16(target, bytes.size()); target.append_array(bytes)

func _u16(target: PackedByteArray, value: int) -> void:
	target.append(value & 255); target.append((value >> 8) & 255)

func _u32(target: PackedByteArray, value: int) -> void:
	for shift in [0, 8, 16, 24]: target.append((value >> shift) & 255)
