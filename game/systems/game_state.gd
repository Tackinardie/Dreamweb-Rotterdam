extends Spel
## Autoload `GameState`: de enige instantie van de spelstaat in het echte spel. Alle logica staat in Spel;
## tests maken hun eigen Spel met een eigen ContentDb.


func _ready() -> void:
	bouw(Content)
	auto_tik = true
	if Ontwikkel.actief():
		audio.start_logboek()
