shader_type canvas_item;

uniform vec4 color : source_color = vec4(0.30, 1.00, 0.72, 1.0);

uniform float core_size    : hint_range(0.01, 0.20)  = 0.090;
uniform float star_radius  : hint_range(0.05, 0.45)  = 0.22;
uniform float star_inner   : hint_range(1.2,  4.0)   = 2.5;
uniform float border_width : hint_range(0.002, 0.1)  = 0.018;

uniform float ring_radius    : hint_range(0.10, 0.49) = 0.38;
uniform float ring_thickness : hint_range(0.003, 0.06) = 0.022;

uniform float pulse_speed  : hint_range(0.0, 8.0)  = 2.4;
uniform float pulse_amount : hint_range(0.0, 0.15) = 0.07;
uniform float spin_speed   : hint_range(0.0, 6.0)  = 1.6;

uniform float custom_time    : hint_range(0.0, 1e+20) = 0.0;
uniform float visible_amount : hint_range(0.0, 1.0)   = 1.0;

float sdf_star(vec2 p, float r, float n, float m) {
    float an  = PI / n;
    float en  = PI / m;
    vec2  acs = vec2(cos(an), sin(an));
    vec2  ecs = vec2(cos(en), sin(en));
    float bn  = mod(atan(p.y, p.x), 2.0 * an) - an;
    p = length(p) * vec2(cos(bn), abs(sin(bn)));
    p -= r * acs;
    p += ecs * clamp(-dot(p, ecs), 0.0, r * acs.y / ecs.y);
    return length(p) * sign(p.x);
}

void fragment() {
    vec2  uv    = UV - 0.5;
    float dist  = length(uv);
    float pulse = 1.0 + sin(custom_time * pulse_speed) * pulse_amount;
    float aa    = 0.006;

    // ─── Anillo exterior ─────────────────────────────────────
    float rd   = abs(dist - ring_radius * pulse);
    float ring = 1.0 - smoothstep(ring_thickness, ring_thickness + aa, rd);

    // ─── Estrella ────────────────────────────────────────────
    float ca = cos(custom_time * spin_speed);
    float sa = sin(custom_time * spin_speed);
    vec2  uv_rot = vec2(ca * uv.x - sa * uv.y,
                        sa * uv.x + ca * uv.y);
    float sd = sdf_star(uv_rot, star_radius * pulse, 5.0, star_inner);

    float star_border = (1.0 - smoothstep(border_width, border_width + aa, sd))
                      *       smoothstep(0.0, aa, sd);
    float star_fill   = 1.0 - smoothstep(0.0, aa, sd);

    // ─── Core ────────────────────────────────────────────────
    float core = 1.0 - smoothstep(core_size * 0.5, core_size, dist / pulse);
    float core_border = (1.0 - smoothstep(core_size + border_width,
                                          core_size + border_width + aa, dist / pulse))
                       * smoothstep(core_size, core_size + aa, dist / pulse);

    // ─── Composición ─────────────────────────────────────────
    vec3 col = color.rgb;
    col = mix(col, color.rgb,   ring);
    col = mix(col, color.rgb,   star_fill);
    col = mix(col, color.rgb, star_border);
    col = mix(col, vec3(1.0),        core);
    col = mix(col, color.rgb, core_border);

    float alpha = clamp(ring * color.a + star_fill + star_border + core, 0.0, 1.0)
                * visible_amount;

    COLOR = vec4(col, alpha);
}