class_name Overgang
extends CanvasLayer
## Kamerwissel zonder laadscherm (kamerweergave.md, W20-W21): uitfaden naar #07080C in 0,25 s, wisselen, infaden
## in 0,25 s. Naar een droomkamer: een filter van 1,5 s (0,75 op, wissel, 0,75 af). `tik(dt)` drijft het;
## tests tikken zelf.

signal klaar

const FADE_S: float = 0.25
const DROOM_S: float = 0.75

var actief: bool = false
var droom: bool = false
var filter: float = 0.0          # 0..1: fade-dekking of droomfilter
var max_filter: float = 0.0
var duur: float = 0.0            # totale tijd van de laatste overgang
var _fase: String = ""           # uit | wacht | in
var _t: float = 0.0
var _wissel: Callable
var _rect: ColorRect = null


func _init() -> void:
	layer = 20
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh: Shader = load("res://weergave/overgang.gdshader")
	var m := ShaderMaterial.new()
	m.shader = sh
	_rect.material = m
	_rect.visible = false
	add_child(_rect)


## `wissel` bouwt de nieuwe kamer en geeft true zodra alles klaar is (anders blijft het beeld zwart).
func start(is_droom: bool, wissel: Callable) -> void:
	actief = true
	droom = is_droom
	_wissel = wissel
	_fase = "uit"
	_t = 0.0
	duur = 0.0
	max_filter = 0.0
	_zet(0.0)


func _fase_duur() -> float:
	return DROOM_S if droom else FADE_S


func tik(dt: float) -> void:
	if not actief:
		return
	duur += dt
	match _fase:
		"uit":
			_t += dt
			_zet(clampf(_t / _fase_duur(), 0.0, 1.0))
			if _t >= _fase_duur():
				_fase = "wacht"
		"wacht":
			if _wissel.call():
				_fase = "in"
				_t = 0.0
		"in":
			_t += dt
			_zet(1.0 - clampf(_t / _fase_duur(), 0.0, 1.0))
			if _t >= _fase_duur():
				actief = false
				_zet(0.0)
				_rect.visible = false
				klaar.emit()


func _zet(w: float) -> void:
	filter = w
	max_filter = maxf(max_filter, w)
	_rect.visible = true
	var m := _rect.material as ShaderMaterial
	m.set_shader_parameter("droom", w if droom else 0.0)
	m.set_shader_parameter("fade", 0.0 if droom else w)
