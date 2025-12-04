shader_type canvas_item;

uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	// Apply modulate (COLOR contains vertex color including sprite.modulate)
	vec4 modulated = tex_color * COLOR;
	// Mix between modulated color and flash color
	COLOR = mix(modulated, vec4(flash_color.rgb, modulated.a), flash_intensity);
}
