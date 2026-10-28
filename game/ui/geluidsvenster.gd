class_name Geluidsvenster
extends CanvasLayer
## Het geluidsvenster (F2), alleen in ontwikkelbuilds: wat je nu had moeten horen. Vangt geen klikken op.

var audio: AudioCues
var _paneel: PanelContainer
var _tekst: RichTextLabel


## In een release-build bestaat het venster niet (AC-08): dan geeft dit null terug.
static func maak(a: AudioCues, ontwikkel: bool) -> Geluidsvenster:
	return Geluidsvenster.new(a) if ontwikkel else null


func _init(a: AudioCues) -> void:
	audio = a
	layer = 100
	visible = false
	_paneel = PanelContainer.new()
	_paneel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paneel.position = Vector2(8, 8)
	_paneel.custom_minimum_size = Vector2(560, 0)
	_paneel.modulate = Color(1, 1, 1, 0.82)
	_tekst = RichTextLabel.new()
	_tekst.bbcode_enabled = true
	_tekst.fit_content = true
	_tekst.scroll_active = false
	_tekst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paneel.add_child(_tekst)
	add_child(_paneel)
	audio.gewijzigd.connect(ververs)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		zet_zichtbaar(not visible)
		get_viewport().set_input_as_handled()


func zet_zichtbaar(aan: bool) -> void:
	visible = aan
	if aan:
		ververs()


func ververs() -> void:
	if visible:
		_tekst.text = bouw_tekst()


## Opgemaakte tekst (BBCode); los van de UI zodat tests hem kunnen lezen.
func bouw_tekst() -> String:
	var uit := PackedStringArray()
	uit.append("[b]Nu actief[/b]")
	for sleutel: String in audio.lagen:
		var l: Dictionary = audio.lagen[sleutel]
		var status: String = "fout" if l.get("status", "") == "fout" else audio.status_van(l["cue"])
		var beschrijving: String = audio.content.cues.get(l["cue"], {}).get("beschrijving", "")
		uit.append(_regel("%s  %s" % [sleutel, l["cue"]], status, beschrijving, l["context"]))
	uit.append("[b]Gebeurtenissen[/b]")
	for r: Dictionary in audio.recent:
		var teller: String = "  ×%d" % r["aantal"] if r["aantal"] > 1 else ""
		var tijd: String = "%02d:%02d" % [int(r["t"]) / 60, int(r["t"]) % 60]
		uit.append(_regel("%s  %s%s" % [tijd, r["cue"], teller], r["status"], "", r["context"]))
	uit.append("[b]Ruimte[/b]")
	uit.append("%s  galm %s  raamfilter %s" % [audio.ruimte["kamer"], audio.ruimte["galm"], "aan" if audio.ruimte["raamfilter"] else "uit"])
	return "\n".join(uit)


func _regel(kern: String, status: String, beschrijving: String, context: Dictionary) -> String:
	var kleur: String = AudioCues.kleur_voor(status).to_html(false)
	var extra: String = " " + AudioCues.context_tekst(context) if not context.is_empty() else ""
	var besch: String = "  [i]%s[/i]" % beschrijving.left(40) if beschrijving != "" else ""
	return "[color=#%s]%s%s[/color]%s" % [kleur, kern, extra, besch]
