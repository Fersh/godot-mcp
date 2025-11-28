shader_type canvas_item;

// Rarity particle effect - fire-like particles rising upward
uniform vec4 rarity_color : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform float intensity : hint_range(0.0, 3.0) = 1.0;
uniform float speed : hint_range(0.1, 5.0) = 1.5;
uniform float particle_density : hint_range(1.0, 30.0) = 12.0;

// Pseudo-random function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Noise function for organic movement
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = UV;

    // Time-based animation
    float t = TIME * speed;

    // Create multiple fire particles rising up
    float particles = 0.0;

    for (float i = 0.0; i < particle_density; i++) {
        // Each particle has different x position and timing
        float seed = i / particle_density;
        float x_base = random(vec2(seed, 0.0));
        float phase = random(vec2(seed, 1.0)) * 6.28;
        float speed_var = 0.4 + random(vec2(seed, 2.0)) * 0.6;

        // Particle rises over time (0 at bottom, 1 at top), wrapping
        float particle_y = fract(t * speed_var + seed);

        // Particle x position with fire-like wobble that increases as it rises
        float wobble = sin(t * 3.0 + phase + particle_y * 5.0) * (0.05 + particle_y * 0.1);
        float px = x_base + wobble;

        // Distance from this particle
        float dx = abs(uv.x - px);

        // Particle visible when UV.y is near the particle's current height
        // Particles start at bottom (uv.y = 1) and rise to top (uv.y = 0)
        float py = 1.0 - particle_y;  // Convert to screen space (0=top, 1=bottom)
        float dy = abs(uv.y - py);

        // Particle fades in at bottom, fades out at top
        float fade_in = smoothstep(0.0, 0.15, particle_y);
        float fade_out = smoothstep(1.0, 0.6, particle_y);
        float fade = fade_in * fade_out;

        // Particle size - larger at bottom, smaller as it rises
        float base_size = 0.08 * (1.0 - particle_y * 0.6);
        float size_x = base_size * 1.5;
        float size_y = base_size * 2.0;

        // Elliptical particle shape
        float dist = sqrt((dx * dx) / (size_x * size_x) + (dy * dy) / (size_y * size_y));
        float particle = smoothstep(1.0, 0.3, dist) * fade;

        // Add flickering
        particle *= 0.7 + 0.3 * noise(vec2(seed * 10.0, t * 2.0));

        particles += particle;
    }

    // Apply intensity
    particles = clamp(particles * intensity, 0.0, 1.0);

    // Fire color gradient - brighter/whiter in center
    vec3 color = rarity_color.rgb;
    vec3 bright_color = mix(color, vec3(1.0), 0.5);
    color = mix(color, bright_color, particles * 0.4);

    // Add glow effect
    float glow = particles * 0.3;

    // Output with alpha
    COLOR = vec4(color, particles * rarity_color.a);
}
