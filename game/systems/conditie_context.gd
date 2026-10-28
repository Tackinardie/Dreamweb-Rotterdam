class_name ConditieContext
extends RefCounted
## Wat een conditie over de wereld mag weten (alleen lezen). De GameState-implementatie is `SpelContext`;
## de gedeelde testset gebruikt een eigen implementatie in tests/gut/.

var fouten: PackedStringArray = PackedStringArray()


func fout(tekst: String) -> void:
	fouten.append(tekst)
	printerr("conditie: " + tekst)


func item_bekend(_item: String) -> bool: return true
func heeft(_item: String) -> bool: return false
func ligt(_item: String, _plek: String) -> bool: return false
func heeft_token(_token: String) -> bool: return false
## null = onbekende flag
func flag_waarde(_flag: String) -> Variant: return null
func knoop_opgelost(_knoop: String) -> bool: return false
func huidige_kamer() -> String: return ""
func huidige_scene() -> String: return ""
## "" = onbekende gebeurtenis
func gebeurtenis_status(_gebeurtenis: String) -> String: return ""
func kloktijd_minuten() -> int: return 0
func scenetijd_minuten() -> int: return 0
func heeft_niveau(_niveau: String) -> bool: return false
## "" = onbekend apparaat
func apparaat_toestand(_apparaat: String) -> String: return ""
## null = onbekende benoemde conditie
func benoemd(_naam: String) -> Variant: return null
