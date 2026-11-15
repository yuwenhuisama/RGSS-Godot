shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec2 window_size = vec2(1.0);
uniform sampler2D background_texture : hint_screen_texture, filter_nearest;
varying vec2 local_position;
varying vec4 vertex_color;

vec4 blend_corner(vec4 destination, vec4 source) {
    float alpha = round(source.a * 255.0);
    vec3 rgb = floor(destination.rgb * (255.0 - alpha) / 255.0) + floor(round(source.rgb * 255.0) * alpha / 255.0);
    return vec4(rgb, alpha + floor(destination.a * (255.0 - alpha) / 255.0));
}

void vertex() {
    local_position = VERTEX - vec2(0.5);
    vertex_color = COLOR;
}

void fragment() {
    if (any(lessThan(local_position, vec2(0.0))) || any(greaterThanEqual(local_position, window_size))) {
        discard;
    }
    if (window_size.x < 32.0 || window_size.y < 32.0) {
        vec4 bytes = vec4(0.0);
        vec2 right = local_position - vec2(window_size.x - 16.0, 0.0);
        vec2 bottom = local_position - vec2(0.0, window_size.y - 16.0);
        vec2 bottom_right = local_position - (window_size - vec2(16.0));
        if (window_size.x > 32.0 && local_position.x >= 16.0 && local_position.x < window_size.x - 16.0) {
            float x = 16.5 + mod(local_position.x - 16.0, 32.0);
            if (local_position.y < 16.0)
                bytes = blend_corner(bytes, texture(TEXTURE, vec2(x, local_position.y + 0.5) / 64.0));
            if (bottom.y >= 0.0 && bottom.y < 16.0)
                bytes = blend_corner(bytes, texture(TEXTURE, vec2(x, bottom.y + 48.5) / 64.0));
        }
        if (window_size.y > 32.0 && local_position.y >= 16.0 && local_position.y < window_size.y - 16.0) {
            float y = 16.5 + mod(local_position.y - 16.0, 32.0);
            if (local_position.x < 16.0)
                bytes = blend_corner(bytes, texture(TEXTURE, vec2(local_position.x + 0.5, y) / 64.0));
            if (right.x >= 0.0 && right.x < 16.0)
                bytes = blend_corner(bytes, texture(TEXTURE, vec2(right.x + 48.5, y) / 64.0));
        }
        if (local_position.x < 16.0 && local_position.y < 16.0)
            bytes = blend_corner(bytes, texture(TEXTURE, (local_position + 0.5) / 64.0));
        if (right.x >= 0.0 && right.x < 16.0 && right.y < 16.0)
            bytes = blend_corner(bytes, texture(TEXTURE, (right + vec2(48.5, 0.5)) / 64.0));
        if (bottom.x < 16.0 && bottom.y >= 0.0 && bottom.y < 16.0)
            bytes = blend_corner(bytes, texture(TEXTURE, (bottom + vec2(0.5, 48.5)) / 64.0));
        if (all(greaterThanEqual(bottom_right, vec2(0.0))) && all(lessThan(bottom_right, vec2(16.0))))
            bytes = blend_corner(bytes, texture(TEXTURE, (bottom_right + 48.5) / 64.0));
        vec3 background = round(texture(background_texture, SCREEN_UV).rgb * 255.0);
        COLOR = vec4(round(bytes.rgb * vertex_color.a + background * (1.0 - bytes.a / 255.0 * vertex_color.a)) / 255.0, 1.0);
    } else {
        vec2 pixel_position = floor(local_position + vec2(0.5));
        if (pixel_position.x >= 16.0 && pixel_position.x < window_size.x - 16.0 && pixel_position.y >= 16.0 && pixel_position.y < window_size.y - 16.0) {
            discard;
        }
        vec2 source_pixel = pixel_position;
        source_pixel.x = pixel_position.x < 16.0 ? pixel_position.x : pixel_position.x >= window_size.x - 16.0 ? pixel_position.x - window_size.x + 64.0 : 16.0 + mod(pixel_position.x - 16.0, 32.0);
        source_pixel.y = pixel_position.y < 16.0 ? pixel_position.y : pixel_position.y >= window_size.y - 16.0 ? pixel_position.y - window_size.y + 64.0 : 16.0 + mod(pixel_position.y - 16.0, 32.0);
        vec4 source = texelFetch(TEXTURE, ivec2(source_pixel), 0);
        float alpha = floor(source.a * vertex_color.a * 255.0);
        vec3 background = round(texture(background_texture, SCREEN_UV).rgb * 255.0);
        vec3 bytes = floor((round(source.rgb * 255.0) * (alpha + 1.0) + background * (256.0 - alpha)) / 256.0);
        COLOR = alpha > 0.0 ? vec4(bytes / 255.0, 1.0) : vec4(0.0);
    }
}
