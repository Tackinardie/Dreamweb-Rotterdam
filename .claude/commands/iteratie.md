---
description: Start of vervolg een iteratie van Onderstad voor een hoofdstuk, systeem of ontwerpwijziging
argument-hint: <chNN | systeemnaam | impact #issue>
---
Je bent de producer van Onderstad. Doel van deze iteratie: $ARGUMENTS.
1. Lees docs/GDD.md, het laatste QA- en reviewrapport, en de open issues: `gh issue list --state open --limit 200`.
   Is het doel `impact #n`: lees dat ontwerpwijzigings-issue en de diff, schrijf als reactie op het issue een impactanalyse (geraakte hoofdstukken, systemen, content, agents) en maak voor elk gevolg een taak-issue. Stop daarna en vat samen.
2. Schrijf in docs/iteraties/ een plan: doel, taken per agent, definition of done.
3. Zet het plan in de tracker: één issue per taak, met labels `type:*`, `agent:<eigenaar>`, `hoofdstuk:<chNN|systeem>` en de milestone van de fase. Bestaat een issue al, hergebruik het.
4. Voer uit in deze volgorde, elk via de juiste subagent: verhaalarchitect (samen met mij), locatie-onderzoeker, systems-designer (bij nieuwe of gewijzigde systemen), art-director (briefs), level-designer, puzzle-designer, schrijver, godot-engineer, asset-pipeline en geluidsontwerper (parallel waar onafhankelijk), qa-tester, lore-keeper, art-director (review), playtest-criticus, code-reviewer.
5. Houd de tracker bij terwijl je werkt:
   - Commit per afgeronde taak met `closes #<n>` in het bericht, zodat het issue sluit bij de merge.
   - Elke rode QA-check en elk blokkerend reviewpunt wordt een `type:bug`-issue met de verantwoordelijke agent als label.
   - Wacht iets op mij, zet dan `status:martijn` op het issue en zeg het in je samenvatting. Wacht iets op ander werk, zet `status:geblokkeerd`.
6. Rood bij QA of blokkerend bij review: terug naar de verantwoordelijke agent, maximaal 3 rondes, daarna stoppen en mij de beslissing voorleggen.
7. Sluit af met: wat speelbaar is, hoe ik het start, de top 5 open punten, en welke issues zijn gesloten, nieuw of wachten op mij.
Vraag mij alleen bij keuzes die het verhaal, de pillars of de scope raken.
