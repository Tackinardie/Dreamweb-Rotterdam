class_name Contour
extends RefCounted
## Contour om interactieve dingen bij hover en spatiebalk (kamerweergave.md, W16-W17). Een tweede, onbelichte
## pass als `material_overlay` op elke mesh van het ding; geen emissie, geen kleurverandering van het ding zelf.

static var _shader: Shader = null


static func zet(ding: Node, aan: bool) -> void:
	for m in meshes(ding):
		if aan:
			if m.material_overlay == null:
				m.material_overlay = _materiaal(m)
		else:
			m.material_overlay = null


static func is_aan(ding: Node) -> bool:
	var ms: Array[MeshInstance3D] = meshes(ding)
	if ms.is_empty():
		return false
	for m in ms:
		if m.material_overlay == null:
			return false
	return true


static func meshes(ding: Node) -> Array[MeshInstance3D]:
	var uit: Array[MeshInstance3D] = []
	if ding is MeshInstance3D:
		uit.append(ding)
	for k in ding.find_children("*", "MeshInstance3D", true, false):
		uit.append(k)
	return uit


static func _materiaal(m: MeshInstance3D) -> ShaderMaterial:
	if _shader == null:
		_shader = load("res://weergave/contour.gdshader")
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("midden", m.get_aabb().get_center() if m.mesh != null else Vector3.ZERO)
	return mat
