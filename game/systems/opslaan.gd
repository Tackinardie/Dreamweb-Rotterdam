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


func schrijf(slot: String) -> bool:
	DirAccess.make_dir_recursive_absolute(map)
	var f: FileAccess = FileAccess.open(pad(slot), FileAccess.WRITE)
	if f == null:
		s.log_fout("opslaan mislukt: %s" % pad(slot))
		return false
	f.store_string(JSON.stringify(maak_save(), "\t", true))
	return true


## Laden. Resultaat: {"ok", "reden", "waarschuwingen": PackedStringArray, "melding": tekstsleutel}
func laad(slot: String) -> Dictionary:
	var d: Variant = JsonLezer.lees(pad(slot))
	if not (d is Dictionary):
		return {"ok": false, "reden": "geen_save", "waarschuwingen": PackedStringArray()}
	return pas_toe(d)


func pas_toe(d: Dictionary) -> Dictionary:
	var waarschuwingen := PackedStringArray()
	if int(d.get("versie", 0)) > VERSIE:
		s.mompel_zeg("systeem.save.te_nieuw")
		return {"ok": false, "reden": "te_nieuw", "melding": "systeem.save.te_nieuw", "waarschuwingen": waarschuwingen}
	if d.get("content_hash", "") != s.content.content_hash and Ontwikkel.actief():
		waarschuwingen.append("save: de content is veranderd sinds het opslaan")
	var h: String = d.get("hoofdstuk", "")
	if not s.content.hoofdstukken.has(h):
		return {"ok": false, "reden": "onbekend_hoofdstuk", "waarschuwingen": waarschuwingen}
	s.hoofdstuk = h
	s.objecten.reset(h)
	waarschuwingen.append_array(s.objecten.uit_dict({"objecten": d.get("objecten", {}), "volgorde": d.get("volgorde", {}),
			"open": d.get("containers_open", [])}))
	s.flags.clear()
	for id: String in d.get("flags", {}):
		if s.content.flags.has(id):
			s.flags[id] = d["flags"][id]
		else:
			waarschuwingen.append("save: onbekende flag '%s' overgeslagen" % id)
	s.tokens.clear()
	s.token_volgorde.clear()
	for t: Dictionary in d.get("tokens", []):
		if s.content.tokens.has(t.get("id", "")):
			s.tokens[t["id"]] = t
			s.token_volgorde.append(t["id"])
		else:
			waarschuwingen.append("save: onbekend token '%s' overgeslagen" % t.get("id", ""))
	s.knopen.clear()
	s.knopen_volgorde.clear()
	for k: String in d.get("knopen", []):
		if s.content.knopen.has(k):
			s.knopen[k] = true
			s.knopen_volgorde.append(k)
		else:
			waarschuwingen.append("save: onbekende knoop '%s' overgeslagen" % k)
	s.apparaten.clear()
	for id: String in s.content.apparaten:
		s.apparaten[id] = "ontgrendeld" if s.content.apparaten[id]["vergrendeling"]["type"] == "geen" else "vergrendeld"
	for id: String in d.get("apparaten", {}):
		if s.content.apparaten.has(id):
			s.apparaten[id] = d["apparaten"][id]
		else:
			waarschuwingen.append("save: onbekend apparaat '%s' overgeslagen" % id)
	s.dialoog_keuzes.clear()
	for k: String in d.get("dialoog", []):
		s.dialoog_keuzes[k] = true
	s.hints = (d.get("hints", {}) as Dictionary).duplicate()
	s.systemen = (d.get("systemen", {}) as Dictionary).duplicate(true)
	s.speeltijd_s = float(d.get("speeltijd_s", 0.0))
	s.klok.uit_dict({"scene": d.get("scene", ""), "gebeurtenissen": d.get("gebeurtenissen", {})})
	s.kamer = d.get("kamer", "")
	var p: Dictionary = d.get("positie", {"x": 0, "y": 0})
	s.positie = Vector2i(int(p["x"]), int(p["y"]))
	s.voltooid = false
	s._kamer_geluid()
	for w in waarschuwingen:
		s.log_fout(w)
	return {"ok": true, "reden": "", "waarschuwingen": waarschuwingen}


## "Studentenkamer · wo 1 jan · 00:07" voor het laadscherm (geen echte datum).
func slot_titel(slot: String) -> String:
	var d: Variant = JsonLezer.lees(pad(slot))
	if not (d is Dictionary):
		return ""
	var k: String = s.tekst(s.content.kamers.get(d["kamer"], {}).get("naam", d["kamer"]))
	var klok := Klok.new(s.content)
	klok.uit_dict({"scene": d["scene"], "gebeurtenissen": {}})
	return "%s · %s" % [k, klok.klok_tekst()]
