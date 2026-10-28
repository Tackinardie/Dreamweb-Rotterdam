class_name Toegang
extends RefCounted
## Toegang (docs/systemen/toegang.md): uitgangen, liften, niveaus en wie met wie praat.

var s: Spel


func _init(spel: Spel) -> void:
	s = spel


func uitgang(kamer: String, uitgang_id: String) -> Dictionary:
	for u: Dictionary in s.content.kamers.get(kamer, {}).get("uitgangen", []):
		if u["id"] == uitgang_id:
			return u
	return {}


## Evalueert een doorgang op het moment van aankomst (T3). Verandert niets.
## Resultaat: {"ok": bool, "reden": "", "tekst": sleutel, "cue": id, "doel": Dictionary}
func controleer(doel: Dictionary, u: Dictionary) -> Dictionary:
	var naar_scene: String = doel.get("naar_scene", u.get("naar_scene", ""))
	var scene_kamers: Array = s.content.scenes[naar_scene]["kamers"] if naar_scene != "" and s.content.scenes.has(naar_scene) \
			else s.content.scenes.get(s.klok.scene, {}).get("kamers", [])
	if not scene_kamers.has(doel["naar_kamer"]):
		return {"ok": false, "reden": "niet_nu", "tekst": "systeem.uitgang.niet_nu", "cue": _geweigerd_cue(u)}
	if not Condities.evalueer(doel.get("vereist"), s.ctx):
		var tekst: String = s.kies_variant(doel.get("geweigerd", u.get("geweigerd", "")))
		return {"ok": false, "reden": "geweigerd", "tekst": tekst if tekst != "" else "systeem.uitgang.dicht", "cue": _geweigerd_cue(u)}
	return {"ok": true, "reden": "", "tekst": "", "cue": ""}


func _geweigerd_cue(u: Dictionary) -> String:
	return u.get("geluid", {}).get("geweigerd", "lift.geweigerd" if u["type"] == "lift" else "deur.geweigerd")


## De speler komt aan bij een uitgang. Gewone deur: doorgaan of weigeren. Lift: het paneel opent (zie `lift_paneel`).
func doorgang(kamer: String, uitgang_id: String) -> Dictionary:
	var u: Dictionary = uitgang(kamer, uitgang_id)
	if u.is_empty():
		return {"ok": false, "reden": "onbekend"}
	if u.has("bestemmingen"):
		return {"ok": true, "paneel": true, "knoppen": lift_paneel(kamer, uitgang_id)}
	return _ga(u, u, kamer)


## Knoppen van het liftpaneel: alle bestemmingen behalve de huidige kamer; gedimd als `vereist` niet klopt (T8).
func lift_paneel(kamer: String, uitgang_id: String) -> Array:
	var knoppen: Array = []
	var u: Dictionary = uitgang(kamer, uitgang_id)
	for i in range((u.get("bestemmingen", []) as Array).size()):
		var b: Dictionary = u["bestemmingen"][i]
		if b["naar_kamer"] == kamer:
			continue
		var c: Dictionary = controleer(b, u)
		knoppen.append({"index": i, "label": b.get("label", ""), "naar_kamer": b["naar_kamer"], "gedimd": not c["ok"]})
	return knoppen


func kies_bestemming(kamer: String, uitgang_id: String, index: int) -> Dictionary:
	var u: Dictionary = uitgang(kamer, uitgang_id)
	if u.is_empty() or index < 0 or index >= (u.get("bestemmingen", []) as Array).size():
		return {"ok": false, "reden": "onbekend"}
	return _ga(u, u["bestemmingen"][index], kamer)


func _ga(u: Dictionary, doel: Dictionary, van_kamer: String) -> Dictionary:
	var c: Dictionary = controleer(doel, u)
	if not c["ok"]:
		s.audio.cue(c["cue"])
		s.mompel_zeg(c["tekst"])
		return c
	var naar_scene: String = doel.get("naar_scene", u.get("naar_scene", ""))
	if naar_scene != "" and naar_scene != s.klok.scene:
		var w: Dictionary = s.naar_scene(naar_scene)
		if not w["ok"]:
			return {"ok": false, "reden": w["reden"], "tekst": "systeem.niet_zonder"}
	s.audio.cue(u.get("geluid", {}).get("open", "lift.rit" if u.has("bestemmingen") else "deur.open"))
	s.verplaats_speler(doel["naar_kamer"], doel["naar_uitgang"])
	return {"ok": true, "reden": "", "van": van_kamer, "naar": doel["naar_kamer"]}


## Het eerste gesprek van een NPC waarvan `als` klopt (TG-08). "" = geen.
func kies_gesprek(npc: Dictionary) -> String:
	for g: Dictionary in npc.get("gesprekken", []):
		if Condities.evalueer(g.get("als"), s.ctx):
			return g["dialoog"]
	return ""
