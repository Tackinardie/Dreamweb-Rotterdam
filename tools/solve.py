#!/usr/bin/env python3
"""Oplosser: bewijst dat een hoofdstuk oplosbaar is en zoekt doodlopende staten.

Gebruik:
  python tools/solve.py ch01_katendrecht
  python tools/solve.py ch01_proef --content tests/fixtures/proef
  python tools/solve.py ch01_proef --content tests/fixtures/proef --overlay tests/fixtures/kapot/doodlopend

Exitcode 0 = oplosbaar en geen doodlopende staten; 1 = onoplosbaar of doodlopend; 2 = content niet te laden.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from onderstad.inhoud import REPO, laad_inhoud, valideer_schemas  # noqa: E402
from onderstad.oplosser import los_op  # noqa: E402
from onderstad.wereld import Wereld  # noqa: E402


def main(argv: list[str] | None = None) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("hoofdstuk", help="hoofdstuk-id (of een uniek voorvoegsel, bijv. ch01)")
    ap.add_argument("--content", type=Path, default=REPO / "content")
    ap.add_argument("--overlay", type=Path, action="append", default=[])
    ap.add_argument("--max-staten", type=int, default=1_000_000, help="afkappen na zoveel toestanden")
    ap.add_argument("--leg-limiet", type=int, default=1,
                    help="hoeveel onmisbare objecten tegelijk neergelegd (buiten hun beginplek) mogen liggen; hoger = grondiger maar exponentieel trager")
    ap.add_argument("--json", action="store_true", help="machineleesbare uitvoer (inclusief het veld beperkingen)")
    args = ap.parse_args(argv)

    inh = laad_inhoud([args.content, *args.overlay], None)
    valideer_schemas(inh)
    fouten = [m for m in inh.meldingen if m.niveau == "fout"]
    if fouten:
        for m in fouten:
            print(m)
        print("De content valideert niet tegen de schema's; draai eerst tools/validate.py.")
        return 2
    w = Wereld.bouw(inh, inh.docs)
    kandidaten = [h for h in w.hoofdstukken if h == args.hoofdstuk or h.startswith(args.hoofdstuk)]
    if len(kandidaten) != 1:
        print(f"Hoofdstuk '{args.hoofdstuk}' niet (eenduidig) gevonden; beschikbaar: {', '.join(sorted(w.hoofdstukken)) or 'geen'}")
        return 2
    r = los_op(w, kandidaten[0], inh.docs, args.max_staten, args.leg_limiet)
    r.leg_limiet = args.leg_limiet
    uitslag = "onvolledig" if r.afgekapt else ("groen" if (r.oplosbaar and r.aantal_doodlopend == 0 and not r.problemen) else "rood")
    beperkingen = {
        "leg_limiet": args.leg_limiet,
        "niet_gemodelleerd": ["stop_in", "uitpakken", "inventariscapaciteit"],
        "aanname": "binnen een actieve gebeurtenis lukt elke actie die hem vereist",
        "verkende_toestanden": r.staten,
        "max_staten": args.max_staten,
        "max_staten_bereikt": r.afgekapt,
    }
    if args.json:
        print(json.dumps({
            "hoofdstuk": r.hoofdstuk, "uitslag": uitslag, "oplosbaar": r.oplosbaar, "route": r.route,
            "doodlopend": [{"pad": d.pad, "oorzaak": d.oorzaak} for d in r.doodlopend],
            "aantal_doodlopend": r.aantal_doodlopend, "nooit_vurend": r.nooit_vurend,
            "tokens_nooit_gegeven": r.tokens_nooit_gegeven, "tokens_nooit_gebruikt": r.tokens_nooit_gebruikt,
            "max_open_hoofd": r.max_open_hoofd, "problemen": list(dict.fromkeys(r.problemen)), "beperkingen": beperkingen,
        }, ensure_ascii=False, indent=2))
        return 0 if uitslag == "groen" else 1

    print(f"Hoofdstuk {r.hoofdstuk}: uitslag {uitslag.upper()}")
    print(f"Oplosbaar: {'ja' if r.oplosbaar else 'NEE'}")
    if r.oplosbaar:
        print(f"Kortste oplossing ({len(r.route)} stappen):")
        for i, stap in enumerate(r.route, 1):
            print(f"  {i:>2}. {stap}")
    print(f"Doodlopende staten (unieke ingangen): {r.aantal_doodlopend}")
    if r.onbevestigd or r.kandidaten_niet_gecontroleerd:
        print(f"  (kandidaten zonder uitsluitsel: {r.onbevestigd} niet bevestigd binnen de zoekgrens, {r.kandidaten_niet_gecontroleerd} niet gecontroleerd; probeer een hogere --leg-limiet)")
    for d in r.doodlopend[:5]:
        print(f"  Oorzaak: {d.oorzaak}")
        print(f"  Pad ({len(d.pad)} stappen): " + " > ".join(d.pad))
    if r.nooit_vurend:
        print("Knopen die nooit vuren: " + ", ".join(r.nooit_vurend))
    if r.tokens_nooit_gegeven:
        print("Tokens die nooit gegeven worden: " + ", ".join(r.tokens_nooit_gegeven))
    if r.tokens_nooit_gebruikt:
        print("Tokens die nooit gebruikt worden: " + ", ".join(r.tokens_nooit_gebruikt))
    print(f"Maximaal tegelijk open hoofd-knopen: {r.max_open_hoofd}" + (" (waarschuwing: meer dan 3)" if r.max_open_hoofd > 3 else ""))
    for p_ in dict.fromkeys(r.problemen):
        print(f"PROBLEEM: {p_}")
    print()
    print("Beperkingen van dit bewijs:")
    print(f"- leg-limiet: {args.leg_limiet} onmisbaar object tegelijk buiten zijn beginplek" if args.leg_limiet == 1
          else f"- leg-limiet: {args.leg_limiet} onmisbare objecten tegelijk buiten hun beginplek")
    print("- niet gemodelleerd: stop_in, uitpakken, inventariscapaciteit")
    print("- aanname: binnen een actieve gebeurtenis lukt elke actie die hem vereist")
    print(f"- verkende toestanden: {r.staten} (" + (f"limiet {args.max_staten} BEREIKT: 'geen doodlopende staat' is niet bewezen, uitslag onvolledig" if r.afgekapt else "limiet niet bereikt") + ")")
    return 0 if uitslag == "groen" else 1


if __name__ == "__main__":
    sys.exit(main())
