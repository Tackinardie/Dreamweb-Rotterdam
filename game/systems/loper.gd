class_name Loper
extends RefCounted
## Richard loopt over de vakmiddens van een pad met 1,4 m/s (kamerweergave.md, W14). Zuiver: getallen en vakken.

signal vak_bereikt(vak: Vector2i)
signal aangekomen

const SNELHEID: float = 1.4

var positie: Vector3 = Vector3.ZERO
var richting: Vector3 = Vector3(0, 0, 1)
var vak: Vector2i = Vector2i.ZERO         # het laatst bereikte vak
var bezig: bool = false
var _pad: Array[Vector2i] = []
var _volgende: int = 0


func zet(v: Vector2i) -> void:
	vak = v
	positie = Vak.naar_3d(v)
	_pad = []
	bezig = false


## Begin een pad (het eerste element mag het huidige vak zijn).
func start(pad: Array[Vector2i]) -> void:
	_pad = pad.duplicate()
	_volgende = 1 if not _pad.is_empty() and _pad[0] == vak else 0
	bezig = _volgende < _pad.size()
	if not bezig:
		aangekomen.emit()


## Het vak waar Richard nu naartoe loopt (bij stilstand het huidige vak).
func eerstvolgend_vak() -> Vector2i:
	return _pad[_volgende] if bezig and _volgende < _pad.size() else vak


## Nieuw doel tijdens het lopen: Richard loopt eerst door naar het eerstvolgende vak (W15).
## `pad_vanaf_volgende` is een pad dat bij dat vak begint.
func vervang(pad_vanaf_volgende: Array[Vector2i]) -> void:
	if not bezig:
		start(pad_vanaf_volgende)
		return
	var nieuw: Array[Vector2i] = [vak]
	for i in range(pad_vanaf_volgende.size()):
		if i == 0 and pad_vanaf_volgende[0] == vak:
			continue
		nieuw.append(pad_vanaf_volgende[i])
	_pad = nieuw
	_volgende = 1
	bezig = _volgende < _pad.size()


func tik(dt: float) -> void:
	var rest: float = SNELHEID * dt
	while bezig and rest > 0.0:
		var doel: Vector3 = Vak.naar_3d(_pad[_volgende])
		var d: float = positie.distance_to(doel)
		if d > 0.0001:
			richting = (doel - positie).normalized()
		if d <= rest:
			positie = doel
			rest -= d
			vak = _pad[_volgende]
			_volgende += 1
			vak_bereikt.emit(vak)
			if _volgende >= _pad.size():
				bezig = false
				aangekomen.emit()
		else:
			positie += richting * rest
			rest = 0.0
