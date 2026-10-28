class_name KamerInhoud
extends RefCounted
## Objecten, NPC's en Richard in de kamer (kamerweergave.md, W6-W7). Alleen objecten die direct in de kamer
## liggen krijgen een node; elke node heet naar het item-id.


## Node voor een object op een vak. `plaatsing` = de regel uit het kamerbestand (voor `stand`), of leeg.
static func object(root: KamerRoot, spel: Spel, item_id: String, vak: Vector2i, plaatsing: Dictionary) -> Node3D:
	var item: Dictionary = spel.content.items[item_id]
	var stand: Dictionary = plaatsing.get("stand", {})
	var n := Node3D.new()
	n.name = item_id
	n.position = Vak.naar_3d_stand(vak, stand)
	n.rotation_degrees.y = float(stand.get("draai", 0.0))
	var log_fn := Callable(spel, "log_fout")
	var model: Node3D = ModelLader.laad(str(item.get("model", "")), log_fn)
	var hoogte: float = 1.0
	if model != null:
		model.name = "model"
		n.add_child(model)
		hoogte = root.aabb_van(model, model).size.y
	else:
		hoogte = _placeholder(n, item, stand)
		Placeholder.label(n, spel.tekst(item.get("naam", item_id)), hoogte + 0.25)
	var detail_id: String = str(item.get("closeup", {}).get("model", ""))
	if detail_id != "":
		var detail: Node3D = ModelLader.laad(detail_id, log_fn)
		if detail != null:
			detail.name = "detail"
			n.add_child(detail)
			Placeholder.zet_lagen(detail, KamerRoot.LAAG_DETAIL)
			for k in n.get_children():
				if k != detail:
					Placeholder.zet_lagen(k, KamerRoot.LAAG_GEWOON)
	return n


static func _placeholder(n: Node3D, item: Dictionary, stand: Dictionary) -> float:
	var maat: Vector3
	if item.get("pakbaar", false):
		var z: float = [0.15, 0.25, 0.35][clampi(int(item.get("grootte", 1)) - 1, 0, 2)]
		maat = Vector3(z, z, z)
	elif float(stand.get("hoogte", 0.0)) > 0.0:
		maat = Vector3(0.4, 0.05, 0.3)
	else:
		maat = Vector3(0.8, 1.0, 0.8)
	Placeholder.doos(n, "placeholder", maat, Placeholder.OBJECT, Vector3(0, maat.y * 0.5, 0))
	return maat.y


static func npc(root: KamerRoot, n_data: Dictionary, label_tekst: String) -> Node3D:
	var n := Node3D.new()
	n.name = n_data["id"]
	n.position = Vak.naar_3d(Vak.uit_positie(n_data["positie"]))
	Placeholder.capsule(n, "placeholder", Placeholder.NPC)
	Placeholder.label(n, label_tekst, 2.05)
	root.registreer("npc", n_data["id"], n)
	return n


## Richard: capsule van 1,8 m met randlicht (stijlgids 8.1).
static func richard(root: KamerRoot) -> Node3D:
	var n := Node3D.new()
	n.name = "richard"
	Placeholder.capsule(n, "placeholder", Placeholder.RICHARD)
	var licht := OmniLight3D.new()
	licht.name = "randlicht"
	licht.light_color = Color.html("#C8D8F0")
	licht.light_energy = 0.8
	licht.omni_range = 2.5
	licht.position = Vector3(0.0, 1.9, 0.6)
	n.add_child(licht)
	root.richard = n
	return n
