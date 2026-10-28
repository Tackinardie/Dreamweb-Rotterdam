# Objecten en inventaris

**In één zin:** elk object bestaat precies één keer en ligt altijd op precies één plek (een kamer, een container of de inventaris), en de speler draagt wat in 8 slots plus zijn gedragen containers past.

Schema's: `tools/schemas/item.schema.json` (catalogus `content/items.json`), `tools/schemas/room.schema.json` (beginplek: `objecten` met geneste `inhoud`), `tools/schemas/chapter.schema.json` (`aanname_bij_start.inventaris`).

## Doel en pillar

- **Een fysieke wereld (2):** je pakt iets op, legt het neer, stopt het in iets anders, en het blijft daar. Een jas met een portemonnee met een pasje is één ding in je hand, met inhoud.
- **Sfeer (1):** de inventaris is een smalle strook onderin; het speelveld blijft vrij.

## Regels

**Objectmodel**

- O1. Elk object staat één keer in `content/items.json` met een globaal uniek id (snake_case, zonder `chNN_`-prefix). Er zijn geen kopieën: twee kopjes zijn `kopje_wit` en `kopje_blauw`.
- O2. Een object heeft altijd precies één **plek**: `inventaris`, een kamer-id (met positie), een container-id, of `nergens` (bestaat nog niet, of is opgegaan). De beginplek volgt uit de content: een plaatsing in een kamerbestand, `aanname_bij_start.inventaris`, of `nergens` als het object pas via `geef_object` ontstaat. Elk object heeft hoogstens één beginplaatsing (validator).
- O3. De plekken vormen een boom: kamer → kast → jas → portemonnee → pasje. Een object kan niet in zichzelf of in iets dat in hemzelf zit.
- O4. `grootte` 1–3 (alleen pakbare objecten). Een container heeft `capaciteit` (som van de groottes van de directe inhoud) en `max_grootte` (grootste object dat erin past). De inhoud van een container telt niet mee voor de grootte van de container: een volle jas is even groot als een lege.
- O5. Acties: `bekijk` (altijd), `pak` (alleen als `pakbaar`), `open` (alleen bij een container), `lees` (alleen met `leestekst`), `gebruik`. De validator controleert dat `acties` hiermee klopt.

**Inventaris**

- O6. De inventaris heeft 8 slots (`spel.json` → `inventaris_slots`). Objecten bovenin de inventaris kosten hun `grootte`; samen hoogstens 8. Gedragen containers geven extra ruimte via hun eigen capaciteit. Er is geen raster: de strook schuift aaneen, er ontstaan geen gaten.
- O7. **Pakken** (automatisch plaatsen): eerst in de vrije bovenste slots; past het daar niet, dan in de eerste gedragen container (strookvolgorde, van links naar rechts, diepte eerst) waar het in past (capaciteit en `max_grootte`). Past het nergens: het blijft liggen, mompel `systeem.inventaris.vol`, cue `ui.weiger`. Een container die je pakt, gaat mee met al zijn inhoud.
- O8. **Neerleggen** gebeurt waar de speler staat: het object komt op zijn tegel; ligt daar al iets, dan op de dichtstbijzijnde vrije beloopbare tegel binnen 1 tegel; is die er niet, dan lukt het niet (mompel `systeem.neerleggen.geen_plek`). Nooit in een muur, op een uitgang of op een NPC. Neergelegde objecten blijven liggen en worden per kamer bewaard. In kamers met `neerleggen: false` kan het niet (mompel `systeem.neerleggen.niet_hier`).
- O9. **Niets wordt onbereikbaar.** Een scènewissel die kamers onbereikbaar maakt (de nieuwe scène heeft die kamer niet in `kamers`), gaat niet door zolang er een onmisbaar object (zie state-en-flags.md) in zo'n kamer ligt, ook niet genest. Richard mompelt `systeem.niet_zonder` met de objectnaam ("Mijn {object} ligt er nog.") en de speler kan het gaan halen. Dit geldt voor elke weg naar een scènewissel: een uitgang met `naar_scene` en een knoop met een `naar_scene`-effect, bij **elke** triggersoort (ook `betreed` en `dialoog`). Bij een knoop wordt de controle gedaan vóór het eerste effect; wordt de wissel geweigerd, dan **vuurt de knoop niet**: geen enkel effect, niet opgelost (state-en-flags.md, vuurregel 2a). De speler kan het later opnieuw proberen. "Onmisbaar" wordt afgeleid uit content van het huidige hoofdstuk plus `ch00_hub` (state-en-flags.md). Daarnaast mag een knoop met een `naar_scene`-effect, bij welke trigger ook, volgens de validator geen kamers uit de huidige scène laten wegvallen (V17). De weigering hierboven is dan het vangnet in de engine voor content die de validator niet passeerde of voor saves van oudere content; bij `automatisch` en `gebeurtenis` zou de speler zonder V17 niet begrijpen waarom niets gebeurt. Een scènewissel die kamers laat wegvallen hoort op een uitgang (de speler kiest dan zelf het moment).
- O10. Overbrengen naar een container in de wereld: alleen naar een geopende container in de huidige kamer, met dezelfde capaciteitsregels.
- O11. Objecten in de inventaris tellen overal: `heeft` vindt ze op elke diepte.

**Kleding (vooruitblik, niet in deze iteratie).** Gedragen kleding (later een `kledingslot`) kost geen inventarisslots maar telt met zijn zakken wel als container. Tot het kledingsysteem bestaat, is een jas gewoon een object in de inventaris met grootte en zakken.

## Toestanden

Per object: plek (zie O2) + bij containers `open`/`dicht`. Een container zonder `open_vereist` geldt als dicht tot de speler hem opent (de inhoud is pas dan zichtbaar en pakbaar); daarna blijft hij open (bewaard). Een container met `open_vereist` opent alleen als die conditie klopt, anders `geweigerd` als mompel.

Inventaris als UI: `dicht` (alleen de strook) of `container_open` (boven de strook schuift een tweede strook met de inhoud van de gekozen container, met een kruimelpad "jas › portemonnee").

## UX-flow

| Speler doet | Wat er gebeurt | Cue |
| --- | --- | --- |
| Beweegt de muis over een object | naam bij de cursor; vergrootglas-detail in een hoek | — |
| Houdt spatie ingedrukt | alle interactieve objecten krijgen randlicht | `ui.highlight` |
| Linksklik op een object in de wereld | Richard loopt erheen en doet de `standaard_actie` (anders: pak > open > lees > gebruik > bekijk) | per actie |
| Rechtsklik op een object | Richard loopt niet; de beschrijving verschijnt | — |
| Pakt een object | object verdwijnt uit de kamer en schuift in de strook (of in een container, met een korte puls op die container) | `object.pak` |
| Opent een container (wereld) | paneel met de inhoud boven het object; inhoud sleepbaar naar de strook | `container.open` |
| Klikt op een container in de strook | tweede strook schuift open met inhoud en kruimelpad | `container.open` |
| Sleept een object uit de strook naar de vloer | Richard legt het neer op zijn eigen tegel (hij loopt niet) | `object.leg` |
| Sleept een object op een container (strook of wereld) | object gaat erin als het past; anders schudt de container kort | `object.in_container` / `ui.weiger` |
| Sleept een object op een wereldobject of NPC | trigger `gebruik X met Y` of `geef X aan NPC` | per knoop |
| Linksklik op een leesbaar object in de strook | leestekst in een paneel | `object.lees` |
| Rechtsklik in de strook | beschrijving | — |

Teksten zijn sober en kort; Richard mompelt alleen bij een weigering.

## Edge cases

- Container in zichzelf of in een eigen nakomeling slepen: weigeren (`ui.weiger`), geen mompel.
- Object groter dan `max_grootte`: weigeren met mompel `systeem.past_niet`.
- Container met inhoud neerleggen: de hele boom gaat mee naar de vloer.
- Een container (bijv. een tas van grootte 3) pakken terwijl de bovenste slots vol zijn: hij gaat alleen in een andere gedragen container als die genoeg capaciteit en `max_grootte` heeft; anders blijft hij liggen (regel O7).
- Object uitpakken uit een container in de inventaris terwijl de bovenste slots vol zijn: het gaat naar de eerstvolgende container waar het past, of blijft waar het zit.
- `geef_object` bij een volle inventaris: het object landt op de grond waar de speler staat (regel O8) en Richard mompelt `systeem.inventaris.vol`.
- Gesprek, close-up of titelkaart open: de strook is vergrendeld (geen slepen).
- Object dat via `verwijder_object` naar `nergens` gaat terwijl een container het toont: het verdwijnt uit het paneel.

## Acceptatiecriteria

| # | Criterium |
| --- | --- |
| OI-01 | Na het laden van de fixture heeft elk object precies één plek; de som klopt met het aantal objecten in `items.json`. |
| OI-02 | Pakken van een object van grootte 2 met 7 vrije slots lukt; met 1 vrij slot en geen passende container blijft het liggen en wordt `systeem.inventaris.vol` getoond. |
| OI-03 | Met een gedragen jas (capaciteit 2, `max_grootte` 1) en 0 vrije slots gaat een object van grootte 1 in de jas; een object van grootte 2 niet. |
| OI-04 | Een portemonnee met een pasje in een jas in de inventaris: `heeft pasje` is waar. Na neerleggen van de jas is `heeft pasje` onwaar en `ligt {pasje, in: <kamer>}` waar. |
| OI-05 | Een container in zichzelf of in een nakomeling stoppen faalt en verandert niets. |
| OI-06 | De som van de groottes van de directe inhoud van een container is nooit groter dan zijn capaciteit, na elke actie in een gerandomiseerde test van 1000 acties. |
| OI-07 | De inventaris bevat bovenin nooit meer dan 8 slots aan groottes, in dezelfde gerandomiseerde test. |
| OI-08 | Neerleggen plaatst het object op de tegel van de speler; is die bezet, op een vrije beloopbare buurtegel; anders faalt het. |
| OI-09 | Een neergelegd object ligt na verlaten en terugkomen van de kamer (en na opslaan en laden) op dezelfde positie. |
| OI-10 | Een scènewissel die kamer K onbereikbaar maakt, wordt geweigerd zolang een onmisbaar object (ook genest in een container) in K ligt; na ophalen gaat hij door. |
| OI-11 | Een container met `open_vereist` die niet klopt, gaat niet open en toont `geweigerd`; als de conditie klopt gaat hij open en blijft hij open na laden. |
| OI-12 | Elke actie roept de genoemde cue aan (of de override uit `geluid` van het object); het cue-logboek bevat ze. |
| OI-13 | De validator faalt als een object twee beginplaatsingen heeft, als een begininhoud niet past (capaciteit/`max_grootte`), of als `acties` niet klopt met pakbaar/container/leestekst. |
| OI-14 | Een knoop met `naar_scene` (getest met trigger `betreed`, `dialoog` en `gebruik`) waarvan de wissel kamer K laat wegvallen terwijl een onmisbaar object in K ligt: de knoop vuurt niet (geen effect, niet opgelost) en `systeem.niet_zonder` wordt getoond; na ophalen vuurt dezelfde trigger de knoop wel. |
