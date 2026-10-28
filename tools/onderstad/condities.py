"""Gedeelde conditie-evaluator (docs/systemen/state-en-flags.md, "De conditietaal").

Dezelfde tabel als de GDScript-evaluator (game/systems/condities.gd). Beide worden
getoetst met tests/fixtures/condities.json. Een nieuw atoom gaat tegelijk in
GDScript, hier en in die testset.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Callable, Iterator

MAX_DIEPTE = 32

# Alle atomen met hun sleutel, in de volgorde waarin de evaluator ze herkent.
ATOMEN = (
    "alle", "een_van", "niet", "heeft", "ligt", "token", "flag", "knoop", "kamer",
    "scene", "gebeurtenis", "kloktijd", "scenetijd", "niveau", "apparaat", "conditie",
)


def minuten(tijd: str) -> int:
    """'HH:MM' naar minuten sinds middernacht."""
    uur, minuut = tijd.split(":")
    return int(uur) * 60 + int(minuut)


def tijdstip_minuten(tijdstip: dict) -> int:
    """{'dag': n, 'tijd': 'HH:MM'} naar absolute minuten (dag 1 begint bij 1440)."""
    return int(tijdstip["dag"]) * 1440 + minuten(tijdstip["tijd"])


class Toestand:
    """Wat een conditie over de wereld mag weten. Alleen lezen, nooit schrijven."""

    def __init__(self) -> None:
        self.fouten: list[str] = []

    def fout(self, tekst: str) -> None:
        self.fouten.append(tekst)

    # Vragen die afgeleide klassen beantwoorden
    def item_bekend(self, item: str) -> bool: raise NotImplementedError
    def heeft(self, item: str) -> bool: raise NotImplementedError
    def ligt(self, item: str, plek: str) -> bool: raise NotImplementedError
    def heeft_token(self, token: str) -> bool: raise NotImplementedError
    def flag_waarde(self, flag: str) -> Any: raise NotImplementedError          # None = onbekend
    def knoop_opgelost(self, knoop: str) -> bool: raise NotImplementedError
    def huidige_kamer(self) -> str: raise NotImplementedError
    def huidige_scene(self) -> str: raise NotImplementedError
    def gebeurtenis_status(self, gebeurtenis: str) -> str: raise NotImplementedError  # "" = onbekend
    def kloktijd_minuten(self) -> int: raise NotImplementedError
    def scenetijd_minuten(self) -> int: raise NotImplementedError
    def heeft_niveau(self, niveau: str) -> bool: raise NotImplementedError
    def apparaat_toestand(self, apparaat: str) -> str: raise NotImplementedError      # "" = onbekend
    def benoemd(self, naam: str) -> Any: raise NotImplementedError                   # None = onbekend


def evalueer(c: Any, t: Toestand, diepte: int = 0) -> bool:
    """Evalueert een conditie. Afwezige conditie (None) is waar. Onbekende id: onwaar + foutregel."""
    if c is None:
        return True
    if diepte > MAX_DIEPTE:
        t.fout("benoemde condities nesten te diep (kring?)")
        return False
    if not isinstance(c, dict):
        t.fout(f"conditie is geen object: {c!r}")
        return False
    sleutel = next((k for k in ATOMEN if k in c), None)
    if sleutel is None:
        t.fout(f"onbekende conditie: {c!r}")
        return False
    waarde = c[sleutel]
    if sleutel == "alle":
        if not waarde:
            t.fout("lege 'alle'-lijst")
            return False
        return all(evalueer(x, t, diepte + 1) for x in waarde)
    if sleutel == "een_van":
        if not waarde:
            t.fout("lege 'een_van'-lijst")
            return False
        return any(evalueer(x, t, diepte + 1) for x in waarde)
    if sleutel == "niet":
        return not evalueer(waarde, t, diepte + 1)
    if sleutel == "heeft":
        if not t.item_bekend(waarde):
            t.fout(f"onbekend object: {waarde}")
            return False
        return t.heeft(waarde)
    if sleutel == "ligt":
        if not t.item_bekend(waarde["object"]):
            t.fout(f"onbekend object: {waarde['object']}")
            return False
        return t.ligt(waarde["object"], waarde["in"])
    if sleutel == "token":
        return t.heeft_token(waarde)
    if sleutel == "flag":
        return _flag(c, t)
    if sleutel == "knoop":
        return t.knoop_opgelost(waarde)
    if sleutel == "kamer":
        return t.huidige_kamer() == waarde
    if sleutel == "scene":
        return t.huidige_scene() == waarde
    if sleutel == "gebeurtenis":
        status = t.gebeurtenis_status(waarde)
        if status == "":
            t.fout(f"onbekende gebeurtenis: {waarde}")
            return False
        return status == c.get("status", "actief")
    if sleutel == "kloktijd":
        nu, van, tot = t.kloktijd_minuten(), minuten(waarde["van"]), minuten(waarde["tot"])
        return van <= nu < tot if van <= tot else (nu >= van or nu < tot)
    if sleutel == "scenetijd":
        nu = t.scenetijd_minuten()
        if "vanaf" in waarde and nu < tijdstip_minuten(waarde["vanaf"]):
            return False
        if "voor" in waarde and nu >= tijdstip_minuten(waarde["voor"]):
            return False
        return True
    if sleutel == "niveau":
        return t.heeft_niveau(waarde)
    if sleutel == "apparaat":
        toestand = t.apparaat_toestand(waarde)
        if toestand == "":
            t.fout(f"onbekend apparaat: {waarde}")
            return False
        return toestand == c["toestand"]
    # conditie (benoemd)
    sub = t.benoemd(waarde)
    if sub is None:
        t.fout(f"onbekende benoemde conditie: {waarde}")
        return False
    return evalueer(sub, t, diepte + 1)


def _flag(c: dict, t: Toestand) -> bool:
    waarde = t.flag_waarde(c["flag"])
    if waarde is None:
        t.fout(f"onbekende flag: {c['flag']}")
        return False
    getal = int(waarde)
    if "gelijk" in c:
        return getal == int(c["gelijk"])
    if "minstens" in c:
        return getal >= int(c["minstens"])
    if "hoogstens" in c:
        return getal <= int(c["hoogstens"])
    return getal != 0


def atomen(c: Any, pad: str = "") -> Iterator[tuple[str, Any, str]]:
    """Loopt door alle atomen van een conditie: (soort, conditie-dict of waarde, json-pad)."""
    if not isinstance(c, dict):
        return
    for sleutel in ATOMEN:
        if sleutel not in c:
            continue
        waarde = c[sleutel]
        if sleutel in ("alle", "een_van"):
            for i, sub in enumerate(waarde):
                yield from atomen(sub, f"{pad}.{sleutel}[{i}]")
        elif sleutel == "niet":
            yield from atomen(waarde, f"{pad}.niet")
        else:
            yield sleutel, c, f"{pad}.{sleutel}"
        return


class DictToestand(Toestand):
    """Toestand uit de JSON van tests/fixtures/condities.json."""

    def __init__(self, d: dict, benoemd: dict | None = None) -> None:
        super().__init__()
        self.plekken: dict[str, str] = d.get("plekken", {})
        self.items: dict[str, dict] = d.get("items", {})
        self.tokens = set(d.get("tokens", []))
        self.flag_start: dict[str, Any] = d.get("flag_start", {})
        self.flags: dict[str, Any] = d.get("flags", {})
        self.knopen = set(d.get("knopen", []))
        self.kamer = d.get("kamer", "")
        self.scene = d.get("scene", "")
        self.gebeurtenissen: dict[str, str] = d.get("gebeurtenissen", {})
        self.dag = int(d.get("dag", 1))
        self.tijd = d.get("tijd", "00:00")
        self.apparaten: dict[str, str] = d.get("apparaten", {})
        self.namen: dict = benoemd or {}

    def item_bekend(self, item: str) -> bool:
        return item in self.items

    def _voorouders(self, item: str) -> list[str]:
        keten, huidig, stappen = [], item, 0
        while huidig in self.plekken and stappen < 64:
            huidig = self.plekken[huidig]
            keten.append(huidig)
            stappen += 1
        return keten

    def heeft(self, item: str) -> bool:
        return "inventaris" in self._voorouders(item)

    def ligt(self, item: str, plek: str) -> bool:
        return plek in self._voorouders(item)

    def heeft_token(self, token: str) -> bool:
        return token in self.tokens

    def flag_waarde(self, flag: str) -> Any:
        if flag in self.flags:
            return self.flags[flag]
        return self.flag_start.get(flag)

    def knoop_opgelost(self, knoop: str) -> bool:
        return knoop in self.knopen

    def huidige_kamer(self) -> str:
        return self.kamer

    def huidige_scene(self) -> str:
        return self.scene

    def gebeurtenis_status(self, gebeurtenis: str) -> str:
        return self.gebeurtenissen.get(gebeurtenis, "")

    def kloktijd_minuten(self) -> int:
        return minuten(self.tijd)

    def scenetijd_minuten(self) -> int:
        return self.dag * 1440 + minuten(self.tijd)

    def heeft_niveau(self, niveau: str) -> bool:
        return any(
            self.heeft(i) and niveau in d.get("geeft_niveaus", []) for i, d in self.items.items()
        )

    def apparaat_toestand(self, apparaat: str) -> str:
        return self.apparaten.get(apparaat, "")

    def benoemd(self, naam: str) -> Any:
        return self.namen.get(naam)


def laad_testset(pad: Path) -> dict:
    return json.loads(Path(pad).read_text(encoding="utf-8"))


def draai_testset(testset: dict, evaluator: Callable[[Any, Toestand], bool] = evalueer) -> list[tuple[str, bool, bool]]:
    """Draait alle gevallen; geeft (naam, verwacht, werkelijk) per geval."""
    uitkomst = []
    for geval in testset["gevallen"]:
        t = DictToestand(geval["toestand"], testset.get("benoemd", {}))
        uitkomst.append((geval["naam"], geval["verwacht"], evaluator(geval["conditie"], t)))
    return uitkomst
