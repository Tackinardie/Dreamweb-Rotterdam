# Onderstad — startpakket

## Installeren
1. Pak deze map uit in een lege map en maak er een Git-repository van (`git init`), of zet hem in je nieuwe GitHub-repo.
2. **Zet het GDD erin:** open het Game Design Document in Claude, exporteer het als Markdown en sla het op als `docs/GDD.md` (overschrijf het plaatshouderbestand). Alle agents lezen dat bestand.
3. Open de map in Claude Code. `CLAUDE.md` wordt automatisch gelezen; de agents in `.claude/agents/` en het commando `/iteratie` zijn direct beschikbaar.

## Tracker en statusbord inrichten (eenmalig)
1. Zet de repo op GitHub en log in met `gh auth login` (met scope `project`: `gh auth refresh -s project`).
2. Draai `tools/setup_github.sh`. Dat maakt labels, de vijf fases als milestones, het projectbord "Onderstad" en de startissues.
3. In de repo: **Settings > Pages > Source: GitHub Actions**. Het statusbord staat daarna op `https://<gebruiker>.github.io/<repo>/`.
4. In het projectbord: **Workflows > Auto-add to project** aan, zodat nieuwe issues er vanzelf op komen.

Daarna loopt alles mee:
- Agents maken, labelen en sluiten issues tijdens `/iteratie`.
- Een gewijzigd GDD opent vanzelf een issue "Ontwerpwijziging"; `/iteratie impact #<n>` maakt er een impactanalyse en taken van.
- Het statusbord wordt herbouwd bij elke issuewijziging, elke push naar `main` en elk uur.

## Eerste iteratie: het fundament
```
/iteratie fundament
```
Doel van Fase 0: JSON-schema's en systeemspecificaties (systems-designer), het Godot-project met de kernsystemen (godot-engineer) en de validator en oplosser in `tools/` (godot-engineer, getest door de qa-tester).

## Wat erin zit
- `CLAUDE.md` — projectcontext voor elke sessie
- `.claude/agents/` — 14 subagents
- `.claude/commands/iteratie.md` — het iteratiecommando voor de producer
- `.github/` — issue-sjablonen (taak, bug, ontwerpwijziging) en workflows voor statusbord en GDD-wijzigingen
- `tools/setup_github.sh` en `tools/build_status.py` — tracker inrichten en statusbord bouwen
- `docs/` — startbestanden: backlog, lore-bijbel, waarheidsdocument, open verhaalvragen, personageblad van Richard
- `audio/cues.json` en `audio/licenties.md` — lege catalogus en licentielog
- lege mappen voor content, game, tools en tests
