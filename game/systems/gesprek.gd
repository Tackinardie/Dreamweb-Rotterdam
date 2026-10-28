class_name Gesprek
extends RefCounted
## Een lopend gesprek (dialogue.schema.json). Regels wijzigen zelf niets; het bereiken van een regel
## is de trigger {dialoog, regel} voor de puzzelgraaf. Tijdens een gesprek is opslaan geblokkeerd.

signal regel_bereikt(regel: Dictionary)
signal gesprek_afgelopen

var s: Spel
var dialoog: Dictionary = {}
var huidige: Dictionary = {}
var actief: bool = false


func _init(spel: Spel) -> void:
	s = spel


## Start het gesprek van een NPC (eerste gesprek waarvan `als` klopt). false = er is geen.
func start_met(npc: Dictionary) -> bool:
	var id: String = s.toegang.kies_gesprek(npc)
	return start(id) if id != "" else false


func start(dialoog_id: String) -> bool:
	if not s.content.dialogen.has(dialoog_id):
		return false
	dialoog = s.content.dialogen[dialoog_id]
	actief = true
	s.blokkades["gesprek"] = true
	var start_regel: String = ""
	if dialoog["start"] is String:
		start_regel = dialoog["start"]
	else:
		for x: Dictionary in dialoog["start"]:
			if Condities.evalueer(x.get("als"), s.ctx):
				start_regel = x["regel"]
				break
	_ga_naar(start_regel)
	return true


func keuzes() -> Array:
	var uit: Array = []
	for k: Dictionary in huidige.get("keuzes", []):
		var gedaan: bool = k.get("eenmalig", false) and s.dialoog_keuzes.has("%s.%s" % [dialoog["id"], k["id"]])
		if Condities.evalueer(k.get("als"), s.ctx) and not gedaan:
			uit.append(k)
	return uit


func kies(keuze_id: String) -> void:
	for k: Dictionary in keuzes():
		if k["id"] == keuze_id:
			if k.get("eenmalig", false):
				s.dialoog_keuzes["%s.%s" % [dialoog["id"], keuze_id]] = true
			if k.has("volgende"):
				_ga_naar(k["volgende"])
			else:
				_einde()
			return


func ga_door() -> void:
	if huidige.has("volgende"):
		_ga_naar(huidige["volgende"])
	elif huidige.get("einde", false):
		_einde()


func _ga_naar(regel_id: String) -> void:
	for r: Dictionary in dialoog["regels"]:
		if r["id"] == regel_id:
			huidige = r
			if r.has("cue"):
				s.audio.cue(r["cue"])
			regel_bereikt.emit(r)
			s.puzzel.trigger({"dialoog": dialoog["id"], "regel": regel_id}, false)
			return
	_einde()


func _einde() -> void:
	actief = false
	s.blokkades.erase("gesprek")
	gesprek_afgelopen.emit()
