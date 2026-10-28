# Systemen: overzicht

Specificaties van de spelsystemen van Onderstad. De godot-engineer bouwt alleen wat hier staat; de validator en de oplosser controleren wat hier staat. Bron van waarheid boven deze map: `docs/GDD.md`.

## Specs

| Spec | In één zin | Fase |
| --- | --- | --- |
| [objecten-en-inventaris.md](objecten-en-inventaris.md) | Elk object bestaat één keer, ligt op één plek in een boom, en de speler draagt 8 slots plus gedragen containers. | 0 |
| [toegang.md](toegang.md) | Elke uitgang heeft per kant een `vereist`-regel; passen geven niveaus; `als_bezorger` maakt je onzichtbaar. | 0 |
| [state-en-flags.md](state-en-flags.md) | Flags, tokens, de puzzelgraaf, de gedeelde conditie- en effecttaal, doodlopende staat, de oplosser en opslaan. | 0 |
| [klok-en-scenetijd.md](klok-en-scenetijd.md) | De klok staat stil op de scènetijd, springt per scène, en binnen een scène zijn er alleen gebeurtenissen. | 0 |
| [audio-cues-en-geluidsvenster.md](audio-cues-en-geluidsvenster.md) | Overal een cue-id, nog geen geluid; F2 toont wat je had moeten horen en een logboek telt mee. | 0 |
| [kamerweergave.md](kamerweergave.md) | Elke kamer is een verlicht 3D-eiland op een raster van vakken van 1×1 m, gezien door één vaste camera met smalle FOV. | 1 |

Later (Fase 1+): telefoon en notitieboek-UI, droom, voetsporen en vocht, levende lichtbronnen, ramen en buitenwereld, elektrische apparaten, kleding en uitrusting, metro, hints-UI. De schema's laten daar ruimte voor (zie per spec "uitbreiding later").

## Schema's (`tools/schemas/`, JSON Schema draft 2020-12)

| Schema | Valideert |
| --- | --- |
| `common.schema.json` | niets zelf; gedeelde `$defs`: id-patronen, tekstsleutel, tekstvariant, cue-id, tijd, positie (vak van 1×1 m), vakgebied, kleur, **conditie**, **effect** |
| `spel.schema.json` | `content/spel.json`: startdatum, hoofdstukvolgorde, 8 slots, talen, personages, globale flags, globale condities |
| `item.schema.json` | `content/items.json`: de objectcatalogus |
| `chapter.schema.json` | `content/chapters/<chNN_naam>/chapter.json`: titel, start, doel, scènes, gebeurtenissen, lokale flags, tokens, gebouwen, lokale condities, `aanname_bij_start` |
| `room.schema.json` | `content/chapters/<chNN_naam>/rooms/<kamer_id>.json`: objectboom, uitgangen, NPC's, en voor de weergave plafond, model, camera, geblokkeerde vakken en lichten |
| `puzzle.schema.json` | `content/chapters/<chNN_naam>/puzzles.json`: de puzzelgraaf |
| `dialogue.schema.json` | `content/chapters/<chNN_naam>/dialogue/<dialoog_id>.json` |
| `device.schema.json` | `content/chapters/<chNN_naam>/devices/<apparaat_id>.json`: vergrendeling en apps |
| `audio-cues.schema.json` | `audio/cues.json` |
| `tekst.schema.json` | `content/tekst/<taal>/<domein>.json` |

Elk schema heeft een `$id` onder `https://onderstad.local/schemas/` en verwijst met relatieve `$ref`s (`common.schema.json#/$defs/conditie`). De validator laadt alle schema's in één register (Python `referencing`) en valideert offline. Content-bestanden mogen een `"$schema"`-veld hebben voor editors.

## Contentstructuur

```
content/
  spel.json                       # globaal (nieuw t.o.v. GDD, zie onder)
  items.json                      # alle objecten
  tekst/
    nl/algemeen.json              # ui.*, klok.*, systeem.*, personage.*
    nl/items.json                 # item.*
    nl/ch00_hub.json              # alles van de hub
    nl/ch01_katendrecht.json      # alles van hoofdstuk 1
  chapters/
    ch00_hub/                     # de hub is hoofdstuk 0
      chapter.json  puzzles.json  rooms/*.json  dialogue/*.json  devices/*.json
    ch01_katendrecht/
      ...
audio/cues.json
```

## Id-conventies

| Soort | Patroon | Uniek binnen | Voorbeeld |
| --- | --- | --- | --- |
| Hoofdstuk | `chNN_naam` (= mapnaam) | spel | `ch01_katendrecht` |
| Kamer, scène, gebeurtenis, puzzelknoop, dialoog, apparaat | `chNN_…` met de prefix van het eigen hoofdstuk | spel | `ch01_loft`, `ch01_s1_nacht`, `ch01_pauze_beveiliger` |
| Lokale flag, lokale benoemde conditie | `chNN_…` | spel | `ch01_hek_open` |
| Object (item), token, personage, globale flag, globale conditie | snake_case **zonder** `chNN_`-prefix | spel (per soort) | `bezorgtas`, `pin_ontwikkelaar`, `barman`, `dossier_gevonden`, `als_bezorger` |
| Uitgang, NPC-plaatsing | snake_case | kamer | `deur_gang`, `beveiliger` |
| Gespreksregel, keuze | snake_case | gesprek / regel | `r_opening`, `k_vraag_pauze` |
| App, app-item | snake_case | apparaat / app | `berichten`, `bericht_pauze` |
| Gebouw, niveau | snake_case; verwijzing als `gebouw.niveau` | hoofdstuk / gebouw | `pakhuis.loft` |
| Audio-cue | punt-gescheiden snake_case, categorie eerst | catalogus | `deur.lift.open` |
| Tekstsleutel | punt-gescheiden snake_case | taal | `item.bezorgtas.naam` |

Alles in kleine letters, ASCII, zonder spaties. Bestandsnaam van een kamer, gesprek of apparaat = het id. `richard` is het vaste personage-id van de hoofdpersoon.

## Lokalisatie

**Beslissing:** content bevat nooit spelerszichtbare tekst, alleen tekstsleutels. De teksten staan per taal en per domein in `content/tekst/<taal>/<domein>.json` (schema `tekst.schema.json`):

```json
{ "taal": "nl", "domein": "items", "teksten": { "item.bezorgtas.naam": "bezorgtas" } }
```

- **Domeinen:** `algemeen` (UI, klok, systeemmompels, personagenamen), `items` (alles van `items.json`), en één bestand per hoofdstuk (kamers, NPC's, gesprekken, apparaten, tokens, hints, titelkaart van dat hoofdstuk). Zo werkt een schrijver per hoofdstuk in één bestand, en een vertaler later per bestand.
- **Sleutelconventie** (de validator waarschuwt bij afwijking, faalt niet):

| Bron | Sleutel |
| --- | --- |
| object | `item.<id>.naam`, `.beschrijving`, `.lees`, `.gebruik`, `.geweigerd` |
| kamer | `kamer.<id>.naam`, `.beschrijving` |
| uitgang | `uitgang.<kamer_id>.<uitgang_id>.naam`, `.geweigerd` |
| NPC | `npc.<kamer_id>.<npc_id>.bekijk`; naam via `personage.<id>.naam` |
| gesprek | `dlg.<dialoog_id>.<regel_id>`, keuze `dlg.<dialoog_id>.<regel_id>.<keuze_id>` |
| apparaat | `app.<apparaat_id>.naam`, `app.<apparaat_id>.<app_id>.<item_id>.tekst` / `.titel` / `.afzender` |
| token | `token.<id>` |
| hint | `hint.<knoop_id>.vaag` / `.richting` / `.bijna` |
| knoop-mompel | `knoop.<knoop_id>.onvervuld` |
| hoofdstuk | `hoofdstuk.<id>.titel`, `gebouw.<hoofdstuk>.<gebouw>.naam` |
| systeem | `systeem.*` (mompels van systemen), `ui.*`, `klok.*` |

- **Varianten:** waar het schema `tekstvariant` toestaat (beschrijvingen, leesteksten), mag een lijst `[{"als": conditie, "tekst": sleutel}, …, {"tekst": sleutel}]`; de eerste met kloppende `als` wint. Dat maakt teksten die per nacht verschuiven mogelijk (Twijfel) zonder extra objecten.
- **Invoegen:** een tekst mag `{token:<id>}` bevatten (waarde van een token). Andere plaatshouders bestaan niet.
- **Basistaal** is `nl` en moet compleet zijn. Een andere taal mag onvolledig zijn; ontbrekende sleutels vallen terug op `nl` (en de validator meldt per taal het percentage).
- Ontwerpteksten (`notitie`, `omschrijving`, `waarom`, `beschrijving` in de cue-catalogus) zijn geen spelerstekst en worden niet vertaald.

## Kruisverwijzingsregels voor de validator

Bovenop het JSON Schema controleert `tools/validate.py --all`:

**Bestaan en uniciteit**

- V01. Geen dubbele ids per soort: objecten, tokens, personages, flags (globaal + alle hoofdstukken), condities, kamers, scènes, gebeurtenissen, knopen, dialogen, apparaten, cues, tekstsleutels (over alle bestanden van één taal). Uitgang-, NPC- en licht-ids uniek per kamer; regel-ids per gesprek; keuze-ids per regel; app-ids per apparaat; app-item-ids per app.
- V02. Elke verwijzing bestaat: items, tokens, personages, flags, benoemde condities, kamers, scènes, gebeurtenissen, knopen, dialogen, apparaten, apps en app-items (in triggers), gespreksregels (in triggers, `start`, `volgende`), gebouwen en niveaus (`gebouw.niveau`).
- V03. Bestandsnaam = id voor kamers, gesprekken en apparaten; mapnaam = id voor hoofdstukken; elk hoofdstuk staat in `spel.json` → `hoofdstukken`.
- V04. Scope: een id met `chNN_`-prefix wordt alleen gebruikt in content van hoofdstuk NN; het hoofdstuk van een kamer/scène/knoop/… komt overeen met de map waarin het staat. Uitzondering: scènes mogen hubkamers (`ch00_…`) in `kamers` hebben en uitgangen mogen naar hubkamers wijzen.
- V05. Objecten, tokens, personages, globale flags en globale condities hebben **geen** `chNN_`-prefix; lokale flags en lokale condities wél.
- V06. Elke tekstsleutel in content bestaat in de basistaal; ongebruikte sleutels geven een waarschuwing.
- V07. Elk cue-id in content (en letterlijk in `game/**/*.gd`) bestaat in `audio/cues.json`; `soort` past bij het gebruik (`ambience`, `muziek`, NPC-`geluid` = doorlopend; de rest eenmalig).

**Objecten en containers**

- V08. Elk object heeft hoogstens één beginplek (kamerplaatsing of `aanname_bij_start.inventaris` van één hoofdstuk). Objecten zonder beginplek moeten ergens via `geef_object` ontstaan, anders waarschuwing.
- V09. Begininhoud past: per container som van groottes ≤ `capaciteit`, elk object ≤ `max_grootte`; alleen pakbare objecten in containers; geen kringen. Niet-pakbare objecten alleen als kamerplaatsing op het hoogste niveau. `aanname_bij_start.inventaris` past in 8 slots.
- V10. `acties` klopt: `bekijk` altijd; `pak` ⇔ `pakbaar`; `open` ⇔ `container`; `lees` ⇔ `leestekst`.
- V11. Posities (objecten, uitgangen, NPC's, start, lichten) en `geblokkeerd`-gebieden liggen binnen de `afmeting` van de kamer, in vakken.
- V12. Waarschuwing als de som van de groottes van alle onmisbare pakbare objecten van een hoofdstuk groter is dan 8 (ze passen dan alleen met containers).

**Toegang en scènes**

- V13. Uitgangen zijn wederzijds: de doeluitgang bestaat en wijst terug naar deze kamer (bij een lift: een van de `bestemmingen` wijst terug).
- V14. Elke kamer van een hoofdstuk zit in minstens één scène; `start.kamer` zit in `start.scene`; `start.uitgang` bestaat in die kamer.
- V15. Scènewissels (`naar_scene` in effecten en op uitgangen): de nieuwe scènetijd ≥ de huidige, behalve als een van beide `niet_lineair` heeft. Zonder `kamer` moet de huidige kamer in de nieuwe scène zitten (voor alle kamers waar de trigger kan gebeuren).
- V16. Over alle hoofdstukken hoogstens twee verschillende `niet_lineair`-moment-ids.
- V17. Een `naar_scene` in een knoop mag, bij **elke** triggersoort (ook `betreed`, `dialoog`, `gebruik`, `automatisch`, `gebeurtenis`), geen kamers uit de huidige scène laten wegvallen (objecten-en-inventaris.md, O9; state-en-flags.md, vuurregel 2a). Fout. Waarschuwing als in dezelfde effectenlijst een `geef_object` of `verplaats_object` vóór de `naar_scene` staat (valt buiten de O9-voorcontrole). "Huidige scène" = elke scène waarin de trigger van de knoop kan gebeuren.- V18. Elke gebeurtenis die in een conditie voorkomt is merkbaar: `cue_start`, `cue_einde`, of een NPC wiens `aanwezig` ervan afhangt.
- V19. Waarschuwing: uitgang naar een kamer met een `niveau` zonder `niveau`-, `token`- of `heeft`-atoom in `vereist`.

**Puzzelgraaf, flags en tokens**

- V20. Toestandswijzigende effecten (alles behalve `cue` en `mompel`) staan alleen in `puzzles.json`.
- V21. Precies één knoop met `type: doel` per hoofdstuk, en `chapter.doel` verwijst ernaar of is ermee te vervullen.
- V22. Elke `hoofd`-knoop heeft `hints` met drie sleutels.
- V23. **Verkrijgbaar:** elk token in een conditie of `sleutel_token` wordt ergens gegeven (`geef_token` of `aanname_bij_start.tokens`); elke flag in een conditie wordt ergens gezet of heeft een `start`-waarde die de conditie waar kan maken; elk object in `heeft`/`ligt`/trigger heeft een beginplek of wordt gegeven; elk `niveau` wordt door minstens één object gegeven.
- V24. Elk gegeven token wordt ergens gebruikt (conditie, `sleutel_token` of `combineer`), anders waarschuwing.
- V25. Benoemde condities vormen geen kring.
- V26. Lokale flags en condities van hoofdstuk NN worden niet gelezen of gezet buiten NN (zelfde als V04, expliciet genoemd omdat het de meest gemaakte fout zal zijn).
- V27. Waarschuwing: twee knopen met identieke trigger waarvan de `vereist` elkaar niet uitsluiten (alleen de eerste vuurt).
- V28. `aanname_bij_start` van hoofdstuk N+1 wordt waargemaakt door hoofdstuk N: elk aangenomen object is aan het eind van N in de inventaris bereikbaar, elke aangenomen flag en elk token is in N verkrijgbaar (waarschuwing zolang N nog niet bestaat).

**Gesprekken en apparaten**

- V29. Elke gespreksregel is bereikbaar vanaf `start` (waarschuwing); elke `spreker` is `richard` of staat in `deelnemers`; `volgende` wijst naar een bestaande regel.
- V30. Elke dialoog wordt door minstens één NPC in een kamer van hetzelfde hoofdstuk gebruikt.
- V31. Het `object` van een apparaat bestaat; elk object hoort bij hoogstens één apparaat.

Validatorfouten noemen altijd bestand, JSON-pad en de regel (V-nummer). Waarschuwingen laten `--all` groen.

## Wijzigingsregel

Bij elke wijziging aan een spec of schema noemt de systems-designer welke hoofdstukken en welke content geraakt worden. Fase 0 raakt nog geen content (alleen de testfixture in `tests/fixtures/`).
