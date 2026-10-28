class_name KamerRaster
extends RefCounted
## Beloopbaarheid en padzoeken over de vakken van een kamer (kamerweergave.md, W13-W15). Zuiver: geen Node3D.
## Beloopbaar = binnen de afmeting, niet geblokkeerd, geen niet-pakbaar object, geen aanwezige NPC.

var breedte: int = 0
var hoogte: int = 0
var geblokkeerd: Dictionary = {}    # Vector2i -> true (uit de kamerdata)
var obstakels: Dictionary = {}      # Vector2i -> true (niet-pakbare objecten, NPC's)
var _astar: AStarGrid2D = null


static func uit_kamer(kamer: Dictionary) -> KamerRaster:
	var r := KamerRaster.new()
	r.breedte = int(kamer.get("afmeting", {}).get("breedte", 0))
	r.hoogte = int(kamer.get("afmeting", {}).get("hoogte", 0))
	for g: Dictionary in kamer.get("geblokkeerd", []):
		for v in Vak.gebied_vakken(g):
			r.geblokkeerd[v] = true
	r.zet_obstakels([])
	return r


## Vakken van niet-pakbare objecten en aanwezige NPC's in een kamer (W13).
static func obstakels_van(kamer_id: String, content: ContentDb, objecten: ObjectBoom, npcs: Array) -> Array[Vector2i]:
	var uit: Array[Vector2i] = []
	for item: String in objecten.kamer_objecten(kamer_id):
		if objecten.positie.has(item) and not objecten.is_pakbaar(item):
			uit.append(objecten.positie[item])
	for n: Dictionary in npcs:
		uit.append(Vak.uit_positie(n["positie"]))
	return uit


func zet_obstakels(vakken: Array) -> void:
	obstakels.clear()
	for v: Vector2i in vakken:
		obstakels[v] = true
	_astar = AStarGrid2D.new()
	_astar.region = Rect2i(0, 0, maxi(breedte, 1), maxi(hoogte, 1))
	_astar.cell_size = Vector2.ONE
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.update()
	for y in range(hoogte):
		for x in range(breedte):
			if not beloopbaar(Vector2i(x, y)):
				_astar.set_point_solid(Vector2i(x, y), true)


func beloopbaar(v: Vector2i) -> bool:
	return Vak.in_kamer(v, breedte, hoogte) and not geblokkeerd.has(v) and not obstakels.has(v)


## Alle geblokkeerde vakken uit de kamerdata (voor O8: neerleggen).
func geblokkeerde_vakken() -> Array[Vector2i]:
	var uit: Array[Vector2i] = []
	for v: Vector2i in geblokkeerd:
		uit.append(v)
	return uit


## Pad van `van` naar `naar`, beide inbegrepen; leeg als er geen is. 8 richtingen, geen hoeken afsnijden (W14).
func pad(van: Vector2i, naar: Vector2i) -> Array[Vector2i]:
	var uit: Array[Vector2i] = []
	if not beloopbaar(naar) or not Vak.in_kamer(van, breedte, hoogte):
		return uit
	var start_vast: bool = _astar.is_point_solid(van)
	if start_vast:
		_astar.set_point_solid(van, false)
	for p: Vector2i in _astar.get_id_path(van, naar):
		uit.append(p)
	if start_vast:
		_astar.set_point_solid(van, true)
	return uit


## Aantal stappen (8 richtingen, geen hoeken afsnijden) naar elk vak dat vanaf `van` bereikbaar is.
func bereikbaar(van: Vector2i) -> Dictionary:
	var afstand: Dictionary = {van: 0}
	var rij: Array[Vector2i] = [van]
	var i: int = 0
	while i < rij.size():
		var v: Vector2i = rij[i]
		i += 1
		for d in Vak.ACHT:
			var w: Vector2i = v + d
			if afstand.has(w) or not beloopbaar(w):
				continue
			if d.x != 0 and d.y != 0 and not (beloopbaar(v + Vector2i(d.x, 0)) and beloopbaar(v + Vector2i(0, d.y))):
				continue
			afstand[w] = afstand[v] + 1
			rij.append(w)
	return afstand


## Waar loopt Richard heen bij een klik op `klik` (W15)? `ding` = er staat een object, uitgang of NPC.
## Resultaat: {"vak": Vector2i, "pad": Array[Vector2i], "dichtbij": bool} (vak == van als er niets te doen is;
## dichtbij = het eindvak is het doel zelf of een van de 8 buren).
func loop_doel(van: Vector2i, klik: Vector2i, ding: bool) -> Dictionary:
	var leeg: Dictionary = {"vak": van, "pad": [] as Array[Vector2i], "dichtbij": false}
	if not Vak.in_kamer(klik, breedte, hoogte):
		return leeg
	var bereik: Dictionary = bereikbaar(van) if beloopbaar(van) else {van: 0}
	var kandidaten: Array[Vector2i] = []
	if ding:
		kandidaten.append(klik)
		for d in Vak.ACHT:
			kandidaten.append(klik + d)
	elif beloopbaar(klik):
		kandidaten.append(klik)
	var beste: Variant = null
	var beste_afstand: int = 1 << 30
	for c in kandidaten:
		if beloopbaar(c) and bereik.has(c) and bereik[c] < beste_afstand:
			beste = c
			beste_afstand = bereik[c]
	var dichtbij: bool = beste != null
	if beste == null:    # geen beloopbaar doelvak: het bereikbare vak het dichtst bij de klik
		var beste_d2: int = 1 << 30
		for v: Vector2i in bereik:
			var d2: int = (v - klik).length_squared()
			if d2 < beste_d2 or (d2 == beste_d2 and bereik[v] < bereik.get(beste, 1 << 30)):
				beste = v
				beste_d2 = d2
	if beste == null:
		return leeg
	var p: Array[Vector2i] = pad(van, beste) if beste != van else ([van] as Array[Vector2i])
	return {"vak": beste, "pad": p, "dichtbij": dichtbij}


## Het beloopbare vak dat het dichtst bij `v` ligt (euclidisch), of `v` zelf als dat beloopbaar is; null als er geen is.
func dichtstbij_beloopbaar(v: Vector2i) -> Variant:
	var beste: Variant = null
	var beste_d2: int = 1 << 30
	for y in range(hoogte):
		for x in range(breedte):
			var c := Vector2i(x, y)
			if beloopbaar(c) and (c - v).length_squared() < beste_d2:
				beste = c
				beste_d2 = (c - v).length_squared()
	return beste
