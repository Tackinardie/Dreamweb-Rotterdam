extends RefCounted
## Gedeelde hulp voor de GUT-tests: laadt het testhoofdstuk uit tests/fixtures/proef en bouwt een Spel.
## Geen class_name: de tests staan buiten res:// en laden dit bestand met preload("hulp.gd").

const FIXTURE: String = "../tests/fixtures/proef"
const HAL: String = "ch01_hal"
const KANTOOR: String = "ch01_kantoor"
const DAK: String = "ch01_dak"
const S1: String = "ch01_s1_nacht"
const S2: String = "ch01_s2_ochtend"


static func repo() -> String:
	return ProjectSettings.globalize_path("res://").path_join("..").simplify_path()


static func fixture_pad() -> String:
	return repo().path_join("tests/fixtures/proef")


static func nieuw_content() -> ContentDb:
	var c := ContentDb.new()
	assert(c.laad(fixture_pad(), fixture_pad().path_join("cues.json")), "fixture laadt niet")
	return c


## Een compleet spel met fixturecontent; `test` ruimt het op.
static func nieuw_spel(test: GutTest, naam: String = "t", overlay: String = "", hoofdstuk: String = "ch01_proef") -> Spel:
	var c := ContentDb.new()
	var pad: String = fixture_pad() if overlay == "" else maak_overlay(overlay)
	assert(c.laad(pad, fixture_pad().path_join("cues.json")), "fixture laadt niet")
	test.add_child_autofree(c)
	var s := Spel.new(c)
	test.add_child_autofree(s)
	s.opslag.map = "user://test_saves/" + naam
	s.nieuw_spel(hoofdstuk)
	return s


## Kopieert de fixture plus een overlay uit tests/fixtures/kapot/<naam> naar user://overlays/<naam>.
static func maak_overlay(naam: String) -> String:
	var doel: String = "user://overlays/" + naam
	kopieer_map(fixture_pad(), doel)
	kopieer_map(repo().path_join("tests/fixtures/kapot/" + naam), doel)
	return ProjectSettings.globalize_path(doel)


static func kopieer_map(van: String, naar: String) -> void:
	DirAccess.make_dir_recursive_absolute(naar)
	for f in DirAccess.get_files_at(van):
		DirAccess.copy_absolute(van.path_join(f), naar.path_join(f))
	for d in DirAccess.get_directories_at(van):
		kopieer_map(van.path_join(d), naar.path_join(d))


## Voegt tijdens een test een knoop toe aan het hoofdstuk van het spel.
static func voeg_knoop_toe(s: Spel, knoop: Dictionary) -> void:
	(s.content.puzzels[s.hoofdstuk] as Array).append(knoop)
	s.content.knopen[knoop["id"]] = knoop
	s.content.knoop_hoofdstuk[knoop["id"]] = s.hoofdstuk


## Voegt tijdens een test een scene toe (bijv. een waarin het kantoor wegvalt).
static func voeg_scene_toe(s: Spel, id: String, kamers: Array, tijd: Dictionary) -> void:
	s.content.scenes[id] = {"id": id, "hoofdstuk": s.hoofdstuk, "tijd": tijd, "kamers": kamers}


static func wis_map(pad: String) -> void:
	if not DirAccess.dir_exists_absolute(pad):
		return
	for f in DirAccess.get_files_at(pad):
		DirAccess.remove_absolute(pad.path_join(f))


## Cues die sinds het begin zijn aangeroepen (uit het logboek).
static func cues(s: Spel) -> Array:
	return s.audio.logboek.map(func(r: Dictionary) -> String: return r["cue"])


## Een Spel met synthetische content en toestand uit een geval van condities.json (voor SpelContext).
static func spel_uit_toestand(test: GutTest, t: Dictionary, benoemd: Dictionary) -> Spel:
	var c := ContentDb.new()
	c.condities = benoemd.duplicate(true)
	for id: String in t["items"]:
		c.items[id] = {"id": id, "pakbaar": true, "grootte": 1, "geeft_niveaus": t["items"][id].get("geeft_niveaus", []),
				"container": {"capaciteit": 9, "max_grootte": 3}}
	for p: String in t["plekken"].values():
		if p != "inventaris" and p != "nergens" and not c.items.has(p):
			c.kamers[p] = {"id": p}
	c.kamers[t["kamer"]] = {"id": t["kamer"]}
	for f: String in t["flag_start"]:
		c.flags[f] = {"id": f, "type": "int", "start": t["flag_start"][f]}
	for tk: String in t["tokens"]:
		c.tokens[tk] = {"id": tk}
	for k: String in t["knopen"]:
		c.knopen[k] = {"id": k}
	for a: String in t["apparaten"]:
		c.apparaten[a] = {"id": a}
	c.scenes[t["scene"]] = {"id": t["scene"], "hoofdstuk": "x", "tijd": {"dag": t["dag"], "tijd": t["tijd"]}, "kamers": [t["kamer"]]}
	test.add_child_autofree(c)
	var s := Spel.new(c)
	test.add_child_autofree(s)
	s.objecten.plek = (t["plekken"] as Dictionary).duplicate()
	s.flags = (t["flags"] as Dictionary).duplicate()
	for tk: String in t["tokens"]:
		s.tokens[tk] = {"id": tk}
	for k: String in t["knopen"]:
		s.knopen[k] = true
	s.apparaten = (t["apparaten"] as Dictionary).duplicate()
	s.klok.scene = t["scene"]
	s.klok.tijd = {"dag": t["dag"], "tijd": t["tijd"]}
	for e: String in t["gebeurtenissen"]:
		var g: Dictionary = s.klok._nieuw_status()
		g["status"] = t["gebeurtenissen"][e]
		s.klok.gebeurtenissen[e] = g
	s.kamer = t["kamer"]
	return s


## ConditieContext uit de JSON van tests/fixtures/condities.json.
class DictContext extends ConditieContext:
	var plekken: Dictionary
	var items: Dictionary
	var tokens: Array
	var flag_start: Dictionary
	var flags: Dictionary
	var knopen: Array
	var kamer: String
	var scene: String
	var gebeurtenissen: Dictionary
	var dag: int
	var tijd: String
	var apparaten: Dictionary
	var namen: Dictionary

	func _init(d: Dictionary, benoemd: Dictionary) -> void:
		plekken = d.get("plekken", {})
		items = d.get("items", {})
		tokens = d.get("tokens", [])
		flag_start = d.get("flag_start", {})
		flags = d.get("flags", {})
		knopen = d.get("knopen", [])
		kamer = d.get("kamer", "")
		scene = d.get("scene", "")
		gebeurtenissen = d.get("gebeurtenissen", {})
		dag = int(d.get("dag", 1))
		tijd = d.get("tijd", "00:00")
		apparaten = d.get("apparaten", {})
		namen = benoemd

	func fout(tekst: String) -> void:
		fouten.append(tekst)   # geen printerr: het zijn verwachte fouten

	func _voorouders(item: String) -> Array:
		var keten: Array = []
		var huidig: String = item
		var n: int = 0
		if not plekken.has(item):
			return ["nergens"]
		while plekken.has(huidig) and n < 64:
			huidig = plekken[huidig]
			keten.append(huidig)
			n += 1
		return keten

	func item_bekend(item: String) -> bool: return items.has(item)
	func heeft(item: String) -> bool: return _voorouders(item).has("inventaris")
	func ligt(item: String, plek: String) -> bool: return _voorouders(item).has(plek)
	func heeft_token(token: String) -> bool: return tokens.has(token)
	func flag_waarde(flag: String) -> Variant: return flags[flag] if flags.has(flag) else flag_start.get(flag)
	func knoop_opgelost(knoop: String) -> bool: return knopen.has(knoop)
	func huidige_kamer() -> String: return kamer
	func huidige_scene() -> String: return scene
	func gebeurtenis_status(gebeurtenis: String) -> String: return gebeurtenissen.get(gebeurtenis, "")
	func kloktijd_minuten() -> int: return Condities.minuten(tijd)
	func scenetijd_minuten() -> int: return dag * 1440 + Condities.minuten(tijd)
	func apparaat_toestand(apparaat: String) -> String: return apparaten.get(apparaat, "")
	func benoemd(naam: String) -> Variant: return namen.get(naam)

	func heeft_niveau(niveau: String) -> bool:
		for id: String in items:
			if heeft(id) and (items[id].get("geeft_niveaus", []) as Array).has(niveau):
				return true
		return false
