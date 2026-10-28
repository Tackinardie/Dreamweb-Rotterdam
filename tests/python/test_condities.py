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
