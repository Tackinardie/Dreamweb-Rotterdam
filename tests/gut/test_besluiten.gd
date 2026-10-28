extends GutTest
## Besluiten uit ronde 1: OI-14, SF-19 t/m SF-27, autosave na de hele trigger (B1), scope (B3), laden (M1 t/m M4).

const Hulp = preload("hulp.gd")


func _jas_en_kast(s: Spel) -> void:
	s.objecten.open["kast"] = true


# ---- SF-21 / B1

func test_sf21_autosave_pas_na_de_hele_trigger() -> void:
	var s: Spel = Hulp.nieuw_spel(self, "sf21")
	Hulp.wis_map(s.opslag.map)
	var halve: Dictionary = {"id": "ch01_halve_staat", "type": "actie", "pad": "zij", "waarom": "Eerst weg, dan een flag.",
			"trigger": {"gebruik": "kopje_wit"}, "effecten": [{"naar_kamer": Hulp.KANTOOR}, {"zet_flag": "ch01_dak_bekend"}]}
	Hulp.voeg_knoop_toe(s, halve)
	watch_signals(s)
	var r: Dictionary = s.acties.gebruik("kopje_wit")
	assert_eq(r["trigger"]["gevuurd"], "ch01_halve_staat")
	assert_eq(s.kamer, Hulp.KANTOOR)
	assert_signal_emit_count(s, "autosave_geschreven", 1)   # SF-21: een save, aan het eind
	var s2: Spel = Hulp.nieuw_spel(self, "sf21")
	Hulp.voeg_knoop_toe(s2, halve)
	assert_true(s2.opslag.laad("auto")["ok"])
	assert_true(Condities.evalueer({"flag": "ch01_dak_bekend"}, s2.ctx), "de save bevat de flag")
	assert_true(s2.knopen.has("ch01_halve_staat"), "en de knoop als opgelost")
	s2.verplaats_speler(Hulp.HAL, "deur_kantoor", false)
	assert_eq(s2.puzzel.trigger({"gebruik": "kopje_wit"})["gevuurd"], "", "niet nog eens")


# ---- SF-19 / OI-14: een geweigerde scenewissel laat de knoop niet vuren

func _blokkade_klaar(naam: String) -> Spel:
	var s: Spel = Hulp.nieuw_spel(self, naam, "scenewissel_geweigerd")
	s.objecten.open["kast"] = true
	watch_signals(s)
	assert_eq(s.objecten.plek["rapport"], "kluisje")
	return s


func _niet_gevuurd(s: Spel, soort: String) -> void:
	assert_false(s.knopen.has("ch01_wissel_" + soort), "knoop niet opgelost")
	assert_false(Condities.evalueer({"flag": "ch01_wissel_" + soort}, s.ctx), "geen effect: flag niet gezet")
	assert_eq(s.klok.scene, Hulp.S1, "scene ongewijzigd")


func test_oi14_betreed_geweigerd_en_na_ophalen_wel() -> void:
	var s: Spel = _blokkade_klaar("oi14a")
	s.geef_token("kantoorkennis")
	assert_true(s.toegang.kies_bestemming(Hulp.HAL, "lift_hal", 1)["ok"], "naar het dak")
	assert_eq(s.kamer, Hulp.DAK)
	_niet_gevuurd(s, "betreed")
	assert_signal_emitted_with_parameters(s, "mompel", ["Mijn rapport ligt er nog.", "systeem.niet_zonder"])
	assert_has(Hulp.cues(s), "ui.weiger")
	s.objecten.zet_plek("rapport", "inventaris")
	s.toegang.kies_bestemming(Hulp.DAK, "lift_dak", 0)     # naar de hal
	s.toegang.kies_bestemming(Hulp.HAL, "lift_hal", 1)     # opnieuw het dak op: nu vuurt de knoop
	assert_true(s.knopen.has("ch01_wissel_betreed"), "SF-19: na het ophalen vuurt dezelfde trigger wel")
	assert_eq(s.klok.scene, "ch01_s3_klein")


func test_oi14_dialoog_geweigerd_mompel_na_het_gesprek() -> void:
	var s: Spel = _blokkade_klaar("oi14b")
	s.acties.pak("jas")
	var g := Gesprek.new(s)
	assert_true(g.start_met(s.npcs_in_kamer(Hulp.HAL)[0]))
	assert_eq(g.huidige["id"], "r_hoi")
	_niet_gevuurd(s, "dialoog")
	assert_signal_not_emitted(s, "mompel", "tijdens het gesprek zwijgt Richard")
	g.ga_door()
	assert_false(g.actief)
	assert_signal_emitted_with_parameters(s, "mompel", ["Mijn rapport ligt er nog.", "systeem.niet_zonder"])
	s.objecten.zet_plek("rapport", "inventaris")
	g.start("ch01_portier_bezorger")
	assert_true(s.knopen.has("ch01_wissel_dialoog"), "na het ophalen vuurt de trigger wel")
	assert_eq(s.klok.scene, "ch01_s3_klein")


func test_oi14_gebruik_geweigerd_en_na_ophalen_wel() -> void:
	var s: Spel = _blokkade_klaar("oi14c")
	var r: Dictionary = s.acties.gebruik("kopje_wit")
	assert_eq(r["trigger"]["geweigerd_door"], "rapport")
	_niet_gevuurd(s, "gebruik")
	assert_signal_emitted_with_parameters(s, "mompel", ["Mijn rapport ligt er nog.", "systeem.niet_zonder"])
	s.objecten.zet_plek("rapport", "inventaris")
	assert_eq(s.acties.gebruik("kopje_wit")["trigger"]["gevuurd"], "ch01_wissel_gebruik")
	assert_eq(s.klok.scene, "ch01_s3_klein")


# ---- SF-20 / B3: alleen het eigen hoofdstuk en de hub

func test_sf20_scope_hub_wel_ander_hoofdstuk_niet() -> void:
	var s: Spel = Hulp.nieuw_spel(self, "sf20", "scope_hoofdstukken")
	assert_true(Condities.evalueer({"flag": "hub_vlag"}, s.ctx), "de automatische hubknoop vuurt")
	assert_false(Condities.evalueer({"flag": "ch02_vlag"}, s.ctx), "die van ch02 niet")
	assert_true(s.knopen.has("ch00_auto") and not s.knopen.has("ch02_auto"))
	var ids: Array = s.content.actieve_knopen("ch01_proef").map(func(k: Dictionary) -> String: return k["id"])
	assert_lt(ids.find("ch01_klaar"), ids.find("ch00_auto"), "eerst het huidige hoofdstuk, dan de hub")
	assert_false(ids.has("ch02_blauw"))


# ---- SF-22: afgeleide onmisbare objecten

func test_sf22_onmisbaar_komt_overeen_met_de_verwachte_lijst() -> void:
	var verwacht: Dictionary = JsonLezer.lees(Hulp.repo().path_join("tests/fixtures/onmisbaar.json"))
	for naam: String in ["proef", "scope_hoofdstukken"]:
		var s: Spel = Hulp.nieuw_spel(self, "sf22", "" if naam == "proef" else naam)
		var lijst: Array = []
		for id: String in s.content.items:
			if s.content.is_onmisbaar(id, "ch01_proef"):
				lijst.append(id)
		lijst.sort()
		assert_eq(lijst, verwacht[naam], "SF-22: " + naam)
	var s2: Spel = Hulp.nieuw_spel(self, "sf22", "scope_hoofdstukken")
	assert_false(s2.content.is_onmisbaar("kopje_blauw", "ch01_proef"), "komt alleen in ch02 voor")
	assert_true(s2.content.is_onmisbaar("kopje_blauw", "ch02_extra"))


# ---- laden: SF-24 t/m SF-27, M3, M4

func _bewaard_spel(naam: String) -> Spel:
	var s: Spel = Hulp.nieuw_spel(self, naam)
	s.objecten.open["kast"] = true
	s.acties.pak("jas")
	s.acties.lees("briefje")
	return s


func test_sf24_spel_geladen_een_keer_en_geen_tweede_voltooid() -> void:
	var s: Spel = _bewaard_spel("sf24")
	assert_true(s.toegang.doorgang(Hulp.HAL, "deur_kantoor")["ok"])
	assert_true(s.acties.open("kluisje")["ok"])
	s.acties.pak("rapport")
	s.toegang.doorgang(Hulp.KANTOOR, "deur_hal")
	s.acties.geef("rapport", "portier")
	assert_true(s.voltooid)
	assert_true(s.opslag.schrijf("handmatig"))
	var s2: Spel = Hulp.nieuw_spel(self, "sf24")
	s2.blokkades["gesprek"] = true
	s2.gepauzeerd = true
	watch_signals(s2)
	assert_true(s2.opslag.laad("handmatig")["ok"])
	assert_signal_emit_count(s2, "spel_geladen", 1)
	assert_signal_not_emitted(s2, "hoofdstuk_voltooid")
	s2.puzzel.herzie()
	assert_signal_not_emitted(s2, "hoofdstuk_voltooid")
	assert_true(s2.voltooid)
	assert_true(s2.blokkades.is_empty() and not s2.gepauzeerd, "tijdelijke toestand gereset")
	assert_eq(s2.klok.klok_tekst(), "wo 1 jan · 07:30", "de klok toont de scenetijd uit de save")


func test_sf25_voorbije_gebeurtenis_blijft_voorbij_na_laden() -> void:
	var s: Spel = Hulp.nieuw_spel(self, "sf25")
	s.geef_token("pauze_tijd")
	s.puzzel.herzie()
	s.naar_scene(Hulp.S2, "", "", true)
	assert_eq(s.klok.status("ch01_pauze_portier"), "voorbij")
	s.opslag.schrijf("handmatig")
	var s2: Spel = Hulp.nieuw_spel(self, "sf25")
	s2.opslag.laad("handmatig")
	assert_eq(s2.klok.status("ch01_pauze_portier"), "voorbij", "SF-25")
	# na een niet-lineaire sprong terug naar de eerste scene blijft de status van de tweede bewaard
	s.klok.naar_scene(Hulp.S1)
	s.opslag.schrijf("handmatig")
	s2.opslag.laad("handmatig")
	assert_eq(s2.klok.scene, Hulp.S1)
	assert_eq(s2.klok.gebeurtenissen["ch01_pauze_portier"]["status"], s.klok.gebeurtenissen["ch01_pauze_portier"]["status"])


func test_sf26_onbekende_kamer_of_scene_valt_terug_op_de_start() -> void:
	var s: Spel = _bewaard_spel("sf26")
	s.objecten.zet_plek("kopje_wit", Hulp.DAK, Vector2i(2, 2))
	var d: Dictionary = s.opslag.maak_save()
	d["kamer"] = "ch01_bestaat_niet"
	d["scene"] = "ch01_scene_bestaat_niet"
	d["objecten"]["koffiekop"] = {"plek": "ch01_kamer_bestaat_niet"}
	var s2: Spel = Hulp.nieuw_spel(self, "sf26")
	var r: Dictionary = s2.opslag.pas_toe(JsonLezer.normaliseer(JSON.parse_string(JSON.stringify(d))))
	assert_true(r["ok"])
	assert_eq(s2.kamer, Hulp.HAL, "SF-26: chapter.start")
	assert_eq(s2.klok.scene, Hulp.S1)
	assert_eq(s2.positie, Vector2i(5, 6))
	assert_true(s2.tokens.has("code_kluis") and s2.knopen.has("ch01_lees_briefje"), "de rest laadt")
	assert_eq(s2.objecten.plek["koffiekop"], Hulp.HAL, "object in onbekende kamer: beginplek")
	assert_true((r["waarschuwingen"] as PackedStringArray).size() >= 2)


func test_sf27_ontbrekende_sleutels_en_verkeerde_types_crashen_niet() -> void:
	var s: Spel = _bewaard_spel("sf27")
	var d: Dictionary = s.opslag.maak_save()
	d["flags"] = []
	d["tokens"] = "geen lijst"
	d["knopen"] = 5
	d["objecten"] = {"kopje_wit": 5, "koffiekop": {"plek": 7}}
	d["apparaten"] = {"ch01_laptop": "kapot"}
	d["positie"] = 3
	d["hints"] = []
	d["gebeurtenissen"] = {"ch01_pauze_portier": "kapot"}
	d["containers_open"] = {}
	d.erase("kamer")
	var s2: Spel = Hulp.nieuw_spel(self, "sf27")
	var r: Dictionary = s2.opslag.pas_toe(JsonLezer.normaliseer(JSON.parse_string(JSON.stringify(d))))
	assert_true(r["ok"], "SF-27: geen crash")
	assert_true(s2.tokens.is_empty() and s2.knopen.is_empty(), "terug op de startwaarde")
	assert_eq(s2.apparaten["ch01_laptop"], "vergrendeld")
	assert_eq(s2.kamer, Hulp.HAL)
	assert_eq(s2.klok.status("ch01_pauze_portier"), "wacht")
	assert_false(s2.opslag.pas_toe({"hoofdstuk": "ch01_proef"})["ok"], "zonder versie: geweigerd, geen crash")
	assert_false(s2.opslag.pas_toe({"versie": 1, "hoofdstuk": 5})["ok"])


func test_m4_scenewissel_via_uitgang_geeft_geen_foutregel_en_slaat_op() -> void:
	var s: Spel = Hulp.nieuw_spel(self, "m4")
	s.objecten.open["kast"] = true
	s.acties.pak("jas")
	(s.content.kamers[Hulp.HAL]["uitgangen"][0] as Dictionary)["naar_scene"] = Hulp.S2
	Hulp.wis_map(s.opslag.map)
	assert_true(s.toegang.doorgang(Hulp.HAL, "deur_kantoor")["ok"])
	assert_eq(s.fout_log.size(), 0, "geen onterechte foutregel")
	assert_eq([s.klok.scene, s.kamer], [Hulp.S2, Hulp.KANTOOR])
	assert_true(FileAccess.file_exists(s.opslag.pad("auto")), "en een autosave na afloop")


func test_opslaan_is_atomair_geen_tijdelijk_bestand_blijft_staan() -> void:
	var s: Spel = Hulp.nieuw_spel(self, "atomair")
	assert_true(s.opslag.schrijf("handmatig"))
	assert_true(FileAccess.file_exists(s.opslag.pad("handmatig")))
	assert_false(FileAccess.file_exists(s.opslag.pad("handmatig") + ".tmp"))
	assert_true(JsonLezer.lees(s.opslag.pad("handmatig")) is Dictionary)


# ---- ronde 2 (N1, N2, N3)

func test_n1_mompel_uit_vorige_sessie_verschijnt_niet_na_laden() -> void:
	var s: Spel = Hulp.nieuw_spel(self, "n1")
	s.opslag.schrijf("handmatig")
	s.blokkades["gesprek"] = true
	s.mompel_zeg("systeem.inventaris.vol")      # blijft in de wachtrij
	s.blokkades.erase("gesprek")
	watch_signals(s)
	assert_true(s.opslag.laad("handmatig")["ok"])
	s.spreek_uit_wachtrij()
	assert_signal_not_emitted(s, "mompel")
	s.blokkades["gesprek"] = true
	s.mompel_zeg("systeem.inventaris.vol")
	s.nieuw_spel()
	s.spreek_uit_wachtrij()
	assert_signal_not_emitted(s, "mompel", "ook nieuw_spel leegt de wachtrij")


func test_n2_uitgestelde_autosave_wacht_tot_het_gesprek_voorbij_is() -> void:
	var s: Spel = Hulp.nieuw_spel(self, "n2")
	Hulp.voeg_knoop_toe(s, {"id": "ch01_praat_weg", "type": "actie", "pad": "zij", "waarom": "Een gesprek dat je wegstuurt.",
			"trigger": {"dialoog": "ch01_portier_praat", "regel": "r_opening"}, "effecten": [{"naar_kamer": Hulp.KANTOOR}, {"zet_flag": "ch01_dak_bekend"}]})
	Hulp.wis_map(s.opslag.map)
	watch_signals(s)
	var g := Gesprek.new(s)
	assert_true(g.start("ch01_portier_praat"))
	assert_eq(s.kamer, Hulp.KANTOOR, "de knoop stuurde Richard weg")
	assert_signal_emit_count(s, "autosave_geschreven", 0)
	assert_false(FileAccess.file_exists(s.opslag.pad("auto")), "tijdens het gesprek mag niet opgeslagen worden")
	g.kies("k_dag")
	assert_false(g.actief)
	assert_signal_emit_count(s, "autosave_geschreven", 1)
	assert_true(FileAccess.file_exists(s.opslag.pad("auto")), "N2: de uitgestelde autosave is alsnog geschreven")
	var d: Dictionary = JsonLezer.lees(s.opslag.pad("auto"))
	assert_eq(d["kamer"], Hulp.KANTOOR)
	assert_eq(d["flags"].get("ch01_dak_bekend"), true)


func test_n3_slot_titel_crasht_niet_op_kapotte_saves() -> void:
	var s: Spel = Hulp.nieuw_spel(self, "n3")
	s.opslag.schrijf("handmatig")
	assert_eq(s.opslag.slot_titel("handmatig"), "Hal · wo 1 jan · 00:07")
	var kapot: Array = [{}, {"kamer": 5, "scene": []}, {"kamer": "ch01_hal"}, {"scene": "ch01_s1_nacht"},
			{"kamer": "bestaat_niet", "scene": "ch01_s1_nacht"}, {"kamer": "ch01_hal", "scene": "bestaat_niet"}, {"kamer": null, "scene": null}]
	for d: Dictionary in kapot:
		var f := FileAccess.open(s.opslag.pad("handmatig"), FileAccess.WRITE)
		f.store_string(JSON.stringify(d))
		f.close()
		assert_eq(s.opslag.slot_titel("handmatig"), "", "geen crash voor " + str(d))
	var f2 := FileAccess.open(s.opslag.pad("handmatig"), FileAccess.WRITE)
	f2.store_string("[1, 2]")
	f2.close()
	assert_eq(s.opslag.slot_titel("handmatig"), "")
	assert_eq(s.opslag.slot_titel("auto") if not FileAccess.file_exists(s.opslag.pad("auto")) else "", "")
