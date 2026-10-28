class_name Acties
extends RefCounted
## Speleracties van Richard (pak, open, lees, gebruik, geef, ...). Elke actie controleert of het object
## bereikbaar is, voert de systeemhandeling uit en laat daarna de puzzelgraaf op de trigger reageren.

var s: Spel


func _init(spel: Spel) -> void:
	s = spel


func bereikbaar(item: String) -> bool:
	return s.objecten.bereikbaar_in(item, s.kamer)


func pak(item: String) -> Dictionary:
	var r: Dictionary = s.objecten.pak(item, s.kamer)
	if r["ok"]:
		s.puzzel.trigger({"pak": item})
	return r


func open(item: String) -> Dictionary:
	if not [s.kamer, ObjectBoom.INVENTARIS].has(s.objecten.wortel(item)):
		return {"ok": false, "reden": "onbereikbaar"}
	var r: Dictionary = s.objecten.open_container(item, s.ctx)
	if r["ok"] and not r.get("al_open", false):
		s.puzzel.trigger({"open": item})
	return r


func lees(item: String) -> Dictionary:
	if not bereikbaar(item) or not (s.content.items[item]["acties"] as Array).has("lees"):
		return {"ok": false, "reden": "onbereikbaar"}
	s.audio.cue(s.content.items[item].get("geluid", {}).get("lees", "object.lees"))
	var tekst: String = s.kies_variant(s.content.items[item]["leestekst"])
	var t: Dictionary = s.puzzel.trigger({"lees": item})
	return {"ok": true, "tekst": tekst, "trigger": t}


func bekijk(item: String) -> Dictionary:
	if not bereikbaar(item):
		return {"ok": false, "reden": "onbereikbaar"}
	return {"ok": true, "tekst": s.kies_variant(s.content.items[item]["beschrijving"]), "trigger": s.puzzel.trigger({"bekijk": item})}


func gebruik(item: String, met: String = "") -> Dictionary:
	if not bereikbaar(item) or (met != "" and not bereikbaar(met)):
		return {"ok": false, "reden": "onbereikbaar"}
	var t: Dictionary = {"gebruik": item}
	if met != "":
		t["met"] = met
	var r: Dictionary = s.puzzel.trigger(t)
	if r["standaard"] and s.content.items[item].has("gebruik_tekst"):
		s.mompel_zeg(s.kies_variant(s.content.items[item]["gebruik_tekst"]))
	return {"ok": true, "trigger": r}


## Sleep een object uit de inventaris naar een NPC in deze kamer.
func geef(item: String, personage: String) -> Dictionary:
	if not s.objecten.heeft(item):
		return {"ok": false, "reden": "niet_in_inventaris"}
	var aanwezig: bool = false
	for n: Dictionary in s.npcs_in_kamer(s.kamer):
		aanwezig = aanwezig or n["personage"] == personage
	if not aanwezig:
		return {"ok": false, "reden": "niet_aanwezig"}
	return {"ok": true, "trigger": s.puzzel.trigger({"geef": item, "aan": personage})}


func combineer(a: String, b: String) -> Dictionary:
	if not (s.tokens.has(a) and s.tokens.has(b)):
		return {"ok": false, "reden": "onbekend_token"}
	for t: Array in [[a, b], [b, a]]:
		var r: Dictionary = s.puzzel.trigger({"combineer": t}, true)
		if r["gevuurd"] != "":
			return {"ok": true, "trigger": r}
	s.mompel_zeg("systeem.notitie.past_niet")
	return {"ok": false, "reden": "past_niet"}


## Ontgrendelen met het token of de exacte waarde (het tweede geval geeft het token er ook bij).
func ontgrendel(apparaat: String, ingevoerd: String = "") -> Dictionary:
	var dev: Dictionary = s.content.apparaten.get(apparaat, {})
	if dev.is_empty() or not bereikbaar(dev["object"]):
		return {"ok": false, "reden": "onbereikbaar"}
	if s.apparaten.get(apparaat) == "ontgrendeld":
		return {"ok": true, "al_open": true}
	var v: Dictionary = dev["vergrendeling"]
	var token: String = v["sleutel_token"]
	var waarde: String = str(s.content.tokens.get(token, {}).get("waarde", ""))
	if not s.tokens.has(token) and not (ingevoerd != "" and ingevoerd == waarde):
		return {"ok": false, "reden": "geen_token"}
	if not Condities.evalueer(v.get("extra_vereist"), s.ctx):
		return {"ok": false, "reden": "extra_vereist"}
	s.geef_token(token, "ontgrendel:" + apparaat)
	s.apparaten[apparaat] = "ontgrendeld"
	return {"ok": true, "trigger": s.puzzel.trigger({"ontgrendel": apparaat})}


## Een item in een app van een ontgrendeld apparaat openen (bericht, mail, foto).
func open_app_item(apparaat: String, app: String, item: String) -> Dictionary:
	var dev: Dictionary = s.content.apparaten.get(apparaat, {})
	if dev.is_empty() or not bereikbaar(dev["object"]) or s.apparaten.get(apparaat) != "ontgrendeld":
		return {"ok": false, "reden": "onbereikbaar"}
	for a: Dictionary in dev["apps"]:
		if a["id"] != app or not Condities.evalueer(a.get("als"), s.ctx):
			continue
		for x: Dictionary in a["items"]:
			if x["id"] == item and Condities.evalueer(x.get("als"), s.ctx):
				return {"ok": true, "trigger": s.puzzel.trigger({"apparaat": apparaat, "app": app, "item": item})}
	return {"ok": false, "reden": "niet_zichtbaar"}
