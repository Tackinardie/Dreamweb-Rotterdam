extends GutTest
## OI-01 t/m OI-12: objecten en inventaris (OI-13 is een validatortest in tests/python/).

const Hulp = preload("hulp.gd")

var s: Spel


func before_each() -> void:
	s = Hulp.nieuw_spel(self, "objecten")
	s.objecten.open["kast"] = true
	watch_signals(s)


func _in_inventaris(ids: Array) -> void:
	for i: String in ids:
		s.objecten.zet_plek(i, "inventaris")


func test_oi01_elk_object_heeft_precies_een_plek() -> void:
	var items: int = s.content.items.size()
	assert_eq(s.objecten.plek.size(), items, "OI-01: elk object uit items.json heeft een plek")
	var in_lijsten: int = 0
	for p: String in s.objecten.kinderen:
		in_lijsten += (s.objecten.kinderen[p] as Array).size()
	assert_eq(in_lijsten, items, "OI-01: de objectboom bevat elk object precies een keer")
	assert_eq(s.objecten.plek["pasje"], "portemonnee")
	assert_eq(s.objecten.plek["bezorgtas"], "inventaris", "aanname_bij_start")
	assert_eq(s.objecten.plek["rapport"], "kluisje")


func test_oi02_pakken_en_vol() -> void:
	s.objecten.zet_plek("bezorgtas", Hulp.HAL, Vector2i(0, 0))
	assert_true(s.acties.pak("doos")["ok"], "OI-02: grootte 2 met 8 vrije slots lukt")
	assert_eq(s.objecten.plek["doos"], "inventaris")
	# 1 vrij slot, alleen de jas (max_grootte 1) als container
	s.objecten.zet_plek("doos", Hulp.HAL, Vector2i(8, 2))
	_in_inventaris(["pakket", "jas", "koffiekop", "kopje_wit"])
	assert_eq(s.objecten.inventaris_som(), 7)
	var r: Dictionary = s.acties.pak("doos")
	assert_false(r["ok"], "OI-02: past nergens")
	assert_eq(s.objecten.plek["doos"], Hulp.HAL, "het blijft liggen")
	assert_signal_emitted_with_parameters(s, "mompel", [s.tekst("systeem.inventaris.vol"), "systeem.inventaris.vol"])
	assert_has(Hulp.cues(s), "ui.weiger")


func test_oi03_pakken_in_gedragen_container() -> void:
	s.objecten.zet_plek("bezorgtas", Hulp.HAL, Vector2i(0, 0))
	_in_inventaris(["pakket", "jas", "koffiekop", "kopje_wit", "briefje"])
	assert_eq(s.objecten.inventaris_som(), 8, "geen vrije slots")
	s.objecten.zet_plek("kopje_blauw", Hulp.HAL, Vector2i(3, 3))
	assert_true(s.acties.pak("kopje_blauw")["ok"])
	assert_eq(s.objecten.plek["kopje_blauw"], "jas", "OI-03: grootte 1 gaat in de jas")
	assert_false(s.acties.pak("doos")["ok"], "OI-03: grootte 2 past niet in de jas")


func test_oi04_heeft_verandert_met_neerleggen() -> void:
	assert_true(s.acties.pak("jas")["ok"])
	assert_true(Condities.evalueer({"heeft": "pasje"}, s.ctx), "OI-04")
	assert_true(s.objecten.leg_neer("jas", Hulp.HAL, s.positie)["ok"])
	assert_false(Condities.evalueer({"heeft": "pasje"}, s.ctx))
	assert_true(Condities.evalueer({"ligt": {"object": "pasje", "in": Hulp.HAL}}, s.ctx))


func test_oi05_container_in_zichzelf_of_nakomeling_faalt() -> void:
	_in_inventaris(["jas"])
	var voor: String = s.staat_hash()
	assert_false(s.objecten.stop_in("jas", "jas", Hulp.HAL)["ok"])
	assert_false(s.objecten.stop_in("jas", "portemonnee", Hulp.HAL)["ok"], "portemonnee zit in de jas")
	assert_false(s.objecten.stop_in("jas", "pasje", Hulp.HAL)["ok"], "pasje is geen container")
	assert_eq(s.staat_hash(), voor, "OI-05: niets veranderd")
	assert_false(Hulp.cues(s).has("object.in_container"))


func test_oi06_en_oi07_willekeurige_acties_houden_de_regels() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260101
	for c: String in s.content.items:
		if s.objecten.is_container(c):
			s.objecten.open[c] = true
	var beweegbaar: Array = []
	for id: String in s.content.items:
		if s.objecten.is_pakbaar(id) and [Hulp.HAL, "inventaris"].has(s.objecten.wortel(id)):
			beweegbaar.append(id)
	var gelukt: int = 0
	for stap in range(1000):
		var item: String = beweegbaar[rng.randi() % beweegbaar.size()]
		var r: Dictionary
		match rng.randi() % 4:
			0: r = s.objecten.pak(item, Hulp.HAL)
			1: r = s.objecten.leg_neer(item, Hulp.HAL, Vector2i(rng.randi() % 10, rng.randi() % 8))
			2: r = s.objecten.stop_in(item, beweegbaar[rng.randi() % beweegbaar.size()], Hulp.HAL)
			3: r = s.objecten.uitpakken(item)
		gelukt += 1 if r.get("ok", false) else 0
		assert_lte(s.objecten.inventaris_som(), 8, "OI-07 na stap %d" % stap)
		for c: String in s.content.items:
			if s.objecten.is_container(c):
				if s.objecten.inhoud_som(c) > s.objecten.capaciteit(c):
					fail_test("OI-06: %s is over de capaciteit na stap %d" % [c, stap])
					return
				for k: String in s.objecten.kinderen.get(c, []):
					if s.objecten.grootte(k) > s.objecten.max_grootte(c):
						fail_test("OI-06: %s is te groot voor %s na stap %d" % [k, c, stap])
						return
			if s.objecten.ligt(c, c):
				fail_test("OI-05/06: %s zit in zichzelf na stap %d" % [c, stap])
				return
		if s.objecten.inventaris_som() > 8:
			return
	assert_gt(gelukt, 150, "de willekeurige acties doen daadwerkelijk iets (%d gelukt)" % gelukt)


func test_oi08_neerleggen_op_tegel_of_buur() -> void:
	_in_inventaris(["kopje_wit", "koffiekop"])
	var r1: Dictionary = s.objecten.leg_neer("kopje_wit", Hulp.HAL, Vector2i(6, 6))
	assert_eq(r1["tegel"], Vector2i(6, 6), "OI-08: op de tegel van de speler")
	var r2: Dictionary = s.objecten.leg_neer("koffiekop", Hulp.HAL, Vector2i(6, 6))
	assert_true(r2["ok"])
	assert_ne(r2["tegel"], Vector2i(6, 6), "bezet: een buurtegel")
	assert_lte(absi(r2["tegel"].x - 6), 1)
	assert_lte(absi(r2["tegel"].y - 6), 1)
	# nooit op een uitgang (9,4) of NPC
	_in_inventaris(["briefje"])
	var r3: Dictionary = s.objecten.leg_neer("briefje", Hulp.HAL, Vector2i(9, 4))
	assert_ne(r3["tegel"], Vector2i(9, 4), "niet op een uitgang")
	# alles geblokkeerd: lukt niet
	_in_inventaris(["pakket"])
	var alles: Array = []
	for x in range(0, 3):
		for y in range(0, 3):
			alles.append(Vector2i(x, y))
	var r4: Dictionary = s.objecten.leg_neer("pakket", Hulp.HAL, Vector2i(1, 1), alles)
	assert_false(r4["ok"])
	assert_eq(s.objecten.plek["pakket"], "inventaris")
	assert_signal_emitted_with_parameters(s, "mompel", [s.tekst("systeem.neerleggen.geen_plek"), "systeem.neerleggen.geen_plek"])
	# kamer met neerleggen: false
	s.verplaats_speler(Hulp.DAK, "", false)
	assert_false(s.objecten.leg_neer("pakket", Hulp.DAK, s.positie)["ok"])
	assert_signal_emitted_with_parameters(s, "mompel", [s.tekst("systeem.neerleggen.niet_hier"), "systeem.neerleggen.niet_hier"])


func test_oi09_neergelegd_object_blijft_liggen_na_kamerwissel_en_laden() -> void:
	_in_inventaris(["kopje_wit"])
	var pos: Vector2i = s.objecten.leg_neer("kopje_wit", Hulp.HAL, Vector2i(6, 6))["tegel"]
	s.verplaats_speler(Hulp.KANTOOR, "", false)
	s.verplaats_speler(Hulp.HAL, "deur_kantoor", false)
	assert_eq(s.objecten.positie["kopje_wit"], pos, "OI-09: na verlaten en terugkomen")
	assert_true(s.opslag.schrijf("handmatig"))
	var s2: Spel = Hulp.nieuw_spel(self, "objecten")
	assert_true(s2.opslag.laad("handmatig")["ok"])
	assert_eq(s2.objecten.plek["kopje_wit"], Hulp.HAL)
	assert_eq(s2.objecten.positie["kopje_wit"], pos, "OI-09: na opslaan en laden")


func test_oi10_scenewissel_geweigerd_zolang_onmisbaar_object_in_vervallende_kamer() -> void:
	# rapport zit in het kluisje in het kantoor; s2 heeft het kantoor niet
	Hulp.voeg_scene_toe(s, "ch01_sklein", [Hulp.HAL, Hulp.DAK], {"dag": 1, "tijd": "09:00"})
	var r: Dictionary = s.naar_scene("ch01_sklein")
	assert_false(r["ok"], "OI-10: geweigerd (rapport genest in kluisje)")
	assert_eq(r["object"], "rapport")
	assert_eq(s.klok.scene, Hulp.S1)
	assert_signal_emitted_with_parameters(s, "mompel", [s.tekst("systeem.niet_zonder", {"object": "rapport"}), "systeem.niet_zonder"])
	assert_eq(s.tekst("systeem.niet_zonder", {"object": "rapport"}), "Mijn rapport ligt er nog.")
	s.objecten.zet_plek("rapport", "inventaris")
	assert_true(s.naar_scene("ch01_sklein")["ok"], "na ophalen gaat het door")
	assert_eq(s.klok.scene, "ch01_sklein")


func test_oi11_container_met_open_vereist() -> void:
	s.verplaats_speler(Hulp.KANTOOR, "", false)
	var r: Dictionary = s.acties.open("kluisje")
	assert_false(r["ok"], "OI-11: zonder code gaat hij niet open")
	assert_eq(r["tekst"], "item.kluisje.geweigerd")
	assert_signal_emitted_with_parameters(s, "mompel", ["Op slot. Er zit een cijferslot op.", "item.kluisje.geweigerd"])
	assert_false(s.objecten.open.has("kluisje"))
	s.geef_token("code_kluis")
	assert_true(s.acties.open("kluisje")["ok"])
	assert_true(s.objecten.open.has("kluisje"))
	assert_true(s.opslag.schrijf("handmatig"))
	var s2: Spel = Hulp.nieuw_spel(self, "objecten")
	s2.opslag.laad("handmatig")
	assert_true(s2.objecten.open.has("kluisje"), "blijft open na laden")


func test_oi12_elke_actie_roept_zijn_cue_aan() -> void:
	s.acties.pak("jas")                                    # object.pak
	s.objecten.leg_neer("jas", Hulp.HAL, s.positie)        # object.leg
	s.acties.pak("kopje_wit")
	s.objecten.stop_in("kopje_wit", "bezorgtas", Hulp.HAL)  # object.in_container
	s.acties.open("bezorgtas")                             # container.open
	var c: Array = Hulp.cues(s)
	for verwacht: String in ["object.pak", "object.leg", "object.in_container", "container.open"]:
		assert_has(c, verwacht, "OI-12: " + verwacht)
	# override uit geluid van het object: rapport -> object.lees bij pakken
	s.verplaats_speler(Hulp.KANTOOR, "", false)
	s.geef_token("code_kluis")
	s.acties.open("kluisje")
	s.audio.logboek.clear()
	s.acties.pak("rapport")
	assert_eq(Hulp.cues(s).filter(func(x: String) -> bool: return x.begins_with("object.")), ["object.lees"], "override uit geluid")
