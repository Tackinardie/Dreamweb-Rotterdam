extends GutTest
## De kamerweergave headless (kamerweergave.md, W26): opbouw, klikken, contour, vergrootglas, close-up,
## kamerwissel, droomovergang, kwaliteitsstanden en budget. KW-02 t/m KW-04, KW-08 t/m KW-15.

const Hulp = preload("hulp.gd")
const TIK: float = 1.0 / 60.0

var spel: Spel
var w: KamerWeergave


func before_each() -> void:
	spel = Hulp.nieuw_spel(self, "weergave")
	spel.verplaats_speler(Hulp.KANTOOR, "deur_hal", false)
	w = KamerWeergave.new()
	add_child_autofree(w)
	w.bewaarpad = "user://test_instellingen.cfg"
	w.start(spel, Kwaliteit.VOL, false)


func after_each() -> void:
	KwaliteitToepassen.op_viewport(Kwaliteit.VOL, get_viewport())
	DirAccess.remove_absolute("user://test_instellingen.cfg")


func _tik(seconden: float) -> void:
	var n: int = ceili(seconden / TIK)
	for _i in range(n):
		w.tik(TIK)


func _mesh(naam: String) -> MeshInstance3D:
	return w.root.find_child(naam, true, false) as MeshInstance3D


func test_kw02_placeholder_vloer_en_muren() -> void:
	var vloer: AABB = w.root.aabb_van(_mesh("vloer"))
	assert_almost_eq(vloer.position, Vector3(0, -0.1, 0), Vector3(0.001, 0.001, 0.001))
	assert_almost_eq(vloer.end, Vector3(8, 0, 6), Vector3(0.001, 0.001, 0.001), "vloer X 0-8, Z 0-6, bovenkant Y 0")
	assert_almost_eq(w.root.aabb_van(_mesh("wand_achter")).end.y, 2.6, 0.001)
	assert_almost_eq(w.root.aabb_van(_mesh("wand_links")).end.y, 2.6, 0.001)
	assert_lte(w.root.aabb_van(_mesh("wand_voor")).end.y, 0.5)
	assert_lte(w.root.aabb_van(_mesh("wand_rechts")).end.y, 0.5)


func test_kw03_objecten_op_hun_vakmiddens() -> void:
	var r: KamerRoot = w.root
	assert_eq((r.get_node("kluisje") as Node3D).position, Vector3(6.5, 0, 1.5))
	assert_eq((r.get_node("laptop") as Node3D).position, Vector3(4.5, 0.75, 1.5))
	assert_eq((r.get_node("prullenbak") as Node3D).position, Vector3(6.5, 0, 4.5))
	assert_null(r.get_node_or_null("rapport"), "zit in het kluisje")
	assert_not_null(r.get_node_or_null("deur_hal"))
	assert_not_null(r.get_node_or_null("lift_kantoor"))
	assert_eq((r.get_node("deur_hal") as Node3D).position, Vector3(0.5, 0, 3.5))


func test_kw04_lichten_uit_data() -> void:
	var tl := w.root.get_node("tl_plafond") as SpotLight3D
	var lamp := w.root.get_node("bureaulamp") as OmniLight3D
	assert_not_null(tl)
	assert_not_null(lamp)
	assert_eq(tl.position, Vector3(3.5, 2.5, 3.5))
	assert_eq(lamp.position, Vector3(3.5, 1.1, 1.5))
	assert_eq(tl.light_color, Color.html("#F0F6F0"))
	assert_eq(lamp.light_color, Color.html("#FFD8A0"))
	assert_almost_eq(tl.light_energy, 2.0, 0.001)
	assert_almost_eq(lamp.light_energy, 1.2, 0.001)
	assert_eq(w.root.omgeving.ambient_light_color, Color.html("#4A6590"))
	assert_almost_eq(tl.global_transform.basis.get_euler().x, -PI / 2, 0.001, "spot recht omlaag")


func test_camera_uit_data() -> void:
	assert_eq(w.camera.fov, 17.0)
	assert_eq(w.camera.near, 0.5)
	assert_eq(w.camera.projection, Camera3D.PROJECTION_PERSPECTIVE)
	assert_eq(w.camera.keep_aspect, Camera3D.KEEP_HEIGHT)
	assert_true(w.camera.current)
	var voor: Vector3 = -w.camera.global_transform.basis.z
	var punt: Variant = Vak.vloer_snijpunt(w.camera.global_position, voor)
	assert_almost_eq(punt as Vector3, Vector3(4, 0, 3), Vector3(0.01, 0.01, 0.01))


func test_kw08_klik_op_laptop_loopt_ernaast_en_gebruikt() -> void:
	w.zet_richard(Vector2i(1, 3))
	var acties: Array = []
	w.actie_uitgevoerd.connect(func(id: String, actie: String) -> void: acties.append([id, actie]))
	w.klik_ding("laptop")
	_tik(10.0)
	assert_true(w.root.raster.beloopbaar(w.loper.vak))
	assert_lte(absi(w.loper.vak.x - 4), 1)
	assert_lte(absi(w.loper.vak.y - 1), 1)
	assert_eq(spel.positie, w.loper.vak, "Richards positie in de save is een vak")
	assert_eq(acties, [["laptop", "gebruik"]])


func test_kw08_klik_op_geblokkeerd_vak() -> void:
	w.zet_richard(Vector2i(1, 3))
	w.klik_vak(Vector2i(3, 1))
	_tik(10.0)
	assert_true(w.root.raster.beloopbaar(w.loper.vak))
	assert_lte((w.loper.vak - Vector2i(3, 1)).length(), 1.5)


func test_klik_via_scherm_raakt_vloer() -> void:
	w.zet_richard(Vector2i(1, 3))
	var scherm: Vector2 = w.camera.unproject_position(Vak.naar_3d(Vector2i(2, 4)))
	assert_eq(w.vloer_vak_scherm(scherm), Vector2i(2, 4))
	var p: Dictionary = w.pik_scherm(w.camera.unproject_position(w.root.aabb_van(w.root.get_node("laptop")).get_center()))
	assert_eq(p.get("id"), "laptop")


func test_nieuwe_klik_tijdens_lopen_vervangt_doel() -> void:
	w.zet_richard(Vector2i(1, 3))
	w.klik_vak(Vector2i(6, 5))
	_tik(0.5)
	w.klik_vak(Vector2i(1, 5))
	_tik(10.0)
	assert_eq(w.loper.vak, Vector2i(1, 5))


func test_kw09_spatie_toont_alles() -> void:
	w.zet_spatie(true)
	var met: Array = []
	for p in w.root.pickbaar:
		if Contour.is_aan(p["node"]):
			met.append(p["id"])
	met.sort()
	assert_eq(met, ["deur_hal", "kluisje", "laptop", "lift_kantoor", "prullenbak"])
	var n: int = Hulp.cues(spel).count("ui.highlight")
	assert_eq(n, 1)
	w.zet_spatie(true)
	assert_eq(Hulp.cues(spel).count("ui.highlight"), 1, "een keer per indrukken")
	w.zet_spatie(false)
	for p in w.root.pickbaar:
		assert_false(Contour.is_aan(p["node"]), p["id"])


func test_hover_geeft_contour_en_vergrootglas_kw10() -> void:
	var p: Dictionary = w.root.ding("laptop")
	w.hover_op(p)
	assert_true(Contour.is_aan(p["node"]))
	assert_false(w.glas.zichtbaar)
	_tik(0.4)
	assert_true(w.glas.zichtbaar)
	assert_eq(w.glas.viewport.size, Vector2i(256, 256))
	assert_eq(w.glas.viewport.world_3d, w.get_world_3d(), "dezelfde World3D")
	assert_almost_eq(w.glas.camera.fov, 17.0 / 2.5, 0.001)
	w.hover_op({})
	assert_false(w.glas.zichtbaar)
	assert_false(Contour.is_aan(p["node"]))


func test_hover_op_geblokkeerd_blok_toont_niets() -> void:
	var blok: Vector3 = w.root.aabb_van(w.root.find_child("blok_0", true, false)).get_center()
	var p: Dictionary = w.root.pik(w.camera.project_ray_origin(w.camera.unproject_position(blok + Vector3(-0.9, 0, 0))),
			w.camera.project_ray_normal(w.camera.unproject_position(blok + Vector3(-0.9, 0, 0))))
	w.hover_op(p)
	_tik(0.5)
	assert_false(w.glas.zichtbaar)
	assert_true(w.hover.is_empty())


func test_kw11_closeup() -> void:
	var voor: String = spel.staat_hash()
	w.bekijk_ding("laptop")
	assert_eq(w.staat, "closeup")
	assert_true(w.closeup_camera.current)
	_tik(0.4)
	var midden: Vector3 = w.root.aabb_van(w.root.get_node("laptop")).get_center()
	assert_almost_eq(w.closeup_camera.global_position.distance_to(midden), 0.8, 0.01)
	assert_true(spel.blokkades.has("closeup"), "strook vergrendeld")
	assert_true(Hulp.cues(spel).has("ui.closeup.open"))
	var tijdens: String = spel.staat_hash()
	w.klik_vak(Vector2i(5, 4))
	_tik(1.0)
	assert_eq(w.loper.vak, Vector2i(0, 3), "geen lopen tijdens de close-up")
	w.sluit_closeup()
	_tik(0.4)
	assert_true(w.camera.current)
	assert_eq(w.staat, "spelen")
	assert_true(Hulp.cues(spel).has("ui.closeup.sluit"))
	assert_false(spel.blokkades.has("closeup"))
	assert_eq(spel.staat_hash(), tijdens, "sluiten verandert geen spelstatus")
	assert_ne(voor, "")


func test_bekijk_zonder_closeup_toont_alleen_tekst() -> void:
	w.bekijk_ding("prullenbak")
	assert_eq(w.staat, "spelen")
	assert_true(w.ui.tekst.visible)


func test_kw12_door_deur_naar_hal_zonder_laadscherm() -> void:
	var oude: KamerRoot = w.root
	w.zet_richard(Vector2i(1, 3))
	w.klik_ding("deur_hal")
	var t: float = 0.0
	while t < 10.0 and (spel.kamer != Hulp.HAL or w.staat != "spelen"):
		w.tik(TIK)
		t += TIK
	assert_eq(spel.kamer, Hulp.HAL)
	assert_eq(w.root.kamer_id, Hulp.HAL)
	assert_eq(w.loper.vak, Vector2i(9, 4), "Richard staat op deur_kantoor")
	assert_false(is_instance_valid(oude), "oude kamer vrijgegeven")
	for n in w.find_children("*", "", true, false):
		assert_false("laad" in n.name.to_lower(), "geen laadscherm: " + n.name)


func test_kw12_overgang_duurt_hooguit_0_6_s() -> void:
	spel.verplaats_speler(Hulp.HAL, "deur_kantoor", false)
	assert_eq(w.staat, "overgang")
	var t: float = 0.0
	while w.overgang.actief and t < 5.0:
		w.tik(TIK)
		t += TIK
	assert_lte(w.overgang.duur, 0.6)
	assert_eq(w.root.kamer_id, Hulp.HAL)
	assert_eq(w.staat, "spelen")


func test_kw13_droomovergang() -> void:
	spel.content.kamers[Hulp.HAL]["soort"] = "droom"
	spel.verplaats_speler(Hulp.HAL, "deur_kantoor", false)
	assert_true(Hulp.cues(spel).has("droom.overgang"))
	assert_true(spel.gepauzeerd, "speeltijd staat stil")
	var t: float = 0.0
	var midden: float = -1.0
	while w.overgang.actief and t < 5.0:
		w.tik(TIK)
		t += TIK
		if absf(t - 0.75) < TIK / 2.0:
			midden = w.overgang.filter
		assert_true(spel.gepauzeerd or not w.overgang.actief)
	assert_almost_eq(w.overgang.duur, 1.5, 0.1)
	assert_almost_eq(w.overgang.max_filter, 1.0, 0.01)
	assert_gt(midden, 0.95)
	assert_eq(w.overgang.filter, 0.0)
	assert_false(spel.gepauzeerd)
	assert_false(spel.blokkades.has("droom"))


func test_kw14_licht_en_terug_naar_vol() -> void:
	var vp: Viewport = get_viewport()
	w.zet_stand("licht")
	assert_eq(vp.scaling_3d_scale, 0.75)
	assert_eq(vp.scaling_3d_mode, Viewport.SCALING_3D_MODE_FSR)
	assert_eq(vp.msaa_3d, Viewport.MSAA_DISABLED)
	assert_eq(vp.screen_space_aa, Viewport.SCREEN_SPACE_AA_FXAA)
	var e: Environment = w.root.omgeving
	assert_false(e.ssr_enabled or e.ssao_enabled or e.volumetric_fog_enabled)
	assert_true(e.glow_enabled)
	assert_eq(w.glas.viewport.scaling_3d_scale, 0.75, "ook op het vergrootglas")
	assert_eq(Kwaliteit.laad(w.bewaarpad), "licht", "keuze staat in de instellingen")
	w.zet_stand("vol")
	assert_eq(vp.scaling_3d_scale, 1.0)
	assert_eq(vp.msaa_3d, Viewport.MSAA_4X)
	assert_eq(vp.screen_space_aa, Viewport.SCREEN_SPACE_AA_DISABLED)
	assert_true(e.ssr_enabled and e.ssao_enabled and e.volumetric_fog_enabled)


func test_kw14_schaduwlichten_per_stand() -> void:
	assert_eq(w.root.tel_schaduwlichten(), 2)
	var lichten: Array = []
	for i in range(8):
		lichten.append({"id": "x%d" % i, "schaduw": true})
		var l := OmniLight3D.new()
		l.name = "x%d" % i
		w.root.add_child(l)
		w.root.licht_nodes["x%d" % i] = l
	w.root.kamer = w.root.kamer.duplicate()
	w.root.kamer["lichten"] = lichten
	w.zet_stand("vol")
	assert_eq(w.root.tel_schaduwlichten(), 6)
	w.zet_stand("licht")
	assert_eq(w.root.tel_schaduwlichten(), 3)


func test_kw15_budget_in_beide_standen() -> void:
	for stand in ["vol", "licht"]:
		w.zet_stand(stand)
		assert_lte(w.root.tel_meshes(), 300, stand)
		assert_lte(w.root.tel_lichten(), 16, stand)
		assert_lte(w.root.tel_schaduwlichten(), 6 if stand == "vol" else 3, stand)


func test_object_pakken_haalt_node_weg_en_maakt_vak_vrij() -> void:
	var item: String = "koffiekop"
	spel.verplaats_speler(Hulp.HAL, "deur_kantoor", false)
	var t: float = 0.0
	while w.overgang.actief and t < 5.0:
		w.tik(TIK)
		t += TIK
	assert_not_null(w.root.get_node_or_null(item))
	assert_true(w.root.raster.beloopbaar(spel.objecten.positie[item]), "pakbaar blokkeert niet")
	spel.objecten.zet_plek(item, "inventaris")
	assert_null(w.root.get_node_or_null(item), "node verdwijnt als het object weg is")
