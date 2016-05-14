vec4 leg_color(number dist, vec4 color) {
    number b = color.a * 2;
    return vec4(color.rgb, max(0, b - 1) * dist);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 texturecolor = Texel(texture, texture_coords);
    texturecolor = texturecolor * color;
    texturecolor.a *= 2;
    int n = 6;
    for (int i = 1; i < n; i++) {
        number dist = number(n-i) / number(n);
        number x = i / love_ScreenSize.x;
        number y = i / love_ScreenSize.y;

        vec4 othercolor = Texel(texture, texture_coords + vec2(x, 0));
        texturecolor = max(leg_color(dist, othercolor), texturecolor);

        othercolor = Texel(texture, texture_coords + vec2(-x, 0));
        texturecolor = max(leg_color(dist, othercolor), texturecolor);

        dist *= .8;
        othercolor = Texel(texture, texture_coords + vec2(0, y));
        texturecolor = max(leg_color(dist, othercolor), texturecolor);

        othercolor = Texel(texture, texture_coords + vec2(0, -y));
        texturecolor = max(leg_color(dist, othercolor), texturecolor);
    }
    return texturecolor;
}