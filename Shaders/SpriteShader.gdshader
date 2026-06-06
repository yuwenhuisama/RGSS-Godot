shader_type canvas_item;
render_mode blend_mix, unshaded;

instance uniform vec4 _PackedA = vec4(0.0, 72.0, 720.0, 1.0);
instance uniform vec4 _PackedB = vec4(0.0, 0.0, 0.0, 0.0);
instance uniform vec4 _PackedC = vec4(1.0, 1.0, 1.0, 0.0);
instance uniform vec4 _PackedD = vec4(1.0, 0.0, 0.0, 0.0);

uniform vec4 mix_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float bush_depth = 0.0;
uniform vec2 texture_size = vec2(1.0, 1.0);

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

    // Unity order: mirror -> wave -> gray -> tone -> opacity -> color -> bush -> flash.
    uv.x = mix(uv.x, 1.0 - uv.x, step(0.5, _PackedD.y));

    vec4 col = texture(TEXTURE, uv);
    float use_wave = clamp(_PackedA.x, 0.0, 1.0);
    vec2 waved_uv = wave_uv(uv);
    vec4 waved_col = waved_uv.x < 0.0 ? vec4(0.0) : texture(TEXTURE, waved_uv);
    col = mix(col, waved_col, use_wave);

    float luma = dot(col.rgb, LUMA);
    col.rgb = mix(col.rgb, vec3(luma), _PackedB.w);

    col.rgb += _PackedB.rgb;
    col.a *= _PackedD.x;

    col.rgb = mix(col.rgb, mix_color.rgb, mix_color.a);

    float under_bush = step(uv.y, bush_depth);
    col.a *= mix(1.0, _PackedA.w, under_bush);

    col.rgba = mix(col.rgba, _PackedC.rgba, _PackedC.w);
    COLOR = col;
}
