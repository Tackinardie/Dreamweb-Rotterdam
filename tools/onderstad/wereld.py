"""Indexen over alle content en een verzamelaar van alle verwijzingen (voor de validator)."""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any

from .condities import atomen
from .inhoud import Doc, Inhoud

LOKAAL = re.compile(r"^ch(\d\d)_")
STAAT_EFFECTEN = {
    "zet_flag", "wis_flag", "geef_token", "geef_object", "verplaats_object", "verwijder_object",
    "start_gebeurtenis", "stop_gebeurtenis", "naar_scene", "naar_kamer",
}


def hoofdstuk_nummer(ident: str) -> str | None:
    m = LOKAAL.match(ident)
    return m.group(1) if m else None


@dataclass
class Ref:
    """Een verwijzing vanuit content naar iets met een id."""
    soort: str          # item, token, personage, flag, conditie, kamer, scene, gebeurtenis, knoop, dialoog,
                        # apparaat, niveau, gebouw, tekst, cue, regel, uitgang, app, appitem
    id: str
    doc: Doc
    pad: str
    extra: Any = None   # cue: verwacht soort; regel: dialoog; uitgang: kamer; app: apparaat; appitem: (apparaat, app)
    hub_ok: bool = False


@dataclass
class Def:
    soort: str          # item, token, personage, flag, conditie, kamer, scene, gebeurtenis, knoop, dialoog, apparaat, cue
    id: str
    doc: Doc
    pad: str
    lokaal: bool = False


def plek_ref(plek: str, doc: Doc, pad: str, out: list[Ref]) -> None:
    if plek == "inventaris" or plek == "nergens":
        return
    out.append(Ref("kamer" if LOKAAL.match(plek) else "item", plek, doc, pad))


def cond_refs(c: Any, doc: Doc, pad: str, out: list[Ref]) -> None:
    for soort, node, p in atomen(c, pad):
        if soort == "heeft":
            out.append(Ref("item", node["heeft"], doc, p, extra="onmisbaar"))
        elif soort == "ligt":
            out.append(Ref("item", node["ligt"]["object"], doc, p + ".object", extra="onmisbaar"))
            plek_ref(node["ligt"]["in"], doc, p + ".in", out)
        elif soort == "flag":
            out.append(Ref("flag", node["flag"], doc, p, extra=("cond", node)))
        elif soort in ("token", "knoop", "kamer", "scene", "gebeurtenis", "niveau", "apparaat", "conditie"):
            out.append(Ref(soort, node[soort], doc, p, extra="cond"))


def tekst_ref(sleutel: str | None, doc: Doc, pad: str, out: list[Ref]) -> None:
    if sleutel:
        out.append(Ref("tekst", sleutel, doc, pad))


def variant_refs(v: Any, doc: Doc, pad: str, out: list[Ref]) -> None:
    if isinstance(v, str):
        tekst_ref(v, doc, pad, out)
    elif isinstance(v, list):
        for i, x in enumerate(v):
            cond_refs(x.get("als"), doc, f"{pad}[{i}].als", out)
            tekst_ref(x.get("tekst"), doc, f"{pad}[{i}].tekst", out)


def cue_ref(cue: str | None, doc: Doc, pad: str, out: list[Ref], soort: str = "eenmalig") -> None:
    if cue:
        out.append(Ref("cue", cue, doc, pad, extra=soort))


def effect_refs(effecten: list, doc: Doc, pad: str, out: list[Ref]) -> None:
    for i, e in enumerate(effecten or []):
        p = f"{pad}[{i}]"
        for k, v in e.items():
            if k in ("zet_flag", "wis_flag"):
                out.append(Ref("flag", v, doc, f"{p}.{k}", extra=("zet", e.get("waarde", True)) if k == "zet_flag" else ("wis", None)))
            elif k == "geef_token":
                out.append(Ref("token", v, doc, f"{p}.{k}", extra="geef"))
            elif k in ("geef_object", "verwijder_object"):
                out.append(Ref("item", v, doc, f"{p}.{k}", extra="geef" if k == "geef_object" else "verwijder"))
            elif k == "verplaats_object":
                out.append(Ref("item", v["object"], doc, f"{p}.{k}.object", extra="geef"))
                plek_ref(v["naar"], doc, f"{p}.{k}.naar", out)
            elif k in ("start_gebeurtenis", "stop_gebeurtenis"):
                out.append(Ref("gebeurtenis", v, doc, f"{p}.{k}"))
            elif k == "naar_scene":
                out.append(Ref("scene", v, doc, f"{p}.{k}"))
                if "kamer" in e:
                    out.append(Ref("kamer", e["kamer"], doc, f"{p}.kamer"))
                    if "uitgang" in e:
                        out.append(Ref("uitgang", e["uitgang"], doc, f"{p}.uitgang", extra=e["kamer"]))
            elif k == "naar_kamer":
                out.append(Ref("kamer", v, doc, f"{p}.{k}"))
                if "uitgang" in e:
                    out.append(Ref("uitgang", e["uitgang"], doc, f"{p}.uitgang", extra=v))
            elif k == "cue":
                cue_ref(v, doc, f"{p}.{k}", out)
            elif k == "mompel":
                tekst_ref(v, doc, f"{p}.{k}", out)


def trigger_refs(t: dict, doc: Doc, pad: str, out: list[Ref]) -> None:
    for k in ("gebruik", "met", "pak", "open", "lees", "bekijk", "geef"):
        if k in t:
            out.append(Ref("item", t[k], doc, f"{pad}.{k}", extra=None if k in ("pak", "bekijk") else "onmisbaar"))
    if "aan" in t:
        out.append(Ref("personage", t["aan"], doc, f"{pad}.aan"))
    if "dialoog" in t:
        out.append(Ref("dialoog", t["dialoog"], doc, f"{pad}.dialoog"))
        out.append(Ref("regel", t["regel"], doc, f"{pad}.regel", extra=t["dialoog"]))
    if "apparaat" in t:
        out.append(Ref("apparaat", t["apparaat"], doc, f"{pad}.apparaat"))
        out.append(Ref("app", t["app"], doc, f"{pad}.app", extra=t["apparaat"]))
        out.append(Ref("appitem", t["item"], doc, f"{pad}.item", extra=(t["apparaat"], t["app"])))
    if "ontgrendel" in t:
        out.append(Ref("apparaat", t["ontgrendel"], doc, f"{pad}.ontgrendel"))
    for i, tk in enumerate(t.get("combineer", [])):
        out.append(Ref("token", tk, doc, f"{pad}.combineer[{i}]", extra="combineer"))
    if "betreed" in t:
        out.append(Ref("kamer", t["betreed"], doc, f"{pad}.betreed"))
    if "gebeurtenis" in t:
        out.append(Ref("gebeurtenis", t["gebeurtenis"], doc, f"{pad}.gebeurtenis"))


def inhoud_items(lijst: list, doc: Doc, pad: str, out: list[Ref]) -> None:
    for i, x in enumerate(lijst or []):
        out.append(Ref("item", x["object"], doc, f"{pad}[{i}].object", extra="plaats"))
        inhoud_items(x.get("inhoud", []), doc, f"{pad}[{i}].inhoud", out)


def niveau_ref(niveau: str, doc: Doc, pad: str, out: list[Ref]) -> None:
    out.append(Ref("niveau", niveau, doc, pad))


def refs_van(doc: Doc) -> list[Ref]:
    out: list[Ref] = []
    d = doc.data
    s = doc.soort
    if s == "spel":
        for i, p in enumerate(d.get("personages", [])):
            tekst_ref(p["naam"], doc, f"$.personages[{i}].naam", out)
        for n, c in d.get("condities", {}).items():
            cond_refs(c, doc, f"$.condities.{n}", out)
    elif s == "items":
        for i, it in enumerate(d.get("items", [])):
            p = f"$.items[{i}]"
            tekst_ref(it["naam"], doc, p + ".naam", out)
            variant_refs(it.get("beschrijving"), doc, p + ".beschrijving", out)
            variant_refs(it.get("leestekst"), doc, p + ".leestekst", out)
            variant_refs(it.get("gebruik_tekst"), doc, p + ".gebruik_tekst", out)
            cont = it.get("container")
            if cont:
                cond_refs(cont.get("open_vereist"), doc, p + ".container.open_vereist", out)
                tekst_ref(cont.get("geweigerd"), doc, p + ".container.geweigerd", out)
            for j, n in enumerate(it.get("geeft_niveaus", [])):
                out.append(Ref("niveau", n, doc, f"{p}.geeft_niveaus[{j}]", extra="geeft"))
            for k, c in it.get("geluid", {}).items():
                cue_ref(c, doc, f"{p}.geluid.{k}", out)
    elif s == "chapter":
        tekst_ref(d["titel"], doc, "$.titel", out)
        if "doelwit" in d:
            out.append(Ref("personage", d["doelwit"], doc, "$.doelwit"))
        st = d["start"]
        out.append(Ref("scene", st["scene"], doc, "$.start.scene"))
        out.append(Ref("kamer", st["kamer"], doc, "$.start.kamer"))
        if "uitgang" in st:
            out.append(Ref("uitgang", st["uitgang"], doc, "$.start.uitgang", extra=st["kamer"]))
        cond_refs(d.get("doel"), doc, "$.doel", out)
        aan = d.get("aanname_bij_start", {})
        inhoud_items(aan.get("inventaris", []), doc, "$.aanname_bij_start.inventaris", out)
        for f, waarde in aan.get("flags", {}).items():
            out.append(Ref("flag", f, doc, f"$.aanname_bij_start.flags.{f}", extra=("zet", waarde)))
        for i, t in enumerate(aan.get("tokens", [])):
            out.append(Ref("token", t, doc, f"$.aanname_bij_start.tokens[{i}]", extra="geef"))
        for i, sc in enumerate(d.get("scenes", [])):
            p = f"$.scenes[{i}]"
            for j, k in enumerate(sc["kamers"]):
                out.append(Ref("kamer", k, doc, f"{p}.kamers[{j}]", hub_ok=True))
            cue_ref(sc.get("muziek"), doc, p + ".muziek", out, "doorlopend")
            for j, g in enumerate(sc.get("gebeurtenissen", [])):
                gp = f"{p}.gebeurtenissen[{j}]"
                if isinstance(g["start"], dict):
                    cond_refs(g["start"]["als"], doc, gp + ".start.als", out)
                cue_ref(g.get("cue_start"), doc, gp + ".cue_start", out)
                cue_ref(g.get("cue_einde"), doc, gp + ".cue_einde", out)
        for i, t in enumerate(d.get("tokens", [])):
            tekst_ref(t["notitie"], doc, f"$.tokens[{i}].notitie", out)
        for i, g in enumerate(d.get("gebouwen", [])):
            tekst_ref(g["naam"], doc, f"$.gebouwen[{i}].naam", out)
            for j, n in enumerate(g["niveaus"]):
                tekst_ref(n["naam"], doc, f"$.gebouwen[{i}].niveaus[{j}].naam", out)
        for n, c in d.get("condities", {}).items():
            cond_refs(c, doc, f"$.condities.{n}", out)
    elif s == "room":
        tekst_ref(d["naam"], doc, "$.naam", out)
        variant_refs(d.get("beschrijving"), doc, "$.beschrijving", out)
        if "niveau" in d:
            niveau_ref(d["niveau"], doc, "$.niveau", out)
        if "gebouw" in d:
            out.append(Ref("gebouw", d["gebouw"], doc, "$.gebouw"))
        for i, c in enumerate(d.get("ambience", [])):
            cue_ref(c, doc, f"$.ambience[{i}]", out, "doorlopend")
        for i, o in enumerate(d.get("objecten", [])):
            out.append(Ref("item", o["object"], doc, f"$.objecten[{i}].object", extra="plaats"))
            inhoud_items(o.get("inhoud", []), doc, f"$.objecten[{i}].inhoud", out)
        for i, u in enumerate(d.get("uitgangen", [])):
            p = f"$.uitgangen[{i}]"
            tekst_ref(u.get("naam"), doc, p + ".naam", out)
            variant_refs(u.get("beschrijving"), doc, p + ".beschrijving", out)
            cond_refs(u.get("vereist"), doc, p + ".vereist", out)
            variant_refs(u.get("geweigerd"), doc, p + ".geweigerd", out)
            if "naar_scene" in u:
                out.append(Ref("scene", u["naar_scene"], doc, p + ".naar_scene"))
            if "naar_kamer" in u:
                out.append(Ref("kamer", u["naar_kamer"], doc, p + ".naar_kamer", hub_ok=True))
            for k, c in u.get("geluid", {}).items():
                cue_ref(c, doc, f"{p}.geluid.{k}", out)
            for j, b in enumerate(u.get("bestemmingen", [])):
                bp = f"{p}.bestemmingen[{j}]"
                out.append(Ref("kamer", b["naar_kamer"], doc, bp + ".naar_kamer", hub_ok=True))
                tekst_ref(b.get("label"), doc, bp + ".label", out)
                cond_refs(b.get("vereist"), doc, bp + ".vereist", out)
                tekst_ref(b.get("geweigerd"), doc, bp + ".geweigerd", out)
                if "naar_scene" in b:
                    out.append(Ref("scene", b["naar_scene"], doc, bp + ".naar_scene"))
        for i, n in enumerate(d.get("npcs", [])):
            p = f"$.npcs[{i}]"
            out.append(Ref("personage", n["personage"], doc, p + ".personage"))
            cond_refs(n.get("aanwezig"), doc, p + ".aanwezig", out)
            variant_refs(n.get("bekijk"), doc, p + ".bekijk", out)
            cue_ref(n.get("geluid"), doc, p + ".geluid", out, "doorlopend")
            for j, g in enumerate(n.get("gesprekken", [])):
                cond_refs(g.get("als"), doc, f"{p}.gesprekken[{j}].als", out)
                out.append(Ref("dialoog", g["dialoog"], doc, f"{p}.gesprekken[{j}].dialoog"))
    elif s == "dialogue":
        for i, x in enumerate(d.get("deelnemers", [])):
            out.append(Ref("personage", x, doc, f"$.deelnemers[{i}]"))
        start = d["start"]
        if isinstance(start, str):
            out.append(Ref("regel", start, doc, "$.start", extra=d["id"]))
        else:
            for i, x in enumerate(start):
                cond_refs(x.get("als"), doc, f"$.start[{i}].als", out)
                out.append(Ref("regel", x["regel"], doc, f"$.start[{i}].regel", extra=d["id"]))
        for i, r in enumerate(d["regels"]):
            p = f"$.regels[{i}]"
            out.append(Ref("personage", r["spreker"], doc, p + ".spreker"))
            tekst_ref(r["tekst"], doc, p + ".tekst", out)
            cue_ref(r.get("cue"), doc, p + ".cue", out)
            if "volgende" in r:
                out.append(Ref("regel", r["volgende"], doc, p + ".volgende", extra=d["id"]))
            for j, k in enumerate(r.get("keuzes", [])):
                kp = f"{p}.keuzes[{j}]"
                tekst_ref(k["tekst"], doc, kp + ".tekst", out)
                cond_refs(k.get("als"), doc, kp + ".als", out)
                if "volgende" in k:
                    out.append(Ref("regel", k["volgende"], doc, kp + ".volgende", extra=d["id"]))
    elif s == "device":
        out.append(Ref("item", d["object"], doc, "$.object", extra="onmisbaar"))
        if "eigenaar" in d:
            out.append(Ref("personage", d["eigenaar"], doc, "$.eigenaar"))
        tekst_ref(d["naam"], doc, "$.naam", out)
        v = d["vergrendeling"]
        if "sleutel_token" in v:
            out.append(Ref("token", v["sleutel_token"], doc, "$.vergrendeling.sleutel_token", extra="sleutel"))
        cond_refs(v.get("extra_vereist"), doc, "$.vergrendeling.extra_vereist", out)
        tekst_ref(v.get("hint"), doc, "$.vergrendeling.hint", out)
        for i, a in enumerate(d["apps"]):
            p = f"$.apps[{i}]"
            tekst_ref(a.get("naam"), doc, p + ".naam", out)
            cond_refs(a.get("als"), doc, p + ".als", out)
            for j, it in enumerate(a["items"]):
                ip = f"{p}.items[{j}]"
                for k in ("afzender", "titel", "tekst"):
                    tekst_ref(it.get(k), doc, f"{ip}.{k}", out)
                cond_refs(it.get("als"), doc, ip + ".als", out)
                cue_ref(it.get("cue"), doc, ip + ".cue", out)
    elif s == "puzzle":
        for i, k in enumerate(d["knopen"]):
            p = f"$.knopen[{i}]"
            trigger_refs(k["trigger"], doc, p + ".trigger", out)
            cond_refs(k.get("vereist"), doc, p + ".vereist", out)
            effect_refs(k.get("effecten", []), doc, p + ".effecten", out)
            tekst_ref(k.get("bij_onvervuld"), doc, p + ".bij_onvervuld", out)
            for n, key in k.get("hints", {}).items():
                tekst_ref(key, doc, f"{p}.hints.{n}", out)
    return out


def defs_van(doc: Doc) -> list[Def]:
    out: list[Def] = []
    d = doc.data
    s = doc.soort
    if s == "spel":
        for i, p in enumerate(d.get("personages", [])):
            out.append(Def("personage", p["id"], doc, f"$.personages[{i}].id"))
        for i, f in enumerate(d.get("flags", [])):
            out.append(Def("flag", f["id"], doc, f"$.flags[{i}].id"))
        for n in d.get("condities", {}):
            out.append(Def("conditie", n, doc, f"$.condities.{n}"))
    elif s == "items":
        for i, it in enumerate(d.get("items", [])):
            out.append(Def("item", it["id"], doc, f"$.items[{i}].id"))
    elif s == "chapter":
        for i, f in enumerate(d.get("flags", [])):
            out.append(Def("flag", f["id"], doc, f"$.flags[{i}].id", lokaal=True))
        for i, t in enumerate(d.get("tokens", [])):
            out.append(Def("token", t["id"], doc, f"$.tokens[{i}].id"))
        for n in d.get("condities", {}):
            out.append(Def("conditie", n, doc, f"$.condities.{n}", lokaal=True))
        for i, sc in enumerate(d.get("scenes", [])):
            out.append(Def("scene", sc["id"], doc, f"$.scenes[{i}].id", lokaal=True))
            for j, g in enumerate(sc.get("gebeurtenissen", [])):
                out.append(Def("gebeurtenis", g["id"], doc, f"$.scenes[{i}].gebeurtenissen[{j}].id", lokaal=True))
    elif s == "room":
        out.append(Def("kamer", d["id"], doc, "$.id", lokaal=True))
    elif s == "dialogue":
        out.append(Def("dialoog", d["id"], doc, "$.id", lokaal=True))
    elif s == "device":
        out.append(Def("apparaat", d["id"], doc, "$.id", lokaal=True))
    elif s == "puzzle":
        for i, k in enumerate(d["knopen"]):
            out.append(Def("knoop", k["id"], doc, f"$.knopen[{i}].id", lokaal=True))
    elif s == "cues":
        for i, c in enumerate(d.get("cues", [])):
            out.append(Def("cue", c["id"], doc, f"$.cues[{i}].id"))
    return out


@dataclass
class Wereld:
    """Alle content als doorzoekbare indexen. Wordt door de validator en de oplosser gebruikt."""
    inh: Inhoud
    spel: dict = field(default_factory=dict)
    items: dict[str, dict] = field(default_factory=dict)
    hoofdstukken: dict[str, dict] = field(default_factory=dict)       # mapnaam -> chapter.json
    kamers: dict[str, dict] = field(default_factory=dict)
    kamer_doc: dict[str, Doc] = field(default_factory=dict)
    scenes: dict[str, dict] = field(default_factory=dict)
    scene_hoofdstuk: dict[str, str] = field(default_factory=dict)
    gebeurtenissen: dict[str, dict] = field(default_factory=dict)
    gebeurtenis_scene: dict[str, str] = field(default_factory=dict)
    puzzels: dict[str, list[dict]] = field(default_factory=dict)      # mapnaam -> knopen
    knopen: dict[str, dict] = field(default_factory=dict)
    knoop_hoofdstuk: dict[str, str] = field(default_factory=dict)
    dialogen: dict[str, dict] = field(default_factory=dict)
    apparaten: dict[str, dict] = field(default_factory=dict)
    condities: dict[str, Any] = field(default_factory=dict)
    flags: dict[str, dict] = field(default_factory=dict)
    tokens: dict[str, dict] = field(default_factory=dict)
    personages: dict[str, dict] = field(default_factory=dict)
    cues: dict[str, dict] = field(default_factory=dict)
    teksten: dict[str, dict[str, Doc]] = field(default_factory=dict)  # taal -> sleutel -> doc

    @staticmethod
    def bouw(inh: Inhoud, docs: list[Doc]) -> "Wereld":
        w = Wereld(inh)
        for doc in docs:
            d, s = doc.data, doc.soort
            if s == "spel":
                w.spel = d
                w.personages.update({p["id"]: p for p in d.get("personages", [])})
                w.flags.update({f["id"]: f for f in d.get("flags", [])})
                w.condities.update(d.get("condities", {}))
            elif s == "items":
                w.items.update({i["id"]: i for i in d.get("items", [])})
            elif s == "chapter":
                h = doc.hoofdstuk or d["id"]
                w.hoofdstukken[h] = d
                w.flags.update({f["id"]: f for f in d.get("flags", [])})
                w.tokens.update({t["id"]: t for t in d.get("tokens", [])})
                w.condities.update(d.get("condities", {}))
                for sc in d.get("scenes", []):
                    w.scenes[sc["id"]] = sc
                    w.scene_hoofdstuk[sc["id"]] = h
                    for g in sc.get("gebeurtenissen", []):
                        w.gebeurtenissen[g["id"]] = g
                        w.gebeurtenis_scene[g["id"]] = sc["id"]
            elif s == "room":
                w.kamers[d["id"]] = d
                w.kamer_doc[d["id"]] = doc
            elif s == "puzzle":
                h = doc.hoofdstuk or d["hoofdstuk"]
                w.puzzels[h] = d["knopen"]
                for k in d["knopen"]:
                    w.knopen[k["id"]] = k
                    w.knoop_hoofdstuk[k["id"]] = h
            elif s == "dialogue":
                w.dialogen[d["id"]] = d
            elif s == "device":
                w.apparaten[d["id"]] = d
            elif s == "cues":
                w.cues.update({c["id"]: c for c in d.get("cues", [])})
            elif s == "tekst":
                w.teksten.setdefault(d["taal"], {}).update({k: doc for k in d["teksten"]})
        return w
