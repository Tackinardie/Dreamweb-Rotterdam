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

- [x] Schema en specs spreken van vakken van 1×1 m; vak→3D-positie (x/z, oorsprong, vloerhoogte) is vastgelegd en getest
- [x] `docs/systemen/kamerweergave.md` heeft doel, pillar, regels, edge cases, UX-flow en acceptatiecriteria
- [x] Een kamer uit content verschijnt als 3D-scène met vaste camera (smalle FOV), klik-om-te-lopen, highlight, spatiebalk, 3D-close-up en scènewissel zonder laadscherm
- [x] Volle en lichte kwaliteitsstand schakelbaar; logica headless testbaar
- [x] CI draait validator, pytest, oplosser en GUT op elke push en PR
- [ ] `content/spel.json` en `algemeen.json` valideren (verschoven naar `/iteratie ch01`, zie #30); `python tools/validate.py --all` groen
- [x] `python tools/test_godot.py` groen
- [x] QA eindigt op KLAAR VOOR REVIEW; code-review zonder blokkerende punten
- [x] Martijn heeft de testkamer gestart en gezien

## Starten

De testkamer is `ch01_kantoor` uit `tests/fixtures/proef` (8×6 vakken, bureau geblokkeerd, twee lichten, laptop met close-up). Zolang `content/` nog geen `spel.json` heeft, laadt de hoofdscene in een ontwikkelbuild die fixture en zet Richard bij `deur_hal` (de keuze staat in `tests/fixtures/testscene.json`).

```
godot --path game                          # de testkamer, kwaliteitsstand uit user://instellingen.cfg (eerste start: 3 s meten)
godot --path game -- --stand licht         # forceer vol of licht
godot --path game -- --kamer ch01_hal      # andere kamer uit de fixture
godot --path game -- --meet ch01_kantoor --stand licht   # prestatiemeting naar user://meting/<kamer>_<stand>.json
godot --path game -- --spatie --foto docs/qa/shots/x.png --frames 60   # schermfoto (QA)
```

Bediening: linksklik loopt (op een object: ernaartoe en de standaardactie; op een uitgang: erdoorheen), rechtsklik bekijkt (laptop: 3D-close-up, sluiten met rechtsklik, klik of Esc), spatiebalk ingedrukt houden toont alles wat interactief is, hover geeft contour, naam en vergrootglas. In ontwikkelbuilds: F2 geluidsvenster, F3 meetoverlay met vakkenraster, F4 wisselt vol/licht.

Tests: `python tools/test_godot.py` (logica in `tests/gut/test_vak_logica.gd`, weergave headless in `tests/gut/test_kamerweergave.gd`). Code: logica in `game/systems/` (`vak.gd`, `kamer_raster.gd`, `camera_stand.gd`, `kwaliteit.gd`, `loper.gd`, `interactie.gd`), weergave in `game/weergave/`.
