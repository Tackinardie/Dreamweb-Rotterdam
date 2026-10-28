# Stijlgids Onderstad — v1.1

*v1.1 (2026-10-28): open punten van Martijn verwerkt. Bringbroh fel oranje in plaats van pistache; droomrood in de bovenstad vaste regel; MaasLijn en Havenlicht vormgegeven; Zadkine en Markthal-plafond herkenbaar toegestaan; overal smalle FOV; referentielaptop Iris Xe; geen webversie; personages, close-ups en groot water vastgelegd; gebakken licht blijft open.*

Beheer: art-director · Bron: `docs/GDD.md` (Art direction en audio, Setting en thema, Interface) · Maatstaf: de stijltest in `proto/stijltest/` (issue #32)

Deze gids is de werkinstructie voor de asset-pipeline (low-poly 3D in Godot, modellen uit Blender of Godot-primitieven) en de toetssteen voor elke art-review. Bij strijd met het GDD wint het GDD; de art-director meldt het verschil en past de gids aan.

**Richting (besluit Martijn):** low-poly 3D met vlakke kleuren, geen texturen, sterk realtime licht, Godot 3D (Forward+), vaste schuine camera van bovenaf. Aantrekkelijk zonder complex te ogen. Pixelart vervalt.

## 1. Uitgangspunt

- **Sfeer (pillar 1).** Elk beeld is een klein verlicht eiland in een donker, nat Rotterdam. Licht vertelt waar je moet kijken; de rest zakt weg. Het kernbeeld van de bovenstad is de Coolsingel in de regen bij nacht: nat asfalt, rode achterlichten in plassen, kale bomen met achtergebleven kerstlampjes, een stad die leeg is behalve voor wie bezorgt.
- **Eenvoud in vorm, rijkdom in licht.** De modellen zijn simpel: blokken, cilinders, vlakke kleur. Alles wat leeft komt uit licht, glow, mist, reflectie en regen. Wordt een beeld saai, voeg dan eerst licht of reflectie toe, pas daarna geometrie.
- **Twijfel (pillar 4).** Bovenstad en onderstad zijn visueel streng gescheiden (koud blauw en natrium tegenover sepia met één rood). Juist daardoor valt het op als er iets lekt: een rood dat er niet hoort, een schaduw die te lang is. Zulke lekken zijn regie, nooit toeval (zie 2.3).
- **Ingetogen, niet arm.** De beklemming komt uit de kadrering, niet uit lege kamers (GDD, Kadrering en detail). Vol in het licht, leeg in het donker.

## 2. Palet

Het palet bepaalt de **albedo** van materialen en de **kleur van lichten**. Er wordt niet gekwantiseerd: Godot-licht kleurt het beeld verder, het palet bewaakt de basis. Elke albedo in een model komt uit deze tabellen; de pipeline maakt er gedeelde materialen van in `game/assets/materialen/` (zie 4).

### 2.1 Bovenstad (Rotterdam nu)

| Rol | Hex (donker → licht) | Gebruik |
| --- | --- | --- |
| Kader / leegte | `#07080C` | Achtergrondkleur, vignet-eindkleur, alles buiten het eiland |
| Diepe schaduw | `#0E1220` `#151B2C` | Hoeken, onder meubels, voorgrond-silhouetten |
| Nacht-ambient (koud blauw) | `#1F2A44` `#2A3A5C` `#3E5578` `#5A7398` | Muren en vloeren buiten de lichtplas; ambient-licht `#4A6590` |
| Lucht blauw uur | `#1C2A5E` `#2B3F7A` `#4A5FA0` | Alleen schemer (zie 5.4) |
| Lucht bewolkte nacht | `#1A1620` `#2A2230` `#3C2E36` | Stadsgloed tegen laaghangende bewolking: vuil paars-oranje, geen sterren. Ook de reflectielucht buiten (zie 6.3) |
| Nat asfalt | `#14171E` `#1E232C` `#2E3540` `#46505E` | Straat; nat via roughness, niet via kleur |
| Natriumlicht | `#5A2A10` `#8A3E14` `#C8601E` `#F08A30` `#FFB866` | Straatlantaarns, kade, bouwplaats; lichtkleur `#F08A30`, lampkern `#FFB866` |
| Warm lamplicht binnen | `#4A3020` `#6E4528` `#A8703E` `#D89A5A` `#FFD8A0` | Bureaulamp, sfeerlamp, bar; lichtkleur `#FFD8A0` |
| Tl / koel kunstlicht | `#A8B8B4` `#D6E2DC` `#F0F6F0` | Ziekenhuis, kantine, perron, parkeergarage |
| Neon-accent magenta | `#5C1440` `#A0246E` `#FF3EA5` | Alleen lichtbronnen en hun reflectie |
| Neon-accent cyaan | `#124450` `#1E7A8C` `#3EE6FF` | Alleen lichtbronnen en hun reflectie |
| Kerstlampjes buiten (LED) | `#C8D8F0` `#EEF4FF` | Bomen op straat, gevels (koel wit, zoals de Coolsingel) |
| Kerstlampjes binnen | `#E8B868` `#FFE2A8` | Snoer langs het raam, bar; hooguit één oud gekleurd snoer (`#D04A32` `#5FB860` `#E8C040`) |
| Bovenstad-rood | `#6A2018` `#A8382A` `#D04A32` | Achterlichten, rood-wit van de club, Crispy & Co, vuurwerkresten. Warm, oranje-getint |
| Huid (drie ladders) | `#5A3A2C` `#8A5A40` `#B88462` · `#3A241C` `#5E3A2A` `#86563C` · `#7A5A48` `#B08868` `#D8B494` | Personages; in nachtlicht geen extra verzadiging |
| Interactief-highlight | `#F4F1E6` | Contour van interactieve objecten en spatiebalk-markering. Gereserveerd: geen decor in deze kleur |
| Bringbroh-oranje (signaal) | `#6E2A06` `#A63F08` `#D9520B` | Alleen Bringbroh: tas, schouderpas van de jas, app, fietsbord. Albedo, nooit lichtkleur. Gereserveerd: zie 2.3 |
| UI | paneel `#0B0D14` (85 % dekking) · tekst `#D8D4C8` · tekst 2 `#8A8F9C` · selectie `#F08A30` · rand `#2A3040` | Klok, inventarisstrook, telefoon-chrome, notitieboek |

### 2.2 Onderstad (vooroorlogs Rotterdam, droom)

| Rol | Hex | Gebruik |
| --- | --- | --- |
| Kader / leegte | `#0C0B0A` | Buiten het eiland; in de onderstad ook gaten in de wereld |
| Sepia-grijs ladder | `#1C1916` `#2E2924` `#4A4239` `#6E6355` `#978A76` `#C2B49C` `#E6DCC8` | Alles: gevels, klinkers, water, figuren, ook de lichtkleur |
| Het rood | `#4E0812` `#A01028` | Eén ding per scène (zie regels) |
| Interactief-highlight | `#F4F1E6` | Zelfde als bovenstad: de speler moet de taal herkennen |

**Verwrongen, volgens het GDD**, maar met dezelfde camera en hetzelfde raster (leesbaarheid blijft):
- Geometrie licht scheef: gevels 2–6° uit het lood, deuren te hoog, ramen op de verkeerde hoogte, een straat die te lang doorloopt.
- Ontbrekende stukken: gebouwen die per hoofdstuk verdwijnen of terugkomen (droomsysteem-lagen), randen die overgaan in kader-zwart.
- Filter in Godot als nabewerking: desaturatie naar de sepialadder (behalve het rood), fijne korrel 6–10 % dekking die niet sneller verspringt dan 4 keer per seconde. Geen regen-particles in de onderstad; wel stilstaande waterdruppels in de lucht als dat de scène vraagt.
- Geen hedendaagse objecten, geen neon, geen schermen. Licht komt van gaslantaarns (kleine warme sepia-plas) en van een diffuus, richtingloos schijnsel; geen glow behalve op het rood.

**Referenties (werkwijze).** De locatie-onderzoeker selecteert 10 à 15 vooroorlogse foto's van Rotterdam uit het Stadsarchief (straatbeeld, gevels, kades, licht bij avond), met per beeld vindplaats, inventarisnummer en gebruiksvoorwaarden. Martijn kiest daaruit de basis. Die beelden zijn sfeer- en vormbron: we modelleren gevelritme, maat en licht, nooit de foto zelf. Art-briefs voor de onderstad verwijzen naar de gekozen beelden.

### 2.3 Regels voor accentkleur

| Kleur | Mag | Mag niet |
| --- | --- | --- |
| Neon magenta/cyaan | Lichtbronnen (neonbuis, reclamebord, scherm), hun licht en hun reflectie in plassen, glas, nat asfalt | Albedo van kleding, meubels, merken, UI |
| Natrium | Buitenlampen, hun lichtplas en reflectie | Binnenverlichting (dat is warm lamplicht) |
| Onderstad-rood `#A01028` | In de onderstad: precies één element per scène (wat de droom hem wil laten zien), plus de reflectie daarvan | Meer dan één element; in de UI |
| Onderstad-rood in de bovenstad (vaste regel, GDD Art direction) | Hooguit één keer per hoofdstuk, als bewust twijfelsignaal (pillar 4); plek en moment vastgelegd in de levelbrief en de art-brief | Als gewoon decor; vaker dan één keer per hoofdstuk; zonder vermelding in de levelbrief. Elk gewoon rood in de bovenstad gebruikt de bovenstad-ladder |
| Interactief-highlight | Contour, spatiebalk-markering | Alles anders |
| Bringbroh-oranje | Bringbroh-tas, schouderpas van de Bringbroh-jas, app-scherm, fietsbord of sticker van Bringbroh | Ander decor of kleding; als lichtkleur. Geen enkel ander groot vlak (> 20 cm) in verzadigd oranje (HSV-tint 15–35°, verzadiging > 60 %) in de bovenstad, zodat de tas het enige oranje vlak blijft. Uitgezonderd: lichtbronnen en hun licht, kleine merkdetails (< 20 cm). Baksteenrood van Crispy & Co (tint 12°) en het bovenstad-rood (tint 7–9°) vallen erbuiten |
| Verzadiging albedo decor | HSV-verzadiging ≤ 40 % | — |
| Verzadiging albedo interactieve objecten | ≤ 60 % | Feller dan lichtbronnen |
| Verzadiging signaalkleuren | Tot 95 %: alleen Bringbroh-oranje en het fluorgele hesje van de bouwvakker (8.2) | Op iets anders dan die twee rollen |
| Verzadiging lichtbronnen | tot 100 % | — |

**Waardeopbouw** (helderheid, gemeten op het 1080p-screenshot): kader 0–5 %, schaduwzone 5–20 %, lichtplas 35–75 %, lichtbron zelf 85–100 %. Niets buiten een lichtplas komt boven 30 %. Geen interactief object en geen looproute onder 15 %.

## 3. Camera, schaal en vorm

### 3.1 Camera

| Onderwerp | Waarde |
| --- | --- |
| Projectie | Perspectief met smalle FOV, 15–20° (verticaal), vanaf grote afstand |
| Kanteling (pitch) | 38° omlaag, ±3° per locatie |
| Draaiing (yaw) | 20–35° om de verticale as; vast per locatie, zodat kamers in één locatie dezelfde blik hebben |
| Afstand | Zo dat Richard minstens 80 px hoog is op 1080p (buiten) en 140–200 px in kamers |
| Eiland in beeld | Hooguit 60 % van de beeldbreedte en 70 % van de hoogte; minstens 8 % kader rondom |
| Beweging | Vast per kamer. Alleen buitenruimtes die groter zijn dan het eiland schuiven traag mee met Richard (zelfde hoek, geen zoom, geen rotatie) |
| Clipping | `near` 0,5 m, `far` zo kort als de scène toelaat |

**Vaste regel: overal smalle FOV (besluit Martijn).** Elke spelscène, buiten en binnen, gebruikt perspectief met smalle FOV volgens de tabel hierboven. Geen orthografische camera in kamers. Reden uit de stijltest: orthografisch leest als diorama en vulde in de kamertest het hele scherm (`b_kamer.png`: geen kader onderaan); de smalle FOV geeft de straat diepte (`a_straat_perspectief.png`) en toont de kamer als verlicht doosje in het donker (`b_kamer_perspectief.png`), precies het eiland-in-kader uit het GDD. Orthografisch mag alleen in UI-vensters met 3D-inhoud (de metrokaart is 2D).

**Doorsnede.** De camera kijkt van de voorkant in de kamer. Voorwanden en de zijwand dichtbij de camera zijn weggesneden tot een lage donkere rand (0,3–0,5 m, kleur diepe schaduw), zodat je ziet waar de kamer ophoudt. De achterwand en de verre zijwand staan volledig; daar mag een Rotterdam-element hangen.

**Ramen.** Door de hoge camerahoek zie je door een raam alleen wat lager ligt dan de kamer. De buitenwereld (daken, stadsgloed, vuurwerk) staat in een eigen groep die op de kijkas door het raam wordt geplaatst, zoals in de stijltest (`build_outside`). Bij een vaste camera per kamer is dat één keer goed zetten.

### 3.2 Schaal

| Onderwerp | Waarde |
| --- | --- |
| Eenheid | 1 unit = 1 m. Oorsprong van elk model op de grond in het midden (voetpunt), +Y omhoog |
| Tile | Vak van 1×1 m in de content: looproutes, collision, plaatsing. Objecten staan vrij binnen een vak |
| Richtmaten | Plafond binnen 2,6 m · deur 0,9 × 2,1 m · bureau 0,75 m hoog · stoeprand 0,12 m · lantaarnpaal 5–6 m · Richard 1,80 m |
| Kamer, richtwaarde | 4×5 tot 10×8 m vloer |
| Maximale eilandgrootte | 24×14 m voor open lege ruimtes (containerterrein, platform) |
| Kleinste interactieve object | Minstens 16×16 px op 1080p. Een klein ding (sleutel, pasje) mag daarvoor tot 1,5× ware grootte, en ligt op een vlak dat er in tint van verschilt |
| Vergrootglas (hover) | Tweede camera (SubViewport) op het object, 2,5× vergroot, venster 256×256 px in een hoek; zelfde licht, zelfde materialen |
| Close-up panelen | 3D-close-up (besluit Martijn): een tweede camera op de echte scène, met een detailversie van het object (meer segmenten, afgeschuinde randen, kleine onderdelen zoals knoppen, schroeven, tekst op een scherm) die alleen in de close-up zichtbaar is. Zelfde palet, gedeelde materialen en vormtaal; eigen sleutellicht toegestaan, in de kleur van het licht in de kamer. Maximaal 1920×1080. Handen en ogen (GDD, Regiestijl) krijgen in de close-up een eigen detailmodel, nog steeds low-poly en vlak gekleurd, zonder fotorealisme. Sleutelobjecten blijven kandidaat voor handwerk |
| Metrokaart (UI) | Eigen schematische kaart, 2D, op een raster van 24 px bij 1080p; alleen 0°, 45° en 90°; lijndikte 8 px; stations als open rondjes van 16 px; overstappen als langgerekt rondje; echte lijnkleuren (door de locatie-onderzoeker te bevestigen), iets ontzadigd naar het palet; geen logo, lettertype of kaartontwerp van de vervoerder |

### 3.3 Vormtaal en poly-budget

- **Eerst silhouet.** Een object moet als zwarte vorm herkenbaar zijn. Lukt dat niet, verander de vorm, niet de kleur.
- **Rechte vlakken, harde randen.** Architectuur, meubels en apparaten krijgen flat shading per vlak. Geen subdivision, geen sculpt, geen gladde organische vormen behalve bij personages.
- **Afschuinen alleen waar licht valt.** Een afgeschuinde rand (1 segment, 1–3 cm) vangt een lichtlijn en maakt een object rijk zonder detail. Alleen op objecten in een lichtplas en op interactieve objecten; decor in de schaduw blijft een kale doos.
- **Rond is weinig rond.** Lampen, blikjes, palen: 8–12 segmenten. Takken en kabels: 5–6. Bollen: 16×8 alleen als ze groot in beeld staan.
- **Geen micro-detail.** Niets kleiner dan 5 cm, behalve interactieve objecten en lichtpunten (kerstlampjes). In de schaduw niets kleiner dan 20 cm.
- **Samenvoegen.** Statische kleine dingen van één materiaal (takken van één boom, boeken op een plank, kapsalonresten) worden één mesh. De straattest had circa 600 losse meshes; doel is hooguit 300 per scène.

| Soort | Budget (driehoeken) |
| --- | --- |
| Klein object (blikje, telefoon, boek) | 12–150 |
| Meubel, apparaat | 50–800 |
| Personage inclusief kleding | 1500–3000 |
| Boom (met takken, samengevoegd) | 500–1500 |
| Gevel per 10 m | 500–2000 |
| Kamer totaal | ≤ 60 000 |
| Buitenscène totaal | ≤ 200 000 |

## 4. Materialen

**Geen texturen.** Elk materiaal is een `StandardMaterial3D` met een vlakke albedo uit het palet. Uitzonderingen, allemaal klein en in het palet, nooit een foto:
- **Decal-maskers**: alleen vorm (alfa), kleur via modulate uit het palet; eventueel een roughness-masker voor natte voetsporen.
- **Beeldvlakken**: affiches, schermen, kaarten, borden, merklabels. Vlakke kleurvlakken en eigen tekst, opgebouwd uit dezelfde vormtaal.

**Gedeelde materialen.** Per paletkleur en oppervlak één materiaal in `game/assets/materialen/` (bijvoorbeeld `asfalt_nat_2`, `hout_bureau_3`). Modellen maken geen eigen materialen. Dat houdt het beeld consistent en spaart draw calls.

**Variatie zonder textuur.** Per vlak (vertex color) of per object een tint ±1 ladderstap; grote vlakken (vloer, gevel) bestaan uit meerdere vlakken in 2–4 tinten. Grote buitenvloeren mogen de gedeelde vloer-shader gebruiken: ruis in wereldcoördinaten, afgerond naar de ladder, schaal 1–3 m, nooit een herhaling die op 1080p zichtbaar is.

| Oppervlak | Roughness | Metallic | Opmerking |
| --- | --- | --- | --- |
| Stof, tapijt, bed, kleding | 0,9–1,0 | 0 | |
| Muur, pleister, droog beton, droge steen | 0,8–0,9 | 0 | |
| Hout, laminaat, linoleum | 0,6–0,75 | 0 | Looppad 0,1 lager (gepoetst door gebruik) |
| Gelakt, kunststof, apparaatbehuizing | 0,4–0,6 | 0 | |
| Metaal (paal, leuning, lampkap) | 0,35–0,5 | 0,7–1,0 | Spaarzaam: metaal toont vooral wat het spiegelt |
| Reflecterende strook (kleding, tas) | 0,3 | 0 | Albedo `#C9C2AE`; vangt licht, nooit emissief |
| Glas | 0,05 | 0 | Alfa 0,15–0,3; ruit buiten met regenstrepen als losse geometrie |
| Nat asfalt, natte klinkers | 0,15–0,3 | 0 | Albedo één ladderstap donkerder dan droog |
| Natte gevelvoet | 0,4–0,5 | 0 | Onderste 0,3–0,5 m, één stap donkerder |
| Plas, natte voetstap | 0,02–0,05 | 0 | Zie 6.3 |
| Groot water (Maas, haven, gracht) | 0,02–0,08 | 0 | Zie 6.4 |
| Lichtbron (lampkern, kerstlampje, neon) | — | — | Emissief, energie 4–12: komt boven de glow-drempel |
| Scherm (laptop, tv, telefoon) | 0,2 | 0 | Emissief, energie 1,5–3: gloeit zacht maar inhoud blijft leesbaar |

**Emissie alleen voor lichtbronnen.** Niets anders is emissief, ook geen interactief object of highlight. Alleen emissieve oppervlakken mogen boven de glow-drempel (HDR 1,0) komen; een belicht vlak dat gaat gloeien is te fel belicht of te licht van albedo (albedo hooguit `#E6E1D3`, behalve highlight-wit).

## 5. Belichting

### 5.1 Opbouw per kamer

Elke kamer wordt in deze volgorde belicht. Pas een laag pas aan als de laag eronder klopt.

| Laag | Wat | Waarden (richtwaarde) |
| --- | --- | --- |
| 1. Ambient | Kleine koude ambient, kleur uit de omgeving | `#4A6590`, energie 1,6–2,2 buiten, 1,4–1,8 binnen. Laag genoeg dat de schaduwzone onder 20 % blijft |
| 2. Maanlicht | Zwak richtingslicht zonder schaduw, zodat vormen leesbaar blijven | Koud blauw, energie 0,1–0,3 |
| 3. Sleutellicht | Eén bron die het eiland maakt, met schaduw | Bureaulamp, lantaarn, tl-armatuur |
| 4. Eilanden | 1–3 lichtplassen in totaal, inclusief het sleutellicht. Minstens één zwak eiland aan de donkere kant van de kamer | Raamlicht op de vloer, schermlicht, gangpad, licht onder een deur |
| 5. Randlicht Richard | Volglicht alleen op Richard (zie 8.1) | Koel wit `#C8D8F0`, energie 0,6–1,2 |
| 6. Levende bronnen | Schermen, neon, kerstlampjes, telefoon (GDD, Levende lichtbronnen) | Hooguit 6 per kamer, eigen seed |

- **Lichtbudget.** Hooguit 16 lichten in beeld; hooguit 6 met schaduw (lichte stand 3). Kerstlampjes krijgen geen licht per lampje: één zwakke OmniLight per snoer.
- **Donkere kant (les uit de test: bed en fietskaart onzichtbaar).** Elke zone met een interactief object of een looproute haalt minstens 15 % helderheid. Haalt het de ambient niet, dan komt er een klein eiland (raamlicht, schermgloed, standby-lampje met een zwakke OmniLight), niet meer ambient.
- **Raamlicht (les uit de test: nauwelijks zichtbaar).** Licht dat door een raam valt is een SpotLight buiten het raam met schaduw, zodat het kozijn als vorm op de vloer of muur valt. De plas haalt 35–50 % helderheid. Het raamlicht heeft de kleur van buiten (natrium, stadsgloed of koplamp).

### 5.2 Kadrering

- Achtergrond egaal `#07080C`. Vignet als CanvasLayer naar `#07080C` (in de test: sterkte 0,9, binnen 0,28, buiten 0,82). Het vignet raakt nooit een interactief object.
- Buiten het eiland wordt niets gemodelleerd, of het valt weg onder 5 %. Buitenscènes eindigen in donker: de straat loopt het kader in, niet tegen een rand.
- Elke kamer heeft minstens één voorgrondlaag als echte geometrie tussen camera en kamer (dakrand, leiding, gordijn, stelling, bovenleiding): diepe schaduwtinten, zonder schaduw te werpen, hooguit een randje licht van de dichtstbijzijnde bron. Voorgrond dekt nooit een interactief object of de looproute af.
- Detaildichtheid volgt het licht: in de plas kleine objecten, afgeschuinde randen en de tweede tint; in de schaduw grote vlakken in één of twee tinten.

### 5.3 Lichtsoorten

| Bron | Kleur | Godot en gedrag |
| --- | --- | --- |
| Natrium (straat, kade) | `#F08A30` | SpotLight met schaduw, kegel 50–70°, bereik 8–12 m, plas 4–6 m doorsnee met harde kern en zachte rand. Lampkop volledig emissief (de onderkant zie je niet). Altijd met reflectiestreep in het natte oppervlak en een zichtbare lichtkegel (5.5) |
| Warm lamplicht | `#FFD8A0` | SpotLight of OmniLight, plas 2–4 m; dimbaar waar het GDD dat toestaat |
| Tl | `#F0F6F0` | Rechthoekig, gelijkmatig (SpotLight met brede kegel of meerdere zwakke); knippert 2–4 keer bij aanspringen |
| Tv | per profiel (GDD) | OmniLight voor het scherm; cuts om de 2–8 s, eigen seed per scherm |
| Monitor, laptop | `#9FC8E8` koel | Kleine SpotLight naar het gezicht en het bureau; rustig, kleine verschuivingen bij vensterwissel |
| Telefoon | `#C8DCF0` | Zwakke OmniLight, straal 1–2 m: gezicht en handen; korte flits bij melding |
| Neon | magenta of cyaan | Emissieve buis plus OmniLight; stabiel, af en toe hapering; hooguit één neonbron per binnenkamer |
| Kerstlampjes | zie palet | Emissieve bolletjes van 2–3 cm, onderling verschoven flikkering; samen hooguit één zwakke plas |
| Koplampen (raamgebeurtenis) | `#EEF4FF` | Bewegende SpotLight: strijkende band over muur en plafond, alleen volgens de raamregels |
| Vuurwerk | neon- en kerstladders | Flits: OmniLight 0,1–0,2 s, ver weg en zwak; binnen alleen via het raam |

Twee schermen in één kamer lopen nooit synchroon.

### 5.4 Licht per scènetijd

Per scènetijd een omgevingsinstelling (ambient, mist, reflectielucht).

| Scènetijd | Lucht en ramen | Ambient | Lampen |
| --- | --- | --- | --- |
| Schemer (ca. 16:45–17:45 in januari) | Blauw uur `#2B3F7A` | Nacht-ambient + blauwe lucht, energie hoger | Straatlampen aan, etalages deels aan, rolluiken dicht |
| Avond en nacht (18:00–06:30) | Bewolkte nacht `#2A2230`; bij open hemel donker `#0E1220` | Nacht-ambient | Natrium, schermen; ramen van overburen gaan uit naarmate het later wordt |
| Ochtendschemer (ca. 07:30–08:45) | Van `#1C2A5E` naar grijsblauw `#5A7398` | Wordt per scène lichter | Straatlampen nog aan, gaan rond zonsopgang uit |
| Zonsopgang finale (7 jan, ca. 08:45) | Lage, koude zon: horizon `#E8A060` → `#F4D8B0` | Eerste en enige keer een richtingslicht met lange warme schaduwen van opzij | Platformverlichting valt weg tegen daglicht |

Tijden zijn richtwaarden voor Rotterdam in de eerste week van januari; de locatie-onderzoeker bevestigt ze.

### 5.5 Zichtbare lichtkegels

Les uit de test: met alleen globale mist zijn de kegels onzichtbaar, en meer mist maakt het hele beeld grauw.
- Globale volumetrische mist laag houden: dichtheid 0,006–0,012 buiten, 0,015–0,02 binnen.
- **Volle stand:** per lantaarn (en per sterk raamlicht) een lokaal FogVolume in de vorm van de kegel, dichtheid 0,04–0,08. Kegel 10–25 % lichter dan de omgeving op het screenshot, nooit tot de grond als witte vlek.
- **Lichte stand:** een nepkegel: additieve, onbelichte mesh (kegel of afgeknotte piramide) met een verloop naar de rand en naar beneden, in de shader-aanpak van `streep.gdshader`. Hooguit 30 % helderheid; zelfde plaats en vorm als het mistvolume, zodat beide standen hetzelfde beeld geven.
- Regen die door een kegel valt licht op (de regendeeltjes worden belicht): dat is het mooiste effect, niet uitzetten.

## 6. Regen en nat

### 6.1 Regen

- GPUParticles3D met dunne gestrekte balkjes (1–2 cm breed, 30–50 cm lang), kleur `#6E86A8`, 35–50 % dekking, 10–15° schuin, twee dieptelagen met verschillende snelheid. Alleen in een volume rond het eiland, niet over de hele wereld.
- Aantal: circa 6000 (volle stand), circa 2000 (lichte stand). De dichtheid rond Richard en in de lichtkegels moet in beide standen gelijk ogen; bespaar aan de randen.
- Spetters op de grond en ringen in plassen (6.3).
- Binnen: alleen druppels en strepen op ramen (volgens de raamregels), nooit vallende regen. Achter het raam mag regen vallen.
- Onderstad: geen regen.

### 6.2 Nat oppervlak

- Buiten is alles nat: asfalt en klinkers roughness 0,15–0,3, natte gevelvoet, glimmende stoepranden.
- Elke lichtbron buiten heeft een reflectie in het natte oppervlak, ook in de lichte stand: een reflectiestreep (`streep.gdshader`: additief, verloop weg van de bron naar de camera) in de kleur van de bron, 4–8 m lang, lichte rimpeling. SSR vult aan in de volle stand, maar het beeld hangt er niet van af.
- Per straatdeel (circa 20–30 m) een ReflectionProbe met box projection, één keer bijgewerkt. Daardoor spiegelen gevels, ramen, lantaarnkoppen en bomen ook als ze buiten beeld staan en zonder SSR.
- Binnen: natte voetsporen van het vochtsysteem als decal met roughness 0,05–0,2; ze glanzen alleen waar licht valt.

### 6.3 Plassen

Les uit de test: plassen waren blauwe ellipsen die vooral de blauwe lucht spiegelden.

| Regel | Waarom |
| --- | --- |
| Albedo donkerder dan het asfalt eromheen (`#14171E`), roughness 0,02–0,05. Een plas heeft geen eigen kleur | Een plas is donker tot er licht in valt |
| De reflectielucht buiten is bewolkte nacht (`#1A1620`–`#2A2230`, energie ≤ 1), niet `#3E5578` op energie 4 | Anders wordt elke plas een blauwe ovaal |
| Reflectie uit de ReflectionProbe van het straatdeel, plus SSR in de volle stand, plus de reflectiestreep van elke bron | Gevel, lampen en bomen moeten herkenbaar spiegelen |
| Onregelmatige rand (10–20 hoekpunten), geen ellips; maten 0,3–3 m door elkaar | Echte plassen hebben geen vorm |
| Op logische plekken: langs de stoeprand, in de goot, bij putten, in laagtes van klinkers, onder dakranden. 3–8 per 20 m straat | Een plas midden op een egale stoep oogt geplakt |
| Rand van 10–20 cm met een tussenroughness (0,1) naar het natte asfalt | Geen harde rand tussen plas en weg |
| Regenringen: procedurele verstoring van de normaal in de plas-shader, 3–6 ringen per m² per seconde, geen textuur | Zonder ringen staat het water stil en oogt het als glas |
| Toets: in elke plas binnen 6 m van een lichtbron is die bron op het 1080p-screenshot te herkennen | Anders voelt het droog |

### 6.4 Groot water

Maas, havenbekkens en de grachten van Delfshaven (besluit Martijn):
- **Volle stand:** echte spiegeling via een planaire reflectie (een gespiegelde tweede camera in een SubViewport, alleen voor het watervlak, op halve resolutie). Kades, kranen, gevels en de lichtlijn van de Erasmusbrug spiegelen echt. Lichte golfvervorming in de shader, geen regenringen op afstand.
- **Lichte stand:** geen extra render-pass. Het water gebruikt de ReflectionProbe van het kadedeel plus een reflectiestreep per lichtbron (`streep.gdshader`, langer dan op asfalt: 8–20 m, met meer rimpeling). Albedo `#0E1220`, zodat water zonder licht in het kader wegzakt.
- Toets: in beide standen staan de lichtbronnen op dezelfde plek in het water, en de kade leest in de lichte stand nog als rand tussen land en water.
- Onderstad: dezelfde twee standen, maar het water staat stil (geen golfvervorming, geen regen) en spiegelt in de sepialadder.

## 7. Gevels en straat

Les uit de test: de gevel was te schoon en te regelmatig.
- **Ritme breken.** Geen gevel van meer dan 4 gelijke ramen achter elkaar zonder afwijking: een dicht rolluik, gordijn half dicht, ander raamformaat, airco-unit, open raam, schotelantenne, dichtgetimmerd vak.
- **Sporen van gebruik.** Per 10 m gevel minstens twee: regenpijp, kabelgoot, uithangbord (eigen ontwerp), gevellamp boven een deur, bel- en brievenbuspaneel, graffiti of posters op de plint, fietsen tegen de gevel.
- **Lichtjes.** Per 10 ramen 1–3 verlicht, in verschillende tinten (warm lamplicht, tv-blauw dat verspringt, gordijn ervoor). Gevelverlichting en kerstlampjes in een paar ramen. Een gevel zonder één verlicht raam is dood.
- **Tinten.** Gevelvakken, plint en kozijnen in minstens drie tinten van de ladder; natte gevelvoet donkerder (4).
- **Straatmeubilair.** Paaltjes, stoeprand, putdeksels, fietsenrekken, afvalbakken, geparkeerde fietsen en scooters, lockdownresten (9.2). Op belijning en borden geen echte verkeers- of vervoerdershuisstijl.

## 8. Silhouetten en leesbaarheid

### 8.1 Richard

| Laag | Vorm | Kleur en materiaal |
| --- | --- | --- |
| Bezorgtas (Bringbroh) | Blok van circa 0,40 × 0,40 × 0,25 m op de rug, steekt 10–15 cm boven de schouders uit en iets opzij; het belangrijkste silhouet-kenmerk | Bringbroh-oranje `#D9520B` (bovenkant en zijkanten; de camera ziet vooral de bovenkant), zijvlakken in de schaduw `#A63F08`. Vaste antraciet band `#1E2228` van 8 cm rondom, op een derde van de hoogte, met daarboven een reflecterende strook `#C9C2AE` van 2 cm. Beeldmerk (>>) in antraciet op de bovenkant. De lichtste en verzadigdste vorm aan Richard |
| Jas | Parka tot halverwege de dij, capuchon als bult in de nek of op het hoofd, mouwen los van het lijf | `#2E3848` (lichter dan in v0, zodat hij in het donker als jas leest), capuchonrand één tint lichter; schouderpas in Bringbroh-oranje (bovenkant schouders, van boven goed te zien); reflecterende strook `#C9C2AE` op beide mouwen en op de rug |
| Broek, schoenen | Smal, donker | `#1A1E26`; schoenen één tint lichter zodat het lopen leest |
| Hoofd | Kort donker haar of capuchon; geen gezichtstrekken in het kamerbeeld | Huidladder naar keuze |

**Vindbaarheid onder natriumlicht.** In een natriumplas wordt alles oranje, dus de kleur alleen draagt de tas daar niet. Richard blijft vindbaar door drie dingen die niet van de tint afhangen: (1) de antraciet band, die in elk licht een donkere streep in een licht blok geeft; (2) de reflecterende strook, die het koel witte randlicht vangt; (3) het randlicht zelf (`#C8D8F0`), dat koel afsteekt tegen warm natrium. Toets per kamer en straat: zet het 1080p-screenshot op grijswaarden; de tas moet daar nog als het lichtste blok met een donkere band in Richards silhouet lezen, minstens 15 % helderheidsverschil met de achtergrond direct eromheen. Onder tl en in de nacht-ambient draagt de kleur het zelf.

**Waarom deze oranje.** `#D9520B` (HSV-tint circa 21°, verzadiging 95 %, waarde 85 %) is roder en verzadigder dan natrium `#F08A30` (tint 28°, verzadiging 80 %) en dieper en minder roze dan het koraal van BB-drink `#F0603A` (tint 12°, verzadiging 76 %, waarde 94 %). Het ligt ook bewust roder dan het gangbare oranje van bestaande bezorgapps; samen met de antraciet band en het eigen beeldmerk lijkt de tas niet op een bestaand merk (11).

- **Randlicht (les uit de test: klein en donker op afstand).** Een volglicht dat met Richard meebeweegt: SpotLight van achter-boven, tegenover de camera, alleen op Richards renderlaag (cull mask), koel wit `#C8D8F0`, energie 0,6–1,2. Zo heeft hij in elke scène een lichte rand aan schouders, capuchon en tas, ook in de schaduw.
- **Grootte.** Minstens 80 px hoog op 1080p, ook in de straat. De stijltest (ortho 38 m beeldhoogte, circa 50 px) is te ver weg.
- Richard staat nooit langer dan een paar stappen in een zone onder 15 %.
- Zonder tas en jas moet het silhouet merkbaar kleiner en gewoner ogen, en zonder oranje: dat is het onzichtbaarheidssysteem in beeld.

### 8.2 Rollen (één vorm + één kleurvlak)

Een rol leest aan één vorm (hoofd of gedragen object) en één kleurvlak (bovenkleding). Twee rollen delen nooit dezelfde combinatie.

| Rol | Vorm | Kleurvlak |
| --- | --- | --- |
| Bezorger | Blokvormige tas op de rug | Bringbroh-oranje `#D9520B` met antraciet band (de enige rol in oranje) |
| Bouwvakker | Helm (lichte koepel, breder dan het hoofd) | Hesje fluorgeel `#D8E83A` met twee reflectiestrepen |
| Beveiliger | Brede schouders, pet of kale kop, portofoon | Zwart `#14171E` met een kleine lichte badge |
| Schoonmaker | Karretje naast zich | Lichtblauw jasje `#7A98B8` |
| Verpleegkundige | Geen hoofddeksel, badgehouder | Licht pak `#B8D0D8` |
| Arts | Lange jas tot de knie | Wit `#DCDCD4` (net onder highlight-wit) |
| Cateraar | Dienblad of kist | Zwart met wit schort |
| Crew | Rolkoffer, pet of netjes kapsel | Donkerblauw jasje `#1F2A44` met goudgele strook `#C8A050` |
| Doelwitten | Eén eigen vorm per doelwit (bij hun brief) | Eén eigen kleurvlak, buiten alle rollen hierboven |

Toets: herkenbaar op 1080p bij 80 px hoogte, in de schaduwzone, als zwarte vorm plus één kleur.

### 8.3 Lagen per slot

**Maken en animeren (besluit Martijn).** Personages worden door de agents gemaakt: low-poly (budget 3.3), vlakke kleur, geen gezichtstrekken in het kamerbeeld (hoofd is vorm, haar en huidtint). Animaties komen uit een animatiebibliotheek en worden op het gedeelde skelet overgezet (retarget), niet met de hand gemaakt. Voor de hobby-release mag een gratis bibliotheek; noteer per bron naam, link, licentie en of commercieel gebruik is toegestaan, zodat een latere release haalbaar blijft (GDD, open vragen). Geen animatie in gebruik zonder vastgelegde licentie. Hoofdpersoon blijft kandidaat voor handwerk.

- Eén basismodel met skelet. Kleding per slot (hoofd, bovenkleding, over-laag, handen, voeten, gedragen) is een losse mesh op hetzelfde skelet, met dezelfde animaties.
- Elke laag ligt 0,5–1 cm buiten de laag eronder. Lichaamsdelen onder kleding worden verborgen (weggesneden of gemaskeerd), zodat er niets door kan steken.
- Gedragen objecten (tas, karretje, rolkoffer) hangen aan een bot of lopen als eigen object mee.
- De pipeline maakt een contactvel: elke combinatie in rust en halverwege een stap, vanuit de spelcamera, op 1080p. De art-director controleert op doorsteken (helm door capuchon, hesje onder jas) en kiest per conflict welke laag wint (regel: het hoofddeksel van de rol wint altijd van de capuchon).

### 8.4 Kleding als los object

Les uit de test: de parka aan de haak las als donkere vorm. Een kledingstuk dat los in de wereld ligt of hangt, toont minstens drie kenmerken: mouwen los van het lijf, een kraag of capuchon met een opening, en één contrastlijn (rits, reflecterende strook, zoom). Het hangt in of aan de rand van een lichtplas, en de albedo is één ladderstap lichter dan de muur erachter.

### 8.5 Interactieve objecten

- Albedo één ladderstap lichter of 10 % verzadigder dan het decor eromheen, en in of aan de rand van een lichtplas.
- **Contour** in `#F4F1E6` bij hover en bij de spatiebalk: een tweede, onbelichte materiaal-pass (opgeblazen achterkant), constant 2 px dik op 1080p, 70 % dekking, onder de glow-drempel. Geen emissie, geen kleurverandering van het object zelf. Decor krijgt nooit een contour.
- Bij hover verschijnt ook het vergrootglas (3.2).
- Silhouettoets op 1080p: zou ik het herkennen als zwarte vorm? Minstens 16 px.
- Pure decor-apparaten krijgen nooit een lampje of glans dat interactief oogt (GDD, apparaten).

## 9. Rotterdam van bovenaf, januari 2022

### 9.1 Herkenningsvormen (eigen ontwerp, geen logo's)

| Element | Hoe het leest in 3D | Waar het mag |
| --- | --- | --- |
| Erasmusbrug | Lichtlijn in de verte: geknikte pyloon en een waaier kabels als dunne emissieve lijnen `#C8D8F0` | Hoge verdieping of open zicht richting de Maas |
| *De Verwoeste Stad* (Zadkine) | Herkenbaar toegestaan (akkoord Martijn, `docs/rechten.md`): de gestalte met opgeheven armen en het gat waar het hart zit, low-poly in donker brons (`#2E2924`–`#4A4239`, metallic 0,6, roughness 0,5), het gat als scherpe opening waar licht doorheen valt. Op de echte plek en sokkel. Niet in de onderstad: die is vooroorlogs en het beeld is van na de oorlog (een afwijking eerst in het GDD) | Centraal beeld van het thema: straat bij het Plein 1940, droom, titelkaart, close-up |
| Markthal | Hoefijzerboog als plafondrand; het plafondkunstwerk mag herkenbaar (akkoord Martijn, `docs/rechten.md`): vertaald naar vlakke kleurvlakken en de grote vormen van het origineel, geen foto of textuur. Kleuren ontzadigd naar het palet (≤ 40 % verzadiging), het plafond belicht door de winterverlichting, niet zelf gloeiend | Ch03 |
| Kubuswoningen | Gekantelde gele kubussen in een rij | Ver zicht, poster, maquette |
| Havenkranen | Blauwgrijze portaalkranen met rode en witte lichtpunten, containers in rijen | Ch04, ver zicht vanaf de Maas |
| Stadsvlag | Groen-wit-groen, drie horizontale banen | Bar, poster, wimpel |
| De club | Rood-wit (bovenstad-rood + gebroken wit), alleen kleur en baan, geen embleem | Hub, bar, studentenkamer |
| Klinkers in keperverband | Rood-bruine klinkers in visgraat, gemodelleerd in 2–3 tinten | Katendrecht, Delfshaven |
| Stoeptegels 30×30 | Grijs raster als geometrie of vloer-shader, tegels in 2–3 tinten, een paar scheef | Straten algemeen |
| Bolders | Witte paddenstoelvorm op zwarte voet (zoals op de Rijnhavenkade) | Kades |
| Metro-ingang | MaasLijn-pictogram (11): golflijn boven een chevron naar beneden op een petrol lichtbak die koel wit doorschijnt (vervangt de marineblauwe ring uit de stijltest, die te veel op Kardia leek); geen echt metrobord, geen bestaande letter-M-huisstijl | Straat, perron |

Regels uit het GDD blijven: 1–3 elementen per kamer, logisch voor eigenaar en plek, op horizontale vlakken of op de muren die de camera ziet (achterwand, verre zijwand).

**Bestaande kunstwerken.** Alleen werken met een regel in `docs/rechten.md` mogen herkenbaar voorkomen (nu: Zadkine en het Markthal-plafond). Ook die worden in de vormtaal van het spel vertaald (low-poly, vlakke kleur), nooit als foto of textuur. Elk ander kunstwerk, gevelkunst of beeld blijft eigen ontwerp of een verwijzing (sokkel, schaduw); wil een brief een nieuw werk herkenbaar gebruiken, dan eerst een regel in `docs/rechten.md`.

### 9.2 Januari 2022 in beeld

| Onderwerp | Wat je ziet | Verloop over de week |
| --- | --- | --- |
| Kerstresten | Achtergebleven lampjes, verdroogde boom met naalden als decal, half losgeraakte slinger, kerstkaarten | Minder per nacht; vanaf 5–6 jan bomen bij de inzamelpunten |
| Vuurwerk | Losse illegale pijlen boven de daken: een stijgende vonk, dan 40–120 vonken die vallen en in 1–2 s doven, met een korte flits (5.3); kleuren uit de neon- en kerstladders. Geen statische sterretjes. Op straat rode papiersnippers en kokers als decal en kleine objecten | Alleen nacht 1 en losse knallen in nacht 2; resten blijven langer liggen |
| Lockdown | Dichte rolluiken (variatie met graffiti, deuken, posters), lege terrassen met gestapelde, geketende stoelen, A4-briefjes op deuren (eigen tekst), afhaalluik open bij snackbars | De hele week |
| Bezorgers | Fietsen en scooters met bloktas, als passerende silhouetten met een koplamp; de enige mensen op straat | De hele week, het drukst rond 18–22 uur |
| Mondkapjes | Weggegooide kapjes als decal (lichtblauw `#9AB8D0`), een kapje aan een spiegel of deurknop | De hele week |

## 10. Rendering-instellingen

Uitgangspunt is `make_env` in `proto/stijltest/lib.gd`. Elk beeld moet in de lichte stand nog werken (GDD, Prestaties).

| Instelling | Volle stand | Lichte stand |
| --- | --- | --- |
| Renderer | Forward+ | Forward+ |
| Render scale, anti-aliasing | 1,0, MSAA 4× | 0,75 met FSR, FXAA. Geen TAA (regen veegt uit) |
| Achtergrond | Egaal `#07080C`; lucht alleen als reflectiebron | Zelfde |
| Tonemapping | Filmic, exposure 1,0 | Zelfde |
| Aanpassing | Saturatie 0,92, contrast 1,06 | Zelfde |
| Glow | Screen-modus, HDR-drempel 1,0, intensiteit 0,8, sterkte 1,1, bloom 0 | Zelfde, minder niveaus |
| SSAO | Aan, straal 1,2, intensiteit 2,0 | Uit |
| SSR | Aan, 64–160 stappen, fade-in 0,05, fade-out 3,0, diepte-tolerantie 1,2 | Uit |
| Reflectieprobes | Aan, box projection, één keer bijwerken | Zelfde |
| Volumetrische mist | Aan, dichtheid zie 5.5, anisotropie 0,55, lengte 70, plus FogVolume per lantaarn | Uit; nepkegels (5.5) |
| Schaduwen | Atlas 4096, zachte schaduw medium, hooguit 6 lichten met schaduw in beeld | Atlas 2048, zacht laag, hooguit 3 |
| Regen | Circa 6000 deeltjes | Circa 2000 |
| Vignet | Aan | Aan |
| Groot water | Planaire reflectie (6.4) | Probes en reflectiestrepen (6.4) |

Doel: volle stand 60 fps op 1080p op een middenklasse-gpu (GTX 1660, RTX 3050 laptop); lichte stand minstens 30 fps op 1080p op een laptop met geïntegreerde gpu. **Referentie voor de lichte stand: een gewone laptop met Intel Iris Xe**; QA meet daar per kamer de fps. Er zijn twee standen en geen derde: de demo is een download, er is geen webversie. Budget per scène: hooguit 300 losse meshes, 16 lichten in beeld, 6 levende lichtbronnen per kamer.

## 11. Merkenuniversum

Eigen vormgeving, één regel per merk. Toets per merk: lijkt het op een bestaand merk in dezelfde branche? Dan opnieuw.

| Merk | Wat | Vormgeving | Vermijdt |
| --- | --- | --- | --- |
| **Bringbroh** | Bezorgapp van Richard (tas, jas, app) | Fel vermiljoen-oranje `#D9520B` met antraciet `#1E2228`: tas oranje met vaste antraciet band rondom, jas antraciet-blauw met oranje schouderpas, app oranje op antraciet; beeldmerk twee gestapelde afgeronde punthaken (>>) in een rondje; reflecterende strook gebroken wit | Geel-oranje of oranje-wit (zoals bestaande bezorgapps), huisje of bestek als beeldmerk, magenta, turquoise, paars-geel, zwart met felgroen |
| **VrachtGo** | Vervoerder (busjes, vrachtwagens, vrachtbrieven) | Donker staalblauw `#34495C` met één diagonale okerstrook `#C89B3C`; woordmerk in smalle blokletters | Geel, rood-geel, bruin, oranje, lichtblauw met wit |
| **Crispy & Co** | Snackbarketen (kapsalonbakjes, puntzakken, afhaalluiken) | Baksteenrood `#9A3B24` en crème `#EADBB8`, luifel in brede banen van die twee, beeldmerk een bakje van opzij met drie dampkrullen | Geel-rood, geel-wit, groen-geel |
| **BB-drink** | Energiedrank (blikjes op bureaus, in afvalbakken) | Gebroken wit blik `#E6E1D3` met twee gestapelde koraaloranje stippen `#F0603A` en een zwarte rand bovenaan | Blauw (geen huisstijl van AA-drink), zilver-blauw, zwart met groen |
| **MaasLijn** | Openbaar vervoer: metro, tram, bus (perronborden, ov-kaart, metro-ingang, haltepalen, voertuigen) | Donker petrol `#2E4A4C` met gebroken wit `#E6E1D3`; één witte golflijn als bies op voertuigen en borden; pictogram een golflijn boven een chevron naar beneden in een afgeronde rechthoek; stationsnamen in smalle schreefloze kapitalen, wit op petrol; bij de metro-ingang een lichtbak die koel wit `#EEF4FF` doorschijnt. Bewust geen marine en geen ring, zodat het naast Kardia-affiches op het perron niet als Kardia leest. De lijnkleuren op de metrokaart (3.2) staan los van de huisstijl | Rood-wit en rood met een letter M (huidige vervoerder), geel-blauw (spoorwegen), de echte lijnletters als logo, bestaande borden en lettertypes |
| **Havenlicht** | Sigaretten (pakjes, peuken, asbak, regiedetail) | Neutrale verpakking zoals in Nederland verplicht sinds 2020: mat donker olijfbruin `#4A412A`, merknaam klein in een standaard schreefloze letter in grijs `#8A8F9C`, groot waarschuwingsvlak met eigen tekst en een vlakke grijze afbeelding (geen foto). Geen beeldmerk, geen kleur. Herkenbaar alleen aan de naam en aan waar het ligt | Elk kleurig pakje (rood-wit chevron, blauw, goud), oude Rotterdamse tabaksmerken, kameel of andere dieren, echte waarschuwingsfoto's |
| **Kardia** | Officiële naam van Het Hart (affiches, bouwborden, app-scherm, toren) | Diep marine `#0E1A2C`, koel wit `#E8EEF2`, gloed ijsblauw `#BFE3FF`; beeldmerk een stip in een ring met één opening; schone schreefloze letters, veel lege ruimte | Medische beeldtaal: geen hartsymbool, hartslaglijn, kruis, rood |

Kardia-affiches nemen per nacht toe op perrons en in de stad (GDD). De ring met opening is de enige vorm die in de onderstad terug mag komen, in sepia. Merken staan op beeldvlakken (4) of als kleurvlakken in de geometrie, nooit als foto.

## 12. Do's en don'ts

| Doen | Niet doen |
| --- | --- |
| Een donker kader rond elke kamer, eiland ≤ 60 % van de breedte | Een kamer die het scherm vult |
| Detail en afgeschuinde randen in de lichtplas, kale vormen in de schaduw | Gelijk verdeeld detail van rand tot rand |
| Voorgrond die het beeld afknijpt | Voorgrond over een interactief object of de looproute |
| Elke buitenlichtbron met reflectie in het natte oppervlak, ook in de lichte stand | Droge buitenvloeren; nat dat alleen met SSR werkt |
| Plassen donker, met onregelmatige rand, op logische plekken | Blauwe ellipsen midden op de stoep |
| Vlakke kleur uit het palet, gedeelde materialen | Texturen, fotomateriaal, eigen materiaal per model |
| Emissie alleen op lichtbronnen | Gloeiende interactieve objecten, overbelichte muren die gaan gloeien |
| Een zwak eiland aan de donkere kant van elke kamer | Interactieve objecten in het pikdonker |
| Richard met volglicht en minstens 80 px hoog | Een donker poppetje op afstand |
| Gevels met gebroken ritme, sporen en verlichte ramen | Schone, regelmatige gevels |
| Neon alleen als licht | Neonkleur op kleding, meubels of merken |
| Rotterdam via kleur en vorm, 1–3 per kamer | Echte logo's, metroborden, clubemblemen, de huisstijl van de vervoerder |
| Eigen tekst op briefjes, affiches, schermen | Echte merknamen, echte uitzendingen, kunstwerken nagemaakt zonder regel in `docs/rechten.md` |
| Zadkine en het Markthal-plafond herkenbaar, vertaald naar low-poly en vlakke kleur | Foto's of texturen van kunstwerken |
| Bringbroh-oranje alleen op Bringbroh | Ander groot oranje vlak in de bovenstad |
| Lockdown en kerstresten als stille sporen | Feestelijke drukte, open terrassen |
| Onderstad monochroom met één rood | Kleur, schermen of neon in de onderstad |

### 12.1 Checklist render-review

Een review gaat over een **3D-scène in Godot**, beoordeeld op screenshots van 1920×1080 (vaste spelcamera, na genoeg frames dat regen en mist zijn opgebouwd), in beide kwaliteitsstanden, plus het contactvel voor personages en het vergrootglas voor interactieve objecten. Uitkomst per asset: **goedgekeurd**, **aanpassen** (met concrete punten) of **handwerk nodig**. Hoofdpersoon en sleutelobjecten altijd als kandidaat voor handwerk markeren.

1. **Camera en schaal**: hoek en FOV volgens 3.1; eiland ≤ 60 % × 70 % met kader rondom; Richard minstens 80 px (buiten) of 140–200 px (kamer); kleinste interactieve object minstens 16 px; maten kloppen met 3.2.
2. **Vorm**: silhouet herkenbaar; flat shading; afschuining alleen in het licht; binnen het poly-budget; kleine statische dingen samengevoegd.
3. **Materiaal**: albedo uit het palet, gedeelde materialen, geen texturen behalve decal-maskers en beeldvlakken; roughness volgens tabel 4; emissie alleen op lichtbronnen; niets anders gloeit.
4. **Waarde en verzadiging** binnen 2.3: kader 0–5 %, schaduw 5–20 %, plas 35–75 %; geen interactief object of looproute onder 15 %.
5. **Licht**: opbouw volgens 5.1; 1–3 eilanden, één aan de donkere kant; raamlicht zichtbaar op vloer of muur; lichtkegels zichtbaar zonder grauw beeld; Richard heeft randlicht.
6. **Nat** (buiten): elke lichtbron spiegelt; plassen donker, onregelmatig, op logische plekken, met regenringen; bron herkenbaar in elke plas binnen 6 m; nat werkt ook in de lichte stand; groot water volgens 6.4, lichtbronnen in beide standen op dezelfde plek in het water.
7. **Kamer als geheel**: kader en vignet, voorgrondlaag, doorsnede-rand; past bij de rest van de locatie (zelfde camera, ambient, detaildichtheid); herhalingstest (uitzoomen, zoeken naar strepen, patronen, eentonige vlakken in vloeren en muren, gevels volgens 7).
8. **Interactieve objecten**: springen eruit zonder contour, en zeker met; contour 2 px in `#F4F1E6`; vergrootglas toont het object scherp; decor heeft geen contour en geen interactief ogende glans.
9. **Levende lichtbronnen**: voelen als echte beelden; eigen seed, niet synchroon; hooguit 6; kamer blijft leesbaar bij de donkerste stand.
10. **Rotterdam en januari 2022**: element logisch voor plek en eigenaar, geen echt logo of huisstijl, kerst- en lockdownresten passend bij de nacht.
11. **Kleding**: contactvel zonder doorsteken; elke rol herkenbaar aan vorm en kleurvlak op 80 px; los kledingstuk volgens 8.4; Richard vindbaar onder natriumlicht (grijswaardentoets 8.1); geen ander groot oranje vlak in beeld.
12. **Prestaties**: scène binnen het budget (meshes, lichten, schaduwlichten); fps in beide standen gemeten door QA.

## 13. Open punten voor Martijn

1. **Gebakken licht** (afspraak): vast ambient- en kaatslicht bakken met LightmapGI is mooier en goedkoper, maar maakt elke lichtwijziging een bakstap. Wordt onderzocht in een volgende stijltest (beide standen, met meting op de Iris Xe-laptop); tot dan is alle licht realtime volgens 5 en 10.
2. **Stijltest onderstad**: een kleine 3D-test van de onderstad (sepia, gaslicht, scheve gevels, één rood) op basis van de door Martijn gekozen Stadsarchief-beelden (2.2), voordat ch01 begint. Akkoord?
3. **Stijltest bijwerken**: de stijltest in `proto/stijltest/` gebruikt nog pistache voor de tas en de marineblauwe ring voor de metro-ingang. Als maatstaf bijwerken naar v1.1, of alleen in nieuwe scènes toepassen?
