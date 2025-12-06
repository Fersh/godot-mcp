shader_type canvas_item;

// Film Grain - adds subtle noise texture for atmosphere
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float intensity : hint_range(0.0, 0.5) = 0.05;
uniform float speed : hint_range(0.0, 10.0) = 5.0;
uniform bool colored = false; // Colored grain vs monochrome

// Fast noise function
float random(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 original = texture(screen_texture, SCREEN_UV);

	// Animate noise with time
	vec2 noise_uv = SCREEN_UV * 500.0 + TIME * speed;
	float noise = random(noise_uv) * 2.0 - 1.0; // Range -1 to 1

	vec3 grain;
	if (colored) {
		// RGB grain (each channel has different noise)
		grain = vec3(
			random(noise_uv + vec2(0.0, 0.0)),
			random(noise_uv + vec2(1.0, 0.0)),
			random(noise_uv + vec2(0.0, 1.0))
		) * 2.0 - 1.0;
	} else {
		// Monochrome grain
		grain = vec3(noise);
	}

	// Apply grain - reduce effect in dark areas to avoid crushing blacks
	float luminance = dot(original.rgb, vec3(0.299, 0.587, 0.114));
	float grain_amount = intensity * (0.5 + luminance * 0.5);

	vec3 result = original.rgb + grain * grain_amount;

	COLOR = vec4(clamp(result, 0.0, 1.0), original.a);
}
