class_name Voorlader
extends RefCounted
## Laadt modellen van aangrenzende kamers op de achtergrond vooraf (kamerweergave.md, W20), zodat een
## kamerwissel geen laadscherm nodig heeft. Is iets nog niet klaar, dan blijft het beeld zwart.

var aangevraagd: Array[String] = []


## Modellen van alle kamers die vanaf `kamer_id` via een uitgang bereikbaar zijn.
func vraag_buren(content: ContentDb, kamer_id: String) -> void:
	for u: Dictionary in content.kamers.get(kamer_id, {}).get("uitgangen", []):
		if u.has("naar_kamer"):
			vraag_kamer(content, u["naar_kamer"])
		for b: Dictionary in u.get("bestemmingen", []):
			vraag_kamer(content, b["naar_kamer"])


func vraag_kamer(content: ContentDb, kamer_id: String) -> void:
	var k: Dictionary = content.kamers.get(kamer_id, {})
	var ids: Array[String] = [str(k.get("model", ""))]
	for pl: Dictionary in k.get("objecten", []):
		var item: Dictionary = content.items.get(pl["object"], {})
		ids.append(str(item.get("model", "")))
		ids.append(str(item.get("closeup", {}).get("model", "")))
	for id in ids:
		if ModelLader.bestaat(id) and not aangevraagd.has(id):
			aangevraagd.append(id)
			ResourceLoader.load_threaded_request(ModelLader.pad(id))


func klaar() -> bool:
	for id in aangevraagd:
		if ResourceLoader.load_threaded_get_status(ModelLader.pad(id)) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return false
	return true
