#!/usr/bin/env python3
"""Bouwt het statusbord van Onderstad (docs/status/index.html).

Bronnen, allemaal uit de repo of GitHub zelf, zodat het bord meeloopt met de realisatie:
- GitHub-issues en milestones (fases), via de API met GITHUB_TOKEN
- QA-rapporten in docs/qa/chNN.md (laatste regel: KLAAR VOOR REVIEW / NIET KLAAR)
- Playtest-reviews in docs/review/chNN.md (pillar-scores "x/5" of "score: x")
- Git-historie van docs/GDD.md (ontwerpwijzigingen)

Lokaal testen zonder GitHub:  python tools/build_status.py --issues-file voorbeeld.json
"""
from __future__ import annotations

import argparse
import datetime as dt
import html
import json
import os
import re
import subprocess
import urllib.request
from pathlib import Path
from zoneinfo import ZoneInfo

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "status" / "index.html"

HOOFDSTUKKEN = [
    ("ch00", "Hub", "Witte de Withstraat"),
    ("ch01", "Katendrecht", "Projectontwikkelaar"),
    ("ch02", "Woontoren", "Data-ondernemer"),
    ("ch03", "Markthal / Centraal", "Influencer"),
    ("ch04", "Maasvlakte", "Havenbaron"),
    ("ch05", "Erasmus MC", "Slaaponderzoeker"),
    ("ch06", "Delfshaven", "Persoonlijk doelwit"),
    ("ch07", "Vliegveld", "Bestuurder"),
]
DAGEN = ["ma", "di", "wo", "do", "vr", "za", "zo"]
MAANDEN = ["jan", "feb", "mrt", "apr", "mei", "jun", "jul", "aug", "sep", "okt", "nov", "dec"]


# ---------- bronnen ----------

def gh_get(path: str, token: str, repo: str) -> list:
    out, page = [], 1
    while True:
        url = f"https://api.github.com/repos/{repo}/{path}{'&' if '?' in path else '?'}per_page=100&page={page}"
        req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"})
        with urllib.request.urlopen(req, timeout=30) as r:
            batch = json.load(r)
        out.extend(batch)
        if len(batch) < 100:
            return out
        page += 1


def laad_issues(args) -> tuple[list, list]:
    if args.issues_file:
        data = json.loads(Path(args.issues_file).read_text(encoding="utf-8"))
        return data.get("issues", []), data.get("milestones", [])
    token, repo = os.environ.get("GITHUB_TOKEN"), os.environ.get("GITHUB_REPOSITORY")
    if not token or not repo:
        return [], []
    issues = [i for i in gh_get("issues?state=all", token, repo) if "pull_request" not in i]
    milestones = gh_get("milestones?state=all", token, repo)
    return issues, milestones


def labels(issue) -> set[str]:
    return {l["name"] if isinstance(l, dict) else l for l in issue.get("labels", [])}


def lees_qa(ch: str) -> str | None:
    f = ROOT / "docs" / "qa" / f"{ch}.md"
    if not f.exists():
        return None
    regels = [r.strip() for r in f.read_text(encoding="utf-8").splitlines() if r.strip()]
    if not regels:
        return None
    laatste = regels[-1].upper()
    if "NIET KLAAR" in laatste:
        return "rood"
    if "KLAAR VOOR REVIEW" in laatste:
        return "groen"
    return None


def lees_review(ch: str) -> float | None:
    f = ROOT / "docs" / "review" / f"{ch}.md"
    if not f.exists():
        return None
    scores = [int(m) for m in re.findall(r"\b([1-5])\s*/\s*5\b", f.read_text(encoding="utf-8"))]
    return min(scores) if scores else None


def gdd_historie(n: int = 6) -> list[tuple[str, str]]:
    try:
        uit = subprocess.run(
            ["git", "log", f"-{n}", "--date=short", "--format=%ad\t%s", "--", "docs/GDD.md"],
            cwd=ROOT, capture_output=True, text=True, check=True,
        ).stdout
    except Exception:
        return []
    return [tuple(r.split("\t", 1)) for r in uit.splitlines() if "\t" in r]


# ---------- opbouw ----------

def e(s) -> str:
    return html.escape(str(s))


def pct(klaar: int, totaal: int) -> int:
    return round(100 * klaar / totaal) if totaal else 0


def balk(p: int, toon: str = "") -> str:
    return f'<div class="balk {toon}"><span style="width:{p}%"></span></div>'


def issue_link(i) -> str:
    url = i.get("html_url", "#")
    return f'<a href="{e(url)}">#{e(i.get("number", "?"))} {e(i.get("title", ""))}</a>'


def bouw(issues: list, milestones: list) -> str:
    nu = dt.datetime.now(ZoneInfo("Europe/Amsterdam"))
    klok = f"{DAGEN[nu.weekday()]} {nu.day} {MAANDEN[nu.month - 1]} · {nu:%H:%M}"

    totaal = len(issues)
    gesloten = sum(1 for i in issues if i.get("state") == "closed")
    open_ = [i for i in issues if i.get("state") == "open"]

    # Fases
    fase_html = []
    for m in sorted(milestones, key=lambda m: m.get("title", "")):
        o, c = m.get("open_issues", 0), m.get("closed_issues", 0)
        p = pct(c, o + c)
        status = "klaar" if o == 0 and c > 0 else ("bezig" if c > 0 else "")
        fase_html.append(
            f'<li class="{status}"><div class="rij"><b>{e(m["title"])}</b><span>{c}/{o + c}</span></div>{balk(p)}'
            f'<p>{e(m.get("description") or "")}</p></li>'
        )
    if not fase_html:
        fase_html.append('<li><p>Nog geen milestones. Draai tools/setup_github.sh.</p></li>')

    # Hoofdstukken
    hs_html = []
    for code, naam, doelwit in HOOFDSTUKKEN:
        eigen = [i for i in issues if f"hoofdstuk:{code}" in labels(i)]
        c = sum(1 for i in eigen if i.get("state") == "closed")
        p = pct(c, len(eigen))
        qa = lees_qa(code)
        rev = lees_review(code)
        bugs = sum(1 for i in eigen if i.get("state") == "open" and "type:bug" in labels(i))
        qa_chip = {"groen": '<i class="chip ok">QA groen</i>', "rood": '<i class="chip rood">QA rood</i>'}.get(qa, '<i class="chip">QA —</i>')
        rev_chip = f'<i class="chip {"ok" if rev and rev >= 3 else "rood" if rev else ""}">pillars {rev}/5</i>' if rev else '<i class="chip">review —</i>'
        bug_chip = f'<i class="chip rood">{bugs} bug{"s" if bugs != 1 else ""}</i>' if bugs else ""
        leeg = " leeg" if not eigen else ""
        hs_html.append(
            f'<li class="hs{leeg}"><div class="rij"><span class="code">{code}</span><b>{e(naam)}</b>'
            f'<span class="dim">{e(doelwit)}</span><span class="tal">{c}/{len(eigen)}</span></div>'
            f'{balk(p, "groen" if qa == "groen" else "")}<div class="chips">{qa_chip}{rev_chip}{bug_chip}</div></li>'
        )

    def lijst(filter_fn, leeg_tekst):
        sel = [i for i in open_ if filter_fn(i)]
        if not sel:
            return f'<p class="dim">{leeg_tekst}</p>'
        return "<ul class=\"issues\">" + "".join(f"<li>{issue_link(i)}</li>" for i in sel[:12]) + "</ul>"

    martijn = lijst(lambda i: "status:martijn" in labels(i) or "agent:martijn" in labels(i), "Niets. Alles ligt bij de agents.")
    blok = lijst(lambda i: "status:geblokkeerd" in labels(i), "Niets geblokkeerd.")
    bugs = lijst(lambda i: "type:bug" in labels(i), "Geen open bugs.")
    wijz = lijst(lambda i: "type:wijziging" in labels(i), "Geen open ontwerpwijzigingen.")

    # Agents
    teller: dict[str, int] = {}
    for i in open_:
        for l in labels(i):
            if l.startswith("agent:"):
                teller[l[6:]] = teller.get(l[6:], 0) + 1
    maxa = max(teller.values(), default=1)
    agents = "".join(
        f'<li><span>{e(a)}</span><div class="balk smal"><span style="width:{pct(n, maxa)}%"></span></div><b>{n}</b></li>'
        for a, n in sorted(teller.items(), key=lambda x: -x[1])
    ) or '<li class="dim">Geen open werk.</li>'

    hist = "".join(f"<li><span class=\"dim\">{e(d)}</span> {e(s)}</li>" for d, s in gdd_historie()) or '<li class="dim">Nog geen wijzigingen in het GDD vastgelegd.</li>'

    p_tot = pct(gesloten, totaal)
    return SJABLOON.format(
        klok=klok, p_tot=p_tot, gesloten=gesloten, totaal=totaal, open=len(open_),
        fases="".join(fase_html), hoofdstukken="".join(hs_html), martijn=martijn, blok=blok,
        bugs=bugs, wijz=wijz, agents=agents, hist=hist,
        bijgewerkt=nu.strftime("%d-%m-%Y %H:%M"),
    )


SJABLOON = """<!doctype html>
<html lang="nl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Onderstad · status</title>
<style>
:root{{--bg:#0d1014;--paneel:#151a21;--lijn:#252c36;--tekst:#e6e9ee;--dim:#8792a2;--natrium:#f0a24a;--neon:#36d3e0;--rood:#e5534b;--groen:#57c084}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--tekst);font:15px/1.5 system-ui,-apple-system,"Segoe UI",sans-serif}}
main{{max-width:1100px;margin:0 auto;padding:24px 16px 48px}}
header{{display:flex;justify-content:space-between;align-items:flex-end;gap:16px;flex-wrap:wrap;border-bottom:1px solid var(--lijn);padding-bottom:16px;margin-bottom:24px}}
h1{{margin:0;font-size:28px;letter-spacing:.5px}}h1 small{{display:block;font-size:13px;color:var(--dim);font-weight:400}}
.klok{{font-family:ui-monospace,Menlo,monospace;color:var(--natrium);font-size:18px;border:1px solid var(--lijn);padding:4px 10px;border-radius:6px}}
.groot{{display:flex;align-items:center;gap:16px;margin-bottom:24px}}.groot .getal{{font-size:44px;font-weight:700;color:var(--neon)}}
.groot .balk{{flex:1;height:10px}}
.raster{{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:16px;align-items:start}}
section{{background:var(--paneel);border:1px solid var(--lijn);border-radius:10px;padding:16px}}
h2{{margin:0 0 12px;font-size:14px;text-transform:uppercase;letter-spacing:1px;color:var(--dim)}}
ul{{list-style:none;margin:0;padding:0}}li{{margin-bottom:12px}}li p{{margin:4px 0 0;color:var(--dim);font-size:13px}}
.rij{{display:flex;gap:8px;align-items:baseline}}.rij b{{flex:1}}.dim{{color:var(--dim)}}.tal{{color:var(--dim);font-variant-numeric:tabular-nums}}
.code{{font-family:ui-monospace,Menlo,monospace;color:var(--natrium);font-size:12px}}
.balk{{height:6px;background:var(--lijn);border-radius:4px;overflow:hidden;margin-top:6px}}.balk span{{display:block;height:100%;background:var(--neon)}}
.balk.groen span{{background:var(--groen)}}.balk.smal{{flex:1;margin:0 8px;height:5px}}
li.klaar b{{color:var(--groen)}}li.hs.leeg{{opacity:.55}}
.chips{{margin-top:6px;display:flex;gap:6px;flex-wrap:wrap}}.chip{{font-style:normal;font-size:11px;border:1px solid var(--lijn);border-radius:20px;padding:1px 8px;color:var(--dim)}}
.chip.ok{{color:var(--groen);border-color:var(--groen)}}.chip.rood{{color:var(--rood);border-color:var(--rood)}}
.issues li{{margin-bottom:6px}}a{{color:var(--tekst);text-decoration:none}}a:hover{{color:var(--neon)}}
.agents li{{display:flex;align-items:center;margin-bottom:6px;font-size:13px}}.agents li span:first-child{{width:150px}}
section.let{{border-color:var(--natrium)}}footer{{margin-top:24px;color:var(--dim);font-size:12px}}
</style></head><body><main>
<header><h1>Onderstad<small>projectstatus</small></h1><div class="klok">{klok}</div></header>
<div class="groot"><div class="getal">{p_tot}%</div><div style="flex:1"><div class="dim">{gesloten} van {totaal} issues afgerond · {open} open</div><div class="balk">
<span style="width:{p_tot}%"></span></div></div></div>
<div class="raster">
<section class="let"><h2>Wacht op jou</h2>{martijn}</section>
<section><h2>Fases</h2><ul>{fases}</ul></section>
<section><h2>Hoofdstukken</h2><ul>{hoofdstukken}</ul></section>
<section><h2>Open bugs</h2>{bugs}<h2 style="margin-top:16px">Geblokkeerd</h2>{blok}</section>
<section><h2>Ontwerpwijzigingen</h2>{wijz}<h2 style="margin-top:16px">Laatste wijzigingen in het GDD</h2><ul>{hist}</ul></section>
<section><h2>Open werk per agent</h2><ul class="agents">{agents}</ul></section>
</div>
<footer>Automatisch bijgewerkt {bijgewerkt} uit GitHub-issues, QA-rapporten, reviews en de historie van het GDD.</footer>
</main></body></html>
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--issues-file", help="JSON met {issues, milestones} voor lokaal testen")
    args = ap.parse_args()
    issues, milestones = laad_issues(args)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(bouw(issues, milestones), encoding="utf-8")
    print(f"Statusbord geschreven: {OUT.relative_to(ROOT)} ({len(issues)} issues)")


if __name__ == "__main__":
    main()
