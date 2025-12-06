shader_type canvas_item;

// CRT / Scanlines effect - retro arcade look
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

// Scanlines
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_frequency : hint_range(100.0, 1000.0) = 400.0;

// Screen curvature (barrel distortion)
uniform float curvature : hint_range(0.0, 0.1) = 0.0;

// RGB separation (chromatic aberration at edges)
uniform float rgb_offset : hint_range(0.0, 0.01) = 0.0;

// Brightness boost to compensate for scanlines
uniform float brightness_boost : hint_range(1.0, 1.5) = 1.1;

// Vignette for CRT edge darkening
uniform float crt_vignette : hint_range(0.0, 1.0) = 0.0;

vec2 curve(vec2 uv) {
	uv = uv * 2.0 - 1.0;
	vec2 offset = abs(uv.yx) / vec2(6.0, 4.0);
	uv = uv + uv * offset * offset * curvature;
	uv = uv * 0.5 + 0.5;
	return uv;
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// Apply curvature
	if (curvature > 0.0) {
		uv = curve(uv);
	}

	// Check if outside screen (for curvature)
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		return;
	}

	vec3 color;

	// RGB separation at edges
	if (rgb_offset > 0.0) {
		vec2 center_dist = uv - 0.5;
		float dist = length(center_dist);
		vec2 dir = normalize(center_dist) * rgb_offset * dist;

		color.r = texture(screen_texture, uv + dir).r;
		color.g = texture(screen_texture, uv).g;
		color.b = texture(screen_texture, uv - dir).b;
	} else {
		color = texture(screen_texture, uv).rgb;
	}

	// Scanlines
	if (scanline_intensity > 0.0) {
		float scanline = sin(uv.y * scanline_frequency * 3.14159) * 0.5 + 0.5;
		scanline = pow(scanline, 1.5); // Sharper scanlines
		color *= 1.0 - scanline_intensity * (1.0 - scanline);
	}

	// Brightness boost
	color *= brightness_boost;

	// CRT vignette (edge darkening)
	if (crt_vignette > 0.0) {
		vec2 vig_uv = uv * (1.0 - uv.yx);
		float vig = vig_uv.x * vig_uv.y * 15.0;
		vig = pow(vig, crt_vignette * 0.5);
		color *= vig;
	}

	COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}
