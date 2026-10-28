"""Toestandsmodel van de oplosser (docs/systemen/state-en-flags.md, "De oplosser").

`Model` bevat de vaste gegevens van een hoofdstuk; `Sim` is een muteerbare toestand die
de conditie-evaluator kan lezen (zelfde Toestand-interface als de GDScript-kant).
"""
from __future__ import annotations

import json
from dataclasses import dataclass, field
from typing import Any, Optional

from .condities import Toestand, evalueer, tijdstip_minuten, minuten, atomen
from .regels_basis import alle_atomen_diep
from .wereld import Wereld, hoofdstuk_nummer, refs_van

MAX_RONDES = 32


def onmisbare_items(w: Wereld, docs) -> tuple[set[str], set[str], set[str]]:
    """Onmisbaar (state-en-flags.md): (objecten, gebruikte niveaus, gegeven objecten) uit de docs in scope.

    De scope (globale docs, het hoofdstuk, de hub) bepaalt de aanroeper. Moet gelijk blijven aan
    ContentDb._bereken_onmisbaar in GDScript; tests/fixtures/onmisbaar.json bewaakt dat."""
    nodig: set[str] = set()
    niveaus: set[str] = set()
    gegeven: set[str] = set()
    for d in docs:
        for r in refs_van(d):
            if r.soort == "item" and r.extra == "onmisbaar":
                nodig.add(r.id)
            elif r.soort == "niveau" and r.extra == "cond":
                niveaus.add(r.id)
            elif r.soort == "item" and r.extra == "geef":
                gegeven.add(r.id)
    for n in niveaus:
        nodig.update(i for i, it in w.items.items() if n in it.get("geeft_niveaus", []))
    return nodig, niveaus, gegeven


def scope_hoofdstukken(w: Wereld, hoofdstuk: str) -> list[str]:
    """Het hoofdstuk zelf, dan de hub (ch00_...): de actieve knopen (state-en-flags.md)."""
    hub = [h for h in w.spel.get("hoofdstukken", list(w.hoofdstukken)) if h != hoofdstuk and hoofdstuk_nummer(h) == "00" and h in w.hoofdstukken]
    return [hoofdstuk] + hub


@dataclass
class Model:
    w: Wereld
    hoofdstuk: str
    chapter: dict
    scenes: dict[str, dict]
    kamers: dict[str, dict]
    knopen: list[dict]
    events: dict[str, dict]
    gemodelleerd: list[str]
    begin_plek: dict[str, str]
    begin_open: set[str]
    npcs_per_kamer: dict[str, list[dict]]
    niveau_bronnen: dict[str, list[str]]
    problemen: list[str] = field(default_factory=list)
    leg_limiet: int = 1

    @staticmethod
    def bouw(w: Wereld, hoofdstuk: str, docs) -> "Model":
        ch = w.hoofdstukken[hoofdstuk]
        scenes = {sc["id"]: sc for sc in ch["scenes"]}
        kamer_ids = {k for sc in scenes.values() for k in sc["kamers"]}
        kamers = {k: w.kamers[k] for k in kamer_ids if k in w.kamers}
        nr = hoofdstuk_nummer(hoofdstuk)
        eigen_docs = [d for d in docs if d.hoofdstuk is None or hoofdstuk_nummer(d.hoofdstuk) in (nr, "00")]
        # beginplekken
        plek: dict[str, str] = {}
        ouder: dict[str, str] = {}

        def plaats(lijst: list, boven: str, positie_nodig: bool) -> None:
            for x in lijst:
                plek[x["object"]] = boven
                plaats(x.get("inhoud", []), x["object"], False)

        for k in kamers.values():
            plaats(k.get("objecten", []), k["id"], True)
        plaats(ch.get("aanname_bij_start", {}).get("inventaris", []), "inventaris", False)
        nodig, niveaus, gegeven = onmisbare_items(w, eigen_docs)
        bronnen: dict[str, list[str]] = {n: [i for i, it in w.items.items() if n in it.get("geeft_niveaus", [])] for n in niveaus}
        modelleer = {i for i in nodig if i in plek or i in gegeven}
        for i in list(modelleer):                 # voorouders meenemen
            p = plek.get(i)
            while p in plek:
                modelleer.add(p)
                p = plek[p]
        gem = sorted(modelleer)
        begin = {i: plek.get(i, "nergens") for i in gem}
        events = {g["id"]: g for sc in scenes.values() for g in sc.get("gebeurtenissen", [])}
        npcs = {k: kamers[k].get("npcs", []) for k in kamers}
        knopen = [k for h in scope_hoofdstukken(w, hoofdstuk) for k in w.puzzels.get(h, [])]
        return Model(w, hoofdstuk, ch, scenes, kamers, knopen, events, gem, begin, set(), npcs, bronnen)

    def event_scene(self, ev_id: str) -> str:
        return next(s for s, sc in self.scenes.items() if any(g["id"] == ev_id for g in sc.get("gebeurtenissen", [])))


class Sim(Toestand):
    """Muteerbare oplosser-toestand."""

    def __init__(self, m: Model) -> None:
        super().__init__()
        self.m = m
        self.kamer = m.chapter["start"]["kamer"]
        self.scene = m.chapter["start"]["scene"]
        self.plek: dict[str, str] = dict(m.begin_plek)
        self.open: set[str] = set(m.begin_open)
        aan = m.chapter.get("aanname_bij_start", {})
        self.tokens: set[str] = set(aan.get("tokens", []))
        self.flags: dict[str, Any] = dict(aan.get("flags", {}))
        self.knopen: set[str] = set()
        self.ev: dict[str, str] = {e: "wacht" for e in m.events}
        self.ontgrendeld: set[str] = {d for d, dev in m.w.apparaten.items() if dev["vergrendeling"]["type"] == "geen"}
        self.net_actief: list[str] = []
        self.opgelost_nu: list[str] = []      # knopen die in deze stap vuurden (voor statistiek)
        self.ev_start(self.scene)

    # ---- toestand <-> sleutel
    def sleutel(self) -> tuple:
        return (self.kamer, self.scene, tuple(self.plek[i] for i in self.m.gemodelleerd), frozenset(self.open),
                frozenset(self.tokens), frozenset(self.flags.items()), frozenset(self.knopen),
                tuple(self.ev[e] for e in self.m.events), frozenset(self.ontgrendeld))

    @staticmethod
    def van_sleutel(m: Model, s: tuple) -> "Sim":
        sim = Sim.__new__(Sim)
        Toestand.__init__(sim)
        sim.m = m
        sim.kamer, sim.scene = s[0], s[1]
        sim.plek = dict(zip(m.gemodelleerd, s[2]))
        sim.open, sim.tokens, sim.flags = set(s[3]), set(s[4]), dict(s[5])
        sim.knopen = set(s[6])
        sim.ev = dict(zip(m.events, s[7]))
        sim.ontgrendeld = set(s[8])
        sim.net_actief, sim.opgelost_nu = [], []
        return sim

    # ---- Toestand-interface
    def item_bekend(self, item: str) -> bool: return item in self.m.w.items
    def _keten(self, item: str) -> list[str]:
        keten, huidig, n = [], item, 0
        if item not in self.plek:
            return ["nergens"]
        while huidig in self.plek and n < 64:
            huidig = self.plek[huidig]
            keten.append(huidig)
            n += 1
        return keten
    def heeft(self, item: str) -> bool: return "inventaris" in self._keten(item)
    def ligt(self, item: str, plek: str) -> bool: return plek in self._keten(item)
    def heeft_token(self, token: str) -> bool: return token in self.tokens
    def flag_waarde(self, flag: str) -> Any:
        if flag in self.flags:
            return self.flags[flag]
        f = self.m.w.flags.get(flag)
        return None if f is None else f["start"]
    def knoop_opgelost(self, knoop: str) -> bool: return knoop in self.knopen
    def huidige_kamer(self) -> str: return self.kamer
    def huidige_scene(self) -> str: return self.scene
    def gebeurtenis_status(self, gebeurtenis: str) -> str:
        if gebeurtenis in self.ev:
            return "wacht" if self.ev[gebeurtenis] == "pauze" else self.ev[gebeurtenis]
        return "wacht" if gebeurtenis in self.m.w.gebeurtenissen else ""
    def kloktijd_minuten(self) -> int: return minuten(self.m.scenes[self.scene]["tijd"]["tijd"])
    def scenetijd_minuten(self) -> int: return tijdstip_minuten(self.m.scenes[self.scene]["tijd"])
    def heeft_niveau(self, niveau: str) -> bool: return any(self.heeft(i) for i in self.m.niveau_bronnen.get(niveau, []))
    def apparaat_toestand(self, apparaat: str) -> str:
        if apparaat not in self.m.w.apparaten:
            return ""
        return "ontgrendeld" if apparaat in self.ontgrendeld else "vergrendeld"
    def benoemd(self, naam: str) -> Any: return self.m.w.condities.get(naam)

    def waar(self, c: Any) -> bool:
        return evalueer(c, self)

    # ---- plekken
    def wortel(self, item: str) -> Optional[str]:
        """Waar het object uiteindelijk ligt, alleen als alle containers eromheen open zijn."""
        p = self.plek.get(item)
        while p is not None and p in self.plek:
            if p not in self.open:
                return None
            p = self.plek[p]
        return p

    def bereikbaar(self, item: str) -> bool:
        w = self.wortel(item)
        return w == "inventaris" or (w is not None and w == self.kamer)

    def npc_aanwezig(self, npc: dict) -> bool:
        return self.waar(npc.get("aanwezig"))

    # ---- gebeurtenissen
    def ev_start(self, scene_id: str) -> None:
        for e, g in self.m.events.items():
            if self.m.event_scene(e) == scene_id:
                self.ev[e] = "actief" if g["start"] == "bij_begin" else "wacht"
                if self.ev[e] == "actief":
                    self.net_actief.append(e)

    def naar_scene(self, nieuw: str, kamer: str | None = None) -> None:
        for e in self.m.events:
            if self.m.event_scene(e) == self.scene:
                self.ev[e] = "voorbij"
        self.scene = nieuw
        if kamer:
            self.kamer = kamer
        self.ev_start(nieuw)

    def scene_blokkade(self, nieuw: str) -> Optional[str]:
        """O9: pakbaar onmisbaar object in een kamer die in de nieuwe scène niet meer bestaat."""
        toegestaan = set(self.m.scenes[nieuw]["kamers"])
        for i in self.m.gemodelleerd:
            if not self.m.w.items[i].get("pakbaar"):
                continue
            w = self.plek[i]
            while w in self.plek:
                w = self.plek[w]
            if w not in ("inventaris", "nergens") and w not in toegestaan:
                return i
        return None

    # ---- effecten
    def voer_uit(self, effecten: list[dict]) -> None:
        for e in effecten:
            if "zet_flag" in e:
                self.flags[e["zet_flag"]] = e.get("waarde", True)
            elif "wis_flag" in e:
                f = self.m.w.flags.get(e["wis_flag"], {})
                self.flags[e["wis_flag"]] = False if f.get("type") == "bool" else 0
            elif "geef_token" in e:
                self.tokens.add(e["geef_token"])
            elif "geef_object" in e:
                if e["geef_object"] in self.plek:
                    self.plek[e["geef_object"]] = "inventaris"
            elif "verplaats_object" in e:
                v = e["verplaats_object"]
                if v["object"] in self.plek:
                    self.plek[v["object"]] = v["naar"]
            elif "verwijder_object" in e:
                if e["verwijder_object"] in self.plek:
                    self.plek[e["verwijder_object"]] = "nergens"
                    self.open.discard(e["verwijder_object"])
            elif "start_gebeurtenis" in e:
                if self.ev.get(e["start_gebeurtenis"]) == "wacht":
                    self.ev[e["start_gebeurtenis"]] = "actief"
                    self.net_actief.append(e["start_gebeurtenis"])
            elif "stop_gebeurtenis" in e:
                self.stop(e["stop_gebeurtenis"])
            elif "naar_scene" in e:
                self.naar_scene(e["naar_scene"], e.get("kamer"))
            elif "naar_kamer" in e:
                self.kamer = e["naar_kamer"]

    def stop(self, ev: str) -> None:
        g = self.m.events.get(ev)
        if g is None or self.ev[ev] == "voorbij":
            return
        self.ev[ev] = "pauze" if g.get("herhaal_na_s") else "voorbij"

    # ---- knopen
    def in_aanmerking(self, k: dict) -> bool:
        return k["id"] not in self.knopen or bool(k.get("herhaalbaar"))

    def blokkeert(self, k: dict) -> bool:
        """Vuurregel 2a: een naar_scene-effect dat O9 zou weigeren laat de knoop niet vuren."""
        return any("naar_scene" in e and self.scene_blokkade(e["naar_scene"]) for e in k.get("effecten", []))

    def vuur_trigger(self, trigger: dict) -> Optional[str]:
        """Vuurt de eerste knoop met deze trigger waarvan vereist klopt. Geeft knoop-id of None.
        Is die knoop geblokkeerd door 2a, dan vuurt er niets (zoals de engine)."""
        for k in self.m.knopen:
            if k["trigger"] != trigger or not self.in_aanmerking(k) or not self.waar(k.get("vereist")):
                continue
            if self.blokkeert(k):
                return None
            self._vuur(k)
            return k["id"]
        return None

    def _vuur(self, k: dict) -> None:
        self.voer_uit(k.get("effecten", []))
        self.knopen.add(k["id"])
        self.opgelost_nu.append(k["id"])

    def normaliseer(self) -> bool:
        """Automatische knopen, gebeurtenisstarts en -triggers tot niets meer verandert. False = kring."""
        for _ in range(MAX_RONDES):
            veranderd = False
            for e, g in self.m.events.items():
                if self.ev[e] == "wacht" and isinstance(g["start"], dict) and self.m.event_scene(e) == self.scene \
                        and self.waar(g["start"]["als"]):
                    self.ev[e] = "actief"
                    self.net_actief.append(e)
                    veranderd = True
            while self.net_actief:
                e = self.net_actief.pop(0)
                if self.vuur_trigger({"gebeurtenis": e}):
                    veranderd = True
            for k in self.m.knopen:
                if k["trigger"] == {"automatisch": True} and self.in_aanmerking(k) and self.waar(k.get("vereist")) \
                        and not self.blokkeert(k):
                    self._vuur(k)
                    veranderd = True
            if not veranderd:
                return True
        return False
