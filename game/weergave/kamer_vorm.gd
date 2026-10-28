class_name KamerVorm
extends RefCounted
## Vloer, muren, geblokkeerde vakken en uitgangen als placeholder (kamerweergave.md, W6; KW-02).

const DIKTE: float = 0.1
const RAND_HOOGTE: float = 0.4
const BLOK_HOOGTE: float = 0.75
const DEUR_MAAT: Vector3 = Vector3(0.9, 2.1, 0.9)


static func bouw(root: KamerRoot, vorm: Node3D) -> void:
	var b: float = root.breedte
	var h: float = root.hoogte
	Placeholder.doos(vorm, "vloer", Vector3(b, 0.1, h), Placeholder.VLOER, Vector3(b * 0.5, -0.05, h * 0.5))
	_muren(root, vorm)
	var blokken := Node3D.new()
	blokken.name = "geblokkeerd"
	vorm.add_child(blokken)
	var i: int = 0
	for g: Dictionary in root.kamer.get("geblokkeerd", []):
		var gb: float = float(g.get("breedte", 1))
		var gh: float = float(g.get("hoogte", 1))
		Placeholder.doos(blokken, "blok_%d" % i, Vector3(gb, BLOK_HOOGTE, gh), Placeholder.GEBLOKKEERD,
				Vector3(float(g["x"]) + gb * 0.5, BLOK_HOOGTE * 0.5, float(g["y"]) + gh * 0.5))
		i += 1


## Achter- en verre zijwand op volle hoogte, voor- en nabije zijwand als rand van 0,4 m. Buiten: alleen randen.
static func _muren(root: KamerRoot, vorm: Node3D) -> void:
	var b: float = root.breedte
	var h: float = root.hoogte
	var buiten: bool = root.kamer.get("soort", "binnen") == "buiten"
	var rechts_nabij: bool = float(root.stand.get("draaiing", 27.0)) >= 0.0
	var vol: float = root.plafond
	var hoog_achter: float = RAND_HOOGTE if buiten else vol
	var hoog_links: float = RAND_HOOGTE if buiten or rechts_nabij == false else vol
	var hoog_rechts: float = RAND_HOOGTE if buiten or rechts_nabij else vol
	_muur(vorm, "wand_achter", Vector3(b + 2 * DIKTE, hoog_achter, DIKTE), Vector3(b * 0.5, 0, -DIKTE * 0.5), hoog_achter == vol)
	_muur(vorm, "wand_voor", Vector3(b + 2 * DIKTE, RAND_HOOGTE, DIKTE), Vector3(b * 0.5, 0, h + DIKTE * 0.5), false)
	_muur(vorm, "wand_links", Vector3(DIKTE, hoog_links, h), Vector3(-DIKTE * 0.5, 0, h * 0.5), hoog_links == vol)
	_muur(vorm, "wand_rechts", Vector3(DIKTE, hoog_rechts, h), Vector3(b + DIKTE * 0.5, 0, h * 0.5), hoog_rechts == vol)


static func _muur(vorm: Node3D, naam: String, maat: Vector3, voet: Vector3, volle_muur: bool) -> void:
	Placeholder.doos(vorm, naam, maat, Placeholder.MUUR if volle_muur else Placeholder.RAND, voet + Vector3(0, maat.y * 0.5, 0))


## Uitgang: op een randvak een deurblad in die muur (achter > links > rechts > voor), anders een blok.
static func uitgang(root: KamerRoot, u: Dictionary, label_tekst: String) -> Node3D:
	var v: Vector2i = Vak.uit_positie(u["positie"])
	var n := Node3D.new()
	n.name = u["id"]
	n.position = Vak.naar_3d(v)
	var maat: Vector3 = DEUR_MAAT
	var uit_midden := Vector3(0, DEUR_MAAT.y * 0.5, 0)
	if v.y == 0:
		maat = Vector3(0.9, 2.1, DIKTE)
		uit_midden.z = -0.5 + DIKTE * 0.5
	elif v.x == 0:
		maat = Vector3(DIKTE, 2.1, 0.9)
		uit_midden.x = -0.5 + DIKTE * 0.5
	elif v.x == root.breedte - 1:
		maat = Vector3(DIKTE, 2.1, 0.9)
		uit_midden.x = 0.5 - DIKTE * 0.5
	elif v.y == root.hoogte - 1:
		maat = Vector3(0.9, 2.1, DIKTE)
		uit_midden.z = 0.5 - DIKTE * 0.5
	Placeholder.doos(n, "deurblad", maat, Placeholder.DEUR, uit_midden)
	Placeholder.label(n, label_tekst, 2.4)
	root.registreer("uitgang", u["id"], n)
	return n
