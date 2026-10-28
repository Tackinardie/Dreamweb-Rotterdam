# Stijlgids Onderstad — v0

Beheer: art-director · Bron: `docs/GDD.md` (Art direction en audio, Setting en thema, Interface) · Issue #5

Deze gids is de werkinstructie voor de asset-pipeline (Blender-renders en placeholders) en de toetssteen voor elke art-review. Bij strijd met het GDD wint het GDD; de art-director meldt het verschil en past de gids aan.

## 1. Uitgangspunt

- **Sfeer (pillar 1).** Elk beeld is een klein verlicht eiland in een donker, nat Rotterdam. Licht vertelt waar je moet kijken; de rest zakt weg. Het kernbeeld van de bovenstad is de Coolsingel in de regen bij schemer: nat asfalt, rode achterlichten in plassen, kale bomen met achtergebleven kerstlampjes, een stad die leeg is behalve voor wie bezorgt.
- **Twijfel (pillar 4).** Bovenstad en onderstad zijn visueel streng gescheiden (koud blauw en natrium tegenover sepia met één rood). Juist daardoor valt het op als er iets lekt: een rood dat er niet hoort, een schaduw die te lang is. Zulke lekken zijn regie, nooit toeval (zie 2.3).
- **Ingetogen, niet arm.** De beklemming komt uit de kadrering, niet uit lege kamers (GDD, Kadrering en detail). Vol in het licht, leeg in het donker.

## 2. Palet

Albedo-kleuren van sprites. Godot-licht kleurt ze in het spel verder; het palet bewaakt de basis. De pipeline zet deze tabellen om naar `art/palet/bovenstad.gpl` en `art/palet/onderstad.gpl` voor het kwantiseerscript.

### 2.1 Bovenstad (Rotterdam nu)

| Rol | Hex (donker → licht) | Gebruik |
| --- | --- | --- |
| Kader / leegte | `#07080C` | Alles buiten het kamer-eiland, vignet-eindkleur |
| Diepe schaduw | `#0E1220` `#151B2C` | Hoeken, onder meubels, voorgrond-silhouetten |
| Nacht-ambient (koud blauw) | `#1F2A44` `#2A3A5C` `#3E5578` `#5A7398` | Muren en vloeren buiten de lichtplas |
| Lucht blauw uur | `#1C2A5E` `#2B3F7A` `#4A5FA0` | Alleen schemer (zie 4.4) |
| Lucht bewolkte nacht | `#1A1620` `#2A2230` `#3C2E36` | Stadsgloed tegen laaghangende bewolking: vuil paars-oranje, geen sterren |
| Nat asfalt | `#14171E` `#1E232C` `#2E3540` `#46505E` | Straat, met reflectie via normal map en natlaag |
| Natriumlicht | `#5A2A10` `#8A3E14` `#C8601E` `#F08A30` `#FFB866` | Straatlantaarns, kade, bouwplaats; kern alleen in de lamp zelf |
| Warm lamplicht binnen | `#4A3020` `#6E4528` `#A8703E` `#D89A5A` `#FFD8A0` | Bureaulamp, sfeerlamp, bar |
| Tl / koel kunstlicht | `#A8B8B4` `#D6E2DC` `#F0F6F0` | Ziekenhuis, kantine, perron, parkeergarage |
| Neon-accent magenta | `#5C1440` `#A0246E` `#FF3EA5` | Alleen lichtbronnen en hun reflectie |
| Neon-accent cyaan | `#124450` `#1E7A8C` `#3EE6FF` | Alleen lichtbronnen en hun reflectie |
| Kerstlampjes buiten (LED) | `#C8D8F0` `#EEF4FF` | Bomen op straat, gevels (koel wit, zoals de Coolsingel) |
| Kerstlampjes binnen | `#E8B868` `#FFE2A8` | Snoer langs het raam, bar; hooguit één oud gekleurd snoer (`#D04A32` `#5FB860` `#E8C040`) |
| Bovenstad-rood | `#6A2018` `#A8382A` `#D04A32` | Achterlichten, rood-wit van de club, Crispy & Co, vuurwerkresten. Warm, oranje-getint |
| Huid (drie ladders) | `#5A3A2C` `#8A5A40` `#B88462` · `#3A241C` `#5E3A2A` `#86563C` · `#7A5A48` `#B08868` `#D8B494` | Personages; in nachtlicht geen extra verzadiging |
| Interactief-highlight | `#F4F1E6` | Randlicht (1 px) en spatiebalk-markering. Gereserveerd: geen decor in deze kleur |
| UI | paneel `#0B0D14` (85 % dekking) · tekst `#D8D4C8` · tekst 2 `#8A8F9C` · selectie `#F08A30` · rand `#2A3040` | Klok, inventarisstrook, telefoon-chrome, notitieboek |

### 2.2 Onderstad (vooroorlogs Rotterdam, droom)

| Rol | Hex | Gebruik |
| --- | --- | --- |
| Kader / leegte | `#0C0B0A` | Buiten het eiland; in de onderstad ook gaten in de wereld |
| Sepia-grijs ladder | `#1C1916` `#2E2924` `#4A4239` `#6E6355` `#978A76` `#C2B49C` `#E6DCC8` | Alles: gevels, klinkers, water, figuren |
| Het rood | `#4E0812` `#A01028` | Eén ding per scène (zie regels) |
| Interactief-highlight | `#F4F1E6` | Zelfde als bovenstad: de speler moet de taal herkennen |

**Verwrongen, volgens het GDD**, maar met dezelfde camera en hetzelfde tile-grid (leesbaarheid blijft):
- Geometrie in Blender licht scheef: gevels 2–6° uit het lood, deuren te hoog, ramen op de verkeerde hoogte, een straat die te lang doorloopt.
- Ontbrekende stukken: gebouwen die per hoofdstuk verdwijnen of terugkomen (droomsysteem-lagen), randen die overgaan in kader-zwart.
- Filter in Godot (desaturatie, ruis): korrel 1 px, 6–10 % dekking, geen beweging sneller dan 4 fps. Geen regen-particles in de onderstad; wel stilstaande waterdruppels in de lucht als dat de scène vraagt.
- Geen hedendaagse objecten, geen neon, geen schermen. Licht komt van gaslantaarns en van een diffuus, richtingloos schijnsel.

### 2.3 Regels voor accentkleur

| Kleur | Mag | Mag niet |
| --- | --- | --- |
| Neon magenta/cyaan | Lichtbronnen (neonbuis, reclamebord, scherm) en hun reflectie in plassen, glas, nat asfalt | Kleding, meubels, merken, UI |
| Natrium | Buitenlampen, hun lichtplas en reflectie | Binnenverlichting (dat is warm lamplicht) |
| Onderstad-rood `#A01028` | In de onderstad: precies één element per scène (wat de droom hem wil laten zien), plus de reflectie daarvan | Meer dan één element; in de UI |
| Onderstad-rood in de bovenstad | Alleen als bewust twijfelsignaal, hooguit één keer per hoofdstuk, vastgelegd in de levelbrief | Als gewoon decor; elk gewoon rood in de bovenstad gebruikt de bovenstad-ladder |
| Interactief-highlight | Randlicht, spatiebalk-markering | Alles anders |
| Verzadiging decor | HSV-verzadiging ≤ 40 % | — |
| Verzadiging interactieve objecten | ≤ 60 % | Feller dan lichtbronnen |
| Verzadiging lichtbronnen | tot 100 % | — |

Waardeopbouw (helderheid): kader 0–5 %, schaduwzone 5–20 %, lichtplas 35–75 %, lichtbron zelf 85–100 %. Niets buiten een lichtplas komt boven 30 %.

## 3. Resolutie, schaal en perspectief

| Onderwerp | Waarde |
| --- | --- |
| Interne resolutie | 640×360, pixel-perfect ×3 (1080p) en ×4 (1440p); geen subpixel-beweging van sprites |
| Tile | 16×16 px; 1 Blender-unit = 1 tile = 1 m |
| Kamer, richtwaarde | 10×8 tiles vloer = 160×128 px, plus achterwand 2,6 m = 42 px hoog; eiland ca. 160×170 px, dus ongeveer een kwart van de breedte en de helft van de hoogte van het scherm |
| Maximale eilandgrootte | 24×14 tiles (384×224 px) voor de open lege ruimtes (containerterrein, platform); minimaal 32 px kader rondom |
| Personage-frame | 16×32 px, voetpunt onderaan het midden (y-sort); lichaam zelf 10–12 px breed, 28–30 px hoog bij 1,80 m |
| Richtingen v0 | 4 (voor, achter, links, rechts); loopcyclus 6 frames, idle 2–4 frames |
| Kleinste interactieve object | 6×4 px zichtbaar (sleutel, pasje), altijd met highlight; liever 8×8 |
| Vergrootglas (hover) | Venster 96×96 px intern in een hoek; de pipeline rendert elk interactief object ook op ×2 (32 px per unit) |
| Close-up panelen | Handwerk op het ×3-grid (1 artpixel = 1 schermpixel bij 1080p), maximaal 960×540; zelfde palet |
| Metrokaart (UI) | Eigen schematische kaart op 8-px raster, alleen 0°, 45° en 90°, lijndikte 3 px, stations als open rondjes van 5 px, overstappen als langgerekt rondje; echte lijnkleuren (door de locatie-onderzoeker te bevestigen) gekwantiseerd naar het palet; geen logo, lettertype of kaartontwerp van de vervoerder |

**Camera (vaste 3/4-weergave).** Orthografische camera, 45° naar beneden gekanteld, recht naar het noorden van de kamer kijkend (geen rotatie om de verticale as). Doel: een vloertile is 16×16 px en 1 m hoogte is ook 16 px. Dat vraagt een verticale schaal van √2 ten opzichte van de horizontale: in Blender orthografische schaal instellen op 22,63 px per unit verticaal en pixel aspect X = 1,414 (16 px per unit horizontaal). Nooit achteraf herschalen.
- **IJktest voor de pipeline**: een kubus van 1×1×1 rendert als precies 16×32 px (16×16 bovenvlak + 16×16 voorvlak), zonder anti-aliasing.
- Zijwanden links en rechts zie je niet; achterwanden alleen aan de bovenrand van de kamer (GDD). De voorwand wordt weggelaten of als voorgrond-silhouet getekend.

## 4. Belichting

### 4.1 Verdeling Blender en Godot

| Waar | Wat |
| --- | --- |
| Blender (gebakken) | Zachte ambient per locatie (nacht-ambient of tl), contactschaduw/AO, vaste lichtbronnen die nooit schakelen. Lage sterkte: de albedo moet in het donker nog leesbaar zijn |
| Godot 2D-lights + normal maps | Alles wat aan en uit kan (apparaten), levende lichtbronnen, natriumplassen, reflecties op nat oppervlak, het licht van de telefoon |
| Normal map | Uit de normal pass van Blender, zelfde camera; per sprite meegeleverd. Pipeline toetst de oriëntatie met een bol |

### 4.2 Kadrering

- Kader `#07080C`, vignet 24–48 px van kamerrand naar kader.
- Elke kamer heeft minstens één voorgrondlaag die 8–24 px over de rand hangt (dakrand, leiding, gordijn, stelling, bovenleiding), getekend als silhouet in de diepe schaduwtinten met hooguit 1 px randlicht van de dichtstbijzijnde bron. Voorgrond dekt nooit een interactief object of de looproute af.
- Per kamer 1–3 lichtplassen. Detaildichtheid volgt het licht: in de plas het meeste detail en de scherpste tinten, in de schaduw grote vlakken van 2 tinten.

### 4.3 Lichtsoorten

| Bron | Kleur | Vorm en gedrag |
| --- | --- | --- |
| Natrium (straat, kade) | `#F08A30` | Ronde plas 4–6 tiles doorsnee, harde kern, zachte rand; reflecteert lang uitgerekt in natte vloer (verticale streep onder de bron) |
| Warm lamplicht | `#FFD8A0` | Kleine plas, 2–4 tiles; dimbaar waar het GDD dat toestaat |
| Tl | `#F0F6F0` | Rechthoekig, gelijkmatig; knippert 2–4 keer bij aanspringen |
| Tv | per profiel (GDD) | Cuts om de 2–8 s, eigen seed per scherm |
| Monitor | `#9FC8E8` koel | Rustig, kleine verschuivingen bij vensterwissel |
| Telefoon | `#C8DCF0` | Licht gezicht en handen, straal 1–2 tiles; korte flits bij melding |
| Neon | magenta of cyaan | Stabiel, af en toe hapering; max. één neonbron per binnenkamer |
| Kerstlampjes | zie palet | Puntjes van 1 px, onderling licht verschoven flikkering; samen hooguit één zwakke plas |
| Koplampen (raamgebeurtenis) | `#EEF4FF` | Strijkende band over muur en plafond, alleen volgens de raamregels |

Maximaal ca. 6 levende lichtbronnen per kamer (GDD). Twee schermen in één kamer lopen nooit synchroon.

### 4.4 Licht per scènetijd

| Scènetijd | Lucht en ramen | Ambient | Lampen |
| --- | --- | --- | --- |
| Schemer (ca. 16:45–17:45 in januari) | Blauw uur `#2B3F7A` | Nacht-ambient + blauwe lucht | Straatlampen aan, etalages deels aan, rolluiken dicht |
| Avond en nacht (18:00–06:30) | Bewolkte nacht `#2A2230`; bij open hemel donker `#0E1220` | Nacht-ambient | Natrium, schermen, ramen van overburen gaan uit naarmate het later wordt |
| Ochtendschemer (ca. 07:30–08:45) | Van `#1C2A5E` naar grijsblauw `#5A7398` | Wordt per scène lichter | Straatlampen nog aan, gaan rond zonsopgang uit |
| Zonsopgang finale (7 jan, ca. 08:45) | Lage, koude zon: horizon `#E8A060` → `#F4D8B0` | Eerste en enige keer lange warme lichtstrepen van opzij | Platformverlichting valt weg tegen daglicht |

Tijden zijn richtwaarden voor Rotterdam in de eerste week van januari; de locatie-onderzoeker bevestigt ze.

### 4.5 Regen en nat

- Regen is een vaste particle-laag buiten: strepen 1×3 tot 1×5 px, kleur `#6E86A8`, 35–50 % dekking, 10–15° schuin, twee dieptelagen met verschillende snelheid. Spetters 1–2 px op vloer en plassen.
- Binnen: alleen druppels en strepen op ramen (volgens de raamregels), nooit vallende regen.
- Natte buitenvloer: plassen als aparte decal-laag die lichtbronnen spiegelt (reflectie in de kleur van de bron, 50 % helderheid, horizontale rimpeling 1 px). Elke lichtplas buiten heeft een reflectie, anders voelt het droog.
- Natte voetsporen binnen volgen het vochtsysteem; ze glanzen alleen waar licht valt.

## 5. Silhouetten en leesbaarheid

### 5.1 Richard

| Laag | Vorm | Kleur |
| --- | --- | --- |
| Bezorgtas (Bringbroh) | Rechthoekig blok op de rug, steekt 3–4 px boven de schouders uit en 2 px opzij; het belangrijkste silhouet-kenmerk | Zie Bringbroh (7) |
| Jas | Donkere parka tot halverwege de dij, capuchon als bult in de nek of op het hoofd | `#232A36` met randlicht; reflecterende strook `#C9C2AE` van 1 px op de mouw |
| Broek, schoenen | Smal, donker | `#1A1E26`; schoenen 1 tint lichter zodat de loopcyclus leest |
| Hoofd | Kort donker haar of capuchon | Huidladder naar keuze bij handwerk |

Richard draagt altijd 1 px randlicht `#F4F1E6` op de kant van de sterkste bron (25–40 % dekking), zodat hij in elke kamer vindbaar is. Zonder tas en jas moet het silhouet merkbaar kleiner en gewoner ogen: dat is het onzichtbaarheidssysteem in beeld.

### 5.2 Rollen (één vorm + één kleurvlak)

Een rol leest aan één vorm (hoofd of gedragen object) en één kleurvlak (bovenkleding). Twee rollen delen nooit dezelfde combinatie.

| Rol | Vorm | Kleurvlak |
| --- | --- | --- |
| Bezorger | Blokvormige tas op de rug | Pistache van Bringbroh |
| Bouwvakker | Helm (lichte koepel, 6 px breed) | Hesje fluorgeel `#D8E83A` met twee reflectiestrepen |
| Beveiliger | Brede schouders, pet of kale kop, portofoon | Zwart `#14171E` met één lichte badge-pixel |
| Schoonmaker | Karretje naast zich | Lichtblauw jasje `#7A98B8` |
| Verpleegkundige | Geen hoofddeksel, badgehouder | Licht pak `#B8D0D8` |
| Arts | Lange jas tot de knie | Wit `#DCDCD4` (net onder highlight-wit) |
| Cateraar | Dienblad of kist | Zwart met wit schort |
| Crew | Rolkoffer, pet of netjes kapsel | Donkerblauw jasje `#1F2A44` met goudgele strook `#C8A050` |
| Doelwitten | Eén eigen vorm per doelwit (bij hun brief) | Eén eigen kleurvlak, buiten alle rollen hierboven |

### 5.3 Lagen per slot

- Vaste tekenvolgorde per richting. Voor, links, rechts: voeten, lichaam, bovenkleding, over-laag, handen, hoofd, gedragen (tas achter het lichaam). Achter: tas vóór alles behalve het hoofddeksel.
- Elke laag is een eigen sprite op hetzelfde 16×32-frame met hetzelfde voetpunt. Geen laag mag buiten het frame vallen behalve gedragen objecten (karretje, rolkoffer: eigen sprite naast het personage).
- De pipeline rendert alle combinaties automatisch als contactvel; de art-director controleert op doorsteken (helm door capuchon, hesje onder jas) en kiest per conflict welke laag wint (regel: het hoofddeksel van de rol wint altijd van de capuchon).

### 5.4 Interactieve objecten

- Altijd 1 tint lichter of 10 % verzadigder dan het decor eromheen, en in of aan de rand van een lichtplas.
- Subtiel randlicht `#F4F1E6` 1 px bij hover en bij de spatiebalk; geen randlicht op decor.
- Elk object leest als zichzelf op 1× (640×360): de silhouettoets is "zou ik het herkennen als zwarte vorm?".
- Pure decor-apparaten krijgen nooit een lampje of glans dat interactief oogt (GDD, apparaten).

## 6. Rotterdam van bovenaf, januari 2022

### 6.1 Herkenningsvormen (eigen tekening, geen logo's)

| Element | Hoe het leest in pixels | Waar het mag |
| --- | --- | --- |
| Erasmusbrug | Lichtlijn in de verte: geknikte witblauwe pyloon (`#C8D8F0`) met een waaier kabels in 1 px | Hoge verdieping of open zicht richting de Maas |
| Markthal | Hoefijzerboog als plafondrand met een eigen, abstract bloem- en fruitpatroon; nooit het echte kunstwerk natekenen | Ch03 |
| Kubuswoningen | Gekantelde gele vierkanten in een rij | Ver zicht, poster, maquette |
| Havenkranen | Blauwgrijze portaalkranen met lichtjes, containers in rijen | Ch04, ver zicht vanaf de Maas |
| Stadsvlag | Groen-wit-groen, drie horizontale banen | Bar, poster, wimpel |
| De club | Rood-wit (bovenstad-rood + gebroken wit), alleen kleur en baan, geen embleem | Hub, bar, studentenkamer |
| Klinkers in keperverband | Rode-bruine klinkers in visgraat | Katendrecht, Delfshaven |
| Stoeptegels 30×30 | Grijs raster van ca. 5 px | Straten algemeen |
| Bolders | Witte paddenstoelvorm op zwarte voet (zoals op de Rijnhavenkade) | Kades |
| Metro-ingang | Eigen pictogram (geen echt metrobord, geen bestaande letter-M-huisstijl) | Straat, perron |

Regels uit het GDD blijven: 1–3 elementen per kamer, logisch voor eigenaar en plek, op horizontale vlakken of aan de bovenrand.

### 6.2 Januari 2022 in beeld

| Onderwerp | Wat je ziet | Verloop over de week |
| --- | --- | --- |
| Kerstresten | Achtergebleven lampjes, verdroogde boom met naalden-decal, half losgeraakte slinger, kerstkaarten | Minder per nacht; vanaf 5–6 jan bomen bij de inzamelpunten |
| Vuurwerk | Losse illegale pijlen boven de daken (kleur uit de neon- en kerstladders, korte flits van 2–3 frames); op straat rode papiersnippers en kokers als decal | Alleen nacht 1 en losse knallen in nacht 2; resten blijven langer liggen |
| Lockdown | Dichte rolluiken (variatie met graffiti, deuken, posters tegen het patroon), lege terrassen met gestapelde, geketende stoelen, A4-briefjes op deuren (eigen tekst), afhaalluik open bij snackbars | De hele week |
| Bezorgers | Fietsen en scooters met bloktas, als passerende silhouetten met een koplamp; de enige mensen op straat | De hele week, het drukst rond 18–22 uur |
| Mondkapjes | Weggegooide kapjes als decal (lichtblauw `#9AB8D0`), een kapje aan een spiegel of deurknop | De hele week |

## 7. Merkenuniversum

Eigen vormgeving, één regel per merk. Toets per merk: lijkt het op een bestaand merk in dezelfde branche? Dan opnieuw.

| Merk | Wat | Vormgeving | Vermijdt |
| --- | --- | --- | --- |
| **Bringbroh** | Bezorgapp van Richard (tas, jas, app) | Pistache `#8FCB7A` met antraciet `#1E2228`; beeldmerk twee gestapelde afgeronde punthaken (>>) in een rondje; reflecterende strook gebroken wit | Magenta, oranje, turquoise, paars-geel, zwart met felgroen |
| **VrachtGo** | Vervoerder (busjes, vrachtwagens, vrachtbrieven) | Donker staalblauw `#34495C` met één diagonale okerstrook `#C89B3C`; woordmerk in smalle blokletters | Geel, rood-geel, bruin, oranje, lichtblauw met wit |
| **Crispy & Co** | Snackbarketen (kapsalonbakjes, puntzakken, afhaalluiken) | Baksteenrood `#9A3B24` en crème `#EADBB8`, luifel in brede banen van die twee, beeldmerk een bakje van opzij met drie dampkrullen | Geel-rood, geel-wit, groen-geel |
| **BB-drink** | Energiedrank (blikjes op bureaus, in afvalbakken) | Gebroken wit blik `#E6E1D3` met twee gestapelde koraaloranje stippen `#F0603A` en een zwarte rand bovenaan | Blauw (geen huisstijl van AA-drink), zilver-blauw, zwart met groen |
| **Kardia** | Officiële naam van Het Hart (affiches, bouwborden, app-scherm, toren) | Diep marine `#0E1A2C`, koel wit `#E8EEF2`, gloed ijsblauw `#BFE3FF`; beeldmerk een stip in een ring met één opening; schone schreefloze letters, veel lege ruimte | Medische beeldtaal: geen hartsymbool, hartslaglijn, kruis, rood |

Kardia-affiches nemen per nacht toe op perrons en in de stad (GDD). De ring met opening is de enige vorm die in de onderstad terug mag komen, in sepia.

## 8. Do's en don'ts

| Doen | Niet doen |
| --- | --- |
| Een donker kader rond elke kamer | Een kamer die het scherm vult |
| Detail in de lichtplas, grote vlakken in de schaduw | Gelijk verdeeld detail van rand tot rand |
| Voorgrond die het beeld afknijpt | Voorgrond over een interactief object of de looproute |
| Elke buitenlichtbron met reflectie op nat oppervlak | Droge buitenvloeren |
| Vloer als één uniek beeld per kamer; slijtage op looppaden | Herhaalde tegel zichtbaar op een kleine kamervloer |
| Materiaalladders van 3–5 tinten, beperkte dithering | Fotoruis, verlopen, anti-aliasing |
| Neon alleen als licht | Neonkleur op kleding, meubels of merken |
| Rotterdam via kleur en vorm, 1–3 per kamer | Echte logo's, metroborden, clubemblemen, de huisstijl van de vervoerder |
| Eigen tekst op briefjes, affiches, schermen | Echte merknamen, echte uitzendingen, echte kunstwerken nagetekend |
| Lockdown en kerstresten als stille sporen | Feestelijke drukte, open terrassen |
| Onderstad monochroom met één rood | Kleur, schermen of neon in de onderstad |

### 8.1 Checklist render-review

Uitkomst per asset: **goedgekeurd**, **aanpassen** (met punten) of **handwerk nodig**. Hoofdpersoon en sleutelobjecten altijd als kandidaat voor handwerk markeren.

1. Kubus-ijking klopt: vloer 16×16 per tile, hoogte 16 px per meter, voetpunt goed.
2. Alleen kleuren uit het palet; ladder van 3–5 tinten per materiaal; geen anti-aliasing, strakke transparantie.
3. Verzadiging en waarde binnen de grenzen van 2.3.
4. Leesbaar op 1× (640×360): silhouettoets geslaagd; interactief object springt eruit zonder randlicht, en zeker met.
5. Normal map aanwezig en goed georiënteerd (lichttest met bewegende bron in Godot).
6. Past bij de rest van de kamer: zelfde lichtrichting, zelfde detaildichtheid, zelfde ambient.
7. Kamer als geheel: kader en vignet, voorgrondlaag, 1–3 lichtplassen, herhalingstest (uitzoomen, zoeken naar strepen, patronen, eentonige vlakken).
8. Levende lichtbronnen: eigen seed, niet synchroon, maximaal 6, kamer blijft leesbaar bij de donkerste stand.
9. Rotterdam en januari 2022: element logisch voor plek en eigenaar, geen echt logo, kerst- en lockdownresten passend bij de nacht.
10. Kleding: alle laagcombinaties van het contactvel zonder doorsteken; elke rol in één oogopslag te herkennen.

## 9. Open punten voor Martijn

1. **Pixelart-referentie ontbreekt.** Graag 2–3 games of beelden die de gewenste detaildichtheid en randstijl tonen (wel of geen donkere outline om personages; hoeveel dithering). Kandidaten om uit te kiezen: screenshots van DreamWeb zelf, Gemini Rue, Kathy Rain, Unavowed, The Last Night, Eastward. Tot dan geldt: geen zwarte outline, alleen randlicht.
2. **Bringbroh-kleur**: pistache met antraciet. Akkoord, of een andere kleur? Het is Richards belangrijkste herkenningskleur.
3. **Onderstad-rood als twijfelsignaal in de bovenstad** (2.3): een aanvulling op het GDD. Akkoord, en zo ja, opnemen in het GDD?
4. **Fictieve naam van de ov-vervoerder** (voor perronborden, ov-kaart, metro-ingang) en het **sigarettenmerk** uit de Regiestijl: nog geen naam.
5. **Echte bouwwerken en kunst**: De Verwoeste Stad van Zadkine en het Markthal-plafond zijn auteursrechtelijk beschermd. Panoramavrijheid dekt mogelijk afbeelden in de openbare ruimte, maar niet zeker in een commerciële game. Voorstel: de gestalte en het Markthal-patroon altijd als eigen ontwerp; voor Zadkine juridisch advies of alleen een verwijzing (een sokkel, een schaduw, een foto in de wereld).
6. **Referentie voor de onderstad**: vooroorlogse foto's van Rotterdam (Stadsarchief) als sfeerbron; welke beelden wil je als basis?
