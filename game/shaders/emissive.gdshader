shader_type canvas_item;

// Makes sprites emit light for bloom effect
// Apply to any sprite you want to glow

uniform float emission_strength : hint_range(0.0, 5.0) = 1.5;
uniform vec4 emission_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	// Boost color into HDR range for bloom
	vec3 emissive = tex_color.rgb * emission_strength * emission_tint.rgb;

	COLOR = vec4(emissive, tex_color.a);
}
