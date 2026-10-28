extends GutTest
## AC-03 t/m AC-10: audio-cues en het geluidsvenster. (AC-01 en AC-02 zijn validatortests in tests/python/.)

const Hulp = preload("hulp.gd")

var s: Spel


func before_each() -> void:
	s = Hulp.nieuw_spel(self, "audio")
	s.audio.logboek.clear()


func _gd_bestanden(map: String) -> Array:
	var uit: Array = []
	for f in DirAccess.get_files_at(map):
		if f.ends_with(".gd"):
			uit.append(map.path_join(f))
	for d in DirAccess.get_directories_at(map):
		if d != "addons":
			uit.append_array(_gd_bestanden(map.path_join(d)))
	return uit


func test_ac03_alle_cue_aanroepen_in_game_staan_in_de_echte_catalogus() -> void:
	var echt := ContentDb.new()
	add_child_autofree(echt)
	echt.laad(Hulp.repo().path_join("tests/fixtures/proef"), Hulp.repo().path_join("audio/cues.json"))
	assert_gt(echt.cues.size(), 0, "audio/cues.json is gevuld")
	var aanroep: RegEx = RegEx.create_from_string("\\b(cue|start_laag|cue_gevraagd\\.emit)\\(\\s*\"([^\"]+)\"")
	var standaard: RegEx = RegEx.create_from_string("\\b_cue\\([^)]*,\\s*\"([a-z0-9_.]+)\"\\s*\\)")
	var onbekend: Array = []
	var aantal: int = 0
	for pad in _gd_bestanden("res://"):
		for regel in FileAccess.get_file_as_string(pad).split("\n"):
			if regel.strip_edges().begins_with("#"):
				continue
			var gevonden: Array = []
			for m in aanroep.search_all(regel):
				gevonden.append(m.get_string(2))
			for m in standaard.search_all(regel):
				gevonden.append(m.get_string(1))
			for id: String in gevonden:
				aantal += 1
				if not echt.cues.has(id):
					onbekend.append("%s: %s" % [pad, id])
	assert_gt(aantal, 10, "er zijn cue-aanroepen gevonden")
	assert_eq(onbekend, [], "AC-03: elke letterlijke cue-id bestaat in audio/cues.json")


func test_ac04_onbekende_cue_geen_crash_wel_log() -> void:
	s.audio.cue("bestaat.niet")
	assert_eq(s.audio.fout_log.size(), 1)
	assert_eq(s.audio.logboek.back()["status"], "onbekend", "AC-04")
	assert_eq(s.audio.logboek.back()["cue"], "bestaat.niet")


func test_ac04b_verkeerde_soort_is_een_fout() -> void:
	s.audio.cue("ambience.proef.hal")
	s.audio.start_laag("object.pak", "k")
	assert_eq(s.audio.fout_log.size(), 2, "cue() met doorlopend en start_laag() met eenmalig")
	assert_eq(AudioCues.kleur_voor(s.audio.recent[0]["status"]), AudioCues.kleur_voor("onbekend"), "rood")


func test_ac05_laag_vervangen_en_stoppen() -> void:
	s.audio.start_laag("ambience.proef.hal", "k")
	s.audio.start_laag("muziek.proef.verkennen", "k")
	assert_eq(s.audio.lagen["k"]["cue"], "muziek.proef.verkennen", "AC-05: alleen b")
	var voor: int = s.audio.logboek.size()
	s.audio.start_laag("muziek.proef.verkennen", "k")
	assert_eq(s.audio.logboek.size(), voor, "zelfde laag nogmaals: geen dubbele regel")
	s.audio.stop_laag("k")
	assert_false(s.audio.lagen.has("k"))
	s.audio.stop_laag("bestaat_niet")   # geen fout
	assert_eq(s.audio.fout_log.size(), 0)


func test_ac06_ambience_volgt_de_kamer() -> void:
	var ambience: Callable = func() -> Array:
		return s.audio.lagen.keys().filter(func(k: String) -> bool: return k.begins_with("ambience."))
	assert_eq(ambience.call(), ["ambience.0"])
	assert_eq(s.audio.lagen["ambience.0"]["cue"], "ambience.proef.hal")
	assert_true(s.audio.lagen.has("npc.ch01_hal.portier"), "NPC-geluid zolang hij aanwezig is")
	s.verplaats_speler(Hulp.KANTOOR, "", false)
	assert_eq(ambience.call(), [], "AC-06: na vertrek niet meer")
	assert_false(s.audio.lagen.has("npc.ch01_hal.portier"))
	assert_eq(s.audio.ruimte["galm"], "klein")
	assert_false(s.audio.ruimte["raamfilter"])
	s.verplaats_speler(Hulp.HAL, "", false)
	assert_eq(ambience.call(), ["ambience.0"])


func test_ac07_logboekregel_per_aanroep_met_alle_velden() -> void:
	var pad: String = "user://test_saves/audio/cues.jsonl"
	DirAccess.make_dir_recursive_absolute(pad.get_base_dir())
	DirAccess.remove_absolute(pad)
	s.audio.logboek_pad = pad
	s.speel(3.5)
	s.audio.cue("object.pak", {"nat": 0.7})
	s.audio.start_laag("muziek.proef.verkennen", "muziek")
	s.audio.stop_laag("muziek")
	assert_eq(s.audio.logboek.size(), 3)
	var r: Dictionary = s.audio.logboek[0]
	for sleutel in ["t", "soort", "cue", "sleutel", "context", "kamer", "scene", "status"]:
		assert_true(r.has(sleutel), "AC-07: veld " + sleutel)
	assert_eq([r["t"], r["soort"], r["cue"], r["kamer"], r["scene"]], [3.5, "cue", "object.pak", Hulp.HAL, Hulp.S1])
	assert_eq(s.audio.logboek.map(func(x: Dictionary) -> String: return x["soort"]), ["cue", "start", "stop"])
	s.audio.sluit_logboek()
	var regels: PackedStringArray = FileAccess.get_file_as_string(pad).strip_edges().split("\n")
	assert_eq(regels.size(), 3, "één regel per aanroep in het bestand")
	assert_eq(JSON.parse_string(regels[0])["cue"], "object.pak")


func test_ac08_venster_alleen_in_ontwikkelbuild_en_f2_schakelt() -> void:
	assert_null(Geluidsvenster.maak(s.audio, false), "release: het venster bestaat niet")
	var v: Geluidsvenster = Geluidsvenster.maak(s.audio, true)
	add_child_autofree(v)
	assert_false(v.visible)
	var f2 := InputEventKey.new()
	f2.keycode = KEY_F2
	f2.pressed = true
	v._unhandled_input(f2)
	assert_true(v.visible, "AC-08: F2 toont")
	v._unhandled_input(f2)
	assert_false(v.visible, "F2 verbergt")
	# release-gedrag van de audiolaag: geen logboek
	s.audio.ontwikkel = false
	s.audio.logboek.clear()
	s.audio.cue("object.pak")
	assert_eq(s.audio.logboek.size(), 0, "geen logboek buiten ontwikkelbuilds")


func test_ac09_venster_kleurt_op_status() -> void:
	var v: Geluidsvenster = Geluidsvenster.maak(s.audio, true)
	add_child_autofree(v)
	s.audio.cue("object.pak")      # verwacht
	s.audio.cue("deur.open")       # placeholder
	s.audio.cue("bestaat.niet")    # onbekend
	var tekst: String = v.bouw_tekst()
	assert_true(tekst.contains(AudioCues.kleur_voor("verwacht").to_html(false)), "grijs")
	assert_true(tekst.contains(AudioCues.kleur_voor("placeholder").to_html(false)), "geel")
	assert_true(tekst.contains(AudioCues.kleur_voor("onbekend").to_html(false)), "rood")
	assert_true(tekst.contains("object.pak") and tekst.contains("ambience.proef.hal"))
	assert_ne(AudioCues.kleur_voor("verwacht"), AudioCues.kleur_voor("klaar"))
	assert_eq(AudioCues.context_tekst({"nat": 0.7}), "(nat 0,7)", "Nederlandse notatie")


func test_ac10_standaardcues_bij_hun_acties() -> void:
	s.objecten.open["kast"] = true
	s.acties.pak("jas")
	s.objecten.leg_neer("jas", Hulp.HAL, s.positie)
	s.acties.pak("kopje_wit")
	s.objecten.stop_in("kopje_wit", "bezorgtas", Hulp.HAL)
	s.objecten.pak("pakket", Hulp.HAL)
	s.objecten.pak("doos", Hulp.HAL)
	s.objecten.stop_in("jas", "jas", Hulp.HAL)      # kan niet -> ui.weiger
	s.acties.open("bezorgtas")
	s.acties.lees("briefje")                        # object.lees
	s.toegang.doorgang(Hulp.HAL, "deur_kantoor")    # deur.geweigerd
	s.toegang.kies_bestemming(Hulp.HAL, "lift_hal", 1)   # lift.geweigerd
	s.geef_token("code_kluis")                      # ui.notitie.nieuw
	s.naar_scene(Hulp.S2, "", "", true)             # ui.klok.vooruit
	s.klok.naar_scene(Hulp.S1)                      # terug
	s.acties.pak("jas")
	s.verplaats_speler(Hulp.HAL, "", true)          # ui.opslaan
	s.naar_scene(Hulp.S1, "", "", true)
	s.toegang.doorgang(Hulp.HAL, "deur_kantoor")    # deur.open
	s.geef_token("kantoorkennis")
	s.toegang.kies_bestemming(Hulp.KANTOOR, "lift_kantoor", 1)   # lift.rit
	var c: Array = Hulp.cues(s)
	for id in ["object.pak", "object.leg", "object.in_container", "object.lees", "container.open", "deur.open", "deur.geweigerd",
			"lift.rit", "lift.geweigerd", "ui.weiger", "ui.notitie.nieuw", "ui.klok.vooruit", "ui.klok.terug", "ui.opslaan"]:
		assert_has(c, id, "AC-10: " + id)
