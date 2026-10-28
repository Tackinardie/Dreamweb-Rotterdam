shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never;
uniform vec3 col : source_color = vec3(1.0);
uniform float energy = 1.0;
uniform vec2 sz = vec2(1.0, 6.0);
varying vec3 lv;
void vertex() { lv = VERTEX; }
void fragment() {
	// FACE_Y-quad: lokale z loopt van lamp (-z) naar camera (+z)
	float along = clamp(lv.z / sz.y + 0.5, 0.0, 1.0);
	float across = abs(lv.x) / (sz.x * 0.5);
	float w = mix(1.0, 0.3, along);
	float a = smoothstep(1.0, 0.0, across / w) * pow(1.0 - along, 1.8);
	ALBEDO = col * a * energy;
}
