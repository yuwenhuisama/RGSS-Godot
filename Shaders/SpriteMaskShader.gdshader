shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);

void fragment() {
    vec4 mask_region = region;
    mask_region.y = 1.0 - mask_region.y - mask_region.w;
    vec2 mask = step(mask_region.xy, UV) * step(UV, mask_region.xy + mask_region.zw);
    vec4 col = texture(TEXTURE, UV);
    col *= mask.x * mask.y;
    COLOR = col;
}
