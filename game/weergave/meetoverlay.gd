class_name Meetoverlay
extends Node
## F3 in ontwikkelbuilds (kamerweergave.md, W24): fps, meshes, lichten, schaduwlichten, stand, plus het vakkenraster
## en de geblokkeerde vakken in de scène.

var weergave: KamerWeergave = null
var aan: bool = false
var _raster: MeshInstance3D = null
var _rest: float = 0.0


func wissel() -> void:
	aan = not aan
	weergave.ui.meet.visible = aan
	if _raster != null:
		_raster.queue_free()
		_raster = null
	if aan:
		_raster = RasterDebug.bouw(weergave.root)
		weergave.root.add_child(_raster)
		_rest = 0.0


func _process(dt: float) -> void:
	if not aan:
		return
	_rest -= dt
	if _rest <= 0.0:
		_rest = 0.25
		weergave.ui.meet.text = tekst(weergave)


static func tekst(w: KamerWeergave) -> String:
	var r: KamerRoot = w.root
	return "kamer %s  stand %s\nfps %d\nmeshes %d  lichten %d  met schaduw %d\nvak Richard %s\nraster %dx%d, geblokkeerd %d" % [
			r.kamer_id, w.stand, Engine.get_frames_per_second(), r.tel_meshes(), r.tel_lichten(),
			r.tel_schaduwlichten(), str(w.loper.vak), r.breedte, r.hoogte, r.raster.geblokkeerd.size()]
