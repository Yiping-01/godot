shader_type canvas_item;

uniform vec4 base_color: source_color = vec4(0.86, 0.18, 0.22, 1.0);
uniform vec3 shine_color: source_color = vec3(1.0, 0.32, 0.36);
uniform float shine_alpha = 0.35;
uniform float shine_angle = -35.0;
uniform float shine_duration = 2.2;
uniform float shine_speed = 170.0;
uniform float shine_width = 18.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a <= 0.01) {
		COLOR = vec4(0.0);
		return;
	}

	vec2 coord = SCREEN_UV / SCREEN_PIXEL_SIZE;
	float dist = abs(
		sin(radians(shine_angle)) * coord.x +
		cos(radians(shine_angle)) * coord.y +
		mod(TIME * shine_speed, shine_duration * shine_speed) - shine_duration * shine_speed * 0.5
	);

	vec3 tinted = tex.rgb * base_color.rgb;
	if (dist <= shine_width) {
		tinted = mix(tinted, shine_color, shine_alpha);
	}

	COLOR = vec4(tinted, tex.a * base_color.a);
}
