# Toegang

**In één zin:** elke deur, trap, lift, poort, hek of slagboom heeft per kant een `vereist`-regel in de gedeelde conditietaal, en wie voldoet, loopt door.

Schema's: `tools/schemas/room.schema.json` (`uitgangen`, `bestemmingen`, `npcs`), `tools/schemas/chapter.schema.json` (`gebouwen` met niveaus), `tools/schemas/item.schema.json` (`geeft_niveaus`, container `open_vereist`), `tools/schemas/spel.schema.json` (`condities`, o.a. `als_bezorger`), conditietaal in `tools/schemas/common.schema.json` (zie state-en-flags.md).

## Doel en pillar

- **Informatie is de sleutel (3):** de meeste regels vragen om een token (code, tijdstip) of een gebeurtenis die je ziet gebeuren, niet om een sleutel die ergens klaarligt.
- **Een fysieke wereld (2):** een pas moet je bij je hebben; van binnen gaat een deur meestal vrij open; een lift brengt je alleen waar je pas het toelaat.
- **Onzichtbaarheid (kernervaring):** met bezorgtas en jas ziet niemand je staan.

## Regels

**Uitgangen**

- T1. Een doorgang tussen twee kamers bestaat uit twee uitgangen, één in elke kamer, die naar elkaar verwijzen (`naar_kamer` + `naar_uitgang`). De validator controleert dat het paar wederzijds klopt.
- T2. Elke kant heeft een eigen `vereist`. Afwezig = vrij. Zo kan een personeelsdeur van buiten een pas vragen en van binnen vrij zijn, zoals in het echt.
- T3. `vereist` wordt geëvalueerd op het moment dat Richard **bij de uitgang aankomt**, niet bij het klikken. Klopt het dan niet, dan blijft hij staan en volgt `geweigerd` (mompel of beschrijving) met cue `deur.geweigerd` (of de override).
- T4. Een uitgang naar een kamer die niet in de huidige scène zit, is dicht met de standaardtekst `systeem.uitgang.niet_nu`. (Voorbeeld: de bar is in een latere scène gesloten.)
- T5. `naar_scene` op een uitgang: doorgaan kost tijd; de klok springt (zie klok-en-scenetijd.md). Regel O9 uit objecten-en-inventaris.md geldt.
- T6. Uitgangen zijn altijd tweerichting in de data. Een "eenrichtingsdeur" is een kant met een `vereist` die later niet meer klopt; de oplosser controleert dat dit geen doodlopende staat maakt.
- T7. Geen permanente "ontgrendeld"-toestand op deuren: de regel wordt elke keer opnieuw geëvalueerd. Wil content dat een deur na iets openblijft, dan zet een knoop een flag en vraagt de deur `een_van` die flag of de oorspronkelijke regel.

**Lift**

- T8. Een uitgang van type `lift` met `bestemmingen` opent bij aankomst een liftpaneel met een knop per bestemming (label = tekstsleutel). Knoppen waarvan `vereist` niet klopt zijn zichtbaar maar gedimd; klikken geeft `geweigerd` en cue `lift.geweigerd`. De knop van de huidige verdieping ontbreekt.
- T9. Kiezen van een bestemming: korte overgang (deuren dicht, cue `lift.rit`, deuren open) naar `naar_uitgang` in de doelkamer.

**Toegangsniveaus per gebouw**

- T10. Een hoofdstuk declareert `gebouwen` met `niveaus` (bijv. lobby, verdieping, dak, airside). Kamers hebben optioneel `gebouw` en `niveau`.
- T11. Een object (pas, badge) geeft niveaus via `geeft_niveaus: ["gebouw.niveau", …]` zolang de speler het heeft (op elke diepte in de inventaris). Conditie: `{"niveau": "gebouw.niveau"}`.
- T12. Niveaus zijn een verzameling, geen rangorde: een pas voor `dak` geeft niet automatisch `verdieping`. De passen zelf zeggen welke niveaus ze geven.
- T13. Validatorwaarschuwing (geen fout): een uitgang naar een kamer met een niveau, zonder dat in de `vereist` een `niveau`-, `token`- of `heeft`-atoom staat.

**Onzichtbaarheid als bezorger**

- T14. `spel.json` → `condities` → `als_bezorger` definieert wanneer Richard eruitziet als bezorger. In het fundament: `{"alle": [{"heeft": "<bezorgtas>"}, {"heeft": "<jas>"}]}` met de echte ids zodra de hub-content bestaat. Het kledingsysteem vervangt later `heeft` door `draagt` en kan plek en tijd toevoegen (rol is geloofwaardig als outfit, plek en tijd kloppen); alle content die `{"conditie": "als_bezorger"}` gebruikt, blijft dan ongewijzigd.
- T15. NPC's reageren op `als_bezorger` via hun `gesprekken` (eerste met kloppende `als`) en via de `vereist` van uitgangen waar een NPC de toegang bewaakt, bijv. `{"een_van": [{"conditie": "als_bezorger"}, {"niet": {"gebeurtenis": "ch01_beveiliger_op_post", "status": "actief"}}]}`.
- T16. Opvallen is nooit game-over. De gevolgen zijn content: een NPC spreekt je aan, stuurt je weg (knoop met `naar_kamer`), of de deur blijft dicht. Het kost tijd of een omweg.

**Containers met een slot**

- T17. Een container met `open_vereist` (kluisje, la met slot) volgt dezelfde regels als een uitgang: evaluatie bij aankomst, `geweigerd` als mompel; eenmaal geopend blijft hij open (anders dan deuren, omdat een geopende la open blijft staan).

## Toestanden

| Wat | Toestanden |
| --- | --- |
| Uitgang | geen eigen toestand; uitkomst `doorgang` of `geweigerd` per poging |
| Liftpaneel | dicht, open (knoppen beschikbaar/gedimd), rijdend |
| Container met slot | dicht, open (bewaard) |
| Richard | als bezorger of niet (afgeleid, nooit opgeslagen) |

## UX-flow

1. De speler klikt op een deur. Richard loopt erheen (cue `voetstap.*` per stap, later).
2. Bij aankomst: regel klopt → deur gaat open (cue `deur.open` of override), korte overgang naar de andere kamer, autosave.
3. Regel klopt niet → Richard blijft staan, de deur rammelt (cue `deur.geweigerd`), boven zijn hoofd staat de `geweigerd`-tekst, bijv. "Op slot. Er zit een codepaneel naast." De tekst wijst naar wat nodig is zonder de oplossing te geven.
4. Bij een NPC die de toegang bewaakt, is de weigering een korte zin van de NPC zelf (via een knoop met `bij_onvervuld` of een gesprek), niet van Richard.
5. Hover over een uitgang toont de naam (bijv. "Trappenhuis"); bij `vereist` dat niet klopt en dat de speler al eens geprobeerd heeft, een klein slotje bij de cursor.

## Edge cases

- De pas zit in een portemonnee in de jas in de tas: telt (`heeft` op elke diepte).
- De speler legt de pas neer aan de binnenkant van een deur die van binnen vrij is: hij kan eruit, maar niet meer terug zonder pas. De pas is onmisbaar; de oplosser vindt het als dit een doodlopende staat oplevert, en content lost dat op (bijv. de deur valt niet in het slot, of er is een tweede route).
- Gebeurtenis eindigt terwijl Richard naar de deur loopt: regel wordt bij aankomst geëvalueerd (T3), dus geweigerd.
- Gebeurtenis eindigt terwijl Richard in een bewaakte kamer staat: geen automatisch gevolg; content kan een knoop met trigger `{"gebeurtenis": …}` of `automatisch` gebruiken om de NPC te laten reageren.
- Lift met één bestemming: gewoon `naar_kamer`, geen paneel.
- Uitgang naar een hubkamer vanuit een hoofdstuk: toegestaan als de scène die kamer in `kamers` heeft.

## Acceptatiecriteria

| # | Criterium |
| --- | --- |
| TG-01 | Uitgang zonder `vereist`: Richard gaat door en staat in de doelkamer bij `naar_uitgang`. |
| TG-02 | Uitgang met `{"token": t}` zonder t: geweigerd, `geweigerd`-tekst getoond, cue `deur.geweigerd`, kamer onveranderd. Met t: doorgang. |
| TG-03 | Dezelfde doorgang met verschillende `vereist` per kant: van buiten geweigerd, van binnen vrij. |
| TG-04 | `vereist` met een gebeurtenis: geëvalueerd bij aankomst. Test: gebeurtenis actief bij klikken, voorbij bij aankomst → geweigerd. |
| TG-05 | Liftpaneel toont alle bestemmingen behalve de huidige; een bestemming waarvan `vereist` niet klopt is gedimd en weigert. |
| TG-06 | `{"niveau": "g.n"}` is waar met een pas met `geeft_niveaus: ["g.n"]` in de inventaris (ook genest) en onwaar zonder; een pas met alleen `g.m` geeft `g.n` niet. |
| TG-07 | `{"conditie": "als_bezorger"}` is waar met beide objecten in de inventaris en onwaar als één ontbreekt. |
| TG-08 | Een NPC kiest het eerste gesprek waarvan `als` klopt; met `als_bezorger` waar krijgt de speler een ander gesprek dan zonder. |
| TG-09 | Uitgang naar een kamer die niet in de huidige scène zit, weigert met `systeem.uitgang.niet_nu`. |
| TG-10 | De validator faalt bij een uitgang waarvan het tegenstuk (`naar_kamer`/`naar_uitgang`) niet bestaat of niet terugwijst. |
| TG-11 | Na een geslaagde doorgang wordt een autosave geschreven. |
