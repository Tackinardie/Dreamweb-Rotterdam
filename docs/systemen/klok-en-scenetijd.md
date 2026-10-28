# Klok en scènetijd

**In één zin:** elke scène heeft een vast tijdstip dat de klok toont en dat alle systemen lezen; de klok springt alleen bij een scènewissel, en wat er binnen een scène gebeurt, zijn gebeurtenissen.

Schema's: `tools/schemas/chapter.schema.json` (`scenes`, `gebeurtenissen`), `tools/schemas/spel.schema.json` (`startdatum`), `tools/schemas/common.schema.json` (`tijdstip`, `scenetijd`, condities `kloktijd`, `scenetijd`, `scene`, `gebeurtenis`; effecten `naar_scene`, `start_gebeurtenis`, `stop_gebeurtenis`), `tools/schemas/room.schema.json` (`naar_scene` op uitgangen).

## Doel en pillar

- **Sfeer (1):** de nacht ligt stil. De klok die blijft staan op 00:07 terwijl je rondkijkt, is de stilte van de stad.
- **Informatie is de sleutel (3):** timing-puzzels draaien om wat je ziet gebeuren (de beveiliger gaat pauzeren), niet om een tikkende klok.
- **Twijfel (4) en regie:** een tijdsprong is zichtbaar doordat de klok verspringt; bij de twee niet-lineaire momenten loopt hij zichtbaar terug.

## Regels

- K1. **Scènetijd** = `dag` + `tijd` (HH:MM). Dag 1 = `spel.json` → `startdatum` (de nieuwjaarsdag); de nacht van 1 op 2 januari loopt over in dag 2. Het spel begint in de eerste scène van het eerste hoofdstuk, net na middernacht op dag 1.
- K2. De klok staat stil. Er bestaat geen spelklok die tikt; alleen een scènewissel verandert de scènetijd.
- K3. **Een scène** is een tijdvak van een hoofdstuk: `id`, `tijd`, de `kamers` die dan bereikbaar zijn, optioneel `muziek`, `titelkaart` en `gebeurtenissen`. Een scène is niet hetzelfde als een kamer: in één scène loop je door meerdere kamers.
- K4. **Scènewissel** gebeurt door een effect `naar_scene` (knoop) of een uitgang met `naar_scene` (kamerwissel die tijd kost). Later ook door reizen (metro) en dromen; die gebruiken hetzelfde mechanisme.
- K5. **Vooruit:** de nieuwe scènetijd is later dan of gelijk aan de huidige. De validator controleert dit voor elke mogelijke wissel.
- K6. **Terug** mag alleen als de nieuwe of de huidige scène `niet_lineair` heeft (een moment-id). Over de hele game zijn er hoogstens twee verschillende moment-ids (Regiestijl, validator). Na het moment keert het verhaal met een gewone `naar_scene` terug naar het heden.
- K7. **Alle systemen lezen de scènetijd** via één functie op GameState; niemand leest de systeemklok van de computer. Nu: condities `kloktijd` en `scenetijd`, de klok-UI, de save. Later: licht door de ramen, dienstregeling van de metro, openingstijden, kerstresten per nacht, het tv-programma.
- K8. **Gebeurtenissen** lopen binnen een scène op speeltijd (seconden), niet op de klok:
  - `start`: `bij_begin` (actief bij het begin van de scène), `handmatig` (alleen via `start_gebeurtenis`), of `{"als": conditie}` (wordt actief zodra de conditie klopt, na `start_vertraging_s`).
  - `duur_s`: hoelang actief; zonder duur: tot `stop_gebeurtenis` of het einde van de scène.
  - `herhaal_na_s`: routine; na afloop weer `wacht`, en na zoveel seconden opnieuw actief.
  - Status: `wacht` → `actief` → `voorbij` (eenmalig) of terug naar `wacht` (herhalend).
  - Bij een scènewissel worden alle gebeurtenissen van de oude scène `voorbij`.
- K9. **Speeltijd** loopt door tijdens lopen, gesprekken, de inventaris en (later) de telefoon: de bom onder de tafel werkt alleen als de beveiliger terugkomt terwijl je praat. Speeltijd staat stil in het pauzemenu, op de titelkaart, tijdens de klokanimatie en tijdens een droomovergang.
- K10. Een gebeurtenis moet voor de speler zichtbaar of hoorbaar zijn (Wat de speler niet merkt, bestaat niet): elke gebeurtenis die in een `vereist` wordt gebruikt, heeft een `cue_start` of `cue_einde`, of een NPC wiens `aanwezig` ervan afhangt (validator).

## Klokweergave

- Formaat: `{weekdag} {dag} {maand} · {HH}:{MM}`, bijv. **wo 1 jan · 00:07**. Dag zonder voorloopnul, tijd met voorloopnullen, scheiding " · " (spatie, middenpunt U+00B7, spatie).
- Weekdag wordt berekend uit `startdatum` + (dag − 1). Afkortingen en maanden komen uit tekstsleutels: `klok.weekdag.ma` … `klok.weekdag.zo`, `klok.maand.jan` … `klok.maand.dec`, en het formaat zelf uit `klok.formaat` (zodat een andere taal de volgorde kan wisselen).
- Plaats: altijd in beeld, rechtsboven, klein, gedempte kleur, niet klikbaar. Ook tijdens gesprekken en in de inventaris.
- Droomkamers (`soort: droom`): de klok toont de scènetijd van de scène waarin de droom valt. De droomspec mag dit later anders bepalen (zie open vraag in het eindrapport).

## Toestanden

| Klok-UI | Wanneer |
| --- | --- |
| stil | normaal |
| springt vooruit | scènewissel naar een latere tijd: de cijfers rollen in ongeveer 1 seconde naar de nieuwe tijd (de datum mee als die verandert); cue `ui.klok.vooruit` |
| springt terug | scènewissel van/naar een niet-lineair moment: de cijfers rollen zichtbaar terug, iets langzamer (ongeveer 1,5 seconde); cue `ui.klok.terug` |
| onveranderd | scènewissel met dezelfde tijd: geen animatie |

## UX-flow

1. De speler opent het spel: titelkaart, daarna de kamer; rechtsboven staat **wo 1 jan · 00:07** (met de startdatum uit `spel.json`).
2. Hij verkent; de klok beweegt niet. Buiten (later) knalt het vuurwerk, maar de minuten blijven staan.
3. Hij gaat door een uitgang met `naar_scene` (bijv. "naar buiten, de fiets op"): de overgang speelt, de klok rolt naar de nieuwe tijd, de nieuwe kamer verschijnt.
4. In een scène met een gebeurtenis ziet hij die gebeuren (de beveiliger staat op en loopt weg; de `cue_start` van de gebeurtenis klinkt, bijv. een stoel die over de vloer schuift). Hij weet dat hij nu een venster heeft, zonder minuten.

## Edge cases

- Twee scènes met dezelfde tijd (een kamerwissel die geen tijd kost maar wel andere kamers opent): toegestaan, geen animatie.
- Een gebeurtenis die nog `actief` is bij opslaan: resterende duur wordt bewaard en loopt na laden door (zie state-en-flags.md).
- Een `{"als": …}`-start die al klopt bij het begin van de scène: gebeurtenis wordt direct (na vertraging) actief.
- `stop_gebeurtenis` op een gebeurtenis die `wacht`: wordt `voorbij` (eenmalig) of blijft `wacht` met de herhaaltimer opnieuw gestart (herhalend).
- Dag over het einde van januari (geen voorkomend geval): de validator beperkt scènetijd tot dag 1–14.
- Een kloktijdconditie over middernacht (`23:00`–`06:00`) en een scène op dag 2 om 00:30: waar.

## Acceptatiecriteria

| # | Criterium |
| --- | --- |
| KS-01 | Met `startdatum` 2025-01-01 en scènetijd dag 1, 00:07 toont de klok exact `wo 1 jan · 00:07`. Met dag 7, 06:45: `di 7 jan · 06:45`. |
| KS-02 | Met `startdatum` 2027-01-01 en dag 1, 00:07: `vr 1 jan · 00:07` (weekdag wordt berekend, niet opgeslagen). |
| KS-03 | Zonder scènewissel blijft de klokstring na 120 seconden speeltijd onveranderd. |
| KS-04 | `naar_scene` naar een latere scène zet de scènetijd, start de vooruit-animatie en roept `ui.klok.vooruit` aan. |
| KS-05 | `naar_scene` naar een vroegere scène zonder `niet_lineair` wordt door de validator afgekeurd; met `niet_lineair` speelt de terug-animatie en `ui.klok.terug`. |
| KS-06 | De validator faalt als er in alle hoofdstukken samen meer dan twee verschillende `niet_lineair`-moment-ids zijn. |
| KS-07 | Een gebeurtenis met `start: bij_begin` en `duur_s: 10` is actief bij het begin van de scène en `voorbij` na 10 s speeltijd; met `herhaal_na_s: 5` is ze na 15 s weer actief. |
| KS-08 | Speeltijd staat stil in het pauzemenu: een gebeurtenis van 10 s die 5 s gepauzeerd is, eindigt na 10 s lopende speeltijd, niet na 5. |
| KS-09 | Bij een scènewissel zijn alle gebeurtenissen van de vorige scène `voorbij`. |
| KS-10 | Geen enkel script buiten de kloklaag leest `Time`/`OS`-tijd voor spellogica (code-review en een grep-test in tests/). |
| KS-11 | De validator faalt als een gebeurtenis in een `vereist` wordt gebruikt zonder `cue_start`, `cue_einde` of een NPC wiens `aanwezig` ervan afhangt. |
