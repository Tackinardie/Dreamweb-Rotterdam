# QA fundament (Fase 0), ronde 2

Datum: 2026-10-28 · Branch: `iteratie/fundament` (commit dde92a7, na reviewronde 1) · Issue: #14 · Tester: qa-tester
Dit is ronde 2 (hercontrole). Alles hieronder is opnieuw zelf gedraaid op Windows 11, Git Bash, Godot 4.7.2, Python 3.12.

## Resultaat per check

| # | Check | Uitslag |
| --- | --- | --- |
| 1 | `python tools/validate.py --all` | GROEN |
| 2 | Validator op fixture en 40 kapotte varianten | GROEN |
| 3 | `solve.py` op fixture, varianten, beperkingenblok, `--max-staten` | GROEN |
| 4 | `python tools/test_godot.py` (import, rooktest, GUT) | GROEN (78/78) |
| 5 | pytest | GROEN (93 passed, 74 s) |
| 6 | Dekking SF-19..SF-27 en OI-14, steekproef | GROEN |
| 7 | Schone checkout met wrapper, niet vals groen | GROEN |
| - | `check_windows.py`, `check_audio.py`, `check_devices.py`, headless playthrough | n.v.t. (nog geen hoofdstuk; tools bestaan nog niet) |

### 1. validate --all
`0 fout(en), 0 waarschuwing(en) in 1 bestand(en): GROEN`, exit 0 (alleen de cue-catalogus; er is nog geen spelcontent).

### 2. Validator
- Fixture `tests/fixtures/proef`: 0 fouten in 14 bestanden, exit 0.
- Alle 40 mappen in `tests/fixtures/kapot/` met `--overlay`: 33 geven exit 1 met de passende regel, onder meer `scenewissel_geweigerd` (V17, plus V15 door de scènesprong; bewust een V17-overtreding), `scope_ander_hoofdstuk` (V04), `aanname_*`, `lokale_flag_buiten_hoofdstuk`, `twee_apparaten_zelfde_object`.
- Terecht exit 0 (waarschuwing of statisch correct): `geef_voor_scene` (V17-waarschuwing), `te_veel_onmisbaar` (V12), `token_ongebruikt` (V24), `dubbele_trigger` (V27), `niveau_zonder_regel`, en de twee `doodlopend_*` varianten (die vangt de oplosser).

### 3. Oplosser
- Fixture: `Oplosbaar: ja`, 8 stappen, 0 doodlopende staten, 112.080 toestanden, 17 s, exit 0. Het beperkingenblok staat in elke run (leg-limiet 1; niet gemodelleerd: stop_in, uitpakken, inventariscapaciteit; aanname gebeurtenisduur; verkende toestanden). Tijd is flink beter dan ronde 1.
- `doodlopend_pas_achtergelaten` en `doodlopend_rapport_weg`: elk 1 doodlopende staat, ROOD, exit 1. `onoplosbaar_code_ontbreekt`: `Oplosbaar: NEE`, exit 1. `scenewissel_geweigerd`: ROOD, 4 doodlopende staten, exit 1. `scope_hoofdstukken`: GROEN, exit 0.
- `--max-staten 500`: `uitslag ONVOLLEDIG`, tekst "limiet 500 BEREIKT: 'geen doodlopende staat' is niet bewezen", exit 1. `--leg-limiet 2 --json`: `beperkingen.leg_limiet = 2`, `max_staten_bereikt: true`, uitslag `onvolledig`.

### 4. Godot
`python tools/test_godot.py`: import klaar, rooktest klaar, `GUT: 78/78 tests geslaagd`, exit 0.

### 5. pytest
`python -m pytest tests/python -q`: `93 passed in 74.14s`, exit 0.

### 6. Dekking en steekproef
SF-19..SF-27 en OI-14 hebben elk een test: `tests/gut/test_besluiten.gd` (SF-20, SF-21, SF-22, SF-24..SF-27, OI-14 in drie triggers, M4, atomair opslaan) en `tests/python/test_scenario.py` (SF-19 parametrisch voor betreed/dialoog/gebruik, SF-20, SF-22, SF-23 vier tests). Steekproef, testcode gelezen:
- SF-21: een knoop `[naar_kamer, zet_flag]`; telt precies 1 `autosave_geschreven`; laadt de save in een nieuw spel, controleert flag en opgeloste knoop en dat de trigger niet opnieuw vuurt. Klopt met het criterium.
- SF-19 (oplosser): rapport ligt nog in het kantoor, trigger vuurt niet (knoop, flag, scène ongewijzigd), na ophalen vuurt hij wel. Klopt.
- SF-25: status `voorbij` na opslaan/laden en na niet-lineaire sprong, vergeleken met de bron. Klopt.
- SF-26/27: kapotte kamer/scène/types/ontbrekende sleutels; controleert terugval op startwaarde, waarschuwingen en `ok`. Klopt.
- SF-23: tests op tekst, JSON, `--max-staten` met exit niet 0, `--leg-limiet 2`; ik heb ze ook met de hand bevestigd (check 3).

### 7. Schone checkout (vals-groen-bevinding uit ronde 1 opgelost)
Verse `git clone` in de scratchpad (zonder `.godot/`):
- `python tools/test_godot.py`: importeert zelf, 78/78 groen, exit 0.
- Wrapper faalt (exit 1, met duidelijke reden) bij: 0 tests (`--select bestaatniet`: "GUT draaide 0 tests"), een syntaxfout in een autoload-script (SCRIPT ERROR-regels), en een opzettelijk falende test ("1 van 79 tests mislukt"). Na herstel weer groen, ook na het verwijderen van `.godot/`.
- Het kale GUT-commando zonder import gaf in mijn run wel "All tests passed" (exit 0); de wrapper is dus de enige aanbevolen route, zoals `tests/README.md` zegt.

## Bevindingen

| Id | Ernst | Verantwoordelijke | Bevinding |
| --- | --- | --- | --- |
| B1 (ronde 1) | opgelost | godot-engineer | Vals groen bij 0 tests: nu afgevangen door `tools/test_godot.py`, geverifieerd met negatieve tests. |
| B2 (ronde 1) | opgelost/kan | godot-engineer | Oplosser 17 s op de fixture; blijft exponentieel. Beperkingenblok en `onvolledig` maken dat eerlijk zichtbaar. Voor echte hoofdstukken partiële-orde-reductie overwegen. |
| N1 | kan | godot-engineer | `tests/README.md`: de rij `python/test_scenario.py` staat dubbel in de tabel en de zin over `scenewissel_geweigerd` staat dubbel (regel 81). Bovendien noemt de README "ongeveer 12 s" voor solve en "ongeveer 15 seconden" voor de wrapper (gemeten 17 s resp. 5 s). Cosmetisch. |
| N2 | kan | godot-engineer | Kale GUT-commando heeft nog steeds geen bescherming; het wordt alleen in de README afgeraden. |

Geen blokkerende bevindingen en geen rode checks, dus geen nieuwe issues aangemaakt. Code-review en Martijns eigen speeltest vallen buiten QA.

KLAAR VOOR REVIEW
