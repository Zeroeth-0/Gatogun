shader_type canvas_item;

// Parámetros de paleta
uniform vec3 boom_pal1 = vec3(.2, .15, .3);
uniform vec3 boom_pal2 = vec3(.9, .15, .05);
uniform vec3 boom_pal3 = vec3(.9, .5, .1);
uniform vec3 boom_pal4 = vec3(.95, .95, .35);

uniform vec3 smoke_pal1 = vec3(.2, .15, .3);
uniform vec3 smoke_pal2 = vec3(.35, .3, .45);
uniform vec3 smoke_pal3 = vec3(.5, .45, .6);

uniform float custom_time : hint_range(0.0, 10.0) = 0.0;
uniform float seed : hint_range(0.0, 1000.0) = 0.0;

uniform float size : hint_range(0.1, 50.0, 0.1) = 5.;
uniform float disperse : hint_range(0.1, 10.0, 0.1) = 1.;
uniform float duration : hint_range(0.1, 10.0, 0.1) = 1.0;

// Hash optimizado pero funcional
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

// Noise 2D en vez de 3D - misma calidad visual, mucho más rápido
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(mix(hash12(i + vec2(0,0)), 
                   hash12(i + vec2(1,0)), u.x),
               mix(hash12(i + vec2(0,1)), 
                   hash12(i + vec2(1,1)), u.x), u.y) * 2.0 - 1.0;
}

// Worley 2D en vez de 3D - de 27 a 9 iteraciones
float worley(vec2 p, float t) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    float min_dist = 1.0;
    
    for(int y = -1; y <= 1; y++) {
        for(int x = -1; x <= 1; x++) {
            vec2 offset = vec2(float(x), float(y));
            vec2 h = hash22(i + offset);
            h = 0.5 + 0.5 * sin(disperse * t + 6.2831 * h);
            vec2 r = offset + h - f;
            min_dist = min(min_dist, dot(r, r));
        }
    }
    
    return sqrt(min_dist);
}

float boom(vec2 p, float t)
{
    float progress = clamp(t / duration, 0.0, 1.0);
    float repeat = progress * 2.0;
    
    float shape = 1.0 - pow(length(p), 2.0) / (repeat * 12.0) - repeat * 2.0;
    
    float distortion = noise(p * 0.5 + t * 0.5);
    float bubbles = 0.5 - pow(worley(p * 1.2 + t * 2.0, t), 3.0);
    float bw = 0.5;
    float effects = (bw * bubbles + (1.0 - bw) * distortion);

    return shape + effects;
}

float smoke(vec2 p, float t)
{
    float progress = clamp(t / duration, 0.0, 1.0);
    float repeat = progress * 2.0;
    
    vec2 smoke_offset = vec2(0, -0.6) * pow(repeat / 1.45, 2.0) * 1.5;
    vec2 sp = p - smoke_offset;
    
    float shape = 1.0 - pow(length(sp), 2.0) / (repeat * 16.0) - pow(repeat * 1.5, 0.5);
    
    float distortion = noise(sp * 1.5 + t * 0.1);
    float bubbles = 0.5 - pow(worley((p / pow(repeat, 0.35)) - smoke_offset + t * 0.1, t), 2.0);
    float bw = 0.75;
    float effects = (bw * bubbles + (1.0 - bw) * distortion);

    return shape + effects;
}

float f(vec2 p, float t) {
    float b = boom(p, t);
    float s = smoke(p, t);
    return b > s ? b : s;
}

// Gradiente simplificado - menos preciso pero mucho más rápido
vec2 grad(vec2 x, float t)
{
    float h = 0.05; // h más grande = menos cálculos
    return vec2(f(x + vec2(h, 0), t) - f(x - vec2(h, 0), t),
                f(x + vec2(0, h), t) - f(x - vec2(0, h), t)) / (2.0 * h);
}

float border(vec2 uv, float t)
{
    float b = f(uv, t);
    vec2 g = grad(uv, t);
    float de = abs(b) / max(length(g), 0.001);
    float eps = 0.05;
    
    return smoothstep(eps, eps * 2.0, de);
}

float posterize(float v, int n)
{
    float fn = float(n);
    return floor(v * fn) / (fn - 1.0);
}

void fragment()
{
    vec3 boom_pal[4] = {
        boom_pal1,
        boom_pal2,
        boom_pal3,
        boom_pal4
    };

    vec3 smoke_pal[3] = {
        smoke_pal1,
        smoke_pal2,
        smoke_pal3
    };

    vec2 uv = UV;
    vec2 pos = (uv - vec2(0.5)) * size;
    
    int bpl = 4;
    int spl = 3;

    float boom_val = boom(pos, custom_time);
    float smoke_val = smoke(pos, custom_time);
    
    bool is_boom = boom_val > (smoke_val * 0.4);
    float main_val = is_boom ? boom_val : smoke_val;
    float alpha = step(0.0, main_val);
    
    vec3 color;
    
    if (main_val > 0.75) {
        color = vec3(1.0);
    } else if (is_boom) {
        int idx = clamp(int(posterize(boom_val, bpl) * float(bpl)), 0, bpl - 1);
        color = boom_pal[idx];
    } else {
        int idx = clamp(int(posterize(smoke_val, spl) * float(spl)), 0, spl - 1);
        color = smoke_pal[idx];
    }
    
    float b = step(1.0, border(pos, custom_time));
    
    float fade = 1.0 - smoothstep(duration * 0.8, duration, custom_time);
    alpha *= fade;
    
    color = mix(vec3(0.0), color, b);
    
    COLOR = vec4(color, alpha);
}