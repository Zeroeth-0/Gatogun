shader_type canvas_item;

// === PULSE / HEARTBEAT ===
uniform float pulse_frequency  : hint_range(0.1, 5.0, 0.01)  = 1.8;
uniform float pulse_sharpness  : hint_range(1.0, 20.0, 0.1)  = 8.0;
uniform float pulse_strength   : hint_range(0.0, 0.5, 0.01)  = 0.28;
uniform float pulse_glow_boost : hint_range(0.0, 6.0, 0.01)  = 4.5;
uniform float flash_white      : hint_range(0.0, 1.0, 0.01)  = 0.90;

// === RAYOS ===
uniform float ray_amount         : hint_range(1.0, 32.0, 1.0)    = 8.0;
uniform float rotation_frequency : hint_range(-8.0, 8.0, 0.001)  = 0.25;
uniform float ray_half_width     : hint_range(0.0, 3.142, 0.001) = 0.18;
uniform float ray_softness       : hint_range(0.0, 0.5, 0.001)   = 0.07;
uniform float ray_reach          : hint_range(0.0, 1.0, 0.001)   = 0.75;
uniform float screw_factor       : hint_range(-8.0, 8.0, 0.001)  = 0.0;

// === FORMA ===
uniform float core_radius     : hint_range(0.0, 0.6, 0.001) = 0.22;
uniform float outer_radius    : hint_range(0.0, 1.0, 0.001) = 0.82;
uniform float edge_softness   : hint_range(0.0, 0.3, 0.001) = 0.08;
uniform float glow_falloff    : hint_range(0.5, 8.0, 0.1)   = 2.0;
uniform float edge_turbulence : hint_range(0.0, 0.5, 0.001) = 0.24;
uniform float turbulence_speed: hint_range(0.0, 8.0, 0.01)  = 4.5;

// === POSTERIZACIÓN ===
uniform float posterize_str   : hint_range(0.0, 1.0, 0.01) = 0.70;
uniform int   posterize_bands : hint_range(2, 6)            = 4;

// === ESTRELLA ===
uniform bool  star_enabled      = true;
uniform float star_radius       : hint_range(0.1, 1.2, 0.01)  = 0.82;
uniform float star_inner_ratio  : hint_range(0.1, 0.9, 0.01)  = 0.32;
uniform float star_softness     : hint_range(0.0, 0.1, 0.001) = 0.012;
uniform float star_darkness     : hint_range(0.0, 1.0, 0.01)  = 0.72;
uniform float star_pulse_amount : hint_range(0.0, 0.8, 0.01)  = 0.22;

// === COLORES ===
uniform vec4 core_color : source_color = vec4(1.00, 1.00, 0.92, 1.0);
uniform vec4 mid_color  : source_color = vec4(1.00, 0.82, 0.15, 1.0);
uniform vec4 edge_color : source_color = vec4(1.00, 0.38, 0.00, 1.0);
uniform vec4 rim_color  : source_color = vec4(0.55, 0.03, 0.00, 1.0);
uniform vec4 ray_color  : source_color = vec4(1.00, 0.82, 0.15, 1.0);

// ─────────────────────────────────────────────────────────────────────────────

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    vec2 a = fract(sin(vec2(
        dot(i,             vec2(127.1, 311.7)),
        dot(i + vec2(1,0), vec2(127.1, 311.7))
    )) * 43758.5453);
    vec2 b = fract(sin(vec2(
        dot(i + vec2(0,1), vec2(127.1, 311.7)),
        dot(i + vec2(1,1), vec2(127.1, 311.7))
    )) * 43758.5453);
    return mix(mix(a.x, a.y, f.x), mix(b.x, b.y, f.x), f.y);
}

float sdf_star5(vec2 p, float r, float rf) {
    const vec2 k1 = vec2( 0.80901699437, -0.58778525229);
    const vec2 k2 = vec2(-0.80901699437, -0.58778525229);
    p.x = abs(p.x);
    p -= 2.0 * max(dot(k1, p), 0.0) * k1;
    p -= 2.0 * max(dot(k2, p), 0.0) * k2;
    p.x = abs(p.x);
    p.y -= r;
    vec2  ba = rf * vec2(-k1.y, k1.x) - vec2(0.0, 1.0);
    float h  = clamp(dot(p, ba) / dot(ba, ba), 0.0, r);
    return length(p - ba * h) * sign(p.x * ba.y - p.y * ba.x);
}

void fragment() {
    vec2  uv        = UV * 2.0 - 1.0;
    float r         = length(uv);
    float angle_raw = atan(uv.y, uv.x);

    // === HEARTBEAT: dos beats desfasados 0.5 ===
    float t = mod(TIME * pulse_frequency, 1.0);

    float beat1_orb  = pow(max(0.0, sin(t * PI)), pulse_sharpness);
    float beat2_orb  = pow(max(0.0, sin(mod(t + 0.18, 1.0) * PI)), pulse_sharpness * 2.5) * 0.35;
    float hb_orb     = beat1_orb + beat2_orb;

    float t_star     = mod(t + 0.5, 1.0);
    float beat1_star = pow(max(0.0, sin(t_star * PI)), pulse_sharpness);
    float beat2_star = pow(max(0.0, sin(mod(t_star + 0.18, 1.0) * PI)), pulse_sharpness * 2.5) * 0.35;
    float hb_star    = beat1_star + beat2_star;

    // === TAMAÑO: el orbe expande con hb_orb ===
    float size_kick = hb_orb * 0.18;
    float outer_r   = outer_radius * (1.0 + size_kick);

    // === TURBULENCIA ===
    float tc    = angle_raw * 3.0 + TIME * turbulence_speed;
    float ts    = TIME * turbulence_speed;
    float turb  = (noise(vec2(tc,             ts * 0.5)) * 2.0 - 1.0) * 0.65
                + (noise(vec2(tc * 2.3 + 5.7, ts))      * 2.0 - 1.0) * 0.35;
    float turb2 = (noise(vec2(r * 4.0 + TIME * 1.5, angle_raw * 2.0 + TIME)) * 2.0 - 1.0) * 0.4;
    turb = (turb + turb2 * 0.5) * edge_turbulence * (1.0 + hb_orb * 0.6);

    if (r - turb > outer_r + edge_softness) discard;

    float r_pulse = (r - turb) / (1.0 + hb_orb * pulse_strength);

    // === GRADIENTE ===
    float mp1 = outer_r * 0.25;
    float mp2 = outer_r * 0.55;
    float mp3 = outer_r * 0.82;

    vec3 base_rgb = core_color.rgb;
    base_rgb = mix(base_rgb, mid_color.rgb,  smoothstep(0.0, mp1, r_pulse));
    base_rgb = mix(base_rgb, edge_color.rgb, smoothstep(mp1, mp2, r_pulse));
    base_rgb = mix(base_rgb, rim_color.rgb,  smoothstep(mp2, mp3, r_pulse));

    // === POSTERIZACIÓN ===
    float fn   = float(posterize_bands);
    vec3  post = floor(base_rgb * fn) / (fn - 1.0);
    base_rgb   = mix(base_rgb, post, posterize_str);

    float soft       = edge_softness + abs(turb) * 1.5;
    float outer_mask = 1.0 - smoothstep(outer_r - soft * 0.3, outer_r + soft, r_pulse);

    // === GLOW + FLASH ===
    float inv_r  = max(0.0, 1.0 - r_pulse / outer_r);
    float glow   = pow(inv_r, glow_falloff);
    float glow_p = pow(max(0.0, 1.0 - r_pulse / (outer_r * 0.55)), glow_falloff + 1.0);

    float flash_core = hb_orb * flash_white * pow(inv_r, 1.5);
    float flash_wide = hb_orb * flash_white * 0.55 * inv_r;
    base_rgb += core_color.rgb * (glow * 0.4 + glow_p * hb_orb * pulse_glow_boost);
    base_rgb  = mix(base_rgb, vec3(1.0), clamp(flash_core + flash_wide, 0.0, 1.0));

    // === ESTRELLA ===
    if (star_enabled) {
        float star_angle = -TIME * TAU * rotation_frequency;
        float sc = cos(star_angle);
        float ss = sin(star_angle);
        vec2 star_uv = mat2(vec2(sc, ss), vec2(-ss, sc)) * uv;

        // Clampeamos sr a outer_r * 0.96 para que las puntas nunca sobresalgan
        float sr     = min(star_radius * (1.0 + hb_star * star_pulse_amount), outer_r * 0.96);
        float d_star = sdf_star5(star_uv, sr, star_inner_ratio);

        float star_mask = 1.0 - smoothstep(-star_softness, star_softness, d_star);
        float star_halo = 1.0 - smoothstep(star_softness, star_softness + 0.04, d_star);
        star_mask *= outer_mask;
        star_halo *= outer_mask;

        float star_vis = star_darkness * (0.5 + hb_star * 0.5);
        base_rgb = mix(base_rgb, base_rgb * (1.0 - star_vis), star_mask);

        vec3 star_rim = mix(mid_color.rgb, vec3(1.0), hb_star * 0.8) * (1.2 + hb_star * 0.8);
        base_rgb = mix(base_rgb, star_rim, (star_halo - star_mask) * (0.5 + hb_star * 0.5));
    }

    // === RAYOS ===
    float screw  = r_pulse * screw_factor * PI;
    float angle  = angle_raw * ray_amount + screw;
    float target = PI - mod(TIME * TAU * rotation_frequency * ray_amount, TAU);
    float d      = abs(mod(angle - target, TAU) - PI);

    float ray_a    = 1.0 - smoothstep(
        ray_amount * ray_half_width,
        ray_amount * (ray_half_width + ray_softness), d);
    float ray_r    = smoothstep(core_radius, core_radius + 0.08, r_pulse) *
                     (1.0 - smoothstep(ray_reach, ray_reach + 0.12, r_pulse));
    float ray_mask = ray_a * ray_r * outer_mask;

    vec3 ray_rgb = mix(ray_color.rgb, vec3(1.0), hb_orb * flash_white * 0.6) * (1.0 + hb_orb * 0.8);

    // === FINAL ===
    vec3  final_rgb = mix(base_rgb, ray_rgb, ray_mask * 0.75) * outer_mask;
    float alpha     = clamp(outer_mask * (1.0 + hb_orb * 0.45), 0.0, 1.0);

    COLOR = vec4(final_rgb, alpha);
}