class_name Kwaliteit
extends RefCounted
## De twee kwaliteitsstanden `vol` en `licht` als data (kamerweergave.md, W22-W23; stijlgids 10).
## Zuiver: de weergave past deze waarden toe op viewport, omgeving en lichten.

const VOL: String = "vol"
const LICHT: String = "licht"
const BEWAARPAD: String = "user://instellingen.cfg"
const FPS_GRENS: float = 50.0

const INSTELLINGEN: Dictionary = {
	"vol": {"render_scale": 1.0, "fsr": false, "msaa": 4, "fxaa": false, "volumetrische_mist": true, "ssr": true,
			"ssao": true, "glow": true, "max_schaduw": 6, "schaduw_atlas": 4096, "regen_deeltjes": 6000},
	"licht": {"render_scale": 0.75, "fsr": true, "msaa": 0, "fxaa": true, "volumetrische_mist": false, "ssr": false,
			"ssao": false, "glow": true, "max_schaduw": 3, "schaduw_atlas": 2048, "regen_deeltjes": 2000},
}


static func is_stand(s: String) -> bool:
	return INSTELLINGEN.has(s)


static func instellingen(stand: String) -> Dictionary:
	return (INSTELLINGEN[stand] if INSTELLINGEN.has(stand) else INSTELLINGEN[VOL]).duplicate()


static func andere(stand: String) -> String:
	return LICHT if stand == VOL else VOL


## Ids van de lichten (uit `lichten` van het kamerbestand) die schaduw werpen: de eerste N met `schaduw` (W22).
static func schaduw_lichten(lichten: Array, stand: String) -> Array[String]:
	var uit: Array[String] = []
	var max_n: int = int(instellingen(stand)["max_schaduw"])
	for l: Dictionary in lichten:
		if l.get("schaduw", false) and uit.size() < max_n:
			uit.append(l["id"])
	return uit


## Eerste start (W23): gemiddeld onder 50 fps in de volle stand -> licht.
static func stand_voor_fps(fps_gem: float) -> String:
	return LICHT if fps_gem < FPS_GRENS else VOL


## "" = nog geen keuze opgeslagen.
static func laad(pad: String = BEWAARPAD) -> String:
	var cfg := ConfigFile.new()
	if cfg.load(pad) != OK:
		return ""
	var s: String = str(cfg.get_value("kwaliteit", "stand", ""))
	return s if is_stand(s) else ""


static func bewaar(stand: String, pad: String = BEWAARPAD) -> void:
	var cfg := ConfigFile.new()
	cfg.load(pad)
	cfg.set_value("kwaliteit", "stand", stand)
	cfg.save(pad)
