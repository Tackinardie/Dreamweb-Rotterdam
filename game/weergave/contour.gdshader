shader_type spatial;
// Contour (stijlgids 8.5): onbelichte tweede pass, opgeblazen achterkant, constant 2 px op 1080p, 70 % dekking.
render_mode unshaded, cull_front, depth_draw_never, shadows_disabled;

uniform vec4 kleur : source_color = vec4(0.957, 0.945, 0.902, 0.7);
uniform float dikte_px = 2.0;
uniform vec3 midden = vec3(0.0);

void vertex() {
	vec3 dir = normalize(VERTEX - midden + NORMAL * 0.001);
	vec3 dir_view = normalize((MODELVIEW_MATRIX * vec4(dir, 0.0)).xyz);
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip_dir = PROJECTION_MATRIX * vec4(dir_view, 0.0);
	vec2 d = normalize(clip_dir.xy + vec2(0.00001));
	float px = dikte_px * VIEWPORT_SIZE.y / 1080.0;
	clip.xy += d * px * 2.0 / VIEWPORT_SIZE * clip.w;
	POSITION = clip;
}

void fragment() {
	ALBEDO = kleur.rgb;
	ALPHA = kleur.a;
}
