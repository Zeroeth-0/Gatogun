shader_type canvas_item;

uniform vec4 core_color  : source_color = vec4(1.0, 1.0, 0.9, 1.0);
uniform vec4 body_color  : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform vec4 glow_color  : source_color = vec4(0.0, 0.3, 1.0, 1.0);
uniform vec4 flash_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform float bullet_gap    : hint_range(0.0, 0.9) = 0.4;
uniform float bullet_length : hint_range(0.1, 0.95) = 0.7;
uniform float bullet_width  : hint_range(0.02, 0.45) = 0.12;
uniform float tip_sharpness : hint_range(1.0, 8.0) = 3.0;
uniform float glow_radius   : hint_range(0.0, 0.3) = 0.08;
uniform float glow_strength : hint_range(0.0, 1.0) = 0.85;
uniform float flash_speed   : hint_range(1.0, 200.0) = 80.0;
uniform float flash_duty    : hint_range(0.01, 0.5) = 0.08;
uniform float tail_round    : hint_range(0.0, 0.5) = 0.15;
uniform float opacity       : hint_range(0.0, 1.0) = 1.0;
uniform float custom_time   : hint_range(0.0, 1000.0) = 0.0;

float bullet_sdf(float lx, float ly, float body_start, float body_end) {
    float raw_t      = clamp((lx - body_start) / (body_end - body_start), 0.0, 1.0);
    float tip_factor = 1.0 - raw_t;
    float nearest_x  = clamp(lx, body_start, body_end);
    float nf         = 1.0 - clamp((nearest_x - body_start) / (body_end - body_start), 0.0, 1.0);
    float tip_w      = bullet_width * pow(nf, 1.0 / tip_sharpness);
    float nearest_y  = clamp(ly, -tip_w, tip_w);
    float cone_dist  = length(vec2(lx - nearest_x, ly - nearest_y));
    float tail_cx    = body_start + tail_round * (body_end - body_start);
    float tail_dist  = length(vec2(lx - tail_cx, ly)) - bullet_width;
    float t_blend    = smoothstep(0.0, tail_round * 1.5, raw_t);
    return mix(tail_dist, cone_dist - 0.001, t_blend);
}

vec4 bullet(vec2 uv, float cy, float seed) {
    float lx = uv.x;
    float ly = uv.y - cy;
    float body_start = -0.95;
    float body_end   =  bullet_length;
    float sdf = bullet_sdf(lx, ly, body_start, body_end);
    if (sdf > glow_radius) return vec4(0.0);
    float phase    = seed * 2.094;
    float cycle    = fract(custom_time * flash_speed / 6.2831853 + phase);
    float flash    = step(cycle, flash_duty);
    float raw_t      = clamp((lx - body_start) / (body_end - body_start), 0.0, 1.0);
    float tip_factor = 1.0 - raw_t;
    float half_w     = bullet_width * pow(tip_factor, 1.0 / tip_sharpness);
    bool  in_body    = (sdf <= 0.0);
    vec4 cur_body_color = mix(body_color,  flash_color, flash);
    vec4 cur_glow_color = mix(glow_color,  flash_color * 0.6, flash);
    vec4 cur_core_color = mix(core_color,  flash_color * 1.2, flash);
    if (!in_body) {
        float t = sdf / glow_radius;
        float a = glow_strength * pow(1.0 - t, 2.0);
        a = mix(a, glow_strength * 1.2, flash * (1.0 - t));
        vec4 g = mix(cur_body_color, cur_glow_color, t);
        return vec4(g.rgb * a, a) * opacity;
    }
    float t_body  = tip_factor;
    float t_cross = (half_w > 0.0) ? clamp(abs(ly) / half_w, 0.0, 1.0) : 0.0;
    vec4 col = mix(cur_core_color, cur_body_color, smoothstep(0.0, 0.5, t_cross));
    col = mix(col, cur_glow_color * 0.7, smoothstep(0.6, 1.0, t_cross));
    float spec = smoothstep(0.35, 0.0, abs(ly + half_w * 0.3))
               * smoothstep(1.0, 0.6, t_body)
               * smoothstep(0.0, 0.15, t_body);
    col.rgb = mix(col.rgb, vec3(1.0), spec * 0.55);
    float alpha = mix(0.65, 1.0, smoothstep(0.0, 0.25, 1.0 - t_body));
    return vec4(col.rgb, alpha) * opacity;
}

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    vec4 b1 = bullet(uv,  bullet_gap, 0.0);
    vec4 b2 = bullet(uv, -bullet_gap, 1.0);
    vec4 result;
    result.a   = b1.a + b2.a * (1.0 - b1.a);
    result.rgb = (result.a > 0.0)
        ? (b1.rgb * b1.a + b2.rgb * b2.a * (1.0 - b1.a)) / result.a
        : vec3(0.0);
    COLOR = result;
}