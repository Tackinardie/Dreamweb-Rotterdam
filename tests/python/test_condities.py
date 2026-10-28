"""SF-01 t/m SF-07 voor de Python-kant van de conditie-evaluator (GUT draait dezelfde set in tests/gut/)."""
import json

import pytest

from conftest import REPO
from onderstad.condities import DictToestand, draai_testset, evalueer, laad_testset

TESTSET = laad_testset(REPO / "tests" / "fixtures" / "condities.json")
VORMEN = ["alle", "een_van", "niet", "heeft", "ligt", "token", "flag", "knoop", "kamer", "scene", "gebeurtenis",
          "kloktijd", "scenetijd", "niveau", "apparaat", "conditie"]


def test_sf01_alle_gevallen_geven_de_verwachte_uitkomst():
    verkeerd = [naam for naam, verwacht, werkelijk in draai_testset(TESTSET) if verwacht != werkelijk]
    assert verkeerd == []
    assert len(TESTSET["gevallen"]) > 50


@pytest.mark.parametrize("vorm", VORMEN)
def test_sf01_elke_vorm_heeft_een_waar_en_een_onwaar_geval(vorm):
    gevallen = [g for g in TESTSET["gevallen"] if isinstance(g["conditie"], dict) and vorm in g["conditie"]]
    assert any(g["verwacht"] for g in gevallen), f"{vorm}: geen waar-geval"
    assert any(not g["verwacht"] for g in gevallen), f"{vorm}: geen onwaar-geval"


def test_sf06_onbekende_id_geeft_onwaar_en_foutregel():
    aantal = 0
    for g in TESTSET["gevallen"]:
        if g.get("geeft_foutregel"):
            t = DictToestand(g["toestand"], TESTSET["benoemd"])
            evalueer(g["conditie"], t)
            assert t.fouten, g["naam"]
            aantal += 1
    assert aantal >= 5


def test_sf07_evalueren_verandert_de_toestand_niet():
    for g in TESTSET["gevallen"]:
        t = DictToestand(g["toestand"], TESTSET["benoemd"])
        voor = json.dumps(g["toestand"], sort_keys=True)
        evalueer(g["conditie"], t)
        assert json.dumps(g["toestand"], sort_keys=True) == voor


def test_afwezige_en_lege_condities():
    t = DictToestand({}, {})
    assert evalueer(None, t) is True
    assert evalueer({"alle": []}, t) is False and t.fouten


# ---- M8: dezelfde testset tegen de productiecontext van de oplosser (Sim)

def sim_uit_toestand(t, benoemd):
    from types import SimpleNamespace

    from onderstad.condities import Toestand
    from onderstad.oplosser_sim import Sim

    niveaus = {}
    for i, it in t["items"].items():
        for n in it.get("geeft_niveaus", []):
            niveaus.setdefault(n, []).append(i)
    w = SimpleNamespace(
        items=t["items"], flags={f: {"start": v} for f, v in t["flag_start"].items()},
        gebeurtenissen={e: {} for e in t["gebeurtenissen"]}, condities=benoemd, apparaten={a: {} for a in t["apparaten"]})
    m = SimpleNamespace(w=w, scenes={t["scene"]: {"tijd": {"dag": t["dag"], "tijd": t["tijd"]}}}, niveau_bronnen=niveaus)
    sim = Sim.__new__(Sim)
    Toestand.__init__(sim)
    sim.m, sim.kamer, sim.scene = m, t["kamer"], t["scene"]
    sim.plek, sim.open, sim.tokens = dict(t["plekken"]), set(), set(t["tokens"])
    sim.flags, sim.knopen, sim.ev = dict(t["flags"]), set(t["knopen"]), dict(t["gebeurtenissen"])
    sim.ontgrendeld = {a for a, st in t["apparaten"].items() if st == "ontgrendeld"}
    sim.net_actief, sim.opgelost_nu = [], []
    return sim


def test_m8_gedeelde_testset_geeft_dezelfde_uitkomsten_in_de_oplosser():
    verkeerd = []
    for g in TESTSET["gevallen"]:
        sim = sim_uit_toestand(g["toestand"], TESTSET["benoemd"])
        if evalueer(g["conditie"], sim) != g["verwacht"]:
            verkeerd.append(g["naam"])
        if g.get("geeft_foutregel"):
            assert sim.fouten, g["naam"]
    assert verkeerd == []
