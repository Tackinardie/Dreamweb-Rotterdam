class_name Placeholder
extends RefCounted
## Herkenbare vormen en kleuren voor wat nog geen model heeft (kamerweergave.md, W6).

const KADER: String = "#07080C"
const VLOER: String = "#2A3A5C"
const MUUR: String = "#1F2A44"
const RAND: String = "#0E1220"
const GEBLOKKEERD: String = "#151B2C"
const DEUR: String = "#3E5578"
const OBJECT: String = "#5A7398"
const NPC: String = "#8A93A8"
const RICHARD: String = "#C8D8F0"


static func materiaal(hex: String, emissie: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.html(hex)
	m.roughness = 0.85
	if emissie > 0.0:
		m.emission_enabled = true
		m.emission = Color.html(hex)
		m.emission_energy_multiplier = emissie
	return m


## Een doos met het midden op `midden` (in de ruimte van `parent`).
static func doos(parent: Node3D, naam: String, maat: Vector3, hex: String, midden: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = naam
	var bm := BoxMesh.new()
	bm.size = maat
	mi.mesh = bm
	mi.material_override = materiaal(hex)
	mi.position = midden
	parent.add_child(mi)
	return mi


static func capsule(parent: Node3D, naam: String, hex: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = naam
	var cm := CapsuleMesh.new()
	cm.radius = 0.25
	cm.height = 1.8
	mi.mesh = cm
	mi.material_override = materiaal(hex)
	mi.position = Vector3(0, 0.9, 0)
	parent.add_child(mi)
	return mi


## Id-label boven een placeholder (kleine tekst die de camera volgt).
static func label(parent: Node3D, tekst: String, hoogte: float) -> Label3D:
	var l := Label3D.new()
	l.name = "label"
	l.text = tekst
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.pixel_size = 0.006
	l.font_size = 24
	l.modulate = Color(0.96, 0.95, 0.9, 0.8)
	l.no_depth_test = true
	l.position = Vector3(0, hoogte, 0)
	parent.add_child(l)
	return l


static func zet_lagen(ding: Node, masker: int) -> void:
	for m in Contour.meshes(ding):
		m.layers = masker
