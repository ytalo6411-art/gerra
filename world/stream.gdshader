shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform vec4 deep : source_color = vec4(0.19, 0.29, 0.28, 1.0);
uniform vec4 shallow : source_color = vec4(0.36, 0.46, 0.40, 1.0);
uniform vec4 glint : source_color = vec4(0.60, 0.69, 0.63, 1.0);
void fragment() {
	float edge = smoothstep(0.18, 0.52, abs(UV.x - 0.5));
	float bands = sin(UV.y * 1.8 - TIME * 1.2 + UV.x * 9.0) * sin(UV.y * 3.4 + TIME * 0.9 - UV.x * 13.0);
	float crest = smoothstep(0.61, 0.97, bands) * (0.22 + edge * 0.28);
	float fine = sin(UV.y * 10.9 - TIME * 3.0 + sin(UV.x * 19.0) * 0.82) * 0.028;
	ALBEDO = mix(mix(deep.rgb, shallow.rgb, edge), glint.rgb, crest * 0.68 + 0.02) + fine;
	ROUGHNESS = 0.31;
	SPECULAR = 0.36;
}
