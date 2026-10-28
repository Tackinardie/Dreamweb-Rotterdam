class_name WeergaveUi
extends CanvasLayer
## Lichte interface bij de kamerweergave: vignet (stijlgids 5.2), naam bij de cursor, tekst onderin
## en de F3-meetoverlay. Geen strook of menu; dat is een ander systeem.

const TEKST_S: float = 4.0

var naam: Label = null
var tekst: Label = null
var meet: Label = null
var _tekst_rest: float = 0.0


func _init() -> void:
	layer = 10
	var vignet := ColorRect.new()
	vignet.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://weergave/vignet.gdshader")
	vignet.material = m
	add_child(vignet)
	naam = _label(Vector2(0, 0), 20)
	naam.visible = false
	tekst = _label(Vector2(0, 0), 22)
	tekst.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	tekst.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tekst.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tekst.offset_top = -90.0
	tekst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tekst.custom_minimum_size = Vector2(900, 0)
	tekst.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meet = _label(Vector2(16, 300), 16)
	meet.visible = false


func _label(pos: Vector2, grootte: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", grootte)
	l.add_theme_color_override("font_color", Color(0.957, 0.945, 0.902))
	l.add_theme_color_override("font_outline_color", Color(0.027, 0.031, 0.047))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func toon_naam(t: String, pos: Vector2) -> void:
	naam.text = t
	naam.position = pos + Vector2(18, 22)
	naam.visible = t != ""


func toon_tekst(t: String) -> void:
	tekst.text = t
	tekst.visible = t != ""
	_tekst_rest = TEKST_S


func wis_tekst() -> void:
	tekst.text = ""
	tekst.visible = false


func tik(dt: float, vast: bool) -> void:
	if tekst.visible and not vast:
		_tekst_rest -= dt
		if _tekst_rest <= 0.0:
			wis_tekst()
