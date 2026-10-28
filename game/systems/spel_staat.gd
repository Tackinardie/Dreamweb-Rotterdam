class_name SpelStaat
extends Node
## De velden en signalen van de spelstaat (docs/systemen/state-en-flags.md). Zie Spel voor het gedrag.

signal kamer_gewisseld(van: String, naar: String)
signal scene_gewisseld(van: String, naar: String, richting: String)
signal token_gegeven(id: String)
signal notitie_genoteerd(tekst: String)
signal knoop_opgelost(id: String)
signal hoofdstuk_voltooid(id: String)
signal mompel(tekst: String, sleutel: String)
signal autosave_geschreven
signal nieuw_spel_gestart

var content: ContentDb
var objecten: ObjectBoom
var klok: Klok
var audio: AudioCues
var puzzel: Puzzelgraaf
var toegang: Toegang
var effecten: Effecten
var opslag: Opslaan
var acties: Acties
var ctx: SpelContext

var flags: Dictionary = {}
var tokens: Dictionary = {}              # id -> {id, verkregen_op, bron_knoop, nieuw}
var token_volgorde: Array = []
var knopen: Dictionary = {}              # opgeloste knoop-ids
var knopen_volgorde: Array = []
var apparaten: Dictionary = {}           # id -> "vergrendeld" | "ontgrendeld"
var dialoog_keuzes: Dictionary = {}      # "dialoog.keuze" -> true
var hints: Dictionary = {}               # knoop -> niveau
var systemen: Dictionary = {}            # onbekende latere systemen blijven bewaard
var hoofdstuk: String = ""
var kamer: String = ""
var positie: Vector2i = Vector2i.ZERO
var blokkades: Dictionary = {}           # gesprek, closeup, titelkaart, droom, scenewissel
var gepauzeerd: bool = false
var auto_tik: bool = false
var voltooid: bool = false
var speeltijd_s: float = 0.0
var fout_log: PackedStringArray = PackedStringArray()
