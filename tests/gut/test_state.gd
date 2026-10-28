extends GutTest
## SF-08 t/m SF-16: puzzelgraaf, tokens en opslaan. (SF-17 en SF-18 zijn Python-tests.)

const Hulp = preload("hulp.gd")

var s: Spel


func before_each() -> void:
	s = Hulp.nieuw_spel(self, "state")
	s.objecten.open["kast"] = true
	watch_signals(s)


func _dubbele_lees_knoop() -> void:
	var extra: Dictionary = {
		"id": "ch01_extra_lees", "type": "feit", "pad": "zij", "waarom": "Een tweede knoop met dezelfde trigger.",
		"trigger": {"lees": "briefje"}, "effecten": [{"geef_token": "kluis_plek"}],
	}
	Hulp.voeg_knoop_toe(s, extra)


func test_sf08_alleen_de_eerste_knoop_met_dezelfde_trigger_vuurt() -> void:
	_dubbele_lees_knoop()
	var r: Dictionary = s.acties.lees("briefje")
	assert_eq(r["trigger"]["gevuurd"], "ch01_lees_briefje", "SF-08: bestandsvolgorde")
	assert_true(s.tokens.has("code_kluis"))
	assert_false(s.tokens.has("kluis_plek"), "de tweede vuurt niet in dezelfde actie")
	assert_false(s.knopen.has("ch01_extra_lees"))
	# een volgende keer is de eerste opgelost en komt de tweede aan bod
	var r2: Dictionary = s.acties.lees("briefje")
	assert_eq(r2["trigger"]["gevuurd"], "ch01_extra_lees")


func test_sf09_niet_herhaalbare_knoop_vuurt_een_keer() -> void:
	assert_eq(s.acties.lees("briefje")["trigger"]["gevuurd"], "ch01_lees_briefje")
	var tokens_voor: int = s.tokens.size()
	var r: Dictionary = s.acties.lees("briefje")
	assert_eq(r["trigger"]["gevuurd"], "")
	assert_true(r["trigger"]["standaard"], "SF-09: tweede keer de standaardreactie")
	assert_eq(s.tokens.size(), tokens_voor)


func test_sf10_onvervulde_vereist_toont_bij_onvervuld_en_wijzigt_niets() -> void:
	var voor: String = s.staat_hash()
	var r: Dictionary = s.puzzel.trigger({"gebruik": "koffiekop", "met": "prullenbak"})
	assert_eq(r["mompel"], "knoop.ch01_koffie_weg.onvervuld", "koffiekop is niet in de inventaris")
	assert_signal_emitted_with_parameters(s, "mompel", ["Ik heb geen kop meer.", "knoop.ch01_koffie_weg.onvervuld"])
	assert_eq(s.staat_hash(), voor, "SF-10: niets gewijzigd")


func test_sf11_automatische_knoop_vuurt_direct_en_kring_stopt_na_32_rondes() -> void:
	assert_false(s.knopen.has("ch01_auto_dak"))
	s.geef_token("kantoorkennis")
	s.puzzel.herzie()
	assert_true(s.knopen.has("ch01_auto_dak"), "SF-11: direct na het token")
	assert_true(Condities.evalueer({"flag": "ch01_dak_bekend"}, s.ctx))
	# een herhaalbare automatische knoop zonder voorwaarde maakt zichzelf steeds weer waar
	var kring: Dictionary = {
		"id": "ch01_kring", "type": "actie", "pad": "zij", "waarom": "Test van de kringgrens.",
		"trigger": {"automatisch": true}, "herhaalbaar": true, "effecten": [{"zet_flag": "ch01_pauze_bekend"}],
	}
	Hulp.voeg_knoop_toe(s, kring)
	s.fout_log = PackedStringArray()
	s.puzzel.herzie()
	assert_eq(s.fout_log.size(), 1, "SF-11: een foutregel")
	assert_true(s.fout_log[0].contains("32"))


func test_sf12_token_een_keer_met_scenetijd_en_bron() -> void:
	s.geef_token("code_kluis", "ch01_lees_briefje")
	var eerste: Dictionary = (s.tokens["code_kluis"] as Dictionary).duplicate(true)
	assert_eq(eerste["verkregen_op"], {"dag": 1, "tijd": "00:07"})
	assert_eq(eerste["bron_knoop"], "ch01_lees_briefje")
	assert_true(eerste["nieuw"])
	s.geef_token("code_kluis", "een_andere_knoop")
	assert_eq(s.tokens["code_kluis"], eerste, "SF-12: nogmaals geven verandert niets")
	assert_eq(s.token_volgorde.size(), 1)
	assert_signal_emit_count(s, "token_gegeven", 1)
	assert_signal_emit_count(s, "notitie_genoteerd", 1)
	assert_eq(s.notitie_tekst("code_kluis"), "Code van het kluisje: 4127")


func _rijke_staat(spel: Spel) -> void:
	spel.objecten.open["kast"] = true
	spel.acties.pak("jas")
	spel.acties.lees("briefje")
	spel.acties.pak("kopje_wit")
	spel.objecten.leg_neer("kopje_wit", Hulp.HAL, Vector2i(7, 7))
	spel.geef_token("pauze_tijd")
	spel.puzzel.herzie()
	spel.speel(5.0)
	spel.dialoog_keuzes["ch01_portier_praat.k_vraag_pauze"] = true
	spel.hints["ch01_pak_rapport"] = 1
	spel.verplaats_speler(Hulp.KANTOOR, "deur_hal", false)
	spel.acties.ontgrendel("ch01_laptop")


func test_sf13_opslaan_en_laden_geeft_dezelfde_hash() -> void:
	_rijke_staat(s)
	var voor: String = s.staat_hash()
	assert_true(s.opslag.schrijf("handmatig"))
	var s2: Spel = Hulp.nieuw_spel(self, "state")
	assert_ne(s2.staat_hash(), voor, "een verse staat wijkt af")
	var r: Dictionary = s2.opslag.laad("handmatig")
	assert_true(r["ok"])
	assert_eq(s2.staat_hash(), voor, "SF-13")
	assert_eq(s2.klok.status("ch01_pauze_portier"), "actief", "resterende duur loopt door na laden")
	assert_eq(s2.kamer, Hulp.KANTOOR)
	assert_eq(s2.apparaten["ch01_laptop"], "ontgrendeld")
	s2.speel(16.0)
	assert_ne(s2.klok.status("ch01_pauze_portier"), "actief", "15 s resteren; na 16 s voorbij")


func test_sf14_autosave_na_kamerwissel_en_niet_tijdens_gesprek() -> void:
	Hulp.wis_map(s.opslag.map)
	s.verplaats_speler(Hulp.KANTOOR, "deur_hal")
	assert_true(FileAccess.file_exists(s.opslag.pad("auto")), "SF-14: na de kamerwissel")
	Hulp.wis_map(s.opslag.map)
	var g := Gesprek.new(s)
	assert_true(g.start("ch01_portier_praat"))
	assert_false(s.mag_opslaan())
	s.verplaats_speler(Hulp.HAL, "deur_kantoor")
	assert_false(FileAccess.file_exists(s.opslag.pad("auto")), "SF-14: niet tijdens een gesprek")
	g._einde()
	assert_true(s.mag_opslaan())
	s.verplaats_speler(Hulp.KANTOOR, "deur_hal")
	assert_true(FileAccess.file_exists(s.opslag.pad("auto")))


func test_sf15_save_met_onbekende_ids_laadt_en_waarschuwt() -> void:
	_rijke_staat(s)
	var d: Dictionary = s.opslag.maak_save()
	d["objecten"]["bestaat_niet_object"] = {"plek": "inventaris"}
	d["flags"]["bestaat_niet_flag"] = true
	d["tokens"].append({"id": "bestaat_niet_token", "verkregen_op": {"dag": 1, "tijd": "00:07"}, "bron_knoop": "", "nieuw": true})
	d["knopen"].append("ch01_bestaat_niet")
	d["apparaten"]["ch01_bestaat_niet"] = "ontgrendeld"
	d["containers_open"].append("bestaat_niet_container")
	var s2: Spel = Hulp.nieuw_spel(self, "state")
	var r: Dictionary = s2.opslag.pas_toe(JsonLezer.normaliseer(JSON.parse_string(JSON.stringify(d))))
	assert_true(r["ok"], "SF-15: laadt")
	assert_eq((r["waarschuwingen"] as PackedStringArray).size(), 6, "een waarschuwing per onbekende id")
	assert_true(s2.tokens.has("code_kluis"), "de rest laadt")
	assert_false(s2.tokens.has("bestaat_niet_token"))


func test_sf16_save_van_een_nieuwere_versie_laadt_niet() -> void:
	var d: Dictionary = s.opslag.maak_save()
	d["versie"] = 99
	var voor: String = s.staat_hash()
	var r: Dictionary = s.opslag.pas_toe(d)
	assert_false(r["ok"])
	assert_eq(r["reden"], "te_nieuw")
	assert_eq(r["melding"], "systeem.save.te_nieuw")
	assert_eq(s.staat_hash(), voor, "SF-16: niets veranderd")
	assert_signal_emitted_with_parameters(s, "mompel", ["Deze opslag komt uit een nieuwere versie van het spel.", "systeem.save.te_nieuw"])


func test_doel_bereikt_beeindigt_het_hoofdstuk() -> void:
	# volledige route van de oplosser via de echte acties
	assert_true(s.acties.pak("jas")["ok"])
	s.acties.lees("briefje")
	assert_true(s.toegang.doorgang(Hulp.HAL, "deur_kantoor")["ok"])
	assert_true(s.acties.open("kluisje")["ok"])
	assert_true(s.acties.pak("rapport")["ok"])
	assert_true(s.toegang.doorgang(Hulp.KANTOOR, "deur_hal")["ok"])
	var r: Dictionary = s.acties.geef("rapport", "portier")
	assert_eq(r["trigger"]["gevuurd"], "ch01_klaar")
	assert_true(s.voltooid)
	assert_signal_emitted(s, "hoofdstuk_voltooid")
	assert_eq(s.klok.scene, Hulp.S2)
	assert_eq(s.klok.klok_tekst(), "wo 1 jan · 07:30")


func test_gesprek_triggert_knoop_en_eenmalige_keuze() -> void:
	var g := Gesprek.new(s)
	g.start("ch01_portier_praat")
	assert_eq(g.huidige["id"], "r_opening")
	assert_eq(g.keuzes().size(), 2, "k_vraag_kantoor is verborgen zonder token")
	g.kies("k_vraag_pauze")
	assert_true(s.tokens.has("pauze_tijd"), "bereiken van r_pauze geeft het token")
	g.ga_door()
	assert_eq(g.huidige["id"], "r_einde")
	g.ga_door()
	assert_false(g.actief)
	assert_true(s.mag_opslaan(), "na het gesprek mag opslaan weer")
	g.start("ch01_portier_praat")
	assert_eq(g.huidige["id"], "r_terug", "met token start het gesprek bij r_terug")
