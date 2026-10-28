class_name KamerRoot
extends Node3D
## De 3D-scène van één kamer, gebouwd door KamerBouwer uit het kamerbestand. De wortel staat op de
## wereldoorsprong; kamers delen geen coördinaten (kamerweergave.md, W2).

const LAAG_NORMAAL: int = 1      # renderlaag 1: alles wat beide camera's zien
const LAAG_DETAIL: int = 2       # laag 2: detailmodel, alleen de close-up
const LAAG_GEWOON: int = 4       # laag 3: gewoon model van een object met detailmodel; de close-up ziet het niet

var kamer_id: String = ""
var kamer: Dictionary = {}
var raster: KamerRaster = null
var stand: Dictionary = {}                 # CameraStand.uit_kamer
var breedte: int = 0
var hoogte: int = 0
var plafond: float = 2.6
var pickbaar: Array[Dictionary] = []       # {soort: object|uitgang|npc, id, node}
var licht_nodes: Dictionary = {}           # licht-id -> Light3D
var richard: Node3D = null
var omgeving: Environment = null
var wereld_omgeving: WorldEnvironment = null


func registreer(soort: String, id: String, node: Node3D) -> void:
	pickbaar.append({"soort": soort, "id": id, "node": node})


func vergeet(id: String) -> void:
	for i in range(pickbaar.size() - 1, -1, -1):
		if pickbaar[i]["id"] == id and pickbaar[i]["soort"] == "object":
			pickbaar.remove_at(i)


func ding(id: String) -> Dictionary:
	for p in pickbaar:
		if p["id"] == id:
			return p
	return {}


## Wereld-AABB van een ding (in kamerruimte), zonder dat de scène in de boom hoeft te staan.
func aabb_van(node: Node3D, tot: Node = null) -> AABB:
	var stop: Node = tot if tot != null else self
	var uit := AABB()
	var eerste: bool = true
	for m in Contour.meshes(node):
		if m.mesh == null:
			continue
		var t: Transform3D = Transform3D.IDENTITY
		var n: Node = m
		while n != stop and n != null:
			if n is Node3D:
				t = (n as Node3D).transform * t
			n = n.get_parent()
		var a: AABB = t * m.get_aabb()
		uit = a if eerste else uit.merge(a)
		eerste = false
	return uit


## Dichtstbijzijnde pickbare ding op een straal (W16); bij gelijke afstand wint het laatst gebouwde.
func pik(oorsprong: Vector3, richting: Vector3) -> Dictionary:
	var beste: Dictionary = {}
	var beste_d: float = INF
	for p in pickbaar:
		if not (p["node"] as Node3D).visible:
			continue
		var hit: Variant = aabb_van(p["node"]).intersects_ray(oorsprong, richting)
		if hit != null:
			var d: float = oorsprong.distance_to(hit)
			if d <= beste_d:
				beste_d = d
				beste = p
	return beste


func tel_meshes() -> int:
	return find_children("*", "MeshInstance3D", true, false).size()


func tel_lichten() -> int:
	return find_children("*", "Light3D", true, false).size()


func tel_schaduwlichten() -> int:
	var n: int = 0
	for l in find_children("*", "Light3D", true, false):
		if (l as Light3D).shadow_enabled:
			n += 1
	return n
