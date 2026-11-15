shader_type canvas_item;
render_mode blend_mix, unshaded;
uniform sampler2D background_texture : hint_screen_texture, filter_nearest;
varying float pause_alpha;

void vertex() {
    pause_alpha = COLOR.a;
}

void fragment() {
    vec4 source = texture(TEXTURE, UV);
    float alpha = pause_alpha * source.a;
    if (alpha <= 0.0) {
        discard;
    }
    vec3 source_bytes = round(source.rgb * 255.0);
    vec3 destination = round(texture(background_texture, SCREEN_UV).rgb * 255.0);
    float alpha_byte = floor(alpha * 255.0);
    COLOR = vec4(floor((source_bytes * (alpha_byte + 1.0) + destination * (256.0 - alpha_byte)) / 256.0) / 255.0, 1.0);
}
