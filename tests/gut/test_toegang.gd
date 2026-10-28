extends GutTest
## TG-01 t/m TG-09 en TG-11: toegang. (TG-10 is een validatortest in tests/python/.)

const Hulp = preload("hulp.gd")

var s: Spel


func before_each() -> void:
	s = Hulp.nieuw_spel(self, "toegang")
	s.objecten.open["kast"] = true
	watch_signals(s)


func test_tg01_uitgang_zonder_vereist_gaat_door() -> void:
	s.verplaats_speler(Hulp.KANTOOR, "", false)
	var r: Dictionary = s.toegang.doorgang(Hulp.KANTOOR, "deur_hal")
	assert_true(r["ok"])
	assert_eq(s.kamer, Hulp.HAL)
	assert_eq(s.positie, Vector2i(9, 4), "TG-01: bij naar_uitgang deur_kantoor")
	assert_has(Hulp.cues(s), "deur.open")


func test_tg02_geweigerd_met_tekst_en_cue_en_met_token_doorgang() -> void:
	# deur zonder pas: geweigerd
	var r: Dictionary = s.toegang.doorgang(Hulp.HAL, "deur_kantoor")
	assert_false(r["ok"])
	assert_eq(r["tekst"], "uitgang.ch01_hal.deur_kantoor.geweigerd")
	assert_eq(s.kamer, Hulp.HAL, "kamer onveranderd")
	assert_has(Hulp.cues(s), "deur.geweigerd")
	assert_signal_emitted_with_parameters(s, "mompel", ["Alleen voor personeel met een pas.", "uitgang.ch01_hal.deur_kantoor.geweigerd"])
	# lift naar het dak vraagt een token
	s.verplaats_speler(Hulp.KANTOOR, "", false)
	var geweigerd: Dictionary = s.toegang.kies_bestemming(Hulp.KANTOOR, "lift_kantoor", 1)
	assert_false(geweigerd["ok"], "TG-02: zonder token")
	assert_has(Hulp.cues(s), "lift.geweigerd")
	s.geef_token("kantoorkennis")
	assert_true(s.toegang.kies_bestemming(Hulp.KANTOOR, "lift_kantoor", 1)["ok"], "TG-02: met token")
	assert_eq(s.kamer, Hulp.DAK)
	assert_has(Hulp.cues(s), "lift.rit")


func test_tg03_per_kant_een_eigen_regel() -> void:
	assert_false(s.toegang.doorgang(Hulp.HAL, "deur_kantoor")["ok"], "van buiten geweigerd")
	s.verplaats_speler(Hulp.KANTOOR, "", false)
	assert_true(s.toegang.doorgang(Hulp.KANTOOR, "deur_hal")["ok"], "van binnen vrij")


func test_tg04_gebeurtenis_wordt_bij_aankomst_geevalueerd() -> void:
	s.geef_token("pauze_tijd")
	s.puzzel.herzie()
	assert_eq(s.klok.status("ch01_pauze_portier"), "actief")
	var u: Dictionary = s.toegang.uitgang(Hulp.HAL, "deur_kantoor")
	assert_true(s.toegang.controleer(u, u)["ok"], "bij het klikken staat de deur open")
	s.speel(21.0)   # de pauze duurt 20 seconden en is voorbij tegen de tijd dat hij aankomt
	assert_ne(s.klok.status("ch01_pauze_portier"), "actief")
	var r: Dictionary = s.toegang.doorgang(Hulp.HAL, "deur_kantoor")
	assert_false(r["ok"], "TG-04: bij aankomst geweigerd")
	assert_eq(s.kamer, Hulp.HAL)


func test_tg05_liftpaneel_toont_bestemmingen_en_dimt() -> void:
	var knoppen: Array = s.toegang.doorgang(Hulp.HAL, "lift_hal")["knoppen"]
	assert_eq(knoppen.size(), 2, "twee bestemmingen vanuit de hal")
	assert_true(knoppen.all(func(k: Dictionary) -> bool: return k["gedimd"]), "zonder pas of token zijn beide gedimd")
	s.verplaats_speler(Hulp.KANTOOR, "", false)
	var vanuit_kantoor: Array = s.toegang.lift_paneel(Hulp.KANTOOR, "lift_kantoor")
	assert_eq(vanuit_kantoor.map(func(k: Dictionary) -> String: return k["naar_kamer"]), [Hulp.HAL, Hulp.DAK], "alle bestemmingen behalve de eigen kamer")
	assert_false(vanuit_kantoor[0]["gedimd"], "naar de hal is vrij")
	assert_true(vanuit_kantoor[1]["gedimd"], "naar het dak niet zonder token")
	var vanaf_dak: Array = s.toegang.lift_paneel(Hulp.DAK, "lift_dak")
	assert_eq(vanaf_dak.size(), 2)
	assert_false(s.toegang.kies_bestemming(Hulp.KANTOOR, "lift_kantoor", 1)["ok"], "gedimde knop weigert")


func test_tg06_niveau_van_een_pas() -> void:
	var n: Dictionary = {"niveau": "proef.kantoor"}
	assert_false(Condities.evalueer(n, s.ctx))
	s.acties.pak("jas")   # pasje zit genest in jas > portemonnee
	assert_true(Condities.evalueer(n, s.ctx), "TG-06: ook genest")
	assert_false(Condities.evalueer({"niveau": "proef.dak"}, s.ctx), "geen niveau dak: een pas geeft alleen wat erop staat")
	assert_true(s.toegang.doorgang(Hulp.HAL, "deur_kantoor")["ok"], "met pas door de deur")


func test_tg07_als_bezorger() -> void:
	var c: Dictionary = {"conditie": "als_bezorger"}
	assert_false(Condities.evalueer(c, s.ctx), "alleen bezorgtas")
	s.acties.pak("jas")
	assert_true(Condities.evalueer(c, s.ctx), "bezorgtas en jas")
	s.objecten.leg_neer("jas", Hulp.HAL, s.positie)
	assert_false(Condities.evalueer(c, s.ctx), "jas weer weg")
	s.objecten.zet_plek("jas", "inventaris")
	s.objecten.zet_plek("bezorgtas", Hulp.HAL, Vector2i(0, 0))
	assert_false(Condities.evalueer(c, s.ctx), "TG-07: een ontbreekt")


func test_tg08_npc_kiest_eerste_gesprek_met_kloppende_als() -> void:
	var npc: Dictionary = s.npcs_in_kamer(Hulp.HAL)[0]
	assert_eq(s.toegang.kies_gesprek(npc), "ch01_portier_praat")
	s.acties.pak("jas")
	assert_eq(s.toegang.kies_gesprek(npc), "ch01_portier_bezorger", "TG-08: als_bezorger geeft een ander gesprek")


func test_tg09_uitgang_naar_kamer_buiten_de_scene() -> void:
	s.naar_scene(Hulp.S2, "", "", true)
	var r: Dictionary = s.toegang.doorgang(Hulp.HAL, "deur_kantoor")
	assert_false(r["ok"])
	assert_eq(r["tekst"], "systeem.uitgang.niet_nu", "TG-09")
	assert_eq(r["reden"], "niet_nu")


func test_tg11_autosave_na_doorgang() -> void:
	Hulp.wis_map(s.opslag.map)
	s.acties.pak("jas")
	assert_false(FileAccess.file_exists(s.opslag.pad("auto")))
	assert_true(s.toegang.doorgang(Hulp.HAL, "deur_kantoor")["ok"])
	assert_true(FileAccess.file_exists(s.opslag.pad("auto")), "TG-11")
	assert_signal_emitted(s, "autosave_geschreven")
	assert_has(Hulp.cues(s), "ui.opslaan")
