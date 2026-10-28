class_name RasterDebug
extends RefCounted
## Vakkenraster (witte lijnen) en geblokkeerde/bezette vakken (rode vlakken) net boven de vloer, voor F3.


static func bouw(root: KamerRoot) -> MeshInstance3D:
	var lijnen := PackedVector3Array()
	for x in range(root.breedte + 1):
		lijnen.append(Vector3(x, 0.01, 0))
		lijnen.append(Vector3(x, 0.01, root.hoogte))
	for z in range(root.hoogte + 1):
		lijnen.append(Vector3(0, 0.01, z))
		lijnen.append(Vector3(root.breedte, 0.01, z))
	var vlak := PackedVector3Array()
	for y in range(root.hoogte):
		for x in range(root.breedte):
			if not root.raster.beloopbaar(Vector2i(x, y)):
				vlak.append_array([Vector3(x, 0.02, y), Vector3(x + 1, 0.02, y), Vector3(x + 1, 0.02, y + 1),
						Vector3(x, 0.02, y), Vector3(x + 1, 0.02, y + 1), Vector3(x, 0.02, y + 1)])
	var mesh := ArrayMesh.new()
	_surface(mesh, Mesh.PRIMITIVE_LINES, lijnen, Color(1, 1, 1, 0.35))
	if not vlak.is_empty():
		_surface(mesh, Mesh.PRIMITIVE_TRIANGLES, vlak, Color(0.9, 0.1, 0.1, 0.35))
	var mi := MeshInstance3D.new()
	mi.name = "raster_debug"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _surface(mesh: ArrayMesh, soort: Mesh.PrimitiveType, punten: PackedVector3Array, kleur: Color) -> void:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = punten
	mesh.add_surface_from_arrays(soort, arrays)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = kleur
	mesh.surface_set_material(mesh.get_surface_count() - 1, m)
