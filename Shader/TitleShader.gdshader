shader_type canvas_item;

uniform float shine_progress : hint_range(0.0, 1.0) = 0.0;
uniform float shine_width : hint_range(0.0, 1.0) = 0.2;
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 0.7);
uniform float shine_softness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);

    if (base_color.a > 0.9) {
        float x_coord = UV.x;
        float dist_from_shine_center = abs(x_coord - shine_progress);
        float shine_intensity = 0.0;

        if (dist_from_shine_center < shine_width / 2.0) {
            shine_intensity = 1.0 - smoothstep(0.0, shine_width / 2.0 * (1.0 - shine_softness), dist_from_shine_center);
        }

        vec3 text_color = vec3(0.78039217, 0.8784314, 0.78039217);
        vec3 final_rgb = mix(text_color, shine_color.rgb, shine_intensity * shine_color.a);

        COLOR = vec4(final_rgb, base_color.a);

    } else {
        COLOR = base_color;
    }
}