shader_type canvas_item;
render_mode blend_mix, unshaded;

instance uniform vec4 _PackedA = vec4(0.0, 72.0, 720.0, 1.0);
instance uniform vec4 _PackedB = vec4(0.0, 0.0, 0.0, 0.0);
instance uniform vec4 _PackedC = vec4(1.0, 1.0, 1.0, 0.0);
instance uniform vec4 _PackedD = vec4(1.0, 0.0, 0.0, 0.0);
instance uniform bool compose_background = true;

uniform vec4 mix_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float bush_depth = 1.0;
uniform vec2 texture_size = vec2(1.0, 1.0);
uniform sampler2D background_texture : hint_screen_texture, filter_nearest;

const vec3 LUMA = vec3(0.299, 0.587, 0.114);
const float RGSS_PI = 3.14159265358979323846;

vec2 wave_uv(vec2 uv) {
    float wave_amp = _PackedA.x;
    float wave_length = max(abs(_PackedA.y), 0.0001);
    float wave_speed = _PackedA.z;
    float wave_tex_width = max(texture_size.x, 1.0);
    float wave_tex_height = max(texture_size.y, 1.0);
    float wav = wave_amp / wave_tex_width;
    float band = floor(uv.y / (8.0 / wave_tex_height));
    float phase_angle = (TIME * 60.0 * wave_speed / wave_length) * RGSS_PI / 180.0;
    float length_angle = band * (8.0 / wave_tex_height) * 2.0 * RGSS_PI / (wave_length / wave_tex_height);
    float offset = wav * sin(length_angle + phase_angle);
    float in_wave_range = step(offset, uv.x) * step(uv.x, 1.0);
    return mix(vec2(-1.0, -1.0), vec2(uv.x - offset, uv.y), in_wave_range);
}

void fragment() {
    vec2 uv = UV;
    if (uv.x < 0.0 || uv.x >= 1.0 || uv.y < 0.0 || uv.y >= 1.0) {
        discard;
    }

    // Unity order: mirror -> wave -> gray -> tone -> opacity -> color -> bush -> flash.
    uv.x = mix(uv.x, 1.0 - uv.x, step(0.5, _PackedD.y));

    vec4 col = texture(TEXTURE, uv);
    float use_wave = clamp(_PackedA.x, 0.0, 1.0);
    vec2 waved_uv = wave_uv(uv);
    vec4 waved_col = waved_uv.x < 0.0 ? vec4(0.0) : texture(TEXTURE, waved_uv);
    col = mix(col, waved_col, use_wave);

    vec3 bytes = round(col.rgb * 255.0);
    float luma = floor(dot(bytes, vec3(77.0, 150.0, 29.0)) / 256.0);
    float gray_alpha = _PackedB.w > 0.0 ? (trunc(_PackedB.w * 255.0) + 1.0) / 256.0 : 0.0;
    col.rgb = floor(mix(bytes, vec3(luma), gray_alpha)) / 255.0;

    col.rgb += trunc(_PackedB.rgb * 255.0) / 255.0;
    col.a *= _PackedD.x;

    float color_alpha = mix_color.a > 0.0 ? (floor(mix_color.a * 255.0) + 1.0) / 256.0 : 0.0;
    col.rgb = floor(mix(round(col.rgb * 255.0), round(mix_color.rgb * 255.0), color_alpha)) / 255.0;

    float under_bush = step(bush_depth, uv.y);
    col.a *= mix(1.0, _PackedA.w, under_bush);

    float flash_alpha = _PackedC.w > 0.0 ? (floor(_PackedC.w * 255.0) + 1.0) / 256.0 : 0.0;
    col.rgb = floor(mix(round(col.rgb * 255.0), round(_PackedC.rgb * 255.0), flash_alpha)) / 255.0;
    if (compose_background && col.a > 0.0 && col.a < 1.0) {
        vec4 background = texture(background_texture, SCREEN_UV);
        float alpha = (floor(col.a * 255.0) + 1.0) / 256.0;
        float result_alpha = alpha + background.a * (1.0 - alpha);
        col.rgb = floor(((col.rgb * alpha + background.rgb * (1.0 - alpha)) / result_alpha) * 255.0) / 255.0;
        col.a = result_alpha;
    }
    COLOR = col;
}
