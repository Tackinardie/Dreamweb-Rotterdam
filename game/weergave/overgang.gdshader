shader_type canvas_item;
// Fade naar #07080C (fade) of droomfilter: desaturatie, sepia en ruis (droom), kamerweergave.md W20-W21.
uniform sampler2D scherm : hint_screen_texture, filter_linear_mipmap;
uniform float fade = 0.0;
uniform float droom = 0.0;

void fragment() {
	vec3 c = texture(scherm, SCREEN_UV).rgb;
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 sepia = vec3(g * 1.12, g * 0.95, g * 0.72);
	float n = fract(sin(dot(SCREEN_UV * vec2(1920.0, 1080.0) + TIME * 60.0, vec2(12.9898, 78.233))) * 43758.5453);
	vec3 d = mix(c, sepia, droom * 0.9) + (n - 0.5) * 0.3 * droom;
	COLOR = vec4(mix(d, vec3(0.027, 0.031, 0.047), fade), 1.0);
}
