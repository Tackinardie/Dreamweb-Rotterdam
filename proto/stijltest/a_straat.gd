extends Node3D
# Scene A: brede stadsstraat in de regen, nacht, net na middernacht 1 januari 2022.
# Straat loopt langs de z-as (naar achteren = -z). Monumentale gevel links (x=-14), bomen en metro rechts.
const L = preload("res://lib.gd")

var rng := RandomNumberGenerator.new()
var fairy: Array[Vector3] = []
var cam: Camera3D
var cam_i := 0

# Camerahoeken: [target, yaw, pitch, dist, ortho_size, fov]
var cams := [
	[Vector3(-5, 8.0, -9), 34.0, 38.0, 100.0, 38.0, 0.0],
	[Vector3(-7, 1.5, 0), 20.0, 30.0, 70.0, 15.0, 0.0],
	[Vector3(-3, 3.0, -8), 30.0, 30.0, 130.0, 0.0, 15.0],
]

func _ready() -> void:
	rng.seed = 20220101
	var a := L.args()
	add_child(L.make_env(L.c("#07080C"), L.c("#4A6590"), 2.2, 0.012, L.c("#7A93B8"), 1.3))
	# Zeer zwak koel maanlicht-achtig vullicht, geen schaduw: geeft vorm aan de gevel
	var dl := DirectionalLight3D.new()
	dl.light_color = L.c("#3E5578")
	dl.light_energy = 0.8
	dl.rotation_degrees = Vector3(-55, 40, 0)
	dl.shadow_enabled = false
	add_child(dl)

	build_ground()
	build_building()
	for p in [Vector3(7.6, 0, -6), Vector3(7.6, 0, -18), Vector3(7.6, 0, -30),
			Vector3(-7.4, 0, -3), Vector3(-7.4, 0, -22)]:
		build_tree(p, rng.randf_range(0.9, 1.1))
	flush_fairy()
	build_lamp(Vector3(-6.7, 0, 0.0), 1.0, true)
	build_lamp(Vector3(6.7, 0, -14.0), -1.0, false)
	build_lamp(Vector3(-6.7, 0, -24.0), 1.0, false)
	build_lamp(Vector3(6.7, 0, -36.0), -1.0, false)
	build_metro(Vector3(10.0, 0, -6.2))
	build_car(Vector3(2.8, 0, -3.0))
	build_richard(Vector3(-9.2, 0.15, 2.0))
	build_trash(Vector3(-8.4, 0.15, 3.8))
	build_puddles()
	build_streaks()
	build_far()
	build_rain()

	cam = Camera3D.new()
	add_child(cam)
	cam_i = int(a.get("cam", 0))
	apply_cam()
	L.vignette(self)
	L.start_shot(self, a)

func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_C:
		cam_i = (cam_i + 1) % cams.size()
		apply_cam()
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_2:
		get_tree().change_scene_to_file("res://b_kamer.tscn")

func apply_cam() -> void:
	var k: Array = cams[cam_i]
	L.place_cam(cam, k[0], k[1], k[2], k[3], k[4], k[5])

# ---------------------------------------------------------------- grond
func build_ground() -> void:
	var asphalt := L.mat(L.c("#1E232C"), 0.1)
	var walk := L.mat(L.c("#2E3540"), 0.3)
	var curb := L.mat(L.c("#46505E"), 0.5)
	var dark := L.mat(L.c("#0E1220"), 0.9)
	L.box(self, Vector3(0, -0.1, -20), Vector3(12, 0.2, 90), asphalt)
	# middenstreep, gestippeld (gedoofd wit)
	var line := L.mat(L.c("#8A8F9C"), 0.3)
	for i in range(0, 20):
		L.box(self, Vector3(0, 0.005, 12 - i * 4.5), Vector3(0.14, 0.01, 2.2), line, Vector3.ZERO, false)
	# stoepen
	L.box(self, Vector3(-10.5, -0.05, -20), Vector3(9, 0.4, 90), walk)  # links x -15..-6, top 0.15
	# rechterstoep met gat voor de metrotrap: x 6..15, gat x 8.7..11.3, z -8..-4.4
	var top := 0.15
	L.box(self, Vector3(7.35, top - 0.2, -20), Vector3(2.7, 0.4, 90), walk)
	L.box(self, Vector3(13.15, top - 0.2, -20), Vector3(3.7, 0.4, 90), walk)
	L.box(self, Vector3(10.0, top - 0.2, 5.3), Vector3(2.6, 0.4, 20.6), walk)
	L.box(self, Vector3(10.0, top - 0.2, -29.0), Vector3(2.6, 0.4, 42.0), walk)
	# straatkant
	L.box(self, Vector3(-6.05, 0.04, -20), Vector3(0.2, 0.2, 90), curb)
	L.box(self, Vector3(6.05, 0.04, -20), Vector3(0.2, 0.2, 90), curb)
	# donkere omgeving
	L.box(self, Vector3(-40, -0.4, -20), Vector3(50, 0.2, 120), dark)
	L.box(self, Vector3(40, -0.4, -20), Vector3(50, 0.2, 120), dark)
	# fietsrek-achtige paaltjes langs de linkerrand, ritme voor het oog
	var steel := L.mat(L.c("#2A3040"), 0.4, 0.6)
	for i in range(0, 9):
		L.cyl(self, Vector3(-5.4, 0.45, 8 - i * 5.2), 0.07, 0.9, steel, Vector3.ZERO, -1.0, 8)

# ---------------------------------------------------------------- gevel
func build_building() -> void:
	var stone := L.mat(L.c("#6E6355"), 0.85)
	var stone_d := L.mat(L.c("#4A4239"), 0.9)
	var stone_l := L.mat(L.c("#978A76"), 0.8)
	var slate := L.mat(L.c("#2A2F3A"), 0.5, 0.15)
	var cop := L.mat(L.c("#2F4A52"), 0.45, 0.25)
	var pane := L.mat(L.c("#0E1220"), 0.06, 0.0)
	var warm := L.mat(L.c("#4A3020"), 0.3, 0.0, L.c("#FFB866"), 1.6)
	# hoofdblok x -26..-14, z -32..-0.5
	L.box(self, Vector3(-20, 5.75, -16.25), Vector3(12, 11.5, 31.5), stone)
	L.box(self, Vector3(-13.75, 0.75, -16.25), Vector3(0.5, 1.5, 31.5), stone_d)       # plint
	L.box(self, Vector3(-13.85, 5.0, -16.25), Vector3(0.3, 0.3, 31.5), stone_l)         # lijst
	L.box(self, Vector3(-13.6, 11.55, -16.25), Vector3(0.8, 0.5, 31.5), stone_l)        # kroonlijst
	var prism := PrismMesh.new()
	prism.size = Vector3(12.4, 4.2, 31.5)
	L.add(self, prism, slate, Vector3(-20, 13.8, -16.25))
	# vensters: 3 verdiepingen, tekening met kozijn en ruit
	for row in range(3):
		var y := 3.0 + row * 3.1
		for i in range(12):
			var z := -1.8 - i * 2.55
			if z < -10.5 and z > -18.8:
				continue
			L.box(self, Vector3(-13.95, y, z), Vector3(0.1, 2.0 if row > 0 else 1.7, 1.45), stone_l, Vector3.ZERO, false)
			var lit := rng.randf() < 0.10
			L.box(self, Vector3(-13.91, y, z), Vector3(0.1, 1.8 if row > 0 else 1.5, 1.2), warm if lit else pane, Vector3.ZERO, false)
	# dakkapellen
	for z in [-5.0, -25.0, -9.0, -22.5, -29.0]:
		L.box(self, Vector3(-16.3, 13.0, z), Vector3(1.4, 1.6, 1.5), stone)
		var dp := PrismMesh.new()
		dp.size = Vector3(1.8, 0.8, 1.7)
		L.add(self, dp, slate, Vector3(-16.3, 14.2, z), Vector3(0, 90, 0))
		L.box(self, Vector3(-15.58, 13.0, z), Vector3(0.06, 1.1, 0.8), pane, Vector3.ZERO, false)
	# torentje
	var tx := -15.2
	var tz := -14.6
	L.box(self, Vector3(tx, 7.0, tz), Vector3(4.6, 14.0, 4.6), stone)
	L.box(self, Vector3(tx + 0.1, 14.3, tz), Vector3(5.2, 0.5, 5.2), stone_l)
	L.box(self, Vector3(tx, 16.1, tz), Vector3(3.0, 3.3, 3.0), stone)
	L.box(self, Vector3(tx, 18.0, tz), Vector3(3.5, 0.4, 3.5), stone_l)
	var clock := L.mat(L.c("#EEF4FF"), 0.3, 0.0, L.c("#FFD8A0"), 1.2)
	L.cyl(self, Vector3(tx + 2.35, 11.0, tz), 1.1, 0.12, clock, Vector3(0, 0, 90), -1.0, 32, false)
	L.box(self, Vector3(tx + 2.45, 11.0, tz), Vector3(0.05, 0.1, 0.9), stone_d, Vector3(0, 0, 0), false)
	L.box(self, Vector3(tx + 2.45, 11.3, tz), Vector3(0.05, 0.7, 0.1), stone_d, Vector3(0, 0, 0), false)
	for dz in [-0.8, 0.8]:
		L.box(self, Vector3(tx + 1.53, 16.1, tz + dz), Vector3(0.06, 1.7, 0.7), pane, Vector3.ZERO, false)
	for row in range(2):
		L.box(self, Vector3(tx + 2.32, 4.0 + row * 4.2, tz), Vector3(0.06, 2.2, 1.2), pane, Vector3.ZERO, false)
	var spire := CylinderMesh.new()
	spire.bottom_radius = 2.6
	spire.top_radius = 0.0
	spire.height = 6.0
	spire.radial_segments = 4
	spire.rings = 1
	L.add(self, spire, cop, Vector3(tx, 21.2, tz), Vector3(0, 45, 0))
	L.cyl(self, Vector3(tx, 25.2, tz), 0.06, 3.0, cop, Vector3.ZERO, 0.02, 6)
	# hoektorentjes op het dak
	for z in [-31.0, -1.5]:
		L.cyl(self, Vector3(-15.5, 13.8, z), 0.9, 4.6, stone, Vector3.ZERO, -1.0, 8)
		L.cyl(self, Vector3(-15.5, 17.4, z), 1.15, 2.6, cop, Vector3.ZERO, 0.0, 8)
	# opmaat: warm uplicht op gevel en toren (zoals de Coolsingel)
	L.spot(self, Vector3(-8.0, 0.3, -9.0), Vector3(-15.0, 9.0, -14.6), L.c("#FFB866"), 40.0, 36.0, 24.0, false)
	L.spot(self, Vector3(-8.0, 0.3, -20.0), Vector3(-14.0, 7.0, -22.0), L.c("#F08A30"), 25.0, 24.0, 34.0, false)
	L.spot(self, Vector3(-8.0, 0.3, -4.0), Vector3(-14.0, 6.0, -5.0), L.c("#F08A30"), 18.0, 22.0, 34.0, false)
	L.omni(self, Vector3(-12.6, 13.5, -14.6), L.c("#FFD8A0"), 2.0, 9.0)

# ---------------------------------------------------------------- bomen
func build_tree(base: Vector3, s: float) -> void:
	var bark := L.mat(L.c("#1A1E26"), 0.9)
	var h := 3.2 * s
	L.limb(self, base, base + Vector3(0, h, 0), 0.30 * s, 0.22 * s, bark, true)
	# lichtsnoer om de stam
	for i in range(34):
		var t := float(i) / 33.0
		var ang := t * TAU * 3.5
		fairy.append(base + Vector3(cos(ang) * 0.3, 0.2 + t * (h - 0.2), sin(ang) * 0.3) * Vector3(s, 1, s) + Vector3(0, 0, 0))
	grow(base + Vector3(0, h, 0), Vector3(0, 1, 0), 2.6 * s, 0.22 * s, 4, bark)
	L.omni(self, base + Vector3(0, 5.5 * s, 0), L.c("#C8D8F0"), 0.9, 7.0 * s)
	L.omni(self, base + Vector3(0, 2.0 * s, 0), L.c("#C8D8F0"), 0.7, 4.0)

func grow(p: Vector3, dir: Vector3, length: float, r: float, depth: int, bark: Material) -> void:
	var n_children := 3 if depth > 1 else 2
	var kids := n_children + (1 if depth == 4 else 0)
	for i in range(kids):
		var d := (dir + Vector3(rng.randf_range(-0.75, 0.75), rng.randf_range(-0.1, 0.45), rng.randf_range(-0.75, 0.75))).normalized()
		var l := length * rng.randf_range(0.7, 0.95)
		var q := p + d * l
		var r2 := r * 0.6
		L.limb(self, p, q, r, r2, bark)
		# lichtjes langs de tak
		var n_l := int(l / 0.45)
		for k in range(n_l):
			fairy.append(p.lerp(q, float(k) / maxf(1.0, n_l)) + Vector3(rng.randf_range(-0.08, 0.08), rng.randf_range(-0.08, 0.08), rng.randf_range(-0.08, 0.08)))
		if depth > 1:
			grow(q, d, l * 0.85, r2, depth - 1, bark)
		else:
			fairy.append(q)

func flush_fairy() -> void:
	var sm := SphereMesh.new()
	sm.radius = 0.045
	sm.height = 0.09
	sm.radial_segments = 6
	sm.rings = 3
	sm.material = L.mat(L.c("#EEF4FF"), 0.5, 0.0, L.c("#C8D8F0"), 7.0)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = sm
	mm.instance_count = fairy.size()
	for i in range(fairy.size()):
		mm.set_instance_transform(i, Transform3D(Basis(), fairy[i]))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

# ---------------------------------------------------------------- lantaarn
func build_lamp(base: Vector3, toward: float, main: bool) -> void:
	var steel := L.mat(L.c("#14171E"), 0.4, 0.5)
	var nat := L.mat(L.c("#FFB866"), 0.3, 0.0, L.c("#F08A30"), 9.0)
	L.cyl(self, base + Vector3(0, 3.75, 0), 0.09, 7.5, steel, Vector3.ZERO, 0.07, 10)
	L.cyl(self, base + Vector3(0, 0.3, 0), 0.16, 0.6, steel, Vector3.ZERO, -1.0, 10)
	var top := base + Vector3(0, 7.4, 0)
	var head := top + Vector3(toward * 2.1, 0.0, 0)
	L.limb(self, top + Vector3(0, -0.3, 0), top + Vector3(toward * 1.0, 0.35, 0), 0.06, 0.05, steel)
	L.limb(self, top + Vector3(toward * 1.0, 0.35, 0), head + Vector3(0, 0.15, 0), 0.05, 0.05, steel)
	L.box(self, head + Vector3(0, 0.0, 0), Vector3(1.2, 0.26, 0.5), nat, Vector3.ZERO, false)
	L.box(self, head + Vector3(0, 0.15, 0), Vector3(1.0, 0.06, 0.3), steel)
	if main:
		L.spot(self, head + Vector3(0, -0.2, 0), head + Vector3(0.0, -8.0, 0.3), L.c("#F08A30"), 75.0, 22.0, 62.0, true)
		L.omni(self, head + Vector3(0, -0.5, 0), L.c("#F08A30"), 0.8, 7.0)
	else:
		L.spot(self, head + Vector3(0, -0.2, 0), head + Vector3(0.0, -8.0, 0.3), L.c("#F08A30"), 45.0, 22.0, 60.0, false)

# ---------------------------------------------------------------- metro-ingang
func build_metro(c: Vector3) -> void:
	var steel := L.mat(L.c("#1A1E26"), 0.35, 0.6)
	var step := L.mat(L.c("#46505E"), 0.4)
	var edge := L.mat(L.c("#A8B8B4"), 0.4, 0.0, L.c("#D6E2DC"), 0.8)
	# trap omlaag richting -z, onder het stoepniveau (stoep top = 0)
	for i in range(8):
		var y := -0.07 - i * 0.22
		L.box(self, Vector3(10.0, y - 0.1, -4.6 - 0.35 - i * 0.45), Vector3(2.6, 0.2, 0.45), step)
		L.box(self, Vector3(10.0, y + 0.005, -4.6 - 0.04 - i * 0.45), Vector3(2.6, 0.03, 0.06), edge, Vector3.ZERO, false)
	L.box(self, Vector3(10.0, -2.3, -7.7), Vector3(2.6, 0.2, 0.9), L.mat(L.c("#07080C"), 1.0))
	L.omni(self, Vector3(10.0, -0.6, -6.2), L.c("#D6E2DC"), 1.6, 5.5)
	# leuningen
	for sx in [-1.35, 1.35]:
		L.limb(self, Vector3(10.0 + sx, 1.0, -4.3), Vector3(10.0 + sx, 1.0, -8.0), 0.04, 0.04, steel)
		for z in [-4.3, -6.1, -7.9]:
			L.cyl(self, Vector3(10.0 + sx, 0.5, z), 0.03, 1.0, steel, Vector3.ZERO, -1.0, 6)
	# luifel van glas op vier palen
	for p in [Vector2(-1.6, -4.0), Vector2(1.6, -4.0), Vector2(-1.6, -8.2), Vector2(1.6, -8.2)]:
		L.cyl(self, Vector3(10.0 + p.x, 1.55, p.y), 0.05, 3.1, steel, Vector3.ZERO, -1.0, 8)
	L.box(self, Vector3(10.0, 3.12, -6.1), Vector3(3.5, 0.08, 4.5), steel)
	var gl := L.glass(L.c("#3E5578"), 0.35, 0.05)
	L.box(self, Vector3(10.0, 3.2, -6.1), Vector3(3.3, 0.04, 4.3), gl, Vector3.ZERO, false)
	L.omni(self, Vector3(10.0, 2.8, -6.1), L.c("#D6E2DC"), 1.1, 5.0)
	# pictogram op een paal (eigen ontwerp): ring met een chevron naar beneden, in een afgeronde plaat
	var px := 8.1
	var pz := -3.3
	L.cyl(self, Vector3(px, 1.9, pz), 0.07, 3.8, steel, Vector3.ZERO, -1.0, 8)
	var sign_root := Node3D.new()
	sign_root.position = Vector3(px, 3.7, pz)
	sign_root.rotation_degrees = Vector3(0, 35, 0)
	add_child(sign_root)
	var panel := L.mat(L.c("#0E1A2C"), 0.4)
	var teal := L.mat(L.c("#1E7A8C"), 0.4, 0.0, L.c("#3EE6FF"), 2.4)
	var white := L.mat(L.c("#E8EEF2"), 0.4, 0.0, L.c("#E8EEF2"), 1.6)
	L.box(sign_root, Vector3.ZERO, Vector3(1.3, 1.3, 0.1), panel)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.40
	ring.outer_radius = 0.50
	ring.rings = 32
	ring.ring_segments = 8
	L.add(sign_root, ring, teal, Vector3(0, 0, 0.06), Vector3(90, 0, 0), false)
	L.box(sign_root, Vector3(-0.17, 0.0, 0.07), Vector3(0.1, 0.5, 0.04), white, Vector3(0, 0, 50), false)
	L.box(sign_root, Vector3(0.17, 0.0, 0.07), Vector3(0.1, 0.5, 0.04), white, Vector3(0, 0, -50), false)
	L.omni(self, Vector3(px + 1.0, 3.6, pz + 1.0), L.c("#3EE6FF"), 0.5, 4.0)

# ---------------------------------------------------------------- auto (rijdt van de camera weg)
func build_car(p: Vector3) -> void:
	var body := L.mat(L.c("#34425A"), 0.3, 0.5)
	var glass_m := L.mat(L.c("#0E1220"), 0.05, 0.3)
	var tyre := L.mat(L.c("#07080C"), 0.8)
	var red := L.mat(L.c("#A8382A"), 0.3, 0.0, L.c("#D04A32"), 12.0)
	var root := Node3D.new()
	root.position = p
	add_child(root)
	L.box(root, Vector3(0, 0.62, 0), Vector3(1.8, 0.62, 4.3), body)
	L.box(root, Vector3(0, 1.18, 0.35), Vector3(1.55, 0.55, 2.4), glass_m)
	L.box(root, Vector3(0, 1.5, 0.35), Vector3(1.6, 0.06, 2.3), body)
	for x in [-0.9, 0.9]:
		for z in [-1.4, 1.4]:
			L.cyl(root, Vector3(x, 0.33, z), 0.33, 0.24, tyre, Vector3(0, 0, 90), -1.0, 16)
	for x in [-0.65, 0.65]:
		L.box(root, Vector3(x, 0.78, 2.16), Vector3(0.38, 0.14, 0.05), red, Vector3.ZERO, false)
		L.spot(root, Vector3(x, 0.78, 2.3), Vector3(x * 1.4, 0.0, 9.0), L.c("#D04A32"), 30.0, 10.0, 50.0)
	L.box(root, Vector3(0, 0.78, 2.16), Vector3(0.5, 0.04, 0.04), red, Vector3.ZERO, false)
	L.omni(root, Vector3(0, 0.8, 2.6), L.c("#D04A32"), 0.8, 4.0)
	# koplampen vooruit, ver voor de auto
	for x in [-0.6, 0.6]:
		L.spot(root, Vector3(x, 0.7, -2.2), Vector3(x, 0.0, -14.0), L.c("#EEF4FF"), 18.0, 22.0, 30.0)

# ---------------------------------------------------------------- Richard (placeholder)
func build_richard(p: Vector3) -> void:
	var jas := L.mat(L.c("#232A36"), 0.7)
	var broek := L.mat(L.c("#1A1E26"), 0.8)
	var huid := L.mat(L.c("#8A5A40"), 0.7)
	var tas := L.mat(L.c("#8FCB7A"), 0.5)
	var ant := L.mat(L.c("#1E2228"), 0.5)
	var strip := L.mat(L.c("#C9C2AE"), 0.3, 0.0, L.c("#C9C2AE"), 0.25)
	var root := Node3D.new()
	root.position = p
	root.rotation_degrees = Vector3(0, 125, 0)   # kijkt naar de gevel, tas naar de camera
	add_child(root)
	L.omni(self, p + Vector3(1.4, 1.6, 1.2), L.c("#FFB866"), 1.2, 4.0)
	L.cyl(root, Vector3(0, 0.45, 0), 0.16, 0.9, broek, Vector3.ZERO, 0.13, 10)
	L.cyl(root, Vector3(0, 1.15, 0), 0.30, 0.8, jas, Vector3.ZERO, 0.24, 12)
	L.sphere(root, Vector3(0, 1.66, 0), 0.17, huid)
	L.sphere(root, Vector3(0, 1.66, 0.04), 0.205, jas)  # capuchon
	L.sphere(root, Vector3(0, 1.69, -0.08), 0.12, huid)
	L.box(root, Vector3(0, 1.2, -0.46), Vector3(0.62, 0.7, 0.42), tas)
	L.box(root, Vector3(0, 1.6, -0.46), Vector3(0.64, 0.08, 0.44), ant)
	L.box(root, Vector3(0, 1.25, -0.68), Vector3(0.6, 0.06, 0.02), strip, Vector3.ZERO, false)
	L.box(root, Vector3(0, 1.1, -0.255), Vector3(0.5, 0.07, 0.12), ant)

# ---------------------------------------------------------------- vuurwerkresten
func build_trash(p: Vector3) -> void:
	var red := L.mat(L.c("#A8382A"), 0.8)
	var card := L.mat(L.c("#6E6355"), 0.9)
	var dark := L.mat(L.c("#07080C"), 1.0)
	var paper := L.mat(L.c("#C2B49C"), 0.9)
	L.cyl(self, p + Vector3(0.0, 0.006, 0.0), 1.1, 0.012, dark, Vector3.ZERO, -1.0, 20, false)   # verschroeid plek
	for i in range(11):
		var q := p + Vector3(rng.randf_range(-1.2, 1.2), 0.04, rng.randf_range(-1.2, 1.2))
		var ang := Vector3(90, rng.randf_range(0, 360), 0) if i % 3 != 0 else Vector3(0, rng.randf_range(0, 360), 90)
		L.cyl(self, q, 0.035, 0.3, red if i % 2 == 0 else card, ang, -1.0, 8)
	for i in range(8):
		L.box(self, p + Vector3(rng.randf_range(-1.4, 1.4), 0.012, rng.randf_range(-1.4, 1.4)), Vector3(0.12, 0.01, 0.08), paper if i % 2 == 0 else red, Vector3(0, rng.randf_range(0, 360), 0), false)
	L.limb(self, p + Vector3(-0.6, 0.03, 1.1), p + Vector3(0.6, 0.05, 0.4), 0.012, 0.012, card)  # rakettenstok
	# batterijdoos, half verbrand
	L.box(self, p + Vector3(0.9, 0.18, -0.9), Vector3(0.5, 0.36, 0.3), card, Vector3(0, 30, 0))
	L.box(self, p + Vector3(0.9, 0.37, -0.9), Vector3(0.45, 0.03, 0.26), dark, Vector3(0, 30, 0), false)

# ---------------------------------------------------------------- plassen
func build_puddles() -> void:
	var pm := L.mat(L.c("#14171E"), 0.03, 0.0)
	pm.metallic_specular = 1.0
	var spots := [
		[Vector3(-3.0, 0.0, 3.0), 2.6, 1.6], [Vector3(1.0, 0.0, 8.0), 3.2, 1.8], [Vector3(-1.5, 0.0, -9.0), 2.0, 3.0],
		[Vector3(3.5, 0.0, -12.0), 1.8, 2.8], [Vector3(-3.8, 0.0, -18.0), 2.4, 4.0], [Vector3(2.0, 0.0, -22.0), 2.0, 3.5],
		[Vector3(-8.8, 0.0, -1.0), 1.8, 1.4], [Vector3(-7.4, 0.0, 6.5), 1.4, 2.0], [Vector3(8.4, 0.0, 4.0), 1.8, 1.4],
		[Vector3(7.4, 0.0, -14.0), 1.5, 1.2], [Vector3(-9.5, 0.0, -9.0), 2.0, 2.4], [Vector3(-8.0, 0.0, -16.0), 1.4, 1.2],
		[Vector3(0.5, 0.0, -30.0), 2.8, 4.0], [Vector3(-2.5, 0.0, -35.0), 3.0, 3.0],
	]
	for s in spots:
		var m := L.cyl(self, s[0] + Vector3(0, 0.02 if abs(s[0].x) < 6 else 0.17, 0), 1.0, 0.01, pm, Vector3.ZERO, -1.0, 28, false)
		m.scale = Vector3(s[1], 1.0, s[2])

# ---------------------------------------------------------------- achtergrond
func build_far() -> void:
	var dark := L.mat(L.c("#0E1220"), 0.7)
	var glassb := L.mat(L.c("#124450"), 0.15, 0.2)
	var win := L.mat(L.c("#2A2230"), 0.3, 0.0, L.c("#FFD8A0"), 1.0)
	# blokken links achter de gevel en rechts langs de straat
	L.box(self, Vector3(-20, 5, -44), Vector3(12, 10, 14), L.mat(L.c("#2E2924"), 0.9))
	L.box(self, Vector3(20, 6, -34), Vector3(8, 12, 22), dark)
	L.box(self, Vector3(4, 14, -64), Vector3(10, 28, 8), glassb)
	L.box(self, Vector3(-8, 9, -62), Vector3(9, 18, 8), dark)
	L.box(self, Vector3(14, 8, -62), Vector3(9, 16, 8), dark)
	# een paar lichtgevende ramen (lockdown: nauwelijks iemand wakker)
	for i in range(14):
		var wx := 16.0
		L.box(self, Vector3(wx, rng.randf_range(2.0, 12.0), rng.randf_range(-44.0, -23.0)), Vector3(0.1, 1.0, 0.8), win, Vector3.ZERO, false)
	# verre lantaarns, enkel gloed
	var nat := L.mat(L.c("#FFB866"), 0.3, 0.0, L.c("#F08A30"), 6.0)
	for z in [-46.0, -56.0]:
		for x in [-6.5, 6.5]:
			L.sphere(self, Vector3(x, 7.5, z), 0.3, nat, false)
	L.omni(self, Vector3(0, 8, -50), L.c("#F08A30"), 2.0, 22.0)
	# rood verkeerslicht in de verte
	L.sphere(self, Vector3(5.5, 4.5, -48), 0.25, L.mat(L.c("#D04A32"), 0.3, 0.0, L.c("#D04A32"), 6.0), false)

# ---------------------------------------------------------------- regen
func build_rain() -> void:
	var p := GPUParticles3D.new()
	p.amount = 9000
	p.lifetime = 1.25
	p.preprocess = 2.0
	p.position = Vector3(-2, 26, -10)
	p.visibility_aabb = AABB(Vector3(-60, -40, -60), Vector3(120, 60, 120))
	p.transform_align = GPUParticles3D.TRANSFORM_ALIGN_Y_TO_VELOCITY
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(34, 1, 40)
	pm.direction = Vector3(0.18, -1, 0.06)
	pm.spread = 1.5
	pm.initial_velocity_min = 22.0
	pm.initial_velocity_max = 27.0
	pm.gravity = Vector3.ZERO
	p.process_material = pm
	var bm := BoxMesh.new()
	bm.size = Vector3(0.01, 0.6, 0.01)
	var rm := L.mat(Color(0.43, 0.53, 0.66, 0.4), 0.6, 0.0, L.c("#6E86A8"), 0.5)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.material = rm
	p.draw_pass_1 = bm
	add_child(p)

# ---------------------------------------------------------------- gespiegeld licht op nat asfalt
# SSR ziet de onderkant van lampen en de lichten van boven niet goed; daarom een zachte, procedurele streep
# (geen textuur: streep.gdshader) onder elke lamp en achter de auto, richting camera uitgerekt.
func build_streaks() -> void:
	var sh: Shader = load("res://streep.gdshader")
	var dir := Vector3(0.56, 0, 0.83)
	var items := [
		[Vector3(-4.6, 0.03, 0.0), "#F08A30", 8.0, 2.2, 0.8], [Vector3(4.6, 0.03, -14.0), "#F08A30", 7.0, 2.0, 0.6],
		[Vector3(-4.6, 0.03, -24.0), "#F08A30", 7.0, 2.0, 0.5], [Vector3(4.6, 0.03, -36.0), "#F08A30", 6.0, 1.8, 0.4],
		[Vector3(2.15, 0.03, -0.9), "#D04A32", 4.5, 0.5, 0.6], [Vector3(3.45, 0.03, -0.9), "#D04A32", 4.5, 0.5, 0.6],
	]
	for it in items:
		var q := QuadMesh.new()
		q.size = Vector2(it[3], it[2])
		q.orientation = PlaneMesh.FACE_Y
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("col", L.c(it[1]))
		m.set_shader_parameter("energy", it[4])
		m.set_shader_parameter("sz", Vector2(it[3], it[2]))
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = it[0] + dir * (it[2] * 0.5)
		mi.rotation.y = atan2(dir.x, dir.z)
		add_child(mi)
