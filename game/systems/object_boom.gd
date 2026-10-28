class_name ObjectBoom
extends ObjectBasis
## Objecten en inventaris: pakken, neerleggen, in containers stoppen en openen (O6 t/m O11).


# ---------------------------------------------------------------- acties

## Pakken (O7): eerst in de vrije bovenste slots, anders in de eerste gedragen container waar het past.
func pak(item: String, kamer: String) -> Dictionary:
	if not is_pakbaar(item) or heeft(item):
		return {"ok": false, "reden": "niet_pakbaar"}
	if wortel(item) != kamer or not bereikbaar_in(item, kamer):
		return {"ok": false, "reden": "onbereikbaar"}
	var bestemming: String = _inventaris_plek(item)
	if bestemming == "":
		mompel_gevraagd.emit("systeem.inventaris.vol", {})
		cue_gevraagd.emit("ui.weiger", {})
		return {"ok": false, "reden": "vol"}
	_zet(item, bestemming)
	cue_gevraagd.emit(_cue(item, "pak", "object.pak"), {})
	return {"ok": true, "bestemming": bestemming}


## Waar zou dit object in de inventaris landen? "" = nergens.
func _inventaris_plek(item: String) -> String:
	if inventaris_som() - (grootte(item) if plek.get(item) == INVENTARIS else 0) + grootte(item) <= slots:
		return INVENTARIS
	for c in gedragen_containers(item):
		if kan_stoppen(item, c)["ok"]:
			return c
	return ""


## Een object uit een gedragen container halen en in de strook leggen (of in een andere container).
func uitpakken(item: String) -> Dictionary:
	if not heeft(item) or plek.get(item) == INVENTARIS:
		return {"ok": false, "reden": "niet_in_container"}
	var oud: String = plek[item]
	if inventaris_som() + grootte(item) <= slots:
		_zet(item, INVENTARIS)
		return {"ok": true, "bestemming": INVENTARIS}
	for c in gedragen_containers(item):
		if c != oud and kan_stoppen(item, c)["ok"]:
			_zet(item, c)
			return {"ok": true, "bestemming": c}
	return {"ok": false, "reden": "vol"}


## Neerleggen (O8) op het vak van de speler, anders op het dichtstbijzijnde vrije vak binnen 1 vak.
func leg_neer(item: String, kamer: String, tegel: Vector2i, geblokkeerd: Array = []) -> Dictionary:
	if not heeft(item) or not is_pakbaar(item):
		return {"ok": false, "reden": "niet_in_inventaris"}
	if not content.kamers.get(kamer, {}).get("neerleggen", true):
		mompel_gevraagd.emit("systeem.neerleggen.niet_hier", {})
		cue_gevraagd.emit("ui.weiger", {})
		return {"ok": false, "reden": "niet_hier"}
	var vrij: Variant = vrije_tegel(kamer, tegel, geblokkeerd)
	if vrij == null:
		mompel_gevraagd.emit("systeem.neerleggen.geen_plek", {})
		cue_gevraagd.emit("ui.weiger", {})
		return {"ok": false, "reden": "geen_plek"}
	_zet(item, kamer, vrij)
	cue_gevraagd.emit(_cue(item, "leg", "object.leg"), {})
	return {"ok": true, "tegel": vrij}


## Eerste vrije vak op `start` of een van de 8 buren; geblokkeerde vakken uit de kamerdata (`geblokkeerd`) tellen
## altijd mee, `geblokkeerd` is voor extra vakken. Naam blijft `tegel` (publieke API).
func vrije_tegel(kamer: String, start: Vector2i, geblokkeerd: Array = []) -> Variant:
	var k: Dictionary = content.kamers.get(kamer, {})
	var b: int = int(k.get("afmeting", {}).get("breedte", 0))
	var h: int = int(k.get("afmeting", {}).get("hoogte", 0))
	var bezet: Array[Vector2i] = []
	for g: Variant in geblokkeerd:
		bezet.append(g)
	for gebied: Dictionary in k.get("geblokkeerd", []):
		bezet.append_array(Vak.gebied_vakken(gebied))
	for u: Dictionary in k.get("uitgangen", []):
		bezet.append(Vector2i(u["positie"]["x"], u["positie"]["y"]))
	for o: String in kinderen.get(kamer, []):
		if positie.has(o):
			bezet.append(positie[o])
	for d: Vector2i in BUREN:
		var c: Vector2i = start + d
		if c.x >= 0 and c.y >= 0 and c.x < b and c.y < h and not bezet.has(c):
			return c
	return null


## Sleep een object in een container. Wereldcontainers moeten open zijn en in de huidige kamer staan (O10).
func stop_in(item: String, container: String, kamer: String) -> Dictionary:
	var kan: Dictionary = kan_stoppen(item, container)
	if not kan["ok"]:
		if kan["reden"] == "te_groot":
			mompel_gevraagd.emit("systeem.past_niet", {})
		cue_gevraagd.emit("ui.weiger", {})
		return kan
	var w: String = wortel(container)
	var wereld: bool = w != INVENTARIS
	if (wereld and (w != kamer or not bereikbaar_in(container, kamer) or not open.has(container))) \
			or not (heeft(item) or (wortel(item) == kamer and bereikbaar_in(item, kamer))):
		cue_gevraagd.emit("ui.weiger", {})
		return {"ok": false, "reden": "onbereikbaar"}
	_zet(item, container)
	cue_gevraagd.emit(_cue(item, "leg", "object.in_container"), {})
	return {"ok": true}


## Openen (T17/OI-11). Met `open_vereist` alleen als de conditie klopt; eenmaal open blijft hij open.
func open_container(item: String, ctx: ConditieContext) -> Dictionary:
	if not is_container(item):
		return {"ok": false, "reden": "geen_container"}
	if open.has(item):
		return {"ok": true, "al_open": true}
	var cont: Dictionary = content.items[item]["container"]
	if not Condities.evalueer(cont.get("open_vereist"), ctx):
		var sleutel: String = cont.get("geweigerd", "systeem.container.dicht")
		mompel_gevraagd.emit(sleutel, {})
		cue_gevraagd.emit("ui.weiger", {})
		return {"ok": false, "reden": "geweigerd", "tekst": sleutel}
	open[item] = true
	container_geopend.emit(item)
	cue_gevraagd.emit(_cue(item, "open", "container.open"), {})
	return {"ok": true}


## Een object komt in de inventaris (geef_object). Past het niet: op de vloer bij vak `tegel` en mompelen.
func geef(item: String, kamer: String, tegel: Vector2i, geblokkeerd: Array = []) -> Dictionary:
	if plek.get(item, NERGENS) == INVENTARIS or not content.items.has(item):
		return {"ok": plek.get(item) == INVENTARIS}
	var bestemming: String = _inventaris_plek(item) if is_pakbaar(item) else ""
	if bestemming != "":
		_zet(item, bestemming)
		cue_gevraagd.emit(_cue(item, "pak", "object.pak"), {})
		return {"ok": true, "bestemming": bestemming}
	mompel_gevraagd.emit("systeem.inventaris.vol", {})
	var vrij: Variant = vrije_tegel(kamer, tegel, geblokkeerd)
	_zet(item, kamer, vrij if vrij != null else tegel)
	return {"ok": true, "bestemming": kamer, "op_grond": true}


## Effect verplaats_object: geen capaciteitscontrole (de content weet wat ze doet).
func zet_plek(item: String, naar: String, pos: Variant = null) -> void:
	if content.items.has(item) and not in_deelboom(item, naar):
		_zet(item, naar, pos)


func verwijder(item: String) -> void:
	if plek.get(item, NERGENS) != NERGENS:
		_zet(item, NERGENS)
	open.erase(item)


func is_onmisbaar(item: String) -> bool:
	return content.is_onmisbaar(item, hoofdstuk)


## O9: eerste pakbare onmisbare object dat in een kamer ligt die in de nieuwe scène niet meer bestaat.
func blokkerend_voor_scene(nieuwe_kamers: Array) -> String:
	for item: String in plek:
		if not is_pakbaar(item) or not is_onmisbaar(item):
			continue
		var w: String = wortel(item)
		if is_kamer(w) and not nieuwe_kamers.has(w):
			return item
	return ""
