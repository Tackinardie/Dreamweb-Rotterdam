class_name ModelLader
extends RefCounted
## Laadt een .glb onder game/assets/ (asset_id zonder extensie). Ontbreekt het bestand: null en een logregel,
## nooit een crash (kamerweergave.md, W7).

const MAP: String = "res://assets/"
const HANDWERK: String = "res://scenes/rooms/"


static func pad(asset_id: String) -> String:
	return MAP + asset_id + ".glb"


static func bestaat(asset_id: String) -> bool:
	return asset_id != "" and ResourceLoader.exists(pad(asset_id))


## Een nieuwe instantie, of null. `log_fn` krijgt de melding.
static func laad(asset_id: String, log_fn: Callable) -> Node3D:
	if asset_id == "":
		return null
	if not bestaat(asset_id):
		log_fn.call("model '%s' ontbreekt: placeholder" % asset_id)
		return null
	var ps: Variant = ResourceLoader.load(pad(asset_id))
	var n: Node = (ps as PackedScene).instantiate() if ps is PackedScene else null
	if n is Node3D:
		return n
	log_fn.call("model '%s' is geen 3D-scene: placeholder" % asset_id)
	return null


## Optioneel handwerk voor decor en voorgrond (W7): res://scenes/rooms/<hoofdstuk>/<kamer>.tscn.
static func handwerk(hoofdstuk: String, kamer: String) -> Node3D:
	var p: String = HANDWERK + hoofdstuk + "/" + kamer + ".tscn"
	if not ResourceLoader.exists(p):
		return null
	var ps: Variant = ResourceLoader.load(p)
	var n: Node = (ps as PackedScene).instantiate() if ps is PackedScene else null
	return n as Node3D
