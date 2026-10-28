extends Node3D
# Scene B: Richards studentenkamer, nacht. Kamer x -3..3, z -2.5..2.5. Achterwand z=-2.5, linkerwand x=-3.
# Voor- en rechterwand ontbreken (doorsnede); de camera kijkt schuin van rechtsvoor.
const L = preload("res://lib.gd")

var rng := RandomNumberGenerator.new()
var cam: Camera3D
var cam_i := 0
var bursts: Array[Node3D] = []
var t := 0.0
var outside: Node3D = null
var outside_lights: Array = []

var cams := [
	[Vector3(0.0, 0.9, -0.5), 22.0, 38.0, 40.0, 6.2, 0.0],
	[Vector3(0.0, 0.9, -1.6), 12.0, 28.0, 40.0, 4.2, 0.0],
	[Vector3(-0.2, 0.8, -0.6), 26.0, 34.0, 21.0, 0.0, 28.0],
]

func _ready() -> void:
	rng.seed = 2022
	var a := L.args()
	add_child(L.make_env(L.c("#07080C"), L.c("#3E5578"), 1.8, 0.02, L.c("#8A93A8"), 1.15, L.c("#151B2C"), L.c("#3E5578"), 2.0))
	build_shell()
	build_window()
	build_desk()
	build_bed()
	build_rug_and_chair()
	build_wall_stuff()
	build_door_stuff()
	cam = Camera3D.new()
	add_child(cam)
	cam_i = int(a.get("cam", 0))
	apply_cam()
	L.vignette(self, 0.95, 0.25, 0.8)
	L.start_shot(self, a)

func _process(d: float) -> void:
	t += d
	for i in range(bursts.size()):
		var s := 0.85 + 0.15 * sin(t * 1.3 + i * 2.0)
		bursts[i].scale = Vector3(s, s, s)

func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_C:
		cam_i = (cam_i + 1) % cams.size()
		apply_cam()
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_1:
		get_tree().change_scene_to_file("res://a_straat.tscn")

func apply_cam() -> void:
	var k: Array = cams[cam_i]
	L.place_cam(cam, k[0], k[1], k[2], k[3], k[4], k[5])
	build_outside()

# ---------------------------------------------------------------- kamer
func wall_seg(x0: float, x1: float, y0: float, y1: float, m: Material) -> void:
	L.box(self, Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, -2.6), Vector3(x1 - x0, y1 - y0, 0.2), m)

func build_shell() -> void:
	var floor_m := L.mat(L.c("#5A4636"), 0.55)
	var wall := L.mat(L.c("#5A7398"), 0.9)
	var wall2 := L.mat(L.c("#3E5578"), 0.9)
	var skirt := L.mat(L.c("#2A3040"), 0.7)
	L.box(self, Vector3(0, -0.1, 0), Vector3(6.4, 0.2, 5.4), floor_m)
	# achterwand met raamopening (x -0.95..0.95, y 1.0..2.1) en deur (x 1.9..2.8, y 0..2.1)
	wall_seg(-3.2, -0.95, 0.0, 2.7, wall)
	wall_seg(-0.95, 0.95, 0.0, 1.0, wall)
	wall_seg(-0.95, 0.95, 2.1, 2.7, wall)
	wall_seg(0.95, 1.9, 0.0, 2.7, wall)
	wall_seg(1.9, 2.8, 2.1, 2.7, wall)
	wall_seg(2.8, 3.2, 0.0, 2.7, wall)
	# linkerwand
	L.box(self, Vector3(-3.1, 1.35, 0.0), Vector3(0.2, 2.7, 5.4), wall2)
	# plinten
	L.box(self, Vector3(0, 0.07, -2.47), Vector3(6.0, 0.14, 0.05), skirt, Vector3.ZERO, false)
	L.box(self, Vector3(-2.97, 0.07, 0.0), Vector3(0.05, 0.14, 5.0), skirt, Vector3.ZERO, false)
	# deur (donkerhout, iets terugliggend) met greep
	var door := L.mat(L.c("#3A241C"), 0.6)
	L.box(self, Vector3(2.35, 1.05, -2.5), Vector3(0.9, 2.1, 0.06), door)
	L.box(self, Vector3(2.0, 1.0, -2.45), Vector3(0.05, 0.05, 0.1), L.mat(L.c("#978A76"), 0.3, 0.8), Vector3.ZERO, false)
	# kier licht onder de deur uit de gang
	L.box(self, Vector3(2.35, 0.012, -2.44), Vector3(0.8, 0.012, 0.03), L.mat(L.c("#F0F6F0"), 0.5, 0.0, L.c("#D6E2DC"), 1.2), Vector3.ZERO, false)

# ---------------------------------------------------------------- raam
func build_window() -> void:
	var frame := L.mat(L.c("#6E7F86"), 0.5)
	var gl := L.glass(L.c("#1F2A44"), 0.25, 0.02)
	L.box(self, Vector3(0, 1.55, -2.56), Vector3(1.9, 0.08, 0.2), frame)       # boven
	L.box(self, Vector3(0, 1.0, -2.45), Vector3(2.1, 0.06, 0.4), frame)        # vensterbank
	L.box(self, Vector3(-0.95, 1.55, -2.56), Vector3(0.08, 1.1, 0.2), frame)
	L.box(self, Vector3(0.95, 1.55, -2.56), Vector3(0.08, 1.1, 0.2), frame)
	L.box(self, Vector3(0.0, 1.55, -2.58), Vector3(0.05, 1.1, 0.12), frame)    # stijl
	L.box(self, Vector3(0.0, 1.9, -2.58), Vector3(1.9, 0.05, 0.12), frame)     # tussenregel
	L.box(self, Vector3(0, 1.55, -2.6), Vector3(1.85, 1.1, 0.02), gl, Vector3.ZERO, false)
	# regenstrepen op het glas
	var rm := L.glass(L.c("#6E86A8"), 0.5, 0.2, L.c("#6E86A8"), 0.4)
	for i in range(34):
		var x := rng.randf_range(-0.9, 0.9)
		var y := rng.randf_range(1.05, 2.05)
		L.box(self, Vector3(x, y, -2.54), Vector3(0.012, rng.randf_range(0.05, 0.3), 0.006), rm, Vector3.ZERO, false)
	# snoer warme lampjes langs de bovenkant van het raam
	var lm := L.mat(L.c("#FFE2A8"), 0.5, 0.0, L.c("#FFE2A8"), 5.0)
	for i in range(18):
		var x := -0.95 + i * 0.112
		L.sphere(self, Vector3(x, 2.2 - 0.07 * sin(float(i) / 17.0 * PI), -2.4), 0.03, lm, false)
	L.omni(self, Vector3(0.0, 2.15, -2.2), L.c("#FFE2A8"), 0.4, 2.0)
	# koel schijnsel van buiten (stadsgloed) door het raam
	L.spot(self, Vector3(-0.3, 1.7, -4.0), Vector3(0.4, 0.0, -0.5), L.c("#5A7398"), 3.0, 8.0, 38.0, true)

# ---------------------------------------------------------------- bureau
func build_desk() -> void:
	var wood := L.mat(L.c("#6E4528"), 0.6)
	var steel := L.mat(L.c("#14171E"), 0.4, 0.5)
	var lap := L.mat(L.c("#A8B8B4"), 0.35, 0.6)
	var scr := L.mat(L.c("#9FC8E8"), 0.3, 0.0, L.c("#9FC8E8"), 1.5)
	var warm_light := L.c("#FFD8A0")
	L.box(self, Vector3(0, 0.75, -2.1), Vector3(1.9, 0.05, 0.7), wood)
	for x in [-0.9, 0.9]:
		L.box(self, Vector3(x, 0.36, -2.1), Vector3(0.05, 0.72, 0.65), wood)
	L.box(self, Vector3(0, 0.45, -2.42), Vector3(1.8, 0.4, 0.03), wood)
	# laptop (scherm naar de stoel), koel licht
	L.box(self, Vector3(0.15, 0.785, -2.0), Vector3(0.36, 0.02, 0.25), lap)
	L.box(self, Vector3(0.15, 0.92, -2.15), Vector3(0.36, 0.24, 0.015), lap, Vector3(-12, 0, 0))
	L.box(self, Vector3(0.15, 0.92, -2.138), Vector3(0.33, 0.21, 0.008), scr, Vector3(-12, 0, 0), false)
	L.omni(self, Vector3(0.15, 0.95, -1.8), L.c("#9FC8E8"), 0.45, 2.4, true)
	# telefoon naast de laptop, scherm dicht, stil
	L.box(self, Vector3(0.55, 0.78, -1.95), Vector3(0.07, 0.01, 0.14), L.mat(L.c("#0E1220"), 0.2, 0.3), Vector3(0, 20, 0))
	# bureaulamp: voet, arm, kap; spot + zachte vulling
	var base := Vector3(-0.72, 0.78, -2.15)
	L.cyl(self, base, 0.09, 0.03, steel)
	var knee := base + Vector3(0.12, 0.38, 0.06)
	var head := base + Vector3(0.28, 0.5, 0.02)
	L.limb(self, base, knee, 0.012, 0.012, steel, true)
	L.limb(self, knee, head, 0.012, 0.012, steel, true)
	var shade := L.cyl(self, head + Vector3(0.05, -0.04, 0.0), 0.1, 0.12, steel, Vector3(0, 0, -25), 0.025, 20)
	L.sphere(self, head + Vector3(0.06, -0.09, 0.0), 0.035, L.mat(L.c("#FFE2A8"), 0.4, 0.0, L.c("#FFD8A0"), 9.0), false)
	L.spot(self, head + Vector3(0.07, -0.1, 0.02), Vector3(0.0, 0.76, -1.95), warm_light, 11.0, 4.6, 40.0, true)
	L.omni(self, head + Vector3(0.1, -0.05, 0.15), L.c("#D89A5A"), 0.9, 4.5, false)
	# kapsalonbakje (leeg, bakstenen bakje met crème binnenkant), plastic vorkje
	L.box(self, Vector3(0.62, 0.8, -2.3), Vector3(0.22, 0.05, 0.17), L.mat(L.c("#9A3B24"), 0.7))
	L.box(self, Vector3(0.62, 0.826, -2.3), Vector3(0.18, 0.012, 0.13), L.mat(L.c("#EADBB8"), 0.8), Vector3.ZERO, false)
	L.box(self, Vector3(0.75, 0.815, -2.3), Vector3(0.12, 0.01, 0.012), L.mat(L.c("#E8EEF2"), 0.5), Vector3(0, 40, 0), false)
	# blikje BB-drink
	L.cyl(self, Vector3(0.42, 0.84, -2.32), 0.033, 0.12, L.mat(L.c("#E6E1D3"), 0.35, 0.3), Vector3.ZERO, -1.0, 16)
	L.cyl(self, Vector3(0.42, 0.845, -2.32), 0.0335, 0.03, L.mat(L.c("#F0603A"), 0.4), Vector3.ZERO, -1.0, 16, false)
	# kerstkaart van thuis
	L.box(self, Vector3(-0.2, 0.78, -2.28), Vector3(0.14, 0.004, 0.1), L.mat(L.c("#D04A32"), 0.7), Vector3(0, 12, 0), false)

# ---------------------------------------------------------------- bed
func build_bed() -> void:
	var frame := L.mat(L.c("#3A241C"), 0.6)
	var sheet := L.mat(L.c("#34425A"), 0.9)
	var duvet := L.mat(L.c("#2A3A5C"), 0.95)
	var pillow := L.mat(L.c("#A8B8B4"), 0.9)
	L.box(self, Vector3(-2.45, 0.18, -1.4), Vector3(1.0, 0.18, 2.1), frame)
	L.box(self, Vector3(-2.45, 0.36, -1.4), Vector3(0.94, 0.18, 2.0), sheet)
	L.box(self, Vector3(-2.45, 0.5, -0.95), Vector3(0.96, 0.12, 1.2), duvet, Vector3(0, 0, 0))
	L.box(self, Vector3(-2.45, 0.54, -0.5), Vector3(0.96, 0.08, 0.3), duvet, Vector3(0, 0, 4))   # omgeslagen rand
	L.box(self, Vector3(-2.45, 0.5, -2.1), Vector3(0.7, 0.14, 0.38), pillow, Vector3(0, 0, 0))
	L.box(self, Vector3(-2.45, 0.7, -2.45), Vector3(1.0, 0.7, 0.06), frame)  # hoofdeinde

# ---------------------------------------------------------------- vloerkleed en stoel
func build_rug_and_chair() -> void:
	var red := L.mat(L.c("#A8382A"), 0.95)
	var cream := L.mat(L.c("#D8D4C8"), 0.95)
	var dark := L.mat(L.c("#6A2018"), 0.95)
	var c := Vector3(0.2, 0.0, 0.3)
	# vloerkleed: rood-wit in concentrische kaders (geen vlag): rode rand, crème rand, rood veld, crème ruit
	L.box(self, c + Vector3(0, 0.008, 0), Vector3(2.5, 0.016, 1.7), red, Vector3.ZERO, false)
	L.box(self, c + Vector3(0, 0.014, 0), Vector3(2.3, 0.016, 1.5), cream, Vector3.ZERO, false)
	L.box(self, c + Vector3(0, 0.02, 0), Vector3(2.1, 0.016, 1.3), red, Vector3.ZERO, false)
	L.box(self, c + Vector3(0, 0.026, 0), Vector3(1.0, 0.016, 1.0), cream, Vector3(0, 45, 0), false)
	L.box(self, c + Vector3(0, 0.032, 0), Vector3(0.55, 0.016, 0.55), dark, Vector3(0, 45, 0), false)
	for i in range(6):
		L.box(self, c + Vector3(-1.05 + i * 0.42, 0.026, 0.0), Vector3(0.08, 0.016, 0.08), cream, Vector3(0, 45, 0), false) if i % 5 == 99 else null
	# stoel, iets achteruit geschoven; clubsjaal (rood-wit, eigen kleuren) over de leuning
	var chair := L.mat(L.c("#1E232C"), 0.6)
	var cp := Vector3(-0.05, 0.0, -1.25)
	var root := Node3D.new()
	root.position = cp
	root.rotation_degrees = Vector3(0, -14, 0)
	add_child(root)
	L.box(root, Vector3(0, 0.46, 0), Vector3(0.46, 0.07, 0.46), chair)
	L.box(root, Vector3(0, 0.78, 0.22), Vector3(0.46, 0.5, 0.06), chair, Vector3(8, 0, 0))
	L.cyl(root, Vector3(0, 0.24, 0), 0.03, 0.4, chair, Vector3.ZERO, -1.0, 8)
	for i in range(5):
		var ang := i * TAU / 5.0
		L.box(root, Vector3(cos(ang) * 0.2, 0.04, sin(ang) * 0.2), Vector3(0.4, 0.03, 0.05), chair, Vector3(0, -rad_to_deg(ang), 0), false)
	# sjaal: bovenstuk over de leuning, hangend stuk aan de achterkant
	var n := 8
	for i in range(n):
		var m := red if i % 2 == 0 else cream
		var zz := 0.19 + i * 0.0
		L.box(root, Vector3(-0.19 + i * 0.054 + 0.027, 1.045, 0.22), Vector3(0.054, 0.07, 0.115), m, Vector3.ZERO, false)
	for i in range(9):
		var m := red if i % 2 == 0 else cream
		L.box(root, Vector3(-0.15, 0.98 - i * 0.075, 0.292), Vector3(0.12, 0.075, 0.03), m, Vector3.ZERO, false)
	# een paar schoenen op het tapijt
	var sh := L.mat(L.c("#14171E"), 0.8)
	L.box(self, Vector3(-0.7, 0.06, 1.0), Vector3(0.12, 0.1, 0.3), sh, Vector3(0, 20, 0))
	L.box(self, Vector3(-0.5, 0.06, 1.1), Vector3(0.12, 0.1, 0.3), sh, Vector3(0, 28, 0))

# ---------------------------------------------------------------- wandspullen: fietskaart, plank
func build_wall_stuff() -> void:
	var paper := L.mat(L.c("#C2B49C"), 0.9)
	var map := Node3D.new()
	map.position = Vector3(-2.97, 1.55, -1.1)
	map.rotation_degrees = Vector3(0, 90, 0)
	add_child(map)
	L.box(map, Vector3.ZERO, Vector3(1.3, 0.9, 0.02), paper)
	var river := L.mat(L.c("#4A5FA0"), 0.9)
	L.box(map, Vector3(0.0, -0.15, 0.012), Vector3(1.3, 0.1, 0.004), river, Vector3(0, 0, 8), false)
	var lines := [
		[Vector3(-0.5, 0.3, 0), Vector3(0.1, 0.3, 0), "#A8382A"], [Vector3(0.1, 0.3, 0), Vector3(0.5, 0.0, 0), "#A8382A"],
		[Vector3(-0.55, -0.3, 0), Vector3(-0.2, 0.2, 0), "#2E2924"], [Vector3(-0.2, 0.2, 0), Vector3(0.3, 0.25, 0), "#2E2924"],
		[Vector3(0.2, -0.35, 0), Vector3(0.0, 0.0, 0), "#5FB860"], [Vector3(0.0, 0.0, 0), Vector3(-0.3, 0.1, 0), "#5FB860"],
		[Vector3(0.45, 0.35, 0), Vector3(0.55, -0.2, 0), "#2E2924"],
	]
	for ln in lines:
		var a: Vector3 = ln[0]
		var b: Vector3 = ln[1]
		var mm := L.mat(L.c(ln[2]), 0.9)
		var d := b - a
		L.box(map, (a + b) * 0.5 + Vector3(0, 0, 0.014), Vector3(d.length(), 0.018, 0.004), mm, Vector3(0, 0, rad_to_deg(atan2(d.y, d.x))), false)
	L.sphere(map, Vector3(0.1, 0.3, 0.02), 0.03, L.mat(L.c("#A8382A"), 0.6), false)   # pin
	# plank met boeken boven het bed
	var wood := L.mat(L.c("#6E4528"), 0.6)
	L.box(self, Vector3(-2.82, 1.0, 0.7), Vector3(0.3, 0.04, 1.2), wood)
	var cols := ["#2A3A5C", "#6A2018", "#4A4239", "#1F2A44", "#978A76", "#3E5578"]
	for i in range(8):
		var h := rng.randf_range(0.2, 0.28)
		L.box(self, Vector3(-2.84, 1.02 + h * 0.5, 0.2 + i * 0.1), Vector3(0.2, h, 0.07), L.mat(L.c(cols[i % cols.size()]), 0.8))

# ---------------------------------------------------------------- jas en bezorgtas bij de deur
func build_door_stuff() -> void:
	var jas := L.mat(L.c("#232A36"), 0.8)
	var strip := L.mat(L.c("#C9C2AE"), 0.3, 0.0, L.c("#C9C2AE"), 0.3)
	var tas := L.mat(L.c("#8FCB7A"), 0.55)
	var ant := L.mat(L.c("#1E2228"), 0.5)
	# haken en parka
	L.box(self, Vector3(1.4, 1.75, -2.46), Vector3(0.5, 0.03, 0.04), L.mat(L.c("#14171E"), 0.4, 0.5))
	var jas2 := L.mat(L.c("#2E3A4E"), 0.8)
	L.box(self, Vector3(1.4, 1.2, -2.35), Vector3(0.46, 0.95, 0.15), jas2, Vector3(0, 0, 0))
	L.box(self, Vector3(1.4, 0.82, -2.35), Vector3(0.54, 0.3, 0.17), jas2)
	L.box(self, Vector3(1.19, 1.12, -2.33), Vector3(0.09, 0.78, 0.12), jas, Vector3(0, 0, 3))
	L.box(self, Vector3(1.61, 1.12, -2.33), Vector3(0.09, 0.78, 0.12), jas, Vector3(0, 0, -3))
	L.sphere(self, Vector3(1.4, 1.7, -2.31), 0.15, jas2)
	L.box(self, Vector3(1.61, 1.0, -2.26), Vector3(0.12, 0.03, 0.02), strip, Vector3(0, 0, -6), false)
	L.box(self, Vector3(1.19, 1.0, -2.26), Vector3(0.12, 0.03, 0.02), strip, Vector3(0, 0, 6), false)
	# Bringbroh-tas op de vloer: groot blok, antraciet klep, reflecterende strook
	L.box(self, Vector3(1.4, 0.33, -1.95), Vector3(0.62, 0.62, 0.45), tas, Vector3(0, 12, 0))
	L.box(self, Vector3(1.4, 0.66, -1.95), Vector3(0.66, 0.08, 0.49), ant, Vector3(0, 12, 0))
	L.box(self, Vector3(1.4, 0.36, -1.71), Vector3(0.6, 0.05, 0.02), strip, Vector3(0, 12, 0), false)
	for dx in [-0.07, 0.07]:
		L.box(self, Vector3(1.4 + dx - 0.015, 0.4, -1.72), Vector3(0.06, 0.2, 0.02), ant, Vector3(0, 12, 40 if dx < 0 else -40), false)
	L.omni(self, Vector3(1.5, 1.3, -1.3), L.c("#D89A5A"), 0.45, 2.5)

# ---------------------------------------------------------------- buiten: daken en vuurpijlen
func build_outside() -> void:
	# Staat in cameraruimte: lokale x/y = schermassen, zodat alles in de kijkbuis door het raam valt
	# (kamer ligt hoog; vuurwerk en daken liggen verderop en lager).
	var k: Array = cams[cam_i]
	var yw := deg_to_rad(k[1])
	var pt := deg_to_rad(k[2])
	var f := -Vector3(sin(yw) * cos(pt), sin(pt), cos(yw) * cos(pt))
	if outside != null:
		outside.queue_free()
	bursts.clear()
	var root := Node3D.new()
	outside = root
	add_child(root)
	root.look_at_from_position(Vector3(0, 1.55, -2.6) + f * 7.0, Vector3(0, 1.55, -2.6) + f * 8.0, Vector3.UP)
	var glow := L.mat(L.c("#2A2230"), 0.9, 0.0, L.c("#5A3E4A"), 0.6)
	L.box(root, Vector3(0, 0, -4), Vector3(3.6, 2.4, 0.3), glow, Vector3.ZERO, false)
	var roof := L.mat(L.c("#0A0D16"), 0.9)
	var win := L.mat(L.c("#2A2230"), 0.3, 0.0, L.c("#FFD8A0"), 1.2)
	var x := -1.6
	while x < 1.6:
		var w := rng.randf_range(0.25, 0.5)
		var h := rng.randf_range(0.12, 0.34)
		L.box(root, Vector3(x + w * 0.5, -0.5 + h * 0.5 - 0.0, -2.0), Vector3(w, h + 0.1, 0.3), roof, Vector3.ZERO, false)
		if rng.randf() < 0.25:
			L.box(root, Vector3(x + w * 0.5, -0.5 + h * 0.5, -1.84), Vector3(0.05, 0.05, 0.02), win, Vector3.ZERO, false)
		x += w
	# losse vuurpijlen
	var cols := [["#FFE2A8", 9.0], ["#F08A30", 8.0], ["#D04A32", 8.0], ["#EEF4FF", 8.0]]
	var spots := [Vector3(-0.55, 0.12, -1.0), Vector3(0.25, 0.22, -1.2), Vector3(0.68, -0.02, -1.0)]
	var sizes := [0.2, 0.26, 0.16]
	for i in range(spots.size()):
		var cc: Array = cols[i % cols.size()]
		bursts.append(make_burst(root, spots[i], L.c(cc[0]), cc[1], sizes[i]))
	if outside_lights.size() == 0:
		outside_lights.append(L.omni(self, Vector3(-0.2, 1.5, -4.0), L.c("#F08A30"), 0.2, 5.0, true))
	L.omni(self, Vector3(0.3, 1.6, -3.6), L.c("#FFE2A8"), 0.2, 5.0, true)

func make_burst(parent: Node3D, pos: Vector3, col: Color, e: float, size: float) -> Node3D:
	var b := Node3D.new()
	b.position = pos
	parent.add_child(b)
	var m := L.mat(col, 0.5, 0.0, col, e)
	var core := L.mat(Color.WHITE, 0.5, 0.0, Color.WHITE, 14.0)
	L.sphere(b, Vector3.ZERO, size * 0.12, core, false)
	for i in range(40):
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-0.4, 0.4)).normalized()
		for k in range(3):
			var r := (1.0 + k * 0.35) * size * rng.randf_range(0.9, 1.0)
			L.sphere(b, d * r, size * (0.07 - k * 0.015), m, false)
	return b
