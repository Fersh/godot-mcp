shader_type canvas_item;

// Desaturation effect - for pause screens, death, slow-motion, etc.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float amount : hint_range(0.0, 1.0) = 0.0; // 0 = full color, 1 = grayscale
uniform float darken : hint_range(0.0, 1.0) = 0.0; // Optional darkening

void fragment() {
	vec4 original = texture(screen_texture, SCREEN_UV);

	// Calculate luminance (grayscale)
	float luminance = dot(original.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grayscale = vec3(luminance);

	// Mix between color and grayscale
	vec3 result = mix(original.rgb, grayscale, amount);

	// Apply optional darkening
	result *= 1.0 - darken * 0.5;

	COLOR = vec4(result, original.a);
}
