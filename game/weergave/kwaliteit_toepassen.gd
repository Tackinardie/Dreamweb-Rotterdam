class_name KwaliteitToepassen
extends RefCounted
## Past een kwaliteitsstand (Kwaliteit) toe op viewport, omgeving en lichten (kamerweergave.md, W22).
## Contour, vergrootglas, close-up en het licht zonder schaduw blijven in beide standen gelijk.


static func op_viewport(stand: String, vp: Viewport) -> void:
	var k: Dictionary = Kwaliteit.instellingen(stand)
	vp.scaling_3d_scale = float(k["render_scale"])
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if k["fsr"] else Viewport.SCALING_3D_MODE_BILINEAR
	vp.msaa_3d = Viewport.MSAA_4X if int(k["msaa"]) == 4 else Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if k["fxaa"] else Viewport.SCREEN_SPACE_AA_DISABLED
	vp.positional_shadow_atlas_size = int(k["schaduw_atlas"])


static func op_omgeving(stand: String, env: Environment) -> void:
	var k: Dictionary = Kwaliteit.instellingen(stand)
	env.volumetric_fog_enabled = k["volumetrische_mist"]
	env.ssr_enabled = k["ssr"]
	env.ssao_enabled = k["ssao"]
	env.glow_enabled = k["glow"]


## Alleen de eerste N lichten met `schaduw` in het kamerbestand werpen schaduw.
static func op_lichten(stand: String, root: KamerRoot) -> void:
	var toegestaan: Array[String] = Kwaliteit.schaduw_lichten(root.kamer.get("lichten", []), stand)
	for id: String in root.licht_nodes:
		(root.licht_nodes[id] as Light3D).shadow_enabled = toegestaan.has(id)


static func alles(stand: String, vp: Viewport, root: KamerRoot) -> void:
	op_viewport(stand, vp)
	if root != null:
		if root.omgeving != null:
			op_omgeving(stand, root.omgeving)
		op_lichten(stand, root)
