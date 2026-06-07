shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D frozen_tex : filter_linear_mipmap;
uniform sampler2D new_tex : filter_linear_mipmap;
uniform sampler2D transition_tex : filter_linear_mipmap;
uniform float vague = 0.0001;
uniform float progress = 0.0;

void fragment() {
    // The frozen/new/mask textures are full-screen captures (544x416). Sample them in
    // SCREEN space, exactly like GraphicsPostprocessShader samples SCREEN_TEXTURE with
    // SCREEN_UV. Using the ColorRect's local UV instead samples only part of the texture
    // under the project's "viewport" stretch mode (window override is 2x the viewport),
    // which made only the top-left quarter of the mask participate.
    vec2 uv = SCREEN_UV;

    float safe_vague = max(vague, 0.0001);
    float trans_v = texture(transition_tex, uv).r;
    float c_trans_v = clamp(trans_v, progress, progress + safe_vague);
    float alpha = (c_trans_v - progress) / safe_vague;

    vec4 new_frag = texture(new_tex, uv);
    vec4 old_frag = texture(frozen_tex, uv);
    COLOR = mix(new_frag, old_frag, alpha);
}
