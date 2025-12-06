shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 2.0) = 0.5;
uniform float threshold : hint_range(0.0, 1.0) = 0.6;
uniform float blur_size : hint_range(1.0, 10.0) = 3.0;

void fragment() {
	vec2 pixel_size = 1.0 / vec2(textureSize(screen_texture, 0));
	vec4 original = texture(screen_texture, SCREEN_UV);

	// Simple 9-tap blur for bloom
	vec4 blur = vec4(0.0);
	float total_weight = 0.0;

	for (float x = -2.0; x <= 2.0; x += 1.0) {
		for (float y = -2.0; y <= 2.0; y += 1.0) {
			vec2 offset = vec2(x, y) * pixel_size * blur_size;
			vec4 sample_color = texture(screen_texture, SCREEN_UV + offset);

			// Extract bright parts
			float brightness = max(sample_color.r, max(sample_color.g, sample_color.b));
			float contribution = max(0.0, brightness - threshold);

			// Gaussian-like weight
			float weight = exp(-(x*x + y*y) / 4.0);
			blur += sample_color * contribution * weight;
			total_weight += weight;
		}
	}

	blur /= total_weight;

	// Additive blend
	COLOR = original + blur * intensity;
	COLOR.a = 1.0;
}
