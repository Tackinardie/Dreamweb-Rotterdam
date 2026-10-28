"""Kruisverwijzingsregels V20-V31: puzzelgraaf, flags en tokens, gesprekken en apparaten."""
from __future__ import annotations

import json
from collections import defaultdict
from typing import Any

from .regels_basis import Ctx, alle_atomen_diep
from .wereld import STAAT_EFFECTEN, hoofdstuk_nummer

NIET_IN_PUZZELS = STAAT_EFFECTEN - {"naar_scene", "naar_kamer"}   # naar_* bestaan ook als veld op uitgangen


def _zoek_sleutels(x: Any, sleutels: set[str], pad: str = "$"):
    if isinstance(x, dict):
        for k, v in x.items():
            if k in sleutels:
                yield f"{pad}.{k}"
            yield from _zoek_sleutels(v, sleutels, f"{pad}.{k}")
    elif isinstance(x, list):
        for i, v in enumerate(x):
            yield from _zoek_sleutels(v, sleutels, f"{pad}[{i}]")


def v20_effecten(ctx: Ctx) -> None:
    for doc in ctx.inh.docs:      # ook bestanden die het schema al afkeurde
        if doc.soort in ("puzzle", "spel", "items", "tekst", "cues"):
            continue
        for pad in _zoek_sleutels(doc.data, NIET_IN_PUZZELS | {"effecten"}):
            ctx.fout("V20", doc, pad, "toestandswijzigende effecten horen alleen in puzzles.json")


def _doelknopen(ctx: Ctx, h: str) -> list[dict]:
    return [k for k in ctx.w.puzzels.get(h, []) if k["type"] == "doel"]


def v21_doel(ctx: Ctx) -> None:
    w = ctx.w
    for doc in ctx.docs:
        if doc.soort != "chapter":
            continue
        h = doc.hoofdstuk or doc.data["id"]
        if h not in w.puzzels:
            ctx.fout("V21", doc, "$", f"hoofdstuk '{h}' heeft geen puzzles.json")
            continue
        doelen = _doelknopen(ctx, h)
        if len(doelen) != 1:
            ctx.fout("V21", doc, "$", f"hoofdstuk '{h}' heeft {len(doelen)} doel-knopen; het moet er precies één zijn")
            continue
        doel = doelen[0]
        atomen = list(alle_atomen_diep(doc.data.get("doel"), w))
        direct = any(s == "knoop" and n["knoop"] == doel["id"] for s, n, _ in atomen)
        gezet_flags = {e.get("zet_flag") for e in doel.get("effecten", [])}
        gegeven = {e.get("geef_token") for e in doel.get("effecten", [])}
        indirect = any((s == "flag" and n["flag"] in gezet_flags) or (s == "token" and n["token"] in gegeven) for s, n, _ in atomen)
        if not (direct or indirect):
            ctx.fout("V21", doc, "$.doel", f"chapter.doel verwijst niet naar de doel-knoop '{doel['id']}' en wordt er ook niet door vervuld")


def v22_hints(ctx: Ctx) -> None:
    for doc in ctx.docs:
        if doc.soort != "puzzle":
            continue
        for i, k in enumerate(doc.data["knopen"]):
            if k.get("pad", "hoofd") == "hoofd" and not all(n in k.get("hints", {}) for n in ("vaag", "richting", "bijna")):
                ctx.fout("V22", doc, f"$.knopen[{i}].hints", f"hoofd-knoop '{k['id']}' heeft geen drie hints (vaag, richting, bijna)")


def _kan_waar(node: dict, start: Any, zetten: list, wis: bool) -> bool:
    kandidaten = {int(start)} | {int(z) for z in zetten} | ({0} if wis else set())
    def ok(v: int) -> bool:
        if "gelijk" in node: return v == int(node["gelijk"])
        if "minstens" in node: return v >= int(node["minstens"])
        if "hoogstens" in node: return v <= int(node["hoogstens"])
        return v != 0
    return any(ok(v) for v in kandidaten)


def v23_verkrijgbaar(ctx: Ctx) -> None:
    w = ctx.w
    gegeven = {r.id for r in ctx.refs if r.soort == "token" and r.extra == "geef"}
    zetten: dict[str, list] = defaultdict(list)
    gewist: set[str] = set()
    for r in ctx.refs:
        if r.soort == "flag" and isinstance(r.extra, tuple) and r.extra[0] == "zet":
            zetten[r.id].append(r.extra[1])
        elif r.soort == "flag" and isinstance(r.extra, tuple) and r.extra[0] == "wis":
            gewist.add(r.id)
    geplaatst = {r.id for r in ctx.refs if r.soort == "item" and r.extra in ("plaats", "geef")}
    niveaus = {r.id for r in ctx.refs if r.soort == "niveau" and r.extra == "geeft"}
    for r in ctx.refs:
        if r.soort == "token" and r.extra in ("cond", "sleutel", "combineer") and r.id in w.tokens and r.id not in gegeven:
            ctx.fout("V23", r.doc, r.pad, f"token '{r.id}' wordt gebruikt maar nergens gegeven")
        elif r.soort == "flag" and isinstance(r.extra, tuple) and r.extra[0] == "cond" and r.id in w.flags:
            start = w.flags[r.id]["start"]
            if not _kan_waar(r.extra[1], start, zetten.get(r.id, []), r.id in gewist):
                ctx.fout("V23", r.doc, r.pad, f"flag '{r.id}' kan deze conditie nooit waar maken (startwaarde {start!r}, gezet: {zetten.get(r.id, [])})")
        elif r.soort == "item" and r.extra == "onmisbaar" and r.id in w.items and r.id not in geplaatst:
            ctx.fout("V23", r.doc, r.pad, f"object '{r.id}' wordt nodig geacht maar heeft geen beginplek en wordt nergens gegeven")
        elif r.soort == "niveau" and r.extra == "cond" and r.id not in niveaus:
            ctx.fout("V23", r.doc, r.pad, f"niveau '{r.id}' wordt door geen enkel object gegeven")


def v24_ongebruikt(ctx: Ctx) -> None:
    gebruikt = {r.id for r in ctx.refs if r.soort == "token" and r.extra in ("cond", "sleutel", "combineer")}
    gemeld: set[str] = set()
    for r in ctx.refs:
        if r.soort == "token" and r.extra == "geef" and r.id not in gebruikt and r.id not in gemeld:
            gemeld.add(r.id)
            ctx.waarschuw("V24", r.doc, r.pad, f"token '{r.id}' wordt gegeven maar nergens gebruikt")


def v25_kringen(ctx: Ctx) -> None:
    w = ctx.w
    graaf = {n: {node["conditie"] for _, node, _ in _directe_namen(c)} for n, c in w.condities.items()}
    toestand: dict[str, int] = {}
    gemeld: set[str] = set()

    def bezoek(n: str, pad: list[str]) -> None:
        toestand[n] = 1
        for m in sorted(graaf.get(n, ())):
            if m not in graaf:
                continue
            if toestand.get(m) == 1:
                kring = pad[pad.index(m):] + [m] if m in pad else [n, m]
                if frozenset(kring) not in gemeld:
                    gemeld.add(frozenset(kring))
                    d = next(d for d in ctx.defs if d.soort == "conditie" and d.id == m)
                    ctx.fout("V25", d.doc, d.pad, f"benoemde condities vormen een kring: {' -> '.join(kring)}")
            elif m not in toestand:
                bezoek(m, pad + [m])
        toestand[n] = 2

    for n in sorted(graaf):
        if n not in toestand:
            bezoek(n, [n])


def _directe_namen(c):
    from .condities import atomen
    return [a for a in atomen(c) if a[0] == "conditie"]


def _literals(c, positief: bool = True, uit: set | None = None) -> set:
    uit = set() if uit is None else uit
    if not isinstance(c, dict):
        return uit
    if "alle" in c:
        for x in c["alle"]:
            _literals(x, positief, uit)
    elif "niet" in c:
        _literals(c["niet"], not positief, uit)
    elif "een_van" not in c:
        uit.add((positief, json.dumps(c, sort_keys=True)))
    return uit


def v27_dubbele_triggers(ctx: Ctx) -> None:
    for doc in ctx.docs:
        if doc.soort != "puzzle":
            continue
        groepen: dict[str, list[tuple[int, dict]]] = defaultdict(list)
        for i, k in enumerate(doc.data["knopen"]):
            if "automatisch" in k["trigger"] or "gebeurtenis" in k["trigger"]:
                continue
            groepen[json.dumps(k["trigger"], sort_keys=True)].append((i, k))
        for lijst in groepen.values():
            for a in range(len(lijst)):
                for b in range(a + 1, len(lijst)):
                    (_, ka), (ib, kb) = lijst[a], lijst[b]
                    la, lb = _literals(ka.get("vereist")), _literals(kb.get("vereist"))
                    uitsluitend = any((not p, s) in lb for p, s in la)
                    volgt = any(p and s == json.dumps({"knoop": ka["id"]}, sort_keys=True) for p, s in lb)
                    if not uitsluitend and not volgt:
                        ctx.waarschuw("V27", doc, f"$.knopen[{ib}].trigger", f"knoop '{kb['id']}' heeft dezelfde trigger als '{ka['id']}' en sluit die niet uit; alleen de eerste vuurt")


def v28_aanname(ctx: Ctx) -> None:
    w = ctx.w
    lijst = w.spel.get("hoofdstukken", [])
    for idx, h in enumerate(lijst):
        doc = next((d for d in ctx.docs if d.soort == "chapter" and d.hoofdstuk == h), None)
        aan = (doc.data.get("aanname_bij_start") if doc else None) or {}
        if idx == 0 or doc is None or not aan:
            continue
        vorige = lijst[idx - 1]
        if vorige not in w.hoofdstukken:
            ctx.waarschuw("V28", doc, "$.aanname_bij_start", f"hoofdstuk '{vorige}' bestaat nog niet; aanname van '{h}' kan niet worden gecontroleerd")
            continue
        grens = int(hoofdstuk_nummer(vorige) or 0)
        tot = lambda r: r.doc.hoofdstuk is not None and int(hoofdstuk_nummer(r.doc.hoofdstuk) or 0) <= grens
        items = {r.id for r in ctx.refs if r.soort == "item" and r.extra in ("plaats", "geef") and tot(r)}
        tokens = {r.id for r in ctx.refs if r.soort == "token" and r.extra == "geef" and tot(r)}
        flags = {r.id for r in ctx.refs if r.soort == "flag" and isinstance(r.extra, tuple) and r.extra[0] == "zet" and tot(r)}
        # een hoofd- of doel-knoop in N (of eerder) die het object verwijdert: het is aan het eind van N weg
        weg: dict[str, str] = {}
        for hh, knopen in ctx.w.puzzels.items():
            if int(hoofdstuk_nummer(hh) or 0) > grens:
                continue
            for kn in knopen:
                if kn["type"] == "doel" or kn.get("pad", "hoofd") == "hoofd":
                    for e in kn.get("effecten", []):
                        if "verwijder_object" in e:
                            weg.setdefault(e["verwijder_object"], f"knoop '{kn['id']}'")
        for r in ctx.refs:
            if r.doc is not doc:
                continue
            if r.soort == "item" and r.extra == "plaats" and r.id not in items:
                ctx.fout("V28", doc, r.pad, f"aangenomen object '{r.id}' komt niet voor in '{vorige}' of eerder")
            elif r.soort == "item" and r.extra == "plaats" and r.id in weg:
                ctx.fout("V28", doc, r.pad, f"aangenomen object '{r.id}' is aan het eind van '{vorige}' niet bereikbaar: {weg[r.id]} verwijdert het")
            elif r.soort == "token" and r.extra == "geef" and r.id not in tokens:
                ctx.fout("V28", doc, r.pad, f"aangenomen token '{r.id}' wordt in '{vorige}' of eerder niet gegeven")
            elif r.soort == "flag" and isinstance(r.extra, tuple) and r.extra[0] == "zet" and r.id not in flags:
                ctx.fout("V28", doc, r.pad, f"aangenomen flag '{r.id}' wordt in '{vorige}' of eerder niet gezet")


def v29_gesprekken(ctx: Ctx) -> None:
    for doc in ctx.docs:
        if doc.soort != "dialogue":
            continue
        d = doc.data
        regels = {r["id"]: r for r in d["regels"]}
        toegestaan = set(d["deelnemers"]) | {"richard"}
        for i, r in enumerate(d["regels"]):
            if r["spreker"] not in toegestaan:
                ctx.fout("V29", doc, f"$.regels[{i}].spreker", f"spreker '{r['spreker']}' is geen deelnemer van het gesprek")
        start = [d["start"]] if isinstance(d["start"], str) else [x["regel"] for x in d["start"]]
        bereikt, rij = set(), [s for s in start if s in regels]
        while rij:
            n = rij.pop()
            if n in bereikt:
                continue
            bereikt.add(n)
            r = regels[n]
            rij += [x for x in [r.get("volgende")] + [k.get("volgende") for k in r.get("keuzes", [])] if x in regels]
        for i, r in enumerate(d["regels"]):
            if r["id"] not in bereikt:
                ctx.waarschuw("V29", doc, f"$.regels[{i}]", f"regel '{r['id']}' is vanaf de start niet bereikbaar")


def v30_dialoog_gebruikt(ctx: Ctx) -> None:
    gebruikt: set[tuple[str, str]] = set()
    for doc in ctx.docs:
        if doc.soort == "room":
            for n in doc.data.get("npcs", []):
                for g in n.get("gesprekken", []):
                    gebruikt.add((doc.hoofdstuk or "", g["dialoog"]))
    for doc in ctx.docs:
        if doc.soort == "dialogue" and (doc.hoofdstuk or "", doc.data["id"]) not in gebruikt:
            ctx.fout("V30", doc, "$.id", f"gesprek '{doc.data['id']}' wordt door geen enkele NPC in dit hoofdstuk gebruikt")


def v31_apparaat_object(ctx: Ctx) -> None:
    gezien: dict[str, str] = {}
    for doc in ctx.docs:
        if doc.soort != "device":
            continue
        o = doc.data["object"]
        if o in gezien:
            ctx.fout("V31", doc, "$.object", f"object '{o}' hoort al bij apparaat '{gezien[o]}'")
        gezien[o] = doc.data["id"]
