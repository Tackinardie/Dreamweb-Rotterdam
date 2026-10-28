class_name SpelContext
extends ConditieContext
## Laat condities de echte spelstaat lezen. Alleen lezen (SF-07).

var s: Spel


func _init(spel: Spel) -> void:
	s = spel


func fout(tekst: String) -> void:
	s.log_fout("conditie: " + tekst)


func item_bekend(item: String) -> bool: return s.content.items.has(item)
func heeft(item: String) -> bool: return s.objecten.heeft(item)
func ligt(item: String, plek: String) -> bool: return s.objecten.ligt(item, plek)
func heeft_token(token: String) -> bool: return s.tokens.has(token)
func flag_waarde(flag: String) -> Variant: return s.flag_waarde(flag)
func knoop_opgelost(knoop: String) -> bool: return s.knopen.has(knoop)
func huidige_kamer() -> String: return s.kamer
func huidige_scene() -> String: return s.klok.scene
func kloktijd_minuten() -> int: return s.klok.kloktijd_minuten()
func scenetijd_minuten() -> int: return s.klok.scenetijd_minuten()


func gebeurtenis_status(gebeurtenis: String) -> String:
	return s.klok.status(gebeurtenis)


func heeft_niveau(niveau: String) -> bool:
	for id: String in s.content.items:
		if niveau in (s.content.items[id].get("geeft_niveaus", []) as Array) and s.objecten.heeft(id):
			return true
	return false


func apparaat_toestand(apparaat: String) -> String:
	return s.apparaten.get(apparaat, "")


func benoemd(naam: String) -> Variant:
	return s.content.condities.get(naam)
