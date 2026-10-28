extends GutTest
## KS-01 t/m KS-05 en KS-07 t/m KS-10: klok en scènetijd. (KS-06 en KS-11 zijn validatortests in tests/python/.)

const Hulp = preload("hulp.gd")

var s: Spel


func before_each() -> void:
	s = Hulp.nieuw_spel(self, "klok")
	watch_signals(s)


func _voeg_gebeurtenis_toe(id: String, duur: float, herhaal: float = 0.0) -> void:
	var def: Dictionary = {"id": id, "start": "bij_begin", "duur_s": duur}
	if herhaal > 0.0:
		def["herhaal_na_s"] = herhaal
	s.content.gebeurtenissen[id] = {"def": def, "scene": Hulp.S1}
	s.klok.gebeurtenissen[id] = s.klok._nieuw_status()
	s.klok.start_scene(Hulp.S1)


func test_ks01_klokstring_uit_startdatum() -> void:
	assert_eq(s.klok.klok_tekst(), "wo 1 jan · 00:07", "KS-01")
	s.klok.tijd = {"dag": 7, "tijd": "06:45"}
	assert_eq(s.klok.klok_tekst(), "di 7 jan · 06:45")


func test_ks02_weekdag_wordt_berekend() -> void:
	s.content.spel["startdatum"] = "2027-01-01"
	assert_eq(s.klok.klok_tekst(), "vr 1 jan · 00:07", "KS-02")
	s.content.spel["startdatum"] = "2024-01-01"
	assert_eq(s.klok.klok_tekst(), "ma 1 jan · 00:07", "schrikkeljaar-controle: 1 jan 2024 was een maandag")


func test_ks03_klok_staat_stil_in_speeltijd() -> void:
	var voor: String = s.klok.klok_tekst()
	for i in range(120):
		s.speel(1.0)
	assert_eq(s.klok.klok_tekst(), voor, "KS-03: na 120 s speeltijd")
	assert_eq(s.speeltijd_s, 120.0)


func test_ks04_naar_latere_scene() -> void:
	var r: Dictionary = s.naar_scene(Hulp.S2, "", "", true)
	assert_eq(r["richting"], "vooruit")
	assert_eq(s.klok.klok_tekst(), "wo 1 jan · 07:30")
	assert_has(Hulp.cues(s), "ui.klok.vooruit", "KS-04")
	assert_signal_emitted_with_parameters(s, "scene_gewisseld", [Hulp.S1, Hulp.S2, "vooruit"])


func test_ks05_terug_met_niet_lineair_en_zelfde_tijd_zonder_animatie() -> void:
	s.content.scenes["ch01_sx"] = {"id": "ch01_sx", "hoofdstuk": "ch01_proef", "tijd": {"dag": 1, "tijd": "00:01"}, "kamers": [Hulp.HAL], "niet_lineair": "moment"}
	s.naar_scene(Hulp.S2, "", "", true)
	s.audio.logboek.clear()
	var r: Dictionary = s.naar_scene("ch01_sx", "", "", true)
	assert_eq(r["richting"], "terug", "KS-05")
	assert_has(Hulp.cues(s), "ui.klok.terug")
	s.audio.logboek.clear()
	s.content.scenes["ch01_sy"] = {"id": "ch01_sy", "hoofdstuk": "ch01_proef", "tijd": {"dag": 1, "tijd": "00:01"}, "kamers": [Hulp.HAL]}
	assert_eq(s.naar_scene("ch01_sy", "", "", true)["richting"], "gelijk")
	assert_eq(Hulp.cues(s).filter(func(x: String) -> bool: return x.begins_with("ui.klok")), [], "zelfde tijd: geen animatie")


func test_ks07_gebeurtenis_duur_en_herhaling() -> void:
	_voeg_gebeurtenis_toe("ch01_ev_a", 10.0)
	_voeg_gebeurtenis_toe("ch01_ev_b", 10.0, 5.0)
	assert_eq(s.klok.status("ch01_ev_a"), "actief", "KS-07: actief bij het begin van de scène")
	s.speel(9.9)
	assert_eq(s.klok.status("ch01_ev_a"), "actief")
	s.speel(0.2)
	assert_eq(s.klok.status("ch01_ev_a"), "voorbij", "voorbij na 10 s")
	assert_eq(s.klok.status("ch01_ev_b"), "wacht", "herhalend: terug naar wacht")
	s.speel(4.9)   # 15.0 s in totaal
	assert_eq(s.klok.status("ch01_ev_b"), "actief", "KS-07: na 15 s weer actief")
	assert_eq(s.klok.status("ch01_ev_a"), "voorbij")


func test_ks08_pauze_telt_niet_mee() -> void:
	_voeg_gebeurtenis_toe("ch01_ev_a", 10.0)
	s.speel(5.0)
	s.zet_pauze(true)
	s.speel(100.0)
	assert_eq(s.klok.status("ch01_ev_a"), "actief", "KS-08: gepauzeerd")
	s.zet_pauze(false)
	s.speel(4.9)
	assert_eq(s.klok.status("ch01_ev_a"), "actief", "5 s gelopen plus 4,9 s")
	s.speel(0.2)
	assert_eq(s.klok.status("ch01_ev_a"), "voorbij", "eindigt na 10 s lopende speeltijd")


func test_ks09_scenewissel_maakt_oude_gebeurtenissen_voorbij() -> void:
	s.geef_token("pauze_tijd")
	s.puzzel.herzie()
	assert_eq(s.klok.status("ch01_pauze_portier"), "actief")
	s.naar_scene(Hulp.S2, "", "", true)
	assert_eq(s.klok.status("ch01_pauze_portier"), "voorbij", "KS-09")
	s.speel(200.0)
	assert_eq(s.klok.status("ch01_pauze_portier"), "voorbij", "blijft voorbij")


func test_ks10_geen_systeemtijd_in_spellogica() -> void:
	var verboden: RegEx = RegEx.create_from_string("\\bTime\\.|OS\\.get_(unix|ticks|system|datetime)|\\bOS\\.delay")
	var toegestaan: Array = ["ontwikkel.gd"]   # alleen de bestandsnaam van het ontwikkel-logboek
	var gevonden: Array = []
	for pad in _gd_bestanden("res://"):
		if "/addons/" in pad or pad.get_file() in toegestaan:
			continue
		var regels: PackedStringArray = FileAccess.get_file_as_string(pad).split("\n")
		for i in range(regels.size()):
			if not regels[i].strip_edges().begins_with("#") and verboden.search(regels[i]) != null:
				gevonden.append("%s:%d" % [pad, i + 1])
	assert_eq(gevonden, [], "KS-10: geen Time/OS-tijd buiten de kloklaag en het ontwikkelbestand")


func _gd_bestanden(map: String) -> Array:
	var uit: Array = []
	for f in DirAccess.get_files_at(map):
		if f.ends_with(".gd"):
			uit.append(map.path_join(f))
	for d in DirAccess.get_directories_at(map):
		uit.append_array(_gd_bestanden(map.path_join(d)))
	return uit
