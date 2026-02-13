shader_type canvas_item;
group_uniforms Shine;
uniform vec3 shine_color: source_color = vec3(1.0, 1.0, 1.0);
uniform float shine_angle = -45.0;
uniform float shine_duration = 5.0;
uniform float shine_speed = 800.0;
uniform float shine_width = 20.0;
// Offset aleatorio para cada instancia
uniform float time_offset : hint_range(0.0, 100.0) = 0.0;
// NUEVO: Tiempo controlado desde GDScript (respeta pausa)
uniform float custom_time = 0.0;
group_uniforms;

void fragment()
{
    // Mantener el sprite original con su textura y alpha
    COLOR = texture(TEXTURE, UV);
    
    // Shine calculado sobre coordenadas LOCALES del sprite
    vec2 sprite_size = 1.0 / TEXTURE_PIXEL_SIZE;
    vec2 coord = UV * sprite_size;
    
    // Usar custom_time en vez de TIME
    float dist = abs(
        sin(radians(shine_angle)) * coord.x +
        cos(radians(shine_angle)) * coord.y +
        mod((custom_time + time_offset) * shine_speed, shine_duration * shine_speed) - shine_duration * shine_speed * 0.5
    );
    
    if (dist <= shine_width) {
        COLOR.rgb = mix(COLOR.rgb, shine_color, 0.7);
    }
}