class_name KamerWeergaveBasis
extends Node3D
## Basis van de kamerweergave: opbouw, tijd, lopen en klikken. De rest (hover, spatiebalk, close-up, kamerwissel)
## staat in KamerWeergave.
## De kamer als verlicht 3D-eiland met een vaste camera (docs/systemen/kamerweergave.md). Bouwt de scène uit het
## kamerbestand (KamerBouwer), laat Richard over de vakken lopen en stuurt klikken door naar de bestaande
## systemen (Spel.acties, Spel.toegang). Alle tijd loopt via `tik(dt)`; tests tikken zelf.

signal actie_uitgevoerd(id: String, actie: String)
signal gesprek_gevraagd(dialoog: String, npc: String)
signal kamer_gebouwd(kamer_id: String)

const HOVER_WACHT_S: float = 0.3
const KAMER_MASKER: int = KamerRoot.LAAG_NORMAAL | KamerRoot.LAAG_GEWOON
const CLOSEUP_MASKER: int = KamerRoot.LAAG_NORMAAL | KamerRoot.LAAG_DETAIL

var spel: Spel = null
var stand: String = Kwaliteit.VOL
var bewaarpad: String = Kwaliteit.BEWAARPAD
var staat: String = "opbouwen"         # opbouwen | spelen | closeup | overgang
var root: KamerRoot = null
var camera: Camera3D = null
var closeup_camera: Camera3D = null
var closeup: Closeup = Closeup.new()
var loper: Loper = Loper.new()
var overgang: Overgang = null
var glas: Vergrootglas = null
var ui: WeergaveUi = null
var voorlader: Voorlader = Voorlader.new()
var spatie: bool = false
var hover: Dictionary = {}
var muis: Vector2 = Vector2.ZERO
var _hover_tijd: float = 0.0
var _doel: Dictionary = {}


func start(s: Spel, begin_stand: String = Kwaliteit.VOL, auto: bool = true) -> void:
	spel = s
	stand = begin_stand
	camera = _camera("kamercamera")
	closeup_camera = _camera("closeup_camera")
	closeup_camera.near = 0.05
	closeup_camera.far = 60.0
	closeup_camera.cull_mask = CLOSEUP_MASKER
	ui = WeergaveUi.new()
	add_child(ui)
	glas = Vergrootglas.new()
	add_child(glas)
	glas.koppel(get_world_3d())
	overgang = Overgang.new()
	add_child(overgang)
	spel.mompel.connect(func(t: String, _sleutel: String) -> void: ui.toon_tekst(t))
	spel.objecten.object_verplaatst.connect(func(_i: String, _v: String, _n: String) -> void: _objecten_veranderd())
	loper.vak_bereikt.connect(func(v: Vector2i) -> void: spel.positie = v)
	loper.aangekomen.connect(_aangekomen)
	set_process(auto)
	bouw_kamer(spel.kamer)
	camera.current = true


func _camera(naam: String) -> Camera3D:
	var c := Camera3D.new()
	c.name = naam
	c.projection = Camera3D.PROJECTION_PERSPECTIVE
	c.keep_aspect = Camera3D.KEEP_HEIGHT
	c.cull_mask = KAMER_MASKER
	add_child(c)
	return c


func _process(dt: float) -> void:
	tik(dt)


# ---------------------------------------------------------------- opbouw

func bouw_kamer(kamer_id: String) -> void:
	staat = "opbouwen"
	if root != null:
		remove_child(root)
		root.free()
	hover = {}
	_doel = {}
	root = KamerBouwer.bouw(spel, kamer_id)
	add_child(root)
	var st: Dictionary = root.stand
	camera.fov = st["fov"]
	camera.near = st["near"]
	camera.far = st["far"]
	camera.transform = st["transform"]
	KwaliteitToepassen.alles(stand, get_viewport(), root)
	KwaliteitToepassen.op_viewport(stand, glas.viewport)
	glas.verberg()
	zet_richard(spel.positie)
	staat = "spelen"
	voorlader.vraag_buren(spel.content, kamer_id)
	kamer_gebouwd.emit(kamer_id)


## Richard op een vak; staat dat niet vrij, dan op het dichtstbijzijnde beloopbare vak (edge case, V32).
func zet_richard(v: Vector2i) -> void:
	if not root.raster.beloopbaar(v):
		var dichtbij: Variant = root.raster.dichtstbij_beloopbaar(v)
		spel.log_fout("start of uitgang %s in kamer '%s' is niet beloopbaar" % [v, root.kamer_id])
		if dichtbij != null:
			v = dichtbij
	spel.positie = v
	loper.zet(v)
	root.richard.position = loper.positie


func zet_stand(nieuw: String, bewaar: bool = true) -> void:
	stand = nieuw
	KwaliteitToepassen.alles(stand, get_viewport(), root)
	KwaliteitToepassen.op_viewport(stand, glas.viewport)
	if bewaar:
		Kwaliteit.bewaar(stand, bewaarpad)


func _objecten_veranderd() -> void:
	if root == null or staat == "opbouwen":
		return
	if not hover.is_empty() and not is_instance_valid(hover["node"]):
		hover = {}
	KamerBouwer.zet_objecten(root, spel)
	KamerBouwer.obstakels_bijwerken(root, spel)
	if spatie:
		for p in root.pickbaar:
			Contour.zet(p["node"], true)


# ---------------------------------------------------------------- tijd

func tik(dt: float) -> void:
	overgang.tik(dt)
	if staat == "spelen":
		loper.tik(dt)
		root.richard.position = loper.positie
		if loper.bezig:
			root.richard.rotation.y = atan2(loper.richting.x, loper.richting.z)
		if not hover.is_empty() and not glas.zichtbaar:
			_hover_tijd += dt
			if _hover_tijd >= HOVER_WACHT_S:
				glas.toon(root.aabb_van(hover["node"]).get_center(), camera, root.stand["afstand"], KAMER_MASKER)
	elif staat == "closeup":
		var klaar: bool = closeup.tik(dt)
		closeup_camera.transform = closeup.huidige_transform()
		closeup_camera.fov = closeup.huidige_fov()
		if klaar:
			camera.current = true
			spel.blokkades.erase("closeup")
			staat = "spelen"
			ui.wis_tekst()
	ui.tik(dt, staat == "closeup")


# ---------------------------------------------------------------- klikken en lopen (W15)

func pik_scherm(pos: Vector2) -> Dictionary:
	if staat != "spelen":
		return {}
	return root.pik(camera.project_ray_origin(pos), camera.project_ray_normal(pos))


func vloer_vak_scherm(pos: Vector2) -> Variant:
	var p: Variant = Vak.vloer_snijpunt(camera.project_ray_origin(pos), camera.project_ray_normal(pos))
	return Vak.uit_3d(p, root.breedte, root.hoogte) if p != null else null


func klik_ding(id: String) -> void:
	var p: Dictionary = root.ding(id)
	if not p.is_empty():
		klik_vak(vak_van(p), p)


func vak_van(p: Dictionary) -> Vector2i:
	if p["soort"] == "object" and spel.objecten.positie.has(p["id"]):
		return spel.objecten.positie[p["id"]]
	return Vak.uit_3d((p["node"] as Node3D).position)


## Klik op een vak (met `doel` = het pickbare ding erop, of leeg).
func klik_vak(v: Vector2i, doel: Dictionary = {}) -> void:
	if staat != "spelen" or spel.blokkades.has("gesprek") or spel.blokkades.has("titelkaart"):
		return
	var ding: bool = not doel.is_empty()
	var van: Vector2i = loper.eerstvolgend_vak() if loper.bezig else loper.vak
	var r: Dictionary = root.raster.loop_doel(van, v, ding)
	_doel = doel if ding and r["dichtbij"] else {}
	var pad: Array[Vector2i] = r["pad"]
	if pad.is_empty():
		return
	if loper.bezig:
		loper.vervang(pad)
	else:
		loper.start(pad)


func _aangekomen() -> void:
	spel.positie = loper.vak
	if _doel.is_empty():
		return
	var d: Dictionary = _doel
	_doel = {}
	var eind: Vector2i = vak_van(d)
	if absi(eind.x - loper.vak.x) > 1 or absi(eind.y - loper.vak.y) > 1:
		return
	match d["soort"]:
		"object":
			var actie: String = Interactie.standaard_actie(spel.content.items[d["id"]])
			var r: Dictionary = Interactie.voer_uit(spel, d["id"], actie)
			actie_uitgevoerd.emit(d["id"], actie)
			if r.get("tekst", "") != "":
				ui.toon_tekst(spel.tekst(r["tekst"]))
		"uitgang":
			_door_uitgang(d["id"])
		"npc":
			for n: Dictionary in spel.npcs_in_kamer(root.kamer_id):
				if n["id"] == d["id"]:
					gesprek_gevraagd.emit(spel.toegang.kies_gesprek(n), d["id"])


func _door_uitgang(id: String) -> void:
	var r: Dictionary = spel.toegang.doorgang(root.kamer_id, id)
	if r.get("paneel", false):
		for knop: Dictionary in r["knoppen"]:      # nog geen liftpaneel: de eerste bestemming die open is
			if not knop["gedimd"]:
				spel.toegang.kies_bestemming(root.kamer_id, id, knop["index"])
				return
		spel.audio.cue("lift.geweigerd")
