shader_type canvas_item;

uniform int bullet_type    : hint_range(0, 3) = 0;
uniform int bullet_subtype : hint_range(0, 4) = 0;

uniform vec4 bullet_color : source_color = vec4(1.0,  0.0,  0.85, 1.0);
uniform vec4 rim_color    : source_color = vec4(0.45, 0.0,  0.40, 1.0);
uniform vec4 core_color   : source_color = vec4(1.0,  1.0,  1.0,  1.0);
uniform bool invert_colors                = false;

uniform float core_radius   : hint_range(0.01, 0.49) = 0.20;
uniform float rim_start     : hint_range(0.01, 0.49) = 0.25;
uniform float edge_softness : hint_range(0.001, 0.1) = 0.025;
uniform float brightness    : hint_range(1.0,   6.0) = 2.0;

// === TIEMPO ===
uniform float custom_time : hint_range(0.0, 1000.0) = 0.0;
uniform float time_offset : hint_range(0.0, 100.0)  = 0.0;

uniform bool  pulse_enabled                        = true;
uniform float pulse_speed  : hint_range(0.0, 20.0) = 5.0;
uniform float pulse_amount : hint_range(0.0, 0.12) = 0.035;

uniform float kunai_length     : hint_range(1.0, 6.0) = 2.0;
uniform float kunai_tip_top    : hint_range(0.3, 4.0) = 1.8;
uniform float kunai_tip_bottom : hint_range(0.3, 4.0) = 1.8;

uniform float box_aspect : hint_range(0.2,  1.5)    = 1.0;
uniform float box_round  : hint_range(0.0,  1.0)    = 0.1;
uniform float box_bulge  : hint_range(-0.25, 0.25)  = 0.0;

uniform float star_inner : hint_range(0.1, 0.9) = 0.45;

uniform float reach     : hint_range(0.0,   1.0)  = 0.85;
uniform float thickness : hint_range(0.01,  1.0)  = 0.30;
uniform int   count     : hint_range(1,    12)    = 4;
uniform float spin      : hint_range(-10.0, 10.0) = 2.0;

vec4 eff_core()   { return invert_colors ? bullet_color : core_color;   }
vec4 eff_bullet() { return invert_colors ? core_color   : bullet_color; }
float T()         { return custom_time + time_offset; }

float core_r() {
    float r = core_radius;
    if (pulse_enabled) r += sin(T() * pulse_speed) * pulse_amount;
    return r;
}

vec4 base_gradient(float d) {
    float cr  = core_r();
    vec4  lit = vec4(eff_bullet().rgb * brightness, 1.0);
    vec4  a   = mix(eff_core(), lit,       smoothstep(cr,        rim_start,           d));
    vec4  b   = mix(a,          rim_color, smoothstep(rim_start, 0.5 - edge_softness, d));
    return b;
}

float circle_alpha(float d) {
    return 1.0 - smoothstep(0.5 - edge_softness, 0.5, d);
}

vec2 rot2D(vec2 v, float a) {
    float c = cos(a), s = sin(a);
    return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

vec4 apply_pattern(vec4 body, vec4 pcol, float mask) {
    float sharpened = smoothstep(1.0 - thickness, 1.0, mask);
    return mix(body, pcol, sharpened);
}

vec4 draw_ball_base(vec2 uv) {
    float pulse = pulse_enabled ? sin(T() * pulse_speed) * pulse_amount : 0.0;
    float scale = 1.0 / (1.0 + pulse * 4.0);
    float d     = length(uv * scale);
    return vec4(base_gradient(d).rgb, circle_alpha(d));
}

vec4 draw_kunai(vec2 uv) {
    float half_w = mix(0.08, 0.48, thickness);
    float nx     = uv.x / half_w;
    float ny     = uv.y / (half_w * kunai_length);
    float sharp  = uv.y < 0.0 ? kunai_tip_top : kunai_tip_bottom;
    float blade  = pow(abs(nx) * 0.92, sharp) + pow(abs(ny) * 0.92, sharp);
    float pulse  = pulse_enabled ? sin(T() * pulse_speed) * pulse_amount : 0.0;
    float edge   = 0.88 - pulse * 3.0;
    float alpha  = 1.0 - smoothstep(edge - edge_softness, edge + edge_softness, blade);
    float d      = clamp(blade / edge, 0.0, 1.0) * 0.5;
    float reflex   = 1.0 - smoothstep(0.0, 0.08, abs(uv.x));
    float reflex_v = 1.0 - smoothstep(0.0, 0.55, abs(ny));
    reflex *= reflex_v;
    vec4 col = base_gradient(d);
    col = mix(col, eff_core(), reflex * 0.70 * (1.0 - d * 2.0 * 0.6));
    return vec4(col.rgb, alpha);
}

vec4 draw_box(vec2 uv) {
    float pulse  = pulse_enabled ? sin(T() * pulse_speed) * pulse_amount : 0.0;
    float size   = mix(0.15, 0.48, thickness) * (1.0 + pulse * 4.0);
    vec2  half_e = vec2(size * box_aspect, size);
    float t_y    = clamp(abs(uv.y) / half_e.y, 0.0, 1.0);
    float t_x    = clamp(abs(uv.x) / half_e.x, 0.0, 1.0);
    float bow_y  = box_bulge * size * (1.0 - t_y * t_y);
    float bow_x  = box_bulge * size * (1.0 - t_x * t_x);
    vec2 uv_b;
    uv_b.x = uv.x - sign(uv.x) * bow_y;
    uv_b.y = uv.y - sign(uv.y) * bow_x;
    float r   = box_round * size;
    vec2  q   = abs(uv_b) - half_e + r;
    float sdf = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
    float alpha     = 1.0 - smoothstep(-edge_softness, edge_softness, sdf);
    float max_inner = min(half_e.x, half_e.y);
    float d         = (1.0 - clamp((-sdf) / max_inner, 0.0, 1.0)) * 0.5;
    vec2  pn     = uv / max(half_e, vec2(0.001));
    float reflex = (1.0 - smoothstep(0.0, 0.30, abs(pn.x + pn.y) * 0.5))
                 * smoothstep(0.0, 0.5, 1.0 - d * 2.0);
    vec4 col = base_gradient(d);
    col = mix(col, eff_core(), reflex * 0.40 * (1.0 - d * 2.0));
    return vec4(col.rgb, alpha);
}

vec4 draw_star(vec2 uv) {
    float pulse = pulse_enabled ? sin(T() * pulse_speed) * pulse_amount : 0.0;
    float sz    = mix(0.08, 0.92, thickness) * (1.0 + pulse * 4.0);
    float an    = PI / float(count);
    vec2  p     = rot2D(uv / sz, -PI * 0.5);
    float bn    = mod(atan(p.y, p.x), 2.0 * an) - an;
    p           = length(p) * vec2(cos(bn), abs(sin(bn)));
    vec2  ab      = vec2(star_inner * cos(an) - 1.0, star_inner * sin(an));
    float tt      = clamp(dot(p - vec2(1.0, 0.0), ab) / dot(ab, ab), 0.0, 1.0);
    vec2  closest = vec2(1.0, 0.0) + ab * tt;
    float sgn     = sign(ab.x * (p.y - closest.y) - ab.y * (p.x - closest.x));
    float sdf_n   = length(p - closest) * -sgn;
    float alpha   = 1.0 - smoothstep(-edge_softness, edge_softness, sdf_n);
    float d       = clamp((1.0 + sdf_n) * 0.5, 0.0, 0.5);
    return vec4(base_gradient(d).rgb, alpha);
}

vec4 apply_spiral(vec2 uv, vec4 body) {
    float d     = length(uv);
    float cr    = core_r();
    float outer = mix(cr + 0.04, 0.50, reach);
    float angle = atan(uv.y, uv.x);
    float sc    = angle * float(count) - 6.0 * TAU * d + T() * spin;
    float threshold = 1.0 - 2.0 * clamp(thickness, 0.01, 1.0);
    float arm_raw   = clamp((cos(sc) - threshold) / (1.0 - threshold), 0.0, 1.0);
    float fade = smoothstep(cr * 0.4, cr + 0.06, d)
               * (1.0 - smoothstep(outer * 0.92, outer, d));
    return apply_pattern(body, eff_core(), arm_raw * fade);
}

vec4 apply_cross(vec2 uv, vec4 body) {
    float d   = length(uv);
    float cr  = core_r();
    vec2  ruv = rot2D(uv, T() * spin * 0.12);
    float arm_reach = mix(cr + 0.04, 0.50, reach);
    float arm_w     = mix(0.01, 0.22, thickness * thickness);
    float angle  = atan(ruv.y, ruv.x);
    float sector = TAU / float(count);
    float folded = mod(angle + sector * 0.5, sector) - sector * 0.5;
    float perp   = abs(d * sin(folded));
    float arm_mask = 1.0 - smoothstep(0.0, arm_w,       perp);
    float arm_glow = 1.0 - smoothstep(0.0, arm_w * 2.5, perp);
    float rfade = smoothstep(cr * 0.2, cr * 0.75, d)
                * (1.0 - smoothstep(arm_reach * 0.88, arm_reach, d));
    vec4 lit      = vec4(eff_bullet().rgb * brightness, 1.0);
    vec4 glow_col = mix(lit, eff_core(), 0.5);
    vec4 result   = body;
    result = mix(result, glow_col,   arm_glow * rfade * 0.7);
    result = mix(result, eff_core(), arm_mask * rfade);
    return result;
}

vec4 apply_rings(vec2 uv, vec4 body) {
    float d      = length(uv);
    float cr     = core_r();
    float outer  = mix(cr + 0.04, 0.50, reach);
    float zone   = max(outer - cr, 0.001);
    float ring_t = clamp((d - cr) / zone, 0.0, 1.0);
    float duty     = mix(0.04, 0.96, thickness);
    float phase    = ring_t * float(count) * TAU - T() * spin;
    float wave_raw = cos(phase);
    float thr      = cos(duty * PI);
    float wave     = clamp((wave_raw - thr) / (1.0 - thr), 0.0, 1.0);
    float fade = smoothstep(0.0, cr * 0.5, d)
               * (1.0 - smoothstep(outer * 0.93, outer, d));
    return apply_pattern(body, eff_core(), wave * fade);
}

vec4 apply_star(vec2 uv, vec4 body) {
    float d   = length(uv);
    vec2  ruv = rot2D(uv, T() * spin * 0.18);
    float r_outer = mix(0.10, 0.48, reach);
    float r_inner = r_outer * mix(0.04, 0.82, thickness);
    float angle    = atan(ruv.y, ruv.x);
    float sector   = TAU / float(count);
    float half_sec = sector * 0.5;
    float folded   = mod(angle + half_sec, sector) - half_sec;
    float spoke_r  = mix(r_outer, r_inner, abs(folded) / half_sec);
    float sdf       = d - spoke_r;
    float star_fill = 1.0 - smoothstep(-0.010, 0.018, sdf);
    float star_glow = 1.0 - smoothstep(-0.08,  0.06,  sdf);
    vec4 lit = vec4(eff_bullet().rgb * brightness, 1.0);
    vec4 b   = mix(body, lit,        star_glow * 0.6);
         b   = mix(b,    eff_core(), star_fill);
    return b;
}

void fragment() {
    vec2  uv        = (UV - 0.5) * 2.0;
    float tex_alpha = texture(TEXTURE, UV).a;
    vec4 result;
    if (bullet_type == 1) {
        result = draw_kunai(uv);
    } else if (bullet_type == 2) {
        result = draw_box(uv);
    } else if (bullet_type == 3) {
        result = draw_star(uv);
    } else {
        result = draw_ball_base(uv);
        if      (bullet_subtype == 1) result = apply_spiral(uv, result);
        else if (bullet_subtype == 2) result = apply_cross(uv,  result);
        else if (bullet_subtype == 3) result = apply_rings(uv,  result);
        else if (bullet_subtype == 4) result = apply_star(uv,   result);
    }
    COLOR = vec4(result.rgb, result.a * tex_alpha);
}