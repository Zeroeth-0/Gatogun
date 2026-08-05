shader_type canvas_item;

// --- Inspector controls ---
uniform int scroll_mode : hint_enum("Diagonal,Vertical") = 0;
uniform float scroll_speed : hint_range(0.0, 5.0, 0.05) = 0.6;

// --- Pattern shape ---
uniform float tile_scale   : hint_range(1.0, 20.0, 0.1)  = 7.0;
uniform float stripe_width : hint_range(0.05, 0.95, 0.01) = 0.42;
uniform float edge_softness : hint_range(0.005, 0.3, 0.005) = 0.07;

// --- Wobble ---
uniform float wobble_amount    : hint_range(0.0, 0.3, 0.005) = 0.055;
uniform float wobble_frequency : hint_range(0.5, 20.0, 0.5)  = 5.5;
uniform float wobble_speed     : hint_range(0.0, 3.0, 0.05)  = 0.4;

// --- Colors (match the lime-yellow plaid) ---
uniform vec4 color_light : source_color = vec4(0.875, 0.965, 0.365, 1.0); // base / highlight
uniform vec4 color_mid   : source_color = vec4(0.750, 0.890, 0.235, 1.0); // single stripe
uniform vec4 color_dark  : source_color = vec4(0.640, 0.815, 0.145, 1.0); // crossing stripes

void fragment() {
    vec2 uv = UV * tile_scale;

    // ---- Scroll offset ----
    float t = TIME * scroll_speed;
    if (scroll_mode == 0) {
        uv += vec2(t, t);      // diagonal (↘)
    } else {
        uv += vec2(0.0, t);    // vertical  (↓)
    }

    // ---- Diagonal axes ----
    float diag1 = uv.x + uv.y;   // NW-SE direction
    float diag2 = uv.x - uv.y;   // NE-SW direction

    // ---- Wobbly distortion ----
    float wt = TIME * wobble_speed;
    float w1 = sin(diag2 * wobble_frequency + wt * 1.3) * wobble_amount
             + sin(diag2 * wobble_frequency * 0.47 - wt) * wobble_amount * 0.4;
    float w2 = sin(diag1 * wobble_frequency - wt * 0.9) * wobble_amount
             + sin(diag1 * wobble_frequency * 0.53 + wt) * wobble_amount * 0.4;

    // ---- Stripe mask (soft edges → wobbly look) ----
    float f1 = fract((diag1 + w1) * 0.5);
    float f2 = fract((diag2 + w2) * 0.5);

    float sw = stripe_width;
    float s  = edge_softness;

    float stripe1 = clamp(smoothstep(0.0, s, f1) - smoothstep(sw, sw + s, f1), 0.0, 1.0);
    float stripe2 = clamp(smoothstep(0.0, s, f2) - smoothstep(sw, sw + s, f2), 0.0, 1.0);

    // ---- Combine into three tones ----
    float both   = stripe1 * stripe2;
    float either = clamp(stripe1 + stripe2 - both, 0.0, 1.0);

    vec4 col = color_light;
    col = mix(col, color_mid,  either);
    col = mix(col, color_dark, both);

    COLOR = col;
}