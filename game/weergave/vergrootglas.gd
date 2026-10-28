class_name Vergrootglas
extends CanvasLayer
## Vergrootglas (kamerweergave.md, W18): SubViewport van 256x256 linksboven met dezelfde World3D als de kamer
## en een tweede camera met dezelfde richting, FOV = kamer-FOV / 2,5.

const MAAT: int = 256
const ZOOM: float = 2.5

var viewport: SubViewport = null
var camera: Camera3D = null
var zichtbaar: bool = false
var _paneel: TextureRect = null


func _init() -> void:
	layer = 5
	viewport = SubViewport.new()
	viewport.size = Vector2i(MAAT, MAAT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.transparent_bg = false
	camera = Camera3D.new()
	camera.name = "vergrootglas_camera"
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	viewport.add_child(camera)
	add_child(viewport)
	_paneel = TextureRect.new()
	_paneel.texture = viewport.get_texture()
	_paneel.position = Vector2(24, 24)
	_paneel.custom_minimum_size = Vector2(MAAT, MAAT)
	_paneel.size = Vector2(MAAT, MAAT)
	_paneel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paneel.visible = false
	add_child(_paneel)


## Dezelfde wereld als de kamer; moet worden aangeroepen zodra deze node in de boom staat.
func koppel(wereld: World3D) -> void:
	viewport.own_world_3d = false
	viewport.world_3d = wereld


## Richt op `midden` met de richting en stand van de kamercamera.
func toon(midden: Vector3, kamer_camera: Camera3D, afstand: float, cull_mask: int) -> void:
	camera.fov = kamer_camera.fov / ZOOM
	camera.near = kamer_camera.near
	camera.far = kamer_camera.far
	camera.cull_mask = cull_mask
	camera.global_transform = Transform3D(kamer_camera.global_transform.basis, midden + kamer_camera.global_transform.basis.z * afstand)
	zichtbaar = true
	_paneel.visible = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS


func verberg() -> void:
	zichtbaar = false
	_paneel.visible = false
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
