class_name KamerInvoer
extends Node
## Muis en toetsen voor de kamerweergave: linksklik loopt, rechtsklik bekijkt, spatie toont alles,
## Esc sluit de close-up, F3 (meetoverlay) en F4 (standwissel) alleen in ontwikkelbuilds.

var weergave: KamerWeergave = null
var meetoverlay: Meetoverlay = null


func _unhandled_input(ev: InputEvent) -> void:
	if weergave == null or weergave.staat == "opbouwen":
		return
	if ev is InputEventMouseMotion:
		weergave.muis = (ev as InputEventMouseMotion).position
		weergave.hover_op(weergave.pik_scherm(weergave.muis))
		weergave.ui.toon_naam(weergave.ui.naam.text, weergave.muis)
	elif ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			weergave.klik_scherm(mb.position)
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			weergave.rechtsklik_scherm(mb.position)
	elif ev is InputEventKey and not (ev as InputEventKey).echo:
		var k := ev as InputEventKey
		match k.keycode:
			KEY_SPACE:
				weergave.zet_spatie(k.pressed)
			KEY_ESCAPE:
				if k.pressed:
					weergave.sluit_closeup()
			KEY_F3:
				if k.pressed and Ontwikkel.actief():
					_meetoverlay().wissel()
			KEY_F4:
				if k.pressed and Ontwikkel.actief():
					weergave.zet_stand(Kwaliteit.andere(weergave.stand))


func _meetoverlay() -> Meetoverlay:
	if meetoverlay == null:
		meetoverlay = Meetoverlay.new()
		meetoverlay.weergave = weergave
		weergave.add_child(meetoverlay)
	return meetoverlay
