"""Content laden uit een of meer mappen (overlay) en tegen de schema's valideren."""
from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable

from jsonschema import Draft202012Validator
from jsonschema.exceptions import best_match
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

REPO = Path(__file__).resolve().parents[2]
SCHEMA_MAP = REPO / "tools" / "schemas"
SCHEMA_BASIS = "https://onderstad.local/schemas/"

SOORT_SCHEMA = {
    "spel": "spel.schema.json",
    "items": "item.schema.json",
    "tekst": "tekst.schema.json",
    "chapter": "chapter.schema.json",
    "room": "room.schema.json",
    "puzzle": "puzzle.schema.json",
    "dialogue": "dialogue.schema.json",
    "device": "device.schema.json",
    "cues": "audio-cues.schema.json",
}


@dataclass
class Melding:
    niveau: str            # "fout" of "waarschuwing"
    regel: str             # "schema", "V01", ...
    bestand: str
    pad: str
    tekst: str

    def __str__(self) -> str:
        soort = {"fout": "FOUT", "waarschuwing": "WAARSCHUWING"}.get(self.niveau, "INFO")
        plek = f"{self.bestand} {self.pad}".strip()
        return f"{soort} [{self.regel}] {plek}: {self.tekst}"


@dataclass
class Doc:
    soort: str
    bestand: str               # weergavepad
    data: Any
    hoofdstuk: str | None = None   # mapnaam, voor chapters/<id>/...
    taal: str | None = None


@dataclass
class Inhoud:
    docs: list[Doc] = field(default_factory=list)
    meldingen: list[Melding] = field(default_factory=list)
    wortels: list[Path] = field(default_factory=list)
    hoofdstuk_mappen: list[str] = field(default_factory=list)

    def info(self, regel: str, bestand: str, pad: str, tekst: str) -> None:
        self.meldingen.append(Melding("info", regel, bestand, pad, tekst))

    def fout(self, regel: str, bestand: str, pad: str, tekst: str) -> None:
        self.meldingen.append(Melding("fout", regel, bestand, pad, tekst))

    def waarschuw(self, regel: str, bestand: str, pad: str, tekst: str) -> None:
        self.meldingen.append(Melding("waarschuwing", regel, bestand, pad, tekst))

    def van_soort(self, soort: str) -> list[Doc]:
        return [d for d in self.docs if d.soort == soort]

    def leeg(self) -> bool:
        return not any(d.soort != "cues" for d in self.docs)


def _verzamel_bestanden(wortels: Iterable[Path]) -> dict[str, Path]:
    """Relatief pad -> bestand; latere wortels overschrijven eerdere (overlay)."""
    bestanden: dict[str, Path] = {}
    for wortel in wortels:
        if not wortel.is_dir():
            continue
        for p in sorted(wortel.rglob("*.json")):
            bestanden[p.relative_to(wortel).as_posix()] = p
    return bestanden


def _lees(pad: Path, inh: Inhoud, weergave: str) -> Any:
    try:
        return json.loads(pad.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        inh.fout("schema", weergave, f"regel {e.lineno}, kolom {e.colno}", f"geen geldige JSON: {e.msg}")
    except OSError as e:
        inh.fout("schema", weergave, "", f"bestand niet leesbaar: {e}")
    return None


def laad_inhoud(wortels: list[Path], cues_pad: Path | None) -> Inhoud:
    """Leest content/ (met optionele overlays) en het cue-bestand. Schema's worden hier nog niet toegepast."""
    inh = Inhoud(wortels=list(wortels))
    bestanden = _verzamel_bestanden(wortels)
    mappen: set[str] = set()
    for rel, pad in bestanden.items():
        delen = rel.split("/")
        if rel == "cues.json":
            continue  # staat naast de content (fixtures); wordt via cues_pad geladen
        data = _lees(pad, inh, str(pad))
        if data is None:
            continue
        weergave = str(pad)
        doc: Doc | None = None
        if rel == "spel.json":
            doc = Doc("spel", weergave, data)
        elif rel == "items.json":
            doc = Doc("items", weergave, data)
        elif len(delen) == 3 and delen[0] == "tekst":
            doc = Doc("tekst", weergave, data, taal=delen[1])
        elif len(delen) >= 3 and delen[0] == "chapters":
            h = delen[1]
            mappen.add(h)
            onder = delen[2:]
            if onder == ["chapter.json"]:
                doc = Doc("chapter", weergave, data, hoofdstuk=h)
            elif onder == ["puzzles.json"]:
                doc = Doc("puzzle", weergave, data, hoofdstuk=h)
            elif len(onder) == 2 and onder[0] in ("rooms", "dialogue", "devices"):
                soort = {"rooms": "room", "dialogue": "dialogue", "devices": "device"}[onder[0]]
                doc = Doc(soort, weergave, data, hoofdstuk=h)
        if doc is None:
            inh.waarschuw("V03", weergave, "", "bestand op onverwachte plek; wordt genegeerd")
            continue
        inh.docs.append(doc)
    inh.hoofdstuk_mappen = sorted(mappen)
    if cues_pad is not None and cues_pad.is_file():
        data = _lees(cues_pad, inh, str(cues_pad))
        if data is not None:
            inh.docs.append(Doc("cues", str(cues_pad), data))
    return inh


def maak_register() -> Registry:
    """Alle schema's in een register, op $id."""
    register = Registry()
    for pad in sorted(SCHEMA_MAP.glob("*.schema.json")):
        schema = json.loads(pad.read_text(encoding="utf-8"))
        register = register.with_resource(schema["$id"], Resource(contents=schema, specification=DRAFT202012))
    return register


def _json_pad(pad: Iterable[Any]) -> str:
    uit = "$"
    for deel in pad:
        uit += f"[{deel}]" if isinstance(deel, int) else f".{deel}"
    return uit


def valideer_schemas(inh: Inhoud) -> None:
    register = maak_register()
    validators: dict[str, Draft202012Validator] = {}
    for soort, bestandsnaam in SOORT_SCHEMA.items():
        schema = json.loads((SCHEMA_MAP / bestandsnaam).read_text(encoding="utf-8"))
        validators[soort] = Draft202012Validator(schema, registry=register)
    for doc in inh.docs:
        for e in sorted(validators[doc.soort].iter_errors(doc.data), key=lambda x: list(map(str, x.absolute_path))):
            diepste = best_match([e]) or e
            inh.fout("schema", doc.bestand, _json_pad(diepste.absolute_path), diepste.message[:300])
