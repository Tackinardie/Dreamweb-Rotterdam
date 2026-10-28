"""Ruimtelijke regels V32 (beloopbaarheid, kamerweergave.md W13/V32) en V33 (schaduwbudget, W8/W22)."""
from __future__ import annotations

from .regels_basis import Ctx

ACHT = [(0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1)]
MAX_SCHADUW = 6


def _vakken(g: dict) -> list[tuple[int, int]]:
    return [(g["x"] + dx, g["y"] + dy) for dy in range(g.get("hoogte", 1)) for dx in range(g.get("breedte", 1))]


def _pos(p: dict) -> tuple[int, int]:
    return (p["x"], p["y"])


def _bereikbaar(start: tuple[int, int], b: int, h: int, dicht: set) -> set:
    def vrij(v):
        return 0 <= v[0] < b and 0 <= v[1] < h and v not in dicht

    gezien, rij = {start}, [start]
    while rij:
        v = rij.pop()
        for dx, dy in ACHT:
            w = (v[0] + dx, v[1] + dy)
            if w in gezien or not vrij(w):
                continue
            if dx and dy and not (vrij((v[0] + dx, v[1])) and vrij((v[0], v[1] + dy))):
                continue
            gezien.add(w)
            rij.append(w)
    return gezien


def v32_beloopbaar(ctx: Ctx) -> None:
    for doc in ctx.docs:
        if doc.soort != "room":
            continue
        d = doc.data
        b, h = d["afmeting"]["breedte"], d["afmeting"]["hoogte"]
        geblokkeerd = {v for g in d.get("geblokkeerd", []) for v in _vakken(g)}
        vast: dict[tuple[int, int], str] = {}
        for i, o in enumerate(d.get("objecten", [])):
            if ctx.w.items.get(o["object"], {}).get("pakbaar"):
                continue
            v = _pos(o["positie"])
            if v in vast:
                ctx.fout("V32", doc, f"$.objecten[{i}].positie", f"niet-pakbare objecten '{vast[v]}' en '{o['object']}' staan op hetzelfde vak {v}")
            vast[v] = o["object"]
        dicht = geblokkeerd | set(vast)
        punten = [("start_positie", "$.start_positie", d["start_positie"])] if "start_positie" in d else []
        punten += [(f"uitgang '{u['id']}'", f"$.uitgangen[{i}].positie", u["positie"]) for i, u in enumerate(d.get("uitgangen", []))]
        punten += [(f"NPC '{n['id']}'", f"$.npcs[{i}].positie", n["positie"]) for i, n in enumerate(d.get("npcs", []))]
        for wat, pad, p in punten:
            if _pos(p) in geblokkeerd:
                ctx.fout("V32", doc, pad, f"{wat} staat op een geblokkeerd vak {_pos(p)}")
        vrij_start = [_pos(p) for wat, _, p in punten if (wat == "start_positie" or wat.startswith("uitgang")) and _pos(p) not in dicht]
        if not vrij_start:
            continue
        bereik = _bereikbaar(vrij_start[0], b, h, dicht)
        for wat, pad, p in punten:
            if not wat.startswith("NPC") and _pos(p) not in dicht and _pos(p) not in bereik:
                ctx.fout("V32", doc, pad, f"{wat} is niet bereikbaar vanaf {vrij_start[0]}")
        for i, o in enumerate(d.get("objecten", [])):
            v = _pos(o["positie"])
            if not any((v[0] + dx, v[1] + dy) in bereik for dx, dy in [(0, 0)] + ACHT):
                ctx.fout("V32", doc, f"$.objecten[{i}].positie", f"object '{o['object']}' op {v} heeft geen bereikbaar vak ernaast")


def v33_schaduwbudget(ctx: Ctx) -> None:
    for doc in ctx.docs:
        if doc.soort != "room":
            continue
        n = sum(1 for lamp in doc.data.get("lichten", []) if lamp.get("schaduw"))
        if n > MAX_SCHADUW:
            ctx.fout("V33", doc, "$.lichten", f"{n} lichten met schaduw; hoogstens {MAX_SCHADUW} (kamerweergave.md W8)")
