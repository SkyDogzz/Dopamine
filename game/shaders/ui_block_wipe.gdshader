shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 wipe_color : source_color = vec4(0.0314, 0.0431, 0.0941, 1.0);

const vec2 GRID = vec2(160.0, 90.0);

float cell_hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(UV * GRID);
	float jitter = (cell_hash(cell) - 0.5) * 0.7;
	float edge = (cell.x + 0.5 + jitter) / GRID.x;
	float covered = step(edge, progress);
	COLOR = vec4(wipe_color.rgb, wipe_color.a * covered);
}
