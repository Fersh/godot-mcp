shader_type canvas_item;

uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	// Only modify rendering when flash is active
	// This preserves the exact default sprite rendering when flash_intensity is 0
	if (flash_intensity > 0.001) {
		vec4 tex_color = texture(TEXTURE, UV);
		// Apply modulate (COLOR contains vertex color including sprite.modulate)
		vec4 modulated = tex_color * COLOR;
		// Mix between modulated color and flash color
		COLOR = mix(modulated, vec4(flash_color.rgb, modulated.a), flash_intensity);
	}
	// When flash_intensity is ~0, don't modify COLOR - use Godot's default rendering
}
