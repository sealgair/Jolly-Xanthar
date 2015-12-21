extern vec4 fromColor[6];
extern vec4 toColor[6];

bool same_color( vec4 a, vec4 b ) {
    float tolerance = 1.0/255.0;
    for (int i = 0; i < 4; i++) {
        if (a[i] <= b[i] - tolerance || a[i] >= b[i] + tolerance) {
            return false;
        }
    }
    return true;
}

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ) {
    vec4 texcolor = Texel(texture, texture_coords);
    for (int i = 0; i < fromColor.length(); i++) {
        if (same_color(texcolor, fromColor[i])) {
            return toColor[i];
        }
    }
    return texcolor;
}