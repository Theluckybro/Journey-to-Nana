shader_type canvas_item;

uniform vec4 silhouette_color: source_color = vec4(0.0, 0.0, 0.0, 0.5);

void fragment() {
	vec4 sprite_color = texture(TEXTURE, UV);
	COLOR = vec4(silhouette_color.rgb, silhouette_color.a * sprite_color.a);
}