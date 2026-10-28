extends GutTest
## Zuivere logica van de kamerweergave (kamerweergave.md): KW-01, KW-05 (afstand), KW-06, KW-07, kwaliteit, loper.
## Geen enkele Node3D in deze tests (KW-17).

const Hulp = preload("hulp.gd")

var kantoor: Dictionary


func before_each() -> void:
	var c: ContentDb = Hulp.nieuw_content()
	add_child_autofree(c)
	kantoor = c.kamers[Hulp.KANTOOR]


func _raster() -> KamerRaster:
	var r: KamerRaster = KamerRaster.uit_kamer(kantoor)
	# niet-pakbare objecten: laptop (4,1), kluisje (6,1), prullenbak (6,4); pakbare tellen niet
	r.zet_obstakels([Vector2i(4, 1), Vector2i(6, 1), Vector2i(6, 4)])
	return r


func test_kw01_vak_naar_3d_en_terug() -> void:
	assert_eq(Vak.naar_3d(Vector2i(0, 0)), Vector3(0.5, 0, 0.5))
	assert_eq(Vak.naar_3d(Vector2i(7, 5)), Vector3(7.5, 0, 5.5))
	assert_eq(Vak.uit_3d(Vector3(3.99, 0, 0.01), 8, 6), Vector2i(3, 0))
	assert_null(Vak.uit_3d(Vector3(-0.01, 0, 1), 8, 6))
	assert_null(Vak.uit_3d(Vector3(8.0, 0, 1), 8, 6))
	for y in range(6):
		for x in range(8):
			assert_eq(Vak.uit_3d(Vak.naar_3d(Vector2i(x, y)), 8, 6), Vector2i(x, y))


func test_stand_verschuift_alleen_het_model() -> void:
	var p: Vector3 = Vak.naar_3d_stand(Vector2i(4, 1), {"dx": 0.2, "hoogte": 0.75, "dz": -0.1})
	assert_almost_eq(p, Vector3(4.7, 0.75, 1.4), Vector3(0.001, 0.001, 0.001))
	assert_eq(Vak.uit_3d(Vak.naar_3d_stand(Vector2i(4, 1), {"hoogte": 0.75}), 8, 6), Vector2i(4, 1))


func test_vloerklik_snijdt_vlak_y0() -> void:
	var cam: Dictionary = CameraStand.uit_kamer(kantoor)
	var t: Transform3D = cam["transform"]
	var p: Variant = Vak.vloer_snijpunt(t.origin, -t.basis.z)    # midden van het beeld = richtpunt
	assert_almost_eq(p as Vector3, Vector3(4, 0, 3), Vector3(0.01, 0.01, 0.01))


func test_kw05_camerastand() -> void:
	var c: Dictionary = CameraStand.uit_kamer(kantoor)
	assert_eq(c["fov"], 17.0)
	assert_eq(c["near"], 0.5)
	assert_eq(c["richtpunt"], Vector3(4, 0, 3))
	var t: Transform3D = c["transform"]
	var voor: Vector3 = -t.basis.z
	assert_almost_eq(rad_to_deg(asin(-voor.y)), 38.0, 0.1, "kanteling")
	assert_almost_eq(rad_to_deg(atan2(-voor.x, -voor.z)), 27.0, 0.1, "draaiing")
	assert_gt(float(c["far"]), float(c["afstand"]))


func test_kw05_afstand_past_net() -> void:
	var b := 8.0
	var h := 6.0
	var d: float = CameraStand.automatische_afstand(b, h, 2.6, 38.0, 27.0, 17.0)
	var m := Vector3(b / 2, 0, h / 2)
	var dir: Vector3 = CameraStand.richting(38.0, 27.0)
	assert_true(CameraStand.past(b, h, 2.6, m, dir, d * 1.001, 17.0), "past")
	assert_false(CameraStand.past(b, h, 2.6, m, dir, d * 0.95, 17.0), "5 % minder past niet meer")
	var met_afstand: Dictionary = CameraStand.uit_kamer({"afmeting": {"breedte": 8, "hoogte": 6}, "camera": {"afstand": 33.0}})
	assert_eq(met_afstand["afstand"], 33.0, "content wint")


func test_draaiing_negatief_kijkt_van_linksvoor() -> void:
	var c: Dictionary = CameraStand.uit_kamer({"afmeting": {"breedte": 8, "hoogte": 6}, "camera": {"draaiing": -27}})
	assert_lt((c["positie"] as Vector3).x, 4.0)


func test_kw06_beloopbaar() -> void:
	var r: KamerRaster = _raster()
	for v in [Vector2i(3, 1), Vector2i(4, 1), Vector2i(6, 1), Vector2i(6, 4)]:
		assert_false(r.beloopbaar(v), str(v))
	for v in [Vector2i(0, 3), Vector2i(7, 3), Vector2i(1, 3)]:
		assert_true(r.beloopbaar(v), str(v))
	assert_false(r.beloopbaar(Vector2i(8, 3)), "buiten de kamer")
	assert_false(r.beloopbaar(Vector2i(-1, 0)))


func test_kw07_paden_zijn_beloopbaar_en_snijden_geen_hoeken() -> void:
	var r: KamerRaster = _raster()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var gevonden: int = 0
	for _i in range(200):
		var a := Vector2i(rng.randi_range(0, 7), rng.randi_range(0, 5))
		var b := Vector2i(rng.randi_range(0, 7), rng.randi_range(0, 5))
		if not r.beloopbaar(a) or not r.beloopbaar(b):
			continue
		var pad: Array[Vector2i] = r.pad(a, b)
		assert_false(pad.is_empty(), "pad %s -> %s" % [a, b])
		gevonden += 1
		for i in range(pad.size()):
			assert_true(r.beloopbaar(pad[i]))
			if i > 0:
				var d: Vector2i = pad[i] - pad[i - 1]
				assert_true(absi(d.x) <= 1 and absi(d.y) <= 1 and d != Vector2i.ZERO)
				if d.x != 0 and d.y != 0:
					assert_true(r.beloopbaar(pad[i - 1] + Vector2i(d.x, 0)) and r.beloopbaar(pad[i - 1] + Vector2i(0, d.y)),
							"hoek afgesneden bij %s" % str(pad[i - 1]))
	assert_gt(gevonden, 100)


func test_pad_om_obstakels_heen() -> void:
	var r: KamerRaster = _raster()
	var pad: Array[Vector2i] = r.pad(Vector2i(2, 1), Vector2i(7, 1))
	assert_eq(pad.front(), Vector2i(2, 1))
	assert_eq(pad.back(), Vector2i(7, 1))
	assert_false(pad.has(Vector2i(3, 1)))
	assert_eq(r.pad(Vector2i(0, 0), Vector2i(3, 1)).size(), 0, "geblokkeerd doel: geen pad")


func test_loop_doel_object_en_geblokkeerd() -> void:
	var r: KamerRaster = _raster()
	var o: Dictionary = r.loop_doel(Vector2i(1, 3), Vector2i(4, 1), true)
	assert_true(o["dichtbij"])
	assert_true(r.beloopbaar(o["vak"]))
	assert_lte(absi(o["vak"].x - 4), 1)
	assert_lte(absi(o["vak"].y - 1), 1)
	var g: Dictionary = r.loop_doel(Vector2i(1, 3), Vector2i(3, 1), false)
	assert_true(r.beloopbaar(g["vak"]))
	assert_lte((g["vak"] - Vector2i(3, 1)).length(), 1.5)
	var buiten: Dictionary = r.loop_doel(Vector2i(1, 3), Vector2i(20, 20), false)
	assert_eq(buiten["pad"].size(), 0, "buiten de kamer: niets")


func test_pakbaar_object_blokkeert_niet_en_uitgang_ook_niet() -> void:
	var s: Spel = Hulp.nieuw_spel(self)
	var vakken: Array[Vector2i] = KamerRaster.obstakels_van(Hulp.KANTOOR, s.content, s.objecten, [])
	assert_true(vakken.has(Vector2i(6, 1)), "kluisje (niet pakbaar)")
	assert_true(vakken.has(Vector2i(4, 1)), "laptop")
	var r: KamerRaster = KamerRaster.uit_kamer(kantoor)
	r.zet_obstakels(vakken)
	assert_true(r.beloopbaar(Vector2i(0, 3)), "uitgang deur_hal")


func test_o8_neerleggen_mijdt_geblokkeerd() -> void:
	var s: Spel = Hulp.nieuw_spel(self)
	var vrij: Variant = s.objecten.vrije_tegel(Hulp.KANTOOR, Vector2i(3, 2))
	assert_not_null(vrij)
	assert_false(Vak.gebied_vakken(kantoor["geblokkeerd"][0]).has(vrij), "geblokkeerd vak is nooit vrij")


func test_kwaliteit_standen() -> void:
	var licht: Dictionary = Kwaliteit.instellingen("licht")
	assert_eq(licht["render_scale"], 0.75)
	assert_true(licht["fsr"])
	assert_eq(licht["msaa"], 0)
	assert_true(licht["fxaa"])
	assert_false(licht["ssr"] or licht["ssao"] or licht["volumetrische_mist"])
	assert_true(licht["glow"])
	var vol: Dictionary = Kwaliteit.instellingen("vol")
	assert_eq(vol["msaa"], 4)
	assert_true(vol["ssr"] and vol["ssao"] and vol["volumetrische_mist"])
	var lichten: Array = []
	for i in range(8):
		lichten.append({"id": "l%d" % i, "schaduw": i != 1})
	assert_eq(Kwaliteit.schaduw_lichten(lichten, "vol").size(), 6)
	assert_eq(Kwaliteit.schaduw_lichten(lichten, "licht"), ["l0", "l2", "l3"] as Array[String])
	assert_eq(Kwaliteit.stand_voor_fps(49.0), "licht")
	assert_eq(Kwaliteit.stand_voor_fps(55.0), "vol")
	assert_eq(Kwaliteit.andere("vol"), "licht")


func test_kwaliteit_bewaren() -> void:
	var pad := "user://test_kwaliteit.cfg"
	DirAccess.remove_absolute(pad)
	assert_eq(Kwaliteit.laad(pad), "")
	Kwaliteit.bewaar("licht", pad)
	assert_eq(Kwaliteit.laad(pad), "licht")
	DirAccess.remove_absolute(pad)


func test_loper_loopt_met_1_4_ms() -> void:
	var l := Loper.new()
	l.zet(Vector2i(0, 0))
	var bereikt: Array[Vector2i] = []
	l.vak_bereikt.connect(func(v: Vector2i) -> void: bereikt.append(v))
	l.start([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)] as Array[Vector2i])
	l.tik(1.0)
	assert_almost_eq(l.positie.x, 0.5 + 1.4, 0.001)
	assert_eq(bereikt, [Vector2i(1, 0)] as Array[Vector2i])
	l.tik(1.0)
	assert_false(l.bezig)
	assert_eq(l.vak, Vector2i(2, 0))
	assert_eq(l.positie, Vak.naar_3d(Vector2i(2, 0)))


func test_loper_nieuw_doel_vanaf_eerstvolgende_vak() -> void:
	var l := Loper.new()
	l.zet(Vector2i(0, 0))
	l.start([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)] as Array[Vector2i])
	l.tik(0.3)
	assert_eq(l.eerstvolgend_vak(), Vector2i(1, 0))
	l.vervang([Vector2i(1, 0), Vector2i(1, 1)] as Array[Vector2i])
	l.tik(5.0)
	assert_eq(l.vak, Vector2i(1, 1))


func test_start_opties() -> void:
	var o: Dictionary = StartOpties.parse(PackedStringArray(["--meet", "ch01_kantoor", "--stand=licht", "--x"]))
	assert_eq(o["meet"], "ch01_kantoor")
	assert_eq(o["stand"], "licht")
	assert_eq(o["x"], "true")


func test_meting_samenvatting() -> void:
	var tijden: Array = []
	for i in range(100):
		tijden.append(1.0 / 60.0)
	tijden[50] = 0.1
	var s: Dictionary = Meting.samenvatting(tijden)
	assert_almost_eq(s["fps_1pct_laagst"], 10.0, 0.01)
	assert_between(s["fps_gem"], 50.0, 60.0)
