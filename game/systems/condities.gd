class_name Condities
extends RefCounted
## De gedeelde conditietaal (docs/systemen/state-en-flags.md). Zuiver: lezen zonder bijwerkingen.
## Identiek aan tools/onderstad/condities.py; beide draaien tests/fixtures/condities.json.

const MAX_DIEPTE: int = 32


static func minuten(tijd: String) -> int:
	return tijd.substr(0, 2).to_int() * 60 + tijd.substr(3, 2).to_int()


static func tijdstip_minuten(t: Dictionary) -> int:
	return int(t["dag"]) * 1440 + minuten(t["tijd"])


## Afwezige conditie (null) is waar. Onbekende id: onwaar plus een foutregel (SF-06).
static func evalueer(c: Variant, ctx: ConditieContext, diepte: int = 0) -> bool:
	if c == null:
		return true
	if diepte > MAX_DIEPTE:
		ctx.fout("benoemde condities nesten te diep (kring?)")
		return false
	if not (c is Dictionary):
		ctx.fout("conditie is geen object: %s" % str(c))
		return false
	var d: Dictionary = c
	if d.has("alle"):
		var lijst: Array = d["alle"]
		if lijst.is_empty():
			ctx.fout("lege 'alle'-lijst")
			return false
		for x: Variant in lijst:
			if not evalueer(x, ctx, diepte + 1):
				return false
		return true
	if d.has("een_van"):
		var lijst2: Array = d["een_van"]
		if lijst2.is_empty():
			ctx.fout("lege 'een_van'-lijst")
			return false
		for x: Variant in lijst2:
			if evalueer(x, ctx, diepte + 1):
				return true
		return false
	if d.has("niet"):
		return not evalueer(d["niet"], ctx, diepte + 1)
	if d.has("heeft"):
		if not ctx.item_bekend(d["heeft"]):
			ctx.fout("onbekend object: %s" % d["heeft"])
			return false
		return ctx.heeft(d["heeft"])
	if d.has("ligt"):
		var l: Dictionary = d["ligt"]
		if not ctx.item_bekend(l["object"]):
			ctx.fout("onbekend object: %s" % l["object"])
			return false
		return ctx.ligt(l["object"], l["in"])
	if d.has("token"):
		return ctx.heeft_token(d["token"])
	if d.has("flag"):
		return _flag(d, ctx)
	if d.has("knoop"):
		return ctx.knoop_opgelost(d["knoop"])
	if d.has("kamer"):
		return ctx.huidige_kamer() == d["kamer"]
	if d.has("scene"):
		return ctx.huidige_scene() == d["scene"]
	if d.has("gebeurtenis"):
		var status: String = ctx.gebeurtenis_status(d["gebeurtenis"])
		if status == "":
			ctx.fout("onbekende gebeurtenis: %s" % d["gebeurtenis"])
			return false
		return status == d.get("status", "actief")
	if d.has("kloktijd"):
		var nu: int = ctx.kloktijd_minuten()
		var van: int = minuten(d["kloktijd"]["van"])
		var tot: int = minuten(d["kloktijd"]["tot"])
		return (nu >= van and nu < tot) if van <= tot else (nu >= van or nu < tot)
	if d.has("scenetijd"):
		var st: Dictionary = d["scenetijd"]
		var nu2: int = ctx.scenetijd_minuten()
		if st.has("vanaf") and nu2 < tijdstip_minuten(st["vanaf"]):
			return false
		if st.has("voor") and nu2 >= tijdstip_minuten(st["voor"]):
			return false
		return true
	if d.has("niveau"):
		return ctx.heeft_niveau(d["niveau"])
	if d.has("apparaat"):
		var toestand: String = ctx.apparaat_toestand(d["apparaat"])
		if toestand == "":
			ctx.fout("onbekend apparaat: %s" % d["apparaat"])
			return false
		return toestand == d["toestand"]
	if d.has("conditie"):
		var sub: Variant = ctx.benoemd(d["conditie"])
		if sub == null:
			ctx.fout("onbekende benoemde conditie: %s" % d["conditie"])
			return false
		return evalueer(sub, ctx, diepte + 1)
	ctx.fout("onbekende conditie: %s" % str(d))
	return false


static func _flag(d: Dictionary, ctx: ConditieContext) -> bool:
	var waarde: Variant = ctx.flag_waarde(d["flag"])
	if waarde == null:
		ctx.fout("onbekende flag: %s" % d["flag"])
		return false
	var getal: int = int(waarde)
	if d.has("gelijk"):
		return getal == int(d["gelijk"])
	if d.has("minstens"):
		return getal >= int(d["minstens"])
	if d.has("hoogstens"):
		return getal <= int(d["hoogstens"])
	return getal != 0
