shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D frozen_tex : filter_linear_mipmap;
uniform sampler2D transition_tex : filter_linear_mipmap;
uniform float vague = 0.0;
uniform float progress = 0.0;

void fragment() {
    vec2 uv = SCREEN_UV;

    float trans_v = texture(transition_tex, uv).r;
    float c_trans_v = clamp(trans_v, progress, progress + vague);
    float alpha = (c_trans_v - progress) / vague;

    vec4 new_frag = textureLod(SCREEN_TEXTURE, uv, 0.0);
    vec4 old_frag = texture(frozen_tex, uv);
    COLOR = mix(new_frag, old_frag, alpha);
}
