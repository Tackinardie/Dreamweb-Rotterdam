class_name KamerBouwer
extends RefCounted
## Bouwt een kamer uit content als 3D-scène (kamerweergave.md, W6-W8): kader, vloer, muren, geblokkeerd, objecten,
## uitgangen, NPC's, Richard, lichten. Alles uit het kamerbestand; zonder model een placeholder.


static func bouw(spel: Spel, kamer_id: String) -> KamerRoot:
	var root := KamerRoot.new()
	root.name = "kamer_" + kamer_id
	root.kamer_id = kamer_id
	root.kamer = spel.content.kamers[kamer_id]
	root.breedte = int(root.kamer["afmeting"]["breedte"])
	root.hoogte = int(root.kamer["afmeting"]["hoogte"])
	root.plafond = float(root.kamer.get("plafond", CameraStand.STANDAARD_PLAFOND))
	root.stand = CameraStand.uit_kamer(root.kamer)
	root.raster = KamerRaster.uit_kamer(root.kamer)
	var vorm := Node3D.new()
	vorm.name = "vorm"
	root.add_child(vorm)
	var model: Node3D = ModelLader.laad(str(root.kamer.get("model", "")), Callable(spel, "log_fout"))
	if model != null:
		model.name = "model"
		root.add_child(model)       # vervangt vloer, muren en blokken (W7)
		vorm.free()
	else:
		KamerVorm.bouw(root, vorm)
	var hoofdstuk: String = spel.content.kamer_hoofdstuk.get(kamer_id, "")
	var handwerk: Node3D = ModelLader.handwerk(hoofdstuk, kamer_id)
	if handwerk != null:
		handwerk.name = "handwerk"
		root.add_child(handwerk)
	for u: Dictionary in root.kamer.get("uitgangen", []):
		root.add_child(KamerVorm.uitgang(root, u, u["id"]))
	zet_objecten(root, spel)
	for n: Dictionary in spel.npcs_in_kamer(kamer_id):
		root.add_child(KamerInhoud.npc(root, n, spel.tekst(n.get("naam", n["id"]))))
	root.add_child(KamerInhoud.richard(root))
	KamerLicht.bouw(root, spel, root)
	obstakels_bijwerken(root, spel)
	return root


## Zet voor elk object dat nu direct in de kamer ligt een node; verwijdert nodes van objecten die weg zijn.
static func zet_objecten(root: KamerRoot, spel: Spel) -> void:
	var nu: Array = spel.objecten.kamer_objecten(root.kamer_id)
	for p in root.pickbaar.duplicate():
		if p["soort"] == "object" and not nu.has(p["id"]):
			root.vergeet(p["id"])
			(p["node"] as Node).free()
	for item: String in nu:
		if not root.ding(item).is_empty() or not spel.objecten.positie.has(item):
			continue
		var plaatsing: Dictionary = {}
		for pl: Dictionary in root.kamer.get("objecten", []):
			if pl["object"] == item:
				plaatsing = pl
		var node: Node3D = KamerInhoud.object(root, spel, item, spel.objecten.positie[item], plaatsing)
		root.add_child(node)
		root.registreer("object", item, node)


static func obstakels_bijwerken(root: KamerRoot, spel: Spel) -> void:
	root.raster.zet_obstakels(KamerRaster.obstakels_van(root.kamer_id, spel.content, spel.objecten, spel.npcs_in_kamer(root.kamer_id)))
