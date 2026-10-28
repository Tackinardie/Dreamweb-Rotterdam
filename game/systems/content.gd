class_name ContentDb
extends Node
## Alle spelcontent uit content/ (autoload `Content`). Niets hardcoded: kamers, objecten, knopen,
## teksten en cues komen hier vandaan. Tests laden een fixture-pad met `laad(pad, cues_pad)`.

signal geladen
## Vlak voor het (her)laden: wie de oude content gebruikt, moet zijn staat wissen.
signal gewist

var pad: String = ""
var is_geladen: bool = false
var fouten: PackedStringArray = PackedStringArray()
var ontbrekende_teksten: Dictionary = {}
var content_hash: String = ""

var spel: Dictionary = {}
var items: Dictionary = {}                 # id -> item
var hoofdstukken: Dictionary = {}          # id -> chapter.json
var hoofdstuk_volgorde: Array = []
var kamers: Dictionary = {}                # id -> kamer
var kamer_hoofdstuk: Dictionary = {}       # kamer-id -> hoofdstuk-id
var scenes: Dictionary = {}                # id -> scene (+ "hoofdstuk")
var gebeurtenissen: Dictionary = {}        # id -> {"def", "scene"}
var puzzels: Dictionary = {}               # hoofdstuk -> Array knopen
var alle_knopen: Array = []                # alle knopen, hoofdstukvolgorde en bestandsvolgorde
var knopen: Dictionary = {}                # id -> knoop
var dialogen: Dictionary = {}
var apparaten: Dictionary = {}
var flags: Dictionary = {}                 # id -> flag-definitie
var tokens: Dictionary = {}                # id -> token-definitie
var condities: Dictionary = {}             # benoemde condities, globaal + lokaal
var personages: Dictionary = {}
var teksten: Dictionary = {}               # taal -> {sleutel: tekst}
var cues: Dictionary = {}                  # id -> cue
var begin_plaatsingen: Array = []          # {object, plek, positie, hoofdstuk, aanname}
var onmisbaar: Dictionary = {}             # item-id -> true (zie state-en-flags.md, "Onmisbaar")


func laad_standaard() -> bool:
	var wortel: String = ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	return laad(wortel.path_join("content"), wortel.path_join("audio/cues.json"))


func laad(content_pad: String, cues_pad: String = "") -> bool:
	_wis()
	gewist.emit()
	pad = content_pad
	var spel_data: Variant = JsonLezer.lees(pad.path_join("spel.json"))
	if cues_pad != "":
		var c: Variant = JsonLezer.lees(cues_pad)
		if c is Dictionary:
			for cue: Dictionary in (c as Dictionary).get("cues", []):
				cues[cue["id"]] = cue
	if not (spel_data is Dictionary):
		return false  # geen spelcontent (nog): een lege wereld is geen fout
	spel = spel_data
	var hasher := HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	for p in JsonLezer.lijst_json(pad):
		hasher.update(FileAccess.get_file_as_bytes(p))
	content_hash = hasher.finish().hex_encode()
	for p: Dictionary in spel.get("personages", []):
		personages[p["id"]] = p
	for f: Dictionary in spel.get("flags", []):
		flags[f["id"]] = f
	condities = (spel.get("condities", {}) as Dictionary).duplicate(true)
	var it: Variant = JsonLezer.lees(pad.path_join("items.json"))
	if it is Dictionary:
		for item: Dictionary in (it as Dictionary).get("items", []):
			items[item["id"]] = item
	_laad_teksten()
	hoofdstuk_volgorde = (spel.get("hoofdstukken", []) as Array).duplicate()
	for h: String in hoofdstuk_volgorde:
		_laad_hoofdstuk(h)
	_bereken_onmisbaar()
	is_geladen = true
	geladen.emit()
	return true


func _wis() -> void:
	for naam: String in ["spel", "items", "hoofdstukken", "kamers", "kamer_hoofdstuk", "scenes", "gebeurtenissen", "puzzels",
			"knopen", "dialogen", "apparaten", "flags", "tokens", "condities", "personages", "teksten", "cues", "onmisbaar",
			"ontbrekende_teksten"]:
		(get(naam) as Dictionary).clear()
	alle_knopen.clear()
	begin_plaatsingen.clear()
	hoofdstuk_volgorde.clear()
	fouten = PackedStringArray()
	is_geladen = false
	content_hash = ""


func _laad_teksten() -> void:
	for p in JsonLezer.lijst_json(pad.path_join("tekst")):
		var d: Variant = JsonLezer.lees(p)
		if d is Dictionary:
			var taal: String = (d as Dictionary).get("taal", "nl")
			if not teksten.has(taal):
				teksten[taal] = {}
			(teksten[taal] as Dictionary).merge((d as Dictionary).get("teksten", {}), true)


func _laad_hoofdstuk(h: String) -> void:
	var map: String = pad.path_join("chapters").path_join(h)
	var ch: Variant = JsonLezer.lees(map.path_join("chapter.json"))
	if not (ch is Dictionary):
		fouten.append("hoofdstuk %s: chapter.json ontbreekt of is ongeldig" % h)
		return
	var chd: Dictionary = ch
	hoofdstukken[h] = chd
	for f: Dictionary in chd.get("flags", []):
		flags[f["id"]] = f
	for t: Dictionary in chd.get("tokens", []):
		tokens[t["id"]] = t
	condities.merge(chd.get("condities", {}), true)
	for sc: Dictionary in chd.get("scenes", []):
		sc["hoofdstuk"] = h
		scenes[sc["id"]] = sc
		for g: Dictionary in sc.get("gebeurtenissen", []):
			gebeurtenissen[g["id"]] = {"def": g, "scene": sc["id"]}
	for p in JsonLezer.lijst_json(map.path_join("rooms")):
		var k: Variant = JsonLezer.lees(p)
		if k is Dictionary:
			var kd: Dictionary = k
			kamers[kd["id"]] = kd
			kamer_hoofdstuk[kd["id"]] = h
			_plaatsingen(kd.get("objecten", []), kd["id"], h, false)
	_plaatsingen(chd.get("aanname_bij_start", {}).get("inventaris", []), "inventaris", h, true)
	for p in JsonLezer.lijst_json(map.path_join("dialogue")):
		var dd: Variant = JsonLezer.lees(p)
		if dd is Dictionary:
			dialogen[(dd as Dictionary)["id"]] = dd
	for p in JsonLezer.lijst_json(map.path_join("devices")):
		var ad: Variant = JsonLezer.lees(p)
		if ad is Dictionary:
			apparaten[(ad as Dictionary)["id"]] = ad
	var pz: Variant = JsonLezer.lees(map.path_join("puzzles.json"))
	if pz is Dictionary:
		puzzels[h] = (pz as Dictionary).get("knopen", [])
		for kn: Dictionary in puzzels[h]:
			knopen[kn["id"]] = kn
			alle_knopen.append(kn)


func _plaatsingen(lijst: Array, plek: String, h: String, aanname: bool) -> void:
	for x: Dictionary in lijst:
		var pos: Variant = null
		if x.has("positie"):
			pos = Vector2i(x["positie"]["x"], x["positie"]["y"])
		begin_plaatsingen.append({"object": x["object"], "plek": plek, "positie": pos, "hoofdstuk": h, "aanname": aanname})
		_plaatsingen(x.get("inhoud", []), x["object"], h, aanname)


## Onmisbaar = voorkomt in een heeft/ligt-atoom, een trigger (gebruik, met, geef, open, lees), is het
## object van een apparaat of geeft een toegangsniveau dat in een conditie gebruikt wordt.
## (Het laatste is een aanvulling op de spec; zonder dat kan een pas achtergelaten worden.)
func _bereken_onmisbaar() -> void:
	var niveaus: Dictionary = {}
	var docs: Array = [spel.get("condities", {}), items.values()]
	for ch: Dictionary in hoofdstukken.values():
		docs.append([ch.get("doel"), ch.get("condities", {}), ch.get("scenes", [])])
	for k: Dictionary in kamers.values():
		docs.append([k.get("uitgangen", []), k.get("npcs", [])])  # niet de kamer zelf: "niveau" is daar een eigenschap
	docs.append(dialogen.values())
	for a: Dictionary in apparaten.values():
		onmisbaar[a["object"]] = true
		docs.append(a)
	for kn: Dictionary in alle_knopen:
		var t: Dictionary = kn["trigger"]
		for sl: String in ["gebruik", "met", "geef", "open", "lees"]:
			if t.has(sl):
				onmisbaar[t[sl]] = true
		docs.append(kn.get("vereist"))
	_scan_condities(docs, niveaus)
	for id: String in items:
		for n: String in items[id].get("geeft_niveaus", []):
			if niveaus.has(n):
				onmisbaar[id] = true


func _scan_condities(x: Variant, niveaus: Dictionary) -> void:
	if x is Dictionary:
		var d: Dictionary = x
		if d.has("heeft") and d["heeft"] is String:
			onmisbaar[d["heeft"]] = true
		if d.has("ligt") and d["ligt"] is Dictionary:
			onmisbaar[(d["ligt"] as Dictionary).get("object", "")] = true
		if d.has("niveau") and d["niveau"] is String:
			niveaus[d["niveau"]] = true
		for k: Variant in d:
			_scan_condities(d[k], niveaus)
	elif x is Array:
		for v: Variant in (x as Array):
			_scan_condities(v, niveaus)


func knoop_lijst(hoofdstuk: String) -> Array:
	return puzzels.get(hoofdstuk, [])


## Tekst voor een sleutel in de gevraagde taal; valt terug op nl, daarna op de sleutel zelf.
func tekst(sleutel: String, taal: String = "nl") -> String:
	var t: Dictionary = teksten.get(taal, {})
	if t.has(sleutel):
		return t[sleutel]
	if (teksten.get("nl", {}) as Dictionary).has(sleutel):
		return teksten["nl"][sleutel]
	ontbrekende_teksten[sleutel] = true
	return sleutel


func eerste_hoofdstuk() -> String:
	return hoofdstuk_volgorde[0] if not hoofdstuk_volgorde.is_empty() else ""
