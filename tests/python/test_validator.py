"""De validator: de fixture is groen, de lege content is groen en elke kapotte variant faalt op de juiste regel."""
import json
import subprocess
import sys

import pytest

import maak_kapot
from conftest import CUES, KAPOT, PROEF, REPO
from onderstad.valideer import valideer


def fouten(inh):
    return [m for m in inh.meldingen if m.niveau == "fout"]


def test_fixture_is_groen_zonder_waarschuwingen(valideer_variant):
    inh = valideer_variant()
    assert [str(m) for m in inh.meldingen if m.niveau != "info"] == []
    assert len(inh.docs) == 14


def test_lege_content_is_groen(tmp_path):
    inh = valideer([tmp_path], REPO / "audio" / "cues.json", REPO / "game")
    assert fouten(inh) == []


def test_echte_content_en_cues_zijn_groen():
    inh = valideer([REPO / "content"], REPO / "audio" / "cues.json", REPO / "game")
    assert [str(m) for m in fouten(inh)] == []


@pytest.mark.parametrize("naam", sorted(maak_kapot.VARIANTEN))
def test_kapotte_variant_faalt_op_de_verwachte_regel(naam, valideer_variant):
    regel, fragment, niveau = maak_kapot.VARIANTEN[naam]
    gevonden = [m for m in valideer_variant(naam).meldingen if m.niveau == niveau]
    treffers = [m for m in gevonden if m.regel == regel and fragment in m.tekst]
    assert treffers, f"{naam}: geen {niveau} {regel} met '{fragment}'; wel: {[str(m) for m in gevonden]}"
    for m in treffers:
        assert m.bestand and m.pad, "een melding noemt bestand en pad"


def test_varianten_zijn_actueel(tmp_path, monkeypatch):
    """De ingecheckte varianten komen overeen met wat maak_kapot.py nu genereert."""
    monkeypatch.setattr(maak_kapot, "KAPOT", tmp_path / "kapot")
    maak_kapot.main()
    for pad in sorted((tmp_path / "kapot").rglob("*.json")):
        ingecheckt = KAPOT / pad.relative_to(tmp_path / "kapot")
        assert ingecheckt.is_file(), f"{ingecheckt} ontbreekt"
        assert json.loads(ingecheckt.read_text(encoding="utf-8")) == json.loads(pad.read_text(encoding="utf-8")), ingecheckt
    assert {p.name for p in (tmp_path / "kapot").iterdir()} == {p.name for p in KAPOT.iterdir()}


# --- acceptatiecriteria die niet in een kapotte-variant-map passen

def _cues_variant(tmp_path, wijzig):
    d = json.loads(CUES.read_text(encoding="utf-8"))
    wijzig(d["cues"])
    pad = tmp_path / "cues.json"
    pad.write_text(json.dumps(d), encoding="utf-8")
    return pad


def test_ac01_cue_met_status_klaar_zonder_bestand_faalt(tmp_path):
    def wijzig(cues):
        cues[0]["status"] = "klaar"
        cues[0].pop("bestand", None)
    gevonden = fouten(valideer([tmp_path / "leeg"], _cues_variant(tmp_path, wijzig)))
    assert gevonden and gevonden[0].regel == "schema"


def test_ac01_cue_met_status_verwacht_met_bestand_faalt(tmp_path):
    def wijzig(cues):
        cues[0]["bestand"] = "proef/a.ogg"
    assert fouten(valideer([tmp_path / "leeg"], _cues_variant(tmp_path, wijzig)))


def test_ac01_geldige_catalogus_is_groen(tmp_path):
    assert fouten(valideer([tmp_path / "leeg"], CUES)) == []


def test_tg10_uitgang_zonder_tegenstuk_faalt(valideer_variant):
    assert any(m.regel == "V13" for m in fouten(valideer_variant("geen_tegenstuk")))


def test_oi13_dubbele_beginplek_past_niet_en_acties(valideer_variant):
    assert any(m.regel == "V08" and "beginplek" in m.tekst for m in fouten(valideer_variant("dubbele_beginplek")))
    past_niet = fouten(valideer_variant("past_niet"))
    assert any(m.regel == "V09" and "max_grootte" in m.tekst for m in past_niet)
    assert any(m.regel == "V09" and "capaciteit" in m.tekst for m in past_niet)
    assert any(m.regel == "V10" for m in fouten(valideer_variant("acties_kloppen_niet")))


def test_ks06_meer_dan_twee_niet_lineaire_momenten(valideer_variant):
    assert any(m.regel == "V16" for m in fouten(valideer_variant("drie_niet_lineaire_momenten")))


def test_ks05_terug_in_de_tijd_zonder_niet_lineair(valideer_variant):
    assert any(m.regel == "V15" for m in fouten(valideer_variant("terug_in_de_tijd")))


def test_ks11_onmerkbare_gebeurtenis(valideer_variant):
    assert any(m.regel == "V18" for m in fouten(valideer_variant("gebeurtenis_onmerkbaar")))


def test_ac02_onbekende_cue_in_content(valideer_variant):
    assert any(m.regel == "V07" for m in fouten(valideer_variant("cue_onbekend")))


def test_sf17_lokale_flag_in_ander_hoofdstuk(valideer_variant):
    assert any(m.regel == "V26" and "ch01_bezoeken" in m.tekst for m in fouten(valideer_variant("lokale_flag_buiten_hoofdstuk")))


def test_ac03_cue_in_gdscript_die_niet_bestaat(tmp_path):
    game = tmp_path / "game"
    game.mkdir()
    (game / "a.gd").write_text('func f():\n\taudio.cue("object.pak")\n\taudio.cue("bestaat.niet")\n\tcue_gevraagd.emit("ui.weiger", {})\n', encoding="utf-8")
    inh = valideer([tmp_path / "leeg"], REPO / "audio" / "cues.json", game)
    assert [m.tekst for m in fouten(inh)] == ["cue 'bestaat.niet' staat niet in de cue-catalogus"]


# --- commandoregel

def _draai(*args):
    return subprocess.run([sys.executable, str(REPO / "tools" / "validate.py"), *args], capture_output=True, text=True, encoding="utf-8")


def test_cli_all_op_de_repo_is_groen():
    r = _draai("--all")
    assert r.returncode == 0, r.stdout
    assert "GROEN" in r.stdout


def test_cli_kapotte_variant_geeft_exitcode_1_met_nederlandse_melding():
    r = _draai("--content", str(PROEF), "--overlay", str(KAPOT / "onbekend_object"), "--cues", str(CUES))
    assert r.returncode == 1
    assert "FOUT [V02]" in r.stdout and "onbekend item" in r.stdout and "ch01_dak.json" in r.stdout and "$.objecten" in r.stdout
