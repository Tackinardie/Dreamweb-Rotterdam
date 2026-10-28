extends Node
## Lege, draaiende hoofdscene: laadt de content, start een nieuw spel als er content is, en toont in
## ontwikkelbuilds het geluidsvenster (F2). Rechtsboven staat de klok.

var klok_label: Label


func _ready() -> void:
	var geladen: bool = Content.laad_standaard()
	klok_label = Label.new()
	klok_label.anchor_left = 1.0
	klok_label.anchor_right = 1.0
	klok_label.offset_left = -260.0
	klok_label.offset_top = 8.0
	klok_label.modulate = Color(1, 1, 1, 0.55)
	var laag := CanvasLayer.new()
	laag.add_child(klok_label)
	add_child(laag)
	var venster: Geluidsvenster = Geluidsvenster.maak(GameState.audio, Ontwikkel.actief())
	if venster != null:
		add_child(venster)
	if geladen and Content.is_geladen:
		GameState.klok.scene_gewisseld.connect(func(_v: String, _n: String, _r: String) -> void: _ververs())
		GameState.nieuw_spel()
		_ververs()
		print("Onderstad: content geladen (%d hoofdstuk(ken))" % Content.hoofdstuk_volgorde.size())
	else:
		print("Onderstad: nog geen spelcontent in content/; lege wereld.")


func _ververs() -> void:
	klok_label.text = GameState.klok.klok_tekst()
