class_name Effecten
extends RefCounted
## Voert de effecttaal uit (docs/systemen/state-en-flags.md). Toestandswijzigende effecten komen alleen
## uit de puzzelgraaf; deze klasse is de enige plek die ze toepast.

var s: Spel


func _init(spel: Spel) -> void:
	s = spel


func voer_uit(lijst: Array, bron: String = "", forceer_scene: bool = false) -> void:
	for e: Dictionary in lijst:
		if e.has("zet_flag"):
			s.zet_flag(e["zet_flag"], e.get("waarde", true))
		elif e.has("wis_flag"):
			s.wis_flag(e["wis_flag"])
		elif e.has("geef_token"):
			s.geef_token(e["geef_token"], bron)
		elif e.has("geef_object"):
			var blokkeer: Array = s.npcs_in_kamer(s.kamer).map(func(n: Dictionary) -> Vector2i: return Vector2i(n["positie"]["x"], n["positie"]["y"]))
			s.objecten.geef(e["geef_object"], s.kamer, s.positie, blokkeer)
		elif e.has("verplaats_object"):
			_verplaats(e["verplaats_object"])
		elif e.has("verwijder_object"):
			s.objecten.verwijder(e["verwijder_object"])
		elif e.has("start_gebeurtenis"):
			s.klok.start(e["start_gebeurtenis"])
		elif e.has("stop_gebeurtenis"):
			s.klok.stop(e["stop_gebeurtenis"])
		elif e.has("naar_scene"):
			s.naar_scene(e["naar_scene"], e.get("kamer", ""), e.get("uitgang", ""), forceer_scene)
		elif e.has("naar_kamer"):
			s.verplaats_speler(e["naar_kamer"], e.get("uitgang", ""))
		elif e.has("cue"):
			s.audio.cue(e["cue"])
		elif e.has("mompel"):
			s.mompel_zeg(e["mompel"])
		else:
			s.log_fout("onbekend effect: %s" % str(e))


func _verplaats(v: Dictionary) -> void:
	var naar: String = v["naar"]
	if naar == ObjectBoom.INVENTARIS:
		s.objecten.zet_plek(v["object"], ObjectBoom.INVENTARIS)
		return
	var pos: Variant = null
	if s.content.kamers.has(naar):
		var p: Dictionary = v.get("positie", s.content.kamers[naar].get("start_positie", {"x": 1, "y": 1}))
		pos = Vector2i(p["x"], p["y"])
	s.objecten.zet_plek(v["object"], naar, pos)
