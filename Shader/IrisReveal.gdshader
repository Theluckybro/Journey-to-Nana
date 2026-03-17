shader_type canvas_item;

uniform vec2 center_position = vec2(320.0, 180.0);
uniform float circle_radius : hint_range(0.0, 4096.0) = 0.0;
uniform float edge_softness : hint_range(0.0, 64.0) = 0.0;

void fragment() {
	vec2 screen_size = vec2(1.0) / SCREEN_PIXEL_SIZE;
	vec2 pixel_pos = SCREEN_UV * screen_size;
	float dist = distance(pixel_pos, center_position);

	float alpha = 1.0;
	if (edge_softness > 0.0) {
		alpha = smoothstep(circle_radius - edge_softness, circle_radius + edge_softness, dist);
	} else {
		alpha = dist > circle_radius ? 1.0 : 0.0;
	}

	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
