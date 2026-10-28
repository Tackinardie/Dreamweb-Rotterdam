"""De oplosser: doorzoekt de toestandsruimte van de puzzelgraaf van een hoofdstuk."""
from __future__ import annotations

from collections import deque
from dataclasses import dataclass, field
from typing import Iterator

from .oplosser_sim import Model, Sim
from .wereld import Wereld, hoofdstuk_nummer, refs_van


@dataclass
class DoodlopendeStaat:
    pad: list[str]
    oorzaak: str


@dataclass
class Resultaat:
    hoofdstuk: str
    oplosbaar: bool = False
    route: list[str] = field(default_factory=list)
    staten: int = 0
    afgekapt: bool = False
    doodlopend: list[DoodlopendeStaat] = field(default_factory=list)
    aantal_doodlopend: int = 0
    onbevestigd: int = 0
    kandidaten_niet_gecontroleerd: int = 0
    aantal_unieke_ingangen: int = 0
    nooit_vurend: list[str] = field(default_factory=list)
    tokens_nooit_gegeven: list[str] = field(default_factory=list)
    tokens_nooit_gebruikt: list[str] = field(default_factory=list)
    max_open_hoofd: int = 0
    problemen: list[str] = field(default_factory=list)


def gesprek_regels(sim: Sim, npc: dict) -> tuple[str | None, set[str]]:
    """Welk gesprek start deze NPC nu, en welke regels zijn daarin bereikbaar?"""
    dlg_id = next((g["dialoog"] for g in npc.get("gesprekken", []) if sim.waar(g.get("als"))), None)
    if dlg_id is None or dlg_id not in sim.m.w.dialogen:
        return None, set()
    d = sim.m.w.dialogen[dlg_id]
    regels = {r["id"]: r for r in d["regels"]}
    start = d["start"]
    if isinstance(start, list):
        start = next((x["regel"] for x in start if sim.waar(x.get("als"))), None)
    bereikt: set[str] = set()
    rij = [start] if start in regels else []
    while rij:
        n = rij.pop()
        if n in bereikt:
            continue
        bereikt.add(n)
        r = regels[n]
        opvolgers = [r.get("volgende")] + [k.get("volgende") for k in r.get("keuzes", []) if sim.waar(k.get("als"))]
        rij += [x for x in opvolgers if x in regels]
    return dlg_id, bereikt


def _mogelijk(sim: Sim, t: dict) -> bool:
    w = sim.m.w
    if "gebruik" in t:
        return sim.bereikbaar(t["gebruik"]) and (("met" not in t) or sim.bereikbaar(t["met"]))
    if "lees" in t:
        return sim.bereikbaar(t["lees"]) and "lees" in w.items[t["lees"]]["acties"]
    if "bekijk" in t:
        return sim.bereikbaar(t["bekijk"])
    if "geef" in t:
        if sim.wortel(t["geef"]) != "inventaris":
            return False
        return any(n["personage"] == t["aan"] and sim.npc_aanwezig(n) for n in sim.m.npcs_per_kamer.get(sim.kamer, []))
    if "dialoog" in t:
        for n in sim.m.npcs_per_kamer.get(sim.kamer, []):
            if sim.npc_aanwezig(n):
                dlg, regels = gesprek_regels(sim, n)
                if dlg == t["dialoog"] and t["regel"] in regels:
                    return True
        return False
    if "apparaat" in t:
        dev = w.apparaten.get(t["apparaat"])
        if dev is None or not sim.bereikbaar(dev["object"]) or t["apparaat"] not in sim.ontgrendeld:
            return False
        app = next((a for a in dev["apps"] if a["id"] == t["app"]), None)
        item = next((x for x in (app or {}).get("items", []) if x["id"] == t["item"]), None)
        return app is not None and item is not None and sim.waar(app.get("als")) and sim.waar(item.get("als"))
    if "combineer" in t:
        return all(x in sim.tokens for x in t["combineer"])
    return False


def acties(m: Model, sleutel: tuple, problemen: list[str]) -> Iterator[tuple[str, tuple]]:
    """Alle acties vanuit een toestand: (label, nieuwe toestand)."""
    basis = Sim.van_sleutel(m, sleutel)
    w = m.w

    def klaar(label: str, sim: Sim) -> Iterator[tuple[str, tuple]]:
        if not sim.normaliseer():
            problemen.append(f"kring van automatische knopen na '{label}' (meer dan 32 rondes)")
        nieuw = sim.sleutel()
        if nieuw != sleutel:
            yield label, nieuw

    def kopie() -> Sim:
        return Sim.van_sleutel(m, sleutel)

    # lopen
    kamer = m.kamers.get(basis.kamer, {})
    for u in kamer.get("uitgangen", []):
        doelen = [u] if "naar_kamer" in u else u.get("bestemmingen", [])
        for d in doelen:
            if not basis.waar(d.get("vereist")) or d["naar_kamer"] not in m.kamers:
                continue
            naar = d.get("naar_scene") or (u.get("naar_scene") if d is u else None)
            if naar and naar not in m.scenes:
                continue
            doel_scene = naar or basis.scene
            if d["naar_kamer"] not in m.scenes[doel_scene]["kamers"]:
                continue
            if naar and naar != basis.scene and basis.scene_blokkade(naar):
                continue
            sim = kopie()
            if naar and naar != basis.scene:
                sim.naar_scene(naar)
            sim.kamer = d["naar_kamer"]
            sim.vuur_trigger({"betreed": d["naar_kamer"]})
            yield from klaar(f"loop naar {d['naar_kamer']} via {u['id']}", sim)
    # pakken, neerleggen, openen
    weggelegd = sum(1 for j in m.gemodelleerd if basis.plek[j] in m.kamers and basis.plek[j] != m.begin_plek[j])
    for i in m.gemodelleerd:
        it = w.items[i]
        wortel = basis.wortel(i)
        if it.get("pakbaar") and wortel == basis.kamer:
            sim = kopie()
            sim.plek[i] = "inventaris"
            sim.vuur_trigger({"pak": i})
            yield from klaar(f"pak {i}", sim)
        if it.get("pakbaar") and wortel == "inventaris" and kamer.get("neerleggen", True):
            if not (weggelegd >= m.leg_limiet and basis.kamer != m.begin_plek[i]):
                sim = kopie()
                sim.plek[i] = basis.kamer
                yield from klaar(f"leg {i} neer in {basis.kamer}", sim)
        cont = it.get("container")
        if cont and i not in basis.open and wortel in ("inventaris", basis.kamer) and basis.waar(cont.get("open_vereist")):
            sim = kopie()
            sim.open.add(i)
            sim.vuur_trigger({"open": i})
            yield from klaar(f"open {i}", sim)
    # triggers van knopen
    gezien: set[str] = set()
    for k in m.knopen:
        t = k["trigger"]
        sleutel_t = repr(sorted(t.items()))
        if sleutel_t in gezien or not _mogelijk(basis, t):
            continue
        gezien.add(sleutel_t)
        sim = kopie()
        if sim.vuur_trigger(t):
            yield from klaar(_label(t, basis), sim)
    # apparaten ontgrendelen
    for dev_id, dev in w.apparaten.items():
        if dev_id in basis.ontgrendeld or dev_id not in {d for d in w.apparaten} or not basis.bereikbaar(dev["object"]):
            continue
        v = dev["vergrendeling"]
        if v.get("sleutel_token") in basis.tokens and basis.waar(v.get("extra_vereist")):
            sim = kopie()
            sim.ontgrendeld.add(dev_id)
            sim.vuur_trigger({"ontgrendel": dev_id})
            yield from klaar(f"ontgrendel {dev_id}", sim)
    # wachten op gebeurtenissen
    for e, g in m.events.items():
        status = basis.ev[e]
        if m.event_scene(e) != basis.scene:
            continue
        if status == "actief" and g.get("duur_s"):
            sim = kopie()
            sim.stop(e)
            yield from klaar(f"wacht tot gebeurtenis {e} voorbij is", sim)
        elif status == "pauze":
            sim = kopie()
            if isinstance(g["start"], dict):
                sim.ev[e] = "wacht"
            else:
                sim.ev[e] = "actief"
                sim.net_actief.append(e)
            yield from klaar(f"wacht tot gebeurtenis {e} opnieuw begint", sim)


def _label(t: dict, sim: Sim) -> str:
    if "gebruik" in t:
        return f"gebruik {t['gebruik']}" + (f" met {t['met']}" if "met" in t else "")
    if "lees" in t: return f"lees {t['lees']}"
    if "bekijk" in t: return f"bekijk {t['bekijk']}"
    if "geef" in t: return f"geef {t['geef']} aan {t['aan']}"
    if "dialoog" in t: return f"praat: bereik {t['dialoog']}.{t['regel']}"
    if "apparaat" in t: return f"open {t['item']} in {t['app']} op {t['apparaat']}"
    if "combineer" in t: return f"combineer {t['combineer'][0]} met {t['combineer'][1]}"
    return str(t)


def _oorzaak(m: Model, s: tuple) -> str:
    sim = Sim.van_sleutel(m, s)
    weg = [i for i in m.gemodelleerd if sim.plek[i] == "nergens" and m.begin_plek[i] != "nergens"]
    if weg:
        return f"onmisbaar object verdwenen: {', '.join(weg)} (verwijderd of opgegaan)"
    vast = [i for i in m.gemodelleerd if sim.plek[i] not in ("inventaris", "nergens") and not _bereikbaar_later(sim, i)]
    if vast:
        return f"onmisbaar object in een niet meer bereikbare kamer: {', '.join(vast)}"
    kamer = sim.m.kamers.get(sim.kamer, {})
    uitgangen = kamer.get("uitgangen", [])
    if uitgangen and not any(
            sim.waar(d.get("vereist")) for u in uitgangen for d in ([u] if "naar_kamer" in u else u.get("bestemmingen", []))):
        return f"alle uitgangen van {sim.kamer} zijn dicht en de speler heeft niet wat de deuren vragen"
    voorbij = [e for e, st in sim.ev.items() if st == "voorbij"]
    if voorbij:
        return f"gebeurtenis(sen) voorbij: {', '.join(voorbij)}"
    return "geen directe oorzaak gevonden; bekijk de toestand na dit pad"


def _bereikbaar_later(sim: Sim, item: str) -> bool:
    p = sim.plek[item]
    while p in sim.plek:
        p = sim.plek[p]
    return p == "inventaris" or p in sim.m.scenes[sim.scene]["kamers"]


MAX_KANDIDATEN = 5000
BEVESTIG_CAP = 30_000


def _bevestig(m: Model, begin: tuple, limiet: int, doel_cond, levend: set) -> str:
    """Zoekt vanuit een kandidaat met een ruimere limiet. 'levend', 'dood' (gebied uitgeput) of 'onbevestigd' (cap)."""
    oud, m.leg_limiet = m.leg_limiet, limiet
    try:
        gezien = {begin}
        rij = deque([begin])
        while rij:
            s = rij.popleft()
            if s in levend or Sim.van_sleutel(m, s).waar(doel_cond):
                return "levend"
            for _, n in acties(m, s, []):
                if n not in gezien:
                    if len(gezien) >= BEVESTIG_CAP:
                        return "onbevestigd"
                    gezien.add(n)
                    rij.append(n)
        return "dood"
    finally:
        m.leg_limiet = oud


def _pad(ouder: dict, s: tuple) -> list[str]:
    uit: list[str] = []
    while ouder[s] is not None:
        s, label = ouder[s]
        uit.append(label)
    return uit[::-1]


def los_op(w: Wereld, hoofdstuk: str, docs, max_staten: int = 1_000_000, leg_limiet: int = 1) -> Resultaat:
    m = Model.bouw(w, hoofdstuk, docs)
    m.leg_limiet = leg_limiet
    res = Resultaat(hoofdstuk)
    start_sim = Sim(m)
    start_sim.normaliseer()
    begin = start_sim.sleutel()
    ouder: dict[tuple, tuple | None] = {begin: None}
    opvolgers: dict[tuple, list[tuple]] = {}
    doelen: list[tuple] = []
    rij = deque([begin])
    doel_cond = m.chapter.get("doel")
    eerste_doel: tuple | None = None
    while rij:
        s = rij.popleft()
        sim = Sim.van_sleutel(m, s)
        if sim.waar(doel_cond):
            doelen.append(s)
            eerste_doel = eerste_doel or s
            opvolgers[s] = []
            continue
        volgende = []
        for label, n in acties(m, s, res.problemen):
            volgende.append(n)
            if n not in ouder:
                if len(ouder) >= max_staten:
                    res.afgekapt = True
                    continue
                ouder[n] = (s, label)
                rij.append(n)
        opvolgers[s] = volgende
    res.staten = len(ouder)
    res.oplosbaar = eerste_doel is not None
    if eerste_doel is not None:
        res.route = _pad(ouder, eerste_doel)
    if not res.afgekapt:
        levend = set(doelen)
        omgekeerd: dict[tuple, list[tuple]] = {}
        for s, lijst in opvolgers.items():
            for n in lijst:
                omgekeerd.setdefault(n, []).append(s)
        rij = deque(levend)
        while rij:
            for v in omgekeerd.get(rij.popleft(), []):
                if v not in levend:
                    levend.add(v)
                    rij.append(v)
        dood = [s for s in ouder if s not in levend]
        ingang = [s for s in dood if ouder[s] is None or ouder[s][0] in levend]
        # De limiet op neergelegde objecten kan vluchtwegen afsnijden; bevestig elke kandidaat met een ruimere limiet.
        gemeld: set[tuple] = set()
        if res.oplosbaar:
            for s in ingang[:MAX_KANDIDATEN]:
                uitkomst = _bevestig(m, s, leg_limiet + 1, doel_cond, levend)
                if uitkomst == "dood":
                    pad = _pad(ouder, s)
                    oorzaak = _oorzaak(m, s)
                    sleutel = (oorzaak, pad[-1] if pad else "")
                    if sleutel not in gemeld:
                        gemeld.add(sleutel)
                        res.doodlopend.append(DoodlopendeStaat(pad, oorzaak))
                        res.aantal_unieke_ingangen += 1
                elif uitkomst == "onbevestigd":
                    res.onbevestigd += 1
            res.kandidaten_niet_gecontroleerd = max(0, len(ingang) - MAX_KANDIDATEN)
        res.aantal_doodlopend = len(res.doodlopend)
    # statistiek
    gevuurd = set().union(*(set(s[6]) for s in ouder)) if ouder else set()
    res.nooit_vurend = [k["id"] for k in m.knopen if k["id"] not in gevuurd]
    tokens_gehad = set().union(*(set(s[4]) for s in ouder)) if ouder else set()
    nr = hoofdstuk_nummer(hoofdstuk)
    eigen = [t for t in w.tokens if any(d.soort == "chapter" and d.hoofdstuk == hoofdstuk and t in [x["id"] for x in d.data.get("tokens", [])] for d in docs)]
    res.tokens_nooit_gegeven = [t for t in eigen if t not in tokens_gehad]
    gebruikt = {r.id for d in docs for r in refs_van(d) if r.soort == "token" and r.extra in ("cond", "sleutel", "combineer")}
    res.tokens_nooit_gebruikt = [t for t in eigen if t not in gebruikt]
    if len(ouder) <= 200_000:
        hoofd = [k for k in m.knopen if k.get("pad", "hoofd") == "hoofd"]
        for s in ouder:
            sim = Sim.van_sleutel(m, s)
            open_ = sum(1 for k in hoofd if k["id"] not in sim.knopen and sim.waar(k.get("vereist")))
            res.max_open_hoofd = max(res.max_open_hoofd, open_)
    return res
