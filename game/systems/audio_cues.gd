class_name AudioCues
extends Node
## Audiolaag (docs/systemen/audio-cues-en-geluidsvenster.md). Zolang er geen geluid is, speelt dit niets af
## maar houdt het alles bij: lopende lagen, recente cues en een logboek (alleen in ontwikkelbuilds).

signal gewijzigd
signal fout_gemeld(tekst: String)

const MAX_RECENT: int = 30
const GROEP_SECONDEN: float = 1.0

const KLEUREN: Dictionary = {
	"verwacht": Color(0.62, 0.62, 0.62),
	"placeholder": Color(0.95, 0.82, 0.25),
	"klaar": Color(0.35, 0.8, 0.4),
	"onbekend": Color(0.9, 0.25, 0.25),
	"fout": Color(0.9, 0.25, 0.25),
}

var content: ContentDb
## Ontwikkelbuild: logboek bijhouden. In een release-build gebeurt er niets (AC-08).
var ontwikkel: bool = false
## Callable() -> Dictionary met "t" (speeltijd), "kamer", "scene". Zo kent de audiolaag de spelstaat niet.
var context_leverancier: Callable = Callable()
var logboek_pad: String = ""
var lagen: Dictionary = {}        # sleutel -> {"cue", "context"}
var recent: Array = []            # nieuwste eerst: {"t", "cue", "context", "status", "aantal"}
var logboek: Array = []           # alle aanroepen (dicts)
var fout_log: PackedStringArray = PackedStringArray()
var ruimte: Dictionary = {"kamer": "", "galm": "", "raamfilter": false}
var _bestand: FileAccess = null


func _init(c: ContentDb = null) -> void:
	content = c
	ontwikkel = Ontwikkel.actief()


func reset() -> void:
	lagen.clear()
	recent.clear()
	logboek.clear()
	ruimte = {"kamer": "", "galm": "", "raamfilter": false}
	gewijzigd.emit()


# ---------------------------------------------------------------- aanroepen (A3)

func cue(id: String, context: Dictionary = {}) -> void:
	var status: String = status_van(id)
	if status == "onbekend":
		_fout("cue '%s' staat niet in de catalogus" % id)
	elif content.cues[id]["soort"] != "eenmalig":
		_fout("cue() met doorlopende cue '%s'; gebruik start_laag()" % id)
		status = "fout"
	_noteer("cue", id, "", context, status)
	_recent(id, context, status)
	gewijzigd.emit()


func start_laag(id: String, sleutel: String, context: Dictionary = {}) -> void:
	if lagen.has(sleutel) and lagen[sleutel]["cue"] == id:
		return
	var status: String = status_van(id)
	if status == "onbekend":
		_fout("cue '%s' staat niet in de catalogus" % id)
	elif content.cues[id]["soort"] != "doorlopend":
		_fout("start_laag() met eenmalige cue '%s'; gebruik cue()" % id)
		status = "fout"
	lagen[sleutel] = {"cue": id, "context": context, "status": status}
	_noteer("start", id, sleutel, context, status)
	gewijzigd.emit()


func stop_laag(sleutel: String) -> void:
	if not lagen.has(sleutel):
		return
	var id: String = lagen[sleutel]["cue"]
	lagen.erase(sleutel)
	_noteer("stop", id, sleutel, {}, status_van(id))
	gewijzigd.emit()


func zet_ruimte(galm: String, raamfilter: bool = false) -> void:
	ruimte["galm"] = galm
	ruimte["raamfilter"] = raamfilter
	gewijzigd.emit()


## Stopt alle lagen waarvan de sleutel met `voorvoegsel` begint (kamerwissel: ambience. en npc.).
func stop_lagen_met(voorvoegsel: String) -> void:
	for sleutel: String in lagen.keys():
		if sleutel.begins_with(voorvoegsel):
			stop_laag(sleutel)


# ---------------------------------------------------------------- status en weergave

## "verwacht", "placeholder", "klaar" of "onbekend".
func status_van(id: String) -> String:
	if content == null or not content.cues.has(id):
		return "onbekend"
	return content.cues[id].get("status", "verwacht")


static func kleur_voor(status: String) -> Color:
	return KLEUREN.get(status, KLEUREN["onbekend"])


## Context in Nederlandse notatie: {"nat": 0.7} -> "(nat 0,7)".
static func context_tekst(context: Dictionary) -> String:
	if context.is_empty():
		return ""
	var delen := PackedStringArray()
	for k: String in context:
		var v: Variant = context[k]
		delen.append("%s %s" % [k, str(v).replace(".", ",")])
	return "(" + ", ".join(delen) + ")"


# ---------------------------------------------------------------- intern

func _fout(tekst: String) -> void:
	fout_log.append(tekst)
	printerr("audio: " + tekst)
	fout_gemeld.emit(tekst)


func _nu() -> Dictionary:
	if context_leverancier.is_valid():
		return context_leverancier.call()
	return {"t": 0.0, "kamer": "", "scene": ""}


func _recent(id: String, context: Dictionary, status: String) -> void:
	var nu: Dictionary = _nu()
	if not recent.is_empty():
		var laatste: Dictionary = recent[0]
		if laatste["cue"] == id and laatste["context"] == context and float(nu["t"]) - float(laatste["t"]) <= GROEP_SECONDEN:
			laatste["aantal"] += 1
			return
	recent.push_front({"t": nu["t"], "cue": id, "context": context, "status": status, "aantal": 1})
	while recent.size() > MAX_RECENT:
		recent.pop_back()


func _noteer(soort: String, id: String, sleutel: String, context: Dictionary, status: String) -> void:
	if not ontwikkel:
		return
	var nu: Dictionary = _nu()
	var regel: Dictionary = {
		"t": snappedf(float(nu["t"]), 0.1), "soort": soort, "cue": id, "sleutel": sleutel if sleutel != "" else null,
		"context": context, "kamer": nu["kamer"], "scene": nu["scene"], "status": status,
	}
	logboek.append(regel)
	if logboek_pad == "":
		return
	if _bestand == null:
		DirAccess.make_dir_recursive_absolute(logboek_pad.get_base_dir())
		_bestand = FileAccess.open(logboek_pad, FileAccess.WRITE)
	if _bestand != null:
		_bestand.store_line(JSON.stringify(regel))
		_bestand.flush()


## Start een logboekbestand voor deze sessie (user://logs/cues/<tijdstempel>.jsonl).
func start_logboek() -> void:
	if ontwikkel:
		logboek_pad = "user://logs/cues/%s.jsonl" % Ontwikkel.tijdstempel()


func sluit_logboek() -> void:
	_bestand = null
