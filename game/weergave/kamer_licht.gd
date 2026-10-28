class_name KamerLicht
extends RefCounted
## Omgeving en lichten van een kamer (kamerweergave.md, W8; stijlgids 5.1 en 10). Alleen de vaste kamerlichten
## uit de data; ambient en maanlicht zijn voor elke kamer gelijk. Kwaliteit: zie KwaliteitToepassen.

const AMBIENT: String = "#4A6590"
const MAAN: String = "#6E86A8"


static func omgeving(buiten: bool) -> Environment:
	var e := Environment.new()
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()   # alleen als reflectiebron; de achtergrond blijft het kader
	psm.sky_top_color = Color.html("#151B2C")
	psm.sky_horizon_color = Color.html("#3E5578")
	psm.ground_horizon_color = Color.html("#3E5578")
	psm.ground_bottom_color = Color.html("#151B2C")
	psm.sky_energy_multiplier = 4.0
	sky.sky_material = psm
	e.sky = sky
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.html(Placeholder.KADER)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.html(AMBIENT)
	e.ambient_light_energy = 1.9 if buiten else 1.6
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.0
	e.glow_intensity = 0.8
	e.glow_strength = 1.1
	e.glow_bloom = 0.0
	e.glow_hdr_threshold = 1.0
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	e.ssr_max_steps = 160
	e.ssr_fade_in = 0.05
	e.ssr_fade_out = 3.0
	e.ssr_depth_tolerance = 1.2
	e.ssao_radius = 1.2
	e.ssao_intensity = 2.0
	e.volumetric_fog_density = 0.02
	e.volumetric_fog_albedo = Color.html("#8A93A8")
	e.volumetric_fog_length = 70.0
	e.volumetric_fog_anisotropy = 0.55
	e.volumetric_fog_ambient_inject = 0.0
	e.adjustment_enabled = true
	e.adjustment_saturation = 0.92
	e.adjustment_contrast = 1.06
	return e


static func bouw(root: KamerRoot, spel: Spel, parent: Node3D) -> void:
	var we := WorldEnvironment.new()
	we.name = "omgeving"
	root.omgeving = omgeving(root.kamer.get("soort", "binnen") == "buiten")
	we.environment = root.omgeving
	parent.add_child(we)
	root.wereld_omgeving = we
	var maan := DirectionalLight3D.new()
	maan.name = "maanlicht"
	maan.light_color = Color.html(MAAN)
	maan.light_energy = 0.2
	maan.shadow_enabled = false
	maan.rotation_degrees = Vector3(-55.0, 150.0, 0.0)
	parent.add_child(maan)
	var lichten: Array = root.kamer.get("lichten", [])
	if lichten.is_empty():
		spel.log_fout("kamer '%s' heeft geen lichten: alleen ambient en maanlicht" % root.kamer_id)
	var met_schaduw: int = lichten.filter(func(l: Dictionary) -> bool: return l.get("schaduw", false)).size()
	if met_schaduw > Kwaliteit.instellingen(Kwaliteit.VOL)["max_schaduw"]:
		spel.log_fout("kamer '%s': %d lichten met schaduw; alleen de eerste %d werpen schaduw (licht: %d)" % [root.kamer_id,
				met_schaduw, Kwaliteit.instellingen(Kwaliteit.VOL)["max_schaduw"], Kwaliteit.instellingen(Kwaliteit.LICHT)["max_schaduw"]])
	var n: int = 0
	for l: Dictionary in lichten:
		if n >= 16:
			spel.log_fout("kamer '%s': meer dan 16 lichten, de rest wordt genegeerd" % root.kamer_id)
			break
		parent.add_child(_licht(root, l))
		parent.add_child(_lamp(l, _positie(root, l)))
		n += 1


static func _positie(root: KamerRoot, l: Dictionary) -> Vector3:
	var p: Vector3 = Vak.naar_3d(Vak.uit_positie(l["positie"]))
	p.y = float(l["hoogte"]) if l.has("hoogte") else root.plafond - 0.2
	return p


static func _licht(root: KamerRoot, l: Dictionary) -> Light3D:
	var licht: Light3D
	if l["soort"] == "spot":
		var s := SpotLight3D.new()
		s.spot_range = float(l.get("bereik", 5.0))
		s.spot_angle = float(l.get("kegel", 60.0)) * 0.5
		s.spot_attenuation = 0.8
		s.rotation_degrees = Vector3(-90.0, 0.0, 0.0)    # recht omlaag
		licht = s
	else:
		var o := OmniLight3D.new()
		o.omni_range = float(l.get("bereik", 5.0))
		o.omni_attenuation = 1.5
		licht = o
	licht.name = l["id"]
	licht.position = _positie(root, l)
	licht.light_color = Color.html(l["kleur"])
	licht.light_energy = float(l["energie"])
	root.licht_nodes[l["id"]] = licht
	return licht


## Bolletje van 0,1 m, emissief in de lichtkleur, op de lichtpositie (W6, Lamp).
static func _lamp(l: Dictionary, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "lamp_" + str(l["id"])
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = Placeholder.materiaal(l["kleur"], 4.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	return mi
