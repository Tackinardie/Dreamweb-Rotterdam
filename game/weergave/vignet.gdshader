shader_type canvas_item;
// Vignet naar #07080C (stijlgids 5.2): sterkte 0,9, binnen 0,28, buiten 0,82.
uniform float sterkte = 0.9;
uniform float binnen = 0.28;
uniform float buiten = 0.82;

void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.6, 1.0);
	float d = length(p) * 1.25;
	float v = smoothstep(binnen, buiten, d);
	COLOR = vec4(0.027, 0.031, 0.047, v * sterkte);
}
