#!/usr/bin/env python3
"""Valideert content/ en audio/cues.json tegen de schema's en de kruisverwijzingsregels V01-V31.

Gebruik:
  python tools/validate.py --all
  python tools/validate.py --all --content tests/fixtures/proef --cues tests/fixtures/proef/cues.json
  python tools/validate.py --content tests/fixtures/proef --overlay tests/fixtures/kapot/schemafout --cues ...

Exitcode 0 = groen (waarschuwingen mogen), 1 = er zijn fouten.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from onderstad.inhoud import REPO  # noqa: E402
from onderstad.valideer import valideer  # noqa: E402


def main(argv: list[str] | None = None) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--all", action="store_true", help="valideer alles (content, cue-catalogus, cue-aanroepen in game/)")
    ap.add_argument("--content", type=Path, default=None, help="contentmap (standaard: content/)")
    ap.add_argument("--overlay", type=Path, action="append", default=[], help="map die bestanden uit --content overschrijft (voor kapotte varianten)")
    ap.add_argument("--cues", type=Path, default=None, help="cue-catalogus (standaard: audio/cues.json)")
    ap.add_argument("--game", type=Path, default=None, help="Godot-map om cue-aanroepen in .gd te controleren (standaard game/, alleen bij standaard content)")
    ap.add_argument("--stil", action="store_true", help="toon alleen fouten")
    args = ap.parse_args(argv)

    eigen = args.content is None
    content = args.content or REPO / "content"
    cues = args.cues or (REPO / "audio" / "cues.json" if eigen else None)
    game = args.game or (REPO / "game" if eigen else None)
    inh = valideer([content, *args.overlay], cues, game)

    fouten = [m for m in inh.meldingen if m.niveau == "fout"]
    waarschuwingen = [m for m in inh.meldingen if m.niveau == "waarschuwing"]
    for m in inh.meldingen:
        if m.niveau == "fout" or not args.stil:
            print(m)
    print(f"{len(fouten)} fout(en), {len(waarschuwingen)} waarschuwing(en) in {len(inh.docs)} bestand(en): {'GROEN' if not fouten else 'ROOD'}")
    return 1 if fouten else 0


if __name__ == "__main__":
    sys.exit(main())
