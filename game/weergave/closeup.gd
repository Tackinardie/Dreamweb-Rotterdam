class_name Closeup
extends RefCounted
## 3D-close-up (kamerweergave.md, W19): een tweede camera recht voor het object, met een zachte overgang van
## 0,3 s van en naar de kamercamera. Rekent alleen de cameratransform en -fov uit; de weergave stuurt de nodes.

const DUUR: float = 0.3
const STANDAARD_AFSTAND: float = 0.8
const FOV: float = 40.0
const KANTELING: float = 20.0      # graden omhoog t.o.v. horizontaal, zodat platte dingen te zien zijn

var open: bool = false
var sluitend: bool = false
var voortgang: float = 0.0         # 0 = kamercamera, 1 = close-up
var item: String = ""
var van: Transform3D = Transform3D.IDENTITY
var naar: Transform3D = Transform3D.IDENTITY
var van_fov: float = 17.0
var naar_fov: float = FOV


## Camerastand recht voor `midden`, vanaf de camerakant (+Z), op `afstand` m.
static func stand_voor(midden: Vector3, afstand: float) -> Transform3D:
	var k: float = deg_to_rad(KANTELING)
	var pos: Vector3 = midden + Vector3(0.0, sin(k), cos(k)) * afstand
	return Transform3D(Basis.IDENTITY, pos).looking_at(midden, Vector3.UP)


func start(item_id: String, kamer_transform: Transform3D, kamer_fov: float, midden: Vector3, afstand: float) -> void:
	item = item_id
	van = kamer_transform
	van_fov = kamer_fov
	naar = stand_voor(midden, afstand)
	naar_fov = FOV
	open = true
	sluitend = false
	voortgang = 0.0


func sluit() -> void:
	if open:
		sluitend = true


## Voortgang bijwerken. Geeft true terug op het moment dat het sluiten klaar is.
func tik(dt: float) -> bool:
	if not open:
		return false
	voortgang = clampf(voortgang + (-dt if sluitend else dt) / DUUR, 0.0, 1.0)
	if sluitend and voortgang <= 0.0:
		open = false
		sluitend = false
		return true
	return false


func huidige_transform() -> Transform3D:
	var t: float = smoothstep(0.0, 1.0, voortgang)
	return van.interpolate_with(naar, t)


func huidige_fov() -> float:
	return lerpf(van_fov, naar_fov, smoothstep(0.0, 1.0, voortgang))
