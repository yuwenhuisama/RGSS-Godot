shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 mix_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 tone = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec2 tile_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);
uniform vec2 scroll_speed = vec2(0.0, 0.0);

const vec3 LUMA = vec3(0.299, 0.587, 0.114);

void fragment() {
    vec2 uv = UV * tile_scale;
    uv.y -= tile_scale.y - 1.0;
    uv += vec2(uv_offset.x, -uv_offset.y) + (scroll_speed * TIME);
    uv = fract(uv);

    vec4 col = texture(TEXTURE, uv);

    float luma = dot(col.rgb, LUMA);
    col.rgb = mix(col.rgb, vec3(luma), tone.a);
    col.rgb += tone.rgb;
    col.rgb = mix(col.rgb, mix_color.rgb, mix_color.a);

    COLOR = col;
}
