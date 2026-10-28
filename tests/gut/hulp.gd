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
static func nieuw_spel(test: GutTest, naam: String = "t") -> Spel:
	var c: ContentDb = nieuw_content()
	test.add_child_autofree(c)
	var s := Spel.new(c)
	test.add_child_autofree(s)
	s.opslag.map = "user://test_saves/" + naam
	s.nieuw_spel()
	return s


static func wis_map(pad: String) -> void:
	for f in DirAccess.get_files_at(pad):
		DirAccess.remove_absolute(pad.path_join(f))


## Cues die sinds het begin zijn aangeroepen (uit het logboek).
static func cues(s: Spel) -> Array:
	return s.audio.logboek.map(func(r: Dictionary) -> String: return r["cue"])


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
