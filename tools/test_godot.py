#!/usr/bin/env python3
"""Draait de Godot-tests betrouwbaar: importeren, rooktest van het project, GUT. Faalt bij 0 tests of fouten.

Gebruik (vanaf de repo-root):  python tools/test_godot.py [--select test_objecten] [--toon-alles]

Waarom een wrapper: op een schone checkout (zonder .godot/) laadt Godot de autoloads niet als de importstap
is vergeten; GUT draait dan 0 tests maar eindigt toch met exitcode 0. Dit script behandelt dat als falen.
Omgeving: GODOT = pad naar de godot-console-executable (standaard `godot` op het PATH).
"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ANSI = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
FOUTPATRONEN = (
    "SCRIPT ERROR", "Parse Error", "Could not find base class", "Failed to instantiate an autoload",
    "Failed loading resource", "[GUT ERROR]", "Unexpected Errors",
)


def draai(args: list[str]) -> tuple[int, str]:
    godot = shutil.which(os.environ.get("GODOT", "godot"))
    if godot is None:
        sys.exit("FOUT: godot niet gevonden op het PATH (zet GODOT=pad naar de console-executable)")
    r = subprocess.run([godot, *args], capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=REPO)
    return r.returncode, ANSI.sub("", r.stdout + r.stderr)


def fouten_in(uitvoer: str) -> list[str]:
    return [regel.strip() for regel in uitvoer.splitlines() if any(p in regel for p in FOUTPATRONEN)
            or regel.startswith("ERROR:")]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--select", help="alleen dit testbestand (zonder .gd), bijv. test_objecten")
    ap.add_argument("--toon-alles", action="store_true", help="druk de volledige GUT-uitvoer af")
    args = ap.parse_args()
    problemen: list[str] = []

    code, uit = draai(["--headless", "--path", "game", "--import"])
    if code != 0 or fouten_in(uit):
        problemen += ["import: " + f for f in fouten_in(uit)] or [f"import: exitcode {code}"]
    print("1/3 import klaar")

    code, uit = draai(["--headless", "--path", "game", "--quit-after", "5"])
    if code != 0 or fouten_in(uit):
        problemen += ["rooktest: " + f for f in fouten_in(uit)] or [f"rooktest: exitcode {code}"]
    print("2/3 rooktest (hoofdscene start headless) klaar")

    gut = ["--headless", "--path", "game", "-s", "addons/gut/gut_cmdln.gd", "-gdir=../tests/gut", "-gexit"]
    if args.select:
        gut.append(f"-gselect={args.select}")
    code, uit = draai(gut)
    totaal = re.search(r"^Tests\s+(\d+)", uit, re.M)
    geslaagd = re.search(r"^Passing Tests\s+(\d+)", uit, re.M)
    n = int(totaal.group(1)) if totaal else 0
    ok = int(geslaagd.group(1)) if geslaagd else 0
    if args.toon_alles:
        print(uit)
    if n == 0:
        problemen.append("GUT draaide 0 tests (importeren mislukt, autoloads niet geladen of verkeerd pad)")
    if ok != n:
        problemen.append(f"GUT: {n - ok} van {n} tests mislukt")
        problemen += [r.strip() for r in uit.splitlines() if "[Failed]" in r]
    if code != 0 and n > 0 and ok == n:
        problemen.append(f"GUT eindigde met exitcode {code}")
    problemen += ["gut: " + f for f in fouten_in(uit) if f not in " ".join(problemen)]
    print(f"3/3 GUT: {ok}/{n} tests geslaagd")

    if problemen:
        print("\nFOUT: de Godot-tests zijn niet groen:")
        for p in dict.fromkeys(problemen):
            print("  - " + p)
        return 1
    print("GROEN: import, rooktest en GUT zijn in orde.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
