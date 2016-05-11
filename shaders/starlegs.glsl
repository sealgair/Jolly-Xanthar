vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 texturecolor = Texel(texture, texture_coords);
    texturecolor = texturecolor * color;
    int n = 5;
    for (int i = 1; i <= n; i++) {
        number x = i / love_ScreenSize.x;
        number y = i / love_ScreenSize.y;

        vec4 othercolor = Texel(texture, texture_coords + vec2(x, 0));
        othercolor.a *= (number(n-i)/number(n)) - .1;
        texturecolor += othercolor;

        othercolor = Texel(texture, texture_coords + vec2(-x, 0));
        othercolor.a *= (number(n-i)/number(n)) - .1;
        texturecolor += othercolor;

        othercolor = Texel(texture, texture_coords + vec2(0, y));
        othercolor.a *= (number(n-i)/number(n)) - .1;
        texturecolor += othercolor;

        othercolor = Texel(texture, texture_coords + vec2(0, -y));
        othercolor.a *= (number(n-i)/number(n)) - .1;
        texturecolor += othercolor;
    }
    return texturecolor;
}