class_name Schermfoto
extends Node
## `--foto <pad.png> [--frames n]`: slaat na n frames het beeld op en sluit af (voor QA en documentatie).

var pad: String = ""
var frames: int = 90
var _n: int = 0


func _process(_dt: float) -> void:
	_n += 1
	if _n >= frames:
		set_process(false)
		var img: Image = get_viewport().get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(pad.get_base_dir())
		var fout: int = img.save_png(pad)
		print("Schermfoto %s (%s) fout=%d" % [pad, str(img.get_size()), fout])
		get_tree().quit()
