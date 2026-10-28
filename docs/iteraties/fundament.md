# Iteratie: fundament (Fase 0)

Branch: `iteratie/fundament` · Milestone: Fase 0 · Fundament · Gestart: 2026-10-28

## Doel

De basis waarop elk hoofdstuk wordt gebouwd: content als data met schema's, de kernsystemen gespecificeerd en gebouwd, en automatische controle (validator, oplosser, GUT). Poort uit de roadmap: *systemen getest, oplosser draait*.

Speelbaar is aan het eind nog niets voor een speler; er is een draaiend Godot-project met getestde systemen en een testhoofdstuk als fixture.

## Technische keuzes (vastgelegd)

| Keuze | Waarde |
| --- | --- |
| Engine | Godot 4.7.2 stable, GDScript met statische types |
| 3D/art-bron | Blender 5.2.3 LTS |
| Repo | github.com/Tackinardie/Dreamweb-Rotterdam |
| Ontwikkelmachine | Windows 11; `godot`, `python`, `blender` op PATH |
| Tests | GUT voor systemen; Python-tools draaien met `python` (3.12) |

## Taken per agent

| # | Agent | Taak | Oplevering |
| --- | --- | --- | --- |
| #2 | systems-designer | Specificaties kernsystemen | `docs/systemen/`: objecten-en-inventaris, toegang, state-en-flags (incl. feit-tokens, puzzelgraaf, opslaan), klok-en-scenetijd, audio-cues-en-geluidsvenster |
| #1 | systems-designer | JSON-schema's | `tools/schemas/`: item, room, puzzle, dialogue, device, chapter (+ audio-cue) |
| #3 | godot-engineer | Godot-project | `game/project.godot`, autoloads `GameState` en `Content`, kernsystemen volgens de specs, GUT met tests, testhoofdstuk als fixture in `tests/fixtures/` |
| #4 | godot-engineer | Validator en oplosser | `tools/validate.py --all`, `tools/solve.py <hoofdstuk>` |
| #5 | art-director | Stijlgids v0 | Geblokkeerd tot de visuele referenties (#9) er zijn |
| #14 | qa-tester | QA fundament | `docs/qa/fundament.md` |
| #15 | code-reviewer | Code-review fundament | `docs/review/fundament-code.md` |

Niet in deze iteratie (geen content, geen nieuwe verhaalkeuzes): verhaalarchitect, locatie-onderzoeker, level-designer, puzzle-designer, schrijver, asset-pipeline, geluidsontwerper, lore-keeper, playtest-criticus. Telefoon-UI, droom, voetsporen, ramen, apparaten, kleding en metro volgen in Fase 1 of later; de schema's laten er ruimte voor.

## Definition of done

- [x] Elke spec in `docs/systemen/` heeft doel, pillar, regels, toestanden, edge cases, UX-flow, schema-verwijzing en acceptatiecriteria
- [x] Schema's voor alle zes contenttypes; de fixture valideert, kapotte voorbeelden falen
- [x] `python tools/validate.py --all` groen
- [x] `python tools/solve.py` bewijst oplosbaarheid van de fixture en vindt een opzettelijke doodlopende staat
- [x] Godot-project opent en draait headless zonder fouten; GUT-tests groen
- [x] Geen hardcoded content in scenes of scripts
- [x] QA-rapport eindigt op `KLAAR VOOR REVIEW`; code-review zonder blokkerende punten
- [ ] Martijn heeft het project geopend en de tests zien draaien

## Verloop

- Specs (#2) en schema's (#1) door de systems-designer; standaardcues (#16) door de geluidsontwerper; project, GUT, validator en oplosser (#3, #4) door de godot-engineer.
- QA ronde 1 `KLAAR VOOR REVIEW`, code-review ronde 1 met drie blokkerende punten (#18–#20) en moet-punten (#21–#23).
- Reviewronde 1 en 2 (#24) opgelost; QA ronde 2 `KLAAR VOOR REVIEW`, hercontrole zonder blokkerende punten.
- Eindstand: `python tools/test_godot.py` 81/81, pytest 93 groen, validator groen, oplosser op de fixture groen (8 stappen).
- Doorgeschoven naar Fase 1: technische schuld #25. Open keuze voor Martijn: #17 (startjaar).
