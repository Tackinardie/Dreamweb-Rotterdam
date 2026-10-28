"""Kruisverwijzingsregels V01-V07: uniciteit, bestaan, bestandsnamen, scope, tekst en cues."""
from __future__ import annotations

import re
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

from .condities import atomen
from .inhoud import Doc, Inhoud
from .wereld import Def, Ref, Wereld, hoofdstuk_nummer, LOKAAL, defs_van, refs_van

GEBRUIKT_DOOR_ENGINE = ("systeem.", "ui.", "klok.", "personage.")
# Tekstsleutels die de engine zelf gebruikt; ze moeten in tekst/nl/algemeen.json staan.
ENGINE_SLEUTELS = (
    "systeem.inventaris.vol", "systeem.past_niet", "systeem.neerleggen.geen_plek", "systeem.neerleggen.niet_hier",
    "systeem.niet_zonder", "systeem.uitgang.niet_nu", "systeem.uitgang.dicht", "systeem.container.dicht",
    "systeem.notitie.past_niet", "systeem.save.te_nieuw", "ui.notitie.genoteerd", "klok.formaat",
    *[f"klok.weekdag.{d}" for d in ("ma", "di", "wo", "do", "vr", "za", "zo")],
    *[f"klok.maand.{m}" for m in ("jan", "feb", "mrt", "apr", "mei", "jun", "jul", "aug", "sep", "okt", "nov", "dec")],
)


@dataclass
class Ctx:
    w: Wereld
    docs: list[Doc]
    refs: list[Ref]
    defs: list[Def]
    game_map: Path | None = None

    @property
    def inh(self) -> Inhoud:
        return self.w.inh

    def fout(self, regel: str, doc: Doc, pad: str, tekst: str) -> None:
        self.inh.fout(regel, doc.bestand, pad, tekst)

    def waarschuw(self, regel: str, doc: Doc, pad: str, tekst: str) -> None:
        self.inh.waarschuw(regel, doc.bestand, pad, tekst)


def maak_ctx(w: Wereld, docs: list[Doc], game_map: Path | None) -> Ctx:
    refs: list[Ref] = []
    defs: list[Def] = []
    for d in docs:
        refs.extend(refs_van(d))
        defs.extend(defs_van(d))
    return Ctx(w, docs, refs, defs, game_map)


def alle_atomen_diep(c, w: Wereld, bezocht: tuple = ()):
    """Atomen van een conditie, met benoemde condities uitgevouwen."""
    for soort, node, pad in atomen(c):
        if soort == "conditie":
            naam = node["conditie"]
            if naam in w.condities and naam not in bezocht:
                yield from alle_atomen_diep(w.condities[naam], w, bezocht + (naam,))
        else:
            yield soort, node, pad


def v01_uniek(ctx: Ctx) -> None:
    gezien: dict[tuple[str, str], Def] = {}
    for d in ctx.defs:
        sleutel = (d.soort, d.id)
        if sleutel in gezien:
            eerder = gezien[sleutel]
            ctx.fout("V01", d.doc, d.pad, f"dubbel {d.soort}-id '{d.id}' (ook in {eerder.doc.bestand} {eerder.pad})")
        else:
            gezien[sleutel] = d
    # lokaal per kamer / gesprek / apparaat
    for doc in ctx.docs:
        data = doc.data
        if doc.soort == "room":
            _uniek_lijst(ctx, doc, "uitgang", [(u["id"], f"$.uitgangen[{i}].id") for i, u in enumerate(data.get("uitgangen", []))])
            _uniek_lijst(ctx, doc, "NPC", [(n["id"], f"$.npcs[{i}].id") for i, n in enumerate(data.get("npcs", []))])
        elif doc.soort == "dialogue":
            _uniek_lijst(ctx, doc, "regel", [(r["id"], f"$.regels[{i}].id") for i, r in enumerate(data["regels"])])
            for i, r in enumerate(data["regels"]):
                _uniek_lijst(ctx, doc, "keuze", [(k["id"], f"$.regels[{i}].keuzes[{j}].id") for j, k in enumerate(r.get("keuzes", []))])
        elif doc.soort == "device":
            _uniek_lijst(ctx, doc, "app", [(a["id"], f"$.apps[{i}].id") for i, a in enumerate(data["apps"])])
            for i, a in enumerate(data["apps"]):
                _uniek_lijst(ctx, doc, "app-item", [(x["id"], f"$.apps[{i}].items[{j}].id") for j, x in enumerate(a["items"])])
        elif doc.soort == "tekst":
            for k in data["teksten"]:
                ander = ctx.w.teksten[data["taal"]].get(k)
                if ander is not None and ander is not doc:
                    ctx.fout("V01", doc, f"$.teksten.{k}", f"tekstsleutel '{k}' staat ook in {ander.bestand}")


def _uniek_lijst(ctx: Ctx, doc: Doc, soort: str, items: list[tuple[str, str]]) -> None:
    gezien = set()
    for ident, pad in items:
        if ident in gezien:
            ctx.fout("V01", doc, pad, f"dubbel {soort}-id '{ident}'")
        gezien.add(ident)


def _bestaat(ctx: Ctx, r: Ref) -> bool:
    w = ctx.w
    if r.soort == "item": return r.id in w.items
    if r.soort == "token": return r.id in w.tokens
    if r.soort == "personage": return r.id in w.personages
    if r.soort == "flag": return r.id in w.flags
    if r.soort == "conditie": return r.id in w.condities
    if r.soort == "kamer": return r.id in w.kamers
    if r.soort == "scene": return r.id in w.scenes
    if r.soort == "gebeurtenis": return r.id in w.gebeurtenissen
    if r.soort == "knoop": return r.id in w.knopen
    if r.soort == "dialoog": return r.id in w.dialogen
    if r.soort == "apparaat": return r.id in w.apparaten
    if r.soort == "gebouw":
        return any(g["id"] == r.id for h in w.hoofdstukken.values() for g in h.get("gebouwen", []))
    if r.soort == "niveau":
        gebouw, _, niveau = r.id.partition(".")
        return any(g["id"] == gebouw and any(n["id"] == niveau for n in g["niveaus"])
                   for h in w.hoofdstukken.values() for g in h.get("gebouwen", []))
    if r.soort == "regel":
        dlg = w.dialogen.get(r.extra)
        return dlg is not None and any(x["id"] == r.id for x in dlg["regels"])
    if r.soort == "uitgang":
        kamer = w.kamers.get(r.extra)
        return kamer is not None and any(u["id"] == r.id for u in kamer.get("uitgangen", []))
    if r.soort == "app":
        dev = w.apparaten.get(r.extra)
        return dev is not None and any(a["id"] == r.id for a in dev["apps"])
    if r.soort == "appitem":
        dev = w.apparaten.get(r.extra[0])
        if dev is None:
            return False
        return any(a["id"] == r.extra[1] and any(x["id"] == r.id for x in a["items"]) for a in dev["apps"])
    return True  # tekst en cue worden elders gecontroleerd


def v02_bestaan(ctx: Ctx) -> None:
    for r in ctx.refs:
        if r.soort in ("tekst", "cue"):
            continue
        if not _bestaat(ctx, r):
            ctx.fout("V02", r.doc, r.pad, f"verwijst naar onbekend {r.soort} '{r.id}'")


def v03_namen(ctx: Ctx) -> None:
    w = ctx.w
    spel_lijst = w.spel.get("hoofdstukken", [])
    for doc in ctx.docs:
        d = doc.data
        stem = Path(doc.bestand).stem
        if doc.soort in ("room", "dialogue", "device") and d.get("id") != stem:
            ctx.fout("V03", doc, "$.id", f"id '{d.get('id')}' wijkt af van de bestandsnaam '{stem}'")
        if doc.soort == "chapter" and d.get("id") != doc.hoofdstuk:
            ctx.fout("V03", doc, "$.id", f"id '{d.get('id')}' wijkt af van de mapnaam '{doc.hoofdstuk}'")
        if doc.soort == "puzzle" and d.get("hoofdstuk") != doc.hoofdstuk:
            ctx.fout("V03", doc, "$.hoofdstuk", f"hoofdstuk '{d.get('hoofdstuk')}' wijkt af van de mapnaam '{doc.hoofdstuk}'")
        if doc.soort == "tekst":
            map_taal = Path(doc.bestand).parent.name
            if d.get("taal") != map_taal or d.get("domein") != stem:
                ctx.waarschuw("V03", doc, "$", f"taal/domein ({d.get('taal')}/{d.get('domein')}) horen bij map/bestand ({map_taal}/{stem})")
    for h in ctx.inh.hoofdstuk_mappen:
        if h not in w.hoofdstukken:
            bestand = next((d.bestand for d in ctx.docs if d.hoofdstuk == h), f"chapters/{h}")
            ctx.inh.fout("V03", bestand, "", f"map '{h}' heeft geen geldig chapter.json")
        elif w.spel and h not in spel_lijst:
            doc = next(d for d in ctx.docs if d.soort == "chapter" and d.hoofdstuk == h)
            ctx.fout("V03", doc, "$.id", f"hoofdstuk '{h}' staat niet in spel.json hoofdstukken")
    for doc in ctx.docs:
        if doc.soort == "spel":
            for i, h in enumerate(spel_lijst):
                if h not in w.hoofdstukken:
                    ctx.fout("V03", doc, f"$.hoofdstukken[{i}]", f"hoofdstuk '{h}' heeft geen map met chapter.json")


def v04_scope(ctx: Ctx) -> None:
    """V04/V05/V26: prefix en hoofdstuk-scope."""
    for r in ctx.refs:
        nn = hoofdstuk_nummer(r.id) if r.soort in ("kamer", "scene", "gebeurtenis", "knoop", "dialoog", "apparaat", "flag", "conditie") else None
        if nn is None:
            continue
        eigen = hoofdstuk_nummer(r.doc.hoofdstuk) if r.doc.hoofdstuk else None
        if eigen == nn or (r.hub_ok and nn == "00"):
            continue
        regel = "V26" if r.soort in ("flag", "conditie") else "V04"
        waar = f"hoofdstuk {eigen}" if eigen else "globale content"
        ctx.fout(regel, r.doc, r.pad, f"{r.soort} '{r.id}' hoort bij hoofdstuk {nn} maar wordt gebruikt in {waar}")
    for d in ctx.defs:
        nn = hoofdstuk_nummer(d.id)
        eigen = hoofdstuk_nummer(d.doc.hoofdstuk) if d.doc.hoofdstuk else None
        if d.lokaal:
            if nn is None:
                ctx.fout("V05", d.doc, d.pad, f"{d.soort} '{d.id}' is lokaal en moet de prefix ch{eigen}_ krijgen")
            elif nn != eigen:
                ctx.fout("V04", d.doc, d.pad, f"{d.soort} '{d.id}' staat in hoofdstuk {eigen} maar heeft de prefix van hoofdstuk {nn}")
        elif d.soort in ("item", "token", "personage", "flag", "conditie") and nn is not None:
            ctx.fout("V05", d.doc, d.pad, f"{d.soort} '{d.id}' is globaal en mag geen hoofdstukprefix hebben")


def v06_teksten(ctx: Ctx) -> None:
    w = ctx.w
    basis = w.teksten.get("nl", {})
    gebruikt: set[str] = set()
    for r in ctx.refs:
        if r.soort != "tekst":
            continue
        gebruikt.add(r.id)
        if r.id not in basis:
            ctx.fout("V06", r.doc, r.pad, f"tekstsleutel '{r.id}' ontbreekt in de basistaal (nl)")
    spel_doc = next((d for d in ctx.docs if d.soort == "spel"), None)
    if spel_doc is not None:
        for k in ENGINE_SLEUTELS:
            if k not in basis:
                ctx.fout("V06", spel_doc, "$", f"tekstsleutel '{k}' die de engine gebruikt ontbreekt in tekst/nl/algemeen.json")
    for taal, sleutels in w.teksten.items():
        for k, doc in sleutels.items():
            if taal == "nl" and k not in gebruikt and not k.startswith(GEBRUIKT_DOOR_ENGINE):
                ctx.waarschuw("V06", doc, f"$.teksten.{k}", f"tekstsleutel '{k}' wordt nergens gebruikt")
        if taal != "nl" and basis:
            ctx.inh.info("V06", f"tekst/{taal}", "", f"taal {taal}: {100 * len([k for k in basis if k in sleutels]) // len(basis)}% van de sleutels vertaald")


GD_CUE = re.compile(r"\b(cue|start_laag|cue_gevraagd\.emit)\(\s*\"([^\"]+)\"")
GD_CUE_STANDAARD = re.compile(r"\b_cue\([^)]*,\s*\"([a-z0-9_.]+)\"\s*\)")


def v07_cues(ctx: Ctx) -> None:
    cues = ctx.w.cues
    for r in ctx.refs:
        if r.soort != "cue":
            continue
        c = cues.get(r.id)
        if c is None:
            ctx.fout("V07", r.doc, r.pad, f"cue '{r.id}' staat niet in de cue-catalogus")
        elif c["soort"] != r.extra:
            ctx.fout("V07", r.doc, r.pad, f"cue '{r.id}' is {c['soort']} maar wordt hier als {r.extra} gebruikt")
    if ctx.game_map and ctx.game_map.is_dir():
        for pad in sorted(ctx.game_map.rglob("*.gd")):
            if "addons" in pad.parts:
                continue
            for n, regel in enumerate(pad.read_text(encoding="utf-8").splitlines(), 1):
                gevonden = [(m.group(1), m.group(2)) for m in GD_CUE.finditer(regel)]
                gevonden += [("cue", m.group(1)) for m in GD_CUE_STANDAARD.finditer(regel)]
                for aanroep, cue_id in gevonden:
                    soort = "doorlopend" if aanroep == "start_laag" else "eenmalig"
                    c = cues.get(cue_id)
                    if c is None:
                        ctx.inh.fout("V07", str(pad), f"regel {n}", f"cue '{cue_id}' staat niet in de cue-catalogus")
                    elif c["soort"] != soort:
                        ctx.inh.fout("V07", str(pad), f"regel {n}", f"cue '{cue_id}' is {c['soort']} maar wordt met {aanroep}() aangeroepen")
