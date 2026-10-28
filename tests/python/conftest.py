"""Pytest-configuratie: maakt de tools en de fixtures importeerbaar en levert gedeelde hulpfuncties."""
import sys
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "tools"))
sys.path.insert(0, str(REPO / "tests" / "fixtures"))

PROEF = REPO / "tests" / "fixtures" / "proef"
KAPOT = REPO / "tests" / "fixtures" / "kapot"
CUES = PROEF / "cues.json"


@pytest.fixture(scope="session")
def valideer_variant():
    from onderstad.valideer import valideer

    def _valideer(naam: str | None = None):
        wortels = [PROEF] + ([KAPOT / naam] if naam else [])
        return valideer(wortels, CUES)

    return _valideer
