shader_type spatial;
// Graesterraen med tekstur + grid-overlay. Kun Compatibility-kompatible features.
// T-059: tilebar graestekstur (egen, procedurel) i to skalaer + bloed
// storskala-variation, saa grid'et ikke dominerer. Gridlinjerne bevares svagt.
uniform vec4 grass_color : source_color = vec4(0.47, 0.66, 0.33, 1.0);
uniform vec4 grass_color_alt : source_color = vec4(0.40, 0.60, 0.29, 1.0);
uniform vec4 line_color : source_color = vec4(0.25, 0.38, 0.18, 1.0);
uniform float line_width : hint_range(0.0, 0.2) = 0.02;
uniform float line_strength : hint_range(0.0, 1.0) = 0.16;
uniform float checker_strength : hint_range(0.0, 1.0) = 0.15;
uniform sampler2D grass_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float tex_scale = 0.5; // gentagelser pr. meter (1 tile = 2 m)

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	vec2 cell = floor(p);
	float checker = mod(cell.x + cell.y, 2.0) * checker_strength;
	// Storskala-pletter: graestekstur samplet meget stort og roteret.
	float big = texture(grass_tex, mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * p * 0.045).g;
	float patch = smoothstep(0.78, 0.95, big);
	vec3 base = mix(grass_color.rgb, grass_color_alt.rgb, clamp(checker + patch, 0.0, 1.0));
	vec3 t = texture(grass_tex, p * tex_scale).rgb;
	vec3 t2 = texture(grass_tex, p * tex_scale * 0.27 + vec2(0.37, 0.71)).rgb;
	base *= t * mix(vec3(1.0), t2, 0.5) * 1.22;
	vec2 f = abs(fract(p) - 0.5);
	vec2 d = 0.5 - f; // afstand til naermeste linje
	vec2 aa = fwidth(p) * 1.0;
	vec2 l = 1.0 - smoothstep(vec2(line_width) - aa, vec2(line_width) + aa, d);
	// Linjerne fader ud paa afstand, saa de ikke moirer.
	float fade = 1.0 - smoothstep(0.08, 0.25, max(aa.x, aa.y));
	float line = max(l.x, l.y) * line_strength * fade;
	ALBEDO = mix(base, line_color.rgb, line);
	ROUGHNESS = 0.95;
}
