# Iteratie: fundament-3d (Fase 1, voorbereiding)

Branch: `iteratie/fundament-3d` · Milestone: Fase 1 · Vertical slice · Gestart: 2026-10-28

## Doel

Het fundament klaarmaken voor de 3D-stijl, zodat `/iteratie ch01` content kan bouwen die je ook ziet: vakken van 1×1 m, een kamerweergave in 3D, CI op GitHub en de eerste globale content. Daarnaast een aanzet voor het stemvoorbeeld.

Speelbaar aan het eind: een testkamer uit de fixture die je in Godot ziet en waarin je kunt lopen en klikken; nog geen echt hoofdstuk.

## Taken per agent

| # | Agent | Taak | Oplevering |
| --- | --- | --- | --- |
| #8 | schrijver | Aanzet stemvoorbeeld (drie varianten) | `docs/stem/aanzet.md`; Martijn kiest en herschrijft |
| #34 | systems-designer | Vak van 1×1 m in schema en specs | `tools/schemas/`, `docs/systemen/`; vak→3D-positie vastgelegd |
| #35 | systems-designer | Spec kamerweergave 3D | `docs/systemen/kamerweergave.md` |
| #34, #35 | godot-engineer | Bouw: vak→3D, kamerweergave, kwaliteitsstanden | `game/`, GUT-tests, headless testbaar |
| #37 | godot-engineer | CI | `.github/workflows/ci.yml` |
| #30 | level-designer + schrijver | Basiscontent | `content/spel.json`, `content/tekst/nl/algemeen.json` |
| — | qa-tester | QA | `docs/qa/fundament-3d.md` |
| — | code-reviewer | Code-review | `docs/review/fundament-3d-code.md` |

Niet in deze iteratie: verhaal, locaties, puzzels, art-assets (behalve placeholders in de testkamer), geluid.

## Definition of done

- [ ] Schema en specs spreken van vakken van 1×1 m; vak→3D-positie (x/z, oorsprong, vloerhoogte) is vastgelegd en getest
- [ ] `docs/systemen/kamerweergave.md` heeft doel, pillar, regels, edge cases, UX-flow en acceptatiecriteria
- [ ] Een kamer uit content verschijnt als 3D-scène met vaste camera (smalle FOV), klik-om-te-lopen, highlight, spatiebalk, 3D-close-up en scènewissel zonder laadscherm
- [ ] Volle en lichte kwaliteitsstand schakelbaar; logica headless testbaar
- [ ] CI draait validator, pytest, oplosser en GUT op elke push en PR
- [ ] `content/spel.json` en `algemeen.json` valideren; `python tools/validate.py --all` groen
- [ ] `python tools/test_godot.py` groen
- [ ] QA eindigt op KLAAR VOOR REVIEW; code-review zonder blokkerende punten
- [ ] Martijn heeft de testkamer gestart en gezien
