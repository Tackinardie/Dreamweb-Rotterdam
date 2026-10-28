"""Orkestratie van de validator: laden, schema's, kruisverwijzingsregels."""
from __future__ import annotations

from pathlib import Path

from . import regels_basis as basis
from . import regels_graaf as graaf
from . import regels_objecten as objecten
from .inhoud import Inhoud, laad_inhoud, valideer_schemas
from .wereld import Wereld

REGELS = [
    basis.v01_uniek, basis.v02_bestaan, basis.v03_namen, basis.v04_scope, basis.v06_teksten, basis.v07_cues,
    objecten.v08_beginplek, objecten.v09_inhoud, objecten.v10_acties, objecten.v11_posities, objecten.v12_draagbaar,
    objecten.v13_wederzijds, objecten.v14_scenes, objecten.v15_scenewissel, objecten.v16_niet_lineair,
    objecten.v17_automatisch, objecten.v18_merkbaar, objecten.v19_niveau_zonder_regel,
    graaf.v20_effecten, graaf.v21_doel, graaf.v22_hints, graaf.v23_verkrijgbaar, graaf.v24_ongebruikt,
    graaf.v25_kringen, graaf.v27_dubbele_triggers, graaf.v28_aanname, graaf.v29_gesprekken,
    graaf.v30_dialoog_gebruikt, graaf.v31_apparaat_object,
]


def valideer(wortels: list[Path], cues_pad: Path | None, game_map: Path | None = None) -> Inhoud:
    inh = laad_inhoud(wortels, cues_pad)
    valideer_schemas(inh)
    kapot = {m.bestand for m in inh.meldingen if m.regel == "schema" and m.niveau == "fout"}
    goed = [d for d in inh.docs if d.bestand not in kapot]
    if inh.leeg():
        inh.info("-", "content", "", "geen spelcontent gevonden; alleen de cue-catalogus is gecontroleerd")
    else:
        if not any(d.soort == "spel" for d in goed) and not any(d.bestand.endswith("spel.json") for d in inh.docs):
            inh.fout("V03", "content/spel.json", "", "spel.json ontbreekt")
        if not any(d.soort == "items" for d in goed) and not any(d.bestand.endswith("items.json") for d in inh.docs):
            inh.fout("V03", "content/items.json", "", "items.json ontbreekt")
    w = Wereld.bouw(inh, goed)
    ctx = basis.maak_ctx(w, goed, game_map)
    for regel in REGELS:
        try:
            regel(ctx)
        except Exception as e:  # een kapotte regel mag de rest niet verbergen
            inh.fout("intern", regel.__name__, "", f"{type(e).__name__}: {e}")
    return inh
