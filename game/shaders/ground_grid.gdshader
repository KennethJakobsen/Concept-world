shader_type spatial;
// Grid-overlay paa jorden. Kun Compatibility-kompatible features.
uniform vec4 grass_color : source_color = vec4(0.47, 0.66, 0.33, 1.0);
uniform vec4 grass_color_alt : source_color = vec4(0.43, 0.62, 0.30, 1.0);
uniform vec4 line_color : source_color = vec4(0.25, 0.38, 0.18, 1.0);
uniform float line_width : hint_range(0.0, 0.2) = 0.03;
uniform float line_strength : hint_range(0.0, 1.0) = 0.45;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	vec2 cell = floor(p);
	float checker = mod(cell.x + cell.y, 2.0);
	vec3 base = mix(grass_color.rgb, grass_color_alt.rgb, checker);
	vec2 f = abs(fract(p) - 0.5);
	vec2 d = 0.5 - f; // afstand til naermeste linje
	vec2 aa = fwidth(p) * 1.0;
	vec2 l = 1.0 - smoothstep(vec2(line_width) - aa, vec2(line_width) + aa, d);
	float line = max(l.x, l.y) * line_strength;
	ALBEDO = mix(base, line_color.rgb, line);
	ROUGHNESS = 0.95;
}
