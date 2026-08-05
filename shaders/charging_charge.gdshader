shader_type canvas_item;

// === CARGA ===
uniform float charge : hint_range(0.0, 1.0, 0.001) = 0.0;

// === HEARTBEAT ===
uniform float pulse_frequency  : hint_range(0.1, 5.0, 0.01)  = 2.2;
uniform float pulse_sharpness  : hint_range(1.0, 20.0, 0.1)  = 5.0;
uniform float pulse_strength   : hint_range(0.0, 0.5, 0.01)  = 0.14;
uniform float pulse_glow_boost : hint_range(0.0, 4.0, 0.01)  = 2.5;
uniform float flash_white      : hint_range(0.0, 1.0, 0.01)  = 0.55;

// === FORMA ===
uniform float max_radius      : hint_range(0.05, 1.2, 0.01)   = 0.32;
uniform float edge_softness   : hint_range(0.0,  0.15, 0.001) = 0.07;
uniform float glow_falloff    : hint_range(0.5,  8.0,  0.1)   = 2.5;
uniform float edge_turbulence : hint_range(0.0,  0.40, 0.001) = 0.13;
uniform float turbulence_speed: hint_range(0.0,  8.0,  0.01)  = 2.8;

// === POSTERIZACIÓN ===
uniform float posterize_str   : hint_range(0.0, 1.0, 0.01) = 0.50;
uniform int   posterize_bands : hint_range(2, 6)            = 4;

// === ESTRELLA 4 PUNTAS ===
uniform float star4_radius       : hint_range(0.1, 2.0, 0.01)   = 0.68;
uniform float star4_inner_ratio  : hint_range(0.02, 0.5, 0.01)  = 0.15;
uniform float star4_softness     : hint_range(0.0, 0.12, 0.001) = 0.025;
uniform float star4_darkness     : hint_range(0.0, 1.0, 0.01)   = 0.50;
uniform float star4_pulse_amount : hint_range(0.0, 1.2, 0.01)   = 0.60;
uniform float star4_rot_speed    : hint_range(-3.0, 3.0, 0.01)  = 0.35;
uniform float star4_ready_scale  : hint_range(1.0, 4.0, 0.05)   = 2.4;

// === RAYOS ===
uniform float ray_amount         : hint_range(4.0, 24.0, 1.0)    = 12.0;
uniform float ray_rotation_speed : hint_range(-6.0, 6.0, 0.01)   = 1.2;
uniform float ray_half_width     : hint_range(0.02, 0.4, 0.001)  = 0.135;
uniform float ray_softness       : hint_range(0.01, 0.25, 0.001) = 0.065;
uniform float ray_reach          : hint_range(0.4, 1.6, 0.01)    = 1.15;
uniform float ray_screw_factor   : hint_range(-6.0, 6.0, 0.01)   = 0.8;
uniform float ray_base_intensity : hint_range(0.3, 1.2, 0.05)    = 0.70;
uniform vec4  ray_color : source_color = vec4(1.00, 0.88, 0.28, 1.0);

// === COLORES ===
uniform vec4 core_color : source_color = vec4(1.00, 1.00, 0.92, 1.0);
uniform vec4 mid_color  : source_color = vec4(1.00, 0.82, 0.15, 1.0);
uniform vec4 edge_color : source_color = vec4(1.00, 0.38, 0.00, 1.0);
uniform vec4 rim_color  : source_color = vec4(0.90, 0.00, 0.00, 1.0);

// === TIEMPO ===
uniform float custom_time : hint_range(0.0, 1000.0) = 0.0;

const float ACTIVATION_THRESHOLD = 0.985;

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    vec2 a = fract(sin(vec2(dot(i, vec2(127.1,311.7)), dot(i+vec2(1,0),vec2(127.1,311.7))))*43758.5453);
    vec2 b = fract(sin(vec2(dot(i+vec2(0,1),vec2(127.1,311.7)), dot(i+vec2(1,1),vec2(127.1,311.7))))*43758.5453);
    return mix(mix(a.x,a.y,f.x), mix(b.x,b.y,f.x), f.y);
}

float sdf_star4(vec2 p, float r, float rf) {
    const float c = 0.70710678118;
    p = abs(p); if (p.x < p.y) p = p.yx;
    vec2 tip   = vec2(r, 0.0);
    vec2 inner = vec2(rf * r * c, rf * r * c);
    vec2 ba    = inner - tip;
    vec2 pa    = p - tip;
    float h    = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    float d    = length(pa - ba * h);
    float s    = sign(ba.y * pa.x - ba.x * pa.y);
    return d * s;
}

void fragment() {
    vec2  uv    = UV * 2.0 - 1.0;
    float dist  = length(uv);
    float angle = atan(uv.y, uv.x);

    float t      = mod(custom_time * pulse_frequency, 1.0);
    float beat1  = pow(max(0.0, sin(t * PI)), pulse_sharpness);
    float beat2  = pow(max(0.0, sin(mod(t + 0.18, 1.0) * PI)), pulse_sharpness * 2.5) * 0.35;
    float hb_raw = beat1 + beat2;
    float hb     = hb_raw * smoothstep(ACTIVATION_THRESHOLD - 0.04, ACTIVATION_THRESHOLD + 0.02, charge);

    float hb_full   = smoothstep(ACTIVATION_THRESHOLD, 1.0, charge);
    float size_kick = hb_raw * hb_full * 0.35;
    float cur_r     = max_radius * pow(charge, 0.6) * (1.0 + size_kick);

    float tc    = angle * 3.0 + custom_time * turbulence_speed;
    float ts    = custom_time * turbulence_speed;
    float turb  = (noise(vec2(tc, ts*0.5))*2.-1.)*0.65 + (noise(vec2(tc*2.3+5.7, ts))*2.-1.)*0.35;
    float turb2 = (noise(vec2(dist*4.0 + custom_time*1.5, angle*2.0 + custom_time))*2.-1.) * 0.4;
    turb = (turb + turb2*0.5) * edge_turbulence * charge;

    if (dist - turb > cur_r + edge_softness) discard;

    float r_pulse = (dist - turb) / (1.0 + hb * pulse_strength * 1.6);

    float mp1 = cur_r * 0.25;
    float mp2 = cur_r * 0.55;
    float mp3 = cur_r * 0.82;

    vec3 base = core_color.rgb;
    base = mix(base, mid_color.rgb,  smoothstep(0.0, mp1, r_pulse));
    base = mix(base, edge_color.rgb, smoothstep(mp1, mp2, r_pulse));
    base = mix(base, rim_color.rgb,  smoothstep(mp2, mp3, r_pulse));

    float fn   = float(posterize_bands);
    vec3  post = floor(base * fn) / (fn - 1.0);
    base = mix(base, post, posterize_str * charge);

    float soft       = edge_softness + abs(turb) * 1.5;
    float outer_mask = 1.0 - smoothstep(cur_r - soft*0.3, cur_r + soft, r_pulse);

    float inv_r  = max(0.0, 1.0 - r_pulse / max(cur_r, 0.001));
    float glow   = pow(inv_r, glow_falloff);
    float glow_p = pow(max(0.0, 1.0 - r_pulse / max(cur_r * 0.55, 0.001)), glow_falloff + 1.0);

    float flash_amount = flash_white * hb_raw
        * smoothstep(ACTIVATION_THRESHOLD - 0.03, ACTIVATION_THRESHOLD, charge) * 1.4;

    base += core_color.rgb * (glow * 0.35 + glow_p * hb * pulse_glow_boost * 0.6);
    base  = mix(base, vec3(1.0), flash_amount * inv_r * 1.2);

    float screw     = r_pulse * ray_screw_factor * PI;
    float ray_angle = angle * ray_amount + custom_time * TAU * ray_rotation_speed + screw;
    float d_ray     = abs(mod(ray_angle, TAU) - PI);

    float ray_a       = 1.0 - smoothstep(ray_amount * ray_half_width, ray_amount * (ray_half_width + ray_softness), d_ray);
    float ray_r_start = smoothstep(cur_r * 0.15, cur_r * 0.5, dist);
    float ray_r_end   = 1.0 - smoothstep(cur_r * ray_reach * 0.6, cur_r * ray_reach * 1.1, dist);
    float ray_r       = ray_r_start * ray_r_end;
    float ray_boost   = smoothstep(ACTIVATION_THRESHOLD - 0.06, ACTIVATION_THRESHOLD + 0.04, charge) * 1.5;
    float ray_intensity = ray_base_intensity * (1.0 + hb_raw * 0.6) * (1.0 + ray_boost);
    float ray_mask    = ray_a * ray_r * outer_mask * ray_intensity * 0.85;

    vec3 ray_rgb = mix(ray_color.rgb, vec3(1.15), hb_raw * flash_white * 0.8);
    ray_rgb *= (1.0 + hb * 0.7);
    base = mix(base, ray_rgb, ray_mask);

    float star_rot  = custom_time * TAU * star4_rot_speed;
    float sc        = cos(star_rot), ss = sin(star_rot);
    vec2  star_uv   = mat2(vec2(sc, ss), vec2(-ss, sc)) * uv;
    float star_wave = sin(custom_time * pulse_frequency * TAU) * 0.5 + 0.5;
    float star_scale = 1.0 + charge * 0.4
        + max(0.0, (charge - ACTIVATION_THRESHOLD) / (1.0 - ACTIVATION_THRESHOLD)) * (star4_ready_scale - 1.4);
    float sr = cur_r * star4_radius * star_scale
        * (1.0 + star_wave * star4_pulse_amount * max(0.0, charge - 0.9));

    float d_star        = sdf_star4(star_uv, sr, star4_inner_ratio);
    float star_mask_raw = 1.0 - smoothstep(-star4_softness, star4_softness, d_star);
    float star_appear   = smoothstep(ACTIVATION_THRESHOLD - 0.015, ACTIVATION_THRESHOLD + 0.025, charge);
    float star_mask     = star_mask_raw * star_appear * outer_mask * 1.1;
    float star_white    = smoothstep(ACTIVATION_THRESHOLD - 0.02, ACTIVATION_THRESHOLD + 0.03, charge);
    vec3  star_col      = mix(base, vec3(1.0), star_white * 0.95);
    float star_dark     = mix(star4_darkness, 0.08, star_white);
    vec3  star_final    = star_col * (1.0 - star_dark);
    base = mix(base, star_final, star_mask * 0.88);

    float alpha = outer_mask * smoothstep(0.0, 0.08, charge);
    COLOR = vec4(base, alpha);
}