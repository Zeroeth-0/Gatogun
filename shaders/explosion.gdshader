shader_type canvas_item;

uniform vec3 boom_pal1  : source_color = vec3(0.12, 0.05, 0.02);
uniform vec3 boom_pal2  : source_color = vec3(0.58, 0.28, 0.04);
uniform vec3 boom_pal3  : source_color = vec3(0.95, 0.80, 0.35);
uniform vec3 boom_pal4  : source_color = vec3(1.00, 0.98, 0.90);
uniform vec3 smoke_pal1 : source_color = vec3(0.05, 0.05, 0.07);
uniform vec3 smoke_pal2 : source_color = vec3(0.28, 0.26, 0.28);
uniform vec3 smoke_pal3 : source_color = vec3(0.62, 0.58, 0.55);

uniform float custom_time    : hint_range(0.0, 10.0)   = 0.0;
uniform float seed            : hint_range(0.0, 1000.0) = 0.0;
uniform float size            : hint_range(0.1, 50.0, 0.1) = 5.0;
uniform float disperse        : hint_range(0.1, 10.0, 0.1) = 1.0;
uniform float duration        : hint_range(0.1, 10.0, 0.1) = 1.0;
uniform float edge_turbulence : hint_range(0.0, 1.0, 0.01) = 0.12;
uniform float rise_bias       : hint_range(0.0, 1.0, 0.01) = 0.45;
uniform float filament_str    : hint_range(0.0, 1.0, 0.01) = 0.35;

float hash12(vec2 p) {
    p = fract(p * vec2(0.1031, 0.1030) + seed * 0.001);
    p += dot(p, p + 33.33);
    return fract(p.x * p.y);
}
vec2 hash22(vec2 p) {
    p = fract(p * vec2(0.1031, 0.1030) + seed * 0.001);
    p += dot(p, p.yx + 33.33);
    return fract((p.xx + p.yy) * p.yx);
}
float noise(vec2 p) {
    vec2 i = floor(p); vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash12(i), hash12(i+vec2(1,0)), u.x),
               mix(hash12(i+vec2(0,1)), hash12(i+vec2(1,1)), u.x), u.y) * 2.0 - 1.0;
}
float worley(vec2 p, float t) {
    vec2 i = floor(p); vec2 f = fract(p);
    float md = 1.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 o = vec2(float(x), float(y));
            vec2 h = hash22(i + o);
            h = 0.5 + 0.5 * sin(disperse * t + 6.2831 * h);
            vec2 rv = o + h - f;
            md = min(md, dot(rv, rv));
        }
    }
    return sqrt(md);
}

float aniso_dist(vec2 p, float t) {
    float progress = clamp(t / duration, 0.0, 1.0);
    float up_scale = 1.0 - rise_bias * 0.45 * smoothstep(0.1, 0.6, progress);
    float dn_scale = 1.0 + rise_bias * 0.25 * smoothstep(0.1, 0.6, progress);
    float sy = p.y < 0.0 ? up_scale : dn_scale;
    return sqrt(p.x*p.x + (p.y*sy)*(p.y*sy));
}

float boom(vec2 p, float t) {
    float repeat = clamp(t / duration, 0.0, 1.0) * 2.0;
    float dist   = aniso_dist(p, t);
    float shape  = 1.0 - pow(dist, 2.0) / (repeat * 12.0) - repeat * 2.0;
    vec2 warp;
    warp.x = noise(p * 0.4 + t * 0.4);
    warp.y = -abs(noise(p * 0.4 + vec2(4.3,1.7) + t * 0.3))
             * filament_str * smoothstep(0.1, 0.5, repeat);
    vec2 pw = p + warp * 0.4;
    float distortion = noise(pw * 0.5 + t * 0.5);
    float bubbles    = 0.5 - pow(worley(pw * 1.2 + t * 2.0, t), 3.0);
    return shape + (0.5 * bubbles + 0.5 * distortion);
}

float smoke(vec2 p, float t) {
    float repeat       = clamp(t / duration, 0.0, 1.0) * 2.0;
    float rise         = pow(repeat / 1.45, 2.0) * 1.5 * (1.0 + rise_bias * 0.6);
    vec2  smoke_offset = vec2(0.0, -rise);
    vec2  sp           = p - smoke_offset;
    sp.x += noise(sp * 0.8 + custom_time * 0.5) * 0.15;
    float shape      = 1.0 - pow(length(sp), 2.0) / (repeat * 16.0) - pow(repeat*1.5, 0.5);
    float distortion = noise(sp * 1.5 + t * 0.1);
    float bubbles    = 0.5 - pow(worley((p / pow(max(repeat,0.01), 0.35)) - smoke_offset + t*0.1, t), 2.0);
    return shape + (0.75 * bubbles + 0.25 * distortion);
}

float posterize(float v, int n) {
    float fn = float(n);
    return floor(v * fn) / (fn - 1.0);
}

void fragment() {
    vec2  pos       = (UV - vec2(0.5)) * size;
    float boom_val  = boom(pos, custom_time);
    float smoke_val = smoke(pos, custom_time);
    bool  is_boom   = boom_val > (smoke_val * 0.4);
    float main_val  = is_boom ? boom_val : smoke_val;
    float turb      = noise(pos * 0.8 + custom_time * 1.5) * edge_turbulence;
    float alpha     = smoothstep(0.0, edge_turbulence * 0.6, main_val + turb);
    vec3 bp[4]  = { boom_pal1, boom_pal2, boom_pal3, boom_pal4 };
    vec3 sp2[3] = { smoke_pal1, smoke_pal2, smoke_pal3 };
    vec3 color;
    if (main_val > 0.75) {
        color = vec3(1.0);
    } else if (is_boom) {
        int idx = clamp(int(posterize(boom_val, 4) * 4.0), 0, 3);
        color = bp[idx];
    } else {
        int idx = clamp(int(posterize(smoke_val, 3) * 3.0), 0, 2);
        color = sp2[idx];
    }
    alpha *= 1.0 - smoothstep(duration * 0.8, duration, custom_time);

    // Fade suave en los bordes del rect para evitar cortes visibles
    float border_fade = size * 0.5;
    float edge_dist   = border_fade - max(abs(pos.x), abs(pos.y));
    alpha *= smoothstep(0.0, border_fade * 0.3, edge_dist);

    COLOR = vec4(color, alpha);
}