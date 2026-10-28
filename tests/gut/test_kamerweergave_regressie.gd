extends GutTest
## Regressietests uit de code-review fundament-3d: B1 (hover na pakken), M1 (spel_geladen), M2 (stand na neerleggen),
## M3 (NPC aanwezig), M7 (Meting, Voorlader, klik buiten de kamer).

const Hulp = preload("hulp.gd")
const TIK: float = 1.0 / 60.0

var spel: Spel
var w: KamerWeergave


func _start(kamer: String, uitgang: String) -> void:
	spel = Hulp.nieuw_spel(self, "regressie")
	spel.verplaats_speler(kamer, uitgang, false)
	w = KamerWeergave.new()
	add_child_autofree(w)
	w.bewaarpad = "user://test_instellingen.cfg"
	w.start(spel, Kwaliteit.VOL, false)


func _tik(seconden: float) -> void:
	for _i in range(ceili(seconden / TIK)):
		w.tik(TIK)


func test_b1_hover_op_gepakt_object_geeft_geen_fout() -> void:
	_start(Hulp.HAL, "deur_kantoor")
	w.hover_op(w.root.ding("koffiekop"))
	_tik(0.4)
	assert_true(w.glas.zichtbaar)
	spel.objecten.zet_plek("koffiekop", "inventaris")
	assert_true(w.hover.is_empty(), "hover gewist")
	assert_false(w.glas.zichtbaar)
	assert_false(w.ui.naam.visible)
	_tik(1.0)     # een scriptfout per frame zou hier de test laten falen
	assert_null(w.root.get_node_or_null("koffiekop"))


func test_m1_geladen_save_herbouwt_de_kamer() -> void:
	_start(Hulp.KANTOOR, "deur_hal")
	w.bekijk_ding("laptop")
	assert_eq(w.staat, "closeup")
	spel.kamer = Hulp.HAL
	spel.positie = Vector2i(5, 6)
	spel.spel_geladen.emit()
	assert_eq(w.root.kamer_id, Hulp.HAL)
	assert_eq(w.loper.vak, Vector2i(5, 6))
	assert_eq(w.staat, "spelen")
	assert_true(w.camera.current)
	assert_false(spel.blokkades.has("closeup"))


func test_m2_neergelegd_object_krijgt_geen_stand() -> void:
	_start(Hulp.KANTOOR, "deur_hal")
	spel.content.items["laptop"]["pakbaar"] = true
	spel.content.items["laptop"]["grootte"] = 1
	assert_eq((w.root.get_node("laptop") as Node3D).position.y, 0.75, "op zijn beginvak: met stand")
	spel.objecten.zet_plek("laptop", "inventaris")
	spel.objecten.zet_plek("laptop", Hulp.KANTOOR, Vector2i(2, 2))
	assert_eq((w.root.get_node("laptop") as Node3D).position, Vector3(2.5, 0, 2.5))


func test_m3_npc_die_verdwijnt_maakt_vak_beloopbaar_en_herberekent_pad() -> void:
	_start(Hulp.HAL, "deur_kantoor")
	var npcs: Array = spel.content.kamers[Hulp.HAL]["npcs"].duplicate(true)
	assert_not_null(w.root.get_node_or_null("portier"))
	var vak: Vector2i = Vak.uit_positie(npcs[0]["positie"])
	assert_false(w.root.raster.beloopbaar(vak))
	w.klik_vak(Vector2i(1, 5))
	_tik(0.5)
	assert_true(w.loper.bezig)
	spel.content.kamers[Hulp.HAL]["npcs"] = []
	_tik(0.3)
	assert_null(w.root.get_node_or_null("portier"), "NPC weg")
	assert_true(w.root.raster.beloopbaar(vak))
	_tik(10.0)
	assert_eq(w.loper.vak, Vector2i(1, 5), "pad opnieuw berekend, doel bereikt")
	spel.content.kamers[Hulp.HAL]["npcs"] = npcs
	_tik(0.3)
	assert_not_null(w.root.get_node_or_null("portier"), "NPC terug")
	assert_false(w.root.raster.beloopbaar(vak))


func test_klik_buiten_de_kamer_tijdens_lopen_laat_pad_staan() -> void:
	_start(Hulp.KANTOOR, "deur_hal")
	w.klik_vak(Vector2i(2, 5))
	_tik(0.3)
	w.klik_vak(Vector2i(40, 40))
	_tik(10.0)
	assert_eq(w.loper.vak, Vector2i(2, 5))


func test_meting_schrijft_alle_velden() -> void:
	_start(Hulp.KANTOOR, "deur_hal")
	var m := Meting.new()
	m.weergave = w
	add_child_autofree(m)
	m.set_process(false)
	var r: Dictionary = m.resultaat()
	var pad: String = Meting.schrijf(r, "user://test_meting")
	var gelezen: Variant = JSON.parse_string(FileAccess.get_file_as_string(pad))
	for veld in ["kamer", "stand", "fps_gem", "fps_1pct_laagst", "meshes", "lichten", "lichten_schaduw", "gpu", "resolutie"]:
		assert_true((gelezen as Dictionary).has(veld), veld)
	assert_eq(gelezen["kamer"], Hulp.KANTOOR)
	DirAccess.remove_absolute(pad)


func test_voorlader_zonder_modellen_is_meteen_klaar() -> void:
	_start(Hulp.KANTOOR, "deur_hal")
	var v := Voorlader.new()
	v.vraag_buren(spel.content, Hulp.KANTOOR)
	assert_true(v.klaar())
	assert_eq(v.aangevraagd.size(), 0)
