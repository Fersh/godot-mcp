shader_type canvas_item;

// Outline shader for sprites - adds a colored border around non-transparent pixels
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 1.0;
uniform bool outline_only = false; // If true, only show outline (useful for silhouettes)

void fragment() {
	vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
	vec4 sprite_color = texture(TEXTURE, UV);

	// Sample surrounding pixels
	float alpha_sum = 0.0;

	// 8-direction sampling for smooth outline
	alpha_sum += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
	alpha_sum += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
	alpha_sum += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
	alpha_sum += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
	alpha_sum += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
	alpha_sum += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
	alpha_sum += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
	alpha_sum += texture(TEXTURE, UV + vec2(size.x, size.y)).a;

	// If any neighbor has alpha but current pixel doesn't, it's an edge
	float outline = min(alpha_sum, 1.0) * (1.0 - sprite_color.a);

	if (outline_only) {
		// Only show the outline
		COLOR = vec4(outline_color.rgb, outline * outline_color.a);
	} else {
		// Show sprite with outline behind it
		vec4 final_color = mix(vec4(outline_color.rgb, outline * outline_color.a), sprite_color, sprite_color.a);
		COLOR = final_color;
	}
}
