class_name Interactie
extends RefCounted
## Wat een klik op een object doet (objecten-en-inventaris.md, UX; kamerweergave.md, W15).

const VOLGORDE: Array[String] = ["pak", "open", "lees", "gebruik", "bekijk"]


## `standaard_actie` of de eerste uit pak > open > lees > gebruik > bekijk die het object heeft.
static func standaard_actie(item: Dictionary) -> String:
	if item.has("standaard_actie"):
		return item["standaard_actie"]
	var acties: Array = item.get("acties", [])
	for a in VOLGORDE:
		if acties.has(a):
			return a
	return "bekijk"


static func voer_uit(spel: Spel, item: String, actie: String) -> Dictionary:
	match actie:
		"pak": return spel.acties.pak(item)
		"open": return spel.acties.open(item)
		"lees": return spel.acties.lees(item)
		"gebruik": return spel.acties.gebruik(item)
		_: return spel.acties.bekijk(item)
