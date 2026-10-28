class_name Spel
extends SpelTekst
## Alle spelstaat op één plek. `GameState` (autoload) is gewoon een instantie hiervan; tests maken er zelf een
## met een eigen ContentDb. Subsystemen praten via signalen.


func _init(c: ContentDb = null) -> void:
	if c != null:
		bouw(c)


func bouw(c: ContentDb) -> void:
	content = c
	objecten = ObjectBoom.new(content)
	klok = Klok.new(content)
	audio = AudioCues.new(content)
	audio.context_leverancier = Callable(self, "_audio_context")
	add_child(audio)
	ctx = SpelContext.new(self)
	effecten = Effecten.new(self)
	puzzel = Puzzelgraaf.new(self)
	toegang = Toegang.new(self)
	opslag = Opslaan.new(self)
	acties = Acties.new(self)
	content.gewist.connect(wis_staat)
	objecten.cue_gevraagd.connect(audio.cue)
	klok.cue_gevraagd.connect(audio.cue)
	objecten.mompel_gevraagd.connect(mompel_zeg)
	klok.gebeurtenis_gewijzigd.connect(puzzel.gebeurtenis_gewijzigd)
	klok.scene_gewisseld.connect(func(van: String, naar: String, richting: String) -> void: scene_gewisseld.emit(van, naar, richting))


## Nieuwe content geladen: er loopt geen spel meer tot nieuw_spel().
func wis_staat() -> void:
	hoofdstuk = ""
	kamer = ""
	klok.reset()
	audio.reset()


func _process(dt: float) -> void:
	if auto_tik:
		speel(dt)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Verwijst naar elkaar (RefCounted-kringen); losmaken zodat er niets lekt.
		ctx = null; effecten = null; puzzel = null; toegang = null; opslag = null; acties = null


func _audio_context() -> Dictionary:
	return {"t": speeltijd_s, "kamer": kamer, "scene": klok.scene if klok != null else ""}


# ---------------------------------------------------------------- nieuw spel

func nieuw_spel(h: String = "") -> void:
	flags.clear(); tokens.clear(); token_volgorde.clear(); knopen.clear(); knopen_volgorde.clear()
	apparaten.clear(); dialoog_keuzes.clear(); hints.clear(); systemen.clear(); blokkades.clear()
	fout_log = PackedStringArray()
	voltooid = false
	speeltijd_s = 0.0
	hoofdstuk = h if h != "" else content.eerste_hoofdstuk()
	audio.reset()
	var ch: Dictionary = content.hoofdstukken[hoofdstuk]
	var aanname: Dictionary = ch.get("aanname_bij_start", {})
	for f: String in aanname.get("flags", {}):
		flags[f] = aanname["flags"][f]
	for id: String in content.apparaten:
		apparaten[id] = "ontgrendeld" if content.apparaten[id]["vergrendeling"]["type"] == "geen" else "vergrendeld"
	objecten.reset(hoofdstuk)
	klok.reset()
	klok.start_scene(ch["start"]["scene"])
	for t: String in aanname.get("tokens", []):
		geef_token(t, "aanname", false)
	_zet_speler(ch["start"]["kamer"], ch["start"].get("uitgang", ""))
	kamer_geluid()
	puzzel.herzie()
	nieuw_spel_gestart.emit()


# ---------------------------------------------------------------- tijd

## Speeltijd (K9): loopt tijdens lopen, gesprekken en inventaris; staat stil bij pauze.
func speel(dt: float) -> void:
	if gepauzeerd or dt <= 0.0 or klok == null or hoofdstuk == "":
		return
	speeltijd_s += dt
	klok.tik(dt, ctx)
	puzzel.herzie()


func zet_pauze(aan: bool) -> void:
	gepauzeerd = aan


# ---------------------------------------------------------------- flags en tokens

func flag_waarde(id: String) -> Variant:
	if flags.has(id):
		return flags[id]
	if content.flags.has(id):
		return content.flags[id]["start"]
	return null


func zet_flag(id: String, waarde: Variant = true) -> void:
	if not content.flags.has(id):
		log_fout("zet_flag: onbekende flag '%s'" % id)
		return
	flags[id] = waarde


func wis_flag(id: String) -> void:
	if content.flags.has(id):
		flags[id] = false if content.flags[id]["type"] == "bool" else 0


func heeft_token(id: String) -> bool:
	return tokens.has(id)


## SF-12: één keer, met scènetijd en bron-knoop. Meldt "Genoteerd: ..." en roept de cue aan.
func geef_token(id: String, bron_knoop: String = "", melden: bool = true) -> void:
	if tokens.has(id):
		return
	if not content.tokens.has(id):
		log_fout("geef_token: onbekend token '%s'" % id)
		return
	tokens[id] = {"id": id, "verkregen_op": klok.tijd.duplicate(), "bron_knoop": bron_knoop, "nieuw": true}
	token_volgorde.append(id)
	token_gegeven.emit(id)
	if melden:
		var notitie: String = notitie_tekst(id)
		notitie_genoteerd.emit(tekst("ui.notitie.genoteerd") + " " + notitie)
		audio.cue("ui.notitie.nieuw")


func notitie_tekst(id: String) -> String:
	var t: String = tekst(content.tokens[id]["notitie"])
	return t.replace("{token:%s}" % id, str(content.tokens[id].get("waarde", "")))


# ---------------------------------------------------------------- kamers en scènes

func positie_van_uitgang(k: String, uitgang: String) -> Vector2i:
	var kd: Dictionary = content.kamers.get(k, {})
	for u: Dictionary in kd.get("uitgangen", []):
		if u["id"] == uitgang:
			return Vector2i(u["positie"]["x"], u["positie"]["y"])
	var sp: Dictionary = kd.get("start_positie", {"x": 0, "y": 0})
	return Vector2i(sp["x"], sp["y"])


func _zet_speler(k: String, uitgang: String = "") -> void:
	kamer = k
	positie = positie_van_uitgang(k, uitgang)


## Speler naar een andere kamer; trigger `betreed` en autosave (SF-14, TG-11).
func verplaats_speler(naar: String, uitgang: String = "", autosave_nu: bool = true) -> void:
	if not content.kamers.has(naar):
		log_fout("verplaats_speler: onbekende kamer '%s'" % naar)
		return
	var van: String = kamer
	_zet_speler(naar, uitgang)
	kamer_geluid()
	kamer_gewisseld.emit(van, naar)
	puzzel.trigger({"betreed": naar})
	if autosave_nu:
		if _actie_diepte > 0:
			_autosave_wacht = true      # B1: pas opslaan als de buitenste actie klaar is
		else:
			autosave()


## Een actie (trigger, herziening) begint of eindigt. Autosave wacht tot de buitenste actie klaar is.
func begin_actie() -> void:
	_actie_diepte += 1


func einde_actie() -> void:
	_actie_diepte = maxi(0, _actie_diepte - 1)
	if _actie_diepte == 0 and _autosave_wacht:
		_autosave_wacht = false
		autosave()


## Scènewissel (K4). O9: geweigerd zolang een onmisbaar pakbaar object in een vervallende kamer ligt.
func naar_scene(scene_id: String, doel_kamer: String = "", uitgang: String = "", forceer: bool = false) -> Dictionary:
	if not content.scenes.has(scene_id):
		log_fout("naar_scene: onbekende scène '%s'" % scene_id)
		return {"ok": false, "reden": "onbekend"}
	var nieuwe: Array = content.scenes[scene_id]["kamers"]
	if not forceer:
		var blok: String = objecten.blokkerend_voor_scene(nieuwe)
		if blok != "":
			mompel_zeg("systeem.niet_zonder", {"object": tekst(content.items[blok]["naam"])})
			audio.cue("ui.weiger")
			return {"ok": false, "reden": "niet_zonder", "object": blok}
	blokkades["scenewissel"] = true
	var richting: String = klok.naar_scene(scene_id)
	blokkades.erase("scenewissel")
	if doel_kamer != "" and doel_kamer != kamer:
		verplaats_speler(doel_kamer, uitgang, false)
	elif doel_kamer != "" and uitgang != "":
		_zet_speler(kamer, uitgang)
	elif doel_kamer == "" and not nieuwe.has(kamer):
		log_fout("naar_scene '%s': huidige kamer '%s' bestaat daarin niet" % [scene_id, kamer])
	puzzel.herzie()
	return {"ok": true, "richting": richting}


func npcs_in_kamer(k: String) -> Array:
	var uit: Array = []
	for n: Dictionary in content.kamers.get(k, {}).get("npcs", []):
		if Condities.evalueer(n.get("aanwezig"), ctx):
			uit.append(n)
	return uit


## Ambience en NPC-lagen van de kamer starten, die van de vorige stoppen (A4, AC-06).
func kamer_geluid() -> void:
	audio.stop_lagen_met("ambience.")
	audio.stop_lagen_met("npc.")
	var kd: Dictionary = content.kamers.get(kamer, {})
	audio.ruimte["kamer"] = kamer
	audio.zet_ruimte(kd.get("galm", ""), false)
	var n: int = 0
	for c: String in kd.get("ambience", []):
		audio.start_laag(c, "ambience.%d" % n)
		n += 1
	for npc in npcs_in_kamer(kamer):
		if npc.has("geluid"):
			audio.start_laag(npc["geluid"], "npc.%s.%s" % [kamer, npc["id"]])


# ---------------------------------------------------------------- opslaan

func mag_opslaan() -> bool:
	return blokkades.is_empty()


func autosave() -> bool:
	if not mag_opslaan():
		return false
	if opslag.schrijf("auto"):
		audio.cue("ui.opslaan")
		autosave_geschreven.emit()
		return true
	return false


func staat_hash() -> String:
	return opslag.staat_hash()
