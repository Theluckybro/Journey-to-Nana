shader_type canvas_item;

uniform vec4 outline_color: source_color = vec4(1.0, 0.9, 0.2, 1.0);
uniform float outline_size_px = 2.5;
uniform float fill_strength = 0.4;
uniform float pulse_strength = 0.2;
uniform float pulse_speed = 6.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float a = base.a;
	float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_strength;

	vec2 px = TEXTURE_PIXEL_SIZE * outline_size_px;
	vec2 px_outer = px * 1.6;
	float max_a = a;

	max_a = max(max_a, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(-px.x, 0.0)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, -px.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(px.x, px.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(-px.x, px.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(px.x, -px.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(-px.x, -px.y)).a);

	max_a = max(max_a, texture(TEXTURE, UV + vec2(px_outer.x, 0.0)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(-px_outer.x, 0.0)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, px_outer.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, -px_outer.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(px_outer.x, px_outer.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(-px_outer.x, px_outer.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(px_outer.x, -px_outer.y)).a);
	max_a = max(max_a, texture(TEXTURE, UV + vec2(-px_outer.x, -px_outer.y)).a);

	float outline = clamp((max_a - a) * pulse, 0.0, 1.0);
	float fill = clamp(fill_strength * pulse, 0.0, 1.0) * a;
	vec3 filled_rgb = mix(base.rgb, outline_color.rgb, fill);
	vec3 edge_rgb = mix(filled_rgb, vec3(1.0), outline * 0.55);

	COLOR.rgb = mix(filled_rgb, edge_rgb, outline);
	COLOR.a = max(base.a, outline * outline_color.a);
}

