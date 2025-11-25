shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float softness : hint_range(0.0, 1.0) = 0.4;
uniform vec4 vignette_color : source_color = vec4(0.8, 0.0, 0.0, 1.0);

void fragment() {
	vec2 uv = UV;
	// Calculate distance from edges (works for any aspect ratio)
	float edge_x = min(uv.x, 1.0 - uv.x) * 2.0;  // 0 at edges, 1 at center
	float edge_y = min(uv.y, 1.0 - uv.y) * 2.0;
	float edge_dist = min(edge_x, edge_y);  // Distance from nearest edge

	// Create soft falloff from edges
	float vignette = smoothstep(0.0, 0.3 + softness * 0.4, edge_dist);
	COLOR = vec4(vignette_color.rgb, (1.0 - vignette) * intensity);
}
