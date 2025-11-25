shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.4;
uniform float softness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv * vec2(1.0, 0.5625)); // Adjust for aspect ratio
	float vignette = smoothstep(0.5, 0.5 - softness * 0.5, dist);
	COLOR = vec4(0.0, 0.0, 0.0, (1.0 - vignette) * intensity);
}
