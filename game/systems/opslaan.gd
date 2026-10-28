class_name Opslaan
extends RefCounted
## Opslaan en laden (docs/systemen/state-en-flags.md, "Opslaan"): één automatisch slot en één handmatig slot.

const VERSIE: int = 1

var s: Spel
## Waar de saves komen; tests wijzen dit naar een eigen map.
var map: String = "user://saves"


func _init(spel: Spel) -> void:
	s = spel


func pad(slot: String) -> String:
	return map.path_join("%s.json" % ("auto" if slot == "auto" else "handmatig"))


## De hele toestand als JSON-geschikt woordenboek.
func maak_save() -> Dictionary:
	var vlaggen: Dictionary = {}
	for id: String in s.flags:
		var start: Variant = s.content.flags[id]["start"] if s.content.flags.has(id) else null
		if s.flags[id] != start:
			vlaggen[id] = s.flags[id]
	var ob: Dictionary = s.objecten.naar_dict()
	var tokens: Array = []
	for id: String in s.token_volgorde:
		tokens.append((s.tokens[id] as Dictionary).duplicate(true))
	return {
		"versie": VERSIE,
		"content_hash": s.content.content_hash,
		"hoofdstuk": s.hoofdstuk, "scene": s.klok.scene, "kamer": s.kamer,
		"positie": {"x": s.positie.x, "y": s.positie.y},
		"objecten": ob["objecten"], "volgorde": ob["volgorde"], "containers_open": ob["open"],
		"flags": vlaggen,
		"tokens": tokens,
		"knopen": s.knopen_volgorde.duplicate(),
		"gebeurtenissen": s.klok.naar_dict()["gebeurtenissen"],
		"apparaten": s.apparaten.duplicate(),
		"dialoog": s.dialoog_keuzes.keys(),
		"hints": s.hints.duplicate(),
		"speeltijd_s": s.speeltijd_s,
		"systemen": s.systemen.duplicate(true),
	}


## Hash over de toestand die er voor het spel toe doet (SF-07, SF-13). Niet over speeltijd.
func staat_hash() -> String:
	var d: Dictionary = maak_save()
	d.erase("speeltijd_s")
	d.erase("content_hash")
	d.erase("systemen")
	# volgorde van knopen en containers doet er niet toe
	d["knopen"] = (d["knopen"] as Array).duplicate()
	(d["knopen"] as Array).sort()
	(d["containers_open"] as Array).sort()
	d["dialoog"] = (d["dialoog"] as Array).duplicate()
	(d["dialoog"] as Array).sort()
	return JSON.stringify(d, "", true).md5_text()


## Atomair: eerst naar een tijdelijk bestand, dan hernoemen.
func schrijf(slot: String) -> bool:
	DirAccess.make_dir_recursive_absolute(map)
	var doel: String = pad(slot)
	var f: FileAccess = FileAccess.open(doel + ".tmp", FileAccess.WRITE)
	if f == null:
		s.log_fout("opslaan mislukt: %s" % doel)
		return false
	f.store_string(JSON.stringify(maak_save(), "\t", true))
	var fout: int = f.get_error()
	f.close()
	if fout != OK or DirAccess.rename_absolute(doel + ".tmp", doel) != OK:
		DirAccess.remove_absolute(doel + ".tmp")
		s.log_fout("opslaan mislukt: %s" % doel)
		return false
	return true


## Laden. Resultaat: {"ok", "reden", "waarschuwingen": PackedStringArray, "melding": tekstsleutel}
func laad(slot: String) -> Dictionary:
	var d: Variant = JsonLezer.lees(pad(slot))
	if not (d is Dictionary):
		return {"ok": false, "reden": "geen_save", "waarschuwingen": PackedStringArray()}
	return pas_toe(d)


static func _dict(d: Dictionary, sleutel: String) -> Dictionary:
	var v: Variant = d.get(sleutel, {})
	return v if v is Dictionary else {}


static func _lijst(d: Dictionary, sleutel: String) -> Array:
	var v: Variant = d.get(sleutel, [])
	return v if v is Array else []


static func _is_getal(v: Variant) -> bool:
	return v is int or v is float


## Past een save toe (state-en-flags.md, "Na laden"). Slecht gevormde saves crashen niet: wat niet klopt wordt
## overgeslagen (met een waarschuwing) of valt terug op de start van het hoofdstuk.
func pas_toe(d: Dictionary) -> Dictionary:
	var w := PackedStringArray()
	if not _is_getal(d.get("versie")):
		return {"ok": false, "reden": "ongeldig", "waarschuwingen": w}
	if int(d["versie"]) > VERSIE:
		s.mompel_zeg("systeem.save.te_nieuw")
		return {"ok": false, "reden": "te_nieuw", "melding": "systeem.save.te_nieuw", "waarschuwingen": w}
	if d.get("content_hash", "") != s.content.content_hash and Ontwikkel.actief():
		w.append("save: de content is veranderd sinds het opslaan")
	var h: Variant = d.get("hoofdstuk", "")
	if not (h is String) or not s.content.hoofdstukken.has(h):
		return {"ok": false, "reden": "onbekend_hoofdstuk", "waarschuwingen": w}
	var start: Dictionary = s.content.hoofdstukken[h]["start"]
	s.hoofdstuk = h
	s.objecten.reset(h)
	w.append_array(s.objecten.uit_dict({"objecten": _dict(d, "objecten"), "volgorde": _dict(d, "volgorde"),
			"open": _lijst(d, "containers_open")}))
	s.flags.clear()
	var vlaggen: Dictionary = _dict(d, "flags")
	for id: String in vlaggen:
		if s.content.flags.has(id) and (vlaggen[id] is bool or vlaggen[id] is int):
			s.flags[id] = vlaggen[id]
		else:
			w.append("save: flag '%s' overgeslagen (onbekend of verkeerd type)" % id)
	s.tokens.clear()
	s.token_volgorde.clear()
	for t: Variant in _lijst(d, "tokens"):
		var id: String = str(t.get("id", "")) if t is Dictionary else ""
		if id != "" and s.content.tokens.has(id):
			var op: Variant = t.get("verkregen_op")
			s.tokens[id] = {"id": id, "verkregen_op": op if op is Dictionary else s.klok.tijd.duplicate(),
					"bron_knoop": str(t.get("bron_knoop", "")), "nieuw": t.get("nieuw", false) == true}
			s.token_volgorde.append(id)
		else:
			w.append("save: token '%s' overgeslagen" % id)
	s.knopen.clear()
	s.knopen_volgorde.clear()
	for k: Variant in _lijst(d, "knopen"):
		if k is String and s.content.knopen.has(k):
			s.knopen[k] = true
			s.knopen_volgorde.append(k)
		else:
			w.append("save: knoop '%s' overgeslagen" % str(k))
	s.apparaten.clear()
	for id: String in s.content.apparaten:
		s.apparaten[id] = "ontgrendeld" if s.content.apparaten[id]["vergrendeling"]["type"] == "geen" else "vergrendeld"
	var app: Dictionary = _dict(d, "apparaten")
	for id: String in app:
		if s.content.apparaten.has(id) and ["vergrendeld", "ontgrendeld"].has(app[id]):
			s.apparaten[id] = app[id]
		else:
			w.append("save: apparaat '%s' overgeslagen" % id)
	s.dialoog_keuzes.clear()
	for k: Variant in _lijst(d, "dialoog"):
		s.dialoog_keuzes[str(k)] = true
	s.hints = _dict(d, "hints").duplicate()
	s.systemen = _dict(d, "systemen").duplicate(true)
	s.speeltijd_s = float(d["speeltijd_s"]) if _is_getal(d.get("speeltijd_s")) else 0.0
	var scene: Variant = d.get("scene", "")
	var kamer: Variant = d.get("kamer", "")
	var plek_ok: bool = scene is String and s.content.scenes.has(scene) and kamer is String and s.content.kamers.has(kamer) \
			and (s.content.scenes[scene]["kamers"] as Array).has(kamer)
	if not plek_ok:
		w.append("save: onbekende scène '%s' of kamer '%s'; start van het hoofdstuk gebruikt" % [str(scene), str(kamer)])
		scene = start["scene"]
		kamer = start["kamer"]
		# objecten die in een onbekende kamer lagen, gaan naar hun beginplek (uit_dict slaat onbekende plekken al over)
	s.klok.uit_dict({"scene": scene, "gebeurtenissen": _dict(d, "gebeurtenissen")})
	s.kamer = kamer
	var p: Dictionary = _dict(d, "positie")
	if plek_ok and _is_getal(p.get("x")) and _is_getal(p.get("y")):
		s.positie = Vector2i(int(p["x"]), int(p["y"]))
	else:
		s.positie = s.positie_van_uitgang(kamer, start.get("uitgang", "") if not plek_ok else "")
	s.blokkades.clear()
	s.gepauzeerd = false
	s.puzzel.wis()
	s.wis_tijdelijk()
	var doel: Variant = s.content.hoofdstukken[h].get("doel")
	s.voltooid = doel != null and Condities.evalueer(doel, s.ctx)
	s.kamer_geluid()
	for x in w:
		s.log_fout(x)
	s.spel_geladen.emit()
	return {"ok": true, "reden": "", "waarschuwingen": w}


## "Studentenkamer · wo 1 jan · 00:07" voor het laadscherm (geen echte datum). Crasht niet op een kapotte save:
## ontbrekende of verkeerd getypeerde velden geven een lege titel.
func slot_titel(slot: String) -> String:
	var d: Variant = JsonLezer.lees(pad(slot))
	if not (d is Dictionary):
		return ""
	var kamer: Variant = d.get("kamer")
	var scene: Variant = d.get("scene")
	if not (kamer is String) or not (scene is String) or not s.content.kamers.has(kamer) or not s.content.scenes.has(scene):
		return ""
	var naam: Variant = s.content.kamers[kamer].get("naam", kamer)
	var klok := Klok.new(s.content)
	klok.uit_dict({"scene": scene, "gebeurtenissen": {}})
	return "%s · %s" % [s.tekst(naam if naam is String else kamer), klok.klok_tekst()]
