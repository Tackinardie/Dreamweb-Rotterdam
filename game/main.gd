extends Node
## Hoofdscene: laadt de content, start een nieuw spel en toont de kamer in 3D (docs/systemen/kamerweergave.md).
## Zonder spelcontent in content/ start een ontwikkelbuild de testkamer uit tests/fixtures/proef.
## Opties na `--`: zie StartOpties (`--meet`, `--stand`, `--kamer`, `--foto`, `--spatie`). Rechtsboven staat de klok, F2 = geluidsvenster.

const FIXTURE: String = "tests/fixtures/proef"

var klok_label: Label
var weergave: KamerWeergave = null


func _ready() -> void:
	var opties: Dictionary = StartOpties.parse(OS.get_cmdline_user_args())
	var geladen: bool = Content.laad_standaard()
	var testscene: Dictionary = {}
	if not geladen and Ontwikkel.actief():
		var wortel: String = ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
		var pad: String = wortel.path_join(FIXTURE)
		geladen = Content.laad(pad, pad.path_join("cues.json"))
		var t: Variant = JsonLezer.lees(wortel.path_join("tests/fixtures/testscene.json"))
		testscene = t if t is Dictionary else {}
	klok_label = Label.new()
	klok_label.anchor_left = 1.0
	klok_label.anchor_right = 1.0
	klok_label.offset_left = -260.0
	klok_label.offset_top = 8.0
	klok_label.modulate = Color(1, 1, 1, 0.55)
	var laag := CanvasLayer.new()
	laag.layer = 30
	laag.add_child(klok_label)
	add_child(laag)
	var venster: Geluidsvenster = Geluidsvenster.maak(GameState.audio, Ontwikkel.actief())
	if venster != null:
		add_child(venster)
	if geladen and Content.is_geladen:
		GameState.klok.scene_gewisseld.connect(func(_v: String, _n: String, _r: String) -> void: _ververs())
		GameState.spel_geladen.connect(_ververs)
		GameState.nieuw_spel()
		var kamer: String = str(opties.get("meet", opties.get("kamer", testscene.get("kamer", ""))))
		if kamer != "" and Content.kamers.has(kamer):
			GameState.verplaats_speler(kamer, str(testscene.get("uitgang", "")) if kamer == testscene.get("kamer") else "", false)
		_ververs()
		print("Onderstad: content geladen (%d hoofdstuk(ken))" % Content.hoofdstuk_volgorde.size())
		_start_weergave(opties)
	else:
		print("Onderstad: nog geen spelcontent in content/; lege wereld.")


func _start_weergave(opties: Dictionary) -> void:
	var stand: String = str(opties.get("stand", ""))
	if not Kwaliteit.is_stand(stand):
		stand = Kwaliteit.laad()
	var eerste_start: bool = stand == "" and not opties.has("meet") and DisplayServer.get_name() != "headless"
	if stand == "":
		stand = Kwaliteit.VOL
	weergave = KamerWeergave.new()
	add_child(weergave)
	weergave.start(GameState, stand)
	if opties.has("meet"):
		var r: Vector2i = Vector2i(weergave.root.breedte / 2, weergave.root.hoogte / 2)
		weergave.zet_richard(r)
		_meet(Meting.new(), 2.0, 10.0, func(res: Dictionary) -> void:
			print("Meting: ", Meting.schrijf(res), " ", res)
			get_tree().quit())
	elif eerste_start:
		_meet(Meting.new(), 0.0, 3.0, func(res: Dictionary) -> void:
			weergave.zet_stand(Kwaliteit.stand_voor_fps(res["fps_gem"])))
	if opties.has("spatie"):
		weergave.zet_spatie(true)
	if opties.has("foto"):
		var foto := Schermfoto.new()
		foto.pad = str(opties["foto"])
		foto.frames = int(opties.get("frames", 90))
		add_child(foto)


func _meet(m: Meting, wacht: float, duur: float, na: Callable) -> void:
	m.weergave = weergave
	m.wacht = wacht
	m.duur = duur
	m.klaar.connect(na)
	add_child(m)


func _ververs() -> void:
	klok_label.text = GameState.klok.klok_tekst()
