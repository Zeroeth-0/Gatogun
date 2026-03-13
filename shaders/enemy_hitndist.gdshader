shader_type canvas_item;

// === HIT FLASH ===
uniform float hit_effect      : hint_range(0.0, 1.0) = 0.0;
uniform float shake_intensity                         = 10.0;
uniform float flash_speed                             = 30.0;
uniform float time_offset                             = 0.0;
uniform vec4  flash_color : source_color              = vec4(0.3, 0.7, 1.0, 1.0);
uniform float custom_time : hint_range(0.0, 1000.0)  = 0.0;

// === OUTLINE DE PROXIMIDAD ===
uniform float outline_fill   : hint_range(0.0, 1.0) = 0.0;
uniform float outline_active : hint_range(0.0, 1.0) = 0.0;
uniform float outline_width  : hint_range(0.0, 8.0) = 2.0;
uniform vec4  outline_color  : source_color          = vec4(1.0, 0.85, 0.1, 1.0);
uniform bool  inline_mode                            = false;

// ─────────────────────────────────────────────────────────────────────────────

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float edge_mask(sampler2D tex, vec2 uv, vec2 px, float width) {
    float self_alpha = texture(tex, uv).a;
    if (!inline_mode) {
        if (self_alpha > 0.5) return 0.0;
        for (int x = -1; x <= 1; x++) {
            for (int y = -1; y <= 1; y++) {
                if (x == 0 && y == 0) continue;
                vec2 offset = vec2(float(x), float(y)) * px * width;
                if (texture(tex, uv + offset).a > 0.5) return 1.0;
            }
        }
    } else {
        if (self_alpha < 0.5) return 0.0;
        for (int x = -1; x <= 1; x++) {
            for (int y = -1; y <= 1; y++) {
                if (x == 0 && y == 0) continue;
                vec2 offset = vec2(float(x), float(y)) * px * width;
                if (texture(tex, uv + offset).a < 0.5) return 1.0;
            }
        }
    }
    return 0.0;
}

// ─────────────────────────────────────────────────────────────────────────────

void vertex() {
    if (hit_effect > 0.0) {
        float t   = custom_time * 30.0 + time_offset;
        vec2  rnd = vec2(rand(vec2(t, 0.0))  * 2.0 - 1.0,
                         rand(vec2(t, 10.0)) * 2.0 - 1.0);
        VERTEX += rnd * shake_intensity * hit_effect;
    }
}

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);

    // --- Outline de proximidad ---
    if (outline_fill > 0.0) {
        float is_edge = edge_mask(TEXTURE, UV, TEXTURE_PIXEL_SIZE, outline_width);

        if (is_edge > 0.5) {
            // Llenado angular: ángulo respecto al centro, sentido horario desde arriba
            vec2  dir        = UV - vec2(0.5, 0.5);
            float angle_rad  = atan(dir.x, -dir.y);
            float angle_norm = angle_rad / (2.0 * 3.14159265) + 0.5;
            float visible    = step(angle_norm, outline_fill);

            vec3  oc = outline_color.rgb;
            float oa = outline_color.a * visible;

            // Pulso al alcanzar el umbral
            if (outline_active > 0.5) {
                float pulse = sin(custom_time * 10.0) * 0.5 + 0.5;
                float glow  = 0.6 + 0.4 * pulse;
                oc  = mix(oc, vec3(1.0), pulse * 0.55);
                oa  = min(oa * glow * 1.4, 1.0);
            }

            vec4 outline_px = vec4(oc, oa);

            if (!inline_mode) {
                COLOR = mix(original_color, outline_px, outline_px.a);
            } else {
                COLOR = mix(original_color, outline_px, outline_px.a * outline_fill);
            }
        } else {
            COLOR = original_color;
        }
    } else {
        COLOR = original_color;
    }

    // --- Hit flash (encima del outline) ---
    if (hit_effect > 0.0) {
        float flash  = sin((custom_time + time_offset) * flash_speed) * 0.5 + 0.5;
        flash       *= COLOR.a;
        vec4 flashed = mix(COLOR, flash_color, flash);
        flashed      = mix(COLOR, flashed, hit_effect);
        flashed.a    = COLOR.a;
        COLOR        = flashed;
    }
}