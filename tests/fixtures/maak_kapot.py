#!/usr/bin/env python3
"""Genereert de opzettelijk kapotte varianten van de testfixture in tests/fixtures/kapot/<naam>/.

Elke variant is een overlay: alleen de gewijzigde bestanden staan erin, met hetzelfde relatieve pad als
in tests/fixtures/proef/. Gebruik:

  python tests/fixtures/maak_kapot.py          # (her)genereert alle varianten
  python tools/validate.py --content tests/fixtures/proef --overlay tests/fixtures/kapot/<naam> --cues tests/fixtures/proef/cues.json
  python tools/solve.py ch01_proef --content tests/fixtures/proef --overlay tests/fixtures/kapot/<naam>

VARIANTEN is ook de bron voor tests/python/test_kapot.py (welke regel moet falen).
"""
from __future__ import annotations

import copy
import json
import shutil
from pathlib import Path

HIER = Path(__file__).resolve().parent
GOED = HIER / "proef"
KAPOT = HIER / "kapot"
CH = "chapters/ch01_proef/"


def lees(rel: str):
    return json.loads((GOED / rel).read_text(encoding="utf-8"))


def schrijf(naam: str, rel: str, data) -> None:
    pad = KAPOT / naam / rel
    pad.parent.mkdir(parents=True, exist_ok=True)
    pad.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def knoop(puzzels: dict, ident: str) -> dict:
    return next(k for k in puzzels["knopen"] if k["id"] == ident)


# naam -> (regel die moet falen, gewenste tekstfragment in de melding of "")
VARIANTEN: dict[str, tuple[str, str]] = {}
BOUWERS: dict[str, object] = {}


def variant(naam: str, regel: str, fragment: str = ""):
    def deco(f):
        VARIANTEN[naam] = (regel, fragment)
        BOUWERS[naam] = f
        return f
    return deco


@variant("schemafout", "schema", "tekst")
def _(n):
    d = lees(CH + "dialogue/ch01_portier_bezorger.json")
    del d["regels"][0]["tekst"]
    schrijf(n, CH + "dialogue/ch01_portier_bezorger.json", d)


@variant("onbekend_object", "V02", "bestaat_niet")
def _(n):
    d = lees(CH + "rooms/ch01_dak.json")
    d["objecten"].append({"object": "bestaat_niet", "positie": {"x": 1, "y": 1}})
    schrijf(n, CH + "rooms/ch01_dak.json", d)


@variant("geen_tegenstuk", "V13", "bestaat niet")
def _(n):
    d = lees(CH + "rooms/ch01_kantoor.json")
    d["uitgangen"][0]["naar_uitgang"] = "bestaat_niet"
    schrijf(n, CH + "rooms/ch01_kantoor.json", d)


@variant("dubbele_beginplek", "V08", "beginplek")
def _(n):
    d = lees(CH + "rooms/ch01_dak.json")
    d["objecten"].append({"object": "kopje_wit", "positie": {"x": 5, "y": 5}})
    schrijf(n, CH + "rooms/ch01_dak.json", d)


@variant("past_niet", "V09", "max_grootte")
def _(n):
    d = lees(CH + "rooms/ch01_kantoor.json")
    d["objecten"][0]["inhoud"].insert(0, {"object": "pakket"})
    schrijf(n, CH + "rooms/ch01_kantoor.json", d)
    h = lees(CH + "rooms/ch01_hal.json")
    h["objecten"] = [o for o in h["objecten"] if o["object"] != "pakket"]
    schrijf(n, CH + "rooms/ch01_hal.json", h)


@variant("acties_kloppen_niet", "V10", "lees")
def _(n):
    d = lees("items.json")
    next(i for i in d["items"] if i["id"] == "briefje")["acties"] = ["bekijk", "pak"]
    next(i for i in d["items"] if i["id"] == "kopje_wit")["acties"] = ["bekijk"]
    schrijf(n, "items.json", d)


@variant("dubbel_id", "V01", "dubbel")
def _(n):
    d = lees("items.json")
    d["items"].append(copy.deepcopy(d["items"][-1]))
    schrijf(n, "items.json", d)


@variant("buiten_kamer", "V11", "buiten")
def _(n):
    d = lees(CH + "rooms/ch01_dak.json")
    d["objecten"][0]["positie"] = {"x": 20, "y": 1}
    schrijf(n, CH + "rooms/ch01_dak.json", d)


@variant("cue_onbekend", "V07", "ambience.bestaat.niet")
def _(n):
    d = lees(CH + "rooms/ch01_hal.json")
    d["ambience"] = ["ambience.bestaat.niet"]
    schrijf(n, CH + "rooms/ch01_hal.json", d)


@variant("cue_verkeerde_soort", "V07", "doorlopend")
def _(n):
    d = lees(CH + "rooms/ch01_hal.json")
    d["ambience"] = ["deur.open"]
    schrijf(n, CH + "rooms/ch01_hal.json", d)


@variant("tekst_ontbreekt", "V06", "ontbreekt")
def _(n):
    d = lees("tekst/nl/ch01_proef.json")
    del d["teksten"]["kamer.ch01_dak.naam"]
    schrijf(n, "tekst/nl/ch01_proef.json", d)


@variant("engine_tekst_ontbreekt", "V06", "engine")
def _(n):
    d = lees("tekst/nl/algemeen.json")
    del d["teksten"]["systeem.inventaris.vol"]
    schrijf(n, "tekst/nl/algemeen.json", d)


@variant("lokale_flag_buiten_hoofdstuk", "V26", "ch01_bezoeken")
def _(n):
    spel = lees("spel.json")
    spel["hoofdstukken"].append("ch02_extra")
    schrijf(n, "spel.json", spel)
    schrijf(n, "chapters/ch02_extra/chapter.json", {
        "id": "ch02_extra", "nummer": 2, "titel": "hoofdstuk.ch02_extra.titel",
        "start": {"scene": "ch02_s1", "kamer": "ch02_kamer"}, "doel": {"knoop": "ch02_klaar"},
        "scenes": [{"id": "ch02_s1", "tijd": {"dag": 2, "tijd": "00:10"}, "kamers": ["ch02_kamer"]}],
    })
    schrijf(n, "chapters/ch02_extra/rooms/ch02_kamer.json", {
        "id": "ch02_kamer", "naam": "kamer.ch02_kamer.naam", "soort": "binnen",
        "afmeting": {"breedte": 4, "hoogte": 4}, "objecten": [], "uitgangen": [],
    })
    schrijf(n, "chapters/ch02_extra/puzzles.json", {
        "hoofdstuk": "ch02_extra",
        "knopen": [{
            "id": "ch02_klaar", "type": "doel", "pad": "hoofd", "waarom": "Dit leest een flag van een ander hoofdstuk.",
            "trigger": {"automatisch": True}, "vereist": {"flag": "ch01_bezoeken", "minstens": 1},
            "hints": {"vaag": "hint.ch02_klaar.vaag", "richting": "hint.ch02_klaar.richting", "bijna": "hint.ch02_klaar.bijna"},
        }],
    })
    t2 = {"taal": "nl", "domein": "ch02_extra", "teksten": {
        "hoofdstuk.ch02_extra.titel": "Hoofdstuk 2", "kamer.ch02_kamer.naam": "Kamer",
        "hint.ch02_klaar.vaag": "a", "hint.ch02_klaar.richting": "b", "hint.ch02_klaar.bijna": "c"}}
    schrijf(n, "tekst/nl/ch02_extra.json", t2)


@variant("drie_niet_lineaire_momenten", "V16", "niet_lineair")
def _(n):
    d = lees(CH + "chapter.json")
    for i, m in enumerate(("m1", "m2", "m3"), 3):
        d["scenes"].append({"id": f"ch01_s{i}", "tijd": {"dag": 1, "tijd": "08:00"}, "kamers": ["ch01_hal"], "niet_lineair": m})
    schrijf(n, CH + "chapter.json", d)


@variant("terug_in_de_tijd", "V15", "terug in de tijd")
def _(n):
    d = lees(CH + "chapter.json")
    d["scenes"][1]["tijd"] = {"dag": 1, "tijd": "00:01"}
    schrijf(n, CH + "chapter.json", d)


@variant("gebeurtenis_onmerkbaar", "V18", "merkbaar")
def _(n):
    d = lees(CH + "chapter.json")
    ev = d["scenes"][0]["gebeurtenissen"][0]
    del ev["cue_start"], ev["cue_einde"]
    schrijf(n, CH + "chapter.json", d)
    h = lees(CH + "rooms/ch01_hal.json")
    h["npcs"][0]["aanwezig"] = {"niet": {"flag": "ch01_pauze_bekend"}}
    schrijf(n, CH + "rooms/ch01_hal.json", h)


@variant("kamer_zonder_scene", "V14", "geen enkele scène")
def _(n):
    d = lees(CH + "chapter.json")
    d["scenes"][0]["kamers"] = ["ch01_hal", "ch01_kantoor"]
    d["scenes"][1]["kamers"] = ["ch01_hal"]
    schrijf(n, CH + "chapter.json", d)


@variant("twee_doelknopen", "V21", "doel-knopen")
def _(n):
    p = lees(CH + "puzzles.json")
    knoop(p, "ch01_pak_rapport")["type"] = "doel"
    schrijf(n, CH + "puzzles.json", p)


@variant("hints_ontbreken", "V22", "hints")
def _(n):
    p = lees(CH + "puzzles.json")
    del knoop(p, "ch01_lees_briefje")["hints"]
    schrijf(n, CH + "puzzles.json", p)


@variant("token_nooit_gegeven", "V23", "code_kluis")
def _(n):
    p = lees(CH + "puzzles.json")
    knoop(p, "ch01_lees_briefje")["effecten"] = []
    schrijf(n, CH + "puzzles.json", p)


@variant("conditiekring", "V25", "kring")
def _(n):
    d = lees(CH + "chapter.json")
    d["condities"]["ch01_a"] = {"conditie": "ch01_b"}
    d["condities"]["ch01_b"] = {"conditie": "ch01_a"}
    schrijf(n, CH + "chapter.json", d)


@variant("dialoog_ongebruikt", "V30", "NPC")
def _(n):
    h = lees(CH + "rooms/ch01_hal.json")
    h["npcs"][0]["gesprekken"] = [{"dialoog": "ch01_portier_praat"}]
    schrijf(n, CH + "rooms/ch01_hal.json", h)


@variant("spreker_onbekend", "V29", "deelnemer")
def _(n):
    spel = lees("spel.json")
    spel["personages"].append({"id": "bewaker", "naam": "personage.bewaker.naam"})
    schrijf(n, "spel.json", spel)
    t = lees("tekst/nl/algemeen.json")
    t["teksten"]["personage.bewaker.naam"] = "de bewaker"
    schrijf(n, "tekst/nl/algemeen.json", t)
    d = lees(CH + "dialogue/ch01_portier_bezorger.json")
    d["regels"][0]["spreker"] = "bewaker"
    schrijf(n, CH + "dialogue/ch01_portier_bezorger.json", d)


# Varianten voor de oplosser (valideren wel, maar zijn onoplosbaar of hebben een doodlopende staat)
OPLOSSER: dict[str, str] = {}


def oplosser_variant(naam: str, verwacht: str):
    def deco(f):
        OPLOSSER[naam] = verwacht
        BOUWERS[naam] = f
        return f
    return deco


@oplosser_variant("doodlopend_rapport_weg", "doodlopend")
def _(n):
    p = lees(CH + "puzzles.json")
    k = knoop(p, "ch01_koffie_weg")
    k["trigger"] = {"gebruik": "rapport", "met": "prullenbak"}
    k["vereist"] = {"heeft": "rapport"}
    k["effecten"] = [{"verwijder_object": "rapport"}]
    schrijf(n, CH + "puzzles.json", p)


@oplosser_variant("doodlopend_pas_achtergelaten", "doodlopend")
def _(n):
    k = lees(CH + "rooms/ch01_kantoor.json")
    k["uitgangen"][0]["vereist"] = {"niveau": "proef.kantoor"}
    k["uitgangen"][0]["geweigerd"] = "uitgang.ch01_hal.deur_kantoor.geweigerd"
    k["uitgangen"][1]["bestemmingen"][0]["vereist"] = {"niveau": "proef.kantoor"}
    schrijf(n, CH + "rooms/ch01_kantoor.json", k)


@oplosser_variant("onoplosbaar_code_ontbreekt", "onoplosbaar")
def _(n):
    p = lees(CH + "puzzles.json")
    knoop(p, "ch01_lees_briefje")["effecten"] = []
    schrijf(n, CH + "puzzles.json", p)


def main() -> None:
    """Schrijft alle varianten naar KAPOT (tests wijzen dit naar een tijdelijke map)."""
    if KAPOT.exists():
        shutil.rmtree(KAPOT)
    for naam, bouw in BOUWERS.items():
        bouw(naam)
    print(f"{len(VARIANTEN)} validatorvarianten en {len(OPLOSSER)} oplosservarianten in {KAPOT}")


if __name__ == "__main__":
    main()
