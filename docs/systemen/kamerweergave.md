# Kamerweergave

**In één zin:** elke kamer is een verlicht 3D-eiland op een raster van vakken van 1×1 m, gebouwd uit haar kamerbestand en gezien door één vaste camera met smalle FOV; de logica kent alleen vakken, de weergave tekent ze.

Schema's: `tools/schemas/room.schema.json` (`afmeting`, `plafond`, `model`, `camera`, `geblokkeerd`, `lichten`, `stand` bij een plaatsing), `tools/schemas/item.schema.json` (`model`, `closeup`), `tools/schemas/common.schema.json` (`positie`, `vakgebied`, `kleur`, `asset_id`). Testkamer: `tests/fixtures/proef/chapters/ch01_proef/rooms/ch01_kantoor.json` (8×6, bureau geblokkeerd, twee lichten, laptop met close-up).

## Doel en pillar

- **Sfeer (1):** een klein verlicht doosje in een donker kader, door een bijna orthografische blik (GDD, Kadrering en detail; stijlgids 3.1).
- **Een fysieke wereld (2):** wat in de data op een vak ligt, staat daar zichtbaar; je loopt erheen en pakt het.
- Geen pixel hunting: contour bij hover, spatiebalk toont alles, vergrootglas en close-up voor detail.

## Regels

**Vakken en 3D-ruimte** (issue #34)

- W1. **Vak.** Een vak is 1×1 m. Alle posities in content zijn gehele vakken (`positie {x, y}`); looproutes, neerleggen (O8), blokkeren en interactie rekenen alleen in vakken. 1 unit = 1 m.
- W2. **Assen en oorsprong.** Elke kamer heeft een eigen kamerruimte (Godot, rechtshandig, +Y omhoog). De kamerwortel staat op de wereldoorsprong; kamers delen geen coördinaten. Oorsprong (0,0,0) = de hoek linksachter van de vloer, de buitenhoek van vak (0,0). `positie.x` loopt langs +X (kolom, links → rechts), `positie.y` langs +Z (rij, achterwand → camerakant). `afmeting.breedte` = aantal kolommen, `afmeting.hoogte` = aantal rijen in de diepte, niet omhoog.
- W3. **Omrekening** (één statische, zuivere functie, bijv. `Vak.naar_3d` / `Vak.uit_3d`):
  - vak → 3D: `Vector3(x + 0.5, 0.0, y + 0.5)`, het middelpunt van het vak op de vloer.
  - 3D → vak: `Vector2i(floori(X), floori(Z))`; ligt dat buiten `[0, breedte) × [0, hoogte)`, dan is er geen vak (`null`).
  - Een plaatsing met `stand` verschuift alleen het model: `+ Vector3(dx, hoogte, dz)` en `draai` om Y. Het vak blijft hetzelfde.
- W4. **Vloerhoogte en verdiepingen.** De vloer ligt op Y = 0 en is in deze versie overal even hoog. Een verdieping van een gebouw is een aparte kamer (via trap of lift). Hoogte boven straatniveau is geen kamereigenschap; het ramensysteem legt die later per raam vast. Hoogteverschillen binnen één kamer (trapje, podium) bestaan nog niet.
- W5. **Oriëntatie.** Achterwand = Z 0 (rij 0), voorkant = Z `hoogte` (camerakant, weggesneden), links = X 0, rechts = X `breedte`. Draai 0 van een model = voorkant naar +Z (naar de camera). Kompasrichting staat niet in de kamer; het ramensysteem legt later per raam vast wat erachter ligt.

**Opbouw van de scène**

- W6. **Opbouw uit het kamerbestand,** in deze volgorde: kader, vloer, muren, `geblokkeerd`, objecten, uitgangen, NPC's, Richard, lichten. Zonder `model` (of als het bestand ontbreekt) bouwt de weergave een **placeholder**:

| Onderdeel | Placeholder |
| --- | --- |
| Kader | Achtergrond `#07080C`, vignet naar dezelfde kleur |
| Vloer | Vlak van `breedte × hoogte` m op Y 0, `#2A3A5C` |
| Muren (binnen, droom) | Achterwand en verre zijwand volle `plafond`-hoogte (standaard 2,6 m), 0,1 m dik, `#1F2A44`. Voorwand en nabije zijwand: rand van 0,4 m, `#0E1220`. Nabij = rechts bij `draaiing` > 0, links bij < 0. Buiten: geen muren, alleen de rand. Geen plafond in beeld |
| Geblokkeerd | Blok per gebied, 0,75 m hoog, `#151B2C` |
| Uitgang | Op een randvak: opening van 0,9 × 2,1 m in die muur (achter > links > rechts > voor bij een hoekvak), deurblad `#3E5578`. Niet aan de rand: blok 0,9 × 2,1 m |
| Object, pakbaar | Kubus van 0,15 / 0,25 / 0,35 m voor grootte 1 / 2 / 3, `#5A7398` |
| Object, niet pakbaar | Blok 0,8 × 1,0 × 0,8 m, `#5A7398`; met `stand.hoogte` > 0: 0,4 × 0,05 × 0,3 m (ligt op iets) |
| NPC, Richard | Capsule 1,8 m, straal 0,25 m; Richard met randlicht (stijlgids 8.1) |
| Lamp | Bolletje van 0,1 m, emissief in de lichtkleur, op de lichtpositie |

  Alleen objecten die direct in de kamer liggen krijgen een node; inhoud van containers niet. Elke object-node heet naar het item-id, elke uitgang naar het uitgang-id (testbaar).
- W7. **Model en handwerk.** Met `model` vervangt het `.glb` vloer, muren en de geblokkeerd-blokken; objecten met een eigen `model` vervangen hun placeholder. Een ontbrekend bestand geeft een regel in het log en de placeholder, nooit een crash. Een optionele `game/scenes/rooms/<hoofdstuk>/<id>.tscn` wordt als kind toegevoegd voor decor en voorgrond; die bevat geen interactieve objecten en geen lichten (anders zijn logica en budget niet uit data te controleren).
- W8. **Licht.** Elke kamer krijgt ambient `#4A6590` (energie 1,6 binnen, 1,9 buiten) en een zwak maanlicht (richtingslicht, energie 0,2, geen schaduw). Daarnaast de `lichten` uit het kamerbestand: `punt` = OmniLight3D, `spot` = SpotLight3D recht omlaag; `hoogte` standaard 0,2 m onder het plafond. Budget: hoogstens 16 lichten, hoogstens 6 met `schaduw` (schema en W22). Volgorde in de lijst = belang.

**Camera**

- W9. **Eén vaste Camera3D per kamer,** perspectief, verticale FOV `camera.fov` (standaard 17°, bereik 15–20), `keep_aspect` = hoogte, `near` 0,5 m, `far` = afstand + diagonaal van de kamer + 10 m. Geen orthografische camera.
- W10. **Stand.** Richtpunt M = `(breedte/2, 0, hoogte/2)`. Richting vanaf M: `d = (sin(draaiing)·cos(kanteling), sin(kanteling), cos(draaiing)·cos(kanteling))`; camera op `M + afstand·d`, `look_at(M)`. Standaard kanteling 38°, draaiing 27°. Kamers van één gebouw horen dezelfde kanteling en draaiing te hebben.
- W11. **Afstand.** Zonder `camera.afstand` kiest een zuivere functie de kleinste afstand waarbij de acht hoeken van het blok (0,0,0)–(breedte, plafond, hoogte) op 1920×1080 binnen het middelste 60 % van de breedte en 70 % van de hoogte vallen. Met `afstand` wint de content (de art-director stelt bij als Richard niet 140–200 px hoog is).
- W12. **Meeschuiven** (`camera.volgt`, alleen buiten): de camera verschuift in X en Z met Richard, zelfde hoek, geen zoom; ze blijft binnen de kamer. Niet nodig voor de testkamer.

**Lopen**

- W13. **Beloopbaar** is een vak binnen de afmeting dat niet in `geblokkeerd` valt, waar geen niet-pakbaar object staat en geen aanwezige NPC. Uitgangen en pakbare objecten blokkeren het lopen niet (wel neerleggen, O8).
- W14. **Pad.** A* over de vakken (AStarGrid2D), 8 richtingen; diagonaal alleen als beide rechte buren beloopbaar zijn (geen hoeken afsnijden). De logica levert een lijst vakken; de weergave beweegt Richard over de vakmiddens met 1,4 m/s en draait hem in de looprichting. Een NavigationMesh is niet nodig: dit is de navigatie "uit het raster" uit het GDD.
- W15. **Klikken** (links). Raycast op het vloervlak Y 0 → vak (W3).
  - Op een beloopbaar vak: Richard loopt erheen.
  - Op een object, uitgang of NPC: Richard loopt naar het beloopbare vak dat het dichtst bij het doel ligt (het doelvak zelf of een van de 8 buren, kortste pad wint) en doet daar de actie (`standaard_actie`, uitgang = doorgaan met toegang, NPC = gesprek).
  - Op een niet-beloopbaar of onbereikbaar vak: naar het bereikbare vak dat er het dichtst bij ligt (euclidisch; gelijk = kortste pad).
  - Buiten de kamer: niets. Een nieuwe klik tijdens het lopen vervangt het doel vanaf het eerstvolgende vak.

**Zien wat interactief is**

- W16. **Hover.** Onder de cursor: objecten die direct in de kamer liggen, uitgangen, aanwezige NPC's (collision per node, niet per vak). Het geraakte ding krijgt de contour, de naam staat bij de cursor (tekstsleutel `naam`), en na 0,3 s verschijnt het vergrootglas (W18). Decor en geblokkeerde blokken reageren niet.
- W17. **Spatiebalk** (ingedrukt houden): alles uit W16 in de kamer krijgt tegelijk de contour; cue `ui.highlight` één keer per indrukken; loslaten haalt de contour weg. **Contour** volgens stijlgids 8.5: tweede onbelichte pass (opgeblazen achterkant), `#F4F1E6`, 2 px op 1080p, 70 % dekking, geen emissie. Ook in de lichte stand.
- W18. **Vergrootglas.** SubViewport 256×256 px linksboven (klok rechtsboven, strook onderin), die dezelfde `World3D` deelt: zelfde licht en materialen. Een tweede Camera3D met dezelfde richting als de kamercamera, FOV = kamer-FOV / 2,5, gericht op het midden van het object. Verdwijnt als de cursor van het object af gaat.
- W19. **3D-close-up.** Bekijken (rechtsklik) van een object met `closeup` opent de close-up in plaats van alleen de beschrijving: een tweede Camera3D in dezelfde scène wordt actief, recht voor het object (vanaf de camerakant, op `closeup.afstand`, standaard 0,8 m), FOV vrij. Een `closeup.model` (detailversie) staat op renderlaag 2: alleen de close-up-camera ziet het, en zij ziet het gewone model dan niet. De beschrijving staat onderin. Overgang 0,3 s; cues `ui.closeup.open` en `ui.closeup.sluit`. Sluiten met rechtsklik, Esc of klik. Tijdens de close-up: geen lopen, strook vergrendeld, klok blijft staan, speeltijd loopt door.

**Wisselen zonder laadscherm**

- W20. **Kamerwissel** (uitgang, `naar_kamer`, `naar_scene`): uitfaden naar `#07080C` in 0,25 s, oude kamer weg, nieuwe kamer bouwen (W6), Richard op de uitgang of `start_positie`, infaden in 0,25 s. Geen laadscherm, geen tekst, geen spinner. Modellen van kamers die vanaf de huidige kamer via een uitgang bereikbaar zijn, worden op de achtergrond vooraf geladen (`ResourceLoader.load_threaded_request`); is iets nog niet klaar, dan blijft het beeld zwart tot het klaar is. De klok verspringt tijdens het zwart (klok-en-scenetijd.md).
- W21. **Droomovergang** (naar een kamer met `soort: droom`): in plaats van de fade een filter van 1,5 s: desaturatie en ruis lopen op (0,75 s), wissel, en lopen af naar het onderstad-palet (0,75 s). Cue `droom.overgang`. Speeltijd staat stil (klok K9). Zelfde opbouw als W20, zelfde camera-regels.

**Kwaliteitsstanden en prestaties**

- W22. **Twee standen**, één instelling `vol` / `licht` die op Viewport, WorldEnvironment en lichten wordt toegepast, ook op het vergrootglas en de close-up:

| | Vol | Licht |
| --- | --- | --- |
| Render scale | 1,0 | 0,75 met FSR |
| Anti-aliasing | MSAA 4× | FXAA |
| Volumetrische mist | aan | uit |
| SSR, SSAO | aan | uit |
| Glow | aan | aan |
| Lichten met schaduw | de eerste 6 met `schaduw` | de eerste 3 met `schaduw`; de rest zonder |
| Regendeeltjes (later) | circa 6000 | circa 2000 |

  Niets anders verschilt: contour, vergrootglas, close-up, licht zonder schaduw en de kamer blijven hetzelfde.
- W23. **Kiezen en wisselen.** Bij de eerste start meet het spel 3 s in de volle stand in de eerste kamer; gemiddeld onder 50 fps → `licht`. Wisselen kan zonder herstart (in ontwikkelbuilds F4 tot het menu bestaat). De keuze staat in `user://instellingen.cfg`, niet in de save.
- W24. **Prestatiemeting.** `godot -- --meet <kamer_id> [--stand vol|licht]` laadt de kamer met Richard in het midden, wacht 2 s, meet 10 s en schrijft `user://meting/<kamer_id>_<stand>.json` met `kamer`, `stand`, `fps_gem`, `fps_1pct_laagst`, `meshes`, `lichten`, `lichten_schaduw`, `gpu`, `resolutie`. Doel: vol ≥ 60 fps op een middenklasse-gpu, licht ≥ 30 fps op Iris Xe. In ontwikkelbuilds toont F3 dezelfde getallen live, plus het vakkenraster en de geblokkeerde vakken.

**Logica en weergave gescheiden**

- W25. **Twee lagen.** De logica (bijv. `game/systems/kamer_raster.gd`, `vak.gd`, `camera_stand.gd`, `kwaliteit.gd`) is zuiver: vakken, beloopbaarheid, pad, vak↔3D, camerastand en -afstand, de instellingen per stand als data. Ze maakt geen Node3D en leest nooit node-posities. De weergave (bijv. `game/weergave/`) bouwt nodes uit de logica en de content, en stuurt klikken door als `loop_naar(vak)` of `interactie(id, actie)` naar de bestaande systemen. Richards positie in de save is een vak.
- W26. **Headless testbaar.** Alle logica draait in GUT met `--headless`. De weergave-opbouw draait ook headless (de node-boom bestaat zonder gpu), zodat posities, namen, lichten en budget te testen zijn; alleen pixels en fps niet.

## Toestanden

- Kamerweergave: `opbouwen` → `spelen` ⇄ `closeup`; `spelen` → `overgang` (fade of droom) → `opbouwen`. Binnen `spelen`: `highlight` zolang spatie is ingedrukt.
- Richard: `staat` · `loopt` (pad) · `handeling` (actie op het doelvak). Klikken in `overgang` en `closeup`, en tijdens een gesprek of titelkaart, doen niets.
- Kwaliteit: `vol` · `licht`.

## UX-flow

| Speler doet | Wat hij ziet | Cue |
| --- | --- | --- |
| Komt in een kamer | Zwart, dan het verlichte eiland in een donker kader; Richard op de uitgang | `deur.open` of per uitgang |
| Beweegt over een object | Contour, naam bij de cursor, na 0,3 s het vergrootglas linksboven | — |
| Houdt spatie ingedrukt | Contour op alles wat interactief is | `ui.highlight` |
| Klikt op de vloer | Richard loopt over de vakken erheen, om obstakels heen | — (voetstappen: voetsporen-systeem, later) |
| Klikt op een object | Richard loopt ernaast en doet de standaardactie | per actie |
| Rechtsklikt op een object met close-up | Zachte zoom naar een detailbeeld in hetzelfde licht, beschrijving onderin | `ui.closeup.open` / `ui.closeup.sluit` |
| Klikt op een uitgang | Richard loopt erheen; fade; nieuwe kamer | `deur.open` / `deur.geweigerd` |
| Gaat naar de droom | Beeld verliest kleur en korrelt, wordt sepia | `droom.overgang` |
| Drukt F4 / F3 (ontwikkelbuild) | Andere stand zonder herstart / fps, meshes, lichten en raster | — |

## Edge cases

- Kamer zonder `lichten`: alleen ambient en maanlicht, plus een logregel; de kamer blijft speelbaar.
- Meer dan 6 lichten met `schaduw`: alleen de eerste 6 (licht: 3) werpen schaduw; logregel.
- `start_positie` of de aankomstuitgang ligt op een niet-beloopbaar vak: Richard verschijnt op het dichtstbijzijnde beloopbare vak; logregel (content-fout, zie open punt V32).
- Een object is van geen enkel beloopbaar vak te bereiken: de klik loopt zo dicht mogelijk en de actie gaat niet door; Richard mompelt niets. Dit mag niet in content voorkomen (V32).
- Twee objecten in content op hetzelfde vak: ze overlappen tenzij `stand` ze scheidt; hover pakt het bovenste (het laatst gebouwde).
- Neergelegd object: op het vakmidden, `stand` 0; een niet-pakbaar object ligt nooit neer.
- Een NPC die verschijnt of verdwijnt (`aanwezig`) maakt een vak (on)beloopbaar; een lopend pad wordt opnieuw berekend.
- Venster niet 16:9: de FOV is verticaal vast; de kamer krijgt aan de zijkanten meer kader.
- Kamermodel of objectmodel ontbreekt: placeholder plus logregel.
- Hover over een object terwijl de close-up open is: geen contour, geen vergrootglas.

## Acceptatiecriteria

| # | Criterium |
| --- | --- |
| KW-01 | `Vak.naar_3d((0,0))` = (0,5; 0; 0,5) en `Vak.naar_3d((7,5))` = (7,5; 0; 5,5). `Vak.uit_3d((3,99; 0; 0,01))` = (3,0); `Vak.uit_3d((-0,01; 0; 1))` en `Vak.uit_3d((8,0; 0; 1))` in een 8×6-kamer = geen vak. Heen en terug klopt voor alle 48 vakken. |
| KW-02 | Placeholder van `ch01_kantoor`: vloer van X 0–8 en Z 0–6 op Y 0; achterwand (Z 0) en linkerwand (X 0) 2,6 m hoog; voorwand en rechterwand ≤ 0,5 m (draaiing 27). |
| KW-03 | Er zijn nodes `kluisje`, `laptop` en `prullenbak` op hun vakmiddens; `laptop` op Y 0,75; geen node `rapport` (zit in het kluisje). Nodes `deur_hal` en `lift_kantoor` bestaan. |
| KW-04 | Twee lichten uit de fixture: `tl_plafond` SpotLight3D op (3,5; 2,5; 3,5) en `bureaulamp` OmniLight3D op (3,5; 1,1; 1,5), met kleur en energie uit het bestand; plus ambient `#4A6590`. |
| KW-05 | Kamercamera: perspectief, FOV 17, near 0,5, kijkt naar (4; 0; 3) met kanteling 38° en draaiing 27° (±0,1°). De automatische afstand projecteert de acht hoeken van het kamerblok binnen 60 % × 70 % van 1920×1080, en 5 % minder afstand niet meer. |
| KW-06 | Beloopbaar in `ch01_kantoor`: (3,1), (4,1), (6,1), (6,4) niet; (0,3), (7,3), (1,3) wel. |
| KW-07 | Elk berekend pad bestaat uit beloopbare vakken, en geen diagonale stap gaat langs een niet-beloopbaar recht buurvak (gerandomiseerd: 200 paren vakken). |
| KW-08 | Klik op `laptop` vanaf (1,3): Richard eindigt op een beloopbaar buurvak van (4,1) en de gebruik-actie vuurt (de cue staat in het logboek). Klik op (3,1) (geblokkeerd): Richard eindigt op een beloopbaar vak op afstand ≤ 1,5 vak. |
| KW-09 | Spatie indrukken: precies `kluisje`, `laptop`, `prullenbak`, `deur_hal`, `lift_kantoor` hebben een zichtbare contour; `ui.highlight` staat één keer in het logboek; loslaten haalt alle contouren weg. |
| KW-10 | Hover op `laptop`: het vergrootglas is een SubViewport van 256×256 met dezelfde `World3D` als de kamer en een camera met FOV 17 / 2,5. Hover op een geblokkeerd blok toont niets. |
| KW-11 | Rechtsklik op `laptop` (heeft `closeup`): de close-up-camera is actief op 0,8 m van het object, de strook is vergrendeld, `ui.closeup.open` is gelogd; Esc maakt de kamercamera weer actief, logt `ui.closeup.sluit` en verandert geen spelstatus. |
| KW-12 | Door `deur_hal` naar `ch01_hal`: geen laadscherm-node in de boom, de overgang duurt in de testkamer ≤ 0,6 s, Richard staat op `deur_kantoor`, en de nodes van `ch01_kantoor` zijn vrijgegeven. |
| KW-13 | Overgang naar een kamer met `soort: droom` (testkamer in de GUT-test): de filterparameter loopt 0 → 1 → 0 in 1,5 s (±0,1), `droom.overgang` is gelogd, speeltijd staat stil tijdens de overgang. |
| KW-14 | Stand `licht`: scale 0,75 met FSR, MSAA uit, FXAA aan, SSR, SSAO en volumetrische mist uit, glow aan, alleen de eerste 3 lichten met `schaduw` werpen schaduw. Terug naar `vol` herstelt alles; wisselen zonder herstart; de keuze staat na herstart nog in `user://instellingen.cfg`. |
| KW-15 | Budget, headless, in beide standen: `ch01_kantoor` heeft ≤ 300 MeshInstance3D, ≤ 16 Light3D, ≤ 6 (vol) of ≤ 3 (licht) lichten met schaduw. |
| KW-16 | `--meet ch01_kantoor --stand licht` schrijft een JSON met alle velden uit W24. QA meet op de referentielaptop (Iris Xe) ≥ 30 fps licht, en op een middenklasse-gpu ≥ 60 fps vol. |
| KW-17 | KW-01 t/m KW-15 draaien in `godot --headless` via GUT; de tests voor KW-01, KW-05 (afstand), KW-06 en KW-07 maken geen enkele Node3D. |
| KW-18 | De validator: `geblokkeerd` of een licht buiten de afmeting faalt op V11; een dubbel licht-id in een kamer faalt op V01; een camera met FOV buiten 15–20 faalt op het schema (`tests/python/test_validator.py`). |

## Uitbreiding later

- V32 (validator, nog te bouwen): uitgangen, `start_positie` en NPC's liggen niet op een niet-beloopbaar vak, en elk object in de kamer heeft een beloopbaar vak (zelf of buur) dat bereikbaar is vanaf elke uitgang. Dat maakt "geen object kan onbereikbaar worden" ook ruimtelijk waar.
- Levende lichtbronnen, apparaten (lampen aan/uit/dimmen via `lichten`-id), ramen, voetsporen (afdruklaag op de vloer), regen en de omgeving per scènetijd haken in op W8 en W22.
- Hoogteverschillen binnen een kamer en een kompasrichting per raam.
