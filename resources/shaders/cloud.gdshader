shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable, filter_nearest;
uniform vec4 fog_color : source_color = vec4(0.9, 0.7, 0.3, 1.0);

// Fog density
uniform float density : hint_range(0.0, 1.0) = 0.25;
// Fog speed
uniform vec2 speed = vec2(0.02, 0.01);

// Pixelation strength (smaller = chunkier)
uniform float pixel_size : hint_range(1.0, 512.0) = 64.0;

void fragment() {
    // UVs that move with time
    vec2 uv = UV + speed * TIME;

    // Quantize UVs (pixelation in texture space)
    vec2 pixelated_uv = floor(uv * pixel_size) / pixel_size;

    // Sample noise
    float noise = texture(noise_texture, pixelated_uv).r;

    // Convert noise → fog
    float fog = clamp(noise * 2.0 - 1.0, 0.0, 1.0);

    // Apply fog color and density
    COLOR = vec4(fog_color.rgb, fog * density * fog_color.a);
}
