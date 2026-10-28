# Onderstad

Donkere top-down point-and-click adventure in hedendaags Rotterdam, geïnspireerd door DreamWeb (1994). Godot 4, GDScript. Alle teksten in het Nederlands.

**Pitch.** Rotterdam is de stad zonder hart. Zeven mensen bouwen er nu één: Het Hart, een stadsproject waar alle data van de stad naartoe vloeit en dat hun absolute macht geeft. Richard (22, student data/informatica, flitsbezorger) ziet in zijn dromen wat er gebeurt als het gaat kloppen en wil de zeven stoppen voordat het live gaat. Of is dat alleen waar in zijn hoofd? De game begint net na middernacht in de nieuwjaarsnacht en speelt zich af over zeven nachten.

## Bron van waarheid
`docs/GDD.md` is leidend voor elke ontwerpbeslissing. Lees het voordat je iets maakt. Wijkt een beslissing af, pas dan eerst het GDD aan en daarna de content.

## Design pillars
1. **Sfeer is het product.** Regen, neon, nat asfalt, stilte.
2. **Een fysieke wereld.** Objecten bestaan echt; puzzels volgen alledaagse logica.
3. **Informatie is de sleutel.** Telefoons, panelen, mails en roosters geven toegang.
4. **Twijfel tot het einde.** Elk moment laat twee lezingen toe: uitverkoren of waan.

**Anti-pillars:** geen gevechtssysteem, geen skilltrees, geen open wereld, geen humor als toon, geen game-over, geen geldsysteem, geen overlevingsbehoeften.

## Harde regels
- Content staat in JSON onder `content/`, met een schema in `tools/schemas/`. Nooit hardcoded in scenes of scripts.
- Echte personen komen niet voor. Echte instellingen krijgen een fictieve naam (Maasstad Medisch Centrum, Rotterdam Airport Zestienhoven). Geen echte logo's of huisstijlen.
- Geweld buiten beeld en zonder na te volgen werkwijze. De zeven confrontaties zijn elk anders (zie GDD).
- Realisme: wat er gebeurt moet kunnen op die plek, die hoogte en dat tijdstip.
- Geluid: nog niet maken. Roep alleen audio-cues aan uit `audio/cues.json`; het geluidsvenster (F2) toont ze.

## Werkwijze
- Start een iteratie met `/iteratie <chNN of systeemnaam>`. De producer (deze hoofdsessie) verdeelt het werk over de subagents in `.claude/agents/`.
- Makers en controleurs zijn gescheiden: niemand keurt eigen werk.
- Eén branch per iteratie. Merge naar `main` pas als de definition of done in het GDD is afgevinkt en Martijn het hoofdstuk zelf heeft gespeeld.

## Tracker en statusbord
- GitHub-issues zijn de enige takenlijst. Labels: `type:taak|bug|wijziging`, `agent:<naam>`, `hoofdstuk:<chNN|systeem>`, `status:martijn|geblokkeerd`. Milestones zijn de fases uit de roadmap.
- Werk alleen aan iets waar een issue voor is; sluit het met `closes #<n>` in de commit.
- Elke push die `docs/GDD.md` wijzigt, opent automatisch een `type:wijziging`-issue. Pak dat op met `/iteratie impact #<n>`.
- Het statusbord (GitHub Pages, gebouwd door `tools/build_status.py`) leest issues, `docs/qa/`, `docs/review/` en de GDD-historie. Houd die formats aan: QA-rapporten eindigen op `KLAAR VOOR REVIEW` of `NIET KLAAR`; reviews geven per pillar een score als `x/5`.

## Mappen
- `.claude/agents/` subagents · `.claude/commands/` slash-commando's
- `docs/` GDD, lore-bijbel, waarheid.md, personages/, locaties/, systemen/, levels/, art-briefs/, qa/, review/, iteraties/
- `content/` alle spelcontent als data · `game/` Godot-project · `tools/` validators en scripts (Python) · `tests/` GUT-tests en playthroughs
- `art/blender/` Blender-bronnen · `audio/` cue-catalogus, licenties, veldopnames
