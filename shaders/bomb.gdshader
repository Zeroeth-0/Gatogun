shader_type canvas_item;
render_mode blend_add;

uniform float custom_time = 0.0; // ← Driven by CUSTIME

uniform vec4 star_color : source_color = vec4(0.30, 1.00, 0.72, 1.0);
uniform float star_count : hint_range(1.0, 20.0) = 5.0;
uniform vec2 spacing = vec2(0.8, 0.8); 
uniform float vertical_pos : hint_range(0.0, 1.0) = 0.5;
uniform float global_opacity : hint_range(0.0, 1.0) = 1.0;

uniform int trail_samples : hint_range(1, 15) = 6;
uniform float trail_delay : hint_range(0.0, 0.5) = 0.1;
uniform float trail_offset_v : hint_range(0.0, 0.5) = 0.1;
uniform float trail_decay : hint_range(0.1, 2.0) = 0.8;

uniform float star_radius : hint_range(0.05, 0.45) = 0.22;
uniform float star_inner  : hint_range(1.2, 4.0)   = 2.5;
uniform float spin_speed  : hint_range(0.0, 10.0)  = 4.0;
uniform float pulse_speed : hint_range(0.0, 8.0)   = 2.4;

float sdf_star(vec2 p, float r, float n, float m) {
    float an = PI / n;
    float en = PI / m;
    vec2 acs = vec2(cos(an), sin(an));
    vec2 ecs = vec2(cos(en), sin(en));
    float bn = mod(atan(p.y, p.x), 2.0 * an) - an;
    p = length(p) * vec2(cos(bn), abs(sin(bn)));
    p -= r * acs;
    p += ecs * clamp(-dot(p, ecs), 0.0, r * acs.y / ecs.y);
    return length(p) * sign(p.x);
}

float hash12(vec2 p) {
    p = fract(p * vec2(0.1031, 0.1030));
    p += dot(p, p + 33.33);
    return fract(p.x * p.y);
}

void fragment() {
    float x_coord = UV.x * star_count;
    vec3 final_rgb = vec3(0.0);
    float final_alpha = 0.0;
    float aa = 0.01;

    for (int x = -1; x <= 1; x++) {
        float node_x = floor(x_coord) + float(x);
        vec2 node = vec2(node_x, 0.0);
        float h = hash12(node);
        
        for (int i = 0; i < trail_samples; i++) {
            float fi = float(i);
            float falloff = pow(1.0 - (fi / float(trail_samples)), trail_decay);
            float y_off = fi * trail_offset_v;

            vec2 p = vec2(
                fract(x_coord) - float(x) - 0.5, 
                (UV.y - vertical_pos + y_off) * star_count
            ) / spacing;

            float t = custom_time - (fi * trail_delay) + h * 6.28; // ← custom_time

            float pulse = (1.0 + sin(t * pulse_speed) * 0.15) * falloff;
            float cos_a = cos(t * spin_speed);
            float sin_a = sin(t * spin_speed);
            vec2 p_rot = vec2(cos_a * p.x - sin_a * p.y, sin_a * p.x + cos_a * p.y);

            float sd = sdf_star(p_rot, star_radius * pulse, 5.0, star_inner);

            float fill   = 1.0 - smoothstep(0.0, aa, sd);
            float border = (1.0 - smoothstep(0.02, 0.02 + aa, sd)) * smoothstep(0.0, aa, sd);

            float intensity = (fill + border) * falloff;
            vec3 star_sample = mix(star_color.rgb * 0.4, star_color.rgb, intensity);

            final_rgb   += star_sample * intensity * 2.0;
            final_alpha += intensity;
        }
    }

    COLOR = vec4(final_rgb, clamp(final_alpha, 0.0, 1.0) * global_opacity);
}