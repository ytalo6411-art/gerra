shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D soil_grain : filter_linear_mipmap, repeat_enable;
varying vec2 terrain;

void vertex() {
	terrain = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float texture_grain = 0.82 + 0.27 * texture(soil_grain, terrain * vec2(0.47, 0.61)).r;
	ALBEDO = COLOR.rgb * texture_grain;
	ROUGHNESS = 1.0;
}
