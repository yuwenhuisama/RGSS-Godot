shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 mix_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 tone = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec2 tile_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);
uniform vec2 scroll_speed = vec2(0.0, 0.0);
uniform vec2 viewport_size = vec2(1.0);
uniform vec2 bitmap_size = vec2(1.0);
uniform vec2 zoom = vec2(1.0);
uniform vec2 scroll = vec2(0.0);
uniform float opacity = 1.0;
uniform int blend_type = 0;
uniform sampler2D background_texture : hint_screen_texture, filter_nearest;

const vec3 LUMA = vec3(0.299, 0.587, 0.114);

void fragment() {
    vec2 period = floor(bitmap_size * zoom);
    vec2 position = mod(floor(UV * viewport_size) + scroll, period);
    vec2 inverse_zoom = floor(bitmap_size / period * 65536.0) / 65536.0;
    vec2 source_pixel = floor(position * inverse_zoom);
    vec2 uv = (source_pixel + 0.5) / bitmap_size;

    vec4 col = texture(TEXTURE, uv);

    vec3 bytes = round(col.rgb * 255.0);
    float luma = floor(dot(bytes, vec3(77.0, 150.0, 29.0)) / 256.0);
    float gray_alpha = tone.a > 0.0 ? (round(tone.a * 255.0) + 1.0) / 256.0 : 0.0;
    bytes = clamp(floor(mix(bytes, vec3(luma), gray_alpha)) + round(tone.rgb * 255.0), vec3(0.0), vec3(255.0));
    float color_alpha = mix_color.a > 0.0 ? (floor(mix_color.a * 255.0) + 1.0) / 256.0 : 0.0;
    col.rgb = floor(mix(bytes, round(mix_color.rgb * 255.0), color_alpha)) / 255.0;
    col.a *= opacity;
    if (blend_type == 0 && col.a > 0.0 && col.a < 1.0) {
        vec3 background = texture(background_texture, SCREEN_UV).rgb;
        float alpha = (floor(col.a * 255.0) + 1.0) / 256.0;
        col.rgb = floor(mix(background, col.rgb, alpha) * 255.0) / 255.0;
        col.a = 1.0;
    }
    if (blend_type == 2) {
        col = vec4(max(texture(background_texture, SCREEN_UV).rgb - col.rgb * col.a, vec3(0.0)), 1.0);
    }
    COLOR = col;
}
