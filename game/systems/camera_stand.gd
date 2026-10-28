class_name CameraStand
extends RefCounted
## Stand van de vaste kamercamera uit de kamerdata (kamerweergave.md, W9-W11). Zuiver: rekent met getallen
## en Transform3D (een waarde, geen node).

const STANDAARD_KANTELING: float = 38.0
const STANDAARD_DRAAIING: float = 27.0
const STANDAARD_FOV: float = 17.0
const NEAR: float = 0.5
const STANDAARD_PLAFOND: float = 2.6
const SCHERM: Vector2 = Vector2(1920.0, 1080.0)
const KADER: Vector2 = Vector2(0.6, 0.7)    # middelste deel van breedte en hoogte (W11)


## Richting vanaf het richtpunt naar de camera (W10).
static func richting(kanteling_graden: float, draaiing_graden: float) -> Vector3:
	var k: float = deg_to_rad(kanteling_graden)
	var d: float = deg_to_rad(draaiing_graden)
	return Vector3(sin(d) * cos(k), sin(k), cos(d) * cos(k))


## Alles wat de weergave nodig heeft: kanteling, draaiing, fov, afstand, near, far, richtpunt, positie, transform.
static func uit_kamer(kamer: Dictionary) -> Dictionary:
	var c: Dictionary = kamer.get("camera", {})
	var b: float = float(kamer.get("afmeting", {}).get("breedte", 1))
	var h: float = float(kamer.get("afmeting", {}).get("hoogte", 1))
	var plafond: float = float(kamer.get("plafond", STANDAARD_PLAFOND))
	var kant: float = float(c.get("kanteling", STANDAARD_KANTELING))
	var draai: float = float(c.get("draaiing", STANDAARD_DRAAIING))
	var fov: float = float(c.get("fov", STANDAARD_FOV))
	var afstand: float = float(c["afstand"]) if c.has("afstand") else automatische_afstand(b, h, plafond, kant, draai, fov)
	var m := Vector3(b * 0.5, 0.0, h * 0.5)
	var pos: Vector3 = m + richting(kant, draai) * afstand
	var diagonaal: float = sqrt(b * b + h * h)
	return {"kanteling": kant, "draaiing": draai, "fov": fov, "afstand": afstand, "near": NEAR,
			"far": afstand + diagonaal + 10.0, "richtpunt": m, "positie": pos,
			"transform": Transform3D(Basis.IDENTITY, pos).looking_at(m, Vector3.UP)}


## Genormaliseerde schermpositie (-1..1) van een punt voor een camera met deze stand en een schermverhouding.
static func projecteer(p: Vector3, cam: Transform3D, fov_graden: float, schermverhouding: float) -> Vector2:
	var v: Vector3 = cam.affine_inverse() * p     # camera kijkt langs -Z
	var diepte: float = -v.z
	var t: float = tan(deg_to_rad(fov_graden) * 0.5)
	return Vector2(v.x / (diepte * t * schermverhouding), v.y / (diepte * t))


## Kleinste afstand waarbij de acht hoeken van het kamerblok binnen 60 % x 70 % van het scherm vallen (W11).
static func automatische_afstand(breedte: float, hoogte: float, plafond: float, kanteling: float, draaiing: float, fov: float) -> float:
	var m := Vector3(breedte * 0.5, 0.0, hoogte * 0.5)
	var dir: Vector3 = richting(kanteling, draaiing)
	var laag: float = 1.0
	var hoog: float = 1000.0
	for _i in range(60):
		var mid: float = (laag + hoog) * 0.5
		if past(breedte, hoogte, plafond, m, dir, mid, fov):
			hoog = mid
		else:
			laag = mid
	return hoog


static func past(breedte: float, hoogte: float, plafond: float, m: Vector3, dir: Vector3, afstand: float, fov: float) -> bool:
	var cam: Transform3D = Transform3D(Basis.IDENTITY, m + dir * afstand).looking_at(m, Vector3.UP)
	for x in [0.0, breedte]:
		for y in [0.0, plafond]:
			for z in [0.0, hoogte]:
				var s: Vector2 = projecteer(Vector3(x, y, z), cam, fov, SCHERM.x / SCHERM.y)
				if absf(s.x) > KADER.x or absf(s.y) > KADER.y:
					return false
	return true
