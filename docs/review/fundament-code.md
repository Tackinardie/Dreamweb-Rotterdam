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

---

# Hercontrole na reviewronde 1 (HEAD dde92a7)

Gedraaid: `python tools/test_godot.py` groen (GUT 78/78), pytest 93 groen, `validate.py --all` groen, `solve.py` op de fixture groen met beperkingenblok.

| Punt | Oordeel |
| --- | --- |
| B1 autosave | Opgelost (`begin_actie`/`einde_actie`; `test_sf21`) |
| B2 geweigerde scènewissel | Opgelost, engine en oplosser gelijk (`test_oi14_*`, `test_sf19`) |
| B3 knoopscope | Opgelost (`actieve_knopen`; `test_sf20`) |
| M1 laden valideren | Grotendeels opgelost (rest: N3, N6) |
| M2 signaal na laden | Opgelost (rest: N1) |
| M3 gebeurtenisstatus | Opgelost (`test_sf25`) |
| M4 scènewissel via uitgang | Opgelost (`test_m4`) |
| M5 oplosserbeperkingen | Opgelost (`test_sf23_*`) |
| M6 V15 | Opgelost (zie N7) |
| M7 validatortests | Opgelost; V28 aangescherpt (zie N8) |
| M8 pariteit condities | Opgelost |

## Nieuwe bevindingen

**Blokkerend**: geen.

**Moet**
- **N1.** Mompel-wachtrij wordt bij laden en `nieuw_spel` niet geleegd (`opslaan.gd:178-188`, `spel_tekst.gd:30-40`): een mompel uit de vorige sessie verschijnt na het volgende gesprek.
- **N2.** Autosave verdwijnt als aan het eind van een actie een blokkade staat (`spel.gd:183-187`): een `dialoog`-knoop met `naar_kamer` tijdens een gesprek geeft nooit een autosave.
- **N3.** `slot_titel` crasht op een kapotte save (`opslaan.gd:196-197`).

**Kan**
- **N4.** Een geweigerde `gebeurtenis`-knoop wordt pas bij een volgende statuswijziging opnieuw geprobeerd.
- **N6.** Positie in een save wordt niet gevalideerd.
- **N7.** V15 met `all` is conservatief zonder `scene`-atoom; leg in de spec vast dat auteurs een `scene`-atoom gebruiken, en voeg een test toe met een vroege en een late bron.
- **N8.** V28 kijkt alleen naar `verwijder_object`, niet naar `verplaats_object` naar `nergens` of `geef_object` aan een NPC.
- Nog open uit ronde 1: oplosserprestaties, bestandsgrootte `klok.gd`/`spel.gd`, ongetypeerde lussen, migratiepad saveversies.

## Oordeel

Geen blokkerende punten. N1–N3 oplossen vóór de merge.
