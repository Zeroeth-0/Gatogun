shader_type canvas_item;

uniform vec2 shadow_offset = vec2(10.0, 10.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.8);

void fragment() {
    vec2 shadow_uv = UV - shadow_offset / vec2(textureSize(TEXTURE, 0));
    vec4 shadow = texture(TEXTURE, shadow_uv) * shadow_color;
    vec4 original = texture(TEXTURE, UV);
    COLOR = mix(shadow, original, original.a);
}