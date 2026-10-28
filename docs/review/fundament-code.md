# Code-review fundament (#15)

Reviewer: code-reviewer · Branch: `iteratie/fundament` · Diff `main...HEAD` zonder `game/addons/gut/` · 2026-10-28

Gedraaid: pytest 69 groen, GUT 65/65 groen, `validate.py --all` groen, `solve.py` op de fixture oplosbaar (8 stappen, 108.248 toestanden). Geen playthroughs van eerdere hoofdstukken: die bestaan nog niet.

## Blokkerend

**B1. Autosave midden in een effectenlijst slaat een halve staat op.** `effecten.gd:35` → `spel.gd:204-205`; de knoop wordt pas in `puzzelgraaf.gd:63-66` als opgelost gemarkeerd. Effecten `[naar_kamer X, zet_flag F]` geven een save zonder F, en de knoop kan na laden opnieuw vuren. Raakt SF-14 en TG-11. Fix: autosave pas na afloop van de buitenste trigger.

**B2. `betreed`- en `dialoog`-knopen met `naar_scene` worden verbruikt als de scènewissel geweigerd wordt.** `spel.gd:203` en `gesprek.gd:78` slaan de O9-voorcontrole over; `effecten.gd:33` negeert de weigering. Flag staat, knoop opgelost, scène niet gewisseld; de speler kan het nooit opnieuw proberen. De oplosser (`oplosser_sim.py:256-267`) vuurt de knoop dan helemaal niet: engine en oplosser lopen uiteen. V17 dekt alleen `automatisch` en `gebeurtenis`.

**B3. Knopen van alle hoofdstukken vuren tegelijk.** `puzzelgraaf.gd:30, :82` lopen over `content.alle_knopen` (alle hoofdstukken); de oplosser gebruikt alleen het eigen hoofdstuk. Een `automatisch`-knoop van ch02 kan in ch01 vuren; de hub (ch00) wordt door de oplosser genegeerd en door de engine niet.

## Moet

- **M1. Laden valideert kamer en scène niet** (`opslaan.gd:132-135`); onbekende ids laden met `ok:true`. Ontbrekende sleutels of verkeerde types (`opslaan.gd:104, 148, 150`) crashen; apparaattoestanden niet gecontroleerd.
- **M2. Geen signaal na laden** (`opslaan.gd:129-137`); UI (klok) ververst niet, `blokkades`/`gepauzeerd` niet gereset, `voltooid` wordt false zodat `hoofdstuk_voltooid` opnieuw vuurt; private `_kamer_geluid` wordt van buiten aangeroepen.
- **M3. Gebeurtenisstatus van niet-huidige scènes herstelt niet** (`opslaan.gd:40`, `klok.gd:272-280`); na een niet-lineaire sprong is `voorbij` na laden `wacht`.
- **M4. Onterechte foutregel bij scènewissel via een uitgang** (`spel.gd:227-229`, `toegang.gd:75`); `herzie()` draait met de oude kamer.
- **M5. Oplosser niet eerlijk over wat "geen doodlopende staat" bewijst** (`oplosser.py:128-141`, `solve.py:397-402`): alleen neerleggen van onmisbare objecten, standaard 1 tegelijk; `stop_in`, uitpakken en capaciteit niet gemodelleerd. Spec en uitvoer moeten dat zeggen.
- **M6. V15 gebruikt `any` waar `all` hoort** (`regels_objecten.py:198-202`): terug in de tijd wordt gemist zodra één bron vóór het doel ligt.
- **M7. Validatorregels zonder rode test**: V03, V04, V05, V12, V17, V19, V20, V24, V27, V28, V31. V28 controleert alleen "komt voor", niet "bereikbaar aan het eind van N".
- **M8. Gedeelde testset dekt de productiecontexten niet**: `SpelContext` en `Sim` draaien `condities.json` niet. Afwijkingen: `ligt(x, "nergens")` en de afleiding van "onmisbaar" verschillen tussen GDScript en Python.

## Kan

- Oplosser schaalt slecht (108k toestanden op de fixture; echte hoofdstukken raken `--max-staten`); overweeg partiële-orde-reductie.
- Dode staten via een andere ouder worden niet apart gemeld.
- Opslaan niet atomair (geen tijdelijk bestand, `store_string` niet gecontroleerd).
- Subsystemen grijpen direct in `Spel`-velden; `Gesprek` heeft geen eigenaar in `Spel`.
- Enkele ongetypeerde lussen; waarschuwing voor ongetypeerde declaraties staat niet aan.
- `klok.gd` (289) en `spel.gd` (274) zitten dicht bij de 300-regelgrens.
- `startdatum` valt terug op een hardcoded "2025-01-01"; beter een validatorfout.
- Savetest gebruikt `JSON.parse_string` in plaats van `JsonLezer`.
- Geen migratiepad voor saveversies vastgelegd.
- `geef_object` vóór `naar_scene` in één effectenlijst valt buiten de O9-voorcontrole.

## Oordeel

Drie blokkerende punten. Niet mergen voordat B1–B3 zijn opgelost.
