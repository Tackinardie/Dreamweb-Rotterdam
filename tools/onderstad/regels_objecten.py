"""Kruisverwijzingsregels V08-V19: objecten en containers, toegang en scenes."""
from __future__ import annotations

from collections import defaultdict

from .condities import tijdstip_minuten
from .inhoud import Doc
from .regels_basis import Ctx, alle_atomen_diep
from .wereld import hoofdstuk_nummer


def _grootte(item: dict) -> int:
    return int(item.get("grootte", 0)) if item.get("pakbaar") else 0


def _nr(doc: Doc) -> int:
    n = hoofdstuk_nummer(doc.hoofdstuk or "")
    return int(n) if n is not None else -1


def v08_beginplek(ctx: Ctx) -> None:
    w = ctx.w
    plaats = defaultdict(list)
    for r in ctx.refs:
        if r.soort == "item" and r.extra == "plaats":
            plaats[r.id].append(r)
    gegeven = {r.id for r in ctx.refs if r.soort == "item" and r.extra == "geef"}
    for item, lijst in plaats.items():
        kamers = [r for r in lijst if r.doc.soort == "room"]
        aannames = [r for r in lijst if r.doc.soort == "chapter"]
        if len(kamers) > 1:
            ctx.fout("V08", kamers[1].doc, kamers[1].pad, f"object '{item}' heeft meer dan één beginplek (ook {kamers[0].doc.bestand} {kamers[0].pad})")
        if len(aannames) > 1:
            ctx.fout("V08", aannames[1].doc, aannames[1].pad, f"object '{item}' staat in aanname_bij_start van meer dan één hoofdstuk")
        for a in aannames[:1]:
            for k in kamers[:1]:
                if _nr(a.doc) <= _nr(k.doc):
                    ctx.fout("V08", a.doc, a.pad, f"object '{item}' heeft twee beginplekken (kamer {k.doc.bestand} en aanname_bij_start)")
    for item, data in w.items.items():
        if item not in plaats and item not in gegeven:
            doc = next((d for d in ctx.docs if d.soort == "items"), None)
            if doc is not None:
                idx = next(i for i, x in enumerate(doc.data["items"]) if x["id"] == item)
                ctx.waarschuw("V08", doc, f"$.items[{idx}]", f"object '{item}' heeft geen beginplek en wordt nergens gegeven")


def _controleer_boom(ctx: Ctx, doc: Doc, pad: str, ouder: str | None, kinderen: list, voorouders: tuple, slots: int | None) -> None:
    items = ctx.w.items
    som = 0
    for i, k in enumerate(kinderen):
        p = f"{pad}[{i}]"
        it = items.get(k["object"])
        if it is None:
            continue  # V02
        if k["object"] in voorouders:
            ctx.fout("V09", doc, p, f"object '{k['object']}' zit (indirect) in zichzelf")
            continue
        som += _grootte(it)
        if ouder is not None:
            if not it.get("pakbaar"):
                ctx.fout("V09", doc, p, f"niet-pakbaar object '{k['object']}' kan niet in een container")
            cont = items[ouder].get("container")
            if cont is None:
                ctx.fout("V09", doc, p, f"'{ouder}' is geen container")
            elif _grootte(it) > cont["max_grootte"]:
                ctx.fout("V09", doc, p, f"'{k['object']}' (grootte {_grootte(it)}) is groter dan max_grootte {cont['max_grootte']} van '{ouder}'")
        elif slots is not None and not it.get("pakbaar"):
            ctx.fout("V09", doc, p, f"niet-pakbaar object '{k['object']}' kan niet in de inventaris")
        sub = k.get("inhoud", [])
        if sub:
            if not it.get("container"):
                ctx.fout("V09", doc, p + ".inhoud", f"'{k['object']}' is geen container maar heeft inhoud")
            else:
                _controleer_boom(ctx, doc, p + ".inhoud", k["object"], sub, voorouders + (k["object"],), None)
    if ouder is not None:
        cont = items.get(ouder, {}).get("container")
        if cont and som > cont["capaciteit"]:
            ctx.fout("V09", doc, pad, f"inhoud van '{ouder}' is {som} slots maar de capaciteit is {cont['capaciteit']}")
    if slots is not None and som > slots:
        ctx.fout("V09", doc, pad, f"de inventaris bij de start is {som} slots; het maximum is {slots}")


def v09_inhoud(ctx: Ctx) -> None:
    slots = int(ctx.w.spel.get("inventaris_slots", 8))
    for doc in ctx.docs:
        if doc.soort == "room":
            for i, o in enumerate(doc.data.get("objecten", [])):
                sub = o.get("inhoud", [])
                if sub and o["object"] in ctx.w.items:
                    if not ctx.w.items[o["object"]].get("container"):
                        ctx.fout("V09", doc, f"$.objecten[{i}].inhoud", f"'{o['object']}' is geen container maar heeft inhoud")
                    else:
                        _controleer_boom(ctx, doc, f"$.objecten[{i}].inhoud", o["object"], sub, (o["object"],), None)
        elif doc.soort == "chapter":
            inv = doc.data.get("aanname_bij_start", {}).get("inventaris", [])
            if inv:
                _controleer_boom(ctx, doc, "$.aanname_bij_start.inventaris", None, inv, (), slots)


def v10_acties(ctx: Ctx) -> None:
    for doc in ctx.docs:
        if doc.soort != "items":
            continue
        for i, it in enumerate(doc.data["items"]):
            acties = set(it["acties"])
            p = f"$.items[{i}].acties"
            vereist = {"pak": bool(it.get("pakbaar")), "open": "container" in it, "lees": "leestekst" in it}
            for actie, hoort in vereist.items():
                if (actie in acties) != hoort:
                    wat = {"pak": "pakbaar", "open": "container", "lees": "leestekst"}[actie]
                    ctx.fout("V10", doc, p, f"'{it['id']}': actie '{actie}' {'ontbreekt' if hoort else 'staat erin'} terwijl {wat} {'wel' if hoort else 'niet'} geldt")
            if it.get("standaard_actie") and it["standaard_actie"] not in acties:
                ctx.fout("V10", doc, f"$.items[{i}].standaard_actie", f"standaard_actie '{it['standaard_actie']}' staat niet in acties")


def v11_posities(ctx: Ctx) -> None:
    for doc in ctx.docs:
        if doc.soort != "room":
            continue
        d = doc.data
        b, h = d["afmeting"]["breedte"], d["afmeting"]["hoogte"]

        def check(pos: dict, pad: str, wat: str) -> None:
            if pos["x"] >= b or pos["y"] >= h:
                ctx.fout("V11", doc, pad, f"{wat} op ({pos['x']},{pos['y']}) ligt buiten de kamer van {b}x{h} tegels")

        if "start_positie" in d:
            check(d["start_positie"], "$.start_positie", "start_positie")
        for i, o in enumerate(d.get("objecten", [])):
            check(o["positie"], f"$.objecten[{i}].positie", f"object '{o['object']}'")
        for i, u in enumerate(d.get("uitgangen", [])):
            check(u["positie"], f"$.uitgangen[{i}].positie", f"uitgang '{u['id']}'")
        for i, n in enumerate(d.get("npcs", [])):
            check(n["positie"], f"$.npcs[{i}].positie", f"NPC '{n['id']}'")


def v12_draagbaar(ctx: Ctx) -> None:
    per: dict[str, set[str]] = defaultdict(set)
    for r in ctx.refs:
        if r.soort == "item" and r.extra == "onmisbaar" and r.doc.hoofdstuk and ctx.w.items.get(r.id, {}).get("pakbaar"):
            per[r.doc.hoofdstuk].add(r.id)
    for h, ids in per.items():
        totaal = sum(_grootte(ctx.w.items[i]) for i in ids)
        if totaal > 8:
            doc = next(d for d in ctx.docs if d.soort == "chapter" and d.hoofdstuk == h)
            ctx.waarschuw("V12", doc, "$", f"de onmisbare pakbare objecten ({', '.join(sorted(ids))}) zijn samen {totaal} slots; ze passen alleen met containers")


def _doorgangen(room: dict):
    """(pad, uitgang_dict, doel-dict) voor elke uitgang en elke liftbestemming."""
    for i, u in enumerate(room.get("uitgangen", [])):
        if "naar_kamer" in u:
            yield f"$.uitgangen[{i}]", u, u
        for j, b in enumerate(u.get("bestemmingen", [])):
            yield f"$.uitgangen[{i}].bestemmingen[{j}]", u, b


def v13_wederzijds(ctx: Ctx) -> None:
    kamers = ctx.w.kamers
    for doc in ctx.docs:
        if doc.soort != "room":
            continue
        mijn = doc.data["id"]
        for pad, u, doel in _doorgangen(doc.data):
            andere = kamers.get(doel["naar_kamer"])
            if andere is None:
                continue  # V02
            tegen = next((x for x in andere.get("uitgangen", []) if x["id"] == doel["naar_uitgang"]), None)
            if tegen is None:
                ctx.fout("V13", doc, pad, f"doeluitgang '{doel['naar_uitgang']}' bestaat niet in {doel['naar_kamer']}")
                continue
            wijst_terug = (tegen.get("naar_kamer") == mijn and tegen.get("naar_uitgang") == u["id"]) or any(
                b["naar_kamer"] == mijn and b["naar_uitgang"] == u["id"] for b in tegen.get("bestemmingen", []))
            if not wijst_terug:
                ctx.fout("V13", doc, pad, f"uitgang '{doel['naar_uitgang']}' in {doel['naar_kamer']} wijst niet terug naar '{u['id']}' in {mijn}")


def v14_scenes(ctx: Ctx) -> None:
    w = ctx.w
    in_scene = {k for sc in w.scenes.values() for k in sc["kamers"]}
    for doc in ctx.docs:
        if doc.soort == "room" and doc.data["id"] not in in_scene:
            ctx.fout("V14", doc, "$.id", f"kamer '{doc.data['id']}' zit in geen enkele scène")
        if doc.soort == "chapter":
            st = doc.data["start"]
            sc = w.scenes.get(st["scene"])
            if sc is not None and st["kamer"] not in sc["kamers"]:
                ctx.fout("V14", doc, "$.start.kamer", f"startkamer '{st['kamer']}' zit niet in startscène '{st['scene']}'")
            kamer = w.kamers.get(st["kamer"])
            if kamer is not None and "uitgang" in st and not any(u["id"] == st["uitgang"] for u in kamer.get("uitgangen", [])):
                ctx.fout("V14", doc, "$.start.uitgang", f"startuitgang '{st['uitgang']}' bestaat niet in {st['kamer']}")


def _tijd(sc: dict) -> int:
    return tijdstip_minuten(sc["tijd"])


def _terug_ok(bron: list[dict], doel: dict) -> bool:
    """Is er geen enkele bron waarvoor een sprong naar doel een fout terug in de tijd is?"""
    if doel.get("niet_lineair"):
        return True
    return all(b.get("niet_lineair") or _tijd(doel) >= _tijd(b) for b in bron)


def _bronscenes(ctx: Ctx, knoop: dict, hoofdstuk: str) -> tuple[list[dict], bool]:
    """Scenes waarin een knoop kan vuren; tweede waarde: expliciet (via een scene-atoom)?"""
    expliciet = [a[1]["scene"] for a in alle_atomen_diep(knoop.get("vereist"), ctx.w) if a[0] == "scene"]
    if expliciet:
        return [ctx.w.scenes[s] for s in expliciet if s in ctx.w.scenes], True
    alle = [sc for sc in ctx.w.scenes.values() if ctx.w.scene_hoofdstuk[sc["id"]] == hoofdstuk]
    if "betreed" in knoop["trigger"]:
        alle = [sc for sc in alle if knoop["trigger"]["betreed"] in sc["kamers"]]
    return alle, False


def v15_scenewissel(ctx: Ctx) -> None:
    w = ctx.w
    for doc in ctx.docs:
        if doc.soort == "room":
            mijn = doc.data["id"]
            bron = [sc for sc in w.scenes.values() if mijn in sc["kamers"]]
            for pad, u, doel in _doorgangen(doc.data):
                naar = doel.get("naar_scene", u.get("naar_scene") if doel is u else None)
                if not naar or naar not in w.scenes:
                    continue
                t = w.scenes[naar]
                if doel["naar_kamer"] not in t["kamers"]:
                    ctx.fout("V15", doc, pad, f"na de scènewissel naar '{naar}' zit doelkamer '{doel['naar_kamer']}' niet in die scène")
                if bron and not _terug_ok(bron, t):
                    ctx.fout("V15", doc, pad, f"scènewissel naar '{naar}' loopt terug in de tijd zonder niet_lineair")
        elif doc.soort == "puzzle":
            h = doc.hoofdstuk or ""
            for i, k in enumerate(doc.data["knopen"]):
                for j, e in enumerate(k.get("effecten", [])):
                    if "naar_scene" not in e or e["naar_scene"] not in w.scenes:
                        continue
                    t = w.scenes[e["naar_scene"]]
                    p = f"$.knopen[{i}].effecten[{j}]"
                    if "kamer" in e and e["kamer"] not in t["kamers"]:
                        ctx.fout("V15", doc, p, f"kamer '{e['kamer']}' zit niet in de nieuwe scène '{t['id']}'")
                    bron, expliciet = _bronscenes(ctx, k, h)
                    bron = [b for b in bron if b["id"] != t["id"]]
                    if bron and not _terug_ok(bron, t):
                        ctx.fout("V15", doc, p, f"scènewissel naar '{t['id']}' loopt terug in de tijd zonder niet_lineair")


def v16_niet_lineair(ctx: Ctx) -> None:
    gezien: dict[str, tuple] = {}
    for doc in ctx.docs:
        if doc.soort != "chapter":
            continue
        for i, sc in enumerate(doc.data["scenes"]):
            m = sc.get("niet_lineair")
            if m and m not in gezien:
                gezien[m] = (doc, f"$.scenes[{i}].niet_lineair")
                if len(gezien) > 2:
                    ctx.fout("V16", doc, f"$.scenes[{i}].niet_lineair", f"meer dan twee niet_lineair-momenten in de hele game ({', '.join(sorted(gezien))})")


def v17_automatisch(ctx: Ctx) -> None:
    """V17: een naar_scene in een knoop mag, bij elke triggersoort, geen kamers laten wegvallen (fout).
    Waarschuwing als een geef_object of verplaats_object vóór de naar_scene staat (valt buiten de O9-voorcontrole)."""
    w = ctx.w
    for doc in ctx.docs:
        if doc.soort != "puzzle":
            continue
        for i, k in enumerate(doc.data["knopen"]):
            gezien_verplaatsing = False
            for j, e in enumerate(k.get("effecten", [])):
                if "geef_object" in e or "verplaats_object" in e:
                    gezien_verplaatsing = True
                if "naar_scene" not in e or e["naar_scene"] not in w.scenes:
                    continue
                p = f"$.knopen[{i}].effecten[{j}]"
                if gezien_verplaatsing:
                    ctx.waarschuw("V17", doc, p, "een geef_object of verplaats_object staat vóór de naar_scene en valt buiten de O9-voorcontrole")
                doel = w.scenes[e["naar_scene"]]
                bron, _ = _bronscenes(ctx, k, doc.hoofdstuk or "")
                for b in bron:
                    if b["id"] == doel["id"]:
                        continue
                    weg = sorted(set(b["kamers"]) - set(doel["kamers"]))
                    if weg:
                        ctx.fout("V17", doc, p, f"scènewissel naar '{doel['id']}' laat kamers uit '{b['id']}' wegvallen: {', '.join(weg)}")


def v18_merkbaar(ctx: Ctx) -> None:
    w = ctx.w
    npc_afhankelijk: set[str] = set()
    for doc in ctx.docs:
        if doc.soort == "room":
            for n in doc.data.get("npcs", []):
                for soort, node, _ in alle_atomen_diep(n.get("aanwezig"), w):
                    if soort == "gebeurtenis":
                        npc_afhankelijk.add(node["gebeurtenis"])
    gemeld: set[str] = set()
    for r in ctx.refs:
        if r.soort != "gebeurtenis" or r.extra != "cond" or r.id in gemeld:
            continue
        ev = w.gebeurtenissen.get(r.id)
        if ev is None:
            continue
        if not (ev.get("cue_start") or ev.get("cue_einde") or r.id in npc_afhankelijk):
            gemeld.add(r.id)
            ctx.fout("V18", r.doc, r.pad, f"gebeurtenis '{r.id}' wordt in een conditie gebruikt maar is niet merkbaar (geen cue_start, cue_einde of NPC)")


def v19_niveau_zonder_regel(ctx: Ctx) -> None:
    w = ctx.w
    for doc in ctx.docs:
        if doc.soort != "room":
            continue
        for pad, u, doel in _doorgangen(doc.data):
            target = w.kamers.get(doel["naar_kamer"])
            if target is None or "niveau" not in target:
                continue
            vereist = doel.get("vereist") if doel is not u else u.get("vereist")
            soorten = {a[0] for a in alle_atomen_diep(vereist, w)}
            if not soorten & {"niveau", "token", "heeft"}:
                ctx.waarschuw("V19", doc, pad, f"uitgang naar '{doel['naar_kamer']}' (niveau {target['niveau']}) heeft geen niveau-, token- of heeft-regel in vereist")
