shader_type spatial;
// T-092: Scrollende vandoverflade i tømmerrenden. Compatibility-sikker (ingen
// skærm-/dybdeteksturer); UV.y = buelængde, så vandet strømmer langs renden.
render_mode cull_disabled;

uniform vec4 deep : source_color = vec4(0.12, 0.45, 0.72, 1.0);
uniform vec4 foam : source_color = vec4(0.75, 0.92, 1.0, 1.0);
uniform float speed = 1.2;

void fragment() {
	float v = UV.y * 3.0 - TIME * speed;
	float w = sin(v * 6.2832 + sin(UV.x * 9.0) * 1.3) * 0.5 + 0.5;
	float edge = smoothstep(0.38, 0.5, abs(UV.x - 0.5));
	float f = clamp(pow(w, 6.0) * 0.6 + edge * 0.7, 0.0, 1.0);
	ALBEDO = mix(deep.rgb, foam.rgb, f);
	ROUGHNESS = 0.15;
	SPECULAR = 0.6;
}
