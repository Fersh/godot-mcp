shader_type canvas_item;

uniform float intensity : hint_range(0.0, 0.1) = 0.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 offset = (uv - 0.5) * intensity;

	float r = texture(screen_texture, uv + offset).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv - offset).b;

	COLOR = vec4(r, g, b, 1.0);
}
