shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 tone = vec4(0.0, 0.0, 0.0, 0.0);

const vec3 LUMA = vec3(0.299, 0.587, 0.114);

void fragment() {
    vec4 col = texture(TEXTURE, UV);

    float luma = dot(col.rgb, LUMA);
    col.rgb = mix(col.rgb, vec3(luma), tone.a);
    col.rgb += tone.rgb;

    COLOR = col;
}
