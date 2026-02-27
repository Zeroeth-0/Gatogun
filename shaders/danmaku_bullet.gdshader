shader_type canvas_item;

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  DANMAKU BULLET SHADER — Godot 4                                       │
// │                                                                         │
// │  Uso: Sprite2D con textura blanca sólida.                              │
// │  • Circle / Ring / Star: textura CUADRADA (ej. 64×64)                 │
// │  • Capsule stretch=2: textura 1:2 (ej. 32×64) — ajusta el             │
// │    aspect ratio del Sprite2D al valor de capsule_stretch               │
// │  • Rotar el nodo Sprite2D desde código para la dirección               │
// │  • render_mode blend_add en el material = glow aditivo acumulativo     │
// └─────────────────────────────────────────────────────────────────────────┘

// ══════════════════════════════════════════════════════════════════════
//  FORMA
// ══════════════════════════════════════════════════════════════════════
uniform int shape : hint_range(0, 3) = 0;
// 0 Círculo   1 Cápsula   2 Aro   3 Estrella

uniform float capsule_stretch : hint_range(1.0, 5.0, 0.05) = 2.0;
// Cápsula: 1.0=esfera  2.0=píldora/arroz  4.0=aguja/daga
// Usa una textura con ese mismo ratio de aspecto para que no se corte.

uniform float ring_hole : hint_range(0.15, 0.80, 0.01) = 0.50;
// Aro: tamaño del hueco interior (fracción del radio exterior).
// 0.50 = aro clásico  0.75 = aro muy fino

uniform int   star_n      : hint_range(3, 8) = 5;
uniform float star_inner  : hint_range(0.10, 0.75, 0.01) = 0.42;
// Estrella: N puntas.  star_inner < 0.25 = kunai/shuriken afilado.

// ══════════════════════════════════════════════════════════════════════
//  COLOR  — borde oscuro y núcleo sobreexpuesto se derivan automáticamente
// ══════════════════════════════════════════════════════════════════════
uniform vec4  bullet_color : source_color = vec4(0.88, 0.10, 0.88, 1.0);

uniform float border_frac  : hint_range(0.04, 0.40, 0.01) = 0.18;
// Grosor del borde oscuro (fracción de la profundidad efectiva del shape).
// Círculo: 0.18 = 18% del radio.  Anilla/estrella: se escala automáticamente.

uniform float core_frac    : hint_range(0.05, 0.55, 0.01) = 0.28;
// Radio del núcleo brillante (fracción de R). Siempre circular.

uniform float core_bright  : hint_range(1.0, 5.0, 0.05) = 2.80;
// Sobreexposición del núcleo: 1.0=color plano  2.8=blanco caliente clásico

// ══════════════════════════════════════════════════════════════════════
//  GLOW EXTERIOR
// ══════════════════════════════════════════════════════════════════════
uniform float glow_frac    : hint_range(0.0, 1.0, 0.01) = 0.30;
// Radio del halo exterior (fracción de R). 0 = sin glow.

uniform float glow_int     : hint_range(0.0, 3.0, 0.05) = 0.80;
uniform float glow_power   : hint_range(1.0, 6.0, 0.10) = 2.00;
// Mayor power = halo más apretado al borde.

// ══════════════════════════════════════════════════════════════════════
//  ANIMACIONES
// ══════════════════════════════════════════════════════════════════════

// Pulso: el núcleo respira
uniform float pulse_speed  : hint_range(0.0, 12.0, 0.10)  = 5.0;
uniform float pulse_amount : hint_range(0.0, 0.30, 0.005) = 0.08;

// Ripple: anillos concéntricos que emanan desde el núcleo (estilo CAVE)
uniform float ripple_speed  : hint_range(0.0, 12.0, 0.10) = 3.5;
uniform float ripple_bands  : hint_range(1.0, 12.0, 0.50) = 4.0;
uniform float ripple_amount : hint_range(0.0, 0.60, 0.01) = 0.18;

// Shimmer: destello especular que barre la superficie
uniform float shimmer_speed  : hint_range(0.0, 8.0, 0.10) = 2.0;
uniform float shimmer_amount : hint_range(0.0, 0.60, 0.01) = 0.12;

// Wobble: deformación orgánica del borde (estilo CAVE)  0 = desactivado
uniform float wobble_speed  : hint_range(0.0, 6.0,  0.10)  = 2.0;
uniform float wobble_freq   : hint_range(2.0, 10.0, 0.50)  = 4.0;
uniform float wobble_amount : hint_range(0.0, 0.06, 0.001) = 0.0;

// Ciclo de tono automático  0 = desactivado
uniform float hue_speed : hint_range(0.0, 2.0, 0.01) = 0.0;

// ══════════════════════════════════════════════════════════════════════

const float R  = 0.70;   // Radio del bullet en espacio UV [-1,1].
const float AA = 0.022;  // Semiancho de suavizado de bordes.

// ─────────────────────────────────────────────────────────────────────
// Helpers HSV
// ─────────────────────────────────────────────────────────────────────
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0., -1./3., 2./3., -1.);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    return vec3(abs(q.z + (q.w - q.y)/(6.*d + 1e-10)),
                d / (q.x + 1e-10),
                q.x);
}
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1., 2./3., 1./3., 3.);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6. - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0., 1.), c.y);
}

// ─────────────────────────────────────────────────────────────────────
// SDFs — negativo=dentro, 0=borde, positivo=fuera
// ─────────────────────────────────────────────────────────────────────

float sdf_circle(vec2 p) {
    return length(p) - R;
    // Centro → -R ✓
}

float sdf_capsule(vec2 p) {
    // Cápsula vertical con radio R y sección recta de semilongitud h.
    // El borde tiene grosor constante en todos los puntos — clave para que
    // las bandas de color sean uniformes en toda la píldora.
    float h = R * max(0.0, capsule_stretch - 1.0);
    return length(vec2(p.x, p.y - clamp(p.y, -h, h))) - R;
    // Centro (0,0) → -R ✓   Punta (0, h+R) → 0 ✓   Ecuador (R,0) → 0 ✓
}

float sdf_ring(vec2 p) {
    float mid  = R * (1.0 + ring_hole) * 0.5;   // radio medio de la pared
    float half = R * (1.0 - ring_hole) * 0.5;   // semiancho de la pared
    return abs(length(p) - mid) - half;
    // Borde exterior → 0 ✓   Borde interior → 0 ✓   Centro de la pared → -half ✓
}

float sdf_star(vec2 p) {
    // Estrella de N puntas por plegado de sector.
    // La primera punta apunta en la dirección +Y del sprite
    // (que será la dirección de movimiento si el nodo está sin rotar).
    float sa = PI / float(star_n);
    float a  = atan(p.x, p.y);          // ángulo desde eje +Y
    a = mod(a + sa, 2.0 * sa) - sa;     // plegar al sector [-sa, sa]
    vec2  q     = length(p) * vec2(sin(a), cos(a));
    vec2  tip   = vec2(0.0, R);
    vec2  notch = R * star_inner * vec2(sin(sa), cos(sa));
    vec2  ba    = notch - tip;
    vec2  pa    = q - tip;
    float h     = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    float dist  = length(pa - ba * h);
    // IMPORTANTE: negamos el signo para que interior = negativo.
    // Sin esta negación el centro daría valor positivo (SDF invertido).
    return dist * (-sign(pa.x * ba.y - pa.y * ba.x));
}

// ─────────────────────────────────────────────────────────────────────
void fragment() {
    // Corrección de aspecto: TEXTURE_PIXEL_SIZE = (1/W, 1/H)
    // tex_ar = H/W. Para una textura 32×64 (alta): tex_ar = 2.0
    // Así p.x=1 y p.y=1 representan la misma distancia en píxeles.
    float tex_ar = TEXTURE_PIXEL_SIZE.x / TEXTURE_PIXEL_SIZE.y;
    vec2  p      = (UV * 2.0 - 1.0) * vec2(1.0, tex_ar);
    float r      = length(p);
    float ang    = atan(p.y, p.x);

    // ── Ciclo de tono ──────────────────────────────────────────────
    vec3 base = bullet_color.rgb;
    if (hue_speed > 0.001) {
        vec3 h = rgb2hsv(base);
        h.x = fract(h.x + TIME * hue_speed * 0.2);
        base = hsv2rgb(h);
    }

    // ── Wobble: deformación radial del borde ───────────────────────
    // Desplaza el punto de muestreo radialmente según la dirección angular,
    // dando al borde una forma orgánica y temblorosa.
    if (wobble_amount > 0.001) {
        float wb = sin(ang * wobble_freq + TIME * wobble_speed) * wobble_amount;
        p *= (1.0 - wb);   // contrae/expande el punto hacia el centro
        r  = length(p);
    }

    // ── SDF ────────────────────────────────────────────────────────
    float d;
    if      (shape == 1) d = sdf_capsule(p);
    else if (shape == 2) d = sdf_ring(p);
    else if (shape == 3) d = sdf_star(p);
    else                 d = sdf_circle(p);

    // Descartar todo lo que quede fuera del área de glow
    float glow_r = R * glow_frac;
    if (d > glow_r + AA) discard;

    // ── MÁSCARAS BASE ──────────────────────────────────────────────

    // Suavizado del borde exterior (anti-alias)
    float inside = smoothstep(AA, -AA, d);

    // abs_d: distancia hacia el interior desde el borde (0 en el borde)
    float abs_d = max(-d, 0.0);

    // Profundidad efectiva del shape (máxima abs_d alcanzable):
    // Cápsula y círculo: R. Aro: semiancho de la pared. Estrella: radio interior.
    float eff_depth;
    if      (shape == 2) eff_depth = R * (1.0 - ring_hole) * 0.5;
    else if (shape == 3) eff_depth = R * star_inner;
    else                 eff_depth = R;

    // Grosor absoluto del borde oscuro
    float bw = eff_depth * border_frac;

    // Máscara del borde: 1 en zona de borde, 0 más hacia adentro
    float t_border = inside * (1.0 - smoothstep(bw - AA, bw + AA, abs_d));

    // ── NÚCLEO ─────────────────────────────────────────────────────
    // El núcleo ES SIEMPRE CIRCULAR (basado en r, distancia al centro).
    // Esto replica el look de las referencias donde incluso las cápsulas
    // y estrellas tienen un destello redondo en el centro.
    float pf = sin(TIME * pulse_speed) * 0.5 + 0.5;

    float t_core;
    if (shape == 2) {
        // Aro: núcleo en el centro de la pared del aro
        float ring_mid  = R * (1.0 + ring_hole) * 0.5;
        float ring_half = R * (1.0 - ring_hole) * 0.5;
        float wd = abs(length(p) - ring_mid);   // 0 en el centro de la pared
        float cr = ring_half * core_frac * (1.0 + pf * pulse_amount);
        // smoothstep invertido: 1 cerca del centro de pared, 0 cerca del borde
        t_core = inside * smoothstep(cr + AA, cr - AA, wd);
    } else {
        float cr = R * core_frac * (1.0 + pf * pulse_amount);
        t_core = inside * smoothstep(cr + AA, cr - AA, r);
    }
    t_core = pow(max(t_core, 0.0), 1.5);   // cuadrático → borde del núcleo más definido

    // ── ANIMACIONES ────────────────────────────────────────────────

    // Ripple: bandas concéntricas desde el núcleo hacia afuera
    float rip_n;
    if (shape == 2) {
        float ring_mid  = R * (1.0 + ring_hole) * 0.5;
        float ring_half = R * (1.0 - ring_hole) * 0.5;
        rip_n = abs(length(p) - ring_mid) / max(ring_half, 0.001);
    } else {
        rip_n = r / R;
    }
    float rip = (sin(rip_n * ripple_bands * TAU - TIME * ripple_speed) * 0.5 + 0.5)
               * ripple_amount * inside * (1.0 - t_core);

    // Shimmer: haz especular que barre
    float shim = pow(max(0.0, sin(ang + TIME * shimmer_speed)), 8.0)
                * shimmer_amount * inside * (1.0 - t_core);

    // ── COLORES ────────────────────────────────────────────────────
    vec3 hsv = rgb2hsv(base);

    // Borde: mismo tono, muy oscuro y ligeramente desaturado.
    // El contraste borde oscuro / cuerpo brillante es la CLAVE de la
    // visibilidad en danmaku (principio valor-alto junto a valor-bajo).
    vec3 c_border = hsv2rgb(vec3(hsv.x, hsv.y * 0.50, hsv.z * 0.12));

    // Cuerpo: color pleno + modulación de animaciones
    vec3 c_body = base * (1.0 + rip * 0.55 + shim * 0.70);

    // Rim: línea brillante muy fina en la transición borde→cuerpo.
    // Característica visual distintiva de los bullets de CAVE
    // (Junction Butter en la terminología del diseño de sprites).
    float rim_t = inside
                * smoothstep(bw * 0.35, bw,        abs_d)   // se enciende al salir del borde
                * (1.0 - smoothstep(bw, bw * 1.75, abs_d)); // se apaga al entrar al cuerpo
    vec3 c_rim = mix(vec3(1.4), base * 2.1, 0.22);   // blanco con tinte del color base

    // Núcleo: gradiente desde color sobreexpuesto → blanco caliente en el centro
    float core_grad = (shape == 2) ? 0.5 : smoothstep(R * core_frac, 0.0, r);
    vec3  c_core    = mix(base * core_bright,               // borde del núcleo: color×bright
                          vec3(core_bright * 0.88),          // centro: casi blanco
                          core_grad * 0.70);

    // ── COMPOSICIÓN ────────────────────────────────────────────────
    // Orden de capas (de atrás a adelante):
    // cuerpo → borde oscuro → línea rim → núcleo brillante
    vec3 col = c_body;
    col = mix(col, c_border, t_border);
    col = mix(col, c_rim,    rim_t * (1.0 - t_border) * 0.75);
    col = mix(col, c_core,   t_core);

    // ── GLOW EXTERIOR ──────────────────────────────────────────────
    float gd  = max(d, 0.0);
    float gt  = pow(1.0 - smoothstep(0.0, max(glow_r, 0.001), gd), glow_power) * glow_int;

    // Mezcla final: dentro del shape = col, fuera = solo glow
    col   = mix(base * gt, col, inside);
    float alpha = max(inside, gt * (1.0 - inside) * 0.85);

    COLOR = vec4(col, alpha * bullet_color.a);
}