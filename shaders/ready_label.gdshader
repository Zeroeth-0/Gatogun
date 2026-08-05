shader_type canvas_item;

uniform vec4 color_a : source_color = vec4(1.0, 0.08, 0.58, 1.0);
uniform vec4 color_b : source_color = vec4(1.0, 0.82, 0.0, 1.0);
uniform float stripe_angle : hint_range(0.1, 2.0) = 0.5;
uniform float stripe_speed : hint_range(0.0, 5.0) = 2.5;
uniform float custom_time : hint_range(0.0, 1000.0) = 0.0;

void fragment() {
	float coord = (UV.x / stripe_angle + UV.y + custom_time * stripe_speed);
	float stripe = step(0.5, fract(coord));
	COLOR = mix(color_a, color_b, stripe);
}