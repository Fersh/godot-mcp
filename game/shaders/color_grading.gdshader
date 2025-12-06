shader_type canvas_item;

// Color Grading - adjust the overall look and feel of the game
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

// Basic adjustments
uniform float brightness : hint_range(-0.5, 0.5) = 0.0;
uniform float contrast : hint_range(0.5, 2.0) = 1.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;

// Color temperature (negative = cool/blue, positive = warm/orange)
uniform float temperature : hint_range(-1.0, 1.0) = 0.0;

// Tint adjustments for shadows, midtones, highlights
uniform vec4 shadows_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 midtones_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 highlights_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Lift, Gamma, Gain (color wheels style)
uniform float shadows_strength : hint_range(0.0, 1.0) = 0.0;
uniform float midtones_strength : hint_range(0.0, 1.0) = 0.0;
uniform float highlights_strength : hint_range(0.0, 1.0) = 0.0;

// Vignette-style color fade at edges (optional atmospheric effect)
uniform float edge_darken : hint_range(0.0, 1.0) = 0.0;

vec3 apply_saturation(vec3 color, float sat) {
	float luminance = dot(color, vec3(0.299, 0.587, 0.114));
	return mix(vec3(luminance), color, sat);
}

vec3 apply_contrast(vec3 color, float con) {
	return (color - 0.5) * con + 0.5;
}

vec3 apply_temperature(vec3 color, float temp) {
	// Warm shifts toward orange, cool shifts toward blue
	color.r += temp * 0.1;
	color.b -= temp * 0.1;
	return color;
}

vec3 apply_tints(vec3 color) {
	float luminance = dot(color, vec3(0.299, 0.587, 0.114));

	// Define shadow/midtone/highlight regions with smooth transitions
	float shadow_weight = 1.0 - smoothstep(0.0, 0.33, luminance);
	float highlight_weight = smoothstep(0.66, 1.0, luminance);
	float midtone_weight = 1.0 - shadow_weight - highlight_weight;

	// Apply tints based on luminance region
	vec3 tinted = color;
	tinted = mix(tinted, tinted * shadows_tint.rgb, shadow_weight * shadows_strength);
	tinted = mix(tinted, tinted * midtones_tint.rgb, midtone_weight * midtones_strength);
	tinted = mix(tinted, tinted * highlights_tint.rgb, highlight_weight * highlights_strength);

	return tinted;
}

void fragment() {
	vec4 original = texture(screen_texture, SCREEN_UV);
	vec3 color = original.rgb;

	// Apply brightness
	color += brightness;

	// Apply contrast
	color = apply_contrast(color, contrast);

	// Apply saturation
	color = apply_saturation(color, saturation);

	// Apply temperature
	color = apply_temperature(color, temperature);

	// Apply shadow/midtone/highlight tints
	color = apply_tints(color);

	// Edge darkening (atmospheric)
	if (edge_darken > 0.0) {
		vec2 uv = SCREEN_UV - 0.5;
		float dist = length(uv);
		float darken = smoothstep(0.3, 0.8, dist) * edge_darken;
		color *= 1.0 - darken * 0.5;
	}

	// Clamp to valid range
	color = clamp(color, 0.0, 1.0);

	COLOR = vec4(color, original.a);
}
