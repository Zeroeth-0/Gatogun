shader_type canvas_item;

uniform vec3 backFillColour    : source_color = vec3(0.62, 1.00, 1.00);
uniform vec3 frontFillInnerColour : source_color = vec3(0.35, 1.00, 1.00);
uniform vec3 frontFillOuterColour : source_color = vec3(0.00, 0.35, 1.00);
uniform vec3 ringColour        : source_color = vec3(0.00, 0.16, 0.13);
uniform vec3 fresnelColour     : source_color = vec3(0.00, 0.88, 1.00);
uniform vec3 innerRingGlowColour : source_color = vec3(0.00, 1.00, 1.00);
uniform vec4 fillcolour        : source_color = vec4(1);
uniform float ringWidth = 0.15;
uniform float innerCircleRadiusOffset = 0.0;
uniform float fill_value : hint_range(-1, 1) = 0.25;

float sdArc(in vec2 p, in vec2 sc, in float ra, float rb) {
    p.x = abs(p.x);
    return ((sc.y * p.x > sc.x * p.y) ? length(p - sc * ra) :
                                         abs(length(p) - ra)) - rb;
}

mat2 Get2DRotationMatrix(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(vec2(c, s), vec2(-s, c));
}

void fragment() {
    vec2 uv = (UV / -0.48) + vec2(1.038, 1.038);

    float circleSDF = length(uv);

    float oneMinusRingWidth = 1.0 - ringWidth;
    float circleA = step(circleSDF, 1.0);
    float circleB = step(circleSDF, oneMinusRingWidth);
    float ring = circleA - circleB;

    float fillMaskCircle = step(circleSDF, oneMinusRingWidth - innerCircleRadiusOffset);

    // === RING GLOW ===
    float ringGlowSDF = circleSDF - 1.0;

    float innerRingGlow = ringGlowSDF + 0.15;
    // pow(0.01 / x, 1.2) aproximado con multiplicaciones
    innerRingGlow = clamp((0.01 / innerRingGlow) * pow(0.01 / innerRingGlow, 0.2) - fillMaskCircle, 0.0, 1.0);

    // outerRingGlow sin animación de power (ahorra 1 sin() por pixel)
    float outerRingGlow = pow(0.01 / ringGlowSDF, 0.8);
    outerRingGlow = clamp(outerRingGlow - fillMaskCircle, 0.0, 1.0);

    // === FILL / WAVES ===
    float fillAnimationPhase = TIME * 4.0;
    float fillAnimation = sin(fillAnimationPhase) * 0.05;

    float frontWavePhase = ((TIME * 2.0) + uv.x) * 2.0;
    float backWavePhase  = ((TIME * -2.0) + uv.x) * 2.0;

    float frontWaves = sin(frontWavePhase) * 0.05;
    float backWaves  = sin(backWavePhase + PI) * 0.05;

    float verticalBand = smoothstep(0.1, 0.9, sin(uv.x + (PI * 0.5)) - 0.3);

    float animatedVerticalBand = verticalBand * 0.125 * sin(fillAnimationPhase);
    frontWaves += animatedVerticalBand;
    backWaves  -= animatedVerticalBand;

    fillAnimation *= verticalBand;

    float fillProgress = fill_value + sin(TIME * PI) * 0.1;

    float frontFill = step(uv.y, fillAnimation + frontWaves + fillProgress) * fillMaskCircle;
    float backFill  = step(uv.y, -fillAnimation + backWaves + fillProgress) * fillMaskCircle;

    backFill = clamp(backFill - frontFill, 0.0, 1.0);

    float fillMask = (1.0 - (frontFill + backFill)) * fillMaskCircle;
    float fill = frontFill + backFill;

    // === FRESNEL (pow x5 → multiplicaciones) ===
    float f = (circleSDF + 0.01) * fillMask;
    float f2 = f * f;
    float fresnel = clamp(f2 * f2 * f, 0.0, 1.0);

    float ff = (circleSDF + 0.02) * (1.0 - fillMask);
    float ff2 = ff * ff;
    float frontFillFresnel = clamp(ff2 * ff2 * ff, 0.0, 1.0);

    // === SPECULAR ===
    const vec2 sc1 = vec2(sin(radians(15.0)), cos(radians(15.0)));
    const vec2 sc2 = vec2(sin(radians(2.0)),  cos(radians(2.0)));

    vec2 uv1 = Get2DRotationMatrix(radians(60.0)) * uv;
    vec2 uv2 = Get2DRotationMatrix(radians(28.0)) * uv;

    float specular = (step(sdArc(uv1, sc1, 0.65, 0.07), 0.0)
                   +  step(sdArc(uv2, sc2, 0.65, 0.07), 0.0)) * 0.2;

    // === COLOR FINAL ===
    float mask = ring + fill + fresnel + specular;

    vec3 frontFillColour = mix(frontFillInnerColour, frontFillOuterColour, frontFillFresnel);

    const vec3 outerRingGlowColour = vec3(1.0, 0.8, 0.1);
    const vec3 specularColour      = vec3(1.0, 1.0, 0.9);

    vec3 rgb =
        (ring         * ringColour) +
        (innerRingGlow * innerRingGlowColour) +
        (outerRingGlow * outerRingGlowColour) +
        ((frontFill * frontFillColour + backFill * backFillColour) * fillcolour.rbg) +
        (fresnel   * fresnelColour) +
        (specular  * specularColour);

    COLOR = vec4(rgb, mask);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
