shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 tone = vec4(0.0, 0.0, 0.0, 0.0);
uniform sampler2D tiled_texture : filter_nearest, repeat_enable;
uniform vec2 background_size = vec2(1.0);
uniform sampler2D background_texture : hint_screen_texture, filter_nearest;

varying vec4 window_modulate;

void vertex() {
    window_modulate = COLOR;
}

void fragment() {
    vec2 pixel = floor(UV * background_size);
    if ((pixel.x == 0.0 || pixel.x == background_size.x - 1.0) && (pixel.y == 0.0 || pixel.y == background_size.y - 1.0)) discard;
    vec2 sample_position = max(pixel - vec2(1.0), vec2(0.0)) * 63.0 / max(background_size - vec2(2.0), vec2(1.0));
    ivec2 source_pixel = ivec2(floor(sample_position));
    vec2 fraction = floor(fract(sample_position) * 256.0) / 256.0;
    vec4 a = texelFetch(TEXTURE, clamp(source_pixel, ivec2(0), ivec2(63)), 0);
    vec4 b = texelFetch(TEXTURE, clamp(source_pixel + ivec2(1,0), ivec2(0), ivec2(63)), 0);
    vec4 c = texelFetch(TEXTURE, clamp(source_pixel + ivec2(0,1), ivec2(0), ivec2(63)), 0);
    vec4 d = texelFetch(TEXTURE, clamp(source_pixel + ivec2(1,1), ivec2(0), ivec2(63)), 0);
    vec4 col = floor(mix(mix(a,b,fraction.x),mix(c,d,fraction.x),fraction.y) * 255.0 + 0.0001) / 255.0;
    if (pixel.x < 1.0 || pixel.y < 1.0 || pixel.x >= background_size.x - 1.0 || pixel.y >= background_size.y - 1.0) col = vec4(0.0);
    vec2 tiled_uv = (floor(UV * background_size) - 0.5) / 64.0;
    vec4 tile = texture(tiled_texture, tiled_uv);
    ivec3 stretch_bytes = ivec3(round(col.rgb * 255.0));
    ivec3 tile_bytes = ivec3(round(tile.rgb * 255.0));
    int tile_alpha = int(round(tile.a * 255.0));
    col.rgb = vec3((stretch_bytes * (256 - tile_alpha) + tile_bytes * tile_alpha) / 256) / 255.0;

    vec3 bytes = round(col.rgb * 255.0);
    float luma = floor(dot(bytes, vec3(77.0, 150.0, 29.0)) / 256.0);
    float gray = tone.a > 0.0 ? (round(tone.a * 255.0) + 1.0) / 256.0 : 0.0;
    col.rgb = clamp(floor(mix(bytes, vec3(luma), gray)) + round(tone.rgb * 255.0), vec3(0.0), vec3(255.0)) / 255.0;

    COLOR = col * window_modulate;
    if (COLOR.a > 0.0 && COLOR.a < 1.0) {
        int alpha = int(floor(COLOR.a * 255.0)) + 1;
        ivec3 destination = ivec3(round(texture(background_texture, SCREEN_UV).rgb * 255.0));
        ivec3 source = ivec3(round(COLOR.rgb * 255.0));
        COLOR.rgb = vec3((source * alpha + destination * (256 - alpha)) / 256) / 255.0;
        COLOR.a = 1.0;
    }
}
