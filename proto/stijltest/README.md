# Stijltest: low-poly 3D met vlakke kleur en realtime licht (issue #32)

Wegwerpproject, los van `game/`. Godot 4.7, renderer Forward+. Geen texturen en geen foto's: elk materiaal is een vlakke albedo-kleur (palet uit de stijlgids op `taak/stijlgids`), alles wat leeft komt uit licht, glow, fog, reflectie en regen.

## Openen en draaien

- Editor: `godot --editor --path proto/stijltest`, of open `project.godot`. Hoofdscène is `a_straat.tscn`; `b_kamer.tscn` is de kamer.
- Spelen: `godot --path proto/stijltest` (venster). Toets `C` wisselt de camerahoek, `1`/`2` wisselt tussen kamer en straat.
- Screenshots (1920x1080, venster nodig, niet headless): `./run.sh a|b <camera 0-2> <naam.png> [frames]`, bijvoorbeeld `./run.sh a 0 a_straat.png`. Onder de motorkap: `godot --path . --resolution 1920x1080 --windowed -- --cam=0 --shot=shots/x.png --frames=200`. Na 200 frames (regen en mist hebben dan opgebouwd) wordt de viewport opgeslagen en sluit Godot af.
- Alles wordt in GDScript opgebouwd uit primitieven (`lib.gd` bevat de bouwhulpjes, `a_straat.gd` en `b_kamer.gd` de scènes). Er zijn geen externe assets.

## Screenshots (`shots/`)

| Bestand | Wat |
| --- | --- |
| `a_straat.png` | Straat, orthografische camera (hoofdbeeld) |
| `a_straat_perspectief.png` | Straat, smalle FOV (15 graden) vanaf grote afstand |
| `a_straat_richard.png` | Straat, ingezoomd op Richard, vuurwerkresten en de lantaarn |
| `b_kamer.png` | Kamer, orthografisch |
| `b_kamer_dichtbij.png` | Kamer, bureau en raam van dichtbij |
| `b_kamer_perspectief.png` | Kamer, smalle FOV, hele doorsnede |

## Keuzes

**Camera.** Vast, schuin van boven, kijkrichting 34 graden gedraaid om de verticale as (straat) of 22 graden (kamer), 36-38 graden omlaag. Standaard orthografisch (hoogte 38 m voor de straat, 6,2 m voor de kamer): bijna alle verticalen blijven verticaal, de straat leest als een diagonale band en de kamer als een doorsnede. De smalle-FOV-variant (15-26 graden) geeft iets meer diepte en voelt minder als diorama; in de straat vind ik die het mooist, in de kamer is ortho rustiger. Beslis bij het bekijken van de screenshots.

**Licht is de sfeer.** Kleine, koude blauwe ambient (`#4A6590`, energie 2,2 buiten, 1,8 in de kamer) plus een zwak richtingsloos maanlicht zonder schaduw, zodat vormen leesbaar blijven. Daarbovenop warme plassen: natriumlantaarns (`#F08A30`, SpotLight met schaduw, harde kern, zachte rand), warme gevelstralers op het torentje, rode achterlichten en koplampen, koel-wit (`#C8D8F0`) in de bomen, bureaulamp (`#FFD8A0`) en laptop (`#9FC8E8`) in de kamer. De kamer volgt de regel "vol in het licht, leeg in het donker": de bureaulamp maakt het eiland, de rest zakt weg.

**Renderinstellingen** (`lib.gd`, `make_env`): Filmic tonemapping, glow in Screen-modus vanaf HDR-drempel 1,0 (emissive lichtbronnen zijn 6-12 keer helderder dan 1, zodat alleen lampen gloeien), SSAO, SSR (160 stappen, lage roughness op het asfalt), volumetrische mist (dichtheid 0,012 buiten, 0,02 binnen), 4x MSAA in de projectinstellingen, saturatie 0,92. De achtergrond is egaal `#07080C`; een donkere lucht (`#3E5578`) dient alleen als reflectiebron.

**Kader.** Een CanvasLayer met een vignet-shader (eindkleur `#07080C`) legt het donker om het eiland, plus de geometrie zelf die in het donker wegvalt.

**Nat.** Asfalt met roughness 0,1, plassen als platte ellipsen met roughness 0,03. SSR ziet alleen wat op het scherm staat van bovenaf (de onderkant van lampen niet), dus lantaarnkoppen zijn volledig emissive, en onder elke lantaarn en achter de auto ligt een procedurele reflectiestreep (`streep.gdshader`, additief, geen textuur). Regen is een GPUParticles3D (9000 deeltjes buiten, 800 achter het kamerraam) met dunne gestrekte balkjes; op het raam staan losse strepen.

**Kamerraam.** Door de hoge camerahoek zie je door het raam alleen wat lager ligt dan de kamer. De buitenwereld (daken, stadsgloed, drie vuurpijlen) staat daarom in een groep die per camerahoek op de kijkas door het raam wordt geplaatst (`build_outside`). Gevolg: de vuurpijlen kloppen voor de gekozen hoek, bij een andere hoek wordt de groep opnieuw opgebouwd.

**Merken.** Bezorgtas en pictogram volgen de stijlgids: Bringbroh pistache `#8FCB7A` met antraciet en reflecterende strook en twee chevrons; kapsalonbakje baksteen `#9A3B24` met crème; BB-drink gebroken wit met koraaloranje band. Het metro-pictogram is eigen ontwerp: ring met een chevron naar beneden op een marineblauwe plaat, ijsblauw gloeiend. De gevel is een eigen ontwerp met torentje, geen bestaand gebouw. Het clubsjaal en vloerkleed zijn eigen rood-wit (`#A8382A`, `#D8D4C8`).

## Prestaties

Gemeten op een RTX 4080 op 1920x1080, venstermodus: straat circa 170 fps, kamer circa 185-200 fps (gemiddeld over 100 frames, inclusief SSR, SSAO, volumetrische mist en MSAA 4x). Ruim marge, maar dit is een topkaart: de duurste posten zijn volumetrische mist, SSR en de ongeveer 600 losse meshes plus 9000 regendeeltjes in de straat. Voor een zwakkere pc: SSR uit, `volume_size` en `volume_depth` in de projectinstellingen omlaag, regen halveren, boomtakken samenvoegen tot een mesh. Op een integrated GPU is Forward+ met dit lichtaantal (circa 20 lampen in de straat) waarschijnlijk te zwaar; de Mobile-renderer heeft geen SSR en geen volumetrische mist.

## Wat nog niet goed is

- Plassen zijn vlakke blauwe ellipsen; ze spiegelen alleen de lucht en de streepjes. Echte, scherpe reflecties van gevel en bomen ontbreken (SSR heeft daar te weinig beeldinformatie).
- De volumetrische lichtkegels van de lantaarns zijn nauwelijks zichtbaar. Hogere mistdichtheid maakte het hele beeld te donker; dit moet per lamp worden afgesteld (bijvoorbeeld lokale FogVolumes).
- Gevel is te schoon en te regelmatig; het torentje is simpel. Mist daarom detail zoals de lichtjes aan de gevel uit de foto.
- Richard is klein en donker op afstand; leesbaar dankzij de pistachetas, maar hij heeft randlicht nodig.
- Kamer: de parka leest als een donkere vorm, niet als jas; de linkerkant (bed, fietskaart) is erg donker; het licht dat door het raam valt is nauwelijks zichtbaar op de vloer; vuurpijlen zijn statische sterretjes (pulseren zacht, geen vallende vonken).
- Er zijn geen animaties van personages of apparaten, en geen geluid.
