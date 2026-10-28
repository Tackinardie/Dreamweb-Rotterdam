extends GutTest
## SF-01 t/m SF-07: de conditietaal. De gedeelde testset draait ook in Python (tests/python/test_condities.py).

const Hulp = preload("hulp.gd")


func test_sf01_gedeelde_testset_geeft_dezelfde_uitkomsten() -> void:
	var testset: Dictionary = JsonLezer.lees(Hulp.repo().path_join("tests/fixtures/condities.json"))
	assert_gt((testset["gevallen"] as Array).size(), 50, "SF-01: de testset is niet leeg")
	var fout_gevallen: Array = []
	for g: Dictionary in testset["gevallen"]:
		var ctx := Hulp.DictContext.new(g["toestand"], testset["benoemd"])
		var uitkomst: bool = Condities.evalueer(g["conditie"], ctx)
		if uitkomst != g["verwacht"]:
			fout_gevallen.append(g["naam"])
		if g.get("geeft_foutregel", false):
			assert_gt(ctx.fouten.size(), 0, "SF-06: foutregel verwacht bij '%s'" % g["naam"])
	assert_eq(fout_gevallen, [], "SF-01: gevallen met een afwijkende uitkomst")


func test_sf01_elke_conditievorm_heeft_waar_en_onwaar_geval() -> void:
	var testset: Dictionary = JsonLezer.lees(Hulp.repo().path_join("tests/fixtures/condities.json"))
	var vormen: Array = ["alle", "een_van", "niet", "heeft", "ligt", "token", "flag", "knoop", "kamer", "scene",
			"gebeurtenis", "kloktijd", "scenetijd", "niveau", "apparaat", "conditie"]
	for vorm: String in vormen:
		var waar: bool = false
		var onwaar: bool = false
		for g: Dictionary in testset["gevallen"]:
			if g["conditie"] is Dictionary and (g["conditie"] as Dictionary).has(vorm):
				if g["verwacht"]:
					waar = true
				else:
					onwaar = true
		assert_true(waar and onwaar, "SF-01: vorm '%s' heeft een waar- en een onwaar-geval" % vorm)


func test_sf02_logica() -> void:
	var ctx := ConditieContext.new()
	assert_false(Condities.evalueer({"alle": [{"niet": {"kamer": "x"}}, {"kamer": "x"}]}, ctx))
	assert_true(Condities.evalueer({"een_van": [{"kamer": "x"}, {"niet": {"kamer": "x"}}]}, ctx))
	assert_true(Condities.evalueer(null, ctx), "afwezige conditie is waar")


func test_sf03_heeft_geneste_inventaris_maar_niet_in_kamercontainer() -> void:
	var s: Spel = Hulp.nieuw_spel(self, "sf03")
	# pasje zit in portemonnee in jas in kast in de hal: niet in de inventaris
	assert_false(Condities.evalueer({"heeft": "pasje"}, s.ctx))
	s.objecten.open["kast"] = true
	assert_true(s.acties.pak("jas")["ok"])
	assert_true(Condities.evalueer({"heeft": "pasje"}, s.ctx), "genest in inventaris, jas, portemonnee")
	assert_true(Condities.evalueer({"ligt": {"object": "pasje", "in": "jas"}}, s.ctx))


func test_sf04_kloktijd_over_middernacht_met_echte_klok() -> void:
	var s: Spel = Hulp.nieuw_spel(self, "sf04")
	var nacht: Dictionary = {"kloktijd": {"van": "23:00", "tot": "06:00"}}
	assert_true(Condities.evalueer(nacht, s.ctx), "00:07 valt in de nacht")
	s.klok.tijd = {"dag": 1, "tijd": "06:00"}
	assert_false(Condities.evalueer(nacht, s.ctx))
	s.klok.tijd = {"dag": 2, "tijd": "00:30"}
	assert_true(Condities.evalueer(nacht, s.ctx), "dag 2, 00:30")


func test_sf05_flag_startwaarde_en_vergelijkingen() -> void:
	var s: Spel = Hulp.nieuw_spel(self, "sf05")
	assert_false(Condities.evalueer({"flag": "ch01_rapport_gepakt"}, s.ctx), "nooit gezet = startwaarde")
	assert_true(Condities.evalueer({"flag": "ch01_bezoeken", "hoogstens": 0}, s.ctx))
	s.zet_flag("ch01_bezoeken", 3)
	assert_true(Condities.evalueer({"flag": "ch01_bezoeken", "minstens": 3}, s.ctx))
	assert_true(Condities.evalueer({"flag": "ch01_bezoeken", "gelijk": 3}, s.ctx))
	assert_false(Condities.evalueer({"flag": "ch01_bezoeken", "gelijk": 2}, s.ctx))


func test_sf06_onbekende_id_is_onwaar_met_foutregel_zonder_crash() -> void:
	var s: Spel = Hulp.nieuw_spel(self, "sf06")
	var voor: int = s.fout_log.size()
	assert_false(Condities.evalueer({"flag": "bestaat_niet"}, s.ctx))
	assert_false(Condities.evalueer({"heeft": "bestaat_niet"}, s.ctx))
	assert_false(Condities.evalueer({"conditie": "bestaat_niet"}, s.ctx))
	assert_false(Condities.evalueer({"gebeurtenis": "ch01_bestaat_niet"}, s.ctx))
	assert_eq(s.fout_log.size(), voor + 4, "SF-06: elke onbekende id geeft een foutregel")


func test_sf07_evalueren_verandert_de_toestand_niet() -> void:
	var s: Spel = Hulp.nieuw_spel(self, "sf07")
	s.objecten.open["kast"] = true
	s.acties.pak("jas")
	var voor: String = s.staat_hash()
	for c: Dictionary in [{"conditie": "als_bezorger"}, {"niveau": "proef.kantoor"}, {"gebeurtenis": "ch01_pauze_portier"},
			{"kloktijd": {"van": "00:00", "tot": "01:00"}}, {"apparaat": "ch01_laptop", "toestand": "ontgrendeld"},
			{"alle": [{"heeft": "jas"}, {"niet": {"token": "code_kluis"}}]}, {"flag": "ch01_bezoeken", "minstens": 1},
			{"ligt": {"object": "pasje", "in": "ch01_hal"}}, {"knoop": "ch01_klaar"}, {"kamer": "ch01_hal"},
			{"scene": "ch01_s1_nacht"}, {"scenetijd": {"vanaf": {"dag": 1, "tijd": "00:00"}}}]:
		Condities.evalueer(c, s.ctx)
	assert_eq(s.staat_hash(), voor, "SF-07: toestand-hash voor en na gelijk")
