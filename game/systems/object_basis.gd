class_name ObjectBasis
extends RefCounted
## Toestand en vragen van de objectboom (docs/systemen/objecten-en-inventaris.md): elk object heeft precies één plek,
## "inventaris", een kamer-id, een container-id of "nergens". De acties staan in ObjectBoom.

signal object_verplaatst(item: String, van: String, naar: String)
signal container_geopend(item: String)
signal cue_gevraagd(cue_id: String, context: Dictionary)
signal mompel_gevraagd(sleutel: String, vars: Dictionary)

const INVENTARIS: String = "inventaris"
const NERGENS: String = "nergens"
const BUREN: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
		Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)]

var content: ContentDb
var slots: int = 8
var plek: Dictionary = {}        # item -> plek
var positie: Dictionary = {}     # item -> Vector2i (alleen voor objecten op een kamervloer)
var kinderen: Dictionary = {}    # plek -> Array[String] in volgorde
var open: Dictionary = {}        # container -> true
var _begin_plek: Dictionary = {}
var _begin_positie: Dictionary = {}
var _begin_kinderen: Dictionary = {}


func _init(c: ContentDb) -> void:
	content = c


## Zet alle objecten op hun beginplek: kamerbestanden plus de aanname van het opgegeven hoofdstuk.
func reset(hoofdstuk: String) -> void:
	slots = int(content.spel.get("inventaris_slots", 8))
	plek.clear()
	positie.clear()
	kinderen.clear()
	open.clear()
	for id: String in content.items:
		plek[id] = NERGENS
	for p: Dictionary in content.begin_plaatsingen:
		if p["aanname"] and p["hoofdstuk"] != hoofdstuk:
			continue
		if not content.items.has(p["object"]):
			continue
		_zet(p["object"], p["plek"], p["positie"])
	_begin_plek = plek.duplicate()
	_begin_positie = positie.duplicate()
	_begin_kinderen = kinderen.duplicate(true)


# ---------------------------------------------------------------- vragen

func is_kamer(p: String) -> bool:
	return content.kamers.has(p)


func is_item(p: String) -> bool:
	return content.items.has(p)


func is_container(item: String) -> bool:
	return content.items.get(item, {}).has("container")


func is_pakbaar(item: String) -> bool:
	return content.items.get(item, {}).get("pakbaar", false)


func grootte(item: String) -> int:
	return int(content.items.get(item, {}).get("grootte", 0)) if is_pakbaar(item) else 0


func capaciteit(item: String) -> int:
	return int(content.items[item]["container"]["capaciteit"])


func max_grootte(item: String) -> int:
	return int(content.items[item]["container"]["max_grootte"])


func inhoud_som(container: String) -> int:
	var som: int = 0
	for k: String in kinderen.get(container, []):
		som += grootte(k)
	return som


func inventaris_som() -> int:
	return inhoud_som(INVENTARIS)


## Het eind van de keten: "inventaris", een kamer-id of "nergens".
func wortel(item: String) -> String:
	var p: String = plek.get(item, NERGENS)
	var stappen: int = 0
	while is_item(p) and stappen < 64:
		p = plek.get(p, NERGENS)
		stappen += 1
	return p


func heeft(item: String) -> bool:
	return wortel(item) == INVENTARIS


## Ligt `item` (op elke diepte) in `waar`?
func ligt(item: String, waar: String) -> bool:
	var p: String = plek.get(item, NERGENS)
	var stappen: int = 0
	while stappen < 64:
		if p == waar:
			return true
		if not is_item(p):
			return false
		p = plek.get(p, NERGENS)
		stappen += 1
	return false


## Zit `kandidaat` in de deelboom van `item` (of is het item zelf)?
func in_deelboom(item: String, kandidaat: String) -> bool:
	return kandidaat == item or ligt(kandidaat, item)


## Alle containers tussen het object en de wortel gesloten of geopend: zichtbaar/pakbaar als alle open zijn.
func bereikbaar_in(item: String, kamer: String) -> bool:
	var w: String = wortel(item)
	if w != kamer and w != INVENTARIS:
		return false
	var p: String = plek.get(item, NERGENS)
	while is_item(p):
		if not open.has(p):
			return false
		p = plek.get(p, NERGENS)
	return true


func kamer_objecten(kamer: String) -> Array:
	return (kinderen.get(kamer, []) as Array).duplicate()


## Gedragen containers in stripvolgorde (links naar rechts, diepte eerst), zonder `uitgezonderd` en zijn deelboom.
func gedragen_containers(uitgezonderd: String = "") -> Array[String]:
	var uit: Array[String] = []
	_verzamel(INVENTARIS, uitgezonderd, uit)
	return uit


func _verzamel(van: String, uitgezonderd: String, uit: Array[String]) -> void:
	for k: String in kinderen.get(van, []):
		if k == uitgezonderd:
			continue
		if is_container(k):
			uit.append(k)
			_verzamel(k, uitgezonderd, uit)


func kan_stoppen(item: String, container: String) -> Dictionary:
	if not is_container(container):
		return {"ok": false, "reden": "geen_container"}
	if not is_pakbaar(item):
		return {"ok": false, "reden": "niet_pakbaar"}
	if in_deelboom(item, container):
		return {"ok": false, "reden": "cyclus"}
	if grootte(item) > max_grootte(container):
		return {"ok": false, "reden": "te_groot"}
	var al_erin: int = grootte(item) if plek.get(item) == container else 0
	if inhoud_som(container) - al_erin + grootte(item) > capaciteit(container):
		return {"ok": false, "reden": "vol"}
	return {"ok": true, "reden": ""}


# ---------------------------------------------------------------- intern

func _cue(item: String, actie: String, standaard: String) -> String:
	return content.items.get(item, {}).get("geluid", {}).get(actie, standaard)


func _zet(item: String, naar: String, pos: Variant = null) -> void:
	var van: String = plek.get(item, NERGENS)
	if kinderen.has(van):
		(kinderen[van] as Array).erase(item)
	plek[item] = naar
	if not kinderen.has(naar):
		kinderen[naar] = []
	(kinderen[naar] as Array).append(item)
	if is_kamer(naar) and pos != null:
		positie[item] = pos
	else:
		positie.erase(item)
	object_verplaatst.emit(item, van, naar)


# ---------------------------------------------------------------- opslaan

## Alleen wat afwijkt van de beginplek, plus de volgorde van de inventaris (zie state-en-flags.md).
func naar_dict() -> Dictionary:
	var objecten: Dictionary = {}
	for item: String in plek:
		var p: Variant = positie.get(item)
		if plek[item] != _begin_plek.get(item) or p != _begin_positie.get(item):
			var e: Dictionary = {"plek": plek[item]}
			if p != null:
				e["positie"] = {"x": (p as Vector2i).x, "y": (p as Vector2i).y}
			objecten[item] = e
	var volgorde: Dictionary = {}
	for pl: String in kinderen:
		if pl == INVENTARIS or is_item(pl):
			if kinderen[pl] != _begin_kinderen.get(pl, []):
				volgorde[pl] = (kinderen[pl] as Array).duplicate()
	return {"objecten": objecten, "volgorde": volgorde, "open": open.keys()}


## Herstelt vanaf de beginplekken. Onbekende ids worden overgeslagen; geeft de waarschuwingen terug.
func uit_dict(d: Dictionary) -> PackedStringArray:
	var waarschuwingen := PackedStringArray()
	plek = _begin_plek.duplicate()
	positie = _begin_positie.duplicate()
	kinderen = _begin_kinderen.duplicate(true)
	open.clear()
	var objecten: Dictionary = d.get("objecten", {})
	for item: String in objecten:
		if not content.items.has(item):
			waarschuwingen.append("save: onbekend object '%s' overgeslagen" % item)
			continue
		var e: Dictionary = objecten[item]
		var naar: String = e["plek"]
		if naar != NERGENS and naar != INVENTARIS and not is_kamer(naar) and not is_item(naar):
			waarschuwingen.append("save: onbekende plek '%s' voor '%s'; beginplek gebruikt" % [naar, item])
			continue
		var pos: Variant = null
		if e.has("positie"):
			pos = Vector2i(int(e["positie"]["x"]), int(e["positie"]["y"]))
		_zet(item, naar, pos)
	var volgorde: Dictionary = d.get("volgorde", {})
	for pl: String in volgorde:
		var gevuld: Array = []
		for item: String in volgorde[pl]:
			if plek.get(item) == pl:
				gevuld.append(item)
		for item: String in kinderen.get(pl, []):
			if not gevuld.has(item):
				gevuld.append(item)
		kinderen[pl] = gevuld
	for c: String in d.get("open", []):
		if content.items.has(c):
			open[c] = true
		else:
			waarschuwingen.append("save: onbekende container '%s' overgeslagen" % c)
	return waarschuwingen
