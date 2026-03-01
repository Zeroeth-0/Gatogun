shader_type canvas_item;
group_uniforms Shine;
uniform vec3 shine_color: source_color = vec3(1.0, 1.0, 1.0);
uniform float shine_angle = -45.0;
uniform float shine_duration = 5.0;
uniform float shine_speed = 800.0;
uniform float shine_width = 20.0;
uniform float shine_scale : hint_range(0.1, 10.0) = 1.0;
uniform float time_offset : hint_range(0.0, 100.0) = 0.0;
uniform float custom_time = 0.0;
group_uniforms;

varying vec2 local_pos;

void vertex() {
    local_pos = VERTEX;
}

void fragment()
{
    COLOR = texture(TEXTURE, UV);

    float angle_rad = radians(shine_angle);
    float projected = (sin(angle_rad) * local_pos.x + cos(angle_rad) * local_pos.y) / shine_scale;

    float travel = mod((custom_time + time_offset) * shine_speed, shine_duration * shine_speed);
    float offset = travel - shine_duration * shine_speed * 0.5;

    float dist = abs(projected + offset);

    if (dist <= shine_width) {
        if (COLOR.a > 0.01) {
            COLOR.rgb = mix(COLOR.rgb, shine_color, 0.7);
        }
    }
}