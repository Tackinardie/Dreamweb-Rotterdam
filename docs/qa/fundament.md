# QA fundament (Fase 0)

Datum: 2026-10-28 · Branch: `iteratie/fundament` (commit 7308480) · Issue: #14 · Tester: qa-tester
Alles hieronder is zelf gedraaid op Windows 11, Git Bash, Godot 4.7.2, Python 3.12.

## Resultaat per check

| # | Check | Uitslag |
| --- | --- | --- |
| 1 | `python tools/validate.py --all` | GROEN |
| 2 | Validator op fixture en 26 kapotte varianten | GROEN |
| 3 | `python tools/solve.py` op fixture en varianten | GROEN |
| 4 | Godot import, headless run, GUT | GROEN (met kanttekening, bevinding B1) |
| 5 | pytest | GROEN |
| 6 | Dekking acceptatiecriteria en steekproef | GROEN |
| 7 | Geen hardcoded content; cues bestaan | GROEN |
| 8 | Schone checkout | GROEN (met kanttekening, bevinding B1) |
| - | `check_windows.py`, `check_audio.py`, `check_devices.py`, headless playthrough | n.v.t. (nog geen hoofdstuk, tools bestaan nog niet) |

### 1. validate --all
`python tools/validate.py --all` gaf: `content: geen spelcontent gevonden; alleen de cue-catalogus is gecontroleerd` en `0 fout(en), 0 waarschuwing(en) in 1 bestand(en): GROEN`, exit 0. De 15 cues in `audio/cues.json` valideren.

### 2. Validator op fixture en kapotte varianten
- Fixture: `validate.py --content tests/fixtures/proef --cues tests/fixtures/proef/cues.json` gaf 0 fouten in 14 bestanden, exit 0.
- Alle 26 mappen in `tests/fixtures/kapot/` met `--overlay` gedraaid. 24 geven exit 1 met de passende regel, bijvoorbeeld V01 (`dubbel_id`), V06 (`tekst_ontbreekt`, `engine_tekst_ontbreekt`), V07 (`cue_onbekend`, `cue_verkeerde_soort`), V08 (`dubbele_beginplek`), V09 (`past_niet`), V10, V11, V13 (`geen_tegenstuk`), V14, V15 (`terug_in_de_tijd`), V16, V18, V21 (`twee_doelknopen`), V22 (`hints_ontbreken`), V23 (`token_nooit_gegeven`, `onoplosbaar_code_ontbreekt`), V25 (`conditiekring`), V26, V29, V30, en een schemafout.
- `doodlopend_pas_achtergelaten` en `doodlopend_rapport_weg` zijn bij de validator terecht groen (statisch correct); de oplosser vangt ze (check 3).
- Opmerking: `schemafout` en `hints_ontbreken` geven naast de hoofdfout enkele vervolgwaarschuwingen/-fouten (ongebruikte tekstsleutel). Dat is acceptabel.

### 3. Oplosser
- Fixture: `solve.py ch01_proef --content tests/fixtures/proef` gaf `Oplosbaar: ja`, kortste oplossing 8 stappen (kast open, jas, briefje, kantoor, kluisje, rapport, hal, geef aan portier), 108248 toestanden, 0 doodlopende staten, exit 0.
- `doodlopend_pas_achtergelaten`: oplosbaar, maar `Doodlopende staten: 1`, oorzaak "alle uitgangen van ch01_kantoor zijn dicht", pad van 2 stappen, exit 1.
- `doodlopend_rapport_weg`: `Doodlopende staten: 1`, oorzaak "onmisbaar object verdwenen: rapport", pad van 7 stappen, exit 1.
- `onoplosbaar_code_ontbreekt`: `Oplosbaar: NEE`, noemt de knopen die nooit vuren en de tokens die nooit gegeven worden, exit 1.

### 4. Godot
- `godot --headless --path game --import`: geen errors of warnings (klassen `ContentDb`, `Spel` enzovoort geregistreerd).
- `godot --headless --path game --quit-after 60`: draait, enige uitvoer `Onderstad: nog geen spelcontent in content/; lege wereld.`, exit 0.
- GUT: `godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=../tests/gut -gexit`: 7 scripts, 65 tests, 65 geslaagd, 1343 asserts, 0 waarschuwingen/orphans, exit 0.

### 5. pytest
`python -m pytest tests/python -q`: `69 passed in 53.19s`, exit 0.

### 6. Dekking
Alle criteria OI-01..13, TG-01..11, SF-01..18, KS-01..11, AC-01..10 komen in minstens een test voor. SF-02 t/m SF-05 zitten in de gedeelde `tests/fixtures/condities.json` (gelezen door GUT en Python), niet in een testnaam. Er zijn geen onge-dekte criteria.

Steekproef van 5, testcode gelezen:
- TG-03 (per kant eigen `vereist`): test controleert van buiten geweigerd, van binnen vrij. Klopt.
- TG-05 (liftpaneel): controleert bestemmingen zonder eigen kamer, gedimd per `vereist`, en dat een gedimde knop weigert. Klopt.
- KS-08 (pauze): 5 s spelen, 100 s gepauzeerd, status blijft actief; na hervatten eindigt hij tussen 4,9 en 5,1 s. Klopt exact met het criterium.
- OI-04 (heeft/ligt na neerleggen): pak jas, `heeft pasje` waar, jas neerleggen, `heeft` onwaar en `ligt in kamer` waar. Klopt.
- SF-12 (token een keer): tweede `geef_token` met andere bron verandert niets; signaalaantal 1; scènetijd en bron gecontroleerd. Klopt.
Extra gecontroleerd: AC-09 (kleuren per status) toetst echt de kleurcodes in `bouw_tekst()`.

### 7. Hardcoded content en cues
- Scan van `game/` (zonder `addons/`): geen gebruikersgerichte tekst in scripts; alle meldingen zijn tekstsleutels of ontwikkelaarsfouten. `main.tscn` is een lege Node met script. `test_project.gd` bewaakt dit ook.
- Cue-aanroepen in `game/` (`deur.*`, `lift.*`, `object.*`, `ui.*`) staan alle in `audio/cues.json`. `systeem.*` en `klok.*` zijn tekstsleutels, geen cues.

### 8. Schone checkout
Twee `git clone`s in de scratchpad (zonder `.godot/`):
- Met de stappen uit `tests/README.md` (eerst `--import`): GUT 65/65 groen, `validate --all` groen.
- Zonder `--import` faalt het project (zie B1).

## Bevindingen

| Id | Ernst | Verantwoordelijke | Bevinding |
| --- | --- | --- | --- |
| B1 | moet | godot-engineer | Op een schone checkout zonder voorafgaande `--import` laadt Godot de autoloads niet (`Could not find base class "Spel"`, `Failed to instantiate an autoload`) en draait GUT 0 tests, maar het commando eindigt met **exit 0**. Dat is een vals groen voor elke CI of ieder die de importstap vergeet. Oplossing: laat het GUT-commando falen als er 0 tests liepen, of voeg een wrapper-script toe (`tools/run_tests.*`) dat eerst importeert en het aantal tests controleert. |
| B2 | kan | godot-engineer | De oplosser is traag: de fixture onderzoekt 108k toestanden (ruim een minuut); `doodlopend_rapport_weg` duurde ongeveer 4 minuten (gemeten terwijl er andere Godot-processen draaiden). Voor een echt hoofdstuk wordt dit een probleem; overweeg betere toestandsreductie of een tijdsgrens met duidelijke melding. |
| B3 | kan | godot-engineer | `tests/README.md` noemt "ongeveer een minuut" voor pytest; gemeten 53 s, klopt. De oplosser-commando's met de hand (`solve.py`) noemen geen looptijd; vermeld die. |
| B4 | kan | projectleider | Er staat een ongecommit bestand `docs/review/fundament-code.md` (van de code-review, niet van QA). Niet blokkerend voor QA. |

Geen blokkerende bevindingen. De overige punten van de Definition of done (code-review zonder blokkerende punten; Martijn opent het project en ziet de tests draaien) liggen buiten QA.

Voor iedere rode check zou een issue worden aangemaakt; er zijn geen rode checks, B1 is gemeld aan de producer om als issue (`type:bug`, `agent:godot-engineer`, `hoofdstuk:systeem`) op te pakken.

KLAAR VOOR REVIEW
