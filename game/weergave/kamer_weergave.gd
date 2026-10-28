class_name KamerWeergave
extends KamerWeergaveBasis
## De kamer als verlicht 3D-eiland met een vaste camera (docs/systemen/kamerweergave.md): bovenop de basis de
## hover, spatiebalk, vergrootglas, 3D-close-up en kamerwissel met fade of droomfilter.


func start(s: Spel, begin_stand: String = Kwaliteit.VOL, auto: bool = true) -> void:
	super.start(s, begin_stand, auto)
	var invoer := KamerInvoer.new()
	invoer.weergave = self
	add_child(invoer)
	spel.kamer_gewisseld.connect(_kamer_gewisseld)
	overgang.klaar.connect(_overgang_klaar)


func klik_scherm(pos: Vector2) -> void:
	if staat == "closeup":
		sluit_closeup()
		return
	var p: Dictionary = pik_scherm(pos)
	if not p.is_empty():
		klik_ding(p["id"])
	else:
		var v: Variant = vloer_vak_scherm(pos)
		if v != null:
			klik_vak(v)


# ---------------------------------------------------------------- hover, spatiebalk, vergrootglas (W16-W18)

func naam_van(p: Dictionary) -> String:
	match p["soort"]:
		"object": return spel.tekst(spel.content.items[p["id"]]["naam"])
		"uitgang": return spel.tekst(spel.toegang.uitgang(root.kamer_id, p["id"]).get("naam", p["id"]))
		_: return p["id"]


func hover_op(p: Dictionary) -> void:
	if staat != "spelen":
		p = {}
	if p.get("id", "") == hover.get("id", "") and p.get("soort", "") == hover.get("soort", ""):
		return
	if not hover.is_empty() and not spatie and is_instance_valid(hover["node"]):
		Contour.zet(hover["node"], false)
	hover = p
	_hover_tijd = 0.0
	glas.verberg()
	if not p.is_empty():
		Contour.zet(p["node"], true)
	ui.toon_naam(naam_van(p) if not p.is_empty() else "", muis)


func zet_spatie(aan: bool) -> void:
	if aan == spatie or (aan and staat != "spelen"):
		return
	spatie = aan
	if aan:
		spel.audio.cue("ui.highlight")
	for p in root.pickbaar:
		Contour.zet(p["node"], aan or p == hover)


# ---------------------------------------------------------------- close-up (W19)

func rechtsklik_scherm(pos: Vector2) -> void:
	if staat == "closeup":
		sluit_closeup()
	else:
		var p: Dictionary = pik_scherm(pos)
		if not p.is_empty():
			bekijk_ding(p["id"])


func bekijk_ding(id: String) -> void:
	var p: Dictionary = root.ding(id)
	if staat != "spelen" or p.is_empty() or p["soort"] != "object":
		return
	var item: Dictionary = spel.content.items[id]
	var r: Dictionary = spel.acties.bekijk(id)
	if not r.get("ok", false):
		return
	if item.has("closeup"):
		hover_op({})
		var afstand: float = float(item["closeup"].get("afstand", Closeup.STANDAARD_AFSTAND))
		closeup.start(id, camera.global_transform, camera.fov, root.aabb_van(p["node"]).get_center(), afstand)
		closeup_camera.transform = closeup.huidige_transform()
		closeup_camera.fov = closeup.huidige_fov()
		closeup_camera.current = true
		spel.blokkades["closeup"] = true
		staat = "closeup"
		spel.audio.cue("ui.closeup.open")
	ui.toon_tekst(spel.tekst(r["tekst"]))


func sluit_closeup() -> void:
	if staat == "closeup" and not closeup.sluitend:
		closeup.sluit()
		spel.audio.cue("ui.closeup.sluit")


# ---------------------------------------------------------------- kamerwissel (W20-W21)

func _kamer_gewisseld(_van: String, naar: String) -> void:
	var droom: bool = spel.content.kamers.get(naar, {}).get("soort", "") == "droom"
	if closeup.open:
		closeup.open = false
		camera.current = true
		spel.blokkades.erase("closeup")
	if droom:
		spel.audio.cue("droom.overgang")
		spel.zet_pauze(true)
		spel.blokkades["droom"] = true
	staat = "overgang"
	hover_op({})
	voorlader.vraag_kamer(spel.content, naar)
	overgang.start(droom, _wissel)


func _wissel() -> bool:
	if not voorlader.klaar():
		return false
	bouw_kamer(spel.kamer)
	staat = "overgang"
	return true


func _overgang_klaar() -> void:
	staat = "spelen"
	if overgang.droom:
		spel.zet_pauze(false)
		spel.blokkades.erase("droom")
