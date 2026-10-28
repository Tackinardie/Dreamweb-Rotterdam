class_name Puzzelgraaf
extends RefCounted
## De puzzelgraaf (docs/systemen/state-en-flags.md, "Vuurregels"): triggers laten knopen vuren.

const MAX_RONDES: int = 32

var s: Spel
var _net_actief: Array[String] = []
var _bezig: bool = false


func _init(spel: Spel) -> void:
	s = spel


## Verbonden met Klok.gebeurtenis_gewijzigd.
func gebeurtenis_gewijzigd(id: String, status: String) -> void:
	if status == "actief":
		_net_actief.append(id)


func in_aanmerking(k: Dictionary) -> bool:
	return not s.knopen.has(k["id"]) or k.get("herhaalbaar", false)


## Vuurt de eerste knoop met deze trigger waarvan `vereist` klopt (regel 2). Geen: bij_onvervuld (regel 3).
## Resultaat: {"gevuurd": id|"", "mompel": sleutel|"", "geweigerd_door": object|"", "standaard": bool}
func trigger(t: Dictionary, speler: bool = true) -> Dictionary:
	var kandidaten: Array = []
	for k: Dictionary in s.content.alle_knopen:
		if k["trigger"] == t and in_aanmerking(k):
			kandidaten.append(k)
	for k: Dictionary in kandidaten:
		if not Condities.evalueer(k.get("vereist"), s.ctx):
			continue
		if speler:
			var blok: String = _scene_blokkade(k)
			if blok != "":
				s.mompel_zeg("systeem.niet_zonder", {"object": s.tekst(s.content.items[blok]["naam"])})
				s.audio.cue("ui.weiger")
				return {"gevuurd": "", "mompel": "systeem.niet_zonder", "geweigerd_door": blok, "standaard": false}
		vuur(k)
		herzie()
		return {"gevuurd": k["id"], "mompel": "", "geweigerd_door": "", "standaard": false}
	if not kandidaten.is_empty() and (kandidaten[0] as Dictionary).has("bij_onvervuld"):
		s.mompel_zeg(kandidaten[0]["bij_onvervuld"])
		return {"gevuurd": "", "mompel": kandidaten[0]["bij_onvervuld"], "geweigerd_door": "", "standaard": false}
	return {"gevuurd": "", "mompel": "", "geweigerd_door": "", "standaard": true}


func _scene_blokkade(k: Dictionary) -> String:
	for e: Dictionary in k.get("effecten", []):
		if e.has("naar_scene") and s.content.scenes.has(e["naar_scene"]):
			var blok: String = s.objecten.blokkerend_voor_scene(s.content.scenes[e["naar_scene"]]["kamers"])
			if blok != "":
				return blok
	return ""


func vuur(k: Dictionary) -> void:
	# Automatische en gebeurtenisknopen kunnen niet geweigerd worden (V17 bewaakt dat ze niets achterlaten).
	var geforceerd: bool = k["trigger"].has("gebeurtenis") or k["trigger"].has("automatisch")
	s.effecten.voer_uit(k.get("effecten", []), k["id"], geforceerd)
	if not s.knopen.has(k["id"]):
		s.knopen[k["id"]] = true
		s.knopen_volgorde.append(k["id"])
	s.knoop_opgelost.emit(k["id"])


## Regel 4: automatische knopen, gebeurtenisstarts en -triggers tot er niets meer verandert (max 32 rondes).
func herzie() -> void:
	if _bezig:
		return
	_bezig = true
	for _ronde in range(MAX_RONDES):
		var veranderd: bool = false
		s.klok.herzie(s.ctx)
		while not _net_actief.is_empty():
			var e: String = _net_actief.pop_front()
			if trigger({"gebeurtenis": e}, false)["gevuurd"] != "":
				veranderd = true
		for k: Dictionary in s.content.alle_knopen:
			if k["trigger"].has("automatisch") and in_aanmerking(k) and Condities.evalueer(k.get("vereist"), s.ctx):
				vuur(k)
				veranderd = true
		if not veranderd:
			_bezig = false
			_controleer_doel()
			return
	_bezig = false
	s.log_fout("puzzelgraaf: meer dan %d rondes automatische knopen (kring?)" % MAX_RONDES)


func _controleer_doel() -> void:
	if s.voltooid or s.hoofdstuk == "":
		return
	var doel: Variant = s.content.hoofdstukken.get(s.hoofdstuk, {}).get("doel")
	if doel != null and Condities.evalueer(doel, s.ctx):
		s.voltooid = true
		s.hoofdstuk_voltooid.emit(s.hoofdstuk)
