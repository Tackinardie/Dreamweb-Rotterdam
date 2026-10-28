class_name Vak
extends RefCounted
## Vak en 3D-ruimte (kamerweergave.md, W1-W5). Zuiver: geen Node3D. Een vak is 1x1 m, 1 unit = 1 m.
## Oorsprong (0,0,0) = hoek linksachter van de vloer; vak.x loopt langs +X, vak.y langs +Z (naar de camera).

const ACHT: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
		Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1)]


## Middelpunt van het vak op de vloer (W3).
static func naar_3d(v: Vector2i) -> Vector3:
	return Vector3(v.x + 0.5, 0.0, v.y + 0.5)


## 3D -> vak. Met breedte en hoogte (> 0) geeft een punt buiten de kamer `null` (geen vak).
static func uit_3d(p: Vector3, breedte: int = -1, hoogte: int = -1) -> Variant:
	var v := Vector2i(floori(p.x), floori(p.z))
	if breedte > 0 and hoogte > 0 and not in_kamer(v, breedte, hoogte):
		return null
	return v


static func in_kamer(v: Vector2i, breedte: int, hoogte: int) -> bool:
	return v.x >= 0 and v.y >= 0 and v.x < breedte and v.y < hoogte


## Plaatsing met `stand` verschuift alleen het model: (dx, hoogte, dz); het vak blijft hetzelfde.
static func naar_3d_stand(v: Vector2i, stand: Dictionary) -> Vector3:
	return naar_3d(v) + Vector3(float(stand.get("dx", 0.0)), float(stand.get("hoogte", 0.0)), float(stand.get("dz", 0.0)))


## {"x": 1, "y": 2} uit content -> Vector2i.
static func uit_positie(d: Dictionary) -> Vector2i:
	return Vector2i(int(d.get("x", 0)), int(d.get("y", 0)))


## Alle vakken van een vakgebied {x, y, breedte, hoogte}.
static func gebied_vakken(g: Dictionary) -> Array[Vector2i]:
	var uit: Array[Vector2i] = []
	for dy in range(int(g.get("hoogte", 1))):
		for dx in range(int(g.get("breedte", 1))):
			uit.append(Vector2i(int(g["x"]) + dx, int(g["y"]) + dy))
	return uit


## Snijpunt van een straal met het vloervlak Y = 0 (W15). null als de straal het vlak niet raakt.
static func vloer_snijpunt(oorsprong: Vector3, richting: Vector3) -> Variant:
	if absf(richting.y) < 0.000001:
		return null
	var t: float = -oorsprong.y / richting.y
	if t < 0.0:
		return null
	return oorsprong + richting * t
