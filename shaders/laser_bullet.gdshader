shader_type canvas_item;

// --- Colors ---
uniform vec4 core_color  : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 inner_color : source_color = vec4(1.0, 0.6, 0.1, 1.0);
uniform vec4 outer_color : source_color = vec4(1.0, 0.2, 0.0, 1.0);

// --- Shape ---
uniform float core_radius   : hint_range(0.01, 0.45) = 0.10;
uniform float bullet_radius : hint_range(0.01, 0.48) = 0.25;
uniform float body_sharpness : hint_range(0.001, 0.08) = 0.020;

// core_focus: 1.0 = gradiente suave blanco→naranja
//             8.0 = blanco casi hasta el borde, corte brusco
uniform float core_focus : hint_range(1.0, 10.0) = 1.0;

// --- Bullet type ---
uniform int bullet_type : hint_range(0, 4) = 3;

// --- Lifetime fade ---
uniform float lifetime_ratio : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec2  uv   = UV - vec2(0.5);
    float dist = length(uv);

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

    // --- Body: inner→outer según distancia ---
    float body_mask  = smoothstep(t_brad, t_brad - body_sharpness, dist);
    float body_blend = clamp((dist - t_crad) / max(t_brad - t_crad, 0.0001), 0.0, 1.0);
    vec3  body_rgb   = mix(t_inner.rgb, t_outer.rgb, body_blend);

    // --- Core: blanco en centro, transición hacia inner_color ---
    // core_blend va de 0 (centro) a 1 (borde del core)
    // pow() con core_focus hace que el blanco "aguante" más hacia el borde
    float raw_blend  = clamp(dist / max(t_crad, 0.0001), 0.0, 1.0);
    float core_blend = pow(raw_blend, core_focus);
    vec3  core_rgb   = mix(core_color.rgb, t_inner.rgb, core_blend);

    // Dentro del core (dist < t_crad): usar core_rgb
    // Fuera del core: usar body_rgb
    // step() — sin suavizado, corte exacto en t_crad
    float in_core   = step(dist, t_crad);
    vec3  final_rgb = mix(body_rgb, core_rgb, in_core);
    float final_a   = body_mask;

    COLOR = vec4(final_rgb * final_a, final_a) * lifetime_ratio;
}