shader_type canvas_item;

// Rarity particle effect - pixelated square fire particles rising upward
uniform vec4 rarity_color : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform float intensity : hint_range(0.0, 3.0) = 1.0;
uniform float speed : hint_range(0.1, 5.0) = 1.5;
uniform float particle_density : hint_range(1.0, 30.0) = 12.0;
uniform float pixel_size : hint_range(0.01, 0.15) = 0.06;

// Pseudo-random function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;

    // Time-based animation
    float t = TIME * speed;

    // Create multiple pixelated fire particles rising up
    float particles = 0.0;

    for (float i = 0.0; i < particle_density; i++) {
        // Each particle has different x position and timing
        float seed = i / particle_density;
        float x_base = random(vec2(seed, 0.0));
        float phase = random(vec2(seed, 1.0)) * 6.28;
        float speed_var = 0.5 + random(vec2(seed, 2.0)) * 0.5;

        // Particle rises over time (0 at bottom, 1 at top), wrapping
        float particle_y = fract(t * speed_var + seed);

        // Particle x position with slight wobble
        float wobble = sin(t * 2.0 + phase) * 0.03;
        float px = x_base + wobble;

        // Particle visible when UV.y is near the particle's current height
        // Particles start at bottom (uv.y = 1) and rise to top (uv.y = 0)
        float py = 1.0 - particle_y;

        // Particle fades in at bottom, fades out at top
        float fade_in = smoothstep(0.0, 0.2, particle_y);
        float fade_out = smoothstep(1.0, 0.5, particle_y);
        float fade = fade_in * fade_out;

        // Pixel size varies - larger at bottom, smaller as it rises
        float current_pixel_size = pixel_size * (1.2 - particle_y * 0.5);

        // Square/pixelated particle shape using step function
        float dx = abs(uv.x - px);
        float dy = abs(uv.y - py);

        // Create hard-edged square particle
        float in_x = step(dx, current_pixel_size);
        float in_y = step(dy, current_pixel_size * 1.2);  // Slightly taller
        float particle = in_x * in_y * fade;

        // Add flickering by randomly hiding some particles
        float flicker = step(0.3, random(vec2(seed * 10.0, floor(t * 8.0))));
        particle *= flicker;

        particles += particle;
    }

    // Apply intensity
    particles = clamp(particles * intensity, 0.0, 1.0);

    // Fire color - use rarity color directly for pixelated look
    vec3 color = rarity_color.rgb;

    // Brighten center particles slightly
    color = mix(color, vec3(1.0), particles * 0.2);

    // Output with alpha
    COLOR = vec4(color, particles * rarity_color.a);
}
