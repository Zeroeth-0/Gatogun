shader_type canvas_item;

uniform float hit_effect      : hint_range(0, 1)  = 0.0;
uniform float shake_intensity                      = 10.0;
uniform float flash_speed                          = 30.0;
uniform float time_offset                          = 0.0;
uniform vec4  flash_color : source_color           = vec4(0.3, 0.7, 1.0, 1.0);

// === TIEMPO ===
uniform float custom_time : hint_range(0.0, 1000.0) = 0.0;

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
    if (hit_effect > 0.0) {
        float t      = custom_time * 30.0 + time_offset;
        vec2  rnd    = vec2(rand(vec2(t, 0.0)) * 2.0 - 1.0,
                            rand(vec2(t, 10.0)) * 2.0 - 1.0);
        VERTEX += rnd * shake_intensity * hit_effect;
    }
}

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    if (hit_effect > 0.0) {
        float flash = sin((custom_time + time_offset) * flash_speed) * 0.5 + 0.5;
        flash *= original_color.a;
        vec4 final_color = mix(original_color, flash_color, flash);
        final_color      = mix(original_color, final_color, hit_effect);
        final_color.a    = original_color.a;
        COLOR = final_color;
    } else {
        COLOR = original_color;
    }
}