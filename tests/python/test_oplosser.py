"""De oplosser (SF-18): de fixture is oplosbaar, kapotte varianten hebben een doodlopende staat of zijn onoplosbaar."""
import subprocess
import sys

import pytest

import maak_kapot
from conftest import KAPOT, PROEF, REPO
from onderstad.inhoud import laad_inhoud, valideer_schemas
from onderstad.oplosser import los_op
from onderstad.wereld import Wereld


def los(naam=None, **kw):
    wortels = [PROEF] + ([KAPOT / naam] if naam else [])
    inh = laad_inhoud(wortels, None)
    valideer_schemas(inh)
    assert not [m for m in inh.meldingen if m.niveau == "fout"]
    return los_op(Wereld.bouw(inh, inh.docs), "ch01_proef", inh.docs, **kw)


@pytest.fixture(scope="module")
def goed():
    return los()


def test_sf18_fixture_is_oplosbaar_met_kortste_route_en_zonder_doodlopende_staten(goed):
    assert goed.oplosbaar
    assert goed.aantal_doodlopend == 0 and not goed.doodlopend
    assert not goed.afgekapt and not goed.problemen
    assert len(goed.route) == 8, goed.route
    assert goed.route[0] == "open kast"
    assert goed.route[-1] == "geef rapport aan portier"
    assert "open kluisje" in goed.route and "pak rapport" in goed.route


def test_route_is_echt_uitvoerbaar_en_kort(goed):
    # via het pasje in de jas (niveau) in plaats van de pauze van de portier
    assert "pak jas" in goed.route
    assert not any(stap.startswith("praat") for stap in goed.route)


def test_alle_knopen_kunnen_vuren_en_alle_tokens_worden_gegeven(goed):
    assert goed.nooit_vurend == []
    assert goed.tokens_nooit_gegeven == []
    assert goed.tokens_nooit_gebruikt == []


def test_hoogstens_drie_hoofdknopen_tegelijk_open(goed):
    assert 1 <= goed.max_open_hoofd <= 3


@pytest.mark.parametrize("naam", [n for n, v in maak_kapot.OPLOSSER.items() if v == "doodlopend"])
def test_sf18_kapotte_fixture_meldt_doodlopende_staat_met_pad(naam):
    # het achterlaten van de pas vraagt dat één object mag worden neergelegd; het verwijderen van het rapport niet
    r = los(naam, leg_limiet=1 if naam == "doodlopend_pas_achtergelaten" else 0)
    assert r.oplosbaar, "er is nog steeds een route naar het doel"
    assert r.aantal_doodlopend >= 1
    d = r.doodlopend[0]
    assert d.pad and d.oorzaak
    if naam == "doodlopend_rapport_weg":
        assert "rapport" in d.oorzaak
        assert d.pad[-1] == "gebruik rapport met prullenbak"
    else:
        assert "uitgangen" in d.oorzaak and d.pad[-1].startswith("loop naar ch01_kantoor")


def test_onoplosbaar_wordt_gemeld_met_nooit_vurende_knopen():
    r = los("onoplosbaar_code_ontbreekt", leg_limiet=0)
    assert not r.oplosbaar and not r.route
    assert "ch01_klaar" in r.nooit_vurend and "ch01_pak_rapport" in r.nooit_vurend
    assert "code_kluis" in r.tokens_nooit_gegeven


def test_zonder_neerleggen_zijn_de_staten_veel_minder(goed):
    zonder = los(leg_limiet=0)
    assert zonder.oplosbaar and zonder.staten < goed.staten / 5


def test_cli_exitcodes_en_uitvoer():
    basis = [sys.executable, str(REPO / "tools" / "solve.py"), "ch01_proef", "--content", str(PROEF)]
    ok = subprocess.run(basis + ["--leg-limiet", "0"], capture_output=True, text=True, encoding="utf-8")
    assert ok.returncode == 0, ok.stdout
    assert "Oplosbaar: ja" in ok.stdout and "Kortste oplossing (8 stappen)" in ok.stdout
    dood = subprocess.run(basis + ["--overlay", str(KAPOT / "doodlopend_rapport_weg"), "--leg-limiet", "0"], capture_output=True, text=True, encoding="utf-8")
    assert dood.returncode == 1
    assert "Doodlopende staten (unieke ingangen): " in dood.stdout and "Oorzaak: onmisbaar object verdwenen: rapport" in dood.stdout
    onbekend = subprocess.run([sys.executable, str(REPO / "tools" / "solve.py"), "ch99", "--content", str(PROEF)], capture_output=True, text=True, encoding="utf-8")
    assert onbekend.returncode == 2
