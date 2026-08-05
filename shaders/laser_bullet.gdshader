shader_type canvas_item;
// --- Colors ---
uniform vec4 core_color  : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 inner_color : source_color = vec4(1.0, 0.6, 0.1, 1.0);
uniform vec4 outer_color : source_color = vec4(1.0, 0.2, 0.0, 1.0);
// --- Shape ---
uniform float core_radius    : hint_range(0.01, 0.45) = 0.10;
uniform float bullet_radius  : hint_range(0.01, 0.48) = 0.25;
uniform float body_sharpness : hint_range(0.001, 0.08) = 0.020;
uniform float tip_front : hint_range(0.3, 6.0) = 2.0;
uniform float tip_back  : hint_range(0.3, 6.0) = 2.0;
// center_offset positivo → waist baja, frente más largo, trasero más corto
// center_offset negativo → waist sube, trasero más largo, frente más corto
uniform float center_offset : hint_range(-0.4, 0.4) = 0.0;
uniform float core_focus : hint_range(1.0, 10.0) = 1.0;
// --- Bullet type ---
uniform int bullet_type : hint_range(0, 4) = 3;
// --- Lifetime fade ---
uniform float lifetime_ratio : hint_range(0.0, 1.0) = 1.0;

float superellipse_dist(vec2 uv) {
    float shifted_y = uv.y - center_offset;
    float scaled_y;
    float n;
    if (shifted_y < 0.0) {
        // mitad delantera: ocupa (0.5 + center_offset) del sprite
        float half_len = max(0.5 + center_offset, 0.001);
        scaled_y = shifted_y / half_len * 0.5;
        n = tip_front;
    } else {
        // mitad trasera: ocupa (0.5 - center_offset) del sprite
        float half_len = max(0.5 - center_offset, 0.001);
        scaled_y = shifted_y / half_len * 0.5;
        n = tip_back;
    }
    n = max(n, 0.01);
    return pow(pow(abs(uv.x), n) + pow(abs(scaled_y), n), 1.0 / n);
}

void fragment() {
    vec2  uv   = UV - vec2(0.5);
    float dist = superellipse_dist(uv);

    vec4  t_inner = inner_color;
    vec4  t_outer = outer_color;
    float t_brad  = bullet_radius;
    float t_crad  = core_radius;

    if (bullet_type == 0) {
        t_inner = vec4(1.0, 0.3, 0.0, 1.0);
        t_outer = vec4(0.8, 0.0, 0.0, 1.0);
        t_brad *= 1.6;  t_crad *= 1.4;
    } else if (bullet_type == 1) {
        t_inner = vec4(0.5, 0.9, 1.0, 1.0);
        t_outer = vec4(0.0, 0.5, 1.0, 1.0);
    } else if (bullet_type == 2) {
        t_inner = vec4(0.9, 0.3, 1.0, 1.0);
        t_outer = vec4(0.5, 0.0, 0.8, 1.0);
    } else if (bullet_type == 4) {
        t_inner = vec4(1.0, 0.95, 0.4, 1.0);
        t_outer = vec4(1.0, 0.60, 0.0, 1.0);
        t_brad *= 1.8;  t_crad *= 1.6;
    }

    float body_mask  = smoothstep(t_brad, t_brad - body_sharpness, dist);
    float body_blend = clamp((dist - t_crad) / max(t_brad - t_crad, 0.0001), 0.0, 1.0);
    vec3  body_rgb   = mix(t_inner.rgb, t_outer.rgb, body_blend);

    float raw_blend  = clamp(dist / max(t_crad, 0.0001), 0.0, 1.0);
    float core_blend = pow(raw_blend, core_focus);
    vec3  core_rgb   = mix(core_color.rgb, t_inner.rgb, core_blend);

    float in_core   = step(dist, t_crad);
    vec3  final_rgb = mix(body_rgb, core_rgb, in_core);

    COLOR = vec4(final_rgb * body_mask, body_mask) * lifetime_ratio;
}