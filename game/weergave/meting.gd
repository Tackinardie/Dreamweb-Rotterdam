class_name Meting
extends Node
## Prestatiemeting (kamerweergave.md, W23-W24): wacht `wacht` s, meet `duur` s en levert fps-cijfers.
## `--meet <kamer>` schrijft ze naar user://meting/<kamer>_<stand>.json; de eerste start meet 3 s voor de standkeuze.

signal klaar(resultaat: Dictionary)

var weergave: KamerWeergave = null
var wacht: float = 2.0
var duur: float = 10.0
var _t: float = 0.0
var _tijden: Array[float] = []


func _process(dt: float) -> void:
	_t += dt
	if _t > wacht:
		_tijden.append(dt)
	if _t >= wacht + duur:
		set_process(false)
		klaar.emit(resultaat())


## fps_gem en fps_1pct_laagst (fps van de traagste 1 % van de frames) uit frametijden in seconden.
static func samenvatting(tijden: Array) -> Dictionary:
	if tijden.is_empty():
		return {"fps_gem": 0.0, "fps_1pct_laagst": 0.0}
	var gesorteerd: Array = tijden.duplicate()
	gesorteerd.sort()
	var som: float = 0.0
	for t: float in tijden:
		som += t
	var n1: int = maxi(1, ceili(gesorteerd.size() * 0.01))
	var trage: float = 0.0
	for i in range(gesorteerd.size() - n1, gesorteerd.size()):
		trage += gesorteerd[i]
	return {"fps_gem": tijden.size() / som, "fps_1pct_laagst": n1 / trage}


func resultaat() -> Dictionary:
	var r: Dictionary = samenvatting(_tijden)
	var root: KamerRoot = weergave.root
	var res: Vector2i = DisplayServer.window_get_size()
	r["kamer"] = root.kamer_id
	r["stand"] = weergave.stand
	r["meshes"] = root.tel_meshes()
	r["lichten"] = root.tel_lichten()
	r["lichten_schaduw"] = root.tel_schaduwlichten()
	r["gpu"] = RenderingServer.get_video_adapter_name()
	r["resolutie"] = "%dx%d" % [res.x, res.y]
	return r


static func schrijf(r: Dictionary, map: String = "user://meting") -> String:
	DirAccess.make_dir_recursive_absolute(map)
	var pad: String = "%s/%s_%s.json" % [map, r["kamer"], r["stand"]]
	var f := FileAccess.open(pad, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(r, "\t"))
	return pad
