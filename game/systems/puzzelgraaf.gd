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


## Wis lopende tussenstand (na laden).
func wis() -> void:
	_net_actief.clear()
	_bezig = false


func in_aanmerking(k: Dictionary) -> bool:
	return not s.knopen.has(k["id"]) or k.get("herhaalbaar", false)


## Vuurt de eerste knoop met deze trigger waarvan `vereist` klopt (regel 2). Geen: bij_onvervuld (regel 3).
## Een knoop met een scènewissel die O9 weigert vuurt niet (producerbesluit; geldt voor elke trigger).
## Autosave wacht tot de buitenste actie klaar is (geen halve staat in de save).
## Resultaat: {"gevuurd": id|"", "mompel": sleutel|"", "geweigerd_door": object|"", "standaard": bool}
func trigger(t: Dictionary, _speler: bool = true) -> Dictionary:
	s.begin_actie()
	var r: Dictionary = _trigger(t)
	s.einde_actie()
	return r


func _trigger(t: Dictionary) -> Dictionary:
	var kandidaten: Array = []
	for k: Dictionary in s.content.actieve_knopen(s.hoofdstuk):
		if k["trigger"] == t and in_aanmerking(k):
			kandidaten.append(k)
	for k: Dictionary in kandidaten:
		if not Condities.evalueer(k.get("vereist"), s.ctx):
			continue
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
	s.effecten.voer_uit(k.get("effecten", []), k["id"])
	if not s.knopen.has(k["id"]):
		s.knopen[k["id"]] = true
		s.knopen_volgorde.append(k["id"])
	s.knoop_opgelost.emit(k["id"])


## Regel 4: automatische knopen, gebeurtenisstarts en -triggers tot er niets meer verandert (max 32 rondes).
func herzie() -> void:
	if _bezig:
		return
	_bezig = true
	s.begin_actie()
	var stabiel: bool = false
	for _ronde in range(MAX_RONDES):
		var veranderd: bool = false
		s.klok.herzie(s.ctx)
		while not _net_actief.is_empty():
			var e: String = _net_actief.pop_front()
			if _trigger({"gebeurtenis": e})["gevuurd"] != "":
				veranderd = true
		for k: Dictionary in s.content.actieve_knopen(s.hoofdstuk):
			if k["trigger"].has("automatisch") and in_aanmerking(k) and Condities.evalueer(k.get("vereist"), s.ctx) 					and _scene_blokkade(k) == "":
				vuur(k)
				veranderd = true
		if not veranderd:
			stabiel = true
			break
	_bezig = false
	if stabiel:
		_controleer_doel()
	else:
		s.log_fout("puzzelgraaf: meer dan %d rondes automatische knopen (kring?)" % MAX_RONDES)
	s.einde_actie()


func _controleer_doel() -> void:
	if s.voltooid or s.hoofdstuk == "":
		return
	var doel: Variant = s.content.hoofdstukken.get(s.hoofdstuk, {}).get("doel")
	if doel != null and Condities.evalueer(doel, s.ctx):
		s.voltooid = true
		s.hoofdstuk_voltooid.emit(s.hoofdstuk)
