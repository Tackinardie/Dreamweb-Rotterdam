class_name Klok
extends RefCounted
## Klok en scènetijd (docs/systemen/klok-en-scenetijd.md). De klok staat stil; alleen een scènewissel
## verandert hem. Gebeurtenissen lopen op speeltijd (seconden) binnen de scène. Dit is de enige kloklaag:
## niemand leest de systeemklok voor spellogica (KS-10).

signal scene_gewisseld(van: String, naar: String, richting: String)
signal gebeurtenis_gewijzigd(id: String, status: String)
signal cue_gevraagd(cue_id: String, context: Dictionary)

const DAGEN_PER_MAAND: Array[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
const WEEKDAGEN: Array[String] = ["ma", "di", "wo", "do", "vr", "za", "zo"]
const MAANDEN: Array[String] = ["jan", "feb", "mrt", "apr", "mei", "jun", "jul", "aug", "sep", "okt", "nov", "dec"]
const EPS: float = 0.000001

var content: ContentDb
var scene: String = ""
var tijd: Dictionary = {"dag": 1, "tijd": "00:00"}
## id -> {"status", "rest" (-1 = onbeperkt), "herhaal_rest", "vertraging", "gereed", "wacht_vertraging"}
var gebeurtenissen: Dictionary = {}


func _init(c: ContentDb) -> void:
	content = c


func reset() -> void:
	scene = ""
	tijd = {"dag": 1, "tijd": "00:00"}
	gebeurtenissen.clear()
	for id: String in content.gebeurtenissen:
		gebeurtenissen[id] = _nieuw_status()


func _nieuw_status() -> Dictionary:
	return {"status": "wacht", "rest": -1.0, "herhaal_rest": 0.0, "vertraging": 0.0, "gereed": false, "wacht_vertraging": false}


# ---------------------------------------------------------------- scènetijd

func scenetijd_minuten() -> int:
	return Condities.tijdstip_minuten(tijd)


func kloktijd_minuten() -> int:
	return Condities.minuten(tijd["tijd"])


## Zet de scène zonder animatie of cue (nieuw spel, laden).
func start_scene(scene_id: String) -> void:
	_sluit_scene_af()
	scene = scene_id
	tijd = (content.scenes[scene_id]["tijd"] as Dictionary).duplicate()
	_begin_scene()


## Scènewissel. Geeft de richting terug: "vooruit", "terug" of "gelijk".
func naar_scene(scene_id: String) -> String:
	var van: String = scene
	var voor: int = scenetijd_minuten()
	_sluit_scene_af()
	scene = scene_id
	tijd = (content.scenes[scene_id]["tijd"] as Dictionary).duplicate()
	var na: int = scenetijd_minuten()
	var richting: String = "vooruit" if na > voor else ("terug" if na < voor else "gelijk")
	if richting == "vooruit":
		cue_gevraagd.emit("ui.klok.vooruit", {})
	elif richting == "terug":
		cue_gevraagd.emit("ui.klok.terug", {})
	_begin_scene()
	scene_gewisseld.emit(van, scene_id, richting)
	return richting


func _sluit_scene_af() -> void:
	for id: String in content.gebeurtenissen:
		if content.gebeurtenissen[id]["scene"] == scene and gebeurtenissen.has(id):
			_zet_status(id, "voorbij", false)


func _begin_scene() -> void:
	for id: String in content.gebeurtenissen:
		if content.gebeurtenissen[id]["scene"] != scene:
			continue
		gebeurtenissen[id] = _nieuw_status()
		if content.gebeurtenissen[id]["def"]["start"] is String and content.gebeurtenissen[id]["def"]["start"] == "bij_begin":
			_activeer(id)


## "wo 1 jan · 00:07" (KS-01). Weekdag en maand komen uit tekstsleutels; het formaat ook.
func klok_tekst() -> String:
	var datum: Array[int] = _datum(int(tijd["dag"]))
	var weekdag: String = content.tekst("klok.weekdag." + WEEKDAGEN[_weekdag_index(datum)])
	var maand: String = content.tekst("klok.maand." + MAANDEN[datum[1] - 1])
	var uren: String = str(tijd["tijd"]).substr(0, 2)
	var minuten_tekst: String = str(tijd["tijd"]).substr(3, 2)
	return content.tekst("klok.formaat").replace("{weekdag}", weekdag).replace("{dag}", str(datum[2])) \
			.replace("{maand}", maand).replace("{HH}", uren).replace("{MM}", minuten_tekst)


## [jaar, maand, dag] van spel-dag n (dag 1 = startdatum).
func _datum(dag: int) -> Array[int]:
	var delen: PackedStringArray = str(content.spel["startdatum"]).split("-")
	var jaar: int = delen[0].to_int()
	var maand: int = delen[1].to_int()
	var d: int = delen[2].to_int() + dag - 1
	while d > _maanddagen(jaar, maand):
		d -= _maanddagen(jaar, maand)
		maand += 1
		if maand > 12:
			maand = 1
			jaar += 1
	return [jaar, maand, d]


func _maanddagen(jaar: int, maand: int) -> int:
	if maand == 2 and (jaar % 4 == 0 and (jaar % 100 != 0 or jaar % 400 == 0)):
		return 29
	return DAGEN_PER_MAAND[maand - 1]


## 0 = maandag (algoritme van Sakamoto; geen systeemklok).
func _weekdag_index(datum: Array[int]) -> int:
	var t: Array[int] = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
	var y: int = datum[0] - (1 if datum[1] < 3 else 0)
	var zondag0: int = (y + y / 4 - y / 100 + y / 400 + t[datum[1] - 1] + datum[2]) % 7
	return (zondag0 + 6) % 7


# ---------------------------------------------------------------- gebeurtenissen

func status(id: String) -> String:
	return gebeurtenissen[id]["status"] if gebeurtenissen.has(id) else ""


func start(id: String) -> void:
	if status(id) == "wacht":
		_activeer(id)


## Stoppen (K-edge): actief of wachtend wordt voorbij, of bij een routine terug naar wacht met nieuwe timer.
func stop(id: String) -> void:
	if not gebeurtenissen.has(id) or status(id) == "voorbij":
		return
	var def: Dictionary = content.gebeurtenissen[id]["def"]
	var was_actief: bool = status(id) == "actief"
	if def.has("herhaal_na_s"):
		var g: Dictionary = gebeurtenissen[id]
		g["herhaal_rest"] = float(def["herhaal_na_s"])
		g["gereed"] = false
		_zet_status(id, "wacht", was_actief)
	else:
		_zet_status(id, "voorbij", was_actief)


func _activeer(id: String) -> void:
	var def: Dictionary = content.gebeurtenissen[id]["def"]
	var g: Dictionary = gebeurtenissen[id]
	g["rest"] = float(def["duur_s"]) if def.has("duur_s") else -1.0
	g["gereed"] = false
	g["wacht_vertraging"] = false
	_zet_status(id, "actief", false)
	if def.has("cue_start"):
		cue_gevraagd.emit(def["cue_start"], {})


func _zet_status(id: String, nieuw: String, cue_einde: bool) -> void:
	var g: Dictionary = gebeurtenissen[id]
	if g["status"] == nieuw and not cue_einde:
		return
	g["status"] = nieuw
	if cue_einde:
		var def: Dictionary = content.gebeurtenissen[id]["def"]
		if def.has("cue_einde"):
			cue_gevraagd.emit(def["cue_einde"], {})
	gebeurtenis_gewijzigd.emit(id, nieuw)


## Start-voorwaarden `{"als": c}` bekijken. Geeft de gebeurtenissen die nu in gang zijn gezet.
func herzie(ctx: ConditieContext) -> Array[String]:
	var nieuw: Array[String] = []
	for id: String in gebeurtenissen:
		var info: Dictionary = content.gebeurtenissen[id]
		var def: Dictionary = info["def"]
		var g: Dictionary = gebeurtenissen[id]
		if info["scene"] != scene or g["status"] != "wacht" or not (def["start"] is Dictionary):
			continue
		if g["herhaal_rest"] > EPS or g["wacht_vertraging"]:
			continue
		if not Condities.evalueer(def["start"]["als"], ctx):
			continue
		var vertraging: float = float(def.get("start_vertraging_s", 0.0))
		if vertraging > EPS and not g["gereed"]:
			g["vertraging"] = vertraging
			g["wacht_vertraging"] = true
		else:
			_activeer(id)
			nieuw.append(id)
	return nieuw


## Laat `dt` seconden speeltijd verstrijken.
func tik(dt: float, ctx: ConditieContext = null) -> void:
	var rest: float = dt
	while rest > EPS:
		var stap: float = rest
		for id: String in gebeurtenissen:
			if content.gebeurtenissen[id]["scene"] != scene:
				continue
			var t: float = _eerstvolgende(gebeurtenissen[id])
			if t > EPS and t < stap:
				stap = t
		for id: String in gebeurtenissen.keys():
			if content.gebeurtenissen[id]["scene"] != scene:
				continue
			_verloop(id, stap)
		rest -= stap
		if ctx != null:
			herzie(ctx)


func _eerstvolgende(g: Dictionary) -> float:
	if g["status"] == "actief" and g["rest"] >= 0.0:
		return g["rest"]
	if g["status"] == "wacht" and g["herhaal_rest"] > EPS:
		return g["herhaal_rest"]
	if g["status"] == "wacht" and g["wacht_vertraging"]:
		return g["vertraging"]
	return -1.0


func _verloop(id: String, stap: float) -> void:
	var g: Dictionary = gebeurtenissen[id]
	var def: Dictionary = content.gebeurtenissen[id]["def"]
	if g["status"] == "actief" and g["rest"] >= 0.0:
		g["rest"] = g["rest"] - stap
		if g["rest"] <= EPS:
			stop(id)
	elif g["status"] == "wacht" and g["herhaal_rest"] > EPS:
		g["herhaal_rest"] = g["herhaal_rest"] - stap
		if g["herhaal_rest"] <= EPS:
			g["herhaal_rest"] = 0.0
			if def["start"] is Dictionary:
				g["gereed"] = true     # herzie() activeert zodra de voorwaarde weer klopt
			else:
				_activeer(id)
	elif g["status"] == "wacht" and g["wacht_vertraging"]:
		g["vertraging"] = g["vertraging"] - stap
		if g["vertraging"] <= EPS:
			g["wacht_vertraging"] = false
			_activeer(id)


# ---------------------------------------------------------------- opslaan

func naar_dict() -> Dictionary:
	var ev: Dictionary = {}
	for id: String in gebeurtenissen:       # alle scenes, zodat 'voorbij' na een niet-lineaire sprong blijft
		ev[id] = (gebeurtenissen[id] as Dictionary).duplicate()
	return {"scene": scene, "tijd": tijd.duplicate(), "gebeurtenissen": ev}


static func _getal(v: Variant, standaard: float) -> float:
	return float(v) if v is int or v is float else standaard


## Zonder cues of signalen. Wat niet in de save staat, begint op 'wacht'.
func uit_dict(d: Dictionary) -> void:
	reset()
	var sc: String = d.get("scene", "")
	if not content.scenes.has(sc):
		return
	scene = sc
	tijd = (content.scenes[sc]["tijd"] as Dictionary).duplicate()
	var ev: Dictionary = d.get("gebeurtenissen", {})
	for id: String in ev:
		if not gebeurtenissen.has(id) or not (ev[id] is Dictionary):
			continue
		var bron: Dictionary = ev[id]
		var g: Dictionary = gebeurtenissen[id]
		g["status"] = bron["status"] if ["wacht", "actief", "voorbij"].has(bron.get("status")) else "wacht"
		g["rest"] = _getal(bron.get("rest"), -1.0)
		g["herhaal_rest"] = _getal(bron.get("herhaal_rest"), 0.0)
		g["vertraging"] = _getal(bron.get("vertraging"), 0.0)
		g["gereed"] = bron.get("gereed", false) == true
		g["wacht_vertraging"] = bron.get("wacht_vertraging", false) == true
