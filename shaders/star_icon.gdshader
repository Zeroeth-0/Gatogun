shader_type canvas_item;

uniform vec4 star_color : source_color = vec4(1.0, 0.9, 0.2, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float spin_speed : hint_range(-10.0, 10.0) = 1.0;
uniform float roundness : hint_range(1.2, 8.0) = 2.5;  // más alto = más redondeada
uniform float star_radius : hint_range(0.05, 1.0) = 0.9;

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

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;

    float t = TIME * spin_speed;
    float c = cos(t);
    float s = sin(t);
    uv = vec2(c * uv.x - s * uv.y, s * uv.x + c * uv.y);

    float aa = 0.01;
    float sd = sdf_star(uv, star_radius, 5.0, roundness);

    float fill   = 1.0 - smoothstep(0.0, aa, sd);
    float border = (1.0 - smoothstep(0.02, 0.02 + aa, sd)) * smoothstep(0.0, aa, sd);
    float intensity = fill + border;

    vec3 rgb = mix(star_color.rgb * 0.4, star_color.rgb, intensity);
    float alpha = clamp(intensity, 0.0, 1.0) * opacity * star_color.a;

    COLOR = vec4(rgb, alpha);
}