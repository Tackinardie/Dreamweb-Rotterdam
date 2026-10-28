# State en flags

**In één zin:** alles wat de speler veranderd heeft, staat op één plek (GameState), wordt gelezen met één conditietaal en veranderd met één effecttaal, en de puzzelgraaf zegt welke verandering waarvoor nodig is.

Schema's: `tools/schemas/common.schema.json` (conditie, effect), `tools/schemas/puzzle.schema.json` (puzzelgraaf), `tools/schemas/chapter.schema.json` (lokale flags, tokens, scènes), `tools/schemas/spel.schema.json` (globale flags, benoemde condities).

## Doel en pillar

- **Informatie is de sleutel (3):** feiten die de speler vindt worden feit-tokens in het notitieboek. Puzzels vragen om het token, niet om exacte invoer: wie het feit heeft afgeleid, komt verder.
- **Een fysieke wereld (2):** de puzzelgraaf maakt zichtbaar wat een echt mens nodig heeft om iets te doen; de oplosser bewijst binnen zijn model dat niets onbereikbaar wordt (geen game-over, geen doodlopende staat; zie "Wat de oplosser bewijst, en wat niet").
- Ondersteunend voor alle pillars: hints, opslaan en de automatische tests leunen hierop.

## Begrippen

| Begrip | Wat | Waar gedeclareerd | Leeftijd |
| --- | --- | --- | --- |
| Globale flag | bool of int, zonder prefix (`hoofdstuk`, `dossier_gevonden`) | `content/spel.json` → `flags` | hele spel |
| Lokale flag | bool of int, met prefix van het eigen hoofdstuk (`ch01_bouwlift_gezien`) | `chapter.json` → `flags` | hele spel bewaard, alleen leesbaar in dat hoofdstuk |
| Feit-token | iets wat Richard weet (naam, code, tijd, plek) | `chapter.json` → `tokens` | hele spel, in het notitieboek |
| Puzzelknoop | actie, feit of doel in de graaf | `puzzles.json` | opgelost blijft opgelost |
| Gebeurtenis | iets wat binnen een scène gebeurt (zie klok-en-scenetijd.md) | `chapter.json` → scène | tot einde scène |
| Benoemde conditie | herbruikbare conditie met een naam (`als_bezorger`) | `spel.json` (globaal) of `chapter.json` (lokaal, prefix) | — |
| Objectboom | waar elk object ligt (zie objecten-en-inventaris.md) | rooms + `aanname_bij_start` | hele spel |
| Apparaattoestand | vergrendeld/ontgrendeld (later meer) | `devices/*.json` | hele spel |

**Scope-regel (prefix):** een id met prefix `chNN_` hoort bij hoofdstuk NN en mag alleen in content van dat hoofdstuk worden gelezen of gezet. Ids zonder prefix zijn globaal. De validator dwingt dit af. Een ander hoofdstuk dat iets wil weten van ch01, leest een globale flag die ch01 zet.

## De conditietaal

Eén JSON-taal die toegang (`vereist` op uitgangen en containers), de puzzelgraaf (`vereist` op knopen), dialoog (`als` op start en keuzes), NPC-aanwezigheid, gebeurtenisstarts en tekstvarianten allemaal gebruiken. De GDScript-evaluator (`game/systems/`) en de Python-oplosser (`tools/solve.py`) implementeren precies deze tabel; een gedeelde testset (zie acceptatiecriteria) bewaakt dat ze hetzelfde antwoorden.

Een conditie is altijd een object met precies één sleutel (plus eventuele vaste bijvelden). Afwezige conditie = waar.

| Vorm | Waar als | Voorbeeld |
| --- | --- | --- |
| `{"alle": [c…]}` | alle deelcondities waar (lege lijst niet toegestaan) | `{"alle": [{"heeft": "bezorgtas"}, {"heeft": "jas_richard"}]}` |
| `{"een_van": [c…]}` | minstens één waar | |
| `{"niet": c}` | c onwaar | |
| `{"heeft": item}` | object zit in de inventaris, op elke diepte (ook in een gedragen jas → portemonnee) | `{"heeft": "pasje_x"}` |
| `{"ligt": {"object": item, "in": plek}}` | object ligt ergens onder `plek` (op elke diepte). `plek` = `inventaris`, een kamer-id of een item-id | `{"ligt": {"object": "kop_koffie", "in": "balie_x"}}` |
| `{"token": id}` | token staat in het notitieboek | `{"token": "pin_x"}` |
| `{"flag": id}` | flag is `true` of ≠ 0 (nooit gezet = startwaarde) | |
| `{"flag": id, "gelijk": v}` / `"minstens": n` / `"hoogstens": n` | vergelijking; precies één vergelijking | `{"flag": "hoofdstuk", "minstens": 2}` |
| `{"knoop": id}` | puzzelknoop is opgelost | |
| `{"kamer": id}` | speler is in die kamer | |
| `{"scene": id}` | huidige scène | |
| `{"gebeurtenis": id}` | gebeurtenis is `actief`; met `"status": "wacht"\|"voorbij"` die status | `{"gebeurtenis": "ch01_pauze_beveiliger"}` |
| `{"kloktijd": {"van": "HH:MM", "tot": "HH:MM"}}` | scènetijd in [van, tot); van > tot = over middernacht | `{"kloktijd": {"van": "23:00", "tot": "06:00"}}` |
| `{"scenetijd": {"vanaf": t, "voor": t}}` | scènetijd in [vanaf, voor); één grens mag ontbreken. `t = {"dag": n, "tijd": "HH:MM"}` | |
| `{"niveau": "gebouw.niveau"}` | speler heeft een object met dat niveau in `geeft_niveaus` | `{"niveau": "toren.dak"}` |
| `{"apparaat": id, "toestand": "ontgrendeld"\|"vergrendeld"}` | apparaattoestand | |
| `{"conditie": naam}` | de benoemde conditie is waar | `{"conditie": "als_bezorger"}` |

**Evaluatieregels (bindend voor beide implementaties)**

1. Zuiver: evalueren verandert niets, ook geen "gezien"-markeringen.
2. Deterministisch: dezelfde toestand geeft altijd hetzelfde antwoord; geen toeval, geen echte tijd. Alleen de scènetijd en de gebeurtenisstatus brengen tijd binnen.
3. Onbekende id tijdens het spel: onwaar, plus een foutmelding in de log (ontwikkelbuild). De validator voorkomt dit vooraf.
4. Flags die nooit gezet zijn hebben hun gedeclareerde `start`-waarde.
5. Benoemde condities mogen elkaar aanroepen, maar niet in een kring (validator).
6. Lokale benoemde condities en flags van hoofdstuk NN zijn buiten hoofdstuk NN onbekend (validator).

Bewust **niet** in de taal: willekeur, rekenen, tekstvergelijking, "speler heeft object X bekeken". Wat de speler moet weten, wordt een token; wat hij moet hebben gedaan, wordt een knoop.

**Uitbreiding later** (alleen nieuwe atomen, bestaande blijven gelijk): `draagt` (kleding), `rol` (kleding: outfit + plek + tijd), `apparaat`-toestanden `uit/standby/aan/bezig/kapot` (apparaten), `raam` (open/dicht), `schoen` (nat/vuil-drempels). Elk nieuw atoom gaat tegelijk in GDScript, Python en de gedeelde testset.

## De effecttaal

Een lijst effecten wordt in volgorde uitgevoerd. Elk effect is atomair.

| Effect | Wat |
| --- | --- |
| `{"zet_flag": id, "waarde": v}` | flag zetten (waarde standaard `true`) |
| `{"wis_flag": id}` | terug naar `false` / `0` |
| `{"geef_token": id}` | token in het notitieboek; al aanwezig = niets |
| `{"geef_object": item}` | object (dat 'nergens' is) komt in de inventaris; past het niet, dan op de grond waar de speler staat |
| `{"verplaats_object": {"object", "naar", "positie"?}}` | object naar inventaris, kamer of container |
| `{"verwijder_object": item}` | object naar 'nergens' (opgedronken, afgegeven) |
| `{"start_gebeurtenis": id}` / `{"stop_gebeurtenis": id}` | gebeurtenis handmatig starten/stoppen |
| `{"naar_scene": id, "kamer"?, "uitgang"?}` | tijdsprong (zie klok-en-scenetijd.md) |
| `{"naar_kamer": id, "uitgang"?}` | speler verplaatsen (bijv. weggestuurd) |
| `{"cue": cue_id}` | audio-cue (geen toestand) |
| `{"mompel": tekstsleutel}` | Richard zegt een korte zin (geen toestand) |

**Regel: toestand verandert alleen via de puzzelgraaf.** Effecten die toestand wijzigen (alles behalve `cue` en `mompel`) staan uitsluitend in `puzzles.json`. Gesprekken, apparaten en kamers wijzigen zelf niets; ze zijn triggers. Uitzonderingen zijn de systeemhandelingen die de oplosser zelf modelleert: lopen, pakken, neerleggen, containers openen, apparaten ontgrendelen met een token, gebeurtenissen die volgens hun regels starten en stoppen. Zo is de graaf compleet en hoeft de oplosser niets anders te lezen voor toestandsveranderingen.

## Feit-tokens en het notitieboek (datamodel)

- Een token heeft `id`, `categorie` (`persoon`, `plek`, `code`, `tijd` = de tabbladen), optioneel `waarde` (de exacte code, niet vertaald) en `notitie` (tekstsleutel: de regel in het notitieboek). De tekst mag `{token:<id>}` bevatten om de waarde in te voegen.
- In de save per token: `id`, `verkregen_op` (scènetijd), `bron_knoop` (welke knoop het gaf), `nieuw` (nog niet bekeken in het notitieboek).
- Tokens gaan nooit meer weg. Er bestaat geen effect om een token af te nemen.
- **Combineren:** een knoop met trigger `{"combineer": [a, b]}` vuurt als de speler in het notitieboek a op b sleept en de knoop `vereist` klopt; het effect is meestal `geef_token`. Verkeerde combinatie: mompel `systeem.notitie.past_niet`, verder niets.
- **Apparaat-invoer:** een vergrendeld apparaat met `sleutel_token` gaat open als de speler het token heeft (de telefoon-UI biedt het aan vanuit het notitieboek) of de exacte `waarde` zelf intypt; in het tweede geval krijgt hij het token er ook bij. Uitwerking van de UI volgt in de telefoonspec (Fase 1).
- Tot de telefoon-UI er is: bij `geef_token` verschijnt onderin kort een regel "Genoteerd: <notitie>" (sleutel `ui.notitie.genoteerd`) en klinkt cue `ui.notitie.nieuw`.

## De puzzelgraaf

Per hoofdstuk één `puzzles.json` met knopen. Een knoop is een actie, feit of doel.

| Veld | Betekenis |
| --- | --- |
| `id` | `chNN_…` |
| `type` | `actie`, `feit`, `doel` (precies één `doel` per hoofdstuk) |
| `pad` | `hoofd` (nodig voor het doel) of `zij` (optioneel) |
| `waarom` | één zin: waarom een echt mens dit zo doet (ontwerptekst) |
| `trigger` | speleractie of gebeurtenis die de knoop laat vuren (zie schema: gebruik [met], pak, open, lees, bekijk, geef/aan, dialoog/regel, apparaat/app/item, ontgrendel, combineer, betreed, gebeurtenis, automatisch) |
| `vereist` | conditie; de **kanten** van de graaf zijn de `knoop`-, `token`-, `heeft`-, `flag`- en `gebeurtenis`-atomen hierin |
| `effecten` | beloning: tokens, objecten, flags, scènewissel |
| `bij_onvervuld` | mompel als de trigger gebeurt maar `vereist` niet klopt |
| `herhaalbaar` | standaard `false` |
| `hints` | drie tekstsleutels: `vaag`, `richting`, `bijna`; verplicht bij `pad: hoofd` |

**Actieve knopen (scope).** Alleen de knopen van het huidige hoofdstuk (`hoofdstuk` in de save) plus die van `ch00_hub` zijn actief. Knopen van andere hoofdstukken worden niet bekeken: niet bij triggers, niet bij `automatisch`-rondes, niet bij hints. Dat geldt identiek voor de engine en de oplosser. De oplosser van hoofdstuk NN laadt dus de knopen van NN en van `ch00_hub`; de oplosser van `ch00_hub` zelf alleen die van de hub.

**Vuurregels**

1. Bij elke speleractie bepaalt het systeem de trigger (bijv. `gebruik koffie met portier_balie`).
2. De actieve knopen met die trigger worden in bestandsvolgorde bekeken (eerst het huidige hoofdstuk, dan `ch00_hub`). De **eerste** die nog niet opgelost is (of herhaalbaar is), waarvan `vereist` klopt en die niet geblokkeerd is door regel 2a, vuurt: effecten in volgorde, daarna `opgelost`. Er vuurt per actie hoogstens één knoop.
2a. **Geweigerde scènewissel.** Bevat een knoop een `naar_scene`-effect en zou die wissel volgens O9 geweigerd worden (onmisbaar object in een kamer die wegvalt), dan vuurt de knoop **helemaal niet**: geen enkel effect, niet `opgelost`. Dit wordt vóór het eerste effect gecontroleerd, voor elke triggersoort (ook `betreed`, `dialoog`, `automatisch` en `gebeurtenis`). Bij een speleractie volgt de O9-mompel `systeem.niet_zonder` en cue `ui.weiger`; bij `automatisch` en `gebeurtenis` gebeurt niets zichtbaars (de validator voorkomt dat geval, V17). De speler kan het later opnieuw proberen: de trigger werkt weer zodra het object is opgehaald. De controle gebruikt de objectboom van vóór de effecten; een `geef_object` of `verplaats_object` eerder in dezelfde lijst telt niet mee (de validator waarschuwt als zo'n effect vóór `naar_scene` staat, zie V17).
3. Klopt geen enkele `vereist`, dan toont de eerste knoop met die trigger zijn `bij_onvervuld`; zonder `bij_onvervuld` volgt de standaardreactie van het object (`gebruik_tekst`, beschrijving).
4. Na elke toestandswijziging worden `automatisch`-knopen en gebeurtenisstarts opnieuw bekeken, tot er niets meer verandert, met een harde grens van 32 rondes (daarboven: fout in de log, validator moet de kring vinden).
4a. **Afhandeling van een trigger** is één geheel: alle effecten van de knoop, knoop gemarkeerd als `opgelost`, toegang herzien (huidige kamer), en de `automatisch`-rondes van regel 4. Pas daarna mag er iets bewaard worden (zie Opslaan). Een `naar_kamer`- of `naar_scene`-effect midden in de lijst schrijft zelf geen save.
5. Het doel: zodra `chapter.doel` klopt, eindigt het hoofdstuk (droomovergang en titelkaart van het volgende hoofdstuk volgen later uit de droomspec).

**Hints (data nu, gedrag Fase 2).** De hintknoop is de eerstvolgende open knoop: van de niet-opgeloste `hoofd`-knopen eerst die waarvan `vereist` nu klopt; anders die met de minste onware atomen; gelijk = bestandsvolgorde. Elke volgende hintvraag voor dezelfde knoop gaat een niveau omhoog (vaag → richting → bijna) en dat niveau wordt bewaard. De GDD noemt mompelen bij stilstand; de UI daarvoor volgt in de hintspec.

## Doodlopende staat

**Definitie:** een toestand die de speler kan bereiken en van waaruit het doel van het hoofdstuk niet meer bereikbaar is. Ook: een kamer waaruit geen enkele actie meer leidt naar een andere toestand.

Typische oorzaken die de oplosser moet vinden:

- een object dat in een `heeft`/`ligt`-atoom of trigger nodig is, is `verwijderd` of ligt in een kamer die niet meer bereikbaar is;
- een token dat nodig is, kan alleen in een scène worden verkregen die al voorbij is;
- een eenmalige gebeurtenis die nodig is, is `voorbij`;
- een uitgang terug is permanent dicht nadat de speler erdoor ging.

Wat de **engine** garandeert (zodat de oplosser het niet hoeft te ontdekken): de speler kan geen onmisbaar object achterlaten bij een scènewissel die kamers onbereikbaar maakt (zie objecten-en-inventaris.md, regel O9). Wat de **oplosser** garandeert: al het andere, binnen de grenzen van zijn model (leg-limiet, geen `stop_in`/uitpakken/capaciteit; zie de oplosser hieronder). Wat buiten dat model valt, dekken de headless playthrough en de gerandomiseerde inventaristest.

**Onmisbaar** is een afgeleide eigenschap, geen veld: een object is onmisbaar als het in content voorkomt in een `heeft`- of `ligt`-atoom, in een trigger (`gebruik`, `met`, `geef`, `open`, `lees`), of als `object` van een apparaat. Zit een onmisbaar object in een container, dan erft die container de bescherming zolang het object erin zit.

De afleiding volgt **dezelfde scope als de actieve knopen**: alleen content van het huidige hoofdstuk plus `ch00_hub` telt (knopen, uitgangen, containers, gesprekken, apparaten, benoemde condities, en het hoofdstukdoel). Engine (GDScript) en oplosser (Python) leiden de lijst op precies deze manier af; de gedeelde testset bevat de afgeleide lijst voor de fixture (SF-22). Bij een hoofdstukwissel wordt de lijst opnieuw afgeleid.

## De oplosser (wat `tools/solve.py` moet modelleren)

- **Scope:** de actieve knopen en de onmisbaar-afleiding zoals hierboven (huidig hoofdstuk plus `ch00_hub`), identiek aan de engine.
- **Toestand:** huidige kamer, huidige scène, gebeurtenisstatus, flags, tokens, opgeloste knopen, apparaattoestanden, en de plek van elk onmisbaar object (`inventaris`, kamer-id, container-id of `nergens`). Niet-onmisbare objecten en capaciteit worden niet gemodelleerd (de validator controleert capaciteit apart, zie README).
- **Acties:** lopen door een uitgang (als `vereist` klopt en de doelkamer in de scène zit); pak en leg neer van onmisbare objecten; container openen; knoop vuren (trigger mogelijk vanaf de huidige plek, `vereist` klopt en de knoop is niet geblokkeerd door vuurregel 2a); apparaat ontgrendelen (token bekend, object bereikbaar); wachten op een gebeurtenis (start-conditie klopt, of herhalend); gesprekregel bereiken (NPC aanwezig en er is een pad van keuzes waarvan de `als` klopt).
- **Bereikbaar** voor een trigger: het object zit in de inventaris of ligt in de huidige kamer (ook in containers die geopend kunnen worden).
- **Gebeurtenissen met duur:** de oplosser neemt aan dat binnen één actieve periode elke afzonderlijke actie die de gebeurtenis vereist, lukt. Dat is een **aanname**, geen bewijs. Of het venster in speeltijd lang genoeg is, toetst de headless playthrough.
- **Uitvoer:** oplosbaar ja/nee; kortste oplossing als lijst acties; aantal stappen; elke doodlopende staat met het pad ernaartoe en de vermoedelijke oorzaak; knopen die nooit vuren; tokens die nooit gegeven of nooit gebruikt worden; het maximale aantal tegelijk open `hoofd`-knopen (puzzle-designer-regel: maximaal 3).

**Wat de oplosser bewijst, en wat niet.** Het bewijs geldt binnen een begrensd model; de oplosser zegt dat eerlijk.

| | |
| --- | --- |
| Bewezen | Oplosbaarheid: er is een reeks acties van de start naar het doel. |
| Bewezen, binnen leg-limiet N | Geen doodlopende staat onder alle toestanden die bereikbaar zijn als hoogstens N onmisbare objecten tegelijk buiten hun beginplek zijn neergelegd (in een kamer die niet hun beginplek is). Standaard N = 1; instelbaar met `--leg-limiet N`. Hogere N verkent meer, maar de toestandsruimte groeit snel. |
| Niet gemodelleerd | `stop_in` (een object in een container stoppen), uitpakken uit een container in de inventaris, en inventariscapaciteit (8 slots, `capaciteit`, `max_grootte`). Doodlopende staten die alleen via die handelingen ontstaan, vindt de oplosser niet. Capaciteit wordt deels door de validator gedekt (V09, V12); de rest door de headless playthrough en de gerandomiseerde test (OI-06, OI-07). |
| Aanname | Gebeurtenisduur: elke actie binnen een actieve periode lukt (zie boven). |

**Verplichte vermelding in de uitvoer.** Elke run van `tools/solve.py` drukt, vóór of na de uitslag en ook bij `--json` (veld `beperkingen`), een blok af met: de gebruikte leg-limiet N; de zin dat `stop_in`, uitpakken en inventariscapaciteit niet gemodelleerd zijn; de zin dat gebeurtenisduur een aanname is; en het aantal verkende toestanden, met de melding als `--max-staten` bereikt is (dan is "geen doodlopende staat" niet bewezen en is de uitslag `onvolledig`, niet groen). Voorbeeld:

```
Beperkingen van dit bewijs:
- leg-limiet: 1 onmisbaar object tegelijk buiten zijn beginplek
- niet gemodelleerd: stop_in, uitpakken, inventariscapaciteit
- aanname: binnen een actieve gebeurtenis lukt elke actie die hem vereist
- verkende toestanden: 108248 (limiet niet bereikt)
```

QA-rapporten nemen dit blok letterlijk over bij de uitslag van de oplosser.

## Opslaan

- **Automatisch** bij elke kamerwissel, nadat de speler in de nieuwe kamer staat (één rollend slot: `user://saves/auto.json`). Komt de kamerwissel uit een effect (`naar_kamer`, `naar_scene`), dan wordt de autosave pas geschreven nadat de hele trigger is afgehandeld (vuurregel 4a: alle effecten, knoop `opgelost`, toegang herzien, `automatisch`-rondes klaar). Nooit midden in een effectenlijst. Meerdere kamerwissels binnen één trigger geven één autosave, aan het eind. Bij een kamerwissel door een uitgang is de trigger afgehandeld na aankomst plus de `betreed`-knoop die daardoor vuurt (inclusief al zijn effecten) en de `automatisch`-rondes; daarna volgt de autosave.
- **Handmatig:** één slot (`user://saves/handmatig.json`) via het pauzemenu; overschrijven vraagt bevestiging.
- Niet opslaan tijdens: gesprek, close-up, titelkaart, droomovergang, scènewissel. Het menu-item is dan grijs.
- **Laden** toont per slot: kamernaam en klok (bijv. "Studentenkamer · za 1 jan · 00:07"), geen echte datum.

**Wat er in een save zit** (JSON):

| Sleutel | Inhoud |
| --- | --- |
| `versie` | savenummer (int); bij een hogere versie dan het spel kent: niet laden, melding |
| `content_hash` | hash van de content; anders dan nu = waarschuwing in ontwikkelbuild, toch laden |
| `hoofdstuk`, `scene`, `kamer`, `positie` | waar de speler is |
| `objecten` | per object dat niet op zijn beginplek ligt: `{plek, positie?}` (plek = `inventaris`, kamer-id, item-id of `nergens`), plus de volgorde in de inventaris |
| `containers_open` | ids van containers die geopend zijn |
| `flags` | alleen afwijkingen van de startwaarde |
| `tokens` | lijst `{id, verkregen_op, bron_knoop, nieuw}` |
| `knopen` | opgeloste knoop-ids |
| `gebeurtenissen` | per gebeurtenis van **alle scènes van het huidige hoofdstuk en `ch00_hub`** (niet alleen de huidige scène): status (`wacht`/`actief`/`voorbij`) en, bij `actief`, resterende seconden. Zo herstelt `voorbij` ook na een niet-lineaire sprong. |
| `apparaten` | per apparaat-id de toestand |
| `dialoog` | gekozen eenmalige keuzes (`dialoog_id.keuze_id`) |
| `hints` | per knoop het laatst getoonde niveau |
| `speeltijd_s` | totale speeltijd |
| `systemen` | object met een sleutel per later systeem (`voetsporen`, `kleding`, `ramen`, `apparaten_stroom`, `metro`), elk met eigen `versie`. Onbekende sleutels worden bewaard en genegeerd. |

Onbekende ids in een save (content is veranderd): overslaan met een waarschuwing in de log; de rest laadt.

**Na laden** (in deze volgorde):

1. **Controleren.** Ontbrekende sleutels of verkeerde types geven geen crash: het veld valt terug op de startwaarde, met een waarschuwing in de log. Onbekende apparaattoestanden worden overgeslagen (apparaat op zijn starttoestand).
2. **Plek controleren.** Is `hoofdstuk` onbekend: niet laden, melding (zoals bij SF-16). Is `scene` onbekend, of `kamer` onbekend of geen kamer van die scène: **terugval op de start van het hoofdstuk** (`chapter.start`: scène, kamer, uitgang), met een waarschuwing in de log (en in de ontwikkelbuild een melding op het scherm). Flags, tokens, knopen, objecten en de rest laden gewoon; objecten die in een onbekende kamer lagen, gaan naar hun beginplek.
3. **Gebeurtenissen herstellen** voor alle scènes uit de save (zie `gebeurtenissen`); gebeurtenissen die niet in de save staan krijgen `wacht`.
4. **Tijdelijke toestand resetten:** geen open gesprek, close-up of paneel; blokkades en pauze opgeheven; inventaris-UI `dicht`. `voltooid` wordt gezet op "het doel klopt nu"; daardoor vuurt `hoofdstuk_voltooid` niet nog eens voor een hoofdstuk dat al voltooid was.
5. **Signaal `spel_geladen`.** GameState zendt precies één keer `spel_geladen` uit, nadat alles hierboven klaar is. Alle UI en systemen die toestand tonen of afleiden (klok, inventarisstrook, kamer en NPC's, toegang, doorlopende audio-lagen) luisteren hiernaar en verversen zich volledig; ze roepen geen interne functies van elkaar aan.
6. Er vuren geen knopen bij het laden (ook geen `betreed`); de `automatisch`-rondes draaien niet. Een save is altijd geschreven na een afgeronde trigger (vuurregel 4a), dus er staat niets meer open.

## UX-flow

- De speler ziet flags en de graaf nooit. Hij merkt ze aan: een deur die nu wel opengaat, een gesprek met een nieuwe keuze, een regel "Genoteerd: …" onderin, een mompel als iets nog niet kan ("Ik weet de code nog niet.").
- Opslaan merkt hij alleen aan een klein icoon rechtsonder (een seconde) bij autosave, en aan het pauzemenu.
- Ontwikkelbuild: later een flagsvenster (F3, voorstel) met flags, tokens, opgeloste knopen en de hintknoop; niet in deze iteratie.

## Edge cases

- Knoop met `geef_object` voor een object dat al ergens is: verplaatst het (validator waarschuwt).
- Twee knopen met dezelfde trigger en allebei vervuld: alleen de eerste vuurt (regel 2); de validator waarschuwt bij identieke triggers zonder elkaar uitsluitende `vereist`.
- `automatisch`-knoop die zichzelf weer waar maakt en herhaalbaar is: kringgrens 32, fout.
- Token gegeven via twee verschillende knopen: tweede keer gebeurt niets (geen dubbele melding).
- Opslaan net nadat een gebeurtenis actief werd: bij laden loopt de resterende duur verder.
- Laden van een save uit een ouder hoofdstuk waarvan de content gewijzigd is: ontbrekende objecten komen op hun beginplek.
- `betreed`-knoop met `naar_scene` terwijl een onmisbaar object achterblijft in een kamer die wegvalt: Richard komt de kamer binnen, mompelt `systeem.niet_zonder`, verder gebeurt niets; na het ophalen en opnieuw binnenkomen vuurt de knoop alsnog.
- Gesprekskeuze die een knoop met `naar_scene` triggert terwijl de wissel geweigerd zou worden: de knoop vuurt niet, het gesprek gaat verder alsof de keuze geen knoop had (de keuze zelf blijft gekozen als die eenmalig is), en na het gesprek mompelt Richard `systeem.niet_zonder`. Content die dat wil voorkomen, zet de keuze achter een `als` op het object.
- Knoop van een ander hoofdstuk (niet de hub) met een trigger die ook in het huidige hoofdstuk voorkomt: wordt genegeerd.

## Acceptatiecriteria

| # | Criterium |
| --- | --- |
| SF-01 | Elke conditievorm uit de tabel heeft minstens één waar- en één onwaar-geval in een gedeelde testset (`tests/fixtures/condities.json`: toestand + conditie + verwacht). GUT en een Python-test draaien dezelfde set en geven identieke uitkomsten. |
| SF-02 | `{"alle": [...]}` met één onware deelconditie is onwaar; `{"een_van": [...]}` met één ware is waar; `{"niet": c}` keert om. |
| SF-03 | `heeft` vindt een object dat genest zit in inventaris → jas → portemonnee; `heeft` is onwaar voor hetzelfde object in een container in de kamer. |
| SF-04 | `kloktijd` van 23:00 tot 06:00 is waar om 00:07 en 23:00, onwaar om 06:00 en 22:59. |
| SF-05 | Een flag die nooit gezet is, geeft zijn startwaarde; `minstens`/`hoogstens`/`gelijk` werken op int-flags. |
| SF-06 | Een onbekende id in een conditie geeft onwaar en een foutregel in de log, geen crash. |
| SF-07 | Evalueren van een conditie verandert de toestand niet (toestand-hash voor en na gelijk). |
| SF-08 | Bij een trigger met twee knopen waarvan beide `vereist` kloppen, vuurt alleen de eerste in bestandsvolgorde. |
| SF-09 | Een niet-herhaalbare knoop vuurt maar één keer; tweede trigger toont de standaardreactie. |
| SF-10 | Trigger met onvervulde `vereist` toont `bij_onvervuld` en wijzigt niets. |
| SF-11 | Een `automatisch`-knoop vuurt direct nadat zijn `vereist` waar wordt; een kring stopt na 32 rondes met een fout. |
| SF-12 | `geef_token` voegt het token één keer toe met scènetijd en bron-knoop; nogmaals geven verandert niets. |
| SF-13 | Opslaan → laden geeft een toestand met dezelfde hash (objecten, flags, tokens, knopen, gebeurtenissen, apparaten, dialoog, hints). |
| SF-14 | Autosave wordt geschreven na elke kamerwissel en niet tijdens een gesprek. Bij een kamerwissel uit een effect pas nadat de hele trigger is afgehandeld (zie SF-21). |
| SF-15 | Een save met onbekende object- of flag-ids laadt, slaat die over en logt een waarschuwing. |
| SF-16 | Een save met een hogere `versie` dan het spel kent, laadt niet en toont een melding. |
| SF-17 | Lokale flag `ch01_x` gelezen in content van ch02 laat de validator falen. |
| SF-18 | De oplosser meldt voor de fixture: oplosbaar, de kortste oplossing en nul doodlopende staten; voor een kapotte fixture (onmisbaar object wordt verwijderd vóór gebruik) meldt hij een doodlopende staat met het pad ernaartoe. |
| SF-19 | Een knoop met `[zet_flag F, naar_scene S]` en trigger `betreed` (en apart: trigger `dialoog`) waarvan de wissel door O9 geweigerd zou worden: na de trigger is F niet gezet, de knoop niet opgelost, de scène ongewijzigd, en `systeem.niet_zonder` getoond. Na het ophalen van het object vuurt dezelfde trigger de knoop wel. Dezelfde fixture in de oplosser geeft hetzelfde gedrag (knoop vuurt pas na ophalen). |
| SF-20 | Met een `automatisch`-knoop in een ander hoofdstuk (niet de hub) waarvan `vereist` klopt: die knoop vuurt niet, in engine en oplosser. Een `automatisch`-knoop in `ch00_hub` waarvan `vereist` klopt, vuurt wel, in engine en oplosser. |
| SF-21 | Een knoop met `[naar_kamer X, zet_flag F]`: de autosave die daarna geschreven wordt, bevat F en de knoop als opgelost; laden van die save en opnieuw de trigger geven vuurt de knoop niet nog eens. Tijdens de effectenlijst wordt geen save geschreven (teller van saves = 1 na de trigger). |
| SF-22 | De afgeleide lijst onmisbare objecten voor de fixture is in GDScript en Python gelijk, en staat als verwachte waarde in de gedeelde testset; een object dat alleen in content van een ander hoofdstuk (niet de hub) voorkomt, staat er niet in. |
| SF-23 | Elke run van `solve.py` (tekst en `--json`) bevat het beperkingenblok: leg-limiet, niet gemodelleerd (`stop_in`, uitpakken, inventariscapaciteit), aanname gebeurtenisduur, verkende toestanden. Met `--leg-limiet 2` staat er 2. Wordt `--max-staten` bereikt, dan is de uitslag `onvolledig` en de exitcode niet 0. |
| SF-24 | Na laden zendt GameState precies één keer `spel_geladen`; de klok toont daarna de scènetijd uit de save, zonder dat iets anders een interne functie aanroept. Een hoofdstuk waarvan het doel al klopte, geeft na laden geen tweede `hoofdstuk_voltooid`. |
| SF-25 | Een gebeurtenis van een niet-huidige scène die `voorbij` was, is na opslaan en laden nog steeds `voorbij` (ook na een niet-lineaire sprong). |
| SF-26 | Een save met een onbekende `kamer` of `scene` laadt op de start van het hoofdstuk (`chapter.start`), met een waarschuwing in de log; flags, tokens en knopen uit de save zijn geladen. |
| SF-27 | Een save met een ontbrekende sleutel of een verkeerd type (bijv. `flags` is een lijst) crasht niet: het veld valt terug op de startwaarde met een waarschuwing. |
