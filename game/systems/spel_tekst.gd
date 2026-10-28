class_name SpelTekst
extends SpelStaat
## Teksten, mompels en foutregels van de spelstaat (zie Spel voor de rest).


func tekst(sleutel: String, vars: Dictionary = {}) -> String:
	var t: String = content.tekst(sleutel)
	for k: String in vars:
		t = t.replace("{%s}" % k, str(vars[k]))
	for token_id: String in content.tokens:
		if t.contains("{token:%s}" % token_id):
			t = t.replace("{token:%s}" % token_id, str(content.tokens[token_id].get("waarde", "")))
	return t


## Eerste variant waarvan `als` klopt (of de enige sleutel). Geeft een tekstsleutel.
func kies_variant(v: Variant) -> String:
	if v is String:
		return v
	if v is Array:
		for x: Dictionary in v:
			if Condities.evalueer(x.get("als"), ctx):
				return x["tekst"]
	return ""


## Tijdens een gesprek wacht Richard met mompelen tot het gesprek voorbij is (zie `spreek_uit_wachtrij`).
func mompel_zeg(sleutel: String, vars: Dictionary = {}) -> void:
	if sleutel == "":
		return
	if blokkades.has("gesprek"):
		_mompel_wachtrij.append([sleutel, vars])
	else:
		mompel.emit(tekst(sleutel, vars), sleutel)


func spreek_uit_wachtrij() -> void:
	var rij: Array = _mompel_wachtrij.duplicate()
	_mompel_wachtrij.clear()
	for m: Array in rij:
		mompel.emit(tekst(m[0], m[1]), m[0])


func log_fout(tekst_: String) -> void:
	fout_log.append(tekst_)
	printerr("spel: " + tekst_)
