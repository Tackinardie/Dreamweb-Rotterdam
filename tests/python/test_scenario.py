"""SF-19, SF-20, SF-22, SF-23 en de oplosserkant van OI-14: scope, geweigerde scenewissel, onmisbaar, beperkingenblok."""
import json
import subprocess
import sys
from pathlib import Path

import pytest

from conftest import KAPOT, PROEF, REPO
from onderstad.inhoud import laad_inhoud, valideer_schemas
from onderstad.oplosser import los_op
from onderstad.oplosser_sim import Model, Sim, onmisbare_items
from onderstad.wereld import Wereld, hoofdstuk_nummer


def laad(overlay=None):
    wortels = [PROEF] + ([KAPOT / overlay] if overlay else [])
    inh = laad_inhoud(wortels, None)
    valideer_schemas(inh)
    assert not [m for m in inh.meldingen if m.niveau == "fout"]
    return Wereld.bouw(inh, inh.docs), inh.docs


def model(overlay=None):
    w, docs = laad(overlay)
    return Model.bouw(w, "ch01_proef", docs), w, docs


# ---- SF-19 / OI-14 (oplosserkant): een geweigerde scenewissel laat de knoop niet vuren

@pytest.mark.parametrize("soort,trigger", [
    ("betreed", {"betreed": "ch01_dak"}),
    ("dialoog", {"dialoog": "ch01_portier_bezorger", "regel": "r_hoi"}),
    ("gebruik", {"gebruik": "kopje_wit"}),
])
def test_sf19_geweigerde_scenewissel_laat_de_knoop_niet_vuren(soort, trigger):
    m, _, _ = model("scenewissel_geweigerd")
    sim = Sim(m)
    assert sim.plek["rapport"] == "kluisje" and sim.plek["kluisje"] == "ch01_kantoor"
    assert sim.vuur_trigger(trigger) is None, "rapport ligt nog in het kantoor dat in s3 wegvalt"
    assert f"ch01_wissel_{soort}" not in sim.knopen
    assert sim.flag_waarde(f"ch01_wissel_{soort}") is False
    assert sim.scene == "ch01_s1_nacht"
    sim.plek["rapport"] = "inventaris"             # opgehaald
    assert sim.vuur_trigger(trigger) == f"ch01_wissel_{soort}"
    assert sim.flag_waarde(f"ch01_wissel_{soort}") is True
    assert sim.scene == "ch01_s3_klein"


# ---- SF-20: alleen het eigen hoofdstuk en de hub

def test_sf20_scope_hub_wel_ander_hoofdstuk_niet():
    m, w, _ = model("scope_hoofdstukken")
    ids = [k["id"] for k in m.knopen]
    assert "ch00_auto" in ids and "ch02_auto" not in ids
    assert ids.index("ch01_klaar") < ids.index("ch00_auto"), "eerst het huidige hoofdstuk, dan de hub"
    sim = Sim(m)
    assert sim.normaliseer()
    assert "ch00_auto" in sim.knopen and sim.flag_waarde("hub_vlag") is True
    assert "ch02_auto" not in sim.knopen and sim.flag_waarde("ch02_vlag") is False


def test_sf20_oplosser_van_ander_hoofdstuk_ziet_de_hub_niet_van_ch01():
    w, docs = laad("scope_hoofdstukken")
    m2 = Model.bouw(w, "ch02_extra", docs)
    ids = [k["id"] for k in m2.knopen]
    assert "ch02_auto" in ids and "ch00_auto" in ids and "ch01_klaar" not in ids
    mh = Model.bouw(w, "ch00_hub", docs)
    assert [k["id"] for k in mh.knopen] == ["ch00_auto", "ch00_klaar"], "de hub zelf alleen zijn eigen knopen"


# ---- SF-22: afgeleide onmisbare objecten

def _nodig(overlay=None):
    w, docs = laad(overlay)
    scope = [d for d in docs if d.hoofdstuk is None or hoofdstuk_nummer(d.hoofdstuk) in ("01", "00")]
    return sorted(onmisbare_items(w, scope)[0])


def test_sf22_onmisbare_lijst_komt_overeen_met_de_gedeelde_verwachte_waarde():
    verwacht = json.loads((REPO / "tests" / "fixtures" / "onmisbaar.json").read_text(encoding="utf-8"))
    assert _nodig() == verwacht["proef"]
    scope = _nodig("scope_hoofdstukken")
    assert scope == verwacht["scope_hoofdstukken"]
    assert "kopje_blauw" not in scope, "komt alleen in een ander hoofdstuk voor"
    assert "kopje_wit" in scope, "komt voor in de hub"


# ---- SF-23: beperkingenblok

def _solve(*args):
    return subprocess.run([sys.executable, str(REPO / "tools" / "solve.py"), "ch01_proef", "--content", str(PROEF), *args],
                          capture_output=True, text=True, encoding="utf-8")


def test_sf23_tekstuitvoer_bevat_het_beperkingenblok_met_de_leg_limiet():
    r = _solve("--leg-limiet", "0")
    assert "Beperkingen van dit bewijs:" in r.stdout
    assert "- leg-limiet: 0 onmisbare objecten tegelijk buiten hun beginplek" in r.stdout
    assert "- niet gemodelleerd: stop_in, uitpakken, inventariscapaciteit" in r.stdout
    assert "- aanname: binnen een actieve gebeurtenis lukt elke actie die hem vereist" in r.stdout
    assert "- verkende toestanden: " in r.stdout and "limiet niet bereikt" in r.stdout


def test_sf23_json_bevat_beperkingen():
    r = _solve("--leg-limiet", "0", "--json")
    d = json.loads(r.stdout)
    b = d["beperkingen"]
    assert b["leg_limiet"] == 0 and "stop_in" in b["niet_gemodelleerd"] and not b["max_staten_bereikt"]
    assert b["verkende_toestanden"] > 100 and d["uitslag"] == "groen"


def test_sf23_max_staten_bereikt_geeft_onvolledig_en_exitcode_niet_nul():
    r = _solve("--leg-limiet", "0", "--max-staten", "300")
    assert r.returncode != 0
    assert "uitslag ONVOLLEDIG" in r.stdout and "BEREIKT" in r.stdout
    j = json.loads(_solve("--leg-limiet", "0", "--max-staten", "300", "--json").stdout)
    assert j["uitslag"] == "onvolledig" and j["beperkingen"]["max_staten_bereikt"] is True


def test_sf23_leg_limiet_twee_staat_in_het_blok():
    j = json.loads(_solve("--leg-limiet", "2", "--max-staten", "50", "--json").stdout)
    assert j["beperkingen"]["leg_limiet"] == 2
