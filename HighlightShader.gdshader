shader_type spatial;

void fragment() {
	if (UV.x > 0.05 && UV.x < 0.95
		&& UV.y > 0.05 && UV.y < 0.95) discard;
	ALBEDO = vec3(0, 0, 0);
	EMISSION = vec3(0.2, 0, 1);
	ALPHA = sin(TIME * 4.0) * 0.5 + 0.5;
}
