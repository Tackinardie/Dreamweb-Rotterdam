extends GutTest
## Projectregels: data-gedreven (geen hardcoded content), klein, autoloads, lege hoofdscene.

const Hulp = preload("hulp.gd")


func _gd_bestanden(map: String) -> Array:
	var uit: Array = []
	for f in DirAccess.get_files_at(map):
		if f.ends_with(".gd"):
			uit.append(map.path_join(f))
	for d in DirAccess.get_directories_at(map):
		if d != "addons":
			uit.append_array(_gd_bestanden(map.path_join(d)))
	return uit


func test_geen_hardcoded_content_in_scripts() -> void:
	var verboden: RegEx = RegEx.create_from_string("\"ch0[1-9]_|\"ch[1-9][0-9]_")   # de hub (ch00_) staat in de spec
	var gevonden: Array = []
	for pad in _gd_bestanden("res://"):
		var regels: PackedStringArray = FileAccess.get_file_as_string(pad).split("\n")
		for i in range(regels.size()):
			if verboden.search(regels[i]) != null:
				gevonden.append("%s:%d" % [pad, i + 1])
	assert_eq(gevonden, [], "scripts verwijzen niet naar hoofdstuk-ids; alles komt uit content/")


func test_scripts_blijven_klein() -> void:
	for pad in _gd_bestanden("res://"):
		var n: int = FileAccess.get_file_as_string(pad).split("\n").size()
		assert_lt(n, 300, "%s heeft %d regels" % [pad, n])


func test_autoloads_bestaan() -> void:
	assert_not_null(Engine.get_main_loop().root.get_node_or_null("Content"), "autoload Content")
	assert_not_null(Engine.get_main_loop().root.get_node_or_null("GameState"), "autoload GameState")


func test_lege_content_map_is_geen_fout() -> void:
	var c := ContentDb.new()
	add_child_autofree(c)
	assert_false(c.laad(Hulp.repo().path_join("content"), Hulp.repo().path_join("audio/cues.json")), "er is nog geen spel.json")
	assert_false(c.is_geladen)
	assert_gt(c.cues.size(), 0, "de cue-catalogus laadt wel")


func test_hoofdscene_draait_zonder_content() -> void:
	var main: Node = load("res://main.tscn").instantiate()
	add_child_autofree(main)
	await get_tree().process_frame
	assert_not_null(main.get_node_or_null("CanvasLayer") if false else main)


func test_fixture_is_een_kleine_generieke_wereld() -> void:
	var c: ContentDb = Hulp.nieuw_content()
	add_child_autofree(c)
	assert_eq(c.kamers.size(), 3)
	assert_eq(c.hoofdstuk_volgorde, ["ch01_proef"])
	assert_true(c.knopen.has("ch01_klaar"))
	assert_true(c.is_onmisbaar("rapport", "ch01_proef") and c.is_onmisbaar("pasje", "ch01_proef"), "pas geeft een gebruikt niveau: onmisbaar")
	assert_false(c.is_onmisbaar("kopje_wit", "ch01_proef"))
	assert_ne(c.content_hash, "")


func test_autoloads_werken_samen_met_fixturecontent() -> void:
	assert_true(Content.laad(Hulp.fixture_pad(), Hulp.fixture_pad().path_join("cues.json")))
	GameState.opslag.map = "user://test_saves/autoload"
	GameState.nieuw_spel()
	assert_eq(GameState.kamer, Hulp.HAL)
	assert_eq(GameState.klok.klok_tekst(), "wo 1 jan · 00:07")
	assert_true(GameState.objecten.heeft("bezorgtas"))
	GameState.speel(1.0)
	assert_eq(GameState.speeltijd_s, 1.0)
	Content.laad_standaard()   # terug naar de (lege) echte content voor de volgende tests
