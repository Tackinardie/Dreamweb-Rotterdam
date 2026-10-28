extends RefCounted
# Gedeelde bouwhulpjes voor de stijltest. Alles vlakke kleuren, geen texturen.

static func c(hex: String) -> Color:
	return Color.html(hex)

static func mat(col: Color, rough := 0.8, metal := 0.0, emis := Color.BLACK, emis_e := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	if emis_e > 0.0:
		m.emission_enabled = true
		m.emission = emis
		m.emission_energy_multiplier = emis_e
	return m

static func glass(col: Color, alpha: float, rough := 0.05, emis := Color.BLACK, emis_e := 0.0) -> StandardMaterial3D:
	var m := mat(Color(col.r, col.g, col.b, alpha), rough, 0.0, emis, emis_e)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

static func add(parent: Node, mesh: Mesh, m: Material, pos: Vector3, rot_deg := Vector3.ZERO, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot_deg
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

static func box(parent: Node, pos: Vector3, size: Vector3, m: Material, rot_deg := Vector3.ZERO, shadow := true) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return add(parent, b, m, pos, rot_deg, shadow)

static func cyl(parent: Node, pos: Vector3, r: float, h: float, m: Material, rot_deg := Vector3.ZERO, top_r := -1.0, seg := 24, shadow := true) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.bottom_radius = r
	cm.top_radius = r if top_r < 0.0 else top_r
	cm.height = h
	cm.radial_segments = seg
	cm.rings = 1
	return add(parent, cm, m, pos, rot_deg, shadow)

static func sphere(parent: Node, pos: Vector3, r: float, m: Material, shadow := true) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 16
	s.rings = 8
	return add(parent, s, m, pos, Vector3.ZERO, shadow)

# Cilinder tussen twee punten (takken, leuningen, armen).
static func limb(parent: Node, a: Vector3, b: Vector3, r0: float, r1: float, m: Material, shadow := false) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.bottom_radius = r0
	cm.top_radius = r1
	cm.height = a.distance_to(b)
	cm.radial_segments = 6
	cm.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = m
	var y := (b - a).normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := y.cross(ref).normalized()
	var z := x.cross(y).normalized()
	mi.transform = Transform3D(Basis(x, y, z), (a + b) * 0.5)
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

static func omni(parent: Node, pos: Vector3, col: Color, energy: float, rng: float, shadow := false, atten := 1.5) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = atten
	l.shadow_enabled = shadow
	parent.add_child(l)
	return l

static func spot(parent: Node, pos: Vector3, target: Vector3, col: Color, energy: float, rng: float, angle: float, shadow := false) -> SpotLight3D:
	var l := SpotLight3D.new()
	l.position = pos
	l.light_color = col
	l.light_energy = energy
	l.spot_range = rng
	l.spot_angle = angle
	l.spot_attenuation = 0.8
	l.spot_angle_attenuation = 1.0
	l.shadow_enabled = shadow
	parent.add_child(l)
	var dir := (target - pos).normalized()
	l.look_at(target, Vector3(0, 0, 1) if absf(dir.y) > 0.95 else Vector3.UP)
	return l

static func make_env(bg: Color, amb: Color, amb_e: float, fog_density: float, fog_col: Color, exposure := 1.0, sky_top := Color("#151B2C"), sky_hor := Color("#3E5578"), sky_e := 4.0) -> WorldEnvironment:
	var e := Environment.new()
	# Achtergrond blijft egaal donker (kader); de lucht dient alleen als spiegelbeeld in nat oppervlak.
	var sk := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = sky_top
	psm.sky_horizon_color = sky_hor
	psm.ground_horizon_color = sky_hor
	psm.ground_bottom_color = sky_top
	psm.sky_energy_multiplier = sky_e
	sk.sky_material = psm
	e.sky = sk
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.background_mode = Environment.BG_COLOR
	e.background_color = bg
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = amb
	e.ambient_light_energy = amb_e
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = exposure
	e.glow_enabled = true
	e.glow_intensity = 0.8
	e.glow_strength = 1.1
	e.glow_bloom = 0.0
	e.glow_hdr_threshold = 1.0
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	e.ssr_enabled = true
	e.ssr_max_steps = 160
	e.ssr_fade_in = 0.05
	e.ssr_fade_out = 3.0
	e.ssr_depth_tolerance = 1.2
	e.ssao_enabled = true
	e.ssao_radius = 1.2
	e.ssao_intensity = 2.0
	e.volumetric_fog_enabled = true
	e.volumetric_fog_density = fog_density
	e.volumetric_fog_albedo = fog_col
	e.volumetric_fog_emission = Color(0, 0, 0)
	e.volumetric_fog_length = 70.0
	e.volumetric_fog_anisotropy = 0.55
	e.volumetric_fog_ambient_inject = 0.0
	e.adjustment_enabled = true
	e.adjustment_saturation = 0.92
	e.adjustment_contrast = 1.06
	var we := WorldEnvironment.new()
	we.environment = e
	return we

# Vaste camera: yaw (om de verticale as), pitch (omlaag), afstand, ortho-hoogte in meters (0 = perspectief met fov)
static func place_cam(cam: Camera3D, target: Vector3, yaw_deg: float, pitch_deg: float, dist: float, ortho_size: float, fov := 24.0) -> void:
	var yw := deg_to_rad(yaw_deg)
	var pt := deg_to_rad(pitch_deg)
	cam.position = target + Vector3(sin(yw) * cos(pt), sin(pt), cos(yw) * cos(pt)) * dist
	if ortho_size > 0.0:
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = ortho_size
	else:
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.fov = fov
	cam.near = 0.5
	cam.far = 300.0
	cam.look_at(target, Vector3.UP)

static func vignette(parent: Node, strength := 0.92, inner := 0.28, outer := 0.82) -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nuniform float strength = 0.9;\nuniform float inner = 0.28;\nuniform float outer = 0.82;\nvoid fragment() {\n\tvec2 p = (UV - 0.5) * vec2(1.6, 1.0);\n\tfloat d = length(p) * 1.25;\n\tfloat v = smoothstep(inner, outer, d);\n\tCOLOR = vec4(0.027, 0.031, 0.047, v * strength);\n}\n"
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("strength", strength)
	m.set_shader_parameter("inner", inner)
	m.set_shader_parameter("outer", outer)
	r.material = m
	cl.add_child(r)
	parent.add_child(cl)

static func args() -> Dictionary:
	var d := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			d[kv[0]] = kv[1]
	return d

static func start_shot(parent: Node, a: Dictionary) -> void:
	if a.has("shot"):
		var r := Node.new()
		r.set_script(load("res://shot_runner.gd"))
		r.path = a["shot"]
		r.frames = int(a.get("frames", 240))
		parent.add_child(r)
