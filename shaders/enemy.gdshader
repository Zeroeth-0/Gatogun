shader_type canvas_item;

// === SOMBRA ===
uniform vec2 shadow_offset = vec2(20.0, 30.0);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.8);

// === HIT FLASH ===
uniform float hit_effect      : hint_range(0.0, 1.0) = 0.0;
uniform float shake_intensity                         = 10.0;
uniform float flash_speed                             = 30.0;
uniform float time_offset                             = 0.0;
uniform vec4  flash_color : source_color              = vec4(0.3, 0.7, 1.0, 1.0);
uniform float custom_time : hint_range(0.0, 1000.0)  = 0.0;

// === RESPIRACIÓN ===
uniform float breath_enabled   : hint_range(0.0, 1.0) = 1.0;
uniform float breath_speed     : hint_range(0.1, 5.0)  = 1.0;
uniform float breath_intensity : hint_range(0.0, 0.2) = 0.2;
uniform float breath_seed      : hint_range(0.0, 100.0) = 0.0;

// ─────────────────────────────────────────────────────────────────────────────
float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

// ─────────────────────────────────────────────────────────────────────────────
void vertex() {
    // --- Respiración ---
    if (breath_enabled > 0.0) {
        float t = custom_time * breath_speed + breath_seed;
        float breath = sin(t * 1.000) * 0.60
                     + sin(t * 1.337) * 0.28
                     + sin(t * 2.731) * 0.12;
        VERTEX *= 1.0 + breath * breath_intensity;
    }

    // --- Shake en hit ---
    if (hit_effect > 0.0) {
        float t   = custom_time * 30.0 + time_offset;
        vec2  rnd = vec2(rand(vec2(t, 0.0))  * 2.0 - 1.0,
                         rand(vec2(t, 10.0)) * 2.0 - 1.0);
        VERTEX += rnd * shake_intensity * hit_effect;
    }
}

void fragment() {
    // --- Sombra ---
    vec2 shadow_uv = UV - shadow_offset / vec2(textureSize(TEXTURE, 0));
    vec4 shadow_px = texture(TEXTURE, shadow_uv) * shadow_color;

    // --- Original ---
    vec4 original = texture(TEXTURE, UV);

    // --- Hit flash (solo sobre el sprite, no la sombra) ---
    if (hit_effect > 0.0) {
        float flash  = sin((custom_time + time_offset) * flash_speed) * 0.5 + 0.5;
        flash       *= original.a;
        vec4 flashed = mix(original, flash_color, flash);
        flashed      = mix(original, flashed, hit_effect);
        flashed.a    = original.a;
        original     = flashed;
    }

    // --- Composite: sombra debajo, sprite encima ---
    COLOR = mix(shadow_px, original, original.a);
}