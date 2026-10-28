extends Node
# Slaat na N frames de viewport op en sluit af. Argumenten na "--": --shot=pad.png --frames=240
var path := ""
var frames := 240
var n := 0
var t0 := 0

func _process(_d: float) -> void:
	n += 1
	if n == frames - 100:
		t0 = Time.get_ticks_msec()
	if n >= frames:
		var img := get_viewport().get_texture().get_image()
		img.save_png(path)
		var fps := 100.0 / maxf(0.001, (Time.get_ticks_msec() - t0) / 1000.0)
		print("SHOT ", path, " ", img.get_size(), " gem. fps ", snappedf(fps, 0.1))
		get_tree().quit()
