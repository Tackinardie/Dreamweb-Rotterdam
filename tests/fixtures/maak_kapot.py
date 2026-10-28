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
VARIANTEN: dict[str, tuple[str, str, str]] = {}
BOUWERS: dict[str, object] = {}
# Geldige overlays voor GUT- en oplossertests (geen validatorfout verwacht)
SCENARIOS: list[str] = []


def variant(naam: str, regel: str, fragment: str = "", niveau: str = "fout"):
    def deco(f):
        VARIANTEN[naam] = (regel, fragment, niveau)
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



# ---------------------------------------------------------------- hulp voor extra hoofdstukken

def hoofdstuk_bouw(n, nummer, naam, knopen, flags=None, tokens=None, aanname=None, extra_kamer_objecten=None):
    """Voegt een klein hoofdstuk (een kamer, een scene, een puzzelgraaf) toe aan overlay n en spel.json."""
    h = f"ch{nummer:02d}_{naam}"
    pad_spel = KAPOT / n / "spel.json"
    spel = json.loads(pad_spel.read_text(encoding="utf-8")) if pad_spel.exists() else lees("spel.json")
    spel["hoofdstukken"].append(h)
    schrijf(n, "spel.json", spel)
    ch = {
        "id": h, "nummer": nummer, "titel": f"hoofdstuk.{h}.titel",
        "start": {"scene": f"ch{nummer:02d}_s1", "kamer": f"ch{nummer:02d}_kamer"}, "doel": {"knoop": f"ch{nummer:02d}_klaar"},
        "scenes": [{"id": f"ch{nummer:02d}_s1", "tijd": {"dag": 2, "tijd": "00:10"}, "kamers": [f"ch{nummer:02d}_kamer"]}],
    }
    if flags:
        ch["flags"] = flags
    if tokens:
        ch["tokens"] = tokens
    if aanname:
        ch["aanname_bij_start"] = aanname
    schrijf(n, f"chapters/{h}/chapter.json", ch)
    schrijf(n, f"chapters/{h}/rooms/ch{nummer:02d}_kamer.json", {
        "id": f"ch{nummer:02d}_kamer", "naam": f"kamer.ch{nummer:02d}_kamer.naam", "soort": "binnen",
        "afmeting": {"breedte": 4, "hoogte": 4}, "objecten": [], "uitgangen": [],
    })
    doel = {
        "id": f"ch{nummer:02d}_klaar", "type": "doel", "pad": "hoofd", "waarom": "Het doel van dit proefhoofdstuk.",
        "trigger": {"gebruik": "kopje_wit"},
        "hints": {k: f"hint.ch{nummer:02d}_klaar.{k}" for k in ("vaag", "richting", "bijna")},
    }
    schrijf(n, f"chapters/{h}/puzzles.json", {"hoofdstuk": h, "knopen": knopen + [doel]})
    teksten = {f"hoofdstuk.{h}.titel": "Titel", f"kamer.ch{nummer:02d}_kamer.naam": "Kamer"}
    teksten.update({f"hint.ch{nummer:02d}_klaar.{k}": k for k in ("vaag", "richting", "bijna")})
    for t in (tokens or []):
        teksten[t["notitie"]] = "Notitie"
    schrijf(n, f"tekst/nl/{h}.json", {"taal": "nl", "domein": h, "teksten": teksten})
    return h


def knoop_zet_flag(ident, flag, waarde=True, trigger=None, vereist=None):
    k = {"id": ident, "type": "actie", "pad": "zij", "waarom": "Een knoop voor de scope-test.",
         "trigger": trigger or {"automatisch": True}, "effecten": [{"zet_flag": flag, "waarde": waarde}]}
    if vereist:
        k["vereist"] = vereist
    return k


@variant("id_wijkt_af", "V03", "bestandsnaam")
def _(n):
    d = lees(CH + "rooms/ch01_dak.json")
    d["id"] = "ch01_dakx"
    schrijf(n, CH + "rooms/ch01_dak.json", d)


@variant("scope_ander_hoofdstuk", "V04", "hoort bij hoofdstuk 02")
def _(n):
    hoofdstuk_bouw(n, 2, "extra", [])
    p = lees(CH + "puzzles.json")
    p["knopen"].insert(0, {"id": "ch01_naar_ch02", "type": "actie", "pad": "zij", "waarom": "Verwijst naar een kamer van een ander hoofdstuk.",
                           "trigger": {"betreed": "ch02_kamer"}, "effecten": [{"zet_flag": "ch01_bezoeken", "waarde": 1}]})
    schrijf(n, CH + "puzzles.json", p)


@variant("lokaal_zonder_prefix", "V05", "prefix")
def _(n):
    d = lees(CH + "chapter.json")
    d["flags"].append({"id": "zonder_prefix", "type": "bool", "start": False})
    schrijf(n, CH + "chapter.json", d)


@variant("te_veel_onmisbaar", "V12", "slots", "waarschuwing")
def _(n):
    p = lees(CH + "puzzles.json")
    alle = ["kopje_wit", "kopje_blauw", "koffiekop", "briefje", "pakket", "doos", "jas", "bezorgtas", "rapport"]
    p["knopen"].insert(0, {"id": "ch01_veel", "type": "actie", "pad": "zij", "waarom": "Vraagt om veel dragende objecten tegelijk.",
                           "trigger": {"bekijk": "kast"}, "vereist": {"alle": [{"heeft": x} for x in alle]},
                           "effecten": [{"zet_flag": "ch01_dak_bekend"}]})
    schrijf(n, CH + "puzzles.json", p)


def _scenewissel_knopen(p):
    """Drie knopen met een scenewissel die het kantoor laat wegvallen: trigger betreed, dialoog en gebruik."""
    d = lees(CH + "chapter.json")
    d["scenes"].append({"id": "ch01_s3_klein", "tijd": {"dag": 1, "tijd": "08:00"}, "kamers": ["ch01_hal", "ch01_dak"]})
    for f in ("betreed", "dialoog", "gebruik"):
        d["flags"].append({"id": f"ch01_wissel_{f}", "type": "bool", "start": False})
    triggers = {"betreed": {"betreed": "ch01_dak"}, "dialoog": {"dialoog": "ch01_portier_bezorger", "regel": "r_hoi"},
                "gebruik": {"gebruik": "kopje_wit"}}
    for f, t in triggers.items():
        p["knopen"].insert(0, {"id": f"ch01_wissel_{f}", "type": "actie", "pad": "zij", "waarom": "Een scenewissel die het kantoor laat wegvallen.",
                               "trigger": t, "effecten": [{"zet_flag": f"ch01_wissel_{f}"}, {"naar_scene": "ch01_s3_klein"}]})
    return d


@variant("scenewissel_geweigerd", "V17", "wegvallen")
def _(n):
    p = lees(CH + "puzzles.json")
    d = _scenewissel_knopen(p)
    schrijf(n, CH + "chapter.json", d)
    schrijf(n, CH + "puzzles.json", p)


@variant("geef_voor_scene", "V17", "vóór de naar_scene", "waarschuwing")
def _(n):
    p = lees(CH + "puzzles.json")
    k = knoop(p, "ch01_klaar")
    k["effecten"].insert(0, {"geef_object": "kopje_blauw"})
    schrijf(n, CH + "puzzles.json", p)


@variant("niveau_zonder_regel", "V19", "niveau", "waarschuwing")
def _(n):
    d = lees(CH + "rooms/ch01_hal.json")
    del d["uitgangen"][0]["vereist"]
    schrijf(n, CH + "rooms/ch01_hal.json", d)


@variant("effecten_buiten_puzzels", "V20", "puzzles.json")
def _(n):
    d = lees(CH + "dialogue/ch01_portier_bezorger.json")
    d["effecten"] = [{"zet_flag": "ch01_dak_bekend"}]
    schrijf(n, CH + "dialogue/ch01_portier_bezorger.json", d)


@variant("token_ongebruikt", "V24", "nergens gebruikt", "waarschuwing")
def _(n):
    d = lees(CH + "chapter.json")
    d["tokens"].append({"id": "spoor", "categorie": "plek", "notitie": "token.spoor"})
    schrijf(n, CH + "chapter.json", d)
    t = lees("tekst/nl/ch01_proef.json")
    t["teksten"]["token.spoor"] = "Een spoor."
    schrijf(n, "tekst/nl/ch01_proef.json", t)
    p = lees(CH + "puzzles.json")
    knoop(p, "ch01_lees_briefje")["effecten"].append({"geef_token": "spoor"})
    schrijf(n, CH + "puzzles.json", p)


@variant("dubbele_trigger", "V27", "dezelfde trigger", "waarschuwing")
def _(n):
    p = lees(CH + "puzzles.json")
    p["knopen"].insert(1, {"id": "ch01_lees_nog_eens", "type": "feit", "pad": "zij", "waarom": "Dezelfde trigger zonder uitsluiting.",
                           "trigger": {"lees": "briefje"}, "effecten": [{"geef_token": "kluis_plek"}]})
    schrijf(n, CH + "puzzles.json", p)


@variant("aanname_object_weg", "V28", "niet bereikbaar")
def _(n):
    hoofdstuk_bouw(n, 2, "extra", [], aanname={"inventaris": [{"object": "rapport"}]})


@variant("aanname_token_onbekend", "V28", "niet gegeven")
def _(n):
    hoofdstuk_bouw(n, 2, "extra", [], tokens=[{"id": "ander_token", "categorie": "plek", "notitie": "token.ander_token"}],
                   aanname={"tokens": ["ander_token"]})


@variant("twee_apparaten_zelfde_object", "V31", "hoort al bij")
def _(n):
    d = lees(CH + "devices/ch01_laptop.json")
    d["id"] = "ch01_laptop2"
    schrijf(n, CH + "devices/ch01_laptop2.json", d)


def scenario(naam: str):
    def deco(f):
        SCENARIOS.append(naam)
        BOUWERS[naam] = f
        return f
    return deco


@scenario("scope_hoofdstukken")
def _(n):
    """Hub (ch00_hub) en een tweede hoofdstuk, elk met een automatische knoop; ch02 gebruikt kopje_blauw in een trigger."""
    spel = lees("spel.json")
    spel["flags"].append({"id": "hub_vlag", "type": "bool", "start": False})
    spel["hoofdstukken"] = ["ch00_hub"] + spel["hoofdstukken"]
    schrijf(n, "spel.json", spel)
    hoofdstuk_bouw(n, 0, "hub", [knoop_zet_flag("ch00_auto", "hub_vlag")])
    hoofdstuk_bouw(n, 2, "extra", [knoop_zet_flag("ch02_auto", "ch02_vlag"),
                                   {"id": "ch02_blauw", "type": "actie", "pad": "zij", "waarom": "Gebruikt een object alleen in dit hoofdstuk.",
                                    "trigger": {"gebruik": "kopje_blauw"}, "effecten": [{"zet_flag": "ch02_vlag"}]}],
                   flags=[{"id": "ch02_vlag", "type": "bool", "start": False}])
    # de hub-spel.json wordt door hoofdstuk_bouw aangevuld; zet de volgorde terug op hub, ch01, ch02
    sp = json.loads((KAPOT / n / "spel.json").read_text(encoding="utf-8"))
    sp["hoofdstukken"] = ["ch00_hub", "ch01_proef", "ch02_extra"]
    schrijf(n, "spel.json", sp)


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
