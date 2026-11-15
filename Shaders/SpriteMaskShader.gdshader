shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);
uniform sampler2D background_texture : hint_screen_texture, filter_nearest;
varying vec4 contents_modulate;

void vertex() {
    contents_modulate = COLOR;
}

void fragment() {
    vec4 mask_region = region;
    vec2 mask = step(mask_region.xy, UV) * (vec2(1.0) - step(mask_region.xy + mask_region.zw, UV));
    vec4 col = texture(TEXTURE, UV);
    col *= mask.x * mask.y;
    col *= contents_modulate;
    if (col.a > 0.0 && col.a < 1.0) {
        vec4 background = texture(background_texture, SCREEN_UV);
        float alpha_byte = round(col.a * 255.0) + 1.0;
        float result_alpha = alpha_byte + round(background.a * 255.0) * (256.0 - alpha_byte) / 255.0;
        col.rgb = floor((round(col.rgb * 255.0) * alpha_byte + round(background.rgb * 255.0) * (257.0 - alpha_byte)) / result_alpha) / 255.0;
        col.a = result_alpha / 256.0;
    }
    COLOR = col;
}
