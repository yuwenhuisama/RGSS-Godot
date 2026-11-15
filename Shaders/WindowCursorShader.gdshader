shader_type canvas_item;
render_mode blend_mix, unshaded;
uniform sampler2D background_texture : hint_screen_texture, filter_nearest;
uniform vec2 cursor_size = vec2(32.0);
varying vec4 cursor_modulate;
varying vec2 local_position;

vec4 accumulate(vec4 destination, vec4 source) {
    ivec4 previous = ivec4(round(destination));
    ivec4 incoming = ivec4(round(source * 255.0));
    if (previous.a == 0) return vec4(incoming);
    if (incoming.a == 0) return destination;
    int numerator = 255 * incoming.a + previous.a * (255 - incoming.a);
    int weight = 65025 * incoming.a / numerator + 1;
    return vec4(vec3((incoming.rgb * weight + previous.rgb * (256 - weight)) / 256), float(numerator / 255));
}

vec4 interpolate_bytes(vec4 first, vec4 second, float weight) {
    return floor(mix(first, second, weight));
}

float source_coordinate(float position, float size) {
    if (position < 4.0) return position;
    if (position >= size - 4.0) return position - size + 32.0;
    float step = floor(24.0 * 65536.0 / (size - 8.0));
    return 4.0 + (position - 4.0) * step / 65536.0;
}

void vertex() {
    cursor_modulate = COLOR;
    local_position = VERTEX;
}

void fragment() {
    vec2 position_pixel = floor(local_position);
    if (any(lessThan(position_pixel, vec2(0.0))) || any(greaterThanEqual(position_pixel, cursor_size))) discard;
    vec4 source;
    vec4 accumulated = vec4(0.0);
    if (cursor_size.x >= 8.0 && cursor_size.y >= 8.0) {
        vec2 pixel = vec2(source_coordinate(position_pixel.x, cursor_size.x), source_coordinate(position_pixel.y, cursor_size.y));
        if (all(greaterThanEqual(position_pixel, vec2(4.0))) && all(lessThan(position_pixel, cursor_size - 4.0))) {
            pixel = 4.0 + (position_pixel - 4.0) * floor(vec2(23.0) * 65536.0 / (cursor_size - 8.0)) / 65536.0;
            vec2 base = floor(pixel);
            vec2 weight = fract(pixel);
            vec4 top = interpolate_bytes(round(texture(TEXTURE, (base + 0.5) / 32.0) * 255.0), round(texture(TEXTURE, (base + vec2(1.5,0.5)) / 32.0) * 255.0), weight.x);
            vec4 bottom = interpolate_bytes(round(texture(TEXTURE, (base + vec2(0.5,1.5)) / 32.0) * 255.0), round(texture(TEXTURE, (base + 1.5) / 32.0) * 255.0), weight.x);
            source = interpolate_bytes(top,bottom,weight.y) / 255.0;
        } else {
            source = texture(TEXTURE, (floor(pixel) + 0.5) / 32.0);
        }
    } else {
        vec4 bytes = vec4(0.0);
        for (int row = 0; row < 3; row++) {
            for (int column = 0; column < 3; column++) {
                vec2 start = vec2(column == 0 ? 0.0 : column == 1 ? 4.0 : cursor_size.x - 4.0,
                    row == 0 ? 0.0 : row == 1 ? 4.0 : cursor_size.y - 4.0);
                vec2 extent = vec2(column == 1 ? cursor_size.x - 8.0 : 4.0, row == 1 ? cursor_size.y - 8.0 : 4.0);
                vec2 position = position_pixel - start;
                if (all(greaterThanEqual(position, vec2(0.0))) && all(lessThan(position, extent))) {
                    vec2 origin = vec2(column == 0 ? 0.0 : column == 1 ? 4.0 : 28.0, row == 0 ? 0.0 : row == 1 ? 4.0 : 28.0);
                    vec2 span = vec2(column == 1 ? 24.0 : 4.0, row == 1 ? 24.0 : 4.0);
                    vec2 step = floor(span * 65536.0 / extent);
                    bytes = accumulate(bytes, texture(TEXTURE, (origin + floor(position * step / 65536.0) + 0.5) / 32.0));
                }
            }
        }
        source = bytes / 255.0;
    }
    float alpha = round(source.a * cursor_modulate.a * 255.0);
    vec3 background = round(texture(background_texture, SCREEN_UV).rgb * 255.0);
    // RGSS processes pixel pairs and blends an odd-width tail with scalar weights.
    float tail = mod(cursor_size.x, 2.0) == 1.0 && position_pixel.x == cursor_size.x - 1.0 ? 1.0 : 0.0;
    vec3 bytes = floor((round(source.rgb * 255.0) * (alpha + 1.0) + background * (256.0 - alpha - tail)) / 256.0);
    COLOR = vec4(bytes / 255.0, 1.0);
}
