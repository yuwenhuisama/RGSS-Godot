shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 tone = vec4(0.0);
uniform vec4 mix_color = vec4(0.0);
uniform vec4 flash_color = vec4(0.0);
uniform float flash_progress = 0.0;
uniform sampler2D background_texture : hint_screen_texture, filter_nearest;

void fragment() {
    vec4 background = texture(background_texture, SCREEN_UV);
    vec3 bytes = round(background.rgb * 255.0);
    float luma = floor(dot(bytes, vec3(77.0, 150.0, 29.0)) / 256.0);
    float gray_alpha = tone.a > 0.0 ? (round(tone.a * 255.0) + 1.0) / 256.0 : 0.0;
    bytes = clamp(floor(mix(bytes, vec3(luma), gray_alpha)) + round(tone.rgb * 255.0), vec3(0.0), vec3(255.0));
    float color_alpha = mix_color.a > 0.0 ? (floor(mix_color.a * 255.0) + 1.0) / 256.0 : 0.0;
    bytes = floor(mix(bytes, round(mix_color.rgb * 255.0), color_alpha));
    float flash_alpha = flash_color.a * flash_progress;
    flash_alpha = flash_alpha > 0.0 ? (floor(flash_alpha * 255.0) + 1.0) / 256.0 : 0.0;
    bytes = floor(mix(bytes, round(flash_color.rgb * 255.0), flash_alpha));
    COLOR = vec4(bytes / 255.0, 1.0);
}
